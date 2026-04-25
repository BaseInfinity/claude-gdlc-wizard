# Testing Strategy — claude-gdlc-wizard

## The Absolute Rule

```
ALL TESTS MUST PASS. NO EXCEPTIONS.

This is not negotiable. This is not flexible. This is absolute.
```

**Not acceptable excuses:**
- "Those tests were already failing" → then fix them first
- "That's not related to my changes" → doesn't matter, fix it
- "It's flaky, just ignore it" → flaky = bug, investigate it
- "It passes locally" → CI is the source of truth

**The process:**
1. Tests fail → STOP
2. Investigate → find root cause
3. Fix → whatever is actually broken
4. All tests pass → THEN commit

---

## Meta-Testing Framing

This is a **meta-project** — a wizard that sets up *other* projects. Traditional app-testing metaphors don't apply directly.

| Normal project | This project |
|----------------|--------------|
| Test source code logic | Test wizard-install behavior |
| Unit-test functions | Test bash script output + exit codes |
| Integration-test APIs | Test CLI ↔ filesystem ↔ git ↔ consumer project |
| E2E-test user flows | Simulate `npx claude-gdlc-wizard init` in a fresh tmpdir |

The **testing diamond still applies** — just re-scoped:

```
                    ┌────────────────────────┐
                    │  E2E simulation (thin) │  live npx init gated by env var
                    └────────────────────────┘
                ┌──────────────────────────────────┐
                │   Integration (the bulk)          │  real tmpdirs, real hooks,
                │   — 5 bash suites, 96 assertions  │  real JSON validity, zero mocks
                └──────────────────────────────────┘
            ┌──────────────────────────────────────────┐
            │   Contract / Prove-It-Gate (wide base)    │  liveness-checked contracts
            └──────────────────────────────────────────┘
```

Mocking rule: **none**. Tests run the actual binary against actual filesystems, invoke actual hook scripts with real stdin. If a test could pass against `exit 0`, it's a tautology — rewrite it or delete it.

---

## Test suites

5 suites, 96 assertions total. Each file is independently runnable (`bash tests/<name>.sh`).

### tests/test-cli.sh (24 assertions — CLI integration)

Runs the real `cli/bin/gdlc-wizard.js` binary. Covers:

- `--help` / `--version` / unknown flags
- `init` dry-run writes nothing, plans everything
- `init` creates exactly 9 files (settings.json + 3 hook files + 4 skills + wizard doc)
- File parity with `skills/` source (byte-identical)
- `init --force` overwrites cleanly
- `.gitignore` gets exactly `.claude/plans/` and `.claude/settings.local.json`, no dupes on re-run
- Installed hooks are executable where required
- `settings.json` is valid JSON, declares 2 events, uses `$CLAUDE_PROJECT_DIR` (never `${CLAUDE_PLUGIN_ROOT}`)
- Hook content is **GDLC-specific** — no residual `SDLC BASELINE`, `setup-wizard`, `SDLC.md` strings
- `check` reports MATCH / MISSING / JSON output correctly
- `_find-gdlc-root.sh` IS in the CLI's FILES array (this is the fix for SDLC's silent install bug where its own helper was missing)

### tests/test-hooks.sh (13 assertions — hook behavior)

Invokes the three shipped hook scripts with constructed fixtures. Covers:

- `_find-gdlc-root.sh` walks up from CWD and locates `GDLC.md` correctly
- `gdlc-prompt-check.sh` emits `GDLC BASELINE` when `GDLC.md` is present + non-empty
- `gdlc-prompt-check.sh` emits `SETUP NOT COMPLETE` when `GDLC.md` is empty (pointing to `/gdlc-setup`)
- Silent outside a GDLC-managed project (exit 0, no output)
- Always exit 0 (never blocks the user's prompt)
- `instructions-loaded-check.sh` stays silent on a valid state
- CI YAML sanity check (basic parseability)

### tests/test-install-script.sh (18 assertions — structural + gated-live)

Validates `install.sh` without executing `curl | bash`. Covers:

- Strict mode present (`set -euo pipefail`)
- Download-guard brace structure present (`{ ... }` so partial downloads don't execute)
- Shebang is clean bytes (no escaped-bang, no BOM — `xxd` check)
- `--global` flag wired up
- Node ≥ 18 preflight
- No legacy SDLC package-name leakage (the install script must reference only `claude-gdlc-wizard`, never the SDLC sibling's package names — guarded by a denylist grep in the test, not enumerated in this doc)
- At least one `claude-gdlc-wizard` reference
- Live-install path gated behind `CLAUDE_GDLC_WIZARD_NPM_PUBLISHED=1` (package isn't on npm yet — flip the gate after publish to enable the end-to-end test)

### tests/test-plugin.sh (20 assertions — plugin + CLI parity)

The P0 guard against plugin-vs-CLI drift. Covers:

- `plugin.json` valid JSON, name kebab-case, version matches `package.json`
- `hooks/hooks.json` uses `${CLAUDE_PLUGIN_ROOT}` — never `$CLAUDE_PROJECT_DIR`
- `cli/templates/settings.json` uses `$CLAUDE_PROJECT_DIR` — never `${CLAUDE_PLUGIN_ROOT}`
- Event parity: plugin `hooks.json` and CLI `settings.json` declare the **same** event set (today: `UserPromptSubmit` + `InstructionsLoaded`)
- `marketplace.json` valid, version matches
- Skill + hook byte-parity between plugin path and CLI install path

Swapping the two path-prefix vars silently breaks installs. These tests are the only line of defense; do not weaken them.

### tests/test-skill-contracts.sh (21 assertions — Prove-It-Gate)

Contract tests against the 4 skills and `CLAUDE_CODE_GDLC_WIZARD.md`. Covers:

- `effort: high` (or stricter) across all 4 skills
- `gdlc-setup/SKILL.md` has a 9-step registry + 5-line metadata block matching the template in the wizard doc
- `gdlc-setup` scaffolds `.gdlc/feedback-log.md`
- Never-vendor-playbook rule present (skills read `~/gdlc/`, don't bundle it)
- `gdlc-update` references CHANGELOG + sibling repo
- `gdlc-feedback` uses **stock GitHub labels only** (`bug`/`enhancement`/`question`) — no legacy `feedback:*` custom labels
- 5 canonical type identifiers present (`earned-rule-candidate`, `playbook-gap`, `playbook-bug`, `wizard-bug`, `methodology-question`)
- `[<type>]` prefix format enforced on issue titles
- Explicit allowlist with EXCLUDED class
- Wizard doc has template + step registry + managed-files section + no stale SDLC refs

### Running the full suite

```bash
# Required: restore hooks/ first (session quirk — see CLAUDE.md)
git checkout -- hooks/

# All 5 suites sequentially, stop on first failure
for t in tests/*.sh; do echo "--- $t"; bash "$t" || break; done

# Expected: "All tests passed" from each, 96 total assertions, 0 failures
```

---

## CI

Runs on push + PR via `.github/workflows/ci.yml`. Ubuntu latest. Installs `jq` + `xxd`. Iterates `tests/*.sh` and fails fast on any suite failure.

Known CI consideration: if the `xxd` or `jq` install step is removed, `tests/test-install-script.sh::test_shebang_no_escaped_bang` and `tests/test-plugin.sh` will green-fail by skipping their checks. Do not remove those apt-gets.

---

## Manual / Exploratory Testing

### Fresh-tmpdir install simulation

```bash
tmp=$(mktemp -d); cd "$tmp"
node /Users/stefanayala/claude-gdlc-wizard/cli/bin/gdlc-wizard.js init
# Expect: 9 files created under .claude/ + CLAUDE_CODE_GDLC_WIZARD.md + .gitignore
node /Users/stefanayala/claude-gdlc-wizard/cli/bin/gdlc-wizard.js check
# Expect: every installed item reports MATCH (settings + 3 hook files + 4 skills + wizard doc + 1 .gitignore row covering 2 entries = 10 rows), exit 0
node /Users/stefanayala/claude-gdlc-wizard/cli/bin/gdlc-wizard.js init
# Expect: all SKIP, exit 0 (idempotent)
node /Users/stefanayala/claude-gdlc-wizard/cli/bin/gdlc-wizard.js init --force
# Expect: OVERWRITE rows, exit 0
```

### Settings-merge check (P0 — don't clobber user hooks)

Feed `cli/init.js::mergeSettings` a pre-existing `.claude/settings.json` containing a hook for an unrelated plugin. After init, both the unrelated hook AND the gdlc hooks should be present. Tested by `tests/test-cli.sh`, but re-verify manually after any change to `cli/init.js`.

---

## Known gaps

- **Live `curl | bash` install is gated** — package not on npm yet. Flip `CLAUDE_GDLC_WIZARD_NPM_PUBLISHED=1` after publish to exercise the full end-to-end path.
- **Plugin-install detection not implemented** — SDLC's `cli/init.js` has a "dual-install" branch for when the plugin is already installed via Claude Code marketplace. Lower priority while there's no gdlc-wizard plugin distribution in the wild.
- **Hook behavior under real `UserPromptSubmit` / `InstructionsLoaded` dispatch is not tested** — tests invoke the scripts directly with mock stdin. The actual CC dispatch is CC's concern; we validate output shape, not wiring.
- **Statistical / multi-trial regression testing** is not set up — SDLC wizard has 5-trial statistical harnesses for scoring variance. This repo's tests are deterministic contracts, so that apparatus isn't needed today. Reconsider if/when we add AI-scored correctness checks (e.g., "does the scaffolded `GDLC.md` match the target case-study shape").

---

## Session-local quirks (not bugs)

- `./hooks/` gets wiped between Bash tool calls in this specific dev environment. Workaround: `git checkout -- hooks/` before every test run. CI and consumer installs are unaffected — verified by running the suite in a fresh clone where no wipe occurs.
