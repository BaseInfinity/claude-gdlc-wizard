CERTIFIED. Both round-2 findings satisfy their original certify conditions.

### Targeted dispositions

1. **Finding 1 — FIXED**

- The [ordinary-init fixture](/Users/stefanayala/claude-gdlc-wizard/tests/test-cli.sh:642) covers unconditional migration, exact event-key deletion, legacy-file removal, and sibling user-group preservation.
- The [force fixture](/Users/stefanayala/claude-gdlc-wizard/tests/test-cli.sh:703) verifies exact template-command replacement while preserving the separate user group and matcher.
- Reapplied mutations:
  - Disable non-force merging: expected failure, CLI 30/1.
  - Discard sibling groups during force replacement: expected failure, CLI 30/1.
- Both mutations were restored exactly; clean CLI suite: 31/0.

2. **Finding 2 — FIXED**

- [`guarded_doc_content()`](/Users/stefanayala/claude-gdlc-wizard/tests/test-skill-contracts.sh:673) excludes only the marked disabled-wrap section and resumes at the next `##` heading.
- `SDLC.md` appears in both [topology guard loops](/Users/stefanayala/claude-gdlc-wizard/tests/test-skill-contracts.sh:695).
- Appending `10 rows` outside the exemption failed 41/1.
- Inserting it inside the exemption remained green at 42/0.
- Mutation restored exactly; clean contracts suite: 42/0.

### Regression verification

- Full documented suite: **126/0** — 31/14/18/21/42.
- Event parity: `UserPromptSubmit` only; plugin suite 21/0.
- Version parity: 0.4.0 across package, plugin, and marketplace manifests.
- Reviewer contracts: exactly two GPT-5.6 Sol rows; no GPT-5.5/GPT-5.4.
- Counts and CHANGELOG test identifiers verified.
- `cli/init.js` provenance and mutation restoration verified; current SHA-256 is `f7a5a711…e4d4e`.
- `git diff --check` passed, and final status matches the legitimate pre-review release state. Excluded untracked paths were untouched.
- No new P0 findings.

### Notes for next review

The pre-script inherited-locale warning remains noisy but non-blocking, as previously documented.

Score: 10/10 — CERTIFIED