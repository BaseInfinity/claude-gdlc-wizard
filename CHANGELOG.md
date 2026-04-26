# Changelog

This file tracks the **distribution wizard** (CLI, plugin, hooks, install scripts). For the **framework playbook** (GDLC.md rules, playtests, skill versions, earned-rule history) see [`PLAYBOOK_CHANGELOG.md`](./PLAYBOOK_CHANGELOG.md).

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.2] — 2026-04-26

**Issue-fix release.** Bundles the four playbook gaps surfaced by the codeguesser case study (issues #1, #3, #4) and the dogfooding finding from the codeguesser dual-install (issue #5).

### Fixed
- **Issue #1 — `gdlc-setup` test-harness detection false-positives on script names.** Step-1 detection table now scopes `vitest`/`jest`/`mocha`/`playwright` lookups to `package.json` `devDependencies`/`dependencies` blocks (not top-level grep). Added jq-based detection block that parses dependency keys correctly. Regression test: `test_setup_step_1_test_harness_detection_scoped_to_deps`.
- **Issue #3 — `gdlc-setup` lacked existing-install early-redirect.** Added `step-0.5` that checks for an existing wizard-managed `GDLC.md` (via `<!-- (GDLC )?Wizard Version:` metadata comment) before any auto-scan or file write. Three-branch logic: managed install → STOP and redirect to `/gdlc-update`; legacy unmanaged → STOP and ASK (backup, treat-as-legacy, or abort); empty stub or absent → continue with fresh setup. Prevents the codeguesser-class bug where pre-wizard `GDLC.md` could be silently overwritten. Regression tests: `test_setup_existing_install_early_redirect`, `test_setup_existing_install_redirect_before_writes`.
- **Issue #4 — case-study template lacked project-playbook auto-linkage.** Added `step-5.5` to `gdlc-setup`: detects root-level `ARTSTYLE.md`, `TESTING.md`, `CLAUDE.md`, `ARCHITECTURE.md`, `SDLC.md`, `BRANDING.md`, `DESIGN_SYSTEM.md`. For each present, appends a bullet to a `## Related playbooks` section in `GDLC.md`. Idempotent (skips if section exists or no playbooks detected). Skipped silently on `skill-only`. Regression tests: `test_setup_links_surrounding_playbooks`, `test_wizard_doc_documents_playbook_linkage`.
- **Issue #5 — hook filename collision with `claude-sdlc-wizard`.** Renamed `hooks/instructions-loaded-check.sh` → `hooks/gdlc-instructions-loaded-check.sh` (with `git mv` preserving history). Updated `hooks/hooks.json`, `cli/init.js`, `cli/templates/settings.json`, all test files, and skill/architecture docs to reference the namespaced basename. Whichever wizard installed second was previously silently overwriting the other's `instructions-loaded-check.sh` since both wizards target `.claude/hooks/`. Regression tests: `test_no_hook_filename_collisions_with_sdlc`, `test_hooks_json_uses_namespaced_basenames`, `test_cli_settings_template_uses_namespaced_basenames`.

### Changed
- **Step registry** updated in `CLAUDE_CODE_GDLC_WIZARD.md`: setup gains `step-0.5` (existing-install redirect) and `step-5.5` (playbook linkage). Completed-steps metadata block bumped to reflect the new step IDs.

### Added
- **13 new contract / CLI regression tests** (whole-suite total 102 → 115):
  - **10 new contract tests** in `tests/test-skill-contracts.sh` (27 → 37 assertions): per-issue regression coverage for the four fixes above (#1, #3, #4, #5) plus three Codex-round-1 findings — zero-byte `GDLC.md` stub handling (Finding 2), step-5.5 idempotency tolerant header detection (Finding 3), and namespace-collision contracts.
  - **3 new CLI tests** in `tests/test-cli.sh` (24 → 27 assertions): legacy hook migration regressions — `init --force` removes legacy `instructions-loaded-check.sh`, replaces (not appends) the legacy `InstructionsLoaded` settings entry, and `check` flags legacy disk artifacts as DRIFT (Codex Finding 1, P1).

### Migration notes
- Existing v0.2.1 consumers can upgrade with `/gdlc-update` or `npx claude-gdlc-wizard init --force`. The hook rename is automatic via the install path; the legacy `instructions-loaded-check.sh` will be removed by `init --force` (drift detection flags it as DRIFT, regardless of `--force` — see `cli/init.js::isLegacyHookEntry` and `LEGACY_HOOK_FILES`). The CLI also strips legacy entries from `.claude/settings.json` `InstructionsLoaded` regardless of `--force`. If users have customized the legacy hook, `/gdlc-update` will surface that as CUSTOMIZED for explicit per-file decision before the CLI rewrites the hook.

## [0.2.1] — 2026-04-25

**Skill behavioral migration to local-repo paths.** The transitional `~/gdlc/` clone is no longer required. Skills are fully self-contained via the wizard CLI + WebFetch.

### Changed
- **`gdlc-update`** — drift detection delegates to `npx claude-gdlc-wizard check` instead of `diff -q ~/gdlc/.claude/skills/...`. CHANGELOG / playbook fetch via WebFetch from `raw.githubusercontent.com/BaseInfinity/claude-gdlc-wizard/main/`. Apply path is now **per-file WebFetch + Write** (one Write per "adopt latest" decision) so "keep mine" decisions stay no-ops. `.claude/settings.json` keeps an in-skill JSON merge that mirrors `cli/init.js::mergeSettings` semantics. `check-only` always runs through step-5 drift detection — never short-circuits on version-match.
- **`gdlc-feedback`** — issue tracker repo: `BaseInfinity/gdlc` → `BaseInfinity/claude-gdlc-wizard`. Wizard doc read from `CLAUDE_CODE_GDLC_WIZARD.md` at consumer project root (CLI installs it there). Managed-files table updated: `gdlc-feedback/SKILL.md` now noted as installed by the CLI (not "verbatim from sibling").
- **`gdlc-setup`** — sibling-clone prerequisite removed. Step 0.2 now delegates the full-surface verification to `npx claude-gdlc-wizard check` (covers settings.json + 3 hooks + 4 skills + wizard doc in one shot, matches `cli/init.js::FILES`). Source ID captured from `npx claude-gdlc-wizard --version` (with optional git-SHA suffix when a local clone is present).
- **`gdlc`** — playbook reference updated to the upstream raw URL (WebFetch); legacy `~/gdlc/GDLC.md` references removed.
- **`cli/init.js`** — post-install message no longer suggests `git clone https://github.com/BaseInfinity/gdlc ~/gdlc`. Step list shortened from 4 to 3.
- **`README.md`** — transitional sibling-clone prerequisite section removed. Issue-tracker links updated to `BaseInfinity/claude-gdlc-wizard`.
- **`CLAUDE_CODE_GDLC_WIZARD.md`** — URLs table, managed-files table, version-tracking, step registries, and rules all updated to reflect single-repo flow. Field name `Sibling SHA` preserved for backward compatibility (semantics: source ID = npm version, optionally suffixed with git SHA).
- **`package.json` `bugs.url`** — points at `BaseInfinity/claude-gdlc-wizard/issues`.

### Added
- **6 new contract tests** in `tests/test-skill-contracts.sh` (21 → 27 assertions; whole-suite total 96 → 102):
  - 3 forbidden-pattern: no skill or wizard-doc reference to `~/gdlc/`; no skill reference to deprecated `BaseInfinity/gdlc` (regex `BaseInfinity/gdlc([^-]|$)` — `claude-gdlc-wizard` is allowed).
  - 3 regression assertions covering the round-1 review findings: gdlc-update step-7 must document "keep mine" as a no-op (Finding 1); `check-only` must run through drift even when version matches latest (Finding 2); gdlc-setup step-0.2 must delegate full-surface verification to the CLI's `check` (Finding 3).

### Migration notes
- Existing v0.2.0 consumers can upgrade with `/gdlc-update` (or `npx claude-gdlc-wizard init --force`). Their `~/gdlc/` clone becomes unused but harmless; safe to delete.
- `BaseInfinity/gdlc` GitHub-archive remains gated on user authorization. With the migration shipped, no functional consumer dependency remains on that repo.

## [0.2.0] — 2026-04-25

**Path A consolidation.** Framework playbook moved into this repo. `~/gdlc/` is deprecated; `BaseInfinity/gdlc` will be archived after consumer-side skills are migrated to local-path reads. Same single-repo pattern SDLC uses (`claude-sdlc-wizard` is the only SDLC repo — there's no `~/sdlc/` framework repo).

### Added
- `GDLC.md` — playbook content moved from `~/gdlc/GDLC.md` (264 lines, the canonical case-study + rules + cycles + personas reference).
- `ROADMAP.md` — Phase 1/2/3 distribution roadmap moved from `~/gdlc/ROADMAP.md`. Phase 1 now closed (CERTIFIED 2026-04-25); Phases 2-3 pending.
- `FEEDBACK_SKILL_SPEC.md` — feedback-skill design spec moved from `~/gdlc/FEEDBACK_SKILL_SPEC.md`.
- `PLAYBOOK_CHANGELOG.md` — framework changelog moved from `~/gdlc/CHANGELOG.md`. Tracks rule-version history, playtest cycles, skill-version bumps. Distinct from this file (which tracks distribution-wizard releases).

### Pending (next minor)
- Skills' `~/gdlc/` references (drift-detection logic in `gdlc-update`, fetch URLs in `gdlc-feedback`, `diff -q` parity checks) need migration to local-repo paths. Held until a Codex round green-lights the consolidation.
- `BaseInfinity/gdlc` archive on GitHub: gated on user authorization after the skill migration lands.

## [0.1.0] — 2026-04-23

**Initial extraction.** Forked from [BaseInfinity/gdlc](https://github.com/BaseInfinity/gdlc) v0.4.1.

### Added
- Plugin manifest at `.claude-plugin/plugin.json` (name: `gdlc-wizard`)
- 4 skills ported from upstream:
  - `skills/gdlc/SKILL.md` — main playtest cycle picker
  - `skills/gdlc-setup/SKILL.md` — conversational setup wizard (auto-scan, confidence-driven)
  - `skills/gdlc-update/SKILL.md` — CHANGELOG diff + drift detection + per-file apply
  - `skills/gdlc-feedback/SKILL.md` — structured upstream feedback with stock GitHub labels
- `CLAUDE_CODE_GDLC_WIZARD.md` — canonical wizard doc (copied from `~/gdlc/`)
- `README.md` — consumer-facing install and overview

### Distribution channels shipped (v0.1.0)
- **CLI** — `cli/bin/gdlc-wizard.js` with `init`, `init --dry-run`, `init --force`, `check`, `--help`, `--version`. Installs the 4 skills + 2 hooks + helper + settings + wizard doc into a consumer project.
- **Plugin** — `.claude-plugin/plugin.json` + `.claude-plugin/marketplace.json` for the Claude Code plugin system. `hooks/hooks.json` registers events with `${CLAUDE_PLUGIN_ROOT}`; CLI uses `$CLAUDE_PROJECT_DIR`. Event parity enforced by `tests/test-plugin.sh`.
- **`curl | bash`** — `install.sh` with strict mode + download guard, points at `npx -y claude-gdlc-wizard`. Live-install test gated by `CLAUDE_GDLC_WIZARD_NPM_PUBLISHED=1` until the package lands on npm.
- **2 hooks + 1 helper** — `gdlc-prompt-check.sh` (UserPromptSubmit), `instructions-loaded-check.sh` (InstructionsLoaded), `_find-gdlc-root.sh` (sourced helper). 94 quality-test assertions across 5 bash suites enforce contract behavior, not existence.

### Known limitations (v0.1.0)
- **npm package not yet published** — `package.json` is ready; `npx claude-gdlc-wizard init` works locally via `node cli/bin/gdlc-wizard.js`. Publishing pending Phase 1 distribution-channel ramp.
- **Homebrew tap and gh CLI extension not shipped** — Phase 3 deliverables, separate repos (`homebrew-gdlc-wizard`, `gh-gdlc-wizard`).
- **Sibling dependency retained** — skills read `~/gdlc/` for playbook content (GDLC.md, CHANGELOG, FEEDBACK_SKILL_SPEC.md). Path A consolidation (bundle the playbook into this repo) is under user consideration; default for v0.1.0 is Path B (sibling kept).
- **Case study #2 not yet logged** — consumed by codeguesser (case #1) + in progress with pdlc/TamAGI. Formal graduation criteria met in spirit; the formal "Adoption without modification" + "earned rule from case study #2" log entries land when PDLC/TamAGI runs through the suite end-to-end.
