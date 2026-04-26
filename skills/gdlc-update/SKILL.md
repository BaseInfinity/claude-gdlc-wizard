---
name: gdlc-update
description: Smart update for the /gdlc skill — reads CHANGELOG, shows rule diff, runs drift detection via the wizard CLI, applies changes selectively while preserving the project's case-study GDLC.md.
argument-hint: [check-only | apply | force-all]
effort: high
---

# GDLC Update Wizard

## Task

$ARGUMENTS

## MANDATORY FIRST ACTION: Read the Wizard Doc

**Before doing ANYTHING else**, use the Read tool to read `CLAUDE_CODE_GDLC_WIZARD.md` at the consumer project root — especially the "Staying updated (idempotent wizard)", "URLs", and "Managed files" sections. It contains the step registry, version-tracking format, and drift-detection rules. Do NOT proceed without reading it first.

If `CLAUDE_CODE_GDLC_WIZARD.md` is missing from the project root, the wizard wasn't installed. Stop and tell the user to run `npx claude-gdlc-wizard init` first.

## Purpose

Update the installed `/gdlc` skill against the latest published version of `claude-gdlc-wizard`. Show what playbook rules are new since the last sync, run per-file drift detection via the wizard CLI, and apply changes selectively. NEVER overwrite the consumer project's case-study `GDLC.md` body — only update its metadata header.

## Execution Checklist

Follow these steps IN ORDER. Do not skip or combine steps.

### step-0.1 — Read Wizard Doc

Read `CLAUDE_CODE_GDLC_WIZARD.md` at the consumer project root (done above — mandatory first action).

### step-1 — Read Installed Version

Read the consumer project's `GDLC.md` at project root. Extract:

```markdown
<!-- GDLC Wizard Version: X.Y.Z -->
<!-- GDLC Sibling SHA: <short-sha-or-version> -->
```

If no version comment exists, treat as `0.0.0` (first-time setup). Redirect the user to `/gdlc-setup`.

If no `GDLC.md` at project root but `.claude/skills/gdlc/SKILL.md` exists, this is a skill-only install — proceed, but skip the metadata-update steps (step-8). Drift detection still runs.

### step-2 — Fetch Latest CHANGELOG

WebFetch the canonical CHANGELOG:

```
https://raw.githubusercontent.com/BaseInfinity/claude-gdlc-wizard/main/CHANGELOG.md
```

If WebFetch fails (offline / network blocked), stop and tell the user to retry when connectivity is restored. There is no local-clone fallback in v0.2.1+.

### step-3 — Read Latest Version

Parse the topmost `## [X.Y.Z]` from the fetched CHANGELOG — that's the latest version.

**If `check-only`:** always continue through step-5 to surface drift, regardless of version-match. Print report and stop after step-5.

**If `(none)` / `apply` / `force-all` AND installed version matches latest:** still run step-5 drift detection — a CUSTOMIZED skill on a current version is exactly what update needs to triage. Only say "You're up to date!" and stop early when both: (a) version matches latest AND (b) drift detection reports MATCH for every managed file.

### step-4 — Show Rule Diff

Parse CHANGELOG entries between the installed version and the latest. Present a compact summary:

```
Installed: 0.2.0
Latest:    0.4.1

What changed:
- [0.4.1] gdlc-feedback label map swap — custom feedback:* labels replaced with stock bug/enhancement/question (zero-setup on upstream)
- [0.4.0] gdlc-feedback skill + .gdlc/feedback-log.md scaffold + SHA-256 race-check + privacy allowlist (AUTO/CONFIRM/EXCLUDED)
- [0.3.0] Distribution-readiness: gdlc-setup + gdlc-update skills extracted, graduation criteria decoupled from distribution
- [0.2.1] Skill behavioral migration to local-repo paths — sibling-clone no longer required
- [0.2.0] Path A consolidation — framework playbook moved into claude-gdlc-wizard
```

For new earned rules in the playbook, WebFetch the upstream playbook:

```
https://raw.githubusercontent.com/BaseInfinity/claude-gdlc-wizard/main/GDLC.md
```

The user decides whether any new rule warrants a playtest cycle in this project — that's a separate task, not this update.

### step-5 — Drift Detection

Delegate to the wizard CLI — it already knows what's installed vs what should be:

```bash
npx claude-gdlc-wizard check
```

The CLI reports each managed file as MATCH / CUSTOMIZED / MISSING / DRIFT against the locally installed CLI templates. If you need the latest published templates instead, fetch them via WebFetch and compare.

Classification table (CLI output → action):

| CLI status | Classification | Notes |
|------------|----------------|-------|
| MATCH | MATCH | Nothing to do |
| CUSTOMIZED | CUSTOMIZED | Show diff, ask |
| MISSING | MISSING | Install it |
| DRIFT | DRIFT | Investigate (e.g., missing executable bit) |

For a CUSTOMIZED skill, read both files (installed and the upstream raw URL) and present a human-readable diff summary: "what changed in the latest, what you have, what gets lost if you adopt."

Also classify `.gdlc/feedback-log.md` separately. It is not a `diff`-able managed file (append-only, consumer-owned content) — only check presence:

- **Present** → leave alone.
- **Missing** → flag for the step-7.5 migration (pre-v0.4.0 consumers get the file created there, not here).

### step-6 — Per-File Update Plan

For each managed file, propose an action:

| Status | Default action | Overridable? |
|--------|----------------|--------------|
| MATCH | Skip | n/a |
| MISSING | Install | no |
| CUSTOMIZED | Ask: adopt latest / keep mine / merge manually | yes |
| DRIFT | Surface, do not guess | no (user must triage) |

**If `force-all`:** skip the per-file prompts. Still surface DRIFT; still skip MATCH. Only CUSTOMIZED gets auto-overwritten by `force-all`.

### step-7 — Apply

Apply approved updates **per-file**, not via a global force. The wizard CLI's `init --force` overwrites every managed file unconditionally — that destroys any "keep mine" decisions from step-6. Honor the per-file plan instead by writing only the files the user approved:

For each file the user chose **adopt latest** (or which is **MISSING**):

1. WebFetch the latest content from the canonical raw URL (paths under `https://raw.githubusercontent.com/BaseInfinity/claude-gdlc-wizard/main/`):
   - Skills: `skills/<name>/SKILL.md`
   - Hooks: `hooks/<name>.sh` and `hooks/hooks.json`
   - Settings template: `cli/templates/settings.json`
   - Wizard doc: `CLAUDE_CODE_GDLC_WIZARD.md`
2. Write the fetched content to the corresponding `.claude/...` path (or project root for the wizard doc) using the Write tool.
3. For hook scripts, run `chmod +x` on the destination to preserve the executable bit.
4. For `.claude/settings.json`: NEVER overwrite blindly. Read the consumer's existing `settings.json`, parse it as JSON, replace only the wizard hook entries (those whose `command` references one of the wizard's hook script basenames — `gdlc-prompt-check.sh`, `instructions-loaded-check.sh`) with the entries from the fetched template, preserve every other field and every other hook entry, and Write the result back. This in-skill merge mirrors `cli/init.js::mergeSettings` semantics and avoids the global force-apply pitfall.

For each file the user chose **keep mine**: do nothing. The CUSTOMIZED state persists by design — that's the entire point of the per-file plan in step-6.

For files marked **DRIFT**: do not touch automatically. Surface the state to the user and ask for explicit triage (e.g., for a missing executable bit, prompt to `chmod +x` and nothing else).

NEVER touch the consumer's `GDLC.md` body. Only the metadata header in step-8.

### step-7.5 — One-time `.gdlc/` Migration

For pre-v0.4.0 consumers, this is a one-time file-creation migration. It is idempotent — subsequent runs skip any file that already exists. It **never** edits `GDLC.md` body.

1. **Dirty-tree check.** If the consumer repo has uncommitted changes, warn and require explicit confirm before touching new files.
2. **Create `.gdlc/feedback-log.md`** if missing, with the header row:
   ```markdown
   # GDLC Feedback Log

   Traceability index of issues filed upstream via `/gdlc-feedback`. Append-only.

   | Date | Type | Issue | Summary |
   |------|------|-------|---------|
   ```
3. **Append `.gdlc/feedback-drafts/`** to the project `.gitignore` if the pattern is not already present.

If both were already present (post-v0.4.0 consumer), this step is a no-op.

### step-8 — Bump Metadata

In the consumer's `GDLC.md`, update four fields of the five-line canonical metadata block (three bumped, one appended to; one preserved):

```markdown
<!-- GDLC Wizard Version: <new-version> -->   <-- bump
<!-- GDLC Sibling SHA: <new-source-id> -->     <-- bump (npm version or git SHA — see below)
<!-- GDLC Setup Date: <unchanged> -->          <-- preserve
<!-- GDLC Last Update: <YYYY-MM-DD> -->        <-- bump (today)
<!-- Completed Steps: <existing>, step-update-<source-id> -->  <-- append
```

**Source ID source (the `<new-source-id>` value):** capture a stable identifier for the wizard install. In v0.2.1+, this is the npm version, optionally suffixed with a git SHA if the user has a local clone:

```bash
SOURCE_ID=$(npx claude-gdlc-wizard --version 2>/dev/null || echo "unknown")
# Optional: append git SHA if a local clone exists
if [ -d "$HOME/claude-gdlc-wizard/.git" ]; then
  GIT_SHA=$(git -C "$HOME/claude-gdlc-wizard" rev-parse --short HEAD 2>/dev/null)
  [ -n "$GIT_SHA" ] && SOURCE_ID="${SOURCE_ID}-${GIT_SHA}"
fi
```

The field name `Sibling SHA` is preserved as-is for backward compatibility with existing case studies — the value semantics evolved with v0.2.1 (Path A consolidation), but the label is stable.

Four fields change, one is preserved. Three "bump" fields (`Wizard Version`, `Sibling SHA`, `Last Update`) get replaced with new values. `Completed Steps` gains one new entry (`step-update-<source-id>`) appended to the existing list — the prior list is preserved verbatim, only one token is appended. `Setup Date` MUST be preserved verbatim from the existing header. This step NEVER touches `GDLC.md` body content — only the metadata comment block.

If this is a skill-only install (no case-study `GDLC.md`), skip step-8.

### step-9 — Verify

Re-run drift detection via the CLI:

```bash
npx claude-gdlc-wizard check
```

Expected: every managed file reports MATCH for files the user updated. Files the user chose to skip remain CUSTOMIZED — that's their choice.

Verify `.gdlc/feedback-log.md` exists and `.gdlc/feedback-drafts/` is in `.gitignore`.

Check case-study metadata has the new version + source ID.

Final report:

```
GDLC updated <old-version> → <new-version>.
  skills:          gdlc MATCH, gdlc-setup MATCH, gdlc-update MATCH, gdlc-feedback MATCH
  .gdlc/ scaffold: feedback-log.md present, feedback-drafts/ gitignored
  case-study:      version + source ID bumped

New rules available (see step-4 for full list): <N>
Next: /gdlc <task> to kick off a playtest cycle against the new rules,
      or /gdlc-feedback to file earned-rule candidates / gaps / bugs upstream.
```

## Arguments

- `(none)` — full flow with per-file prompts (alias: `apply`).
- `check-only` — run through step-5, print report, stop. Safe unattended.
- `apply` — explicit version of `(none)`.
- `force-all` — skip per-file approval; auto-adopt CUSTOMIZED. Still surface DRIFT; still skip MATCH. Use only after seeing the drift report.

## Rules

1. **NEVER modify the consumer project's `GDLC.md` body.** That's the project's ratchet ledger — only the metadata header is managed.
2. **NEVER vendor the playbook.** The upstream playbook lives in `claude-gdlc-wizard`'s `GDLC.md`. Reference it; do not copy it into the consumer project.
3. **NEVER auto-apply without showing what will change first** (unless `force-all` was passed, and only then for CUSTOMIZED — DRIFT still requires user triage).
4. **Respect customizations.** When a file is CUSTOMIZED, show the diff and let the user decide — don't pressure them.
5. **Offline behavior:** WebFetch is required for CHANGELOG / playbook diff. If WebFetch fails, stop and tell the user to retry. The CLI's `check` works offline (uses installed templates).
6. **Source ID is the stable identifier.** Don't rely on dates or version strings alone — the source ID captured at update time is the audit anchor.
7. **First-time users:** if no `.claude/skills/gdlc/SKILL.md` exists, stop and redirect to `/gdlc-setup`.

## Failure Modes

- **CLI not installed** — `npx claude-gdlc-wizard` fails. Tell the user to install Node ≥ 18 and re-run.
- **WebFetch fails** — stop; tell the user to retry when connectivity is restored.
- **Skill file DRIFT** — surface state (size, mtime, content sample); do not guess at the right fix.
- **No `GDLC.md` metadata comments** — legacy install; offer to add them (run `/gdlc-setup regenerate` to wire metadata without re-scaffolding).
- **Installed version ahead of latest** — unusual; user has been running off a local clone or pre-release. Surface it; do not downgrade.
