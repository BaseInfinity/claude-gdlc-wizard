# Roadmap — GDLC Distribution

> **Status (2026-04-26):** Phase 1 ✅ **SHIPPED + PUBLISHED**. `BaseInfinity/claude-gdlc-wizard` v0.2.2 is live on npm. Both consumer install paths verified: `npx -y claude-gdlc-wizard init` and `curl -fsSL …/install.sh | bash`. Codex round-2 CERTIFIED 9/10. Trusted Publishing (`.github/workflows/npm-publish.yml`, OIDC) wired for v0.2.3+ — future releases auto-publish on `git push --tags` with SLSA provenance, no NPM_TOKEN required. Path A consolidation complete; the legacy `BaseInfinity/gdlc` repo is archived. Phases 2 (`codex-gdlc-wizard`) and 3 (Homebrew/gh CLI) remain open.

## North star

Mirror SDLC's distribution ecosystem:

| Distribution repo | Host | Status | Phase |
|---|---|---|---|
| `BaseInfinity/claude-gdlc-wizard` | Claude Code | ✅ shipped — v0.2.2 on npm | Phase 1 |
| `BaseInfinity/codex-gdlc-wizard` | OpenAI Codex CLI | ⏸ pending | Phase 2 |
| `BaseInfinity/gh-gdlc-wizard` | gh CLI extension | ⏸ pending | Phase 3 |
| `BaseInfinity/homebrew-gdlc-wizard` | Homebrew tap | ⏸ pending | Phase 3 |
| `BaseInfinity/gdlc` | original framework + playbook | 🗄️ archived (consolidated into claude-gdlc-wizard via Path A, 2026-04-25) | retired |

Reference model — SDLC's complete ecosystem:

| SDLC equivalent | URL |
|---|---|
| `BaseInfinity/claude-sdlc-wizard` | https://github.com/BaseInfinity/claude-sdlc-wizard |
| `BaseInfinity/codex-sdlc-wizard` | https://github.com/BaseInfinity/codex-sdlc-wizard |
| `BaseInfinity/gh-sdlc-wizard` | https://github.com/BaseInfinity/gh-sdlc-wizard |
| `BaseInfinity/homebrew-sdlc-wizard` | https://github.com/BaseInfinity/homebrew-sdlc-wizard |

## Naming convention

**Pattern:** `<host>-<dlc>-wizard`

- `claude-` — Claude Code distribution (skills, wizard doc, hooks, CLI)
- `codex-` — OpenAI Codex CLI adapter
- `gh-` — GitHub CLI extension
- `homebrew-` — Homebrew tap

The retired `gdlc` framework repo was the intentional naming exception (now archived). Never use the old `agentic-ai-*` prefix.

Source memory: `~/.claude/projects/-Users-stefanayala-codeguesser/memory/project_dlc_wizard_naming.md`.

## Phase 1 retrospective (✅ shipped)

**Versions shipped:**

| Version | Date | Highlights |
|---|---|---|
| v0.1.0 | 2026-04-23 | Initial extraction from `BaseInfinity/gdlc` — 4 skills, 2 hooks, CLI, plugin manifest |
| v0.2.0 | 2026-04-25 | **Path A consolidation** — framework playbook (`GDLC.md`) merged into wizard repo; `BaseInfinity/gdlc` deprecated |
| v0.2.1 | 2026-04-25 | **Skill behavioral migration** — skills read project-local `CLAUDE_CODE_GDLC_WIZARD.md`, use `npx claude-gdlc-wizard check` for drift, WebFetch upstream playbook. No sibling clone required. |
| v0.2.2 | 2026-04-26 | Issue-fix release (#1, #3, #4, #5, #7) + Codex round-1 hardening + Trusted Publishing workflow |

**Distribution surfaces verified:**

- `npx -y claude-gdlc-wizard init` (npm)
- `curl -fsSL …/install.sh | bash` (curl wrap)
- `.claude-plugin/plugin.json` (Claude Code plugin)
- Manual git clone (Path 4 in README)

**Quality gates passed:**

- 102 assertions across 5 bash test suites (`tests/*.sh`)
- CI green on `main` (GitHub Actions)
- Codex cross-model review CERTIFIED 9/10 (round 2)

## Graduation gate (still relevant for future case studies)

Per [xdlc rule](https://github.com/BaseInfinity/xdlc): "Case study first. Framework second. No premature extraction."

| Case study | Status |
|---|---|
| #1 codeguesser | ✅ 17 playtests, 355+ tests, 26 earned rules — graduation criterion met |
| #2 pdlc/TamAGI | 🔄 in progress — consuming the wizard now |
| #3, #4, #5 | ⏸ queued (another game project, Canvas-based project, terminal clone) |

Phase 1 was greenlit because case study #1 produced enough generalizable signal. Case study #2 is now exercising the install path; remaining case studies will validate cross-domain portability and feed earned rules back into the playbook.

## Phase 2 — `codex-gdlc-wizard`

Mirror `BaseInfinity/codex-sdlc-wizard` ("🧪 Experimental — adapter for OpenAI Codex CLI. Plan is certified, implementation needed. PRs welcome!").

- [ ] 2.1 — Create `BaseInfinity/codex-gdlc-wizard` with README following the `codex-sdlc-wizard` pattern (certified plan + contributor-friendly stub).
- [ ] 2.2 — Port the 4 skills (`gdlc`, `gdlc-setup`, `gdlc-update`, `gdlc-feedback`) to Codex CLI's skill/plugin primitives. Read `codex-sdlc-wizard` for the adapter pattern.
- [ ] 2.3 — Same test + cross-model review discipline as Phase 1.
- [ ] 2.4 — Register in `~/xdlc/` registry (Framework Status table).

## Phase 3 — distribution sprawl

- [ ] 3.1 — `homebrew-gdlc-wizard` tap repo.
- [ ] 3.2 — `gh-gdlc-wizard` CLI extension.
- [ ] 3.3 — Promote `install.sh` to canonical curl path: redirect `raw.githubusercontent.com/BaseInfinity/claude-gdlc-wizard/main/install.sh` documentation in README and add a stable short-link if appropriate.

Each is a separate small repo. Don't bundle.

## Non-goals

- **Do not re-bundle the playbook into a separate `gdlc` repo.** Path A consolidation is final — the playbook lives here.
- **Do not add existence tests.** Every test proves output quality (Prove-It-Gate).
- **Do not rename `BaseInfinity/claude-gdlc-wizard`.** Naming convention locked: `<host>-<dlc>-wizard`.
- **Do not add a `.gdlc/` scaffold to `~/xdlc/`** — xdlc is a registry, not a GDLC consumer.
- **Do not start Phase 2 or 3 work until at least one additional case study (PDLC) ships an earned rule that wasn't in codeguesser's ratchet.** That's the generalization signal that justifies further distribution surface.

## When you pick this up (Phase 2 or 3)

1. Read this entire file.
2. For Phase 2: clone `BaseInfinity/codex-sdlc-wizard` for layout reference; the Codex CLI adapter pattern is the structural template.
3. For Phase 3: each sub-deliverable (homebrew/gh/curl) is independent — pick whichever has the lowest blast radius first.
4. Use the `sdlc-wizard:sdlc` skill for the actual implementation (TDD RED → GREEN → self-review → cross-model review → ship).

## Cross-references

- Naming memory: `~/.claude/projects/-Users-stefanayala-codeguesser/memory/project_dlc_wizard_naming.md`
- Framework registry: `~/xdlc/README.md`
- SDLC sibling: [BaseInfinity/claude-sdlc-wizard](https://github.com/BaseInfinity/claude-sdlc-wizard)
- Playbook: `GDLC.md` (this repo, root)
- Wizard doc: `CLAUDE_CODE_GDLC_WIZARD.md` (this repo, root)
- Changelog: `CHANGELOG.md` (distribution wizard) and `PLAYBOOK_CHANGELOG.md` (framework playbook)
