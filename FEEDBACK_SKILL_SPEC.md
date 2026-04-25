# `/gdlc-feedback` Skill — Design Spec

Status: **SHIPPED in v0.4.0.** Design artifact retained for rationale + review trail.

Revision history:
- 2026-04-19 (v1): initial draft; Codex round 1 scored 4/10 NOT CERTIFIED with 7 findings.
- 2026-04-19 (v2): rewrite — addresses all 7 findings. Key changes: traceability log moved out of `GDLC.md` into `.gdlc/feedback-log.md` (resolves P0 body-immutability); explicit type→label map; privacy allowlist on auto-context; failure modes expanded; case-study# dropped from v0.4.0 auto-context; success criteria reframed; race-check discipline added.
- 2026-04-19 (v3): round-2 review resolved — finding 2 preview-cancel aligned to save-draft behavior. Codex round-2 CERTIFIED 8/10.

## Why this skill exists

With the `gdlc-setup` + `gdlc-update` pair shipped (v0.3.0, 2026-04-19), GDLC now has multiple consumers instead of a single case study. Each case study discovers its own earned rules, hits its own playbook gaps, and finds its own wizard bugs. Without a structured feedback channel, those signals decay: the consumer patches locally, the upstream playbook never hears about it, and framework-graduation (case study #2 producing an earned rule not in case #1's ratchet) becomes invisible to the author.

`/gdlc-feedback` closes that loop. It's the third leg of the wizard-pair trio — setup installs, update pulls, feedback pushes.

## Scope

- **What it does:** files a well-structured GitHub issue against `BaseInfinity/gdlc` from inside a consumer project, with context auto-attached from the case-study metadata.
- **What it does NOT do:** open PRs, push commits to the sibling repo, or auto-graduate rules. Graduation is an upstream decision made by the playbook author after reading the issue.
- **What it does NOT touch:** the consumer's `GDLC.md` body. The traceability log lives in `.gdlc/feedback-log.md` (separate file), not inside `GDLC.md`.

## Feedback types (required taxonomy)

The skill prompts the user to pick exactly one type. Each type maps to a GH label and a structured issue template.

| Type | GH label | When to use | Template fields |
|------|----------|-------------|-----------------|
| **earned-rule-candidate** | `enhancement` | A rule surfaced in the consumer's case study that might graduate to the playbook | Rule statement, playtest number, evidence (file:line in consumer repo), recurrence (1st time or 2nd+), proposed playbook section |
| **playbook-gap** | `enhancement` | The playbook doesn't cover a surface / persona / scenario the consumer hit | Gap description, surface class, what the consumer did instead, proposed addition |
| **playbook-bug** | `bug` | Internal inconsistency, wrong line reference, contradiction between rules | Affected rule numbers, contradiction description, suggested fix |
| **wizard-bug** | `bug` | setup / update / feedback skill misbehaved | Skill name, argument used, expected vs actual, consumer version + sibling SHA |
| **methodology-question** | `question` | Genuine uncertainty about cycle selection, persona choice, triangulation | The question, what the consumer tried, what they'd expect the playbook to say |

Earned-rule-candidate is the load-bearing type. The other four are secondary.

Labels are stock GitHub labels (no per-repo setup required). Type identifier is preserved as a `[<type>]` prefix in the issue title so filter semantics survive the label collapse.

**Canonical type → label map** (source of truth for step-5's `--label` flag):

| Type identifier (arg / prompt value) | GH label applied | Title prefix |
|--------------------------------------|------------------|--------------|
| `earned-rule-candidate` | `enhancement` | `[earned-rule-candidate]` |
| `playbook-gap` | `enhancement` | `[playbook-gap]` |
| `playbook-bug` | `bug` | `[playbook-bug]` |
| `wizard-bug` | `bug` | `[wizard-bug]` |
| `methodology-question` | `question` | `[methodology-question]` |

## Auto-attached context (from case-study metadata)

Every issue gets a fenced block at the top. Field inclusion is governed by a strict allowlist — each field is classified as AUTO (attached without prompting) or CONFIRM (requires explicit user confirmation at step-4; defaults REDACTED if declined). Unlisted fields are EXCLUDED.

| Field | Source | Class | Default if redacted |
|------|--------|-------|---------------------|
| `Installed` (WIZARD_VERSION) | `GDLC.md` metadata | AUTO | — |
| `Sibling SHA` (SHORT_SHA) | `GDLC.md` metadata | AUTO | — |
| `Setup Date` (YYYY-MM-DD) | `GDLC.md` metadata | AUTO | — |
| `Last Update` (YYYY-MM-DD) | `GDLC.md` metadata | AUTO | — |
| `Playtests` | count of `### Playtest #` in `GDLC.md` | AUTO | — |
| `Consumer` (PROJECT_NAME) | `GDLC.md` H1 | CONFIRM | `<redacted>` |
| `Surfaces` | `GDLC.md` Project Surfaces section | CONFIRM | `<redacted>` |

Default block (after per-field confirm):

```
Consumer:     <PROJECT_NAME or "<redacted>">    (confirm required)
Installed:    <WIZARD_VERSION>
Sibling SHA:  <SHORT_SHA>
Setup Date:   <YYYY-MM-DD>
Last Update:  <YYYY-MM-DD>
Surfaces:     <list or "<redacted>">             (confirm required)
Playtests:    <N> completed
```

**Case-study number is intentionally NOT included in v0.4.0 auto-context.** The canonical metadata block does not yet carry a case-study# line; adding one is a cross-skill change affecting setup + update + wizard-doc + migration, deferred to v0.5.0. If a consumer wants to note which case study this is, they can include it in user-provided prompt fields.

**Privacy invariant:** adding a new field to the auto-context block requires a spec revision. Future setup / update releases do NOT automatically promote new metadata fields into the auto-context block. Classification (AUTO / CONFIRM / EXCLUDED) must be set explicitly when the field is introduced.

## Execution flow

1. **step-0.1 — Read wizard doc.** Same mandatory-first-action pattern as setup / update.
2. **step-1 — Read consumer metadata + snapshot hash.** Parse `GDLC.md` metadata header (the five canonical `<!-- GDLC ... -->` lines) for version, SHA, setup date, last update, completed steps. Also parse H1 (PROJECT_NAME), Project Surfaces section, and count `### Playtest #` headings. Compute SHA-256 of the normalized metadata-header string; stash it for the step-5 race check.
3. **step-1.5 — Precondition check.** Verify:
   - `GDLC.md` exists and metadata is well-formed (required lines present). Missing → stop, point to `gdlc-setup regenerate`.
   - `.gdlc/feedback-log.md` exists (created by setup; migrated in by update for pre-v0.4.0 consumers). Missing → stop, tell user to run `/gdlc-update` first.
   - `gh` installed + authenticated. Failures handled per Failure modes.
   - Upstream `BaseInfinity/gdlc` reachable and not archived. Failures handled per Failure modes.
4. **step-2 — Prompt for type.** One question: pick one of the five types above.
5. **step-3 — Type-specific prompts.** Ask only the fields in the template for the chosen type. No generic "anything else?" fields — force structure.
6. **step-4 — Preview + privacy confirm.** Show the full issue body (title + context block + user-provided fields) before filing. For each CONFIRM-class context field (Consumer, Surfaces), prompt individually: accept / redact to default / edit. User then confirms or edits the full assembled body.
7. **step-5 — Race-check + file issue.** Reread `GDLC.md` metadata header; recompute hash `H2`. Compare to step-1 hash `H1`:
   - If `H1 ≠ H2`: abort filing. Tell user "GDLC.md metadata changed during flow (likely `/gdlc-update` ran). Re-run `/gdlc-feedback` to capture fresh context." Draft fields are preserved in `.gdlc/feedback-drafts/<ISO-timestamp>.md` for recovery.
   - If `H1 = H2`: file via canonical label lookup:
     ```
     gh issue create -R BaseInfinity/gdlc \
       --title "<title>" \
       --body "<body>" \
       --label "<label_for_type>"
     ```
     where `<label_for_type>` is resolved from the canonical type → label map above.
8. **step-6 — Verify.** `gh issue view <number> -R BaseInfinity/gdlc` round-trip. Confirms (a) issue exists, (b) labels applied. If verify fails with unknown-issue, report the ambiguity to the user and do NOT proceed to step-7.
9. **step-7 — Append to feedback log.** Only if step-5 filed successfully AND step-6 verified. Append one row to `.gdlc/feedback-log.md`:
   ```
   | 2026-04-22 | earned-rule-candidate | #123 | "Contract-audit persona deserves its own cycle type" |
   ```
   The feedback log is append-only; the skill never rewrites existing rows. **The skill never touches `GDLC.md` under any code path.**

## Arguments

- `(none)` — full interactive flow.
- `earned-rule` / `gap` / `bug` / `wizard-bug` / `question` — skip step-2; jump to type-specific prompts. Argument tokens map to types via the same canonical map (e.g. `earned-rule` → `earned-rule-candidate` → `enhancement`).
- `dry-run` — run through step-4 (preview), print the issue body, skip filing AND skip log append. Safe to run unattended.

## Managed files (in consumer project)

| Path | Created by | Behavior under `gdlc-feedback` |
|------|------------|-------------------------------|
| `.claude/skills/gdlc-feedback/SKILL.md` | `gdlc-setup` | Installed verbatim from sibling; drift-detected by `gdlc-update`. Not mutated by feedback. |
| `.gdlc/feedback-log.md` | `gdlc-setup` (empty with header row at install time); migrated in idempotently by `gdlc-update` for pre-v0.4.0 consumers | Append-only. The skill never rewrites existing rows. **The only file feedback ever writes to.** |
| `.gdlc/feedback-drafts/<ts>.md` | `gdlc-feedback` on cancel-mid-flow | Transient; `.gitignore`d. Recovers partial prompt answers. Pruned by subsequent `/gdlc-feedback` runs after 14 days. |
| `GDLC.md` | `gdlc-setup` | **Never mutated by feedback.** Read-only from this skill's perspective. |

## Integration with existing wizard pair

- **`gdlc-setup` step-5 (case-study scaffold):** also creates `.gdlc/feedback-log.md` with a one-row header table, and adds `.gdlc/feedback-drafts/` to `.gitignore`. The case-study body itself is unchanged.
- **`gdlc-setup` step-4 (skill copy):** copies all four skills — `gdlc/SKILL.md`, `gdlc-setup/SKILL.md`, `gdlc-update/SKILL.md`, `gdlc-feedback/SKILL.md` — in one step.
- **`gdlc-update` migration step** (new, one-time per consumer): if `.gdlc/feedback-log.md` is missing (pre-v0.4.0 consumer), create it with the header row; also add `.gdlc/feedback-drafts/` to `.gitignore` if absent. This is purely file creation + gitignore append — no mutation of `GDLC.md` body. Dirty-tree check applies.
- **`gdlc-update` drift matrix:** add `gdlc-feedback/SKILL.md` to the MATCH / CUSTOMIZED / MISSING / DRIFT classification.
- **Wizard doc `Managed files` table:** add the feedback skill file + feedback log as new rows.
- **`CHANGELOG.md` v0.4.0 entry:** "Added: `gdlc-feedback` skill; `.gdlc/feedback-log.md` scaffold. Changed: setup + update now manage the feedback skill + log as paired artifacts; update performs one-time `.gdlc/` migration for pre-v0.4.0 consumers."

## Prerequisites

- `gh` CLI installed + authenticated (`gh auth status` returns logged-in).
- Consumer has network access + permission to open issues on `BaseInfinity/gdlc`.
- Consumer's `GDLC.md` exists and has valid metadata (run `gdlc-setup regenerate` if missing).
- Consumer has `.gdlc/feedback-log.md` (run `/gdlc-update` first for pre-v0.4.0 consumers — the migration step creates it idempotently).

## Failure modes

### Environment / dependencies
- `gh` not installed → stop; link to `cli.github.com`.
- `gh auth status` fails → stop; tell user to `gh auth login`.
- `gh auth status` returns an **account mismatch** (different login than previously recorded, or user-configured expected account) → warn: show the authed username and target repo, require explicit `yes` to continue or `switch` to abort.
- Network unreachable → offer `dry-run` output so the user can save the body + file manually later. Do NOT append to `.gdlc/feedback-log.md`.
- Rate limit → back off + print the body for retry. Do NOT append to `.gdlc/feedback-log.md`.

### Upstream repo state
- `BaseInfinity/gdlc` archived (`gh repo view -R BaseInfinity/gdlc --json isArchived` returns true) → stop; tell user feedback channel is closed.
- `BaseInfinity/gdlc` private / unreachable (404) → stop; tell user to check access.
- Issue-creation permission denied (403) → stop; print body for manual submission. **Do not** fall back to filing in the consumer's own repo (v0.4.0 is upstream-only; see Anti-goal #7).

### Consumer state
- `GDLC.md` missing → stop; tell user to run `/gdlc-setup`.
- `GDLC.md` metadata malformed (missing required `GDLC Wizard Version` or `GDLC Sibling SHA` lines) → stop; tell user to run `/gdlc-setup regenerate`.
- `.gdlc/feedback-log.md` missing → stop; tell user to run `/gdlc-update` (the migration step will create it).
- `GDLC.md` or `.gdlc/feedback-log.md` has uncommitted changes (dirty tree) → warn + require explicit confirm before step-7 append.

### Flow control
- User cancels after answering one or more type-specific prompts → acknowledge cancel, write partially-assembled draft to `.gdlc/feedback-drafts/<ISO-timestamp>.md`, exit cleanly. Do NOT file, do NOT append log row.
- User cancels at preview (step-4) → write partial answers to `.gdlc/feedback-drafts/<ISO-timestamp>.md`, exit cleanly, no filing, no log append. (Type-specific prompt answers are user-entered and not re-derivable from auto-context; draft save prevents answer-loss on preview cancel.)
- Race between step-1 and step-5 (metadata changed mid-flow — e.g. concurrent `/gdlc-update`) → hash-check at step-5 aborts filing; draft saved for recovery (see step-5).
- Post-submit ambiguous failure (network drop after `gh issue create` sends but before response parses) → do NOT append log row until step-6 verify confirms. If verify returns unknown-issue, report ambiguity; user checks GH manually.

## Anti-goals (things this skill MUST NOT do)

1. **No auto-graduation.** The skill files issues; it never edits the upstream `~/gdlc/GDLC.md` playbook. Graduation is the upstream author's call.
2. **No cross-project feedback aggregation.** Each consumer files its own issues. No telemetry, no central rollup.
3. **No silent filing.** Every issue goes through preview + per-field privacy confirm + overall confirm. `dry-run` is the only non-filing mode; there is no `--yes` fast-path.
4. **No credential handling.** Delegate all auth to `gh` CLI. The skill never reads, stores, or transmits tokens.
5. **No writes to consumer `GDLC.md`.** The feedback skill never mutates `GDLC.md` under any code path. All logging goes to `.gdlc/feedback-log.md` instead.
6. **No section insertion into an existing case-study body.** Skills (setup / update / feedback) never insert new sections into a populated `GDLC.md` body. Setup scaffolds fresh; update migrates via separate-file creation; feedback only appends to a separate log file.
7. **No local-repo fallback in v0.4.0.** Permissions-denied means stop + print body for manual submission, not redirect to consumer's own repo.
8. **No un-confirmed identity leaks.** `Consumer` and `Surfaces` require explicit confirm at step-4. Future metadata fields default to EXCLUDED unless a spec revision classifies them.

## Open questions (decide before implementation)

1. **Issue title convention.** Proposal: `[<type>] <one-line summary>`. Alternative: free-form. → Start structured; relax if annoying.
2. **Draft-recovery retention.** Proposal: `.gdlc/feedback-drafts/` entries older than 14 days get pruned at the top of each `/gdlc-feedback` run. → Cleanup is cheap; adopt.
3. **`wizard-bug` skill-name dropdown.** v0.4.0 introduces a fourth managed skill (`gdlc-feedback`); the `Skill name` template field should be a dropdown of `{gdlc, gdlc-setup, gdlc-update, gdlc-feedback}`. → Small template change; bundle with implementation.
4. **Does the triple extend to PDLC / SDLC?** Eventually yes (pdlc-feedback, sdlc-feedback) — but scope v0.4.0 to GDLC only; generalize once the pattern has a second case study.

### Decided (previously open)

- ~~**Case-study number source of truth.**~~ **DECIDED**: drop from v0.4.0 auto-context block. Revisit in v0.5.0 as a coordinated cross-skill change (setup + update + wizard-doc + migration path) if demand exists.
- ~~**Feedback-log location** (inside `GDLC.md` vs separate file).~~ **DECIDED**: separate file (`.gdlc/feedback-log.md`). Resolves P0 body-immutability by eliminating the need for any section insertion.
- ~~**Local-repo fallback.**~~ **DECIDED**: no in v0.4.0 (Anti-goal #7). Revisit post-v0.4.0 if a real private-case-study need surfaces.

## Success criteria for v0.4.0 release

- `gdlc-feedback` fires end-to-end against a realistic test issue OR from a second consumer project. **Does NOT require a real PDLC earned-rule** — that conflates skill-quality with playbook-graduation, which v0.3.0 explicitly split into distribution-readiness vs framework-graduation.
- `gdlc-setup` installs all three additional skills (setup + update + feedback) and scaffolds `.gdlc/feedback-log.md`.
- `gdlc-update` drift-detects all three skills and runs the one-time `.gdlc/` migration idempotently on pre-v0.4.0 consumers.
- Preview → per-field privacy confirm → file cycle produces a well-labeled issue with the redaction-respecting auto-context block.
- Race-condition hash-check at step-5 correctly aborts filing when metadata changed mid-flow (verified by an integration test that triggers a concurrent `gdlc-update` between step-1 and step-5).
- Codex cross-model review certifies body-immutability holds under every argument path (same bar as `gdlc-update`).

### Framework-graduation forcing function (not a shipping gate)

Separate from v0.4.0 release: one real playtest-earned rule from a second consumer (PDLC or equivalent case study #2) filed via `/gdlc-feedback earned-rule` and accepted by the playbook author. This gates **framework-graduation**, not the v0.4.0 release itself — consistent with the v0.3.0 split of distribution-readiness vs framework-graduation.

## Estimated complexity

- Feedback skill file: ~300-400 lines (adds race-check + per-field privacy confirm + draft-recovery vs `gdlc-update`'s ~200).
- Wizard-doc updates: ~70 lines (case-study scaffold for `.gdlc/`, step registry entries for feedback + migration, managed-file rows).
- Setup integration: ~40 lines (copy fourth skill, create `.gdlc/feedback-log.md`, add drafts-dir to `.gitignore`).
- Update integration: ~50 lines (drift-detect fourth skill, one-time `.gdlc/` migration with dirty-tree check).
- Total: one focused afternoon of work after this spec is approved (Codex round 2 certifies).
