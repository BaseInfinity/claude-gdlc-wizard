# Architecture — claude-gdlc-wizard

## System overview

```
                         ┌───────────────────────────────────┐
                         │  BaseInfinity/gdlc   (playbook)   │
                         │  ~/gdlc/  — GDLC.md + CHANGELOG   │
                         └──────────────┬────────────────────┘
                                        │ read-only sibling dependency
                                        │ (skills read this; never bundled)
                                        ▼
 ┌────────────────────────────────────────────────────────────────────────┐
 │  BaseInfinity/claude-gdlc-wizard   (this repo — distribution)         │
 │                                                                        │
 │   skills/     ◀─── ported verbatim from ~/gdlc/.claude/skills/        │
 │   hooks/      ◀─── 2 enforcement hooks + 1 sourced helper              │
 │   cli/        ◀─── Node CLI: init / check / --force / --dry-run / JSON │
 │   install.sh  ◀─── curl|bash bootstrap → npx claude-gdlc-wizard        │
 │   .claude-plugin/  ◀─── plugin.json + marketplace.json                 │
 │   CLAUDE_CODE_GDLC_WIZARD.md  ◀─── canonical wizard doc (shipped)      │
 │   tests/      ◀─── 5 bash suites, 94 assertions, CI-gated              │
 │   .reviews/   ◀─── per-release preflight + Codex handoff               │
 └──────────────────────────────┬─────────────────────────────────────────┘
                                │  distribution channels
                                ▼
         ┌──────────────┬──────────────┬────────────────┬─────────────────┐
         │  npx         │  curl|bash   │  CC plugin     │  manual clone   │
         │  (planned)   │  install.sh  │  marketplace   │  (v0 path)      │
         └──────────────┴──────────────┴────────────────┴─────────────────┘
                                │
                                ▼
                    Consumer game project (~/somegame/)
                      ├── .claude/hooks/       (CLI mode → $CLAUDE_PROJECT_DIR)
                      ├── .claude/skills/
                      ├── .claude/settings.json
                      └── CLAUDE_CODE_GDLC_WIZARD.md
```

## Repo layout

```
claude-gdlc-wizard/
├── .claude-plugin/
│   ├── plugin.json            — name: gdlc-wizard, version: 0.1.0
│   └── marketplace.json       — local-marketplace wrapper listing
├── .github/
│   └── workflows/
│       └── ci.yml             — runs tests/*.sh on push + PR
├── .gitignore                 — node_modules, build artifacts, .claude/plans/, .claude/settings.local.json
├── .reviews/                          (all review artifacts — see directory listing for current state)
│   ├── preflight-*.md                  — per-release self-review
│   ├── handoff-*.json                  — Codex cross-model handoff with status field (PENDING_REVIEW / PENDING_RECHECK / CERTIFIED)
│   ├── codex-prompt-*.txt              — exact prompt sent to Codex per round
│   ├── codex-review-*.md               — Codex final-message verdict per round
│   └── codex-review-*.log              — full Codex transcript per round (gitignored if > 100 KB)
├── cli/
│   ├── bin/gdlc-wizard.js     — CLI entry: --help/--version/init/check, flag parser
│   ├── init.js                — install logic: FILES array, mergeSettings, gitignore, check
│   └── templates/
│       └── settings.json      — CLI-mode hook registration ($CLAUDE_PROJECT_DIR)
├── hooks/
│   ├── _find-gdlc-root.sh     — sourced helper: walks up CWD to find GDLC.md
│   ├── gdlc-prompt-check.sh   — UserPromptSubmit: GDLC BASELINE / SETUP NOT COMPLETE
│   ├── instructions-loaded-check.sh  — InstructionsLoaded: missing-GDLC.md warning + dual-install nudge
│   └── hooks.json             — plugin-mode hook registration (${CLAUDE_PLUGIN_ROOT})
├── skills/
│   ├── gdlc/SKILL.md              — cycle picker, triangulation, P0-to-TDD promotion
│   ├── gdlc-setup/SKILL.md        — conversational setup wizard (auto-scan, confidence-driven)
│   ├── gdlc-update/SKILL.md       — CHANGELOG diff, drift detection, per-file apply
│   └── gdlc-feedback/SKILL.md     — structured upstream issues (stock labels + canonical types)
├── tests/
│   ├── test-cli.sh            — CLI integration  (22 assertions)
│   ├── test-hooks.sh          — hook behavior    (13 assertions)
│   ├── test-install-script.sh — install.sh      (18 assertions)
│   ├── test-plugin.sh         — plugin + CLI parity (20 assertions)
│   └── test-skill-contracts.sh— Prove-It-Gate   (21 assertions)
├── CHANGELOG.md
├── CLAUDE.md                  — Claude instructions for developing THIS repo
├── CLAUDE_CODE_GDLC_WIZARD.md — wizard doc SHIPPED to consumers
├── README.md                  — consumer-facing install + overview
├── SDLC.md                    — SDLC discipline + enforcement on this repo
├── TESTING.md                 — test strategy + suite index
├── ARCHITECTURE.md            — this file
├── install.sh                 — curl|bash installer
└── package.json               — bin: gdlc-wizard, files: cli/ skills/ .claude-plugin/
```

## Component descriptions

### `skills/` (the payload)

Four markdown files with YAML frontmatter. Consumers invoke them as `/gdlc`, `/gdlc-setup`, `/gdlc-update`, `/gdlc-feedback`. These are ported verbatim from `~/gdlc/.claude/skills/` — the upstream playbook repo — and kept byte-identical via test-skill-contracts.sh. **Do not edit skills in this repo without a synchronized update to `~/gdlc/`**, otherwise drift accumulates between the playbook and the distribution.

### `hooks/` (enforcement at session boundaries)

Three files. Only 2 are executable:

- **`gdlc-prompt-check.sh`** fires on `UserPromptSubmit`. Reads project root via `_find-gdlc-root.sh`, inspects `GDLC.md`, and emits one of: `GDLC BASELINE:` (case-study loaded, cycle reminder), `SETUP NOT COMPLETE:` (GDLC.md empty — directs to `/gdlc-setup`), or silent (not in a GDLC project). **Always exits 0.** Blocking the user's prompt is not an option.
- **`instructions-loaded-check.sh`** fires on `InstructionsLoaded`. Validates session-start state; surfaces dual-install guidance if `claude-sdlc-wizard` is detected alongside.
- **`_find-gdlc-root.sh`** is sourced, not executed. It walks up from CWD until it finds a `GDLC.md`, sets `GDLC_ROOT`, or returns non-zero if no project root is found.

Shipped by the plugin via `hooks/hooks.json` (using `${CLAUDE_PLUGIN_ROOT}`) and by the CLI via `cli/templates/settings.json` (using `$CLAUDE_PROJECT_DIR`). Both declare the **same 2 events** — `UserPromptSubmit` and `InstructionsLoaded`. Event parity is enforced by `tests/test-plugin.sh`; drift between them means plugin users and CLI users would see different behavior.

### `cli/` (the installer surface)

Node 18+, CommonJS, zero runtime deps. Two files do the real work:

- `cli/bin/gdlc-wizard.js` — thin arg parser, dispatches to `init` or `check`. Supports `--force`, `--dry-run`, `--json`, `--version`, `--help`.
- `cli/init.js` — the install engine. A declarative `FILES` array (8 entries today) drives copy logic; `mergeSettings(...)` grafts gdlc hooks into an existing `.claude/settings.json` without clobbering unrelated user hooks; `.gitignore` gets `.claude/plans/` + `.claude/settings.local.json` added idempotently; `check(...)` diffs installed files against source and exits non-zero on drift.

**Critical invariant:** `_find-gdlc-root.sh` is in `FILES`. The sibling SDLC wizard has a silent bug where its analogous helper is not installed, so CLI-installed hooks fail at `source` time. GDLC ships the helper — deliberately.

### `install.sh` (the curl-pipe entry)

`curl -fsSL https://claude-gdlc-wizard.baseinfinity.dev/install | bash`. Downloads inside a `{ ... }` group so a partial download cannot execute. Checks Node ≥ 18, installs `claude-gdlc-wizard` globally (or via `npx -y`), runs a post-install verification that `.claude/hooks/gdlc-prompt-check.sh` exists. `--global` flag supported.

### `.claude-plugin/` (Claude Code plugin distribution)

`plugin.json` declares the plugin with name `gdlc-wizard` and the same version as `package.json`. `marketplace.json` is a local-marketplace listing for when/if we mirror the `sdlc-wizard-wrap` pattern (see `reference_sdlc_wizard_wrap.md` in global memory).

### `tests/` (the compliance gate)

5 bash suites, 94 assertions, integration-heavy, zero mocks. See `TESTING.md` for the per-suite breakdown. CI runs all 5 on every push + PR.

### `.reviews/` (per-release QA)

Every significant release ships with `preflight-<release>.md` (self-review) and `handoff-<release>.json` (Codex cross-model handoff). Format:

- `preflight-*.md` — what's built, what's manually verified, intentional scope cuts, specific concerns flagged for reviewer, known limitations, self-graded score
- `handoff-*.json` — mission / success / failure / files_changed / verification_checklist / review_instructions — mission-first, no rubber-stamping

## Distribution channels

| Channel | Status | Use case |
|---------|--------|----------|
| `npx claude-gdlc-wizard init` | **Planned** (package not on npm yet) | Canonical install, no local state |
| `curl \| bash` via `install.sh` | Ready (gated until npm publish) | Quick bootstrap, scriptable |
| Claude Code plugin marketplace | Ready (manifest complete) | `/plugin install gdlc-wizard@<marketplace>` |
| Manual clone + copy | v0 path (documented in README.md) | Current default until publish |

## Key decisions

### Sibling-dependency retained (Path B default for v0.1.0)

Skills read `~/gdlc/` at runtime for playbook content (GDLC.md, CHANGELOG.md, FEEDBACK_SKILL_SPEC.md). Not bundled, not vendored. Rationale: the playbook is an **evolving source of truth** tied to case studies; bundling it into the wizard means version drift the moment ~/gdlc/ updates. The downside is an extra clone step (`git clone ...gdlc ~/gdlc`).

**Path A** (consolidate `~/gdlc/` into this repo and archive `BaseInfinity/gdlc`) is under user consideration. Decision not made yet; flagged in ROADMAP §1.4. If Path A wins, the skills' `~/gdlc/` reads collapse to local-repo reads, and the framework content ships alongside the distribution.

### Plugin-mode vs CLI-mode path-prefix split

Plugin users get `${CLAUDE_PLUGIN_ROOT}` prefixes (resolved by CC from plugin install location). CLI users get `$CLAUDE_PROJECT_DIR` prefixes (resolved against consumer project root). Same hook scripts, two different resolution contexts. Swapping these breaks installs silently — only the test suite catches the mismatch. Reinforced by `tests/test-plugin.sh`.

### 2 hooks only (vs SDLC's 5)

Dropped `tdd-pretool-check.sh` (code-specific), `model-effort-check.sh` (SDLC-shaped nudge), `precompact-seam-check.sh` (depends on SDLC handoff.json schema). GDLC-specific hooks only. Users who want code-TDD discipline install `claude-sdlc-wizard` alongside — the dual-install is the explicit recommendation, not a bug.

### No `scripts/` directory

SDLC has several (score-analytics, API-changelog parsing, benchmark harnesses) with no GDLC analog today. Don't pre-build; earn them from a concrete need.

### `_find-gdlc-root.sh` is installed (GDLC-specific fix)

SDLC's CLI init omits its analogous helper — CLI-installed hooks then fail at `source` time, but tests pass because the failure is at runtime, not install time. GDLC's `cli/init.js::FILES` includes the helper deliberately; `test-cli.sh::test_creates_all_files` counts it.

## References

- `SDLC.md` — SDLC enforcement + hook inventory for this repo
- `TESTING.md` — test strategy + per-suite breakdown
- `CLAUDE.md` — project overview + code-style + session quirks
- `CLAUDE_CODE_GDLC_WIZARD.md` — the wizard doc shipped to consumers
- `~/gdlc/ROADMAP.md` — Phase 1/2/3 distribution plan (Codex adapter, gh extension, Homebrew tap)
- `~/xdlc/README.md` §Repo Map + §Proven Patterns — ecosystem context
