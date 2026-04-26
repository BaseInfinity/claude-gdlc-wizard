# Preflight Self-Review — v0.2.1 Skill Behavioral Migration

**Date:** 2026-04-25
**Branch:** `main` (uncommitted; last commit `90381e4`)
**Scope:** Migrate the four `/gdlc*` skills + CLI + supporting docs from `~/gdlc/` runtime references to project-local + `npx claude-gdlc-wizard check` + WebFetch flows. Bump version `0.2.0 → 0.2.1`.

## What changed (file-by-file)

### Skills — all 4 migrated

- `skills/gdlc-feedback/SKILL.md` — issue tracker repo `BaseInfinity/gdlc` → `BaseInfinity/claude-gdlc-wizard` (5 sites: description, gh repo view, gh issue create, gh issue view, failure-mode messages); wizard-doc read path moved to project-root `CLAUDE_CODE_GDLC_WIZARD.md`; sibling-clone fallback removed; anti-goal #1 wording updated.
- `skills/gdlc-update/SKILL.md` — full rewrite. step-2 "Pull Sibling Repo" → "Fetch Latest CHANGELOG" (WebFetch). step-5 drift detection delegates to `npx claude-gdlc-wizard check`. step-7 apply path uses `npx claude-gdlc-wizard init --force`. step-8 source-ID semantics documented (npm version + optional git SHA). All `~/gdlc/` references gone (was 16 sites).
- `skills/gdlc-setup/SKILL.md` — full rewrite. step-0.2 "Verify Sibling Repo" → "Verify Wizard Install" (checks the CLI-installed surface). step-4 "Copy the Skill Suite" → "Verify the Skill Suite" via `npx claude-gdlc-wizard check`. Source-ID capture from `npx claude-gdlc-wizard --version` (with optional git-SHA suffix). Failure modes / rules updated. All `~/gdlc/` references gone (was 15 sites + 2 `BaseInfinity/gdlc`).
- `skills/gdlc/SKILL.md` — playbook reference updated to upstream WebFetch URL (`https://raw.githubusercontent.com/BaseInfinity/claude-gdlc-wizard/main/GDLC.md`). 5 site-edits: description line, TaskCreate step list (2 entries), generalize-rule note, References section.

### CLI / install surface

- `cli/init.js` — post-install instruction list shortened from 4 steps to 3; "Clone the sibling playbook" line removed.
- `cli/templates/settings.json` — unchanged.
- `hooks/` — unchanged.
- `install.sh` — unchanged.

### Manifests

- `package.json` — version `0.2.0` → `0.2.1`. `bugs.url` flipped from `BaseInfinity/gdlc/issues` to `BaseInfinity/claude-gdlc-wizard/issues`.
- `.claude-plugin/plugin.json` — version `0.2.0` → `0.2.1`.
- `.claude-plugin/marketplace.json` — version `0.2.0` → `0.2.1`.

### Docs

- `CLAUDE_CODE_GDLC_WIZARD.md` — rewrite: URLs table now points at `BaseInfinity/claude-gdlc-wizard/main/`; Distribution model adds Path A consolidation (v0.2.0) + skill behavioral migration (v0.2.1) sections; Managed-files table reflects CLI ownership; Version-tracking semantics for `Sibling SHA` (preserved field name, source-ID semantics); Setup + Update step registries updated to reflect new flows; Rules `Never read from a sibling repo at runtime` added. All `~/gdlc/` and `BaseInfinity/gdlc` legacy references removed (was 26 sites).
- `README.md` — Status banner bumped to v0.2.1; transitional sibling-clone prerequisite section removed; issue-tracker links flipped to `BaseInfinity/claude-gdlc-wizard` (2 sites). Historical "Originally extracted from BaseInfinity/gdlc" line preserved as accurate provenance with deprecation pointer.
- `CLAUDE.md` — "Pending v0.2.x cleanup" paragraph flipped to "Skill behavioral migration shipped in v0.2.1"; assertion count `96 → 99` (3 places); skill-contract suite count `21 → 24`; ROADMAP path `~/gdlc/ROADMAP.md` → `ROADMAP.md`.
- `ARCHITECTURE.md` — system-overview ASCII diagram updated (no sibling block); skills section says skills run inside consumer + WebFetch upstream; Path A "Pending transitional state" replaced with "Skill behavioral migration (v0.2.1)" section; references list `~/gdlc/ROADMAP.md` → `ROADMAP.md`; assertion count 96 → 99.
- `TESTING.md` — skill-contracts suite count `21 → 24` + behavior summary updated; "skills read `~/gdlc/`" wording flipped to "skills WebFetch the upstream playbook"; v0.2.1 forbidden-pattern bullet added.
- `CHANGELOG.md` — new `[0.2.1] — 2026-04-25` entry: Changed (skills, CLI, README, wizard doc, manifests), Added (3 forbidden-pattern tests), Migration notes. Existing v0.2.0 + v0.1.0 entries preserved verbatim.

### Tests

- `tests/test-skill-contracts.sh` — added 3 new assertions:
  - `test_no_skill_references_legacy_gdlc_path` — fails if any of the 4 skills still contains `~/gdlc/`.
  - `test_no_skill_references_legacy_repo` — fails if any skill contains `BaseInfinity/gdlc` (regex `BaseInfinity/gdlc([^-]|$)` so `claude-gdlc-wizard` substring doesn't false-positive).
  - `test_wizard_doc_no_legacy_paths` — same forbidden-pattern check applied to `CLAUDE_CODE_GDLC_WIZARD.md`.
- `tests/test-skill-contracts.sh::test_update_prefers_local_sibling_over_fetch` renamed/repurposed → `test_update_uses_npx_check_for_drift` — flips assertion from "must reference `~/gdlc/`" to "must reference `npx claude-gdlc-wizard check`".

Net assertion count: 96 → 99 (+3).

## Self-checks performed

- [x] **TDD RED demonstrated.** Ran `tests/test-skill-contracts.sh` after adding the 3 new tests + flipped assertion BEFORE migrating skills. Captured output: `Passed: 20  Failed: 4` — failure messages included specific reference counts (`Skills still contain 40 ~/gdlc/ reference(s)` etc.). RED is the canonical TDD anchor.
- [x] **All 5 suites pass post-migration.** Final run: cli=24, hooks=13, install-script=18, plugin=20, skill-contracts=24 → total 99 passed, 0 failed.
- [x] **Forbidden-pattern grep is exhaustive.** `grep -nE "~/gdlc/|BaseInfinity/gdlc([^-]|$)" skills/ CLAUDE_CODE_GDLC_WIZARD.md` returns no matches.
- [x] **Version parity across 4 manifests.** `package.json::version`, `.claude-plugin/plugin.json::version`, `.claude-plugin/marketplace.json::plugins[0].version`, and `CHANGELOG.md` topmost `## [0.2.1]` all read `0.2.1`.
- [x] **Hooks/ directory restored before measurement.** `git checkout -- hooks/` clears the session-quirk wipe before each test run.
- [x] **Wizard-doc + skill metadata block parity.** `test_setup_metadata_block_matches_wizard_doc` (existing assertion) passes — both files keep the canonical 5-line block byte-for-byte.

## Known limitations / non-goals

- **Field name `Sibling SHA` retained.** The label is a misnomer post-Path-A but keeping it preserves backward compat with existing case-study `GDLC.md` files (e.g., codeguesser). The semantic change is documented in the wizard doc's Version-tracking section. A future major could rename to `Source SHA`.
- **Existing v0.2.0 consumers' `~/gdlc/` clones become orphaned.** Not deleted automatically. Consumers can `rm -rf ~/gdlc/` after running `/gdlc-update` once. Documented in CHANGELOG migration notes.
- **`BaseInfinity/gdlc` GitHub-archive not yet executed.** Still gated on user authorization. Not part of this commit's scope.
- **Historical "Originally extracted from BaseInfinity/gdlc" line in `README.md::Status` retained intentionally.** Provenance is accurate; line points at `DEPRECATED.md` for follow-through. Not a forbidden-pattern violation (test scopes are skills/ + wizard doc only).
- **`gdlc-update` step-7 leans on `npx claude-gdlc-wizard init --force`'s smart-merge.** That logic exists today (`cli/init.js::mergeSettings`) and is exercised by `tests/test-cli.sh`. No new code required.

## Files I asked the reviewer to verify (top-of-mind)

1. `skills/gdlc-update/SKILL.md` — biggest behavioral change. Read the full step list end-to-end; flag any logical gap where a v0.2.0 consumer who runs `/gdlc-update` could land in an inconsistent state.
2. `tests/test-skill-contracts.sh::test_no_skill_references_legacy_repo` regex — verify `BaseInfinity/gdlc([^-]|$)` actually catches the deprecated form without false-positiving on `BaseInfinity/claude-gdlc-wizard`.
3. `CLAUDE_CODE_GDLC_WIZARD.md` Version-tracking section — does the description of `Sibling SHA` semantics cleanly explain the npm-vs-git-clone source-ID dichotomy?
4. `package.json::files` array — confirm hooks + skills + cli + .claude-plugin + 3 markdown files all ship; no missing artifact.
