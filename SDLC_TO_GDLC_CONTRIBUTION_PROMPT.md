# SDLC → GDLC Contribution Prompt

> Paste everything below "## The Prompt" into a Claude Code session in your
> `~/claude-sdlc-wizard` checkout. It runs autonomously: scans SDLC, compares
> against `BaseInfinity/claude-gdlc-wizard`, files PRs and issues from your fork.

## The Prompt

You're collaborating with Stefan Ayala on the XDLC ecosystem. You maintain
`~/claude-sdlc-wizard`; he maintains the sibling repo `BaseInfinity/claude-gdlc-wizard`
(same scaffolding, games instead of code). Mine your SDLC playbook for lessons that
should port to GDLC, file them upstream, and get credit via your own gh account.

### 0. Pre-flight

```bash
gh auth status                                          # must be authenticated
git -C ~/claude-sdlc-wizard rev-parse HEAD              # capture SDLC HEAD for refs
gh repo view BaseInfinity/claude-gdlc-wizard >/dev/null # confirm reachable
```

If you forked from a previous session, sync first:

```bash
gh repo sync <your-username>/claude-gdlc-wizard --branch main
```

### 1. Read the SDLC side

Scan all four sources before triaging:

- `~/claude-sdlc-wizard/PLAYBOOK_CHANGELOG.md` and any earned-rules file — highest signal
- `git -C ~/claude-sdlc-wizard log --oneline -50` plus bodies of the last ~20 commits
- `~/claude-sdlc-wizard/tests/` and `.github/workflows/`
- `~/claude-sdlc-wizard/hooks/`, `cli/`, `install.sh`
- `~/xdlc/README.md` for meta-context

### 2. Read the GDLC side fresh

Clone current upstream — don't assume:

```bash
gh repo clone BaseInfinity/claude-gdlc-wizard /tmp/gdlc-upstream
```

Read `GDLC.md`, `PLAYBOOK_CHANGELOG.md`, `CLAUDE.md`, `TESTING.md`, `skills/*/SKILL.md`,
`hooks/`, `tests/`, `.github/workflows/`. Map SDLC's shape onto GDLC's shape.

### 3. Starter hypotheses (verify before porting)

Stefan already scanned the deltas. Confirm each is still missing, then triage normally:

**Hooks SDLC has, GDLC doesn't:**

- `model-effort-check.sh` — GDLC's `CLAUDE.md` mandates "Opus 4.7 effort ≥ xhigh" but
  has no hook enforcing it. High-confidence PORT.
- `tdd-pretool-check.sh` — GDLC's analog is "regression before fix" (manual). Hook-
  enforcing it would mirror SDLC. Likely PORT.
- `goal-confidence-check.sh`, `precompact-seam-check.sh`, `token-spike-check.sh` —
  domain-agnostic on the SDLC side; verify they make sense for GDLC's workflow.

**CI workflows SDLC has, GDLC doesn't:**

- `pr-review.yml` — GDLC has zero PR automation. Strong PORT candidate.
- `cc-version-drift.yml`, `release-dry-run.yml`, `weekly-update.yml`,
  `weekly-api-update.yml` — verify whether GDLC's release cadence needs them.

**Docs SDLC has, GDLC doesn't:**

- `CONTRIBUTING.md` — GDLC has no contributor guide. If you start here, open an issue
  proposing the structure FIRST; don't PR a CONTRIBUTING.md into a vacuum.
- `CI_CD.md`, `AGENTS.md`, `CODE_REVIEW_EXCEPTIONS.md` — verify need.

If a hypothesis is wrong (file already exists, or GDLC deliberately chose not to —
check the changelog/CLAUDE.md for "we don't do X" signals), drop it and note
"verified absent — skipping" in your summary.

### 4. Triage each candidate

- **PORT (→ PR)**: domain-agnostic scaffolding — hook pattern, test discipline, CLI
  ergonomic, install-script convention, CI gate.
- **DISCUSS (→ issue)**: interesting but needs game-domain translation, or wider than
  one PR.
- **SKIP**: SDLC-specific (type-checker integrations, lint configs, framework-bound
  testing, anything autocompact/score-trends/codex-adapter shaped).

### 5. File the work

Fork once:

```bash
gh repo fork BaseInfinity/claude-gdlc-wizard --clone --remote
```

**For PORT items**: branch → commit → push → `gh pr create`. One PR per lesson.
Conventional commits (`feat(scope): …`, `test(scope): …`, `docs(scope): …`). Before
pushing, all 5 suites must be green:

```bash
for t in tests/*.sh; do bash "$t" || break; done
```

PR body template:

```
## Summary
<one-line: what this PR ports from SDLC>

## Source
- SDLC ref: <link to file or commit in BaseInfinity/claude-sdlc-wizard@<sha>>
- Lesson: <why this earned its keep in SDLC>

## GDLC fit
- Why it ports: <domain-agnostic? maps to existing GDLC concept?>
- Vernacular changes: <e.g. `_find-sdlc-root.sh` → `_find-gdlc-root.sh`>

## Test plan
- [ ] All 5 suites green
- [ ] <new assertions added>

## Out of scope
<what you deliberately did not port and why>
```

**For DISCUSS items**: `gh issue create` with one of the stock labels only —
`bug` / `enhancement` / `question`. Don't invent labels. No PR until Stefan agrees.

Issue body template:

```
## Lesson from SDLC
<one-line>

## Source
<link to SDLC file/commit>

## How it could translate to GDLC
<2-4 sentences>

## Suggested next step
- [ ] Direct PR (small, low-risk)
- [ ] Spike + design review
- [ ] Defer (interesting but not now)
```

### 6. Attribution — strict

- Your `gh` account authors everything → credit is automatic.
- **NEVER** add Claude Code attribution to commits, PR bodies, or issues. No
  `🤖 Generated with…` footer, no `Co-Authored-By: Claude` line. GDLC's `CLAUDE.md`
  forbids it; PRs containing it will be rejected.

### 7. Quality bar

- Max ~3 PRs + ~5 issues per session. Stefan has to actually review these.
- PR >300 LoC → open an issue first instead.
- **Match GDLC vernacular, don't import SDLC naming.** `sdlc-*` files in GDLC will be
  rejected on sight. Read existing `_find-gdlc-root.sh` for the convention.
- **Additive only.** Don't refactor existing GDLC code in the same PR as a port. If a
  port reveals a refactor opportunity, that's a separate issue.
- **Some absences are deliberate.** Read GDLC's `CLAUDE.md` and `PLAYBOOK_CHANGELOG.md`
  for "we don't do X" signals before proposing X.
- Don't touch `GDLC.md` body — that's the case-study, not a porting target.
- Tests follow "Prove-It-Gate" (see `TESTING.md`). No tautologies — any test you add
  must assert behavior that could plausibly break.
- Skip anything you're <70% confident on.

### 8. Summary + blocked handling

When done (or blocked), write `~/gdlc-contribution-log.md`:

```
# GDLC Contribution Run — <date>

## PRs filed
- #NNN — <title> — <one-line outcome>

## Issues filed
- #NNN — <title> — <one-line>

## Skipped
- <lesson> — <reason>

## Blocked on Stefan
- <thing> — opened issue #NNN with `question` label, prefix `[blocked]`
```

If GDLC's `PLAYBOOK_CHANGELOG.md` already mentions a lesson you were about to port,
skip it — it's known.

If you can't decide on your own, open a `[blocked]`-prefixed `question` issue — don't
stop silently. Stefan can unblock async.
