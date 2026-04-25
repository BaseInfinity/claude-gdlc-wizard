<!-- SDLC Wizard Version: 1.30.0 -->
<!-- Setup Date: 2026-04-24 -->
<!-- Completed Steps: step-0.1, step-0.2, step-1, step-2, step-3, step-4, step-5, step-6, step-7, step-9 -->
# SDLC Configuration — claude-gdlc-wizard

## Wizard Version Tracking

| Property | Value |
|----------|-------|
| Wizard Version (active) | 1.30.0 — from global plugin `~/.claude/plugins-local/sdlc-wizard-wrap/` |
| Wizard Version (upstream) | 1.36.1 at `~/tmp-refs/claude-sdlc-wizard/` (stale by 6 minor versions; see `reference_sdlc_wizard_wrap.md`) |
| Setup Date | 2026-04-24 |
| Claude Code Baseline | v2.1.69+ required (`InstructionsLoaded` hook, skill directory variable, Tasks system) |
| Recommended Model | `opus[1m]` (Opus 4.7, 1M context) — `/model opus[1m]` |
| Recommended Effort | `max` (default) / `xhigh` (floor) — `/effort max` at session start |

> **Effort warning (Opus 4.7):** anything below `xhigh` causes shallow reasoning, skipped TDD, and SDLC non-compliance in practice. `max` is the working default for wizard/skill/CI code in this repo.

## Why SDLC here

This repo ships the **GDLC** wizard — but the wizard itself is a Node CLI + bash hooks + plugin manifest, and that's a software project. Per [xdlc](~/xdlc/README.md) §"The Interop Pattern", every project runs two lifecycles in parallel:

- **SDLC** — does the code work? Is it tested? (TDD, self-review, CI shepherd) → governs *how* this wizard is built
- **GDLC** — is the game good? Is it fair? (playtests, triangulation, ratchet) → this is what the wizard *distributes*

SDLC on this repo keeps the distribution machinery honest. GDLC is not consumed here — this repo isn't a game.

## SDLC Enforcement

### 1. Planning before coding

- Multi-step tasks use Claude Code's `TaskCreate` / `TodoWrite`
- Confidence levels stated before implementation (HIGH / MEDIUM / LOW — LOW means ask, don't guess)
- Plan mode used for any change spanning ≥ 2 files

### 2. TDD Red → Green → Pass

- Every new contract/behavior: write the failing bash test in `tests/*.sh` first, see it fail, then implement
- Prove-It-Gate discipline: a test that would pass against a stub (`exit 0`) is a tautology — rewrite it
- Liveness check: temporarily break the contract and confirm the test catches it before treating it as a real guard

### 3. Self-review before handoff

- `.reviews/preflight-<name>.md` — self-review *before* Codex hands off
- `.reviews/handoff-<name>.json` — mission-first, success-criteria, failure-modes, 10+ concrete verification checklist items
- Never paper over concerns; flag them, let Codex decide whether to push back

### 4. Cross-model review (Codex)

- Default for any release or wizard/skill/CI change
- Round 1 = handoff, round 2+ = recheck after fixes. Not one-shot — it's a dialogue
- Score ≥ 7 is the bar; anything less = another round

## Hooks active on this repo

These come from the globally-enabled `sdlc-wizard@sdlc-wizard-local` plugin (v1.30.0 at `~/.claude/plugins-local/sdlc-wizard-wrap/plugins/sdlc-wizard/hooks/`). They fire in every directory without per-repo wiring.

| Hook | Event | Purpose |
|------|-------|---------|
| `sdlc-prompt-check.sh` | `UserPromptSubmit` | SDLC baseline reminder on every prompt |
| `instructions-loaded-check.sh` | `InstructionsLoaded` | Validates `SDLC.md` + `TESTING.md` exist; fires "SETUP NOT COMPLETE" nag otherwise |
| `tdd-pretool-check.sh` | `PreToolUse` (Write/Edit/MultiEdit) | TDD reminder when editing implementation files |
| `_find-sdlc-root.sh` | sourced by others | Walk-up helper to locate project root |

**Not installed (missing from v1.30.0):** `precompact-seam-check.sh` (PreCompact block mid-review/rebase), `model-effort-check.sh` (upgrade nudge). Added in upstream v1.32+. To get them, rsync upstream into the wrap dir per the reference memory.

## Skills available (from the global plugin)

| Skill | Invoke | Purpose |
|-------|--------|---------|
| SDLC | `/sdlc-wizard:sdlc` | Full SDLC workflow guidance on a specific task |
| Setup | `/sdlc-wizard:setup` | The wizard that generated this SDLC.md / TESTING.md / etc. |
| Update | `/sdlc-wizard:update` | Smart update with drift detection against upstream |
| Feedback | `/sdlc-wizard:feedback` | Privacy-first community feedback to upstream |

## Tests as the compliance gate

- Full suite (94 assertions, 0 failures) must be green before any commit
- Run: `git checkout -- hooks/ && for t in tests/*.sh; do bash "$t" || break; done`
- CI re-runs on push + PR via `.github/workflows/ci.yml`

See `TESTING.md` for suite-by-suite detail and the meta-testing framing.

## Compliance verification

Before declaring any wizard/skill/CI change done:

```bash
# 1. Tests green (94/94)
git checkout -- hooks/ && for t in tests/*.sh; do bash "$t" || break; done

# 2. `check` reports no drift
node cli/bin/gdlc-wizard.js check --json

# 3. Preflight written + committed
test -f .reviews/preflight-*.md && git diff --quiet HEAD -- .reviews/

# 4. Codex handoff drafted for anything user-facing
test -f .reviews/handoff-*.json

# 5. Conventional-commit message format, no AI attribution footer
git log -1 --pretty=%B | grep -qE '^(feat|fix|docs|test|chore|refactor)\(' \
  && ! git log -1 --pretty=%B | grep -qE 'Co-Authored-By.*Claude|Generated with.*Claude'
```

## Blast radius tier (for risk-scaled review)

Changes in this repo affect consumer installs the moment they publish. Treat every change as wide-blast-radius unless it's scoped to `.reviews/` or this file:

- **skills/** / **hooks/** / **cli/** / **install.sh** / **.claude-plugin/** → ships to every consumer on next publish → requires Codex round before merge
- **tests/** / **.github/workflows/** → affects CI honesty → requires preflight self-review at minimum
- **README.md** / **CHANGELOG.md** / **CLAUDE_CODE_GDLC_WIZARD.md** → consumer-facing docs → requires honest-language audit (no AI slop)
- **SDLC.md** / **TESTING.md** / **ARCHITECTURE.md** / **CLAUDE.md** → internal-dev only → standard review

## References

- `TESTING.md` — test strategy + suite index
- `ARCHITECTURE.md` — what this repo is structurally
- `CLAUDE.md` — project overview + commands + code style
- `~/xdlc/README.md` — the XDLC meta-framework + Interop Pattern §
- `~/.claude/projects/-Users-stefanayala/memory/reference_sdlc_wizard_wrap.md` — how the active plugin gets here and how to update it
