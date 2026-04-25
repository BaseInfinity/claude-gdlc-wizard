<!-- GDLC Playbook — case-study-agnostic -->
<!-- Status: v0.3 — codeguesser case study #1 deepened through Playtest #18. 34 earned rules. Distribution-ready (gdlc-setup + gdlc-update skills extracted 2026-04-19); awaiting PDLC validation before framework graduation. -->
<!-- Created: 2026-04-18 -->
<!-- Last updated: 2026-04-19 (gdlc-setup + gdlc-update wizard pair extracted — distribution-readiness, not graduation) -->

# GDLC — Game Development Lifecycle (Playbook)

> **This is a playbook, not a framework.** Per the "case study first, framework second" rule, GDLC has one proven case study ([codeguesser](https://github.com/stefanayala/codeguesser)) and case study #2 queued. The `gdlc-setup` + `gdlc-update` skill pair exists (distribution-readiness), but framework graduation requires case study #2 to earn a rule not present in case study #1.

## Why GDLC exists

SDLC (TDD, tests pass, no over-engineering) guarantees the code is correct. It does not guarantee the game is **fun**, **balanced**, **retentive**, or **satisfying to the player it's aimed at**. Those are game-dev concerns that unit tests can't express.

GDLC is the parallel lifecycle that handles "is this game good?" the way ADLC handles "is this audit correct?" Both GDLC and SDLC run in parallel on every feature.

- **SDLC** → code quality (does it work, is it tested, is it clean?)
- **GDLC** → game quality (is it fun, is it balanced, does it serve its personas?)

## The universal loop, mapped to games

| Stage | SDLC (Code) | GDLC (Game) |
|---|---|---|
| **Plan** | Define task, state confidence | Define feature, declare target persona(s), define "what good looks like" |
| **Verify** | TDD (red → green → pass) | Persona playtest — run the feature past each relevant persona, capture bugs + balance issues |
| **Review** | Self-review + `/code-review` | Cross-persona review — does the feature satisfy multiple personas or only one? Are there cheese paths, dead UI, or persona regressions? |
| **Ship** | Commit, merge | Commit, optionally deploy |
| **Improve** | Bug → regression test | Playtest finding → regression test (code test *or* persona-note entry in the ratchet) |

The **Verify** step is where GDLC diverges hardest from SDLC. TDD doesn't cover "does this feel good?" — personas do.

## Three playtest cycle types

GDLC is a cycle-family, not a single loop. Pick the cycle that matches the surface under review.

### 1. Gameplay-matrix playtest

**When:** A feature that affects what the player does in a run (new mechanic, new mode, scoring rule, balance tweak, UX-facing chip/button).

**Target artifact:** The live game surface (e.g. `index.html`, main runtime).

**Personas:** 5 gameplay personas (Tourist / Casual Dev / Polyglot Senior / Language Purist / Speedrunner — adapt names to the game's domain).

**Rubric:** Fun / Fair / Read / Respect / Return (Y/N ship vote).

**Methodology:** 5 agents launched in parallel (Playwright MCP or equivalent), each stays in character, plays a full run, scores the rubric, reports findings with suggested fixes.

**Triangulation rule:** A finding hit by **2+ personas across distinct methods** earns P0 promotion. Same instrument (e.g. both agents polling the same DOM) is not distinct-method — require cross-method confirmation before promoting.

### 2. Art-craft-review playtest

**When:** An art-direction change, palette/typography rollout, sprite-treatment pilot, any surface that makes the art-demo sink noticeably richer (new overlay, new fanfare, new chip variant).

**Target artifact:** The **art-demo sink** (e.g. `demo.html` — a dev-only page that renders every visual primitive the game uses). Personas review the sink, not the live game.

**Personas:** 4 craft personas (Retro Gamer / Game Designer / Game Artist / Art Director — adapt era/genre to the project).

**Rubric:** Cohesion / Era / Hierarchy / Craft / Ship (Y/N).

**Output class:** Every art P0 is a **contract violation** against the project's written `ARTSTYLE.md` (or equivalent). Taste calls land as P1/P2 notes and don't block ship.

**Ship-gate semantics:** Art playtests block **art ships** (palette rollout, surface ports from sink into live game, ARTSTYLE amendments). They do **not** block gameplay ships. A gameplay bugfix can merge with an outstanding art P1; a palette-rollout commit cannot.

**TDD RED on craft:** Every art P0 earns a computed-style contract assertion (e.g. `expect(getComputedStyle(el).backgroundImage).toBe('none')`) authored RED before the CSS fix. Baseline-PNG snapshots protect visual drift; contract tests protect the style contract. Both belong in the ratchet.

### 3. Pipeline-contract-audit playtest

**When:** A refactor that changes a pipeline (RNG, seed, redaction, content-leak audit, persistence serialization, replay encoding) without adding new player-visible surface. Seed-everything, stopword-pipeline, serialization-migrations all fit here.

**Target artifact:** The pipeline itself — tested through contract unit/integration tests against real data, not through a manual gameplay pass.

**Personas:** Selected by which contract dimension each persona defends. E.g. for a seed refactor: Speedrunner (ready-gate + re-entry), Polyglot Senior (determinism audit), Ghost Racer (replay invariant), Tab Hopper (cross-tab + URL round-trip). Don't run the full gameplay matrix on a pipeline change — wrong instrument.

**Methodology:** Each persona is a lens on one contract dimension. The finding is a RED contract test (`expect(parse(format(x))).toEqual(x)` across a domain sample, `expect(replay(seed).sequence).toEqual(originalRun(seed).sequence)` on same seed, etc.). Fix is the GREEN.

**Selection rule:** Pipeline refactors deserve contract-audit, not gameplay playtest. Mixing them produces noise (gameplay personas don't care about URL round-tripping; contract personas don't care about Fun/Fair).

## Mixed-surface sequencing

Real features routinely touch more than one surface — a new mechanic that also needs replay support spans gameplay **and** pipeline; a palette rollout that adds a new fanfare spans art **and** gameplay. Run cycles **sequentially**, never combined, in this order:

1. **Pipeline-contract-audit first** (if any pipeline touched). Lock the determinism/encoding/persistence contract before gameplay or art personas depend on it. Running a gameplay playtest against a not-yet-deterministic pipeline produces findings that evaporate the moment the pipeline stabilizes.
2. **Gameplay-matrix next** (if runtime behavior changed). Gameplay personas review the feature on a known-stable pipeline.
3. **Art-craft-review last** (if ARTSTYLE/sink changed). Art ships gate only art changes; running craft personas on a still-changing gameplay surface wastes cycles.

Each cycle has its own ship-gate. A feature is not ship-ready until every cycle it touched has passed. Do **not** combine rosters across cycles — a gameplay persona reviewing art and a craft persona reviewing balance both produce off-instrument noise. If a mixed feature cannot be decomposed into ordered cycles, the feature itself is too entangled — split it.

## Persona templates

Personas are **lenses on surfaces**, not permanent roster slots. Add a persona when a player-visible contract expands to a dimension no existing persona naturally observes. Remove a persona that no longer maps to a live surface.

### Gameplay personas (adapt to the game's domain)

| Persona | Who they are | What they want | What breaks it for them |
|---|---|---|---|
| **Tourist** | First-time player, may not even know the domain | Discoverability, low barrier, dopamine within 30s | No onboarding, overwhelming UI, dying in round 1 with no feedback |
| **Casual [Domain]** | Novice in the domain (e.g. Casual Dev for a code game, Casual Player for an RPG) | Forgiveness, juice, clear feedback, "I'm learning" vibe | Steep difficulty, brutal scoring, unclear failure states |
| **[Domain] Senior** | Deep knowledge across the domain breadth | Content quality, tasteful distractors, respect for their knowledge | Trivially-guessable content, fake "gotcha" distractors, content that reads AI-generated |
| **[Subdomain] Purist** | Expert in one subdomain (e.g. Rust, turn-based tactics) | Respect for depth, niche content in their subdomain | Forced into subdomains they hate, seeing their subdomain misrepresented |
| **Speedrunner** | Optimizes score/time, chases leaderboard | Clear scoring, speed-run modifier, consistent round pacing | Unpredictable timers, score obfuscation, RNG that ruins runs |

### Craft personas (adapt era/genre)

| Persona | Lens | Scoring Q |
|---|---|---|
| **Retro Gamer (era target)** | "Does this *feel* like the era, or is it cosplay?" | Era, Cohesion |
| **Game Designer** | "Does hierarchy hold under time pressure? Does the palette earn each accent?" | Hierarchy, Cohesion |
| **Game Artist** | "Is the craft tight? Are the outlines consistent? Does anything violate stated pillars?" | Craft |
| **Art Director** | "Would I let this ship? What's the one thing I'd stop-the-line for?" | Ship |

### Contract-audit personas (examples — derive from the contract dimensions)

| Persona | Contract dimension they defend |
|---|---|
| Ghost Racer | "Can I paste this seed into another tab and get the same run?" (replay invariant) |
| Tab Hopper | Cross-tab collision + URL survivability |
| Polyglot [Domain] | Per-unit determinism across [domain categories] |

**Matrix rules:**
- A feature that serves *zero* personas should be deleted.
- A feature that serves *one* persona at the cost of another is flagged for cross-persona review.
- Personas earn their line through **real findings**, not speculation. Don't invent personas upfront.
- **Persona expansion tracks contract expansion.** When a feature adds a player-visible contract (URL shape, share format, replay promise, leaderboard entry), audit whether any existing persona naturally cares. If none do, the matrix is stale — add the persona *before* running the playtest.

## The ratchet — earned findings only tighten

Every playtest P0 earns a permanent regression check before the fix lands. P1/P2 and balance/feel findings earn a ratchet entry (test or persona-note) appropriate to severity. The game only gets stricter, never looser. The ratchet is the enforceable form of "we learned this."

**Severity threshold (explicit):**

| Severity | Ratchet entry required? |
|---|---|
| P0 | Regression test RED before fix. No exceptions. |
| P1 | Test OR persona-note at author's discretion — severity and rationale recorded. |
| P2 | Persona-note if the observation will recur; skip otherwise. |
| Balance/feel | Persona-note with file path reference (always, even without a test). |

| Finding type | Ratchet entry |
|---|---|
| Code bug | Regression test in the appropriate harness (unit / integration / E2E) |
| Content bug | Audit-map entry + test (fail-closed on missing coverage) |
| Craft bug (art) | Computed-style contract assertion + updated baseline PNG |
| Balance / feel | Persona-note with file path reference (if not testable in-code) |

**Rules:**
- **Every P0 earns a regression test *before* the fix lands.** Test RED first. Post-hoc tests don't count. P1/P2 ratchet entries are at author discretion but the severity threshold must be recorded.
- **Re-surfacing is a first-class severity.** A re-surface is never a bug — it's always a broken fix or a missing test. Track re-surface % per playtest round; crossing ~60% signals diminishing returns.
- **Ratchet inversions cluster around new abstractions, not new surfaces.** When a new tier, helper, or pipeline-layer lands, audit what it silently changed about the prior contract surface. A fix that re-regresses an earlier fix is the strongest stop signal of all.
- **A new pipeline tier declares its allowlist/denylist at write-time, not retroactively.** Over-broad coverage is the typical inversion cause.

## Earned rules (the durable core)

Each rule below is earned from a specific case. Rules without a specific incident behind them don't belong here.

### On personas and selection
1. **Derive personas from conversation, not speculation.** A persona earned in context beats one brainstormed at kickoff.
2. **Persona expansion tracks player-visible contract expansion.** New surface → audit whether an existing persona cares → add a persona only if the audit fails.
3. **Match the playtest style to the surface class.** Gameplay-matrix for runtime features, art-craft-review for ARTSTYLE-affected surfaces, pipeline-contract-audit for refactors. Mixing styles dilutes both.

### On triangulation
4. **Cross-method triangulation required before P0.** Two personas using the same instrument (e.g. both polling the same DOM) is one observer. Require cross-method confirmation.
5. **Self-triangulation via regression test counts.** If a fix's GREEN-phase test fails and reveals a distinct root cause, the test is the triangulating instrument — log as convergent, not as a separate bug.
6. **Convergent suggestions are stronger design signal than convergent complaints.** When two personas propose the same fix, promote it from "suggestion" to "accepted improvement."

### On the ratchet
7. **Write the test before the fix.** Visual-regression included — contract tests on computed style RED before the CSS change.
8. **Fix scope must match problem scope.** A one-mode fix for a multi-mode problem is itself a bug.
9. **Ratchet inversions concentrate around new abstractions.** Design-review lifecycle event (cross-model) on pipeline changes specifically.

### On stop rules
10. **Stop when re-surface % crosses ~60% OR the top finding is a regression-of-prior-fix.** Not at zero findings. The former is exhaustion; zero-findings is perfectionism.
11. **When a finding category trend fails to diminish across 4+ playtests, pivot to a pipeline-level fix.** Playtests are the wrong instrument for pipeline-class bugs (content-leaks, encoding round-trips).

### On cycle boundaries
12. **Gameplay matrix and art-craft-review are distinct cycles with distinct ship-gates.** Different target artifact, different rubric, different commit scope. Don't mix.
13. **Pipeline-contract-audit is its own cycle.** Running a gameplay matrix on a seed refactor wastes 5 personas and misses the real contract bugs.
14. **Every cycle earns its line only after it closes a bug class the prior cycle structurally cannot see.**

### On determinism foundations
15. **Seed-everything is half-done without reset-everything.** (Earned P17 P0-B.) Any seed-capture refactor must enumerate every re-entry path (retry, mode switch, modifier toggle) and wire `resetRng()` into each. Invariant: *same (seed, input sequence) → same output sequence*, not *seed is stored*.
16. **A replay URL must encode the full deterministic key.** (Earned P17 P0-C.) Missing any input dimension (mode, modifier, initial state) = silent divergence = lying about determinism.
17. **Cosmetic RNG must not share a stream with game-state RNG.** (Earned P17 P0-bonus, self-triangulated.) Derive separate streams from the run seed; never share the callable. Convenience-sharing is shape-identical to global-state-in-tests: works until the second consumer shows up.
18. **Round-trip encoding needs a property test across a domain sample.** (Earned P17 P0-A.) Spot-checks miss values-indistinguishable collision classes (e.g. base36/decimal: 2.89% of uint32 inputs corrupted but none of the hand-picked values did).
19. **Clock injection is the dual of seed injection.** (Earned v0.11 ship.) Every `Date.now()` in game-state code is a determinism hole, exactly like every `Math.random()` was pre-seed-capture. Same audit shape: enumerate, thread through injectable primitive (`createClock(nowFn)` / `createMockClock()`), default to wall-clock so existing callers are untouched. **When shipping determinism foundations, do the `Math.random()` audit *and* the `Date.now()` audit together — skipping one leaves the other as a latent refactor.**
20. **Record intent, not state mutation.** (Earned v0.11 ship.) A trace/event log should capture user intent (`{type: 'answer', value: 'JavaScript'}`) *before* state mutates, not the derived state after (score delta, rng advance, timer updates). Replaying intents re-runs the deterministic machine; replaying state requires re-applying every derived field. Generalizes to any event-sourced system: log at the intent boundary, not the mutation boundary.
21. **Public-API replay driver beats private-state replay driver.** (Earned v0.11 ship.) A replay/inspection tool for a system should drive it through the same API surface the primary consumer uses (`ui.handleAnswer()`, `ui.setMode()`). Never grow a parallel private-state-access path for tooling — internal state shape changes break every parallel path; the public API is the one surface guaranteed to stay stable.

### On trust boundaries
22. **URL params (and any user-controlled boundary) are untrusted — `Array.isArray` is not a schema.** (Earned P18 P0-A.) `["hi"]` passes `Array.isArray`. Any decoder at a user-controlled boundary (URL, localStorage, clipboard, paste, query string) needs per-field shape validation: type, range, allow-listed enums. Cost: ~10 LoC. Bug class eliminated: attacker sends a crafted payload that satisfies the outer structural check but crashes the inner consumer.
23. **All-or-nothing decoding beats partial-accept at trust boundaries.** (Earned P18 P0-A.) A decoder that returns `[valid, valid, ..., malicious]` forces every downstream consumer to re-validate each element — or trust the decoder and crash. All-or-nothing means one validation pass guards the entire pipeline, and malicious inputs produce a single predictable sentinel result (e.g. `[]`). Parse-don't-validate at the boundary, then trust internally.
24. **Size caps before CPU work, not after.** (Earned P18 P0-B.) A "reject oversize input" guard runs at the *earliest* possible point in the pipeline — before base64 decode, before `JSON.parse`, before any expensive transform. Reverse order (decode first, then cap) still lets a 100MB payload DoS the parser.
25. **"Silently defaults" is a design smell at trust boundaries.** (Earned P18 P1-A.) Loud failure beats quiet fallback. `?replay=X` without `?seed=` silently substituting `Math.random()` produces a ghost URL that *looks* replayed but diverges from step one — "works but wrong" is strictly worse than "doesn't work" because it masquerades as success. Either honor required params together, or ignore the optional surface entirely.
26. **Fail-safe decoders over strict decoders at user-controlled boundaries.** (Earned v0.11 ship, confirmed P18.) A malformed `?replay=`, truncated URL, old-format share, or copy-paste error should return a sentinel empty value, not throw. The page keeps working; the broken decoder surface just contributes nothing. Strict decoders belong behind validated internal boundaries; user-controlled surfaces absorb garbage quietly.

### On methodology itself
27. **Rules only deserve their line after solving a concrete case.** If a rule has no incident behind it, it's cargo-cult.
28. **Keep a "What's Working" section in the project's GDLC.md parallel to the findings ledger.** When a methodological change proves itself across 2+ playtests (anti-confusion prefix, persona-prompt format, cycle selection), log it there with the date + cycle numbers that confirmed it. Without this section, successful process changes get forgotten and re-invented at cost.
29. **Persona prompts include the known-fixed list.** Agents flag re-surfaces vs new findings — re-surface % computes automatically, main loop doesn't re-litigate closed findings.
30. **Agent-orchestration confusion is its own bug class.** Sub-agent's context including orchestrator's summary leads to skipped tasks. Anti-confusion prefix ("CRITICAL: Do NOT read any summaries") on persona prompts.
31. **Net-new findings with 0% re-surface signal a *new surface*, not a weak playtest.** (Earned P18.) Previously, zero re-surface meant "agents didn't look hard enough." When a new contract ships (v0.11's `?replay=` URL), *by construction* no prior playtest could have surfaced its bugs. Expect one playtest of all-new findings per new contract surface before the re-surface metric becomes meaningful again.
32. **Contract-audit persona + UX-persona in parallel is the right shape for a mixed pipeline+UX ship.** (Earned P18.) A code-audit persona (Polyglot Senior) catches DoS/shape findings in 12 min that aren't player-visible until the attacker ships the payload. A UX persona (Ghost Racer via Playwright) exercises "does it feel like a ghost race?" — surface the code audit structurally cannot see. Ship with both in parallel, neither substituting for the other. Do not combine them — rubrics differ.
33. **Ship the foundation, park the UX.** (Earned v0.11 ship.) When a feature has a well-defined contract surface (pipeline: record, encode, decode, replay) *and* an ambiguous presentation surface (UX: live ghost-sprite rendering, timing overlay), split the ship. Pipeline earns contract-audit; UX earns persona-playtest. Bundling forces a presentation decision before the pipeline's data is characterizable. Foundation-first commits are recoverable; presentation-first commits trap the pipeline into serving a specific render shape.
34. **Ratchet density follows surface-class contract density, not LoC.** (Earned v0.11 ship.) Pipeline refactors earn unit + integration tests (one per primitive contract + one load-bearing invariant integration test). Gameplay surfaces earn integration + playtest. 350 LoC of plumbing may earn 20 tests; 350 LoC of UX may earn 2 tests + a playtest cycle. Measure ratchet coverage by contract count, not line count.

## What a GDLC playtest looks like (concrete flow)

1. **Pick the cycle type.** Gameplay-matrix, art-craft-review, or pipeline-contract-audit.
2. **Pick the personas for that cycle.** From the matrix, or add one if a new contract demands it.
3. **Write the persona prompts.** Each prompt includes: persona brief, rubric, known-fixed list, anti-confusion prefix, artifact URL/path.
4. **Launch agents in parallel.** Playwright MCP for live-surface cycles, direct Node-driven tests for pipeline-contract cycles.
5. **Aggregate findings.** Separate re-surface from new, convergent from unique, contract-violation from taste-call.
6. **Triangulate.** Apply rule #4 (cross-method) and #5 (self-triangulation).
7. **RED first.** Author the regression test for each P0 before the fix lands.
8. **GREEN.** Apply the fix. All prior tests must remain green.
9. **Log to the ratchet.** File path + finding + test name.
10. **Score the stop signal.** Re-surface %, top-finding class, total-tests-added. If stop rule trips, pivot (either ship or escalate to pipeline-level).

A feature is GDLC-verified when it has **at least one thumbs-up from each target persona** declared in the Plan stage *and* the ratchet delta is non-negative (no inversions without written justification).

## Interop with SDLC

GDLC does not replace SDLC — it sits next to it.

- **SDLC handles:** TDD, lint, typecheck, tests pass, self-review, clean code.
- **GDLC handles:** persona matrix, playtest pass, cross-persona review, ratchet.

Both lifecycles must green-light a feature before it ships:

1. **Plan** → write feature plan *and* declare which GDLC cycles the feature touches (gameplay-matrix, art-craft-review, pipeline-contract-audit — one or more, ordered per "Mixed-surface sequencing") (GDLC addition)
2. **TDD RED → GREEN → PASS** (SDLC)
3. **Playtest pass** — run each declared cycle in sequence, each with its own personas and ship-gate (GDLC addition)
4. **Self-review** `/code-review` (SDLC)
5. **Cross-persona review** — does any non-target persona regress? (GDLC addition)
6. **Commit**

Cost: GDLC additions run ~10-20 minutes per feature. Features where cost isn't worth it (typos, refactors, dev-only config) skip GDLC and run SDLC-only.

## Distribution vs Graduation

Two distinct milestones, historically conflated:

### Distribution-readiness (achieved 2026-04-19)

The `gdlc-setup` + `gdlc-update` skill pair exists at `~/gdlc/.claude/skills/`. Any consumer project (PDLC, or a future case study) can run `/gdlc-setup` to install the skill via file-copy from the sibling repo, and `/gdlc-update` to pull later changes. This is an **ergonomics gate** — it removes the friction of manual copy-paste, so the second case study has a clean adoption path.

Distribution-readiness is **not** a quality signal about the playbook. It says "the install path works", not "the playbook is generalizable". A playbook can be distributable and still be wrong.

### Framework graduation (pending)

The playbook earns framework status **only after**:

1. A second project independently adopts the skill and confirms the patterns (PDLC queued — install path now frictionless via `/gdlc-setup`).
2. The second project produces at least one earned rule that **wasn't** in the case-study-1 ratchet — proving the playbook is generalizable, not just codeguesser-shaped.
3. A third case study would then trigger any structural reshuffling (e.g. splitting the playbook by surface class, promoting rules from case-study ledgers into playbook bodies).

Until graduation, this doc is a playbook, the `/gdlc` skill is its enforceable form, and the setup/update pair is distribution infrastructure. The pair's existence means nothing about the rules inside the playbook — those still need case-study-2 validation before any rule gets promoted or pruned.

**Why extract the wizard pair early?** Case study #2 (PDLC) was blocked on adoption friction — manually copying `SKILL.md` + constructing a case-study stub is error-prone, and the errors compound (wrong skill version → wrong persona matrix → wrong cycle selection). Extracting the wizard pair moves the friction to zero, so the case study #2 signal — does the playbook generalize? — isn't confounded by install noise.

## References

- Case study #1 (proving ground): `codeguesser/GDLC.md` — 18 playtests, 384 regression tests, 32+ project-earned rules (v0.11 ship + Playtest #18 integrated 2026-04-18).
- Case study #2 (queued): a second project (PDLC — pygame/AI lifecycle) will run `/gdlc-setup` to install the skill and run its first playtest under the GDLC playbook. Framework-graduation signal requires case #2 to produce at least one earned rule that wasn't in case #1's ratchet.
- Install: `/gdlc-setup` (first install in a consumer project), `/gdlc-update` (pull skill + new playbook rules from `~/gdlc/`).
- SDLC sibling: `sdlc-wizard` plugin.
