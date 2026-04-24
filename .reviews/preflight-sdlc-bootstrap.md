# Preflight Self-Review — SDLC Self-Bootstrap (retroactive)

> **Retroactive note.** This preflight was written *after* commit `1ad9441` shipped, in response to Codex round 1 review (`codex-review-sdlc-bootstrap.md`) flagging that the bootstrap commit didn't honor the rules it defined (no preflight, blast-radius tier exempted itself). The retroactive write is the dogfood fix: from this preflight forward, every change to `SDLC.md` / `TESTING.md` / `ARCHITECTURE.md` / `CLAUDE.md` requires a preflight + Codex round before merge.

## Scope

Bootstrap SDLC discipline on the `claude-gdlc-wizard` distribution repo itself, mirroring the dogfooding pattern of sibling `claude-sdlc-wizard`. The repo *ships* the GDLC wizard (4 skills, 2 hooks, CLI, plugin manifest) to consumer game projects; SDLC governs how the distribution machinery is *built*.

## Artifacts shipped (commit `1ad9441` + this round-2 fix commit)

- [x] `CLAUDE.md` — project overview, commands table, code style, session quirks, quality anchoring, git/commit conventions
- [x] `SDLC.md` — version metadata block (active 1.30.0 / upstream 1.36.1), enforcement table, hooks inventory, skills inventory, compliance-verification block, blast-radius tier
- [x] `TESTING.md` — meta-testing framing, 5-suite index, fresh-tmpdir simulation, settings-merge check, known gaps
- [x] `ARCHITECTURE.md` — ASCII system diagram, repo layout tree, component descriptions, distribution channels, key decisions
- [x] `.gitignore` — added `.claude/plans/`, `.claude/settings.local.json`

## Self-review

### Verified manually

- [x] All 4 docs internally cross-reference each other consistently (CLAUDE.md → SDLC/TESTING/ARCHITECTURE; SDLC → TESTING/ARCHITECTURE; TESTING → CLAUDE; ARCHITECTURE → SDLC/TESTING/CLAUDE). Round 2 fixes `CLAUDE.md:53` and `SDLC.md:90-104` to match reality.
- [x] Hook inventory in `SDLC.md` cross-checked against `~/.claude/plugins-local/sdlc-wizard-wrap/plugins/sdlc-wizard/hooks/` (4 scripts + 1 manifest = 5 entries; round-2 fix made the count explicit).
- [x] Test count of 94 cross-checked: `rg -c '^test_[a-z0-9_]+$' tests/*.sh` returns 22 + 13 + 18 + 20 + 21 = 94.
- [x] Full suite ran green (94/94, 0 failures) before commit `1ad9441` was authored.
- [x] Compliance-verification block was rewritten in round 2 with `set -euo pipefail`, named release artifacts (no glob), and a scratch-dir simulation for `gdlc-wizard check` (which legitimately reports MISSING when run at this repo's root because the repo is the distribution, not a consumer).
- [x] Blast-radius tier was rewritten in round 2 to remove the bootstrap-doc self-exemption.

### Intentional scope

- **Active wizard version is v1.30.0** (the wrap plugin is stale by 6 minor versions vs upstream 1.36.1). Documenting both makes the gap visible without requiring an update before the bootstrap can land. Update path is rsync from `~/tmp-refs/claude-sdlc-wizard/` per `reference_sdlc_wizard_wrap.md` in global memory.
- **No `model-effort-check.sh` / `precompact-seam-check.sh`** in the active plugin. SDLC.md flags these as missing-from-v1.30.0; consumers will get them when the wrap is updated.
- **CLI `check --json` at this repo's root reports MISSING.** That's correct behavior — this repo is the distribution, not a consumer install. Compliance verification therefore runs `check` in a scratch-dir tmpdir (round-2 fix).

### Pushback to Codex round 1

- **Round 1 check `(c)` rated CONCERN because Codex's sandbox blocked the test suite from running.** That's an environment artifact in Codex's read-only sandbox, not a repo bug. We ran the full suite green here before committing (94/94). Codex's own ripgrep assertion-count = 94 corroborates the claim. Closed without doc change.
- **Round 1 check `(f)` rated FAIL because `TESTING.md:96` literally contained the string `agentic-sdlc-wizard`** — but the sentence was *describing what NOT to have* in `install.sh`. False-positive shape, but Codex's fix proposal ("legacy SDLC package names") is cleaner anyway. Accepted in round 2.

### Concerns flagged for reviewer

1. **The retroactive nature of this preflight is itself the dogfood fix.** Going forward, the rule (per round-2 SDLC.md `Blast radius tier`) is: every change to the four governance docs requires preflight + Codex round before merge. This file establishes the precedent.
2. **The "session quirks" hooks-wipe paragraph in CLAUDE.md and TESTING.md is honest documentation of an environment artifact**, not an attempt to hide a bug. Consumer installs and CI are unaffected — only this dev environment wipes `hooks/` between Bash tool calls (afterhours git-hook chain via `core.hookspath`).
3. **The active-vs-upstream wizard version gap (1.30.0 vs 1.36.1)** is a real thing to fix eventually, but it's separate from this bootstrap. Filed in global memory as `reference_sdlc_wizard_wrap.md`.
4. **`SDLC.md` policies (`Tests as the compliance gate` + `Compliance verification` + `Blast radius tier`) now apply to this repo's own development.** A breaking change to any of those sections requires the same preflight + Codex round.

## Score (self-graded)

Round 1 self-grade was missing (no preflight existed). Round 2 self-grade after fixes: **7.5 / 10**.
- Would be 8 with a successful Codex round-2 recheck (CERTIFIED).
- Would be 9 with the wrap-plugin update (1.30.0 → 1.36.1 sync).
- 10 requires Phase 1 graduation (case study #2 + GitHub repo + push) which is user-gated.

## Round 2 fix manifest

Applied in commit subsequent to `1ad9441` per Codex round 1 verdict (NEEDS_WORK 5/10):

| File | Line | Fix |
|------|------|-----|
| `CLAUDE.md` | 53 | `init` → `init --dry-run` (correctly describes flag) + added scratch-dir real-install command |
| `TESTING.md` | 96 | Replace stale-package-name enumeration with abstract "legacy SDLC package-name leakage" rule |
| `ARCHITECTURE.md` | 47-52 | Added `.gitignore` to repo-layout tree + expanded `.reviews/` enumeration with sdlc-bootstrap artifacts |
| `SDLC.md` | 56-65 | Hook inventory: explicit "5 entries = 4 scripts + 1 manifest" framing |
| `SDLC.md` | 84-105 | Compliance block: `set -euo pipefail`, named release artifacts (no glob), scratch-dir simulation for `check` |
| `SDLC.md` | 106-114 | Blast radius: removed bootstrap-doc self-exemption; added meta-review-of-review-machinery exemption (with rationale) |
| `.reviews/preflight-sdlc-bootstrap.md` | new | This file |
