# Changelog

All notable changes to `claude-gdlc-wizard` will be documented in this file.

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning: [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
