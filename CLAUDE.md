# claude-gdlc-wizard — Claude Instructions

> **Part of the [XDLC ecosystem](https://github.com/BaseInfinity/xdlc)** — this is the Claude Code distribution repo for the GDLC sibling. SDLC runs on this repo's *own* development in parallel; GDLC is what this repo *ships* to consumer game projects.
>
> **Skills first → wizard later.** This repo exists because the four `/gdlc*` skills already proved themselves on case study #1 (codeguesser: 17 playtests, 355+ regression tests, 26 earned rules). The wizard form earns its keep once case study #2 (pdlc/TamAGI) validates portability — per xdlc's graduation gate.

## Project Overview

This is a **meta-repository**. It contains the distribution machinery for the GDLC wizard, not game code.

### What this repo contains

- `GDLC.md` — the **framework playbook** (264 lines: cycles, personas, rubrics, earned rules from case study #1). Consolidated from `~/gdlc/` 2026-04-25 (Path A).
- `ROADMAP.md` — Phase 1/2/3 distribution roadmap. Phase 1 closed; Phase 2 (`codex-gdlc-wizard`) and Phase 3 (Homebrew/gh/curl) pending.
- `FEEDBACK_SKILL_SPEC.md` — design spec for the feedback skill.
- `PLAYBOOK_CHANGELOG.md` — framework changelog (rule-version history, playtest cycles, skill bumps). Distinct from `CHANGELOG.md` which tracks the distribution wizard.
- `skills/{gdlc,gdlc-setup,gdlc-update,gdlc-feedback}/SKILL.md` — the 4 skills consumers install.
- `hooks/{gdlc-prompt-check.sh, instructions-loaded-check.sh, _find-gdlc-root.sh}` — 2 enforcement hooks + 1 sourced helper.
- `hooks/hooks.json` — plugin-format registration (`${CLAUDE_PLUGIN_ROOT}`).
- `cli/bin/gdlc-wizard.js` + `cli/init.js` + `cli/templates/settings.json` — Node CLI (`npx claude-gdlc-wizard init`).
- `install.sh` — `curl | bash` bootstrap pointed at `npx claude-gdlc-wizard`.
- `.claude-plugin/{plugin.json,marketplace.json}` — Claude Code plugin manifest + local marketplace listing.
- `CLAUDE_CODE_GDLC_WIZARD.md` — the canonical wizard doc shipped to consumers.
- `tests/*.sh` — 5 bash test suites, 96 assertions (see TESTING.md).
- `.github/workflows/ci.yml` — runs the full test suite on push + PR.
- `.reviews/` — preflight + Codex cross-model handoff per release.

### Path A — single-repo consolidation (2026-04-25, v0.2.0)

This repo is now the single home for both **framework playbook** (GDLC.md and friends) and **distribution wizard** (CLI, plugin, hooks, install scripts). Matches SDLC's pattern: `claude-sdlc-wizard` is the only SDLC repo too — there's no separate `~/sdlc/` framework repo.

**Pending v0.2.x cleanup:** the skills still reference `~/gdlc/` for runtime reads (drift detection, CHANGELOG fetch URLs, issue-tracker URL in `gdlc-feedback`). Migration to local-repo paths is queued — held until a Codex round green-lights the v0.2.0 consolidation. Until then, both `~/gdlc/` (deprecated) and `~/claude-gdlc-wizard/` work; new installs should use the latter.

### What this repo does NOT contain

- No game code. This is a wizard that sets up *other* projects.
- No build pipeline. Plain JS + bash scripts; npm handles publication.
- No `src/` directory. Top-level dirs (`cli/`, `hooks/`, `skills/`) are the source.
- No linter config. Plain JS, shellcheck-compatible bash, no TypeScript.
- No runtime dependencies at install time beyond Node ≥ 18 and standard POSIX tools.

### Test dependencies

- `bash` (3.x+ on macOS, 4.x+ on Linux)
- `node` ≥ 18 (for CLI tests that exec `cli/bin/gdlc-wizard.js`)
- `jq` (JSON validation in test-plugin.sh / test-cli.sh)
- `xxd` (shebang byte-check in test-install-script.sh)
- `git` (version-control assertions)

## Commands

All tests are bash, run directly. `package.json` intentionally has no `scripts` — the suites are the interface.

| Command | Purpose |
|---------|---------|
| `git checkout -- hooks/ && for t in tests/*.sh; do bash "$t" \|\| break; done` | Full test run (restore hooks first — see *Session quirks* below) |
| `bash tests/test-cli.sh` | CLI integration (init/check/help/version, 24 assertions) |
| `bash tests/test-hooks.sh` | Hook behavior (`_find-gdlc-root` walk-up, SETUP-vs-BASELINE emission, 13 assertions) |
| `bash tests/test-install-script.sh` | Install-script structure (18 assertions; live-install gated by `CLAUDE_GDLC_WIZARD_NPM_PUBLISHED=1`) |
| `bash tests/test-plugin.sh` | Plugin/CLI parity (plugin.json + marketplace.json validity, hooks.json events, path-prefix split, 20 assertions) |
| `bash tests/test-skill-contracts.sh` | Prove-It-Gate contract tests across all 4 skills + wizard doc (21 assertions) |
| `node cli/bin/gdlc-wizard.js --help` | Inspect the CLI surface |
| `node cli/bin/gdlc-wizard.js init --dry-run` | Print the install plan without writing (safe to run anywhere) |
| `cd $(mktemp -d) && node /Users/stefanayala/claude-gdlc-wizard/cli/bin/gdlc-wizard.js init` | Real install in a throwaway scratch dir |

## Code Style

### Bash (hooks + tests)

- `#!/usr/bin/env bash` shebang
- `set -euo pipefail` at the top of new scripts
- Quote every variable: `"$VAR"` not `$VAR`
- Prefer `$(…)` over backticks
- Use `printf` for structured output; only use `echo` for simple static strings
- POSIX-compatible where feasible — consumers may run on bash 3.2 (macOS)

### JavaScript (CLI)

- Plain CommonJS (no ESM, no TypeScript, no bundler)
- No third-party runtime dependencies; stdlib only
- Functions over classes
- Explicit error exit codes (0 = OK, 1 = drift/missing, 2 = user error)

### JSON (manifests, settings)

- 2-space indent
- Trailing newline
- Schema parity between `hooks/hooks.json` (plugin, `${CLAUDE_PLUGIN_ROOT}`) and `cli/templates/settings.json` (CLI, `$CLAUDE_PROJECT_DIR`) is **load-bearing** — the tests enforce it

### Markdown (skills + wizard doc)

- ATX headers (`#`, `##`, `###`)
- Tables for structured data
- Fenced code blocks with language hints
- Keep lines under ~100 chars when practical, never hard-wrapped

## Architecture

See `ARCHITECTURE.md` for the full diagram and component boundaries.

## Testing

See `TESTING.md`. Short version: this is a **meta-project**, so tests exercise wizard installation + script behavior + plugin parity, not application code. 96 assertions across 5 suites today; Prove-It-Gate discipline — no tautologies.

## Git / Commits

- Conventional Commits format: `type(scope): description` (e.g., `feat(cli): …`, `fix(hooks): …`, `test(skills): …`, `docs(review): …`)
- **Never** include Claude Code attribution footer (no `🤖 Generated with…`, no `Co-Authored-By: Claude …`). This is a global rule from `~/.claude/CLAUDE.md` and applies here.
- Afterhours push guard: BaseInfinity repos block pushes Mon–Fri 08:00–17:00. Hold commits local during work hours; push off-hours.

## Session quirks (this repo only)

- `./hooks/` gets wiped between Bash tool calls in this specific dev environment (likely the afterhours git-hook chain via `core.hookspath=~/.afterhours/hooks` running on tool-call boundaries). Not reproducible on clean checkouts and does not affect CI or consumer installs.
- Workaround: `git checkout -- hooks/` before any local test run. Tests pass atomically when hooks are present.

## Quality Anchoring

- This project runs on Opus 4.7 with effort ≥ `xhigh`. Treat `max` as the default for multi-file changes (wizard/skill/CI code) and any cross-model review.
- Adaptive thinking may under-allocate on complex tasks. For architecture decisions or debugging, reason through the full problem before acting — don't take the "simplest first" path the system prompt suggests.
- If reasoning feels shallow, raise effort rather than prompting around it.

## References

- `SDLC.md` — the enforcement checklist + hook inventory + version tracking
- `TESTING.md` — the meta-testing strategy + test-suite index + CI integration
- `ARCHITECTURE.md` — repo layout, distribution channels, key decisions
- `CLAUDE_CODE_GDLC_WIZARD.md` — the **shipped** wizard doc (consumers read this; it's not about building the wizard, it's about using it)
- `~/xdlc/README.md` — the XDLC meta-registry (the "why" behind this repo existing at all)
- `~/gdlc/ROADMAP.md` — the full Phase 1/2/3 plan for the distribution graduation
