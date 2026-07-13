NOT CERTIFIED. The migration can delete user-owned hooks, and several shipped release documents remain stale.

## Findings

### 1 — P1: settings migration can delete user hooks

Evidence:

- [`isLegacyHookEntry`](/Users/stefanayala/claude-gdlc-wizard/cli/init.js:57) classifies an entire outer hook group as legacy when any nested command matches.
- [`mergeSettings`](/Users/stefanayala/claude-gdlc-wizard/cli/init.js:76) then removes that entire group.
- An audit fixture containing one outer group with both `gdlc-instructions-loaded-check.sh` and `/opt/user-hook.sh` produced settings with `/opt/user-hook.sh` completely absent after `init --force`.
- The same destructive behavior affects current wizard entries during force replacement at [`cli/init.js:96`](/Users/stefanayala/claude-gdlc-wizard/cli/init.js:96).
- The promised regression does not seed a user hook at all ([`tests/test-cli.sh:521`](/Users/stefanayala/claude-gdlc-wizard/tests/test-cli.sh:521)). It also checks `len(hooks.get("InstructionsLoaded", [])) == 0`, which cannot distinguish a deleted key from an empty key ([`tests/test-cli.sh:552`](/Users/stefanayala/claude-gdlc-wizard/tests/test-cli.sh:552)).

Separate outer user entries sharing the event were preserved, and legacy-only non-template events were correctly deleted; the failure occurs when commands share an outer hook group.

Certify condition: Filter or replace matching nested command objects rather than deleting/replacing their entire outer group. Preserve unrelated nested hooks and group fields such as `matcher`. Add regressions covering mixed legacy/user and current/user groups, separate shared-event entries, non-template events, force and non-force runs, and exact absence of emptied event keys.

### 2 — P1: shipped source-of-truth documentation describes the wrong install surface

Evidence:

- The shipped wizard doc says “2 hooks + helper” ([`CLAUDE_CODE_GDLC_WIZARD.md:13`](/Users/stefanayala/claude-gdlc-wizard/CLAUDE_CODE_GDLC_WIZARD.md:13)) and “settings + 3 hooks” ([line 89](/Users/stefanayala/claude-gdlc-wizard/CLAUDE_CODE_GDLC_WIZARD.md:89)).
- Its managed-files table omits `.claude/settings.json` and both hook scripts ([lines 39–48](/Users/stefanayala/claude-gdlc-wizard/CLAUDE_CODE_GDLC_WIZARD.md:39)).
- `npm pack --dry-run --json` confirms this stale wizard doc is included in the release tarball.
- README repeats “2 hooks + helper” and “3 hook files” ([`README.md:30`](/Users/stefanayala/claude-gdlc-wizard/README.md:30), [`README.md:64`](/Users/stefanayala/claude-gdlc-wizard/README.md:64)).
- TESTING still expects nine files under `.claude` and ten check rows ([`TESTING.md:158`](/Users/stefanayala/claude-gdlc-wizard/TESTING.md:158)).
- Additional stale claims remain in [`ARCHITECTURE.md:39`](/Users/stefanayala/claude-gdlc-wizard/ARCHITECTURE.md:39), [`ARCHITECTURE.md:152`](/Users/stefanayala/claude-gdlc-wizard/ARCHITECTURE.md:152), and [`tests/test-cli.sh:3`](/Users/stefanayala/claude-gdlc-wizard/tests/test-cli.sh:3).
- The stale-reference sweep also finds live, non-historical `InstructionsLoaded` guidance in [`TESTING.md:177`](/Users/stefanayala/claude-gdlc-wizard/TESTING.md:177) and [`SDLC.md:13`](/Users/stefanayala/claude-gdlc-wizard/SDLC.md:13).

Certify condition: Consistently document the current surface as settings + one enforcement hook + one helper + four skills + wizard doc = eight managed files, with nine normal `check` rows including `.gitignore`. Add settings and both scripts to the wizard managed-files table, remove non-historical `InstructionsLoaded` guidance, and add a topology contract test over live documentation.

### 3 — P2: the documented test command fails in the current environment

Evidence:

- `bash tests/test-hooks.sh` produced `Passed: 13`, `Failed: 1`, exit 1.
- The failure is `test_prompt_check_silent_outside_project`; it captures Bash’s inherited locale warning as hook output.
- `env -u LC_ALL LANG=C bash tests/test-hooks.sh` passes 14/0.
- With that portable locale, all suites pass: 28/14/18/21/41 = 122/0.
- This still violates [`TESTING.md`](/Users/stefanayala/claude-gdlc-wizard/TESTING.md:5)’s stated “all tests pass, no exceptions” gate under the documented invocation.

Certify condition: Make the suite locale-independent, for example by setting a portable `LANG=C`/`LC_ALL=C` inside the harness, and demonstrate the documented unmodified full-suite command passes 122/0.

### 4 — P2: Issue #15 contract tests are weaker than claimed

Evidence:

- The reviewer-row test passes vacuously if every Codex reviewer row is deleted because it never asserts an expected match count ([`tests/test-skill-contracts.sh:671`](/Users/stefanayala/claude-gdlc-wizard/tests/test-skill-contracts.sh:671)).
- The escalation “paragraph” check only requires its heading ([`tests/test-skill-contracts.sh:704`](/Users/stefanayala/claude-gdlc-wizard/tests/test-skill-contracts.sh:704)); its required `max`/Pro, security-sensitive, and high-blast-radius guidance can disappear while the test stays green.
- README’s stale-model guard rejects GPT-5.5 but not GPT-5.4 ([`tests/test-skill-contracts.sh:740`](/Users/stefanayala/claude-gdlc-wizard/tests/test-skill-contracts.sh:740)).
- Current source text is correct: static grep found zero GPT-5.4/GPT-5.5 in README and AI_SETUP_LANES, and all reviewer locations currently contain both `5.6` and `Sol`.

Certify condition: Assert exactly the expected reviewer locations, validate substantive escalation terms, and reject both GPT-5.4 and GPT-5.5 across both live guidance files.

## Checklist disposition

| Item | Result | Evidence |
|---|---|---|
| (a) Migration sweep | FAIL | Finding 1; regression does not assert all three promised conditions. |
| (b) Event parity | PASS | Both JSON files contain only `UserPromptSubmit`; plugin suite 21/0. |
| (c) Prompt hook | PASS | [`gdlc-prompt-check.sh:9`](/Users/stefanayala/claude-gdlc-wizard/hooks/gdlc-prompt-check.sh:9); branch matrix confirmed setup exits before dual check, both plugin paths work, and all paths return 0. |
| (d) Root finder | PASS | [`_find-gdlc-root.sh:15`](/Users/stefanayala/claude-gdlc-wizard/hooks/_find-gdlc-root.sh:15); HOME-exclusive and `/` termination probes passed; fresh-install nudge passed end-to-end. |
| (e) Version parity | PASS | Package, plugin, and marketplace plugin are 0.4.0; marketplace schema remains 1.0.0. |
| (f) CHANGELOG accuracy | FAIL | Counts sum to 122, but migration safety is not airtight and the claimed regression does not prove empty-key deletion. |
| (g) Stale-reference sweep | FAIL | GPT sweep passes; live stale hook references remain per Finding 2. |
| (h) Docs accuracy | FAIL | Contradictory topology/count claims remain per Finding 2. |
| (i) Update-skill semantics | FAIL | [`gdlc-update/SKILL.md:139`](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-update/SKILL.md:139) promises preservation that `mergeSettings` violates for mixed groups. |
| (j) Issue #15 contracts | FAIL | Current content passes, but contracts are incomplete per Finding 4. |

No prior-round passes existed to re-verify (`previous_score: null`, no prior fixes). Additional checks passed: `git diff --check`, Bash syntax, JSON parsing, and isolated-cache `npm pack --dry-run`.

Score: 5/10 — NOT CERTIFIED