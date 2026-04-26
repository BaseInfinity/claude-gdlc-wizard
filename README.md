# claude-gdlc-wizard

**GDLC enforcement for Claude Code.** The sibling of [claude-sdlc-wizard](https://github.com/BaseInfinity/claude-sdlc-wizard), for games instead of code.

SDLC governs whether code is *correct.* GDLC governs whether a game is *fun, fair, readable, and persona-aligned.* Most games are correctness-underdetermined — passing every unit test doesn't make them good.

This wizard installs the GDLC skill suite into any Claude Code project: persona-driven playtest cycles, triangulated findings, and a ratchet that only tightens.

## Status

**Shipped (v0.2.1, 2026-04-25).** Phase 1 CERTIFIED; framework playbook consolidated into this repo (Path A); skills migrated to local-repo paths (no sibling clone required). Originally extracted from [BaseInfinity/gdlc](https://github.com/BaseInfinity/gdlc) on 2026-04-23 (now deprecated, see [DEPRECATED.md](https://github.com/BaseInfinity/gdlc/blob/main/DEPRECATED.md)). Case studies to date:

- **#1 codeguesser** — 17 playtests, 355+ regression tests, 26 earned rules (complete)
- **#2 pdlc/TamAGI** — consuming now
- **#3, #4, #5** — queued (another game project, Canvas-based project, terminal clone)

## What You Get

4 skills, installed into your Claude Code project:

| Skill | Invoke | What it does |
|-------|--------|--------------|
| `/gdlc` | during a feature cycle | Picks the right playtest cycle type (gameplay-matrix / art-craft-review / pipeline-contract-audit), runs persona agents, triangulates findings, promotes P0s to TDD RED |
| `/gdlc-setup` | first install | Auto-scans your project, detects surfaces (gameplay / art / pipeline), scaffolds a case-study `GDLC.md`, installs the skill suite. Asks only what scanning can't reveal. |
| `/gdlc-update` | periodically | Reads CHANGELOG, shows rule diffs, runs drift detection on managed files, applies updates selectively while preserving your `GDLC.md` |
| `/gdlc-feedback` | when you hit a gap | Files structured issues upstream to [BaseInfinity/claude-gdlc-wizard](https://github.com/BaseInfinity/claude-gdlc-wizard) — earned-rule candidates, playbook gaps, wizard bugs, methodology questions. Stock GitHub labels. |

## Install

Pick whichever fits your environment. All four paths land the same surface: 4 skills + 2 hooks + helper + settings.json + wizard doc. No sibling-repo clone required — the wizard is fully self-contained as of v0.2.1.

### Path 1 — `npx` (recommended)

From your game project root:

```bash
npx -y claude-gdlc-wizard init
```

That installs everything under `.claude/` and writes `CLAUDE_CODE_GDLC_WIZARD.md` to project root. Re-run any time — idempotent. `--force` overwrites; `--dry-run` previews.

### Path 2 — `curl | bash`

```bash
curl -fsSL https://raw.githubusercontent.com/BaseInfinity/claude-gdlc-wizard/main/install.sh | bash
```

Wraps the `npx` flow with Node ≥ 18 preflight + download guard.

### Path 3 — Claude Code plugin

Use the Claude Code plugin marketplace mechanism (see Anthropic docs) to install the plugin defined at `.claude-plugin/plugin.json`. Hooks resolve through `${CLAUDE_PLUGIN_ROOT}` automatically.

### Path 4 — manual clone (fallback)

```bash
git clone https://github.com/BaseInfinity/claude-gdlc-wizard ~/tmp/claude-gdlc-wizard
node ~/tmp/claude-gdlc-wizard/cli/bin/gdlc-wizard.js init
rm -rf ~/tmp/claude-gdlc-wizard
```

### After install — every path

In Claude Code, run `/gdlc-setup`. It auto-scans your project, asks the minimum, and scaffolds your `GDLC.md`. Verify with `npx claude-gdlc-wizard check` — expect every installed item (settings.json + 3 hook files + 4 skills + wizard doc + .gitignore additions = ~10 rows) to report `MATCH`.

## How It Works

GDLC runs **one or more of three cycle types** per release, never combined:

| Cycle | Target | Personas | Rubric | Ship Gate |
|-------|--------|----------|--------|-----------|
| **Gameplay-matrix** | Live game build | 5 gameplay personas (Tourist / Casual / Senior / Purist / Speedrunner — adapt per domain) | Fun / Fair / Readable / Persona-respect / Return | All personas ≥ threshold |
| **Art-craft-review** | Demo sink (`demo.html`) | 4 craft personas (Retro Gamer / Designer / Artist / Art Director) | Cohesion / Era / Hierarchy / Craft / Ship | Unanimous Ship |
| **Pipeline-contract-audit** | Contract harness | Dimension-specific (seed-literate, content-stopword, etc.) | TDD RED before any fix | All RED tests earn GREEN |

Features touching multiple surfaces run cycles **sequentially** — pipeline first (lock determinism), then gameplay (runtime behavior), then art (visual craft). Never combine rosters across cycles.

## Relationship to claude-sdlc-wizard

You should install **both**. SDLC runs in parallel with GDLC on every feature:

- **SDLC** — does the code work? Is it tested? (TDD, self-review, CI shepherd)
- **GDLC** — is the game good? Is it fair? (playtests, triangulation, ratchet)

SDLC without GDLC = clean code that produces boring games. GDLC without SDLC = fun games built with sloppy code.

## Contributing

File feedback using `/gdlc-feedback` from a Claude Code session. It creates a structured GitHub issue on [BaseInfinity/claude-gdlc-wizard](https://github.com/BaseInfinity/claude-gdlc-wizard) with stock labels (`bug` / `enhancement` / `question`) and a `[<type>]` title prefix.

## License

MIT.
