NOT CERTIFIED. The production fixes behave correctly, but Findings 1 and 2 do not yet satisfy their original certify conditions for durable regression coverage.

## Targeted finding dispositions

### 1 — P1: PARTIALLY FIXED — implementation repaired, required regression matrix incomplete

Verified behavior:

- [`isLegacyHookCommand`](/Users/stefanayala/claude-gdlc-wizard/cli/init.js:54) and [`isWizardHookCommand`](/Users/stefanayala/claude-gdlc-wizard/cli/init.js:50) now classify individual command objects.
- The legacy sweep filters nested commands, removes only emptied groups, and deletes only emptied event keys ([`cli/init.js:77`](/Users/stefanayala/claude-gdlc-wizard/cli/init.js:77)).
- `--force` replaces only the current wizard command inside its existing group ([`cli/init.js:100`](/Users/stefanayala/claude-gdlc-wizard/cli/init.js:100)).
- I reran the round-1 mixed-group fixture through the real CLI suite. It preserved both user commands and `matcher`, removed the legacy command, and retained the current wizard command ([`tests/test-cli.sh:579`](/Users/stefanayala/claude-gdlc-wizard/tests/test-cli.sh:579)); CLI result: 29/0.
- The v0.3.0 migration now asserts exact absence of the emptied `InstructionsLoaded` key ([`tests/test-cli.sh:559`](/Users/stefanayala/claude-gdlc-wizard/tests/test-cli.sh:559)).

The original certify condition also required regressions for separate outer entries and force plus non-force runs. Those cases remain unguarded:

- The new fixture has one mixed outer group per event and invokes only `init --force` ([`tests/test-cli.sh:592`](/Users/stefanayala/claude-gdlc-wizard/tests/test-cli.sh:592), [`tests/test-cli.sh:612`](/Users/stefanayala/claude-gdlc-wizard/tests/test-cli.sh:612)).
- Every seeded migration test invokes `--force`; none proves the unconditional legacy sweep during ordinary `init` ([`tests/test-cli.sh:479`](/Users/stefanayala/claude-gdlc-wizard/tests/test-cli.sh:479), [`tests/test-cli.sh:495`](/Users/stefanayala/claude-gdlc-wizard/tests/test-cli.sh:495), [`tests/test-cli.sh:556`](/Users/stefanayala/claude-gdlc-wizard/tests/test-cli.sh:556), [`tests/test-cli.sh:612`](/Users/stefanayala/claude-gdlc-wizard/tests/test-cli.sh:612)).
- Mutation proof: disabling all non-force settings merging still produced CLI 29/0. A separate mutation that discarded every other outer entry after replacing the wizard command also produced CLI 29/0.

Remaining certify work: add persistent fixtures for ordinary `init` and for user-owned outer groups separate from the wizard group under the same event. Assert the legacy sweep, user-group preservation, matcher preservation, current-command force behavior, and exact event-key deletion across the required force/non-force matrix.

### 2 — P1: PARTIALLY FIXED — current docs corrected, topology contract incomplete

Verified current content:

- The wizard doc states eight managed files ([`CLAUDE_CODE_GDLC_WIZARD.md:13`](/Users/stefanayala/claude-gdlc-wizard/CLAUDE_CODE_GDLC_WIZARD.md:13), lists settings and both scripts ([`CLAUDE_CODE_GDLC_WIZARD.md:45`](/Users/stefanayala/claude-gdlc-wizard/CLAUDE_CODE_GDLC_WIZARD.md:45), and states nine check rows ([`CLAUDE_CODE_GDLC_WIZARD.md:92`](/Users/stefanayala/claude-gdlc-wizard/CLAUDE_CODE_GDLC_WIZARD.md:92)).
- README, TESTING, ARCHITECTURE, CLAUDE, and SDLC now carry the current topology/count language; the scoped stale-pattern sweep found no old `2 hooks`, `3 hook files`, `10 rows`, or `9 files` claims in the live release docs and skills.
- `npm pack --dry-run --json` includes the corrected wizard doc and only the two current hook scripts.

The topology contract does not cover every live document implicated by the original finding:

- Both filename loops omit `SDLC.md` ([`tests/test-skill-contracts.sh:679`](/Users/stefanayala/claude-gdlc-wizard/tests/test-skill-contracts.sh:679), [`tests/test-skill-contracts.sh:687`](/Users/stefanayala/claude-gdlc-wizard/tests/test-skill-contracts.sh:687)).
- Mutation proof: adding a live `10 rows` topology claim to `SDLC.md` still produced contracts 42/0.

The round-1 certify condition explicitly required a topology contract over live documentation after identifying stale `SDLC.md` guidance. Add `SDLC.md` to the topology guard, with a precise exemption for its clearly marked disabled-wrap reference section rather than omitting the whole file.

### 3 — P2: FIXED

- All five harnesses export `LC_ALL=C LANG=C` immediately after `set -e` (for example [`tests/test-hooks.sh:5`](/Users/stefanayala/claude-gdlc-wizard/tests/test-hooks.sh:5)).
- Reproduced the prior hostile-locale fixture with `LC_ALL=bogus_locale LANG=bogus_locale`: CLI 29/0 and hooks 14/0.
- Reran the documented unmodified suite from repo root: 29/14/18/21/42 = 124/0.

The invoking Bash can still print a locale warning before the script executes, but it no longer contaminates captured hook output or fails an assertion.

### 4 — P2: FIXED

- Reviewer rows require an exact count of two ([`tests/test-skill-contracts.sh:710`](/Users/stefanayala/claude-gdlc-wizard/tests/test-skill-contracts.sh:710)).
- The escalation line requires the `max`/Pro target, `security-sensitive`, and `blast radius` terms ([`tests/test-skill-contracts.sh:755`](/Users/stefanayala/claude-gdlc-wizard/tests/test-skill-contracts.sh:755)).
- The lanes policy rejects GPT-5.4, and README rejects both GPT-5.5 and GPT-5.4 ([`tests/test-skill-contracts.sh:749`](/Users/stefanayala/claude-gdlc-wizard/tests/test-skill-contracts.sh:749), [`tests/test-skill-contracts.sh:806`](/Users/stefanayala/claude-gdlc-wizard/tests/test-skill-contracts.sh:806)). Static sweep found no stale GPT-5.4/GPT-5.5 in either live file.
- Independent mutation runs all turned RED: deleting one reviewer row failed 41/1 with the expected-count token; gutting the escalation sentence failed 41/1 with all three missing-term tokens; inserting GPT-5.4 into README failed 41/1.

## Prior PASS re-verification

| Item | Result | Evidence |
|---|---|---|
| (a) Migration sweep | FAIL | Current code and round-1 force fixture pass, but the original regression matrix remains incomplete per Finding 1. |
| (b) Event parity | PASS | `hooks/hooks.json` and `cli/templates/settings.json` contain exactly `UserPromptSubmit`; plugin suite 21/0. |
| (c) Prompt hook | PASS | Setup exits at [`gdlc-prompt-check.sh:23`](/Users/stefanayala/claude-gdlc-wizard/hooks/gdlc-prompt-check.sh:23), before the dual-install branch at line 42; hook suite confirms all paths exit 0. |
| (d) Root finder | PASS | Second anchor at [`_find-gdlc-root.sh:16`](/Users/stefanayala/claude-gdlc-wizard/hooks/_find-gdlc-root.sh:16); HOME-exclusive and `/` termination remain in the loop condition at line 15; hook suite 14/0. |
| (e) Version parity | PASS | `package.json`, plugin manifest, and marketplace plugin entry are all 0.4.0. |
| (f) CHANGELOG accuracy | PASS | 9 new assertions and 29/14/18/21/42 = 124 are accurate; named tests exist; migration prose matches current implementation. |
| (g) Stale-reference sweep | PASS | No GPT-5.4/GPT-5.5 in the two live reviewer docs and no live stale GDLC topology claims in the scoped files. |
| (h) Docs accuracy | PASS | Current docs describe eight managed files, nine check rows, one enforcement hook plus one helper, and UserPromptSubmit-only. The missing SDLC regression guard remains Finding 2. |
| (i) Update-skill semantics | PASS | [`skills/gdlc-update/SKILL.md:139`](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-update/SKILL.md:139) matches nested-command merge semantics. |
| (j) Issue #15 contracts | PASS | Static inspection, 42/0 suite, and three independent mutation runs all pass the certify condition. |

Additional checks passed: `git diff --check`, Bash syntax, JSON parsing, and isolated-cache `npm pack --dry-run --json`. `hooks/` was present at review start, so no checkout was performed. Per instruction, untracked `.claude/`, `.playwright-mcp/`, and `CLAUDE_CODE_SDLC_WIZARD.md` were not reviewed. No new P0 observation was found.

## Notes for next review

- Recheck only the new Finding 1 matrix cases and the expanded Finding 2 document guard, then rerun 124+ assertions.
- The pre-script locale warnings are noisy but non-blocking; the original locale-caused assertion failure is fixed.

Score: 8/10 — NOT CERTIFIED
