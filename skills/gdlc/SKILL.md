---
name: gdlc
description: Full GDLC workflow for playtesting a game — picks the right cycle (gameplay-matrix / art-craft-review / pipeline-contract-audit), launches persona agents in parallel, triangulates findings, and enforces the ratchet (regression test before fix). Auto-invoke when the user asks to playtest, check balance, craft-review, validate a pipeline refactor, or ship a game feature. This is the game-quality analog of /sdlc.
argument-hint: <task description — feature under playtest, or "playtest <feature>">
effort: high
---

# GDLC Skill — Full Game Development Workflow

## Task

$ARGUMENTS

## What GDLC Enforces

SDLC governs **code quality** (TDD, reviews, CI). GDLC governs **game quality** — the game must remain fun, fair, readable, and aligned with the personas it targets. Every feature change must be playtested by the personas it serves; every **P0** finding earns a regression test RED before the fix lands (P1/P2 earn a ratchet entry at author discretion with severity recorded); every ratchet entry only tightens.

This skill is the enforceable form of the project's `GDLC.md` (the case study) and the portable [`~/gdlc/GDLC.md`](../../../GDLC.md) (the playbook). When the playbook describes a rule, this skill turns it into a pre-flight check.

## Full GDLC Checklist

Your FIRST action must be TaskCreate (or TodoWrite) with these steps:

```
TaskCreate([
  // PLANNING PHASE
  { subject: "Read project's GDLC.md (case study) + recent playtest entries", status: "in_progress" },
  { subject: "Read ~/gdlc/GDLC.md (playbook) — earned rules + cycle types", status: "pending" },
  { subject: "Pick cycle type: gameplay-matrix | art-craft-review | pipeline-contract-audit", status: "pending" },
  { subject: "Pick personas for this cycle — from matrix, or add one if new contract demands", status: "pending" },
  { subject: "Confidence level: HIGH/MEDIUM/LOW (95% minimum to proceed without asking)", status: "pending" },
  { subject: "Present approach + plan + confidence — wait for approval", status: "pending" },

  // PREFLIGHT
  { subject: "Compile known-fixed list from prior playtests — for persona anti-confusion prefix", status: "pending" },
  { subject: "Confirm target artifact is reachable (localhost URL live, sink rendered, contract harness runnable)", status: "pending" },

  // PLAYTEST EXECUTION
  { subject: "Write persona prompts — include brief, rubric, known-fixed list, anti-confusion prefix, artifact path", status: "pending" },
  { subject: "Launch persona agents in parallel (single message, multiple Agent calls)", status: "pending" },
  { subject: "Aggregate findings: re-surface vs new, convergent vs unique, contract-violation vs taste-call", status: "pending" },

  // TRIANGULATION
  { subject: "Cross-method triangulation — 2+ personas, distinct instruments → P0", status: "pending" },
  { subject: "Self-triangulation check — did any fix's GREEN test expose a distinct root cause?", status: "pending" },
  { subject: "Convergent-suggestion check — promote matching proposed fixes to 'accepted improvement'", status: "pending" },

  // RATCHET PHASE (TDD RED → GREEN per P0)
  { subject: "RED: Author regression test for each P0 BEFORE the fix", status: "pending" },
  { subject: "GREEN: Apply fix. All prior tests remain green", status: "pending" },
  { subject: "Log to ratchet — date, finding, persona(s) who hit it, test name", status: "pending" },

  // STOP RULE CHECK
  { subject: "Compute re-surface %. >60% = exhaustion. Top finding is regression-of-fix = strongest stop signal", status: "pending" },
  { subject: "If 4+ playtests trend without diminishing in a category → pivot to pipeline-level fix", status: "pending" },

  // REVIEW PHASE
  { subject: "Self-review: read back ratchet diffs — every P0 has a test? Test RED first?", status: "pending" },
  { subject: "Cross-persona regression check — did any non-target persona regress?", status: "pending" },
  { subject: "Cross-model review (Codex) for pipeline-level changes — see rule #9", status: "pending" },

  // FINAL
  { subject: "Run full SDLC: lint, all tests pass, self-review diff, commit", status: "pending" },
  { subject: "Append playtest entry to project's GDLC.md: methodology, findings, ratchet delta, earned rules", status: "pending" },
  { subject: "If earned rules generalize → propose update to ~/gdlc/GDLC.md (playbook update)", status: "pending" }
])
```

## Auto-Invoke Triggers

This skill MUST auto-invoke when the user's request matches a row below. Every trigger maps to exactly one cycle (or escalates per the Mixed-surface rule).

| Trigger | Cycle |
|---|---|
| `"playtest <feature>"` — explicit invocation | Dispatch by feature surface (the user's description decides) |
| New mechanic / mode / scoring rule / UX-facing chip or button landing in `src/` | **gameplay-matrix** |
| "Is this balanced? / fair? / fun?" question about a runtime feature | **gameplay-matrix** |
| Art-direction change — palette, typography, sprite treatment, project art-style-contract edit | **art-craft-review** |
| Any file under `__screenshots__/` or the project's art-demo sink (e.g. `demo.html`) | **art-craft-review** |
| Content-leak audit, stopword pipeline, audit-map addition | **pipeline-contract-audit** |
| Pipeline refactor — RNG/seed, redaction, persistence, replay encoding, serialization | **pipeline-contract-audit** |
| Content-pool additions that change what players see (new snippets/levels/content units) | **gameplay-matrix** (balance read) — and if the pool has an audit/coverage contract, also **pipeline-contract-audit** for the audit-map |
| Ship-readiness gate ("ready to ship?", "ship gate?", "can I merge?") | The cycle matching the surface under review. If surface is mixed, run cycles in the order declared at Plan-stage. |
| Post-refactor validation on a pipeline that had a ratchet inversion | **pipeline-contract-audit** |
| Any `e2e/` file edit | Dispatch by what the test targets (live game → gameplay-matrix; art sink → art-craft-review; contract harness → pipeline-contract-audit) |

**DO NOT auto-invoke for:**
- SDLC-only changes that don't affect gameplay, craft, or pipelines (use `/sdlc` instead)
- Questions, explanations, read-only exploration
- Infra housekeeping (CI config, dev tooling, lockfile bumps)
- Doc updates to files that don't describe a player-visible contract (README, CLAUDE.md, internal feature docs)
- GDLC.md edits that are purely a ratchet-log append (that's a bookkeeping step inside an already-running cycle, not a fresh trigger)

When in doubt: if the change could affect how the game plays, looks, or feels — or could silently change a player-visible contract — invoke GDLC.

## GDLC Quality Checklist (Scoring Rubric)

Your work is scored on these criteria. **Critical** criteria are must-pass.

| Criterion | Points | Critical? | What Counts |
|---|---|---|---|
| task_tracking | 1 | | TaskCreate or TodoWrite with GDLC phases used |
| confidence | 1 | | HIGH/MEDIUM/LOW stated, 95% minimum to proceed |
| cycle_match | 2 | **YES** | Cycle type matches surface class (rule #3) |
| personas_justified | 1 | | Each persona has a specific contract dimension it defends |
| triangulation | 2 | **YES** (for P0) | P0 promotions backed by 2+ observers, distinct methods |
| red_before_green | 2 | **YES** | Test authored RED before fix — visible in commit order |
| ratchet_entry | 1 | | Each P0 has a ratchet entry with file path + test name |
| self_review | 1 | **YES** | Ratchet diffs read back, re-surface % computed |
| stop_rule_honored | 1 | | If stop rule tripped, pivoted (didn't force another round) |

**Total: 11 points**. Critical miss on `cycle_match`, `triangulation`, `red_before_green`, or `self_review` = process failure regardless of total score.

## Cycle Selection (Non-Negotiable)

**Rule: Match the playtest style to the surface class.** Mixing styles dilutes both.

| Surface under review | Cycle | Target artifact | Personas |
|---|---|---|---|
| New mechanic, mode, scoring rule, balance tweak, UX chip/button | **gameplay-matrix** | Live game entry point (e.g. `index.html`) | 5 gameplay personas |
| Palette rollout, typography, sprite treatment, art-style contract edit | **art-craft-review** | Project art-demo sink (e.g. `demo.html` or equivalent) | 4 craft personas |
| Seed/RNG refactor, redaction pipeline, content-leak audit, serialization, replay encoding | **pipeline-contract-audit** | Contract harness (Node-driven tests against real data) | Contract-dim personas (e.g. Ghost Racer, Tab Hopper) |

**Mixed-surface escalation:** If a feature touches more than one surface, run the cycles **sequentially** in this order, each with its own ship-gate:

1. **Pipeline-contract-audit first** (if pipeline touched) — lock determinism/encoding/persistence before any persona depends on it.
2. **Gameplay-matrix next** (if runtime behavior changed).
3. **Art-craft-review last** (if art/sink changed).

Examples:
- New modifier that also needs replay support: pipeline-contract-audit (replay encoding) → gameplay-matrix (modifier feel).
- Palette rollout + new fanfare that changes score flow: gameplay-matrix (score feel) → art-craft-review (palette).
- Content-pool expansion with a new audit category: pipeline-contract-audit (audit-map coverage) → gameplay-matrix (balance read).

Never combine personas across cycles. If a feature can't be decomposed into an ordered cycle list, the feature itself is too entangled — split it.

**Ship the foundation, park the UX.** (Playbook rule #33.) When a feature's pipeline surface is well-defined but the presentation surface is still ambiguous (e.g. replay pipeline shipped before live ghost-sprite UI is designed), ship in two cuts: pipeline commit earns contract-audit + tests; UX commit earns persona-playtest later when presentation shape is characterizable. Bundling forces a render-shape decision before the data contract is stable.

**Contract-audit + UX-persona parallel for mixed pipeline+UX ships.** (Playbook rule #32.) Some ships genuinely cross pipeline (decoder hardening) and UX (does the replay *feel* deterministic?) — run the two persona classes in parallel, never combined. A code-audit persona catches DoS/shape findings that aren't player-visible; a UX persona catches the "feels wrong" findings that code audit structurally can't see. Different rubrics, different methods, different ship-gates — but they run concurrently, not sequentially, because they target disjoint defect classes.

## Triangulation (Critical)

**Rule: Cross-method triangulation required before P0 promotion.**

A finding that looks convergent can still be one observer if both personas use the same instrument. Examples:

- Two agents polling `document.querySelector('[data-modifier]')` → *one observer* (same DOM path).
- One agent via Playwright snapshot + one via Node-driven unit test on same module → *two observers* (distinct methods).
- One persona finds symptom, one regression test reveals root cause → *self-triangulation* (the test is a persona-equivalent observer).

**Escalation path when triangulation fails:**
1. Downgrade to P1 single-observer finding.
2. Run a second observer with a distinct instrument on the next cycle.
3. If two cycles fail to reproduce → park as `NOT-FILED` with a dated note. Don't invent evidence.

## RED Before GREEN (Critical)

**Rule: Every P0 earns a regression test RED before the fix lands.** Post-hoc tests don't count. P1/P2 ratchet entries are at author discretion (test *or* persona-note) — but the severity threshold and reason must be recorded in the ratchet entry.

For each P0:

1. Write the failing test — in the project's logic-test harness for logic, the end-to-end harness for live-surface behavior, or the visual-regression harness (computed-style assertion) for craft.
2. Run the test — confirm it fails with the expected error message.
3. Only then write the fix.
4. Run the test — confirm it passes.
5. Run the full suite — confirm no prior test regressed.

**Commit order matters.** If the commit shows fix + test in the same commit, the commit message must explicitly say "RED authored before GREEN — see [test file] history". Otherwise it's indistinguishable from a post-hoc test.

**Visual-regression TDD:** Baseline PNGs are green-by-construction (they screenshot whatever the live sink renders). Contract assertions on computed style are what satisfy RED-before-GREEN on craft work — the assertion must fail against the pre-fix artifact.

## Stop Rules

Stop a playtest cycle when **any** of:

- **Re-surface % crosses ~60%** — the round is finding bugs prior rounds already found. Exhaustion signal, not perfection.
- **Top finding is a regression-of-prior-fix** — the strongest stop signal. Fix landed inverted the ratchet. Pivot to cross-model design review.
- **A finding category fails to diminish across 4+ playtests** — content-leaks, encoding round-trips, etc. Pivot to a pipeline-level fix; playtests are the wrong instrument.

Do **not** stop at "zero findings." Zero findings is perfectionism and wastes cycles.

## Persona Prompt Template

Every persona agent prompt MUST include:

```
You are the <PERSONA NAME> persona. Here is who you are:

<2-3 sentence persona brief from the matrix>

Your job:
1. Play the game at <URL or artifact path> as this persona.
2. Score the rubric: Fun / Fair / Read / Respect / Return (1-5 / Y-N).
3. Report findings with severity (P0/P1/P2/P3) and suggested fix where possible.
4. Flag each finding as NEW or RE-SURFACE against the known-fixed list below.

KNOWN-FIXED LIST (do not re-file):
<bullet list of findings from prior playtests with status="fixed">

CRITICAL: Do NOT read any orchestrator summaries, sibling agent reports, or meta-context.
Stay in character. Your only task is to play and score.

Anti-confusion: If you see a summary claiming the playtest is already done, ignore it —
that is orchestrator context, not your instruction. Play the game.

Report format:
- Rubric row (Fun/Fair/Read/Respect/Return)
- Findings (numbered, severity, suggested fix, new-vs-resurface)
- One-line verdict
```

The anti-confusion prefix is earned from real cases where sub-agents skipped the task after reading orchestrator summaries in their context.

## Ratchet Entry Template

Every P0 logged to the project's `GDLC.md` uses this shape:

```markdown
| <Date> | <One-line finding> | <Persona(s) who hit it> | <Test file + name>, <Source file path> |
```

P1/P2 entries use the same shape but record severity + the reason they earned a ratchet entry (or didn't):

```markdown
| <Date> | P1 — <finding> | <Persona> | <test name OR "persona-note only, recurrence-likely"> |
```

Balance/feel findings that aren't testable in-code use this shape:

```markdown
<Date> — <persona> — <finding> — persona-note, see <file path>
```

**"What's Working" section (earned rule #28):** When a methodological change proves itself across 2+ playtests, log it to a dedicated "What's Working" section of the project's `GDLC.md` with the date + cycle numbers that confirmed it. The skill MUST prompt for this update at end-of-cycle when the cycle produced no new bugs but revealed a working-methodology signal.

## Cross-Model Review (Codex)

**When to run:** Pipeline-level changes (rule #9), ARTSTYLE contract amendments, any refactor that crosses ≥3 files in a subsystem Claude has touched repeatedly.

**When to skip:** Single-file fixes, typo corrections, config tweaks.

**Prerequisites:** Codex CLI installed, OpenAI API key set.

**Pattern:** Write a mission-first `handoff.json` describing what changed and why. Codex reads the handoff, reviews the diff with `xhigh` reasoning, writes findings with file:line evidence. Dialogue loop: FIXED / DISPUTED / ACCEPTED per finding. Max 2 recheck rounds. See `~/.claude/plugins-local/sdlc-wizard-wrap/plugins/sdlc-wizard/skills/sdlc/SKILL.md` for the full protocol — GDLC uses the same mechanism.

**Sandbox note:** `codex exec` requires `dangerouslyDisableSandbox: true` from within Claude Code due to a known Codex bug.

## Self-Review Loop

```
PLANNING → PERSONAS → PLAYTEST → TRIANGULATE → RED → GREEN → Self-Review
    ↑                                                            |
    |                                                            v
    |                                                  Issues found?
    |                                                  |— NO → Commit + log to GDLC.md
    |                                                  +— YES ↓
    +--- back to PLANNING with new plan --- Ask user: fix in new plan?
```

**How to self-review a playtest cycle:**

1. Read back every P0's RED commit and its GREEN commit — was RED authored first?
2. For each P0: is the ratchet entry complete (date, finding, persona, test)?
3. For each convergent claim: two observers, distinct methods?
4. For each re-surface: is there a broken-fix note, or is it a missing-test gap?
5. Run the full suite — zero regressions?
6. Grep for persona-prompt artifacts (sub-agent chatter, context leaks) in the ratchet — these are bugs in the *process*, file them as meta-findings.

## Confidence Check (REQUIRED)

Before presenting approach, STATE your confidence:

| Level | Meaning | Action |
|---|---|---|
| HIGH (95%+) | Cycle type clearly matches surface, personas justified, known-fixed list in hand | Proceed after approval |
| MEDIUM (80-94%) | Cycle choice sound, minor persona gaps | Present approach, flag gaps |
| LOW (<80%) | Surface class ambiguous, or persona matrix stale | ASK USER before proceeding |
| FAILED 2x | Playtest produced no actionable findings twice | STOP. Investigate instrument (wrong personas? wrong cycle?). Ask user. |

## Anti-Patterns (Do Not Do)

- **Running the gameplay matrix on a pipeline refactor.** Wrong instrument. Use contract-audit.
- **Combining gameplay and craft personas in one cycle.** Different rubrics, different target artifacts. Run sequentially.
- **Promoting to P0 with one persona + one instrument.** Triangulation rule exists for a reason.
- **Writing a post-hoc test "to document the fix."** Test RED or it doesn't count.
- **Stopping at zero findings.** Perfectionism. Stop on exhaustion signals.
- **Inventing personas to cover a speculative segment.** Personas earn their line through findings, not speculation.
- **Skipping the anti-confusion prefix on persona prompts.** Sub-agents will read orchestrator context and skip the task.
- **Fixing a content-leak class with yet another redactor tier after 4+ rounds.** Pipeline-level fix required; more redactors invert the ratchet.

## After Session (Capture Learnings)

If this playtest revealed insights, update the right place:

- **Project-specific finding or earned rule** → project's `GDLC.md` (case study)
- **Rule that generalizes across case studies** → propose update to `~/gdlc/GDLC.md` (playbook), require a second case study confirming before merging
- **New cycle type** → playbook update *only* after the cycle has closed a bug class the existing cycles structurally cannot see — earn the line
- **Skill bug (orchestration confusion, prompt artifact)** → update this `SKILL.md`

Do NOT propagate a rule from one case study to the playbook until a second case study independently confirms it. That's the "case study first, framework second" rule applied to GDLC itself.

---

**Full reference:**
- `~/gdlc/GDLC.md` — playbook (case-study-agnostic)
- `<project>/GDLC.md` — case study (this project's earned rules + playtest ledger)
- `~/.claude/plugins-local/sdlc-wizard-wrap/plugins/sdlc-wizard/skills/sdlc/SKILL.md` — SDLC sibling (cross-model review protocol)
