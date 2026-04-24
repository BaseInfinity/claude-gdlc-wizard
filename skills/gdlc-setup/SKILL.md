---
name: gdlc-setup
description: Confidence-driven setup wizard for GDLC — auto-scans consumer project, installs the /gdlc skill, scaffolds a case-study GDLC.md. Asks only what can't be detected or inferred. Run on first install.
argument-hint: [regenerate | skill-only | verify-only]
effort: high
---

# GDLC Setup Wizard

## Task

$ARGUMENTS

## MANDATORY FIRST ACTION: Read the Wizard Doc

**Before doing ANYTHING else**, use the Read tool to read `~/gdlc/CLAUDE_CODE_GDLC_WIZARD.md`. It contains the step registry, managed-files list, URLs, version-tracking format, and the case-study template. Do NOT proceed without reading it first.

If the sibling repo is missing (`~/gdlc/` doesn't exist), stop and tell the user:

```bash
git clone https://github.com/BaseInfinity/gdlc ~/gdlc
```

## Purpose

Install the `/gdlc` skill into the current project, scaffold a case-study stub, and wire metadata so `/gdlc-update` can keep it in sync with the sibling repo. Follow SDLC's confidence-driven principle: **never ask what scanning can reveal** — detect, confirm in bulk, ask only the unresolvable.

## Execution Checklist

Follow these steps IN ORDER. Do not skip or combine steps.

### step-0.1 — Read Wizard Doc

Read `~/gdlc/CLAUDE_CODE_GDLC_WIZARD.md` (done above — this is the mandatory first action).

### step-0.2 — Verify Sibling Repo

```bash
test -f ~/gdlc/GDLC.md && \
  test -f ~/gdlc/.claude/skills/gdlc/SKILL.md && \
  test -f ~/gdlc/CHANGELOG.md
```

If any fail, stop and tell the user to `git clone https://github.com/BaseInfinity/gdlc ~/gdlc` (or `git -C ~/gdlc pull` if the clone is stale).

Verify the sibling working tree is clean (a dirty sibling can leave the consumer pinned to an unrecorded SHA):
```bash
git -C ~/gdlc status --porcelain
```
If the command prints any output, STOP. Tell the user to commit or stash in `~/gdlc/` before re-running setup. Do NOT proceed to SHA capture or skill copy against a dirty sibling.

Capture the sibling commit SHA and the latest CHANGELOG version:
```bash
git -C ~/gdlc rev-parse --short HEAD
```
Parse `~/gdlc/CHANGELOG.md` — the topmost `## [X.Y.Z]` is the current wizard version.

### step-1 — Auto-Scan Consumer Project

Scan the current working directory for GDLC-relevant signals. Every signal maps to one or more of the three surface classes (gameplay / art / pipeline).

| Scan target | Detection | Maps to |
|-------------|-----------|---------|
| `package.json` with `"vitest"` or `"jest"` or `"mocha"` dep | Test harness | All surfaces |
| `package.json` with `"playwright"` or `"@playwright/test"` | e2e harness | gameplay-matrix |
| `__screenshots__/` dir or `*.png` baseline files in tests/ | Visual-regression | art-craft-review |
| `src/*.js` with `new AudioContext` or `canvas.getContext` | Browser game surface | gameplay-matrix, art-craft-review |
| `snippets/`, `levels/`, `content/`, `sprites/`, `audio/` dirs | Content pool | pipeline-contract-audit (audit-map likely) |
| Existing `GDLC.md` at project root | Prior case study | skill-only install |
| Existing `.claude/skills/gdlc/SKILL.md` | Already installed | redirect to `/gdlc-update` |
| `.claude/skills/sdlc-wizard/` or `.claude/skills/setup/` | SDLC wizard installed | compatible peer; note it |
| `CLAUDE.md` present | Project has AI instructions | note it; do not overwrite |

Do the scan with `ls`, `Glob`, and `Grep` — no destructive operations.

### step-2 — Confidence Map

Classify each data point:

| State | Meaning | Action |
|-------|---------|--------|
| RESOLVED (detected) | Scan found it (e.g. `vitest` in deps) | Show for bulk confirmation |
| RESOLVED (inferred) | Two-or-more signals together imply a surface class (e.g. Canvas + audio = gameplay-matrix applies) | Show with inference note |
| UNRESOLVED | Not enough signal (e.g. project name as displayed in the case-study stub) | Must ask |

**Preferences are always UNRESOLVED.** Even if detection succeeds, always ask:
- Project name (as shown in the case-study stub header) — user's canonical name for the repo.
- Surface class subset — if the user only wants gameplay cycles but not art-craft-review, they say so now so the persona matrix gets pruned in the stub.

### step-3 — Present Findings, Ask Unresolved

Output a compact report:

```
Detected:
  - Test harness: vitest (package.json)
  - e2e harness: playwright (package.json)
  - Browser game surface: yes (canvas + AudioContext at src/ui.js, src/effects.js)
  - Content pool: yes (snippets/ dir)

Inferred:
  - Surface classes likely in scope: gameplay-matrix, pipeline-contract-audit
  - Art-craft-review: NOT inferred (no __screenshots__ dir, no visual-regression harness)

Confirm the detected values? (y/n)

Then I need:
  1. Project name for the case-study header?
  2. Include art-craft-review in the persona matrix anyway? (y/n)
```

**Never ask what was already detected.** The confirmation is a single "yes, proceed" — not 15 yes/no questions.

### step-4 — Copy the Skill Suite

The wizard installs four skills from `~/gdlc/.claude/skills/` verbatim. Every sibling skill directory is copied in one pass:

```bash
for skill in gdlc gdlc-setup gdlc-update gdlc-feedback; do
  mkdir -p .claude/skills/$skill
  cp ~/gdlc/.claude/skills/$skill/SKILL.md .claude/skills/$skill/SKILL.md
  diff -q ~/gdlc/.claude/skills/$skill/SKILL.md .claude/skills/$skill/SKILL.md
done
```

Every `diff -q` must report identical. If any mismatch, stop — the copy failed for that skill.

### step-5 — Scaffold Case-Study Stub + Feedback Scaffolds

**Part A — `.gdlc/` scaffolds (always run unless argument is `skill-only`):**

Create `.gdlc/feedback-log.md` with the header row (append-only log used by `/gdlc-feedback`). If the file already exists, leave it alone (idempotent).

```markdown
# GDLC Feedback Log

Traceability index of issues filed upstream via `/gdlc-feedback`. Append-only.

| Date | Type | Issue | Summary |
|------|------|-------|---------|
```

Append `.gdlc/feedback-drafts/` to the project `.gitignore` if the pattern is not already present. Drafts are transient recovery files for cancelled feedback flows; they should not be committed.

**Part B — Case-study stub:**

Skip if argument is `skill-only`, or if `GDLC.md` at project root already exists (do NOT overwrite — legacy case studies are sacred; offer to add metadata comments only if missing).

Otherwise, write `GDLC.md` at the project root from the template in `CLAUDE_CODE_GDLC_WIZARD.md` (Case-Study GDLC.md template section). Replace placeholders:

- `<PROJECT_NAME>` — user's answer from step-3.
- `<VERSION_FROM_CHANGELOG>` — topmost version from `~/gdlc/CHANGELOG.md`.
- `<SHORT_SHA>` — from step-0.2.
- `<YYYY-MM-DD>` — today's date.
- `<DETECTED_OR_USER_CONFIRMED_SURFACES>` — from step-3. Comma-separated list.
- `<DETECTED_HARNESS_OR_...>` — from step-1 detections.

### step-6 — Write Metadata

The metadata comments from the template are already filled. Verify the full five-line canonical block appears in `GDLC.md` header:

```markdown
<!-- GDLC Wizard Version: X.Y.Z -->
<!-- GDLC Sibling SHA: <sha> -->
<!-- GDLC Setup Date: <date> -->
<!-- GDLC Last Update: <date> -->
<!-- Completed Steps: step-0.1, step-0.2, step-1, step-2, step-3, step-4, step-5, step-6, step-7 -->
```

On initial install `GDLC Last Update` equals `GDLC Setup Date`. `/gdlc-update` bumps `Last Update` on every subsequent update while preserving `Setup Date`.

If the user skipped step-5 (skill-only install), there is no case-study `GDLC.md` to write into — skip this step silently. The sibling SHA lives only in the case-study stub; skill-only consumers rely on `/gdlc-update` running `diff -q` against the live sibling instead.

### step-7 — Verify

Confirm:
- All four skill files (`gdlc`, `gdlc-setup`, `gdlc-update`, `gdlc-feedback`) exist under `.claude/skills/` and each `diff -q` matches its sibling counterpart in `~/gdlc/`.
- `.gdlc/feedback-log.md` exists (unless `skill-only`) with the header row.
- `.gdlc/feedback-drafts/` is listed in `.gitignore` (unless `skill-only`).
- `GDLC.md` at project root exists (unless `skill-only`) and contains the expected metadata comments.
- `/gdlc`, `/gdlc-setup`, `/gdlc-update`, and `/gdlc-feedback` are discoverable.

Final report:

```
GDLC v0.4.1 installed.
  skills:     .claude/skills/{gdlc, gdlc-setup, gdlc-update, gdlc-feedback}/SKILL.md (sha <sha>)
  case-study: GDLC.md (project=<name>, surfaces=<list>)
  feedback:   .gdlc/feedback-log.md (empty, ready)

Next:
  1. Restart Claude Code (or /clear) to load the skills.
  2. Run /gdlc <task> for your first playtest cycle.
  3. Run /gdlc-update whenever you want to pull new playbook rules.
  4. Run /gdlc-feedback when a playtest surfaces an earned-rule candidate,
     playbook gap, or wizard bug to file upstream.
```

## Arguments

- `(none)` — full first-install flow (steps 0.1 → 7).
- `regenerate` — re-run steps 4, 6, 7 using existing metadata. Skip scan, skip user prompts, skip stub write. Useful after a failed install.
- `skill-only` — skip step-5. For projects that already have a case-study `GDLC.md` (legacy pre-wizard installs, e.g. codeguesser).
- `verify-only` — jump straight to step-7.

## Rules

1. **Never ask what scanning revealed.** Confirm in bulk; ask only true unknowns (names, opt-in preferences).
2. **Never overwrite an existing case-study `GDLC.md`.** The project's ratchet history is sacred. If one exists, prompt: *skill-only install? or add metadata comments to your existing case study?* — never replace the body.
3. **Never copy the playbook** (`~/gdlc/GDLC.md`) into the consumer project. Reference it; do not vendor it.
4. **Record sibling SHA in metadata.** `/gdlc-update` uses it to compute rule-diffs and detect stale installs.
5. **Fall back cleanly.** Missing sibling → tell user to clone. Dirty sibling → tell user to clean. Existing install → redirect to `/gdlc-update`.
6. **Match SDLC's confidence-driven principle.** The bar is: fewest-possible user prompts, all detection surfaced transparently, user always knows what was inferred vs confirmed.

## Failure Modes

- **Sibling repo missing** — stop; user must clone.
- **Sibling repo dirty** — stop; user must commit/stash in `~/gdlc/`.
- **Consumer isn't a git repo** — GDLC expects commits per cycle. Stop and ask user to `git init` first.
- **Existing `.claude/skills/gdlc/SKILL.md`** — do not overwrite; redirect to `/gdlc-update`.
- **Existing `.gdlc/feedback-log.md` (not empty)** — leave it alone; this is the append-only traceability log and overwriting it destroys history.
- **Existing `.gdlc/feedback-log.md` (empty / header-only)** — safe to leave; idempotent scaffold logic skips re-creation.
- **Existing `GDLC.md` without metadata comments** — legacy install; offer to add metadata in place, keep body untouched, mark as `step-6` complete.
