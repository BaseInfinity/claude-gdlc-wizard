'use strict';

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const RESET = '\x1b[0m';
const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const MAGENTA = '\x1b[35m';
const CYAN = '\x1b[36m';

const REPO_ROOT = path.join(__dirname, '..');
const TEMPLATES_DIR = path.join(__dirname, 'templates');
const WIZARD_DOC = path.join(REPO_ROOT, 'CLAUDE_CODE_GDLC_WIZARD.md');

// Skills and hooks live at repo root (single source of truth for both plugin
// and CLI). settings.json is CLI-specific — lives under cli/templates/.
const FILES = [
  { src: 'settings.json', dest: '.claude/settings.json', base: TEMPLATES_DIR },
  { src: 'hooks/_find-gdlc-root.sh', dest: '.claude/hooks/_find-gdlc-root.sh', base: REPO_ROOT },
  { src: 'hooks/gdlc-prompt-check.sh', dest: '.claude/hooks/gdlc-prompt-check.sh', executable: true, base: REPO_ROOT },
  { src: 'hooks/gdlc-instructions-loaded-check.sh', dest: '.claude/hooks/gdlc-instructions-loaded-check.sh', executable: true, base: REPO_ROOT },
  { src: 'skills/gdlc/SKILL.md', dest: '.claude/skills/gdlc/SKILL.md', base: REPO_ROOT },
  { src: 'skills/gdlc-setup/SKILL.md', dest: '.claude/skills/gdlc-setup/SKILL.md', base: REPO_ROOT },
  { src: 'skills/gdlc-update/SKILL.md', dest: '.claude/skills/gdlc-update/SKILL.md', base: REPO_ROOT },
  { src: 'skills/gdlc-feedback/SKILL.md', dest: '.claude/skills/gdlc-feedback/SKILL.md', base: REPO_ROOT },
];

// Match hook entries by the installed script basename so a user-customized
// settings.json with other hooks doesn't get clobbered.
const WIZARD_HOOK_MARKERS = FILES
  .filter((f) => f.executable && f.dest.startsWith('.claude/hooks/'))
  .map((f) => path.basename(f.src));

// Pre-rename hook artifacts shipped by older wizard versions. These are
// unambiguously wizard-owned: settings entries get replaced (not appended-
// alongside), disk files get removed, `check` flags any leftover as DRIFT.
const LEGACY_HOOK_FILES = [
  { dest: '.claude/hooks/instructions-loaded-check.sh', basename: 'instructions-loaded-check.sh' },
];

const LEGACY_HOOK_MARKERS = LEGACY_HOOK_FILES.map((f) => f.basename);

const GITIGNORE_ENTRIES = ['.claude/plans/', '.claude/settings.local.json'];

function isWizardHookEntry(hookEntry) {
  if (!hookEntry || !hookEntry.hooks) return false;
  return hookEntry.hooks.some((h) =>
    WIZARD_HOOK_MARKERS.some((marker) => h.command && h.command.includes(marker))
  );
}

function isLegacyHookEntry(hookEntry) {
  if (!hookEntry || !hookEntry.hooks) return false;
  return hookEntry.hooks.some((h) =>
    LEGACY_HOOK_MARKERS.some((marker) => h.command && h.command.includes(marker))
  );
}

function mergeSettings(existingPath, templatePath, force) {
  try {
    const existing = JSON.parse(fs.readFileSync(existingPath, 'utf8'));
    const template = JSON.parse(fs.readFileSync(templatePath, 'utf8'));

    if (!existing.hooks) existing.hooks = {};

    for (const [event, templateEntries] of Object.entries(template.hooks || {})) {
      if (!existing.hooks[event]) {
        existing.hooks[event] = templateEntries;
        continue;
      }

      // Each template event has exactly one wizard hook entry.
      const templateEntry = templateEntries[0];

      // Drop legacy wizard entries first (unambiguously wizard-owned, regardless of force).
      // Walk back-to-front so splice indices stay valid.
      for (let i = existing.hooks[event].length - 1; i >= 0; i--) {
        if (isLegacyHookEntry(existing.hooks[event][i])) {
          existing.hooks[event].splice(i, 1);
        }
      }

      const existingIdx = existing.hooks[event].findIndex(isWizardHookEntry);

      if (existingIdx === -1) {
        existing.hooks[event].push(templateEntry);
      } else if (force) {
        existing.hooks[event][existingIdx] = templateEntry;
      }
    }

    const merged = JSON.stringify(existing, null, 2) + '\n';
    const original = fs.readFileSync(existingPath, 'utf8');
    return merged === original ? null : merged;
  } catch (_) {
    return null;
  }
}

function planOperations(targetDir, { force }) {
  const ops = [];

  for (const file of FILES) {
    const destPath = path.join(targetDir, file.dest);
    const srcPath = path.join(file.base, file.src);
    const exists = fs.existsSync(destPath);

    if (exists && file.dest === '.claude/settings.json') {
      const merged = mergeSettings(destPath, srcPath, force);
      if (merged) {
        ops.push({
          src: srcPath,
          dest: destPath,
          relativeDest: file.dest,
          action: 'MERGE',
          mergedContent: merged,
          executable: false,
        });
        continue;
      }
      // Invalid JSON or no-op merge → fall through to SKIP/OVERWRITE.
    }

    ops.push({
      src: srcPath,
      dest: destPath,
      relativeDest: file.dest,
      action: exists ? (force ? 'OVERWRITE' : 'SKIP') : 'CREATE',
      executable: file.executable || false,
    });
  }

  const wizardDest = path.join(targetDir, 'CLAUDE_CODE_GDLC_WIZARD.md');
  const wizardExists = fs.existsSync(wizardDest);
  ops.push({
    src: WIZARD_DOC,
    dest: wizardDest,
    relativeDest: 'CLAUDE_CODE_GDLC_WIZARD.md',
    action: wizardExists ? (force ? 'OVERWRITE' : 'SKIP') : 'CREATE',
    executable: false,
  });

  // Schedule removal of any pre-rename hook files left over from older wizard
  // versions. Always remove (not gated on --force) since these are wizard-owned
  // artifacts, not user files.
  for (const legacy of LEGACY_HOOK_FILES) {
    const legacyPath = path.join(targetDir, legacy.dest);
    if (fs.existsSync(legacyPath)) {
      ops.push({
        src: null,
        dest: legacyPath,
        relativeDest: legacy.dest,
        action: 'REMOVE_LEGACY',
        executable: false,
      });
    }
  }

  return ops;
}

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function executeOperations(ops) {
  for (const op of ops) {
    if (op.action === 'SKIP') continue;
    if (op.action === 'REMOVE_LEGACY') {
      fs.unlinkSync(op.dest);
      continue;
    }
    ensureDir(op.dest);
    if (op.action === 'MERGE') {
      fs.writeFileSync(op.dest, op.mergedContent);
    } else {
      fs.copyFileSync(op.src, op.dest);
    }
    if (op.executable) {
      fs.chmodSync(op.dest, 0o755);
    }
  }
}

function updateGitignore(targetDir, { dryRun }) {
  const gitignorePath = path.join(targetDir, '.gitignore');
  let content = '';
  if (fs.existsSync(gitignorePath)) {
    content = fs.readFileSync(gitignorePath, 'utf8');
  }

  const lines = content.split('\n').map((l) => l.trim()).filter((l) => l && !l.startsWith('#'));
  const toAdd = GITIGNORE_ENTRIES.filter((entry) => !lines.includes(entry));
  if (toAdd.length === 0) return [];

  if (!dryRun) {
    const suffix = (content && !content.endsWith('\n') ? '\n' : '') + toAdd.join('\n') + '\n';
    fs.appendFileSync(gitignorePath, suffix);
  }

  return toAdd;
}

function printOps(ops) {
  for (const op of ops) {
    const color = op.action === 'CREATE' ? GREEN
      : op.action === 'SKIP' ? YELLOW
      : op.action === 'MERGE' ? MAGENTA
      : op.action === 'REMOVE_LEGACY' ? RED
      : CYAN;
    console.log(`  ${color}${op.action}${RESET}  ${op.relativeDest}`);
  }
}

function init(targetDir, { force = false, dryRun = false } = {}) {
  const ops = planOperations(targetDir, { force });

  if (dryRun) {
    console.log('Dry run — no files will be written:\n');
    printOps(ops);
    const gitignoreAdds = updateGitignore(targetDir, { dryRun: true });
    if (gitignoreAdds.length > 0) {
      console.log(`  ${GREEN}APPEND${RESET}  .gitignore (${gitignoreAdds.join(', ')})`);
    }
    return true;
  }

  console.log('');
  printOps(ops);

  const allSkip = ops.every((o) => o.action === 'SKIP');
  if (!allSkip) {
    executeOperations(ops);
  }

  const gitignoreAdds = updateGitignore(targetDir, { dryRun: false });
  if (gitignoreAdds.length > 0) {
    console.log(`  ${GREEN}APPEND${RESET}  .gitignore (${gitignoreAdds.join(', ')})`);
  }

  if (allSkip && gitignoreAdds.length === 0) {
    console.log('\nAll files already exist. Use --force to overwrite.');
    return true;
  }

  console.log(`
${GREEN}GDLC Wizard installed successfully!${RESET}

${YELLOW}Restart Claude Code${RESET} to load new hooks and skills:
  ${CYAN}/exit${RESET} then ${CYAN}claude --continue${RESET}  (keeps conversation history)
  ${CYAN}/exit${RESET} then ${CYAN}claude${RESET}              (fresh start)

Next steps:
  1. Restart Claude Code (see above)
  2. Run ${CYAN}/gdlc-setup${RESET} — auto-scans and scaffolds your GDLC.md
  3. Run ${CYAN}/gdlc <task>${RESET} for your first playtest cycle

The wizard doc is at: CLAUDE_CODE_GDLC_WIZARD.md
  `);

  return true;
}

function checkFile(srcPath, destPath, relativeDest, shouldBeExecutable) {
  if (!fs.existsSync(destPath)) {
    return { file: relativeDest, status: 'MISSING' };
  }
  const srcHash = crypto.createHash('sha256').update(fs.readFileSync(srcPath)).digest('hex');
  const destHash = crypto.createHash('sha256').update(fs.readFileSync(destPath)).digest('hex');
  const result = {
    file: relativeDest,
    status: srcHash === destHash ? 'MATCH' : 'CUSTOMIZED',
  };

  if (shouldBeExecutable) {
    try {
      fs.accessSync(destPath, fs.constants.X_OK);
    } catch (_) {
      result.status = 'DRIFT';
      result.details = 'Missing executable permission (chmod +x)';
    }
  }

  return result;
}

function checkGitignore(gitignorePath) {
  if (!fs.existsSync(gitignorePath)) {
    return { file: '.gitignore', status: 'MISSING', details: 'No .gitignore found' };
  }
  const lines = fs.readFileSync(gitignorePath, 'utf8').split('\n')
    .map((l) => l.trim())
    .filter((l) => l && !l.startsWith('#'));
  const missing = GITIGNORE_ENTRIES.filter((e) => !lines.includes(e));
  if (missing.length > 0) {
    return { file: '.gitignore', status: 'DRIFT', details: `Missing entries: ${missing.join(', ')}` };
  }
  return { file: '.gitignore', status: 'MATCH' };
}

function check(targetDir, { json = false } = {}) {
  const results = [];

  for (const file of FILES) {
    const destPath = path.join(targetDir, file.dest);
    const srcPath = path.join(file.base, file.src);
    results.push(checkFile(srcPath, destPath, file.dest, file.executable || false));
  }

  const wizardDest = path.join(targetDir, 'CLAUDE_CODE_GDLC_WIZARD.md');
  results.push(checkFile(WIZARD_DOC, wizardDest, 'CLAUDE_CODE_GDLC_WIZARD.md', false));

  // Flag any pre-rename hook artifacts so users know to re-run init.
  for (const legacy of LEGACY_HOOK_FILES) {
    const legacyPath = path.join(targetDir, legacy.dest);
    if (fs.existsSync(legacyPath)) {
      results.push({
        file: legacy.dest,
        status: 'DRIFT',
        details: 'Legacy wizard hook from a prior version — run `init` (or `init --force`) to remove',
      });
    }
  }

  const gitignorePath = path.join(targetDir, '.gitignore');
  results.push(checkGitignore(gitignorePath));

  const hasDrift = results.some((r) => r.status === 'MISSING' || r.status === 'DRIFT');

  if (json) {
    console.log(JSON.stringify({ files: results }, null, 2));
  } else {
    for (const r of results) {
      const color = r.status === 'MATCH' ? GREEN : r.status === 'MISSING' ? RED : YELLOW;
      console.log(`  ${color}${r.status}${RESET}  ${r.file}`);
      if (r.details) console.log(`         ${r.details}`);
    }
  }

  return { results, hasDrift };
}

module.exports = { init, check, planOperations, GITIGNORE_ENTRIES };
