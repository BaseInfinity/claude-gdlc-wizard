---
name: gdlc-feedback
description: Structured feedback channel from a GDLC consumer project back to the upstream playbook. Files a well-formed GitHub issue on BaseInfinity/claude-gdlc-wizard with auto-attached case-study context (privacy-gated) and appends a traceability row to .gdlc/feedback-log.md. Never touches the consumer's GDLC.md body.
argument-hint: [earned-rule | gap | bug | wizard-bug | question | dry-run]
effort: high
---

# GDLC Feedback Skill

## Task

$ARGUMENTS

## MANDATORY FIRST ACTION: Read the Wizard Doc

**Before doing ANYTHING else**, use the Read tool to read `CLAUDE_CODE_GDLC_WIZARD.md` at the consumer project root — especially the "Managed files", "URLs", and feedback-related sections. It contains the canonical type → label map, the auto-context allowlist, and the upstream repo target. Do NOT proceed without reading it first.

If `CLAUDE_CODE_GDLC_WIZARD.md` is missing from the project root, the wizard wasn't installed. Stop and tell the user:

```bash
npx claude-gdlc-wizard init
```

## Purpose

Close the upstream feedback loop. With setup + update shipped, each consumer has its own case study that discovers its own earned rules, playbook gaps, and wizard bugs. Without a structured feedback channel those signals decay locally and framework-graduation becomes invisible to the playbook author.

`/gdlc-feedback` files a well-structured GitHub issue against `BaseInfinity/claude-gdlc-wizard` with privacy-gated auto-context, then appends one row to the consumer's `.gdlc/feedback-log.md` as a traceability record. It **never** writes to the consumer's `GDLC.md` body.

## Feedback types (canonical)

The skill prompts the user to pick exactly one. Each type maps to a stock GitHub label (`bug` / `enhancement` / `question`) — present on every repo by default, no upstream label setup required. The type identifier still appears as a `[<type>]` prefix in the issue title so filtering works without custom labels.

| Type identifier | GH label | When to use |
|-----------------|----------|-------------|
| `earned-rule-candidate` | `enhancement` | A rule surfaced in the consumer case study that might graduate to the playbook |
| `playbook-gap` | `enhancement` | The playbook doesn't cover a surface / persona / scenario the consumer hit |
| `playbook-bug` | `bug` | Internal inconsistency, wrong line reference, contradiction between rules |
| `wizard-bug` | `bug` | setup / update / feedback skill misbehaved |
| `methodology-question` | `question` | Genuine uncertainty about cycle selection, persona choice, triangulation |

Short-form arguments map back to the canonical identifiers: `earned-rule` → `earned-rule-candidate`, `gap` → `playbook-gap`, `bug` → `playbook-bug`, `wizard-bug` → `wizard-bug`, `question` → `methodology-question`.

## Auto-attached context (strict allowlist)

Every issue gets a fenced block at the top. Field inclusion is governed by a strict three-class allowlist. Unlisted fields are EXCLUDED — adding a new auto-context field requires a spec revision, not a setup/update release.

| Field | Source | Class | Default if redacted |
|-------|--------|-------|---------------------|
| `Installed` (WIZARD_VERSION) | `GDLC.md` metadata | AUTO | — |
| `Sibling SHA` (SHORT_SHA) | `GDLC.md` metadata | AUTO | — |
| `Setup Date` (YYYY-MM-DD) | `GDLC.md` metadata | AUTO | — |
| `Last Update` (YYYY-MM-DD) | `GDLC.md` metadata | AUTO | — |
| `Playtests` | count of `### Playtest #` in `GDLC.md` | AUTO | — |
| `Consumer` (PROJECT_NAME) | `GDLC.md` H1 | CONFIRM | `<redacted>` |
| `Surfaces` | `GDLC.md` Project Surfaces section | CONFIRM | `<redacted>` |

- **AUTO** — attached without prompting (non-identifying).
- **CONFIRM** — prompted individually at step-4; user accepts / redacts / edits. `<redacted>` is the default if declined.
- **EXCLUDED** — everything else. Case-study number is explicitly EXCLUDED from v0.4.0; it is not in the canonical metadata block yet, and adding it is a cross-skill change deferred to v0.5.0.

Default block (after per-field confirm):

```
Consumer:     <PROJECT_NAME or "<redacted>">
Installed:    <WIZARD_VERSION>
Sibling SHA:  <SHORT_SHA>
Setup Date:   <YYYY-MM-DD>
Last Update:  <YYYY-MM-DD>
Surfaces:     <list or "<redacted>">
Playtests:    <N> completed
```

## Execution Checklist

Follow these steps IN ORDER. Do not skip or combine steps.

### step-0.1 — Read Wizard Doc

Read `CLAUDE_CODE_GDLC_WIZARD.md` at the consumer project root (done above — this is the mandatory first action).

### step-1 — Read Consumer Metadata + Snapshot Hash

Parse the consumer's `GDLC.md` at project root:

- Five canonical metadata lines: `GDLC Wizard Version`, `GDLC Sibling SHA`, `GDLC Setup Date`, `GDLC Last Update`, `Completed Steps`.
- H1 heading (PROJECT_NAME).
- Project Surfaces section body.
- Count of `### Playtest #` headings.

Compute SHA-256 of the normalized metadata-header string (the five `<!-- GDLC ... -->` lines joined by `\n`, trailing whitespace stripped, LF-normalized). Stash this as `H1` for the step-5 race check.

### step-1.5 — Precondition Check

Verify in this order — abort with a specific next-step message on the first failure:

1. **`GDLC.md` exists and metadata well-formed.** All five canonical lines present. Missing → stop, point to `/gdlc-setup regenerate`.
2. **`.gdlc/feedback-log.md` exists.** Created by setup; migrated in by `/gdlc-update` for pre-v0.4.0 consumers. Missing → stop, tell user to run `/gdlc-update` first.
3. **`gh` installed.** `command -v gh` → if absent, stop; link to `cli.github.com`.
4. **`gh` authenticated.** `gh auth status` returns logged-in. If not, stop; tell user to run `gh auth login`.
5. **Account mismatch check.** If the authed user differs from a previously recorded feedback account (or an expected-account override), warn with both values and require explicit `yes` to continue or `switch` to abort.
6. **Upstream reachable and not archived.**
   ```bash
   gh repo view BaseInfinity/claude-gdlc-wizard --json isArchived,visibility
   ```
   Archived → stop ("feedback channel is closed"). 404 / private-unreachable → stop ("check repo access"). Network error → offer `dry-run` to save the body locally.

### step-2 — Prompt for Type

If no type-argument was passed, ask one question: pick one of the five canonical types. If the user passed a short-form argument (`earned-rule` / `gap` / `bug` / `wizard-bug` / `question`), skip this step and resolve to the canonical identifier via the map above.

### step-3 — Type-Specific Prompts

Ask only the template fields for the chosen type. No generic "anything else?" catch-all — force structure.

| Type | Template fields |
|------|-----------------|
| `earned-rule-candidate` | Rule statement, playtest number, evidence (file:line in consumer repo), recurrence (1st time or 2nd+), proposed playbook section |
| `playbook-gap` | Gap description, surface class, what the consumer did instead, proposed addition |
| `playbook-bug` | Affected rule numbers, contradiction description, suggested fix |
| `wizard-bug` | Skill name (one of: `gdlc`, `gdlc-setup`, `gdlc-update`, `gdlc-feedback`), argument used, expected vs actual behavior, consumer wizard version + sibling SHA (auto-filled from metadata) |
| `methodology-question` | The question, what the consumer tried, what they'd expect the playbook to say |

### step-4 — Preview + Privacy Confirm

Assemble the full issue body: title + auto-context block + type-specific fields. Then:

1. **Per-field privacy confirm for each CONFIRM-class context field** (currently `Consumer` and `Surfaces`). For each:
   - Show the current value.
   - Prompt: `accept` / `redact` / `edit`.
   - `redact` replaces the value with `<redacted>`.
   - `edit` lets the user type a replacement string.
2. **Full-body confirm.** Show the assembled body. Prompt: `file` / `edit` / `cancel`.
   - `edit` re-opens prompt fields for revision, then returns to step-4.
   - `cancel` → write partial answers to `.gdlc/feedback-drafts/<ISO-timestamp>.md`, exit cleanly, do NOT file, do NOT append log row.

Title convention: `[<type>] <one-line summary>`.

### step-5 — Race-Check + File Issue

**Race check first.** Reread the `GDLC.md` metadata header (same five canonical lines), recompute SHA-256 as `H2`. Compare to `H1` from step-1:

- **`H1 ≠ H2`** → metadata changed mid-flow (most likely `/gdlc-update` ran concurrently). Abort filing. Save the drafted body + type-specific answers to `.gdlc/feedback-drafts/<ISO-timestamp>.md` for recovery. Tell the user: "GDLC.md metadata changed during this flow (likely a concurrent `/gdlc-update`). Re-run `/gdlc-feedback` to capture fresh context — your draft is at `.gdlc/feedback-drafts/<ts>.md`."
- **`H1 = H2`** → proceed. Resolve the label via the canonical type → label map; file via `gh`:
  ```bash
  gh issue create -R BaseInfinity/claude-gdlc-wizard \
    --title "<title>" \
    --body "<body>" \
    --label "<label_for_type>"
  ```
  Capture the returned issue URL and number.

### step-6 — Verify

Round-trip to confirm the issue exists and labels were applied:

```bash
gh issue view <number> -R BaseInfinity/claude-gdlc-wizard --json number,labels,url
```

- If the issue exists and the expected label is present → proceed to step-7.
- If `gh issue view` returns unknown-issue or the label is missing → report the ambiguity to the user and do NOT proceed to step-7. The user verifies manually on GitHub.

### step-7 — Append to Feedback Log

Only runs if step-5 filed successfully AND step-6 verified. Append one row to `.gdlc/feedback-log.md`:

```
| 2026-04-22 | earned-rule-candidate | #123 | "one-line summary from issue title" |
```

Columns: date (YYYY-MM-DD, today), canonical type identifier, issue number with `#` prefix, one-line summary quoted.

The log is append-only. The skill **never** rewrites existing rows and **never** writes to `GDLC.md` under any code path.

## Arguments

- `(none)` — full interactive flow.
- `earned-rule` / `gap` / `bug` / `wizard-bug` / `question` — skip step-2; jump to type-specific prompts. Arguments resolve to canonical identifiers via the map in "Feedback types" above.
- `dry-run` — run through step-4 (preview), print the assembled body, skip filing AND skip log append. Safe to run unattended.

## Managed files (in consumer project)

| Path | Created by | Behavior under `/gdlc-feedback` |
|------|------------|-------------------------------|
| `.claude/skills/gdlc-feedback/SKILL.md` | `npx claude-gdlc-wizard init` (the CLI) | Installed by the CLI from this repo; drift-detected by `/gdlc-update` via `npx claude-gdlc-wizard check`. Not mutated by feedback. |
| `.gdlc/feedback-log.md` | `/gdlc-setup` on fresh install; `/gdlc-update` migration for pre-v0.4.0 consumers | Append-only. The only file feedback writes to under the happy path. |
| `.gdlc/feedback-drafts/<ts>.md` | `/gdlc-feedback` on cancel-mid-flow or race-check-abort | Transient; `.gitignore`d. Recovers partial prompt answers. Pruned at the top of subsequent runs if older than 14 days. |
| `GDLC.md` | `/gdlc-setup` | **Never mutated by feedback.** Read-only from this skill's perspective. |

## Failure Modes

### Environment / dependencies
- **`gh` not installed** → stop; link to `cli.github.com`.
- **`gh auth status` fails** → stop; tell user to `gh auth login`.
- **Account mismatch** → warn with authed-username and target-repo; require explicit `yes` or `switch`.
- **Network unreachable** → offer `dry-run` output so user can file manually later. Do NOT append to the log.
- **Rate limit** → back off + print body for retry. Do NOT append to the log.

### Upstream repo state
- **`BaseInfinity/claude-gdlc-wizard` archived** → stop; tell user feedback channel is closed.
- **`BaseInfinity/claude-gdlc-wizard` private / 404** → stop; tell user to check access.
- **Issue-create permission denied (403)** → stop; print body for manual submission. **Do not** fall back to filing in the consumer's own repo (Anti-goal #7).

### Consumer state
- **`GDLC.md` missing** → stop; run `/gdlc-setup`.
- **`GDLC.md` metadata malformed** (missing one of the five required `<!-- GDLC ... -->` lines) → stop; run `/gdlc-setup regenerate`.
- **`.gdlc/feedback-log.md` missing** → stop; run `/gdlc-update` (its migration step creates it).
- **`GDLC.md` or `.gdlc/feedback-log.md` dirty** (uncommitted changes) → warn + require explicit confirm before the step-7 append.

### Flow control
- **User cancels after one or more type-specific prompts** → write partial answers to `.gdlc/feedback-drafts/<ISO-timestamp>.md`, exit cleanly. No file, no log row.
- **User cancels at step-4 preview** → write partial answers to `.gdlc/feedback-drafts/<ISO-timestamp>.md`, exit cleanly. No file, no log row. (Matches step-4 cancel path — type-specific prompt answers are user-entered, not derivable from auto-context.)
- **Race at step-5** (`H1 ≠ H2`) → abort filing, save draft for recovery (see step-5).
- **Post-submit ambiguous failure** (network drop after `gh issue create` sends but before response parses) → do NOT append the log row until step-6 verify confirms. If verify returns unknown-issue, report ambiguity; user checks GH manually.

## Rules

1. **Never mutate `GDLC.md`.** The skill has zero write paths to the case-study body. All logging goes to `.gdlc/feedback-log.md`.
2. **Never insert sections into an existing case-study body.** Body-immutability is the triple's core invariant; feedback is the strictest observer of it.
3. **Never silent-file.** Every issue passes through preview + per-field CONFIRM + overall confirm. `dry-run` is the only non-filing mode; there is no `--yes` fast-path.
4. **Never read, store, or transmit tokens.** All auth goes through `gh` CLI.
5. **Never fall back to the consumer's own repo.** Upstream-only in v0.4.0. Permissions-denied means stop + print body for manual submission.
6. **Never auto-promote new metadata fields.** Adding a field to the auto-context block requires a spec revision, not a setup/update release. Classification (AUTO / CONFIRM / EXCLUDED) is set explicitly when a field is introduced.
7. **Race-check at step-5, not earlier.** Reading once and trusting the snapshot is the bug; lock-free optimistic concurrency catches the real concurrent-update race.

## Anti-goals

1. **No auto-graduation.** The skill files issues; it never edits the upstream `GDLC.md` playbook in `claude-gdlc-wizard`.
2. **No cross-project feedback aggregation.** Each consumer files its own issues. No telemetry, no central rollup.
3. **No silent filing.** Every issue: preview + per-field CONFIRM + overall confirm. No `--yes`.
4. **No credential handling.** Delegated to `gh`.
5. **No writes to consumer `GDLC.md`.** All logging to `.gdlc/feedback-log.md` instead.
6. **No section insertion into populated case-study bodies.** Triple invariant.
7. **No local-repo fallback in v0.4.0.** Upstream-only.
8. **No un-confirmed identity leaks.** `Consumer` and `Surfaces` require explicit confirm at step-4. New metadata fields default to EXCLUDED.
