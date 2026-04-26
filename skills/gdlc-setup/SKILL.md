---
name: gdlc-setup
description: Confidence-driven setup wizard for GDLC — auto-scans consumer project, verifies the wizard install, scaffolds a case-study GDLC.md. Asks only what can't be detected or inferred. Run on first install (after `npx claude-gdlc-wizard init`).
argument-hint: [regenerate | skill-only | verify-only]
effort: high
---

# GDLC Setup Wizard

## Task

$ARGUMENTS

## MANDATORY FIRST ACTION: Read the Wizard Doc

**Before doing ANYTHING else**, use the Read tool to read `CLAUDE_CODE_GDLC_WIZARD.md` at the consumer project root. It contains the step registry, managed-files list, URLs, version-tracking format, and the case-study template. Do NOT proceed without reading it first.

If `CLAUDE_CODE_GDLC_WIZARD.md` is missing from the project root, the wizard wasn't installed. Stop and tell the user:

```bash
npx claude-gdlc-wizard init
```

## Purpose

Scaffold the consumer's case-study `GDLC.md`, verify the four `/gdlc*` skills are installed, and wire metadata so `/gdlc-update` can keep the install in sync. Skill files themselves are installed by `npx claude-gdlc-wizard init` (the CLI), not by this skill — `/gdlc-setup` runs *after* the CLI has placed the skill files and wizard doc. Follow SDLC's confidence-driven principle: **never ask what scanning can reveal** — detect, confirm in bulk, ask only the unresolvable.

## Execution Checklist

Follow these steps IN ORDER. Do not skip or combine steps.

### step-0.1 — Read Wizard Doc

Read `CLAUDE_CODE_GDLC_WIZARD.md` at the consumer project root (done above — this is the mandatory first action).

### step-0.2 — Verify Wizard Install

The CLI installs the wizard surface before this skill runs (settings.json, 3 hook files, 4 skill files, wizard doc, .gitignore additions). Delegate the full verification to the CLI rather than partial-test the surface:

```bash
npx claude-gdlc-wizard check
```

Every managed item should report MATCH. Acceptable on first install: `.gitignore` may report DRIFT if the consumer has no `.gitignore` yet — that's resolved later when `/gdlc-setup` writes its own additions. Any MISSING / DRIFT for skills, hooks, settings.json, or the wizard doc means the install is incomplete — stop and tell the user to run `npx claude-gdlc-wizard init` (or `npx claude-gdlc-wizard init --force` to repair a partial install).

Capture the source ID and the latest CHANGELOG version:

```bash
SOURCE_ID=$(npx claude-gdlc-wizard --version 2>/dev/null || echo "unknown")
# Optional: append git SHA if a local clone exists
if [ -d "$HOME/claude-gdlc-wizard/.git" ]; then
  GIT_SHA=$(git -C "$HOME/claude-gdlc-wizard" rev-parse --short HEAD 2>/dev/null)
  [ -n "$GIT_SHA" ] && SOURCE_ID="${SOURCE_ID}-${GIT_SHA}"
fi
```

For the latest version, WebFetch the CHANGELOG:

```
https://raw.githubusercontent.com/BaseInfinity/claude-gdlc-wizard/main/CHANGELOG.md
```

Parse the topmost `## [X.Y.Z]` — that's the current wizard version.

### step-0.5 — Existing-Install Early-Redirect

**Before any auto-scan or file write**, check whether this project already has a wizard-managed `GDLC.md`. If so, this is an **update** scenario, not a setup — stop and redirect to `/gdlc-update`.

```bash
if [ -f GDLC.md ] && grep -qE '^<!-- (GDLC )?Wizard Version:' GDLC.md; then
  echo "Existing wizard install detected. Run /gdlc-update instead — /gdlc-setup would clobber the case-study body."
  exit 1
fi
```

Three branches:

| State | Detection | Action |
|-------|-----------|--------|
| Wizard-managed install | `GDLC.md` exists AND has `<!-- (GDLC )?Wizard Version: ` metadata comment | **STOP.** Tell the user to run `/gdlc-update` and exit before step-1. Setup would overwrite the existing case-study body — never destructive without explicit user confirmation |
| Empty stub | `GDLC.md` exists but is zero-byte (just-installed, pre-setup state) | Continue — this is the expected new-install handoff from `npx claude-gdlc-wizard init` |
| Legacy / unmanaged | `GDLC.md` exists but has no wizard-version metadata | **STOP and ASK.** Show the user the file's first 10 lines, ask whether to (a) treat as legacy and run `/gdlc-update`, (b) move to `GDLC.md.bak` and proceed with fresh setup, or (c) abort. Never overwrite without explicit choice |
| No GDLC.md | File absent | Continue — fresh install path |

This covers Setup Rule 5 ("detect existing install, redirect to update") and prevents the codeguesser-class bug where a pre-wizard `GDLC.md` could be silently overwritten when `/gdlc-setup` ran on an already-populated project.

### step-1 — Auto-Scan Consumer Project

Scan the current working directory for GDLC-relevant signals. Every signal maps to one or more of the three surface classes (gameplay / art / pipeline).

| Scan target | Detection | Maps to |
|-------------|-----------|---------|
| `package.json` `devDependencies`/`dependencies` includes `vitest`, `jest`, or `mocha` | Test harness | All surfaces |
| `package.json` `devDependencies`/`dependencies` includes `playwright` or `@playwright/test` | e2e harness | gameplay-matrix |
| `__screenshots__/` dir or `*.png` baseline files in tests/ | Visual-regression | art-craft-review |
| `src/*.js` with `new AudioContext` or `canvas.getContext` | Browser game surface | gameplay-matrix, art-craft-review |
| `snippets/`, `levels/`, `content/`, `sprites/`, `audio/` dirs | Content pool | pipeline-contract-audit (audit-map likely) |
| Existing `GDLC.md` at project root | Prior case study | skill-only install |
| Existing `.claude/skills/gdlc/SKILL.md` (already there from CLI) | Wizard installed | expected; proceed |
| `.claude/skills/sdlc-wizard/` or `.claude/skills/setup/` | SDLC wizard installed | compatible peer; note it |
| `CLAUDE.md` present | Project has AI instructions | note it; do not overwrite |

For `package.json` dep checks, **parse the JSON with `jq`** rather than top-level grep — script entries like `"test:watch": "vitest"` will false-positive on a regex such as `grep -E '"(vitest|jest|mocha)"'`. Use:

```bash
jq -r '.devDependencies // {}, .dependencies // {} | keys[]' package.json | \
  grep -E '^(vitest|jest|mocha|playwright|@playwright/test)$' || true
```

Other scans use `ls`, `Glob`, and `Grep` — no destructive operations.

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

### step-4 — Verify the Skill Suite

The CLI already installed the four skills under `.claude/skills/`. Verify they match the published templates:

```bash
npx claude-gdlc-wizard check
```

Every managed skill file should report MATCH. If any reports CUSTOMIZED / MISSING / DRIFT, surface to the user — for fresh installs this should never happen, so it indicates either a partial install or a customized fork. For the latter, redirect to `/gdlc-update` to triage.

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

Skip if argument is `skill-only`. Otherwise, decide based on the current state of `GDLC.md` at the project root:

| State | Detection | Action |
|-------|-----------|--------|
| Absent | `GDLC.md` does not exist | Write the case-study stub from the template (fresh-install path). |
| Empty stub | `GDLC.md` exists AND is zero-byte | **Write the case-study stub from the template** — this is the expected `npx claude-gdlc-wizard init` handoff (consistent with step-0.5's `Empty stub → Continue` branch). Do NOT skip; the empty file was created by the CLI specifically so this step would populate it. |
| Non-empty file | `GDLC.md` exists AND is ≥ 1 byte | **Skip writing.** Do NOT overwrite — legacy case studies are sacred; offer to add metadata comments only if missing. |

Detection in bash:
```bash
if [ ! -f GDLC.md ] || [ ! -s GDLC.md ]; then
  # absent OR zero-byte — safe to write the stub
  write_case_study_stub
fi
```

(`test -s FILE` is true only if the file exists AND is non-empty; the negation covers both absent and empty-stub cases.)

When writing, render `GDLC.md` at the project root from the template in `CLAUDE_CODE_GDLC_WIZARD.md` (Case-Study GDLC.md template section). Replace placeholders:

- `<PROJECT_NAME>` — user's answer from step-3.
- `<VERSION_FROM_CHANGELOG>` — topmost version from the CHANGELOG fetched in step-0.2.
- `<SHORT_SHA>` — the source ID captured in step-0.2.
- `<YYYY-MM-DD>` — today's date.
- `<DETECTED_OR_USER_CONFIRMED_SURFACES>` — from step-3. Comma-separated list.
- `<DETECTED_HARNESS_OR_...>` — from step-1 detections.

### step-5.5 — Link Surrounding Playbooks

After scaffolding the case-study body, detect project-local playbooks at the repo root and append a `## Related playbooks` section to `GDLC.md`. This gives readers a breadcrumb from the case study to the project's TDD philosophy, visual-style rules, and AI instructions.

**Detection set** (root only — do not recurse):

| Filename | Linked-as | Notes |
|----------|-----------|-------|
| `ARTSTYLE.md` | Visual-style playbook | Color, typography, motion, asset-quality rules |
| `TESTING.md` | Testing strategy | Diamond/pyramid, fixtures, mocking philosophy, suite index |
| `CLAUDE.md` | AI instructions | Project-specific Claude Code guidance, commands, conventions |
| `ARCHITECTURE.md` | System architecture | Component boundaries, deployment topology |
| `SDLC.md` | SDLC discipline | Hooks, enforcement, version tracking |
| `BRANDING.md` | Brand voice + naming | Tone, terminology, content style |
| `DESIGN_SYSTEM.md` | Design tokens | Colors, fonts, spacing, component patterns |

For each that exists, append a bullet of the form:
```markdown
- [<Title>](<filename>) — <one-line purpose>
```

**Append rules:**
- If a `## Related playbooks` header already exists in `GDLC.md`, leave the section alone (idempotent — `/gdlc-update` re-runs safely). The detection MUST be **case-insensitive and whitespace-tolerant** so that hand-edited variants (`## related playbooks`, `##  Related Playbooks`, trailing spaces) are recognised — otherwise the skill duplicates the section every run.

  Use this regex:
  ```bash
  if grep -qE '^##[[:space:]]+[Rr]elated[[:space:]]+[Pp]laybooks[[:space:]]*$' GDLC.md; then
    # already linked — skip
    exit 0
  fi
  ```

  (Case-insensitive on `R` and `P`, one-or-more spaces between tokens, optional trailing whitespace, anchored to start and end of line — covers every reasonable hand-typed variation while rejecting accidental matches inside prose.)
- If no playbooks are detected, skip the section entirely (don't add an empty header).
- Section goes at the bottom of the case-study body, before any closing footer.
- Skip silently on `skill-only` (no case-study body to append to).

This is purely additive — never modifies existing `GDLC.md` content, only appends a section if absent.

### step-6 — Write Metadata

The metadata comments from the template are already filled. Verify the full five-line canonical block appears in `GDLC.md` header:

```markdown
<!-- GDLC Wizard Version: <VERSION_FROM_CHANGELOG> -->
<!-- GDLC Sibling SHA: <SHORT_SHA> -->
<!-- GDLC Setup Date: <YYYY-MM-DD> -->
<!-- GDLC Last Update: <YYYY-MM-DD> -->
<!-- Completed Steps: step-0.1, step-0.2, step-0.5, step-1, step-2, step-3, step-4, step-5, step-5.5, step-6, step-7 -->
```

On initial install `GDLC Last Update` equals `GDLC Setup Date`. `/gdlc-update` bumps `Last Update` on every subsequent update while preserving `Setup Date`. The `Sibling SHA` field name is preserved for backward compatibility — its value is now the source ID (npm version, optionally suffixed with git SHA) rather than a sibling-repo SHA, but the label is stable.

If the user skipped step-5 (skill-only install), there is no case-study `GDLC.md` to write into — skip this step silently. Skill-only consumers rely on `/gdlc-update` running `npx claude-gdlc-wizard check` instead of reading metadata.

### step-7 — Verify

Confirm:
- All four skill files (`gdlc`, `gdlc-setup`, `gdlc-update`, `gdlc-feedback`) exist under `.claude/skills/` and `npx claude-gdlc-wizard check` reports MATCH for each.
- `.gdlc/feedback-log.md` exists (unless `skill-only`) with the header row.
- `.gdlc/feedback-drafts/` is listed in `.gitignore` (unless `skill-only`).
- `GDLC.md` at project root exists (unless `skill-only`) and contains the expected metadata comments.
- `/gdlc`, `/gdlc-setup`, `/gdlc-update`, and `/gdlc-feedback` are discoverable.

Final report:

```
GDLC v<VERSION> installed.
  skills:     .claude/skills/{gdlc, gdlc-setup, gdlc-update, gdlc-feedback}/SKILL.md (source <source-id>)
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
3. **Never copy the playbook into the consumer project.** Reference it via `claude-gdlc-wizard`'s `GDLC.md` (WebFetch); do not vendor it.
4. **Record the source ID in metadata.** `/gdlc-update` uses it to compute rule-diffs and detect stale installs.
5. **Fall back cleanly.** Wizard install missing → tell user to run `npx claude-gdlc-wizard init`. Existing install → redirect to `/gdlc-update`.
6. **Match SDLC's confidence-driven principle.** The bar is: fewest-possible user prompts, all detection surfaced transparently, user always knows what was inferred vs confirmed.

## Failure Modes

- **Wizard install missing** — stop; tell user to run `npx claude-gdlc-wizard init`.
- **Consumer isn't a git repo** — GDLC expects commits per cycle. Stop and ask user to `git init` first.
- **Existing `.claude/skills/gdlc/SKILL.md` reports CUSTOMIZED in step-4** — redirect to `/gdlc-update` to triage.
- **Existing `.gdlc/feedback-log.md` (not empty)** — leave it alone; this is the append-only traceability log and overwriting it destroys history.
- **Existing `.gdlc/feedback-log.md` (empty / header-only)** — safe to leave; idempotent scaffold logic skips re-creation.
- **Existing `GDLC.md` without metadata comments** — legacy install; offer to add metadata in place, keep body untouched, mark as `step-6` complete.
