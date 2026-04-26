No blocking findings in the targeted recheck.

1. **Finding 1: VERIFIED FIXED.** `/gdlc-update` now says apply is per-file, not global force, and preserves `keep mine` decisions as no-ops: [skills/gdlc-update/SKILL.md](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-update/SKILL.md:128), [line 141](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-update/SKILL.md:141). Regression present at [tests/test-skill-contracts.sh](/Users/stefanayala/claude-gdlc-wizard/tests/test-skill-contracts.sh:369).

2. **Finding 2: VERIFIED FIXED.** `check-only` now always continues through step 5 drift detection, even on version match: [skills/gdlc-update/SKILL.md](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-update/SKILL.md:59). Regression present at [tests/test-skill-contracts.sh](/Users/stefanayala/claude-gdlc-wizard/tests/test-skill-contracts.sh:383).

3. **Finding 3: VERIFIED FIXED.** `/gdlc-setup` step 0.2 delegates verification to `npx claude-gdlc-wizard check`: [skills/gdlc-setup/SKILL.md](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-setup/SKILL.md:36). The CLI install surface includes settings, 3 hooks, and 4 skills at [cli/init.js](/Users/stefanayala/claude-gdlc-wizard/cli/init.js:20), plus wizard doc at [line 111](/Users/stefanayala/claude-gdlc-wizard/cli/init.js:111). Regression present at [tests/test-skill-contracts.sh](/Users/stefanayala/claude-gdlc-wizard/tests/test-skill-contracts.sh:397).

4. **Finding 4: VERIFIED FIXED.** `gdlc-feedback` managed-files row now says the skill is installed by `npx claude-gdlc-wizard init`, not sibling/setup wording: [skills/gdlc-feedback/SKILL.md](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-feedback/SKILL.md:186).

5. **Finding 5: VERIFIED FIXED.** Assertion counts are now internally consistent at 102 total / 27 skill-contracts: [CLAUDE.md](/Users/stefanayala/claude-gdlc-wizard/CLAUDE.md:24), [TESTING.md](/Users/stefanayala/claude-gdlc-wizard/TESTING.md:57), [ARCHITECTURE.md](/Users/stefanayala/claude-gdlc-wizard/ARCHITECTURE.md:16).

Verification:
- `bash tests/test-skill-contracts.sh` passed: `Passed: 27`, `Failed: 0`, including all three named regression tests.
- Path A legacy-reference recheck passed: `legacy_ref_matches=0` for `~/gdlc/` and `BaseInfinity/gdlc([^-]|$)` across `skills/` plus `CLAUDE_CODE_GDLC_WIZARD.md`.
- Regex sanity held: `BaseInfinity/claude-gdlc-wizard` matched `0`; deprecated `BaseInfinity/gdlc/issues` matched `1`.

Notes for next review, non-blocking:
- `CLAUDE_CODE_GDLC_WIZARD.md` still has abbreviated update-registry text saying step 7 applies via `npx claude-gdlc-wizard init --force` at lines 80 and 117, while the operative `/gdlc-update` skill now correctly says per-file apply. Reconcile that doc wording in the next cleanup.
- The three regressions are markdown contract tests, not executable end-to-end simulations of a skill run.

score: 9/10, CERTIFIED