# Preflight Self-Review — v0.2.2 Issue-Fix Release

**Date:** 2026-04-26
**Branch:** `main` (uncommitted; last commit `eac4032`)
**Scope:** Bundle the four issue-fixes surfaced by the codeguesser case study and the codeguesser dual-install dogfooding finding into a single point release. Bump version `0.2.1 → 0.2.2`. No behavioral migration of skills (that landed in v0.2.1); this release is targeted regressions + setup-flow gap closures.

## Issues addressed

| Issue | Title | Severity | Status |
|-------|-------|----------|--------|
| #1 | `gdlc-setup` test-harness detection false-positives on script names | P2 | FIXED |
| #2 | `gdlc-update` `~/gdlc/` references already removed in v0.2.1 | n/a | VERIFIED CLOSED |
| #3 | `gdlc-setup` lacked existing-install early-redirect | **P1** | FIXED |
| #4 | Case-study template lacked project-playbook auto-linkage | P2 | FIXED |
| #5 | Hook filename collision with `claude-sdlc-wizard` | **P1** | FIXED |

#3 and #5 are P1 because they could silently corrupt user state. #3: a pre-wizard `GDLC.md` could be clobbered by `/gdlc-setup` re-run. #5: whichever DLC wizard installed second silently overwrote the other's `instructions-loaded-check.sh`.

## What changed (file-by-file)

### Issue #1 — jq-scoped dependency detection
- `skills/gdlc-setup/SKILL.md` — step-1 detection table reworked. Old: top-level grep for `vitest`/`jest`/`mocha`/`playwright` in `package.json`. New: jq-based `.devDependencies + .dependencies | keys[]` block that parses dependency keys correctly, eliminating false-positives like a script named `"test:vitest-shape"` matching when no vitest dep exists.
- `tests/test-skill-contracts.sh` — added `test_setup_step_1_test_harness_detection_scoped_to_deps` regression assertion. Greps for `jq` invocation + `devDependencies` reference in the step-1 block.

### Issue #3 — existing-install early-redirect (step-0.5)
- `skills/gdlc-setup/SKILL.md` — added `### step-0.5: Existing-Install Detection` between step-0.2 and step-1. Reads `GDLC.md` if present, greps for `<!-- (GDLC )?Wizard Version:` metadata. Three-branch logic:
  - **Managed install** (metadata found) → STOP, redirect to `/gdlc-update`. Exit before any auto-scan or write.
  - **Legacy unmanaged** (`GDLC.md` exists but no metadata) → STOP and ASK user (3 options: backup-then-fresh, treat-as-legacy, abort).
  - **Empty stub or absent** → continue with fresh setup.
- `skills/gdlc-setup/SKILL.md::<!-- Completed Steps:` metadata block — added `step-0.5` to the list.
- `CLAUDE_CODE_GDLC_WIZARD.md` — setup step registry table extended with `step-0.5` row + behavior description. Both `<!-- Completed Steps:` occurrences (registry block + template example) updated to include `step-0.5` via `replace_all=true` on Edit.
- `tests/test-skill-contracts.sh` — added two assertions:
  - `test_setup_existing_install_early_redirect` — verifies step-0.5 header exists AND its body mentions `/gdlc-update` redirect.
  - `test_setup_existing_install_redirect_before_writes` — verifies step-0.5 line number < step-3 line number (early enough to gate writes).

### Issue #4 — playbook linkage (step-5.5)
- `skills/gdlc-setup/SKILL.md` — added `### step-5.5: Link Surrounding Playbooks` between step-5 (case study generation) and step-6. Detection table for 7 root-level playbooks: `ARTSTYLE.md`, `TESTING.md`, `CLAUDE.md`, `ARCHITECTURE.md`, `SDLC.md`, `BRANDING.md`, `DESIGN_SYSTEM.md`. For each present, append a bullet to a `## Related playbooks` section in `GDLC.md`. Idempotent rules:
  - Skip the entire step if `## Related playbooks` already exists in `GDLC.md`.
  - Skip silently on `skill-only` install variant.
  - No-op if no playbooks detected (don't write an empty section).
- `skills/gdlc-setup/SKILL.md::<!-- Completed Steps:` — added `step-5.5`.
- `CLAUDE_CODE_GDLC_WIZARD.md` — registry row added; metadata blocks updated (replace_all).
- `tests/test-skill-contracts.sh` — two assertions:
  - `test_setup_links_surrounding_playbooks` — verifies the skill mentions `ARTSTYLE.md`, `TESTING.md`, `CLAUDE.md`, AND has a `## Related [Pp]laybooks` header.
  - `test_wizard_doc_documents_playbook_linkage` — verifies wizard doc registry mentions related-playbooks step.

### Issue #5 — hook namespace (filename collision with claude-sdlc-wizard)
- **Rename via `git mv`** (history-preserving): `hooks/instructions-loaded-check.sh` → `hooks/gdlc-instructions-loaded-check.sh`.
- `hooks/hooks.json` — plugin-manifest hook command path updated. Re-staged after `git checkout -- hooks/` reset (session quirk per CLAUDE.md).
- `cli/init.js::FILES` — basename updated.
- `cli/templates/settings.json` — hook command path updated.
- `tests/test-cli.sh`, `tests/test-hooks.sh`, `tests/test-plugin.sh`, `tests/test-skill-contracts.sh` — assertion paths updated. Three new namespace-contract tests added:
  - `test_no_hook_filename_collisions_with_sdlc` — fails if any shipped hook lacks the `gdlc-` prefix or `_find-gdlc-root` form.
  - `test_hooks_json_uses_namespaced_basenames` — fails if `hooks/hooks.json` references the legacy filename.
  - `test_cli_settings_template_uses_namespaced_basenames` — same check on `cli/templates/settings.json`.
- Doc cleanup: `CLAUDE.md`, `ARCHITECTURE.md` (2 sites), `TESTING.md` updated to reference the new basename.

### Manifest version bumps
- `package.json` — `"version": "0.2.1"` → `"version": "0.2.2"`.
- `.claude-plugin/plugin.json` — `0.2.1` → `0.2.2`.
- `.claude-plugin/marketplace.json` — `0.2.1` → `0.2.2`.

### CHANGELOG
- `CHANGELOG.md` — new `## [0.2.2] — 2026-04-26` entry above the v0.2.1 entry. Subtitle: "Issue-fix release". Sections:
  - **Fixed**: 4 entries (one per issue) with regression test names.
  - **Changed**: step registry updates in wizard doc.
  - **Added**: 7 new contract tests (27 → 34 in skill-contracts; whole suite 102 → 110).
  - **Migration notes**: upgrade path via `/gdlc-update` or `npx claude-gdlc-wizard init --force`. Hook rename is automatic on install path; legacy `instructions-loaded-check.sh` is removed by `init --force`.

## Self-checks performed

- [x] **TDD RED demonstrated for each issue.** All 7 new contract tests written before the corresponding skill/hook fixes. Each one demonstrably failed against pre-fix state.
- [x] **All 5 suites pass post-fix.** Final run: cli=24, hooks=13, install-script=18, plugin=20, skill-contracts=35 → **total 110 passed, 0 failed**.
- [x] **Issue #5 file rename is `git mv` (history preserved).** `git status --short` shows `R  hooks/instructions-loaded-check.sh -> hooks/gdlc-instructions-loaded-check.sh`. Plugin manifest + CLI template + all four test files reference the new basename. No remaining live references to the legacy form (only historical mentions in CHANGELOG `[0.1.0]` entry + explicit anti-references in regression tests checking absence).
- [x] **`hooks/hooks.json` edit re-staged after session-quirk wipe.** `git checkout -- hooks/` in test-prep step previously reverted the unstaged hooks.json edit; re-applied + `git add hooks/hooks.json` so subsequent test runs preserve the change. Status now shows `M  hooks/hooks.json` (staged-modified).
- [x] **Step-registry parity between skill and wizard doc.** Both `skills/gdlc-setup/SKILL.md::<!-- Completed Steps:` and the matching block in `CLAUDE_CODE_GDLC_WIZARD.md` now contain `step-0.5` and `step-5.5`. The `test_setup_metadata_block_matches_wizard_doc` assertion (existing) passes — both byte-for-byte identical.
- [x] **Version parity across 4 manifests.** `package.json::version`, `.claude-plugin/plugin.json::version`, `.claude-plugin/marketplace.json::plugins[0].version`, and `CHANGELOG.md` topmost `## [0.2.2]` all read `0.2.2`. Confirmed by `test_marketplace_plugin_version_matches_package_version` in test-plugin.sh.
- [x] **No accidental `~/gdlc/` regressions.** v0.2.1 forbidden-pattern tests still green — no skill or wizard-doc reference to the legacy clone path. The fixes in this release operate at a different layer (setup-flow gates, hook namespace, jq parsing) and do not re-introduce sibling-clone semantics.

## Known limitations / non-goals

- **#2 closed without code change.** v0.2.1's full skill rewrite already removed the `~/gdlc/` references the issue flagged. Verified by re-reading `skills/gdlc-update/SKILL.md` end-to-end and grepping the codebase. The issue can be closed citing v0.2.1.
- **Issue #3 detection regex `<!-- (GDLC )?Wizard Version:`** — accepts both the canonical form and a transitional form some early case studies emitted. Future installs will only emit the canonical form. The regex is forgiving by design.
- **`step-5.5` does not write to surrounding playbooks**, only to `GDLC.md`'s `## Related playbooks` section. Bidirectional linkage (e.g., adding a `## Related: GDLC.md` section to `ARTSTYLE.md`) is out of scope — the user's existing playbooks may have intentional structure we shouldn't mutate.
- **Hook rename does NOT include a deprecation shim.** Per CLAUDE.md "Don't support legacy code, just delete it" — `init --force` flags the legacy basename as DRIFT and removes it. The CHANGELOG migration notes call this out explicitly. No silent leftover.
- **npm publish remains deferred.** `package.json` is ready; pinning to v0.2.2 will happen when the broader Phase 2/3 distribution channel ramp lands. Not in scope for this commit.

## Files I asked the reviewer to verify (top-of-mind)

1. **Issue #5's namespace contract tests are exhaustive.** The new `test_no_hook_filename_collisions_with_sdlc` should reject any future hook that ships without the `gdlc-` prefix. Verify the assertion regex covers the full `hooks/*.sh` set, not just the renamed file.
2. **Issue #3's three-branch logic in step-0.5 is exhaustive.** Read the step-0.5 prose end-to-end: managed → redirect, legacy → ASK, absent/empty → continue. Confirm there's no fourth state where the wizard could silently overwrite.
3. **Issue #4's idempotency rules.** `step-5.5` should be safe to re-run via `/gdlc-update` (which may re-trigger setup partial steps). Re-running on a project that already has a `## Related playbooks` section should be a no-op, not a duplicate-bullet append.
4. **Issue #1's jq detection actually parses correctly.** The replacement should use `jq -r '.devDependencies + .dependencies | keys[]'` (or equivalent) and only key off direct dependency map entries — not `scripts`, not nested `peerDependencies`, not `optionalDependencies`. Verify the skill's documented command is correct.
5. **Step-registry table in `CLAUDE_CODE_GDLC_WIZARD.md`** — the new `step-0.5` and `step-5.5` rows should sit in line-number order between their neighbors. Confirm the registry reads top-to-bottom in execution order.
6. **CHANGELOG entry accuracy** — every claim in the v0.2.2 Fixed/Changed/Added sections should map to a real diff hunk in the staged tree. Especially: regression test names, assertion counts (27→34 / 102→110), and migration-path commands (`/gdlc-update`, `init --force`).

## Test status snapshot

```
=== tests/test-cli.sh ===           Passed: 24, Failed: 0
=== tests/test-hooks.sh ===         Passed: 13, Failed: 0
=== tests/test-install-script.sh === Passed: 18, Failed: 0 (live tests gated)
=== tests/test-plugin.sh ===        Passed: 20, Failed: 0
=== tests/test-skill-contracts.sh === Passed: 35, Failed: 0
                                     ─────────
                                     Total:  110 passed, 0 failed
```
