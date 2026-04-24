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

### Known limitations (v0.1.0)
- **v0 install only** — git clone + manual copy. `npm i -g`, Homebrew tap, `gh` extension, and `curl | bash` installers are planned but not shipped.
- **No CLI binary** — `claude-sdlc-wizard` has `cli/bin/sdlc-wizard.js`; this repo does not ship a CLI yet.
- **No hooks/scripts/tests** — placeholder for future iterations. Quality tests per SDLC's "Prove It Gate" pending.
- **Sibling dependency** — skills expect `~/gdlc/` to exist as a sibling repo for playbook content. Bundling is intentional non-goal per upstream ROADMAP.
- **Not case-study-#2-graduated yet** — consumed by codeguesser (case #1) + in progress with pdlc/TamAGI. Formal graduation criteria met in spirit but not yet formally logged.
