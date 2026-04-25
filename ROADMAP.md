# Roadmap — GDLC Distribution Extraction

> **Status (2026-04-23):** Planned but NOT started. A fresh session can use this doc as the sole brief to begin Phase 1.

## North star

Graduate GDLC from "playbook + skills co-located in one repo" to the same 4-repo distribution ecosystem SDLC has:

| Distribution repo | Host | Status today | Target |
|---|---|---|---|
| `BaseInfinity/gdlc` | — framework + playbook + case studies | ✅ shipped (v0.4.1) | stays as framework source of truth |
| `BaseInfinity/claude-gdlc-wizard` | Claude Code | ❌ does not exist | Phase 1 |
| `BaseInfinity/codex-gdlc-wizard` | OpenAI Codex CLI | ❌ does not exist | Phase 2 |
| `BaseInfinity/gh-gdlc-wizard` | gh CLI extension | ❌ does not exist | Phase 3 |
| `BaseInfinity/homebrew-gdlc-wizard` | Homebrew tap | ❌ does not exist | Phase 3 |

The reference model is SDLC, which completed this exact evolution:

| SDLC equivalent | URL | Role |
|---|---|---|
| `BaseInfinity/claude-sdlc-wizard` | https://github.com/BaseInfinity/claude-sdlc-wizard | Main Claude distribution (formerly `agentic-ai-sdlc-wizard`, renamed 2026-04-23) |
| `BaseInfinity/codex-sdlc-wizard` | https://github.com/BaseInfinity/codex-sdlc-wizard | Codex adapter (experimental, "PRs welcome") |
| `BaseInfinity/gh-sdlc-wizard` | https://github.com/BaseInfinity/gh-sdlc-wizard | gh CLI extension |
| `BaseInfinity/homebrew-sdlc-wizard` | https://github.com/BaseInfinity/homebrew-sdlc-wizard | Homebrew tap |

## Naming convention (decided 2026-04-23)

**Pattern:** `<host>-<dlc>-wizard`

- `claude-` — Claude Code distribution (skills, CLAUDE.md wizard doc)
- `codex-` — OpenAI Codex CLI adapter
- `gh-` — GitHub CLI extension
- `homebrew-` — Homebrew tap

Old `agentic-ai-*` prefix was renamed to `claude-*` for precision. Never use `agentic-ai-gdlc-wizard`. The `gdlc` framework repo itself is the intentional exception — it is not a distribution wizard.

Source memory: `~/.claude/projects/-Users-stefanayala-codeguesser/memory/project_dlc_wizard_naming.md`.

## Graduation gate — DO NOT skip

Per xdlc rule ([xdlc/README.md:13-15](https://github.com/BaseInfinity/xdlc) "Case study first. Framework second. No premature extraction."):

**Both required before Phase 1 starts:**

1. **Adoption without modification** — case study #2 installs the gdlc skill suite and runs at least one full playtest cycle without editing the playbook.
2. **Generalization evidence** — case study #2 produces at least one earned rule that was NOT in codeguesser's ratchet. A playbook that only re-confirms its first case study's rules is codeguesser-shaped, not generalizable.

**Current state of gate:**

- Case study #1 (codeguesser): ✅ 17 playtests, 355+ tests, 26 earned rules. Complete.
- Case study #2 (pdlc/TamAGI): ⏸ Queued, not started. Lives at `~/pdlc/`.

**If the gate isn't cleared, Phase 1 is premature extraction.** Stop and run the PDLC/TamAGI case study first. Do not pre-build a wizard for a case study that hasn't happened.

Verification before starting Phase 1:
```bash
# Confirm both graduation criteria are met
test -f ~/pdlc/GDLC.md && grep -q 'Playtest #' ~/pdlc/GDLC.md && \
  echo "criteria 1 (pdlc ran a cycle): PASS" || echo "FAIL — run PDLC case study first"
# Criteria 2 requires human judgment — is there a new earned rule? Read ~/pdlc/GDLC.md ratchet table.
```

## What already exists in `~/gdlc/` (do not re-build)

The skill suite is complete. Do not recreate these — **copy them into the new wizard repo**:

- `~/gdlc/.claude/skills/gdlc/SKILL.md` — main `/gdlc` skill (cycle picker, persona matrix, triangulation)
- `~/gdlc/.claude/skills/gdlc-setup/SKILL.md` (223 lines) — conversational setup wizard, auto-scans consumer project, confidence-driven prompts (same pattern as `~/.claude/plugins-local/sdlc-wizard-wrap/plugins/sdlc-wizard/skills/setup/SKILL.md`, 239 lines)
- `~/gdlc/.claude/skills/gdlc-update/SKILL.md` — CHANGELOG diff + drift detection + per-file apply
- `~/gdlc/.claude/skills/gdlc-feedback/SKILL.md` — files issues upstream using stock GitHub labels (`bug` / `enhancement` / `question`) with `[<type>]` title prefixes
- `~/gdlc/CLAUDE_CODE_GDLC_WIZARD.md` — wizard doc, contains step registry + feedback loop section + canonical type→label map + auto-context allowlist + privacy invariant
- `~/gdlc/GDLC.md` — playbook (framework body — stays in `gdlc` repo, not wizard repo, per the same pattern SDLC uses)
- `~/gdlc/CHANGELOG.md` — framework changelog (stays in `gdlc`)
- `~/gdlc/FEEDBACK_SKILL_SPEC.md` — spec for the feedback skill
- `~/gdlc/README.md` — orientation doc

## Phase 1 — `claude-gdlc-wizard` (when graduation gate clears)

### Reference reading (required before starting)

A fresh session starting this phase should read these, in order:

1. **`~/gdlc/README.md`** — current state, graduation criteria, case-study summary
2. **`~/gdlc/.claude/skills/gdlc-setup/SKILL.md`** — what the conversational setup looks like today
3. **`~/.claude/plugins-local/sdlc-wizard-wrap/plugins/sdlc-wizard/skills/setup/SKILL.md`** — the SDLC setup skill, the structural template. Port its plugin-layout decisions directly. Do not reinvent.
4. **Clone of `BaseInfinity/claude-sdlc-wizard`** — the full distribution layout: `.claude-plugin/`, `.claude/`, `.github/`, `.metrics/`, `.reviews/`, `cli/`, `hooks/`, `plans/`, `scripts/`, `skills/`, `tests/`. This is the skeleton to mirror. Clone it into `~/tmp/claude-sdlc-wizard-reference/` for reading, not as a dependency.
5. **`~/xdlc/README.md`** — framework registry, naming convention, cross-pollination rules
6. **`~/.claude/projects/-Users-stefanayala-codeguesser/memory/project_dlc_wizard_naming.md`** — naming rule with `Why:` context

### Phase 1 deliverables

- [ ] 1.1 — Create `BaseInfinity/claude-gdlc-wizard` repo on GitHub (public). Description: "GDLC Wizard — install the Game Development Life Cycle skill suite into any Claude Code project. Playbook + skills originate from [BaseInfinity/gdlc](https://github.com/BaseInfinity/gdlc)."
- [ ] 1.2 — Clone locally as `~/claude-gdlc-wizard/`. Register in `~/xdlc/README.md` Framework Status table (row for GDLC, add `[claude-gdlc-wizard]` link alongside the `gdlc` framework link).
- [ ] 1.3 — Scaffold the directory structure by mirroring `BaseInfinity/claude-sdlc-wizard` exactly. Every top-level dir has a purpose — don't omit without understanding why. At minimum:
  - `.claude-plugin/plugin.json` — plugin metadata for Claude Code plugin system
  - `.claude/skills/gdlc/`, `.claude/skills/gdlc-setup/`, `.claude/skills/gdlc-update/`, `.claude/skills/gdlc-feedback/` — the 4 skills
  - `CLAUDE_CODE_GDLC_WIZARD.md` — canonical wizard doc (copied from `~/gdlc/`)
  - `cli/` — CLI entry points if we want `npx claude-gdlc-wizard init` parity with SDLC
  - `hooks/` — any hook scripts shipped with the wizard
  - `scripts/` — install helpers
  - `tests/` — quality tests that prove skill output behavior (per SDLC skill's "Prove It Gate" rule — existence tests are NOT quality tests)
  - `README.md` — install instructions, consumer-facing
  - `CHANGELOG.md` — wizard's own changelog (distinct from `gdlc` framework's changelog)
  - `package.json` — if publishing to npm
- [ ] 1.4 — Port the 4 skills from `~/gdlc/.claude/skills/` into the new repo's `.claude/skills/`. Update any references to `~/gdlc/` inside the skills to work in the plugin-installed layout (the skills currently expect a sibling `~/gdlc/` repo — decide whether to keep that dependency or bundle the playbook into the wizard). Decision recommendation: **keep the sibling dependency** — the skills already read `~/gdlc/GDLC.md` for playbook content, and bundling it means every wizard release forks the playbook. Sibling pattern keeps the playbook single-sourced.
- [ ] 1.5 — Write `tests/` with **quality tests, not existence tests**. Per SDLC's Prove It Gate:
  - BAD: "gdlc skill file exists"
  - GOOD: "gdlc skill picks gameplay-matrix cycle when .claude-plugin detects e2e browser game signals"
  - GOOD: "gdlc-setup produces a valid GDLC.md skeleton with required metadata block in under 30s on a fresh repo"
  - GOOD: "gdlc-feedback creates a GitHub issue with `[<type>]` title prefix and correct stock label"
- [ ] 1.6 — Write a preflight self-review doc at `.reviews/preflight-phase-1.md`. Match the SDLC pattern (proven across 4 repos to reduce reviewer findings to 0-1 per round).
- [ ] 1.7 — Cross-model review via Codex. Write `.reviews/handoff-phase-1.json` with mission-first framing. Verification checklist should include: file parity with claude-sdlc-wizard skeleton, skill files identical to `~/gdlc/.claude/skills/*`, no stale `feedback:*` custom labels (use stock labels only), no references to the old `agentic-ai-*` repo naming.
- [ ] 1.8 — Distribution channels (incremental, not all at once). Order:
  1. **git clone + symlink** — baseline, works immediately. Document in README as "v0 install."
  2. **npm package** (`claude-gdlc-wizard`) — `npx claude-gdlc-wizard init` parity with SDLC's npm flow. Check how SDLC's npm flow is set up in `claude-sdlc-wizard/cli/`.
  3. **Claude Code plugin** — `.claude-plugin/plugin.json` shipped, installable via Claude Code's plugin mechanism.
  4. **Homebrew tap** (separate repo `homebrew-gdlc-wizard`) — Phase 3, not Phase 1.
  5. **gh CLI extension** (separate repo `gh-gdlc-wizard`) — Phase 3.
  6. **curl installer** — Phase 3.
- [ ] 1.9 — Update all consumer-facing docs in `~/gdlc/`:
  - `~/gdlc/README.md` install section should show BOTH paths (git clone + wizard install) with the wizard as the recommended path
  - Remove the "this repo stays at playbook + skill only" language once the wizard ships
- [ ] 1.10 — Update `~/xdlc/README.md`:
  - Framework Status table: update GDLC row's "SDLC Installed" column from `planned` to `yes`
  - Working-dir-map table: add `~/claude-gdlc-wizard/` row
  - ASCII tree: update GDLC line from `[skill stage]` to `[shipped]`

### Phase 1 verification

Before shipping Phase 1:
- [ ] Fresh consumer repo: `/gdlc-setup` completes end-to-end without edit, produces valid `GDLC.md`
- [ ] Wizard tests pass (quality tests, not existence tests)
- [ ] Codex cross-model review: CERTIFIED
- [ ] `~/gdlc/` framework and `~/claude-gdlc-wizard/` skills stay in sync (drift check passes)

## Phase 2 — `codex-gdlc-wizard`

Mirror `BaseInfinity/codex-sdlc-wizard` (currently "🧪 Experimental — adapter for OpenAI Codex CLI. Plan is certified, implementation needed. PRs welcome!").

- [ ] 2.1 — Create `BaseInfinity/codex-gdlc-wizard` with README following codex-sdlc-wizard's structure (certified plan, implementation needed, contributor-friendly)
- [ ] 2.2 — Port the 4 skills to Codex's skill/plugin primitives (whatever Codex CLI uses). Read `codex-sdlc-wizard` for the adapter pattern.
- [ ] 2.3 — Same test + review discipline as Phase 1
- [ ] 2.4 — Register in `~/xdlc/` registry

## Phase 3 — distribution sprawl

- [ ] 3.1 — `homebrew-gdlc-wizard` tap repo
- [ ] 3.2 — `gh-gdlc-wizard` CLI extension
- [ ] 3.3 — curl installer at `raw.githubusercontent.com/BaseInfinity/claude-gdlc-wizard/main/install.sh`

Each of these is a separate small repo. Don't bundle.

## Non-goals (do NOT do these)

- **Do NOT start Phase 1 before the graduation gate clears.** The "case study first" rule exists because we burn weeks building wizards for patterns that don't generalize. If PDLC/TamAGI case study hasn't run yet, stop here.
- **Do NOT bundle the playbook (`GDLC.md`) into the wizard repo.** It stays in `~/gdlc/`. The wizard's skills reference the sibling playbook, matching the SDLC pattern.
- **Do NOT add existence tests.** Every test proves output quality or it doesn't get written.
- **Do NOT rename the `gdlc` framework repo.** It stays as `BaseInfinity/gdlc` — the framework repo is the naming exception (see convention doc).
- **Do NOT add a `.gdlc/` scaffold to `~/xdlc/`** — xdlc is a registry, not a GDLC consumer.

## Cross-references for fresh sessions

- **Current skill source of truth:** `~/gdlc/.claude/skills/` (4 skills, v0.4.1)
- **Reference skeleton:** `BaseInfinity/claude-sdlc-wizard` — clone and mirror its layout
- **Naming rule:** `~/.claude/projects/-Users-stefanayala-codeguesser/memory/project_dlc_wizard_naming.md`
- **Framework registry:** `~/xdlc/README.md`
- **Codeguesser ROADMAP cross-link:** `~/codeguesser/ROADMAP.md` "Later / maybe" section references this file (add xref if absent)
- **Case study #2 home:** `~/pdlc/` (currently queued, not started)
- **Recent commit landmarks:**
  - `~/gdlc` origin/main = v0.4.1 squash-merge (stock labels + feedback loop section + version parity)
  - `~/xdlc` origin/main = `d74d7cb` (`docs(registry): sweep agentic-ai-sdlc-wizard refs to claude-sdlc-wizard`)

## When you pick this up

A fresh session should:

1. Read this entire file top-to-bottom
2. Verify the graduation gate (`~/pdlc/` case study state)
3. If gate hasn't cleared — stop, go run the PDLC case study, come back
4. If gate has cleared — start at Phase 1.1, work the checklist in order
5. Use the `sdlc-wizard:sdlc` skill for the actual implementation (TDD RED → GREEN → self-review → cross-model review → ship)
