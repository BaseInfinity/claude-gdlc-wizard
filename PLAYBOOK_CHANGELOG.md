# Changelog

All notable changes to the GDLC playbook and skill are documented here. The format follows [Keep a Changelog](https://keepachangelog.com/) and versioning is [semver](https://semver.org/) where the minor bumps track earned-rule additions and the patch bumps track skill/distribution fixes.

## [0.4.1] - 2026-04-19

### Changed
- `gdlc-feedback` skill — label map simplified from custom `feedback:*` labels to stock GitHub labels (`bug` / `enhancement` / `question`). Custom labels required per-repo setup and silently aborted `gh issue create` on any repo without them pre-provisioned. Type identifier still appears as `[<type>]` prefix in issue titles, preserving filter semantics without the pre-install burden.

### Rationale
First real filing attempt from codeguesser (case study #1) surfaced the cancellation cascade: `gh issue create --label feedback:wizard` failed hard because upstream `BaseInfinity/gdlc` didn't have the label provisioned, which then aborted the three sibling parallel calls as a fail-fast batch. Stock labels exist on every GitHub repo out of the box, so the skill is now zero-setup for future consumers. Filed findings #1–#4 used `bug` / `enhancement` mappings as a pragmatic workaround in the same session.

## [0.4.0] - 2026-04-19

### Added
- `gdlc-feedback` skill at `.claude/skills/gdlc-feedback/` — structured feedback channel from a consumer case study back to the upstream playbook. Files a well-formed GitHub issue on `BaseInfinity/gdlc` with privacy-gated auto-context and appends a one-row traceability record to `.gdlc/feedback-log.md`. Five canonical feedback types (earned-rule-candidate, playbook-gap, playbook-bug, wizard-bug, methodology-question), each mapped deterministically to a GH label.
- `.gdlc/feedback-log.md` scaffold — append-only traceability index; created empty with a header row by `/gdlc-setup`, migrated in by `/gdlc-update` for pre-v0.4.0 consumers.
- `.gdlc/feedback-drafts/` gitignore entry — transient recovery for cancelled feedback flows (race-check aborts, cancel-mid-prompt).
- SHA-256 race-check discipline in `/gdlc-feedback` — step-1 hashes the `GDLC.md` metadata header, step-5 rehashes and aborts filing on mismatch (lock-free optimistic concurrency against concurrent `/gdlc-update`).
- Privacy allowlist for auto-context — AUTO / CONFIRM / EXCLUDED classification; `Consumer` and `Surfaces` fields require explicit per-field confirm at preview time, defaulting to `<redacted>` if declined. Future metadata fields do not auto-promote.
- `FEEDBACK_SKILL_SPEC.md` at repo root — design spec for the feedback skill (Codex round-2 certified 8/10, 2026-04-19).

### Changed
- `/gdlc-setup` step-4 (skill copy) now installs all four skills in one pass: `gdlc`, `gdlc-setup`, `gdlc-update`, `gdlc-feedback`.
- `/gdlc-setup` step-5 (scaffold) adds idempotent `.gdlc/feedback-log.md` creation and `.gdlc/feedback-drafts/` gitignore append.
- `/gdlc-update` step-5 (drift detection) now covers all four skills in the suite.
- `/gdlc-update` gained step-7.5 — one-time `.gdlc/` migration for pre-v0.4.0 consumers: file creation + gitignore append only; never mutates `GDLC.md` body.
- `CLAUDE_CODE_GDLC_WIZARD.md` managed-files table and both step registries expanded to reflect the full skill suite + `.gdlc/` scaffolds.

### Rationale
With setup + update shipped in v0.3.0, GDLC had an install path and a sync path but no **push-back** path — consumers could install the playbook and stay current, but any earned rules or wizard bugs they discovered decayed locally. The framework-graduation signal (case study #2 producing an earned rule not in case #1's ratchet) was invisible to the playbook author because there was no structured channel to surface it.

The feedback skill closes that loop as the third leg of the skill-triple. Design emphasized the triple's body-immutability invariant (the consumer's `GDLC.md` is never mutated — traceability lives in a separate `.gdlc/feedback-log.md`), delegated credentials entirely to `gh` CLI (no token handling in the skill), and enforced a privacy allowlist so future metadata fields cannot silently leak identifying context upstream. SHA-256 race-check between step-1 (context capture) and step-5 (file) catches the real concurrency case — a `/gdlc-update` running mid-flow — without a filesystem lock.

## [0.3.0] - 2026-04-19

### Added
- `gdlc-setup` skill at `.claude/skills/gdlc-setup/` — installs the `/gdlc` skill into a consumer project, scaffolds a case-study stub, auto-scans for game-project surfaces.
- `gdlc-update` skill at `.claude/skills/gdlc-update/` — pulls latest playbook + skill, shows drift per file, preserves customizations.
- `CLAUDE_CODE_GDLC_WIZARD.md` at repo root — source-of-truth wizard doc with step registry, URLs, managed-files list, and case-study template.
- `CHANGELOG.md` at repo root — version history for downstream `gdlc-update` consumption.

### Changed
- `GDLC.md` graduation criteria (lines 237-245) restructured into "Distribution-readiness" (achieved 2026-04-19) and "Framework graduation" (still pending case study #2). The two milestones were historically conflated; splitting them means the wizard-pair's existence is no longer misread as framework graduation.
- `GDLC.md` header bumped to v0.3; References section points to `/gdlc-setup` and `/gdlc-update` as the install path for case study #2 (PDLC).

### Rationale
Case study #2 (PDLC) was blocked on adoption friction — manual skill copy + case-study stub construction is error-prone, and the errors compound (wrong skill version → wrong persona matrix → wrong cycle selection). Extracting the wizard pair moves install friction to zero, so the case-study-2 signal — does the playbook generalize? — is no longer confounded by install noise.

## [0.2.0] - 2026-04-18

### Added
- 12 new earned rules from codeguesser's v0.11 ship + Playtest #18. Per-rule enumeration (playbook line numbers in parens):
  - Rule #19 — Clock injection is the dual of seed injection. (GDLC.md:183)
  - Rule #20 — Record intent, not state mutation. (GDLC.md:184)
  - Rule #21 — Public-API replay driver beats private-state replay driver. (GDLC.md:185)
  - Rule #22 — URL params (and any user-controlled boundary) are untrusted — `Array.isArray` is not a schema. (GDLC.md:188)
  - Rule #23 — All-or-nothing decoding beats partial-accept at trust boundaries. (GDLC.md:189)
  - Rule #24 — Size caps before CPU work, not after. (GDLC.md:190)
  - Rule #25 — "Silently defaults" is a design smell at trust boundaries. (GDLC.md:191)
  - Rule #26 — Fail-safe decoders over strict decoders at user-controlled boundaries. (GDLC.md:192)
  - Rule #31 — Net-new findings with 0% re-surface signal a *new surface*, not a weak playtest. (GDLC.md:199)
  - Rule #32 — Contract-audit persona + UX-persona in parallel is the right shape for a mixed pipeline+UX ship. (GDLC.md:200)
  - Rule #33 — Ship the foundation, park the UX. (GDLC.md:201)
  - Rule #34 — Ratchet density follows surface-class contract density, not LoC. (GDLC.md:202)
- Rule #28 — Keep a "What's Working" section in the project's GDLC.md parallel to the findings ledger. (GDLC.md:196) — originally listed here as a new rule; it landed via the methodology-block renumber (old rule 20 → new rule 28).
- New section "On determinism foundations" introduced for rules 19-21.
- New section "On trust boundaries" introduced for rules 22-26.
- Methodology rules (old 19-22) renumbered to 27-30; rules 31-34 appended.
- Rules 15-18 received `(Earned P17-XX)` citations back to case study #1.
- Case study #1 counter updated: 18 playtests, 384 regression tests, 32+ project-earned rules.

### Changed
- `GDLC.md` header bumped to v0.2.
- `.claude/skills/gdlc/SKILL.md`: added "Ship the foundation, park the UX" and "Contract-audit + UX-persona parallel" guidance citing playbook rules 32 + 33.

### Fixed
- `.claude/skills/gdlc/SKILL.md:234` stale rule-number cross-reference (`earned rule #20` → `earned rule #28`) — orphaned by the methodology renumber. Caught by Codex round-1 review.

## [0.1.0] - 2026-04-18

### Added
- Initial GDLC playbook extracted from codeguesser case study #1.
- `GDLC.md` playbook (case-study-agnostic) at repo root.
- `.claude/skills/gdlc/SKILL.md` — enforceable skill form of the playbook.
- `README.md` — orientation doc.
- 22 earned rules grouped into: Core philosophy, Scope & targeting, Cycle dispatch, Triangulation & evidence, Stop rules, Earned-rule promotion, Methodology rules.
- Framework-graduation criteria — requires case study #2 to confirm generalization before wizard extraction.
