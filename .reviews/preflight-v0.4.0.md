# Preflight Self-Review: v0.4.0 — Fable self-enforcement audit (#14) + GPT-5.6 Sol sync (#15)

- [x] Full suite green: 126 passed / 0 failed across 5 suites (cli 31, hooks 14, install 18, plugin 21, skill-contracts 42). Re-run after every edit wave, including post-version-bump and after every round-1 and round-2 fix.
- [x] TDD RED observed for every behavior change: hook retirement (event-parity + only-UserPromptSubmit tests failed first), `_find-gdlc-root.sh` second anchor (hooks test failed first), v0.3.0→v0.4.0 legacy migration (CLI test failed first), Sol/Terra sync (4 contract tests failed first — RED run reported 10 stale GPT-5.5 refs, all fixed).
- [x] Mutation testing on the #14 fixes: 5 mutations, all killed by the suite.
- [x] `hooks/gdlc-prompt-check.sh` control flow read back post-edit: SETUP branch exits early (line 23), dual-install check runs on BASELINE path only, script always exits 0.
- [x] `cli/init.js::mergeSettings` legacy sweep moved BEFORE the template-event loop and iterates ALL existing events — verified a retired event's stale entry (`InstructionsLoaded`) is swept and its empty event key deleted (CLI regression test seeds exactly this state).
- [x] Version parity: 0.4.0 in `package.json`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json` plugin entry (marketplace top-level `1.0.0` is the marketplace schema version, intentionally untouched).
- [x] Zero stale `GPT-5.5` / `GPT-5.4` references in `AI_SETUP_LANES.md` and `README.md` (contract test `test_lanes_no_stale_gpt55` enforces; per-location tests require "5.6" AND "Sol" together so a future "GPT-5.7 Sol" can't silently pass).
- [x] Grepped all remaining `instructions-loaded` references repo-wide: every survivor is an intentional retirement note, migration instruction, or historical changelog/review artifact.
- [x] Doc sync verified against source, not memory: CLAUDE.md / ARCHITECTURE.md / TESTING.md / SDLC.md test counts (126), hook inventory (1 enforcement hook + 1 helper), event set (`UserPromptSubmit` only), init file count (8). Round-1 fixes extended the sweep to CLAUDE_CODE_GDLC_WIZARD.md, README.md, and all 4 skills — now contract-enforced by `test_live_docs_match_install_topology`; round-2 fixes added SDLC.md itself to that contract (section-scoped exemption for its disabled-wrap reference section).
- [x] Historical citations left untouched per issue #15: CHANGELOG ≤0.3.0 entries, `.reviews/` artifacts, SDLC.md's disabled-wrap table (line 71) still reference the old hook/reviewer names by design.

## Round-2 fix verification (before round-3 recheck)

- [x] `tests/test-cli.sh::test_ordinary_init_sweeps_legacy_settings` (ordinary `init`, no `--force`) written and GREEN; re-applying Codex's round-2 surviving mutation (`if (!force) return null;` at the top of `mergeSettings`) turns EXACTLY this test RED (cli 30/1; the mutation survived 29/0 in round 2). Mutation reverted, `cli/init.js` diffed byte-identical against backup.
- [x] `tests/test-cli.sh::test_force_init_preserves_separate_user_groups` written and GREEN; re-applying the second surviving mutation (`existing.hooks[event] = [group];` after the force in-place replace) turns EXACTLY this test RED (cli 30/1; survived 29/0 in round 2). Reverted and diff-verified.
- [x] `SDLC.md` added to both loops of `test_live_docs_match_install_topology` via `guarded_doc_content()` (awk section filter). Codex's round-2 surviving mutation (live "10 rows" appended at SDLC.md EOF) now fails contracts 41/1; live `InstructionsLoaded` guidance outside the section fails 41/1; the same "10 rows" string INSIDE the exempt `## Hooks (current state — no active SDLC plugin)` section stays GREEN 42/0 — exemption is section-scoped, not file-wide. All mutations reverted, `SDLC.md` diff-verified against backup.
- [x] Count re-sync 124 → 126 across CHANGELOG.md v0.4.0 entry, TESTING.md, ARCHITECTURE.md, CLAUDE.md, SDLC.md, this preflight; per-suite cli 29 → 31. Also corrected two per-suite counts in CLAUDE.md/ARCHITECTURE.md that had been stale since before round 1 (28/41 era).
- [x] No production code changed in round 3 — `cli/init.js` byte-identical to the round-2 reviewed state; tests and docs only.
- [x] Full suite re-run post-everything: 126/0 (31/14/18/21/42).

## Known limitations
- Hook behavior under real Claude Code `UserPromptSubmit` dispatch is not tested (mock stdin only) — longstanding, documented in TESTING.md.
- `CLAUDE_CODE_SDLC_WIZARD.md` (untracked, not part of this release) contains a GPT-5.4 reference — out of scope.
- Live npm-install path still gated (`CLAUDE_GDLC_WIZARD_NPM_PUBLISHED=1`).
