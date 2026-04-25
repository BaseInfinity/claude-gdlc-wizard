# Claude Code GDLC Wizard

This is the source-of-truth wizard doc for the GDLC playbook + skill. Both `/gdlc-setup` and `/gdlc-update` MUST read this doc before acting. It contains the step registry, URLs, managed-files list, version tracking format, and the case-study template.

## What GDLC is

GDLC (Game Development Lifecycle) is the game-quality analog of SDLC. Where SDLC governs code quality (TDD, reviews, CI), GDLC governs game quality — a game must remain fun, fair, readable, and aligned with the personas it targets. GDLC adds persona playtests, surface-class cycle dispatch (gameplay-matrix / art-craft-review / pipeline-contract-audit), cross-method triangulation, and a RED-before-GREEN ratchet.

The `/gdlc` skill is the enforceable form of the playbook (`~/gdlc/GDLC.md`). Consumer projects install the skill plus a case-study `GDLC.md` at their project root — a per-project ratchet ledger + earned-rules log.

## Distribution model

GDLC ships through `BaseInfinity/claude-gdlc-wizard`. Four parallel install channels — same surface (4 skills + 2 hooks + helper + settings.json + this wizard doc) lands either way:

1. **`npx claude-gdlc-wizard init`** — Node CLI (preferred). Idempotent, supports `--dry-run` / `--force` / `check`.
2. **`curl -fsSL .../install.sh | bash`** — wraps the npx flow with strict mode + Node ≥ 18 preflight.
3. **Claude Code plugin** — install via the plugin marketplace using `.claude-plugin/plugin.json`. Hooks resolve through `${CLAUDE_PLUGIN_ROOT}` instead of `$CLAUDE_PROJECT_DIR`.
4. **Manual git clone + `node cli/bin/gdlc-wizard.js init`** — fallback when Node is unavailable in PATH.

The skills still read playbook content from a sibling `~/gdlc/` repo (mirror of `BaseInfinity/gdlc`). Path A (consolidate the playbook into this distribution repo) is under user consideration; Path B (sibling kept) is the v0.1.0 default — framework updates flow through `~/gdlc/` independently of wizard releases.

**Sibling repo prerequisite.** Both setup and update assume `~/gdlc/` exists and is on a clean working tree. If missing:

```bash
git clone https://github.com/BaseInfinity/gdlc ~/gdlc
```

If dirty: user must commit or stash in `~/gdlc/` before running setup or update.

## URLs (source of truth)

| Asset | URL |
|-------|-----|
| CHANGELOG | `https://raw.githubusercontent.com/BaseInfinity/gdlc/main/CHANGELOG.md` |
| Playbook | `https://raw.githubusercontent.com/BaseInfinity/gdlc/main/GDLC.md` |
| Skill | `https://raw.githubusercontent.com/BaseInfinity/gdlc/main/.claude/skills/gdlc/SKILL.md` |
| Wizard doc (this file) | `https://raw.githubusercontent.com/BaseInfinity/gdlc/main/CLAUDE_CODE_GDLC_WIZARD.md` |

Update prefers the **local sibling** at `~/gdlc/` over fetching — it's faster and always consistent with the skill pair. The URLs are the fallback when the sibling is missing or stale.

## Managed files

The wizard manages these files in the consumer project:

| Path | Source | Overwrite policy |
|------|--------|------------------|
| `.claude/skills/gdlc/SKILL.md` | `~/gdlc/.claude/skills/gdlc/SKILL.md` (verbatim copy) | Overwrite with diff approval on CUSTOMIZED |
| `.claude/skills/gdlc-setup/SKILL.md` | `~/gdlc/.claude/skills/gdlc-setup/SKILL.md` (verbatim copy) | Overwrite with diff approval on CUSTOMIZED |
| `.claude/skills/gdlc-update/SKILL.md` | `~/gdlc/.claude/skills/gdlc-update/SKILL.md` (verbatim copy) | Overwrite with diff approval on CUSTOMIZED |
| `.claude/skills/gdlc-feedback/SKILL.md` | `~/gdlc/.claude/skills/gdlc-feedback/SKILL.md` (verbatim copy) | Overwrite with diff approval on CUSTOMIZED |
| `GDLC.md` (case-study stub at project root) | Generated from the case-study template below | **Never overwrite** — project's ratchet ledger is sacred |
| `.gdlc/feedback-log.md` | Scaffolded empty by `/gdlc-setup`; migrated in by `/gdlc-update` for pre-v0.4.0 consumers | **Append-only** — never rewritten. `/gdlc-feedback` appends one row per filed issue |
| `.gdlc/feedback-drafts/` (gitignore entry) | Appended to `.gitignore` by setup / update | Transient recovery for cancelled `/gdlc-feedback` flows; never committed |

The playbook itself (`~/gdlc/GDLC.md`) is referenced but **not** vendored into consumer projects. A stale vendored copy is worse than a live reference.

## Version tracking

The consumer project's case-study `GDLC.md` tracks install state via metadata comments in its header:

```markdown
<!-- GDLC Wizard Version: X.Y.Z -->
<!-- GDLC Sibling SHA: <short-sha> -->
<!-- GDLC Setup Date: YYYY-MM-DD -->
<!-- GDLC Last Update: YYYY-MM-DD -->
<!-- Completed Steps: step-1, step-2, ... -->
```

- **Version** — the wizard/playbook semver at the time of install/update. Compared against the CHANGELOG's topmost version to decide whether an update is needed.
- **Sibling SHA** — the exact `~/gdlc/` commit the skill was copied from. Used for drift detection and for generating rule-diff summaries in `/gdlc-update`.
- **Setup Date / Last Update** — human-readable breadcrumbs; not load-bearing but useful in audits.
- **Completed Steps** — which wizard steps have been run. Allows `/gdlc-setup regenerate` and `/gdlc-update` to know what's already been done.

## Staying updated (idempotent wizard)

Both skills are idempotent — running them twice with the same inputs produces the same result. `/gdlc-update check-only` is safe to run unattended; `/gdlc-update apply` requires user confirmation for every CUSTOMIZED or DRIFT file.

Update flow:
1. Read installed version + sibling SHA from case-study `GDLC.md` metadata.
2. Prefer local: `git -C ~/gdlc pull --ff-only` (fallback to WebFetch if sibling missing).
3. Read latest `CHANGELOG.md` (local or raw URL).
4. Present rule-diff between installed version and latest — what earned rules are new.
5. Run per-file drift detection against `~/gdlc/`.
6. Per-file: MATCH (skip) / MISSING (install) / CUSTOMIZED (ask) / DRIFT (investigate).
7. Apply approved updates; bump version metadata; verify.

## Setup step registry

The `/gdlc-setup` skill runs these steps in order. Completed step IDs are tracked in the consumer project's case-study `GDLC.md` metadata.

| ID | Name | What it does | Asks user? |
|----|------|--------------|------------|
| step-0.1 | Read wizard doc | Load this file (mandatory first action) | No |
| step-0.2 | Verify sibling repo | `test -f ~/gdlc/GDLC.md && test -f ~/gdlc/.claude/skills/gdlc/SKILL.md` | No |
| step-1 | Auto-scan consumer project | Detect: test harness (vitest/jest), e2e (playwright), visual-regression harness, Canvas/Audio APIs, existing `GDLC.md`, `.claude/` directory | No |
| step-2 | Confidence map | Classify each data point: RESOLVED-detected / RESOLVED-inferred / UNRESOLVED | No |
| step-3 | Present findings + ask unresolved | Show detected values for bulk confirmation; ask only what couldn't be inferred | Yes (only unresolved) |
| step-4 | Copy skill suite | Copy all four skills verbatim: `gdlc`, `gdlc-setup`, `gdlc-update`, `gdlc-feedback` | No |
| step-5 | Scaffold case-study stub + `.gdlc/` | Generate `GDLC.md` from the template below; create `.gdlc/feedback-log.md` header row; append `.gdlc/feedback-drafts/` to `.gitignore` | No (unless stub already exists) |
| step-6 | Write metadata | Insert version, sibling SHA, setup date, completed steps into the case-study header | No |
| step-7 | Verify | All four skills diff-clean vs sibling; `.gdlc/feedback-log.md` present; case-study valid; all four skills discoverable | No |

**Arguments:**
- `(none)` — full first-install flow.
- `regenerate` — re-run steps 4, 6, and 7 using existing metadata. Skip scan, skip user prompts, skip step-5 stub write (do not clobber an existing case-study body).
- `skill-only` — skip step-5 (no case-study stub). Project already has its own GDLC.md or is a skill-only consumer.
- `verify-only` — skip to step-7.

## Update step registry

The `/gdlc-update` skill runs these steps in order.

| ID | Name | What it does |
|----|------|--------------|
| step-0.1 | Read wizard doc | Load this file (mandatory first action) |
| step-1 | Read installed version | Parse metadata comment from consumer's `GDLC.md` |
| step-2 | Pull sibling | `git -C ~/gdlc pull --ff-only` (or WebFetch fallback) |
| step-3 | Read latest CHANGELOG | Parse `~/gdlc/CHANGELOG.md`; fall back to raw URL if sibling unavailable |
| step-4 | Show rule diff | List earned rules added between installed version and latest |
| step-5 | Drift detection | For each of `gdlc`, `gdlc-setup`, `gdlc-update`, `gdlc-feedback`: `diff -q ~/gdlc/.claude/skills/$skill/SKILL.md .claude/skills/$skill/SKILL.md` → MATCH / CUSTOMIZED / MISSING / DRIFT. Also check `.gdlc/feedback-log.md` presence (not diff — append-only, consumer-owned) |
| step-6 | Per-file update plan | Present decisions; ask per-file approval unless `force-all` |
| step-7 | Apply | Overwrite approved skill files; preserve case-study `GDLC.md` always |
| step-7.5 | One-time `.gdlc/` migration | For pre-v0.4.0 consumers: create `.gdlc/feedback-log.md` header if missing; append `.gdlc/feedback-drafts/` to `.gitignore` if absent. Idempotent — no-op on post-v0.4.0 consumers. Never mutates `GDLC.md` body |
| step-8 | Bump metadata | Update version, sibling SHA, last-update date in case-study header |
| step-9 | Verify | All four skills diff-clean vs sibling; `.gdlc/feedback-log.md` present; metadata reflects new state |

**Arguments:**
- `(none)` — full flow with per-file prompts.
- `check-only` — run through step-5, print report, stop. Safe to run unattended.
- `apply` — alias for `(none)`; explicit.
- `force-all` — skip per-file approval and auto-adopt CUSTOMIZED files. DRIFT is still surfaced (user must triage) and MATCH is still skipped. Use only after seeing the drift report.

## Feedback loop

The `/gdlc-feedback` skill surfaces consumer findings upstream to this repo.

**Upstream target:** `BaseInfinity/gdlc`.

### Canonical type → label map

Labels are stock GitHub labels (`bug` / `enhancement` / `question`) — zero setup burden on upstream. Type identifier is preserved as `[<type>]` prefix in issue titles for filter semantics.

| Feedback type | GH label | When to use |
|---------------|----------|-------------|
| `earned-rule-candidate` | `enhancement` | Rule surfaced in consumer case study that might graduate to playbook |
| `playbook-gap` | `enhancement` | Playbook doesn't cover a surface / persona / scenario the consumer hit |
| `playbook-bug` | `bug` | Internal inconsistency, wrong line reference, contradiction between rules |
| `wizard-bug` | `bug` | Setup / update / feedback skill misbehaved |
| `methodology-question` | `question` | Genuine uncertainty about cycle selection, persona choice, triangulation |

### Auto-context allowlist

Every filed issue carries a metadata block from the consumer's `GDLC.md` header. Each field is classified AUTO (attached silently) or CONFIRM (per-field prompt at preview time, defaults to `<redacted>` if declined). Unlisted fields are EXCLUDED.

| Field | Source | Class | Default if redacted |
|-------|--------|-------|---------------------|
| `Installed` (WIZARD_VERSION) | `GDLC.md` metadata | AUTO | — |
| `Sibling SHA` (SHORT_SHA) | `GDLC.md` metadata | AUTO | — |
| `Setup Date` | `GDLC.md` metadata | AUTO | — |
| `Last Update` | `GDLC.md` metadata | AUTO | — |
| `Playtests` | count of `### Playtest #` in `GDLC.md` | AUTO | — |
| `Consumer` (PROJECT_NAME) | `GDLC.md` H1 | CONFIRM | `<redacted>` |
| `Surfaces` | `GDLC.md` Project Surfaces section | CONFIRM | `<redacted>` |

**Privacy invariant:** adding a new field to the auto-context block requires a spec revision. Future releases do NOT automatically promote new metadata fields. Classification must be set explicitly at introduction.

## Case-study GDLC.md template

When `/gdlc-setup` scaffolds a new case-study stub, it writes this file at the consumer project root. Placeholders in `<ANGLE BRACKETS>` are filled from the auto-scan results.

```markdown
# GDLC Case Study — <PROJECT_NAME>

<!-- GDLC Wizard Version: <VERSION_FROM_CHANGELOG> -->
<!-- GDLC Sibling SHA: <SHORT_SHA> -->
<!-- GDLC Setup Date: <YYYY-MM-DD> -->
<!-- GDLC Last Update: <YYYY-MM-DD> -->
<!-- Completed Steps: step-0.1, step-0.2, step-1, step-2, step-3, step-4, step-5, step-6, step-7 -->

## Project Surfaces

This project runs GDLC cycles for: <DETECTED_OR_USER_CONFIRMED_SURFACES>

Persona matrix pruned to cover these surfaces only. Add rows back as new surfaces come online.

## Tooling

- Test harness: <DETECTED_HARNESS_OR_"not detected — add when installed">
- e2e harness: <DETECTED_PLAYWRIGHT_OR_NONE>
- Visual-regression harness: <DETECTED_OR_"deferred until art-craft-review cycle">

## Earned Rules (Project-Specific)

_Rules earned through this project's playtests. When a rule recurs in a second case study, it graduates to `~/gdlc/GDLC.md`._

(none yet — first playtest will populate)

## Playtest Ledger

_Chronological log of playtest cycles. Each entry: date, cycle type, personas, findings, ratchet delta._

### Playtest #1 — _scheduled_

- Cycle: TBD
- Personas: TBD
- Findings: TBD
- Ratchet delta: TBD
- Earned rules: TBD

## Ratchet (Regression Tests)

_Each P0 finding earns a test RED before the fix. P1/P2 entries at author discretion, severity + reason recorded._

| Date | Finding | Persona(s) | Test file + name |
|------|---------|-----------|------------------|

## What's Working

_Methodological patterns that proved themselves across 2+ playtests (playbook rule #28)._

(none yet)

## References

- Playbook: `~/gdlc/GDLC.md`
- Skill: `.claude/skills/gdlc/SKILL.md`
- Wizard: `/gdlc-update` to pull playbook changes
```

## Rules for wizard implementations

1. **Never modify the case-study `GDLC.md`** except to update metadata comments. The body is the project's own ratchet ledger.
2. **Never copy the playbook** (`~/gdlc/GDLC.md`) into the consumer project. Reference it; do not vendor it.
3. **Never touch `~/gdlc/`** from within the consumer project's setup/update flow except to `git pull --ff-only`. Playbook edits happen in the sibling repo.
4. **Respect customizations to the skill.** If `.claude/skills/gdlc/SKILL.md` is CUSTOMIZED, show the diff and get explicit approval before overwriting.
5. **SHA tracking is the source of truth for "last seen playbook".** Don't rely on dates or version strings — SHAs don't lie.
6. **Auto-scan before asking.** Only ask the user what can't be detected or inferred (matches SDLC's confidence-driven principle).
7. **Offline fallback:** if WebFetch fails and `~/gdlc/` is missing, stop and tell the user to clone the sibling repo.
