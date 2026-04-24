'use strict';

const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

const RESET = '\x1b[0m';
const RED = '\x1b[31m';
const GREEN = '\x1b[32m';
const YELLOW = '\x1b[33m';
const CYAN = '\x1b[36m';

const REPO_ROOT = path.join(__dirname, '..');
const WIZARD_DOC = path.join(REPO_ROOT, 'CLAUDE_CODE_GDLC_WIZARD.md');

const FILES = [
  { src: 'skills/gdlc/SKILL.md', dest: '.claude/skills/gdlc/SKILL.md', base: REPO_ROOT },
  { src: 'skills/gdlc-setup/SKILL.md', dest: '.claude/skills/gdlc-setup/SKILL.md', base: REPO_ROOT },
  { src: 'skills/gdlc-update/SKILL.md', dest: '.claude/skills/gdlc-update/SKILL.md', base: REPO_ROOT },
  { src: 'skills/gdlc-feedback/SKILL.md', dest: '.claude/skills/gdlc-feedback/SKILL.md', base: REPO_ROOT },
];

const GITIGNORE_ENTRIES = ['.claude/plans/', '.claude/settings.local.json'];

function planOperations(targetDir, { force }) {
  const ops = [];

  for (const file of FILES) {
    const destPath = path.join(targetDir, file.dest);
    const srcPath = path.join(file.base, file.src);
    const exists = fs.existsSync(destPath);
    ops.push({
      src: srcPath,
      dest: destPath,
      relativeDest: file.dest,
      action: exists ? (force ? 'OVERWRITE' : 'SKIP') : 'CREATE',
    });
  }

  const wizardDest = path.join(targetDir, 'CLAUDE_CODE_GDLC_WIZARD.md');
  const wizardExists = fs.existsSync(wizardDest);
  ops.push({
    src: WIZARD_DOC,
    dest: wizardDest,
    relativeDest: 'CLAUDE_CODE_GDLC_WIZARD.md',
    action: wizardExists ? (force ? 'OVERWRITE' : 'SKIP') : 'CREATE',
  });

  return ops;
}

function ensureDir(filePath) {
  fs.mkdirSync(path.dirname(filePath), { recursive: true });
}

function executeOperations(ops) {
  for (const op of ops) {
    if (op.action === 'SKIP') continue;
    ensureDir(op.dest);
    fs.copyFileSync(op.src, op.dest);
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

${YELLOW}Restart Claude Code${RESET} to load new skills:
  ${CYAN}/exit${RESET} then ${CYAN}claude --continue${RESET}  (keeps conversation history)
  ${CYAN}/exit${RESET} then ${CYAN}claude${RESET}              (fresh start)

Next steps:
  1. Restart Claude Code (see above)
  2. Clone the sibling playbook: ${CYAN}git clone https://github.com/BaseInfinity/gdlc ~/gdlc${RESET}
  3. Run ${CYAN}/gdlc-setup${RESET} — auto-scans and scaffolds your GDLC.md
  4. Run ${CYAN}/gdlc <task>${RESET} for your first playtest cycle

The wizard doc is at: CLAUDE_CODE_GDLC_WIZARD.md
  `);

  return true;
}

function checkFile(srcPath, destPath, relativeDest) {
  if (!fs.existsSync(destPath)) {
    return { file: relativeDest, status: 'MISSING' };
  }
  const srcHash = crypto.createHash('sha256').update(fs.readFileSync(srcPath)).digest('hex');
  const destHash = crypto.createHash('sha256').update(fs.readFileSync(destPath)).digest('hex');
  return {
    file: relativeDest,
    status: srcHash === destHash ? 'MATCH' : 'CUSTOMIZED',
  };
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
    results.push(checkFile(srcPath, destPath, file.dest));
  }

  const wizardDest = path.join(targetDir, 'CLAUDE_CODE_GDLC_WIZARD.md');
  results.push(checkFile(WIZARD_DOC, wizardDest, 'CLAUDE_CODE_GDLC_WIZARD.md'));

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
