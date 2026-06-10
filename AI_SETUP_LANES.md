# AI Setup Lanes

Three recommended AI setups for this repo. Setups A and B are complete triads: **planner → driver → reviewer**. Setup C is a lightweight driver-only lane for operational grunt work.

This is **guidance, not a hard rule**. Maintainer override is always allowed.

## Setup A — GDLC Premium

| Role | Model |
|------|-------|
| **Planner** | Claude Code Opus 4.6 max |
| **Driver** | Claude Code Opus 4.6 max |
| **Reviewer** | Codex (GPT-5.5) xhigh |

Quality-first lane for game development. Opus 4.6 max drives both planning (persona design, gameplay matrix, pipeline architecture) and implementation (playtesting, regression tests, rule systems); GPT-5.5 xhigh is the cross-model final gate.

## Setup B — GDLC Saver

| Role | Model |
|------|-------|
| **Planner** | Claude Code Opus 4.6 max |
| **Driver** | Claude Code Sonnet (latest available) |
| **Reviewer** | Codex (GPT-5.5) xhigh |

Cost-efficient lane. Keeps Opus 4.6 max as the planning brain — where persona reasoning and gameplay judgment matter most — but moves implementation to Sonnet for routine work. GPT-5.5 xhigh still the final reviewer.

## Setup C — GDLC Lite

| Role | Model |
|------|-------|
| **Planner** | You (the user) |
| **Driver** | Haiku 4.5 ($1/$5 per Mtok) |
| **Driver fallback** | Sonnet 4.6 standard |
| **Reviewer** | None |

For grunt work: asset pipeline scripts, build deploys, config updates, bulk file operations. No GDLC discipline needed — just fast cheap execution.

## When to Use Setup A

- Persona design or persona-driven playtest cycles
- Gameplay matrix changes (phases, mechanics, scoring)
- Art review pipeline or asset evaluation
- Regression test authoring (earned rules, triangulated findings)
- Architecture decisions (state machine, event system)
- Anything where creative judgment matters as much as correctness

## When to Use Setup B

- Routine implementation of pre-designed features
- Test maintenance (updating existing regression tests)
- Documentation
- Non-gameplay code changes
- Mechanical refactors

## When to Use Setup C

- Build scripts, deploy scripts
- Asset pipeline execution
- Config updates
- File moves, renames, bulk operations

## Final Review Policy

**Setups A and B end at GPT-5.5 xhigh as the cross-model reviewer.** Setup C has no reviewer.

## See Also

- [claude-sdlc-wizard `AI_SETUP_LANES.md`](https://github.com/BaseInfinity/claude-sdlc-wizard/blob/main/AI_SETUP_LANES.md) — Sibling lanes for the SDLC wizard
- [codex-sdlc-wizard `AI_SETUP_LANES.md`](https://github.com/BaseInfinity/codex-sdlc-wizard/blob/main/AI_SETUP_LANES.md) — Codex-side equivalent
