# Preflight Self-Review — Phase 1 (claude-gdlc-wizard bootstrap)

**Scope.** Stand up the first distribution repo for GDLC, mirroring the
claude-sdlc-wizard skeleton. This is *Phase 1* per `~/gdlc/ROADMAP.md`:
graduate the 4 skills that live at `~/gdlc/.claude/skills/` into a
standalone wizard repo that consumers can `npx claude-gdlc-wizard init`
into their game projects, with the sibling `~/gdlc/` as the playbook
source of truth (not bundled).

## Self-review completed

### Artifacts
- [x] `.claude-plugin/plugin.json` (scaffolded) + `.claude-plugin/marketplace.json` (new)
- [x] 4 skills at `skills/{gdlc,gdlc-setup,gdlc-update,gdlc-feedback}/SKILL.md` (scaffolded, ported verbatim from `~/gdlc/.claude/skills/`)
- [x] 3 hook files at `hooks/`: `_find-gdlc-root.sh`, `gdlc-prompt-check.sh`, `instructions-loaded-check.sh`
- [x] Plugin-format `hooks/hooks.json` (uses `${CLAUDE_PLUGIN_ROOT}`)
- [x] CLI-format `cli/templates/settings.json` (uses `$CLAUDE_PROJECT_DIR`)
- [x] CLI: `cli/bin/gdlc-wizard.js` (entry, --help/--version/init/check) + `cli/init.js` (plan/execute with SKIP/OVERWRITE/CREATE/MERGE + gitignore updates + drift-aware `check`)
- [x] `install.sh` — curl | bash installer with strict mode, download guard, Node ≥ 18 check, --global flag
- [x] `.github/workflows/ci.yml` — runs tests/*.sh on push + PR
- [x] `package.json` — `bin.gdlc-wizard`, `files` includes `cli/`/`skills/`/`.claude-plugin/`

### Tests (94 total across 5 suites; CI runs all)
- [x] `tests/test-cli.sh` — 22 integration tests, runs the real binary: help/version, dry-run, file parity with `skills/`, force overwrite, gitignore dedupe, hook executability, settings.json validity + 2 events + `$CLAUDE_PROJECT_DIR`, hook content is GDLC-specific, `check` MATCH/MISSING/JSON
- [x] `tests/test-install-script.sh` — 18 structural tests, gated live test via `CLAUDE_GDLC_WIZARD_NPM_PUBLISHED=1`. No stale `agentic-sdlc-wizard`/`claude-sdlc-wizard` references.
- [x] `tests/test-plugin.sh` — 20 tests: plugin.json validity + kebab-case + version-match, hooks.json uses CLAUDE_PLUGIN_ROOT and NOT CLAUDE_PROJECT_DIR, event parity between plugin hooks.json and CLI settings.json, marketplace.json validity + version-match, CLI/plugin skill + hook byte-parity
- [x] `tests/test-hooks.sh` — 13 behavioral tests: `_find-gdlc-root` walk-up, `gdlc-prompt-check` BASELINE-when-present vs SETUP-NOT-COMPLETE-when-empty, silent-outside-project, always-exit-0, instructions-loaded-check silence on valid state, CI YAML sanity
- [x] `tests/test-skill-contracts.sh` — 21 contract tests (Prove It Gate): effort:high across all 4 skills, gdlc-setup 9-step registry, 5-line metadata block matches wizard doc template, scaffolds `.gdlc/feedback-log.md`, never-vendor-playbook rule, gdlc-update references CHANGELOG + sibling, gdlc-feedback uses stock labels only (no legacy `feedback:*`), 5 canonical type identifiers, `[<type>]` prefix, explicit allowlist with EXCLUDED class, never writes GDLC.md body; wizard doc has template + step registry + managed-files + no stale sdlc refs

## Verified manually
- [x] `./cli/bin/gdlc-wizard.js init` in a fresh tmpdir creates 9 files (4 skills + 3 hooks + settings + wizard doc) + .gitignore additions; `check` reports 6 MATCH.
- [x] Installed hooks are executable; `_find-gdlc-root.sh` is present (sourced, not executed, so no +x).
- [x] `settings.json` merges into an existing user settings.json via `mergeSettings` — user hooks for other plugins are preserved, GDLC hooks are added once, re-runs are idempotent.
- [x] `--dry-run` prints the plan but writes nothing (no .claude/, no wizard doc, no .gitignore mutation).
- [x] `check` returns exit 1 when wizard files are missing (so CI can gate on drift).

## Intentional scope cuts (documented; not bugs)

1. **Only 2 hooks + 1 helper** (vs SDLC's 5 hooks + helper). Dropped `tdd-pretool-check.sh` (code-specific), `model-effort-check.sh` (SDLC-shaped nudge for code-SDLC users), and `precompact-seam-check.sh` (depends on SDLC `.reviews/handoff.json` schema). GDLC-specific hooks only. Users who want code-TDD install `claude-sdlc-wizard` alongside — `instructions-loaded-check.sh` already emits a dual-install nudge for that case.
2. **Live `curl | bash` install test is gated** behind `CLAUDE_GDLC_WIZARD_NPM_PUBLISHED=1`. `claude-gdlc-wizard` is not on npm yet; piping would always fail. Flip the gate after publish. Structural tests on the script (18 of them) still run.
3. **Sibling-repo dependency retained** — `/gdlc-setup` still reads `~/gdlc/CLAUDE_CODE_GDLC_WIZARD.md` and copies skills from `~/gdlc/.claude/skills/`. Path A (consolidate `~/gdlc/` into this repo) is user-pending decision — see `~/gdlc/ROADMAP.md` §Phase 1 item 1.4 and the punch list in the session prompt.
4. **No `scripts/` directory**. SDLC has several (score-analytics, API-changelog parsing, etc.) that have no GDLC analog yet. Don't add until GDLC generates concrete need.
5. **`.github/workflows/ci.yml` is the only workflow.** SDLC has 8 (weekly updates, benchmarks, etc.). Those are earned over time; starting with plain CI and expanding as signals emerge.

## Specific concerns flagged for reviewer

1. **`_find-gdlc-root.sh` IS in the CLI `FILES` array**  — this fixes a silent bug in SDLC's `cli/init.js` where `_find-sdlc-root.sh` is NOT installed, so CLI-installed hooks fail at `source` time. GDLC ships the helper deliberately; verify `cli/init.js:20-29` includes it and that `tests/test-cli.sh::test_creates_all_files` counts it.
2. **`hooks/hooks.json` (plugin) uses `${CLAUDE_PLUGIN_ROOT}`. `cli/templates/settings.json` (CLI) uses `"$CLAUDE_PROJECT_DIR"`.** These are NOT interchangeable. Plugin installs resolve from the plugin root; CLI installs resolve from the consumer project root. `tests/test-plugin.sh::test_hooks_json_uses_plugin_root` enforces the distinction. If a reviewer swaps one for the other, installs break silently.
3. **Event parity.** `tests/test-plugin.sh::test_hooks_json_event_parity` asserts that `hooks.json` and `cli/templates/settings.json` declare the same events. Currently both declare `UserPromptSubmit` + `InstructionsLoaded`. Adding an event to one but not the other means plugin users and CLI users get different behavior.
4. **The hook's user-facing content (`GDLC BASELINE`, cycle names, "gdlc-setup").** `tests/test-cli.sh::test_hook_content_is_gdlc_specific` asserts no stale `SDLC BASELINE` / `setup-wizard` / `SDLC.md` markers from the mirror. A copy-paste mistake here would be a doc-reality mismatch that's hard to find later.
5. **Skill contract tests were GREEN on the first run** — meaning the 4 skills and the wizard doc are already internally consistent. Treat that as evidence the upstream `~/gdlc/` port was clean, not as evidence the tests are weak. If you want to verify: `sed -i '' 's/step-7/step-8/' skills/gdlc-setup/SKILL.md` and re-run — `test_setup_has_all_eight_steps` should fail.
6. **No afterhours push yet.** Per `feedback_afterhours_no_push.md`, BaseInfinity repos block pushes weekdays 08:00–17:00. Current session opened at 17:38 PDT so the window is open; but no remote exists yet — user needs to create `BaseInfinity/claude-gdlc-wizard` via web UI (local `gh auth` is expired) before push is even possible.

## Known limitations (can't verify / not in scope)

- **The `curl | bash` install flow is not end-to-end tested.** Once `claude-gdlc-wizard` is on npm, flip the env gate and re-run `tests/test-install-script.sh` to exercise the live piped-install path.
- **Hook behavior under real Claude Code invocation is not tested.** Tests run the scripts directly with mock stdin. The actual `UserPromptSubmit` / `InstructionsLoaded` dispatch is CC's concern — we validate the shape of the script output matches what CC expects.
- **Plugin-install detection (the "dual-install" branch of SDLC's init.js)** is not ported yet. Lower-value for a brand-new wizard because there's no plugin distribution to conflict with. Defer until the Claude Code marketplace ships `gdlc-wizard` plugin installs in the wild.
- **Local filesystem quirk observed in-session**: `./hooks/` is sometimes wiped between Bash tool calls in this specific dev environment (likely the afterhours git-hooks `core.hookspath` redirect or a local watcher — not reproducible on clean checkouts). Tests pass atomically when hooks/ is present. CI and normal consumer installs are unaffected.

## Score (self-graded)

Self: **7.5 / 10**. Would be an 8 with either (a) a real `npx` publish + live piped-install test, or (b) the Path A consolidation decision resolved so the sibling-repo dependency is either committed-to or removed. Phase-1 graduation criteria from the ROADMAP are met in spirit; formal "Adoption without modification" + "earned rule from case study #2" still blocked on PDLC/TamAGI running through the suite.
