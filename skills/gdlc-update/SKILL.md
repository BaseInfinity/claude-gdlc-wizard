---
name: gdlc-update
description: Smart update for the /gdlc skill — reads CHANGELOG, shows rule diff, runs drift detection, applies changes selectively while preserving the project's case-study GDLC.md.
argument-hint: [check-only | apply | force-all]
effort: high
---

# GDLC Update Wizard

## Task

$ARGUMENTS

## MANDATORY FIRST ACTION: Read the Wizard Doc

**Before doing ANYTHING else**, use the Read tool to read `~/gdlc/CLAUDE_CODE_GDLC_WIZARD.md` — especially the "Staying updated (idempotent wizard)", "URLs", and "Managed files" sections. It contains the step registry, version-tracking format, and drift-detection rules. Do NOT proceed without reading it first.

If `~/gdlc/` is missing, fall back to WebFetch against the raw GitHub URLs listed in the wizard doc. If both fail (offline, no sibling), stop and tell the user to clone `BaseInfinity/gdlc` into `~/gdlc/`.

## Purpose

Update the installed `/gdlc` skill against the sibling playbook at `~/gdlc/`. Show what playbook rules are new since the last sync, run per-file drift detection, and apply changes selectively. NEVER overwrite the consumer project's case-study `GDLC.md` body — only update its metadata header.

## Execution Checklist

Follow these steps IN ORDER. Do not skip or combine steps.

### step-0.1 — Read Wizard Doc

Read `~/gdlc/CLAUDE_CODE_GDLC_WIZARD.md` (done above — mandatory first action).

### step-1 — Read Installed Version

Read the consumer project's `GDLC.md` at project root. Extract:

```markdown
<!-- GDLC Wizard Version: X.Y.Z -->
<!-- GDLC Sibling SHA: <short-sha> -->
```

If no version comment exists, treat as `0.0.0` (first-time setup). Redirect the user to `/gdlc-setup`.

If no `GDLC.md` at project root but `.claude/skills/gdlc/SKILL.md` exists, this is a skill-only install — proceed, but skip the metadata-update steps (step-8). Drift detection still runs against the sibling.

### step-2 — Pull Sibling Repo

Prefer local:
```bash
git -C ~/gdlc status --porcelain
```
If dirty, stop and tell the user to commit or stash in `~/gdlc/`.

```bash
git -C ~/gdlc pull --ff-only
```

If `~/gdlc/` doesn't exist, fall back to WebFetch against the raw URLs from the wizard doc (CHANGELOG, skill, playbook). Note: fallback mode can report rule diffs but cannot cleanly classify DRIFT on the skill file — tell the user.

Capture new sibling SHA:
```bash
git -C ~/gdlc rev-parse --short HEAD
```

### step-3 — Read Latest CHANGELOG

Prefer local `~/gdlc/CHANGELOG.md`; fall back to WebFetch from the raw URL if sibling missing.

Parse the topmost `## [X.Y.Z]` — that's the latest version.

**If installed version matches latest:** say "You're up to date! (version X.Y.Z)" and stop. Nothing else runs.

**If `check-only`:** continue through step-5, print report, stop.

### step-4 — Show Rule Diff

Parse CHANGELOG entries between the installed version and the latest. Present a compact summary:

```
Installed: 0.2.0
Latest:    0.4.1

What changed:
- [0.4.1] gdlc-feedback label map swap — custom feedback:* labels replaced with stock bug/enhancement/question (zero-setup on upstream)
- [0.4.0] gdlc-feedback skill + .gdlc/feedback-log.md scaffold + SHA-256 race-check + privacy allowlist (AUTO/CONFIRM/EXCLUDED)
- [0.3.0] Distribution-readiness: gdlc-setup + gdlc-update skills extracted, graduation criteria decoupled from distribution
- [0.2.0] 12 new earned rules from codeguesser v0.11 ship + Playtest #18 (trust boundaries, determinism foundations, What's Working section)

New earned rules in playbook (not yet in this project's case study):
  - Rule #22: URL-param inputs are user-controlled — validate at the decoder boundary
  - Rule #23: All-or-nothing decoding — one malformed field invalidates the whole payload
  - Rule #28: Keep a "What's Working" section
  (... list all rules added since installed version)
```

Use `git -C ~/gdlc diff <old-sha>..<new-sha> -- GDLC.md` to extract added rule lines if the CHANGELOG is light on detail. The user decides whether any new rule warrants a playtest cycle in this project — that's a separate task, not this update.

### step-5 — Drift Detection

Classify each managed skill file in the suite. Run one `diff -q` per skill:

```bash
for skill in gdlc gdlc-setup gdlc-update gdlc-feedback; do
  diff -q ~/gdlc/.claude/skills/$skill/SKILL.md .claude/skills/$skill/SKILL.md
done
```

Classification table (applies per file):

| diff result | Classification | Notes |
|-------------|----------------|-------|
| Files identical | MATCH | Nothing to do |
| Files differ AND installed file has a known `~/gdlc/` commit SHA in its content (rare — skill file doesn't embed SHA) | DRIFT or CUSTOMIZED | See below |
| Files differ, no embedded marker | CUSTOMIZED | Show diff, ask |
| Installed file missing | MISSING | Install it |
| Installed file exists but is malformed (parse errors, missing frontmatter) | DRIFT | Investigate |

For a CUSTOMIZED skill, read both files and present a human-readable diff summary: "what changed in the latest, what you have, what gets lost if you adopt."

Also classify `.gdlc/feedback-log.md` separately. It is not a `diff`-able managed file (append-only, consumer-owned content) — the update only checks presence:

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

For each approved action, copy the sibling file over and verify:

```bash
# MISSING or CUSTOMIZED-adopt, per approved skill
cp ~/gdlc/.claude/skills/<skill>/SKILL.md .claude/skills/<skill>/SKILL.md
diff -q ~/gdlc/.claude/skills/<skill>/SKILL.md .claude/skills/<skill>/SKILL.md
```

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
<!-- GDLC Sibling SHA: <new-sha> -->           <-- bump
<!-- GDLC Setup Date: <unchanged> -->          <-- preserve
<!-- GDLC Last Update: <YYYY-MM-DD> -->        <-- bump (today)
<!-- Completed Steps: <existing>, step-update-<sha> -->  <-- append
```

Four fields change, one is preserved. Three "bump" fields (`Wizard Version`, `Sibling SHA`, `Last Update`) get replaced with new values. `Completed Steps` gains one new entry (`step-update-<sha>`) appended to the existing list — the prior list is preserved verbatim, only one token is appended. `Setup Date` MUST be preserved verbatim from the existing header. This step NEVER touches `GDLC.md` body content — only the metadata comment block.

If this is a skill-only install (no case-study `GDLC.md`), skip step-8.

### step-9 — Verify

Re-run drift detection across the full suite:

```bash
for skill in gdlc gdlc-setup gdlc-update gdlc-feedback; do
  diff -q ~/gdlc/.claude/skills/$skill/SKILL.md .claude/skills/$skill/SKILL.md
done
```

Expected: identical for every skill that was updated. Files the user chose to skip remain CUSTOMIZED — that's their choice.

Verify `.gdlc/feedback-log.md` exists and `.gdlc/feedback-drafts/` is in `.gitignore`.

Check case-study metadata has the new version + SHA.

Final report:

```
GDLC updated <old-version> → <new-version>.
  skills:          gdlc MATCH, gdlc-setup MATCH, gdlc-update MATCH, gdlc-feedback MATCH
  .gdlc/ scaffold: feedback-log.md present, feedback-drafts/ gitignored
  case-study:      version + sha bumped

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
2. **NEVER touch `~/gdlc/GDLC.md` from the consumer project.** Playbook edits happen in the sibling repo.
3. **NEVER auto-apply without showing what will change first** (unless `force-all` was passed, and only then for CUSTOMIZED — DRIFT still requires user triage).
4. **Respect customizations.** When a file is CUSTOMIZED, show the diff and let the user decide — don't pressure them.
5. **Offline fallback:** if `~/gdlc/` is missing and WebFetch fails, stop. Tell the user to clone the sibling repo. Do not try to reconstruct.
6. **SHA is the source of truth for "last seen playbook".** Don't rely on dates or version strings alone — commit SHAs don't lie.
7. **First-time users:** if no `.claude/skills/gdlc/SKILL.md` exists, stop and redirect to `/gdlc-setup`.

## Failure Modes

- **Sibling repo missing** — stop; tell the user to clone. (Or fall back to WebFetch for rule-diff only; skill updates require sibling presence.)
- **Sibling repo dirty** — stop; tell the user to commit/stash in `~/gdlc/`.
- **`git pull --ff-only` fails (divergence)** — stop; tell user to resolve in `~/gdlc/` manually.
- **Skill file DRIFT** — surface state (size, mtime, content sample); do not guess at the right fix.
- **No `GDLC.md` metadata comments** — legacy install; offer to add them (run `/gdlc-setup regenerate` to wire metadata without re-scaffolding).
- **Installed version ahead of latest** — unusual; user has been editing the sibling repo directly. Surface it; do not downgrade.
