**Findings**

1. **P1 — Legacy hook migration is not actually handled.**  
Evidence: [cli/init.js](/Users/stefanayala/claude-gdlc-wizard/cli/init.js:31) derives wizard hook markers only from current `FILES`, so legacy `instructions-loaded-check.sh` is not recognized:
> `const WIZARD_HOOK_MARKERS = FILES ... .map((f) => path.basename(f.src));`

[cli/init.js](/Users/stefanayala/claude-gdlc-wizard/cli/init.js:63) then appends the new hook instead of replacing the legacy one:
> `if (existingIdx === -1) { existing.hooks[event].push(templateEntry); }`

Simulation of a v0.2.1-style install followed by `init --force` left both:
```text
_find-gdlc-root.sh
gdlc-instructions-loaded-check.sh
gdlc-prompt-check.sh
instructions-loaded-check.sh
"$CLAUDE_PROJECT_DIR"/.claude/hooks/instructions-loaded-check.sh
"$CLAUDE_PROJECT_DIR"/.claude/hooks/gdlc-instructions-loaded-check.sh
```
[skills/gdlc-update/SKILL.md](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-update/SKILL.md:139) has the same blind spot because it only replaces entries referencing `gdlc-prompt-check.sh` or `gdlc-instructions-loaded-check.sh`. [CHANGELOG.md](/Users/stefanayala/claude-gdlc-wizard/CHANGELOG.md:25) claims the opposite:
> `legacy instructions-loaded-check.sh will be removed by init --force (drift detection flags it as DRIFT)`

Certify condition: add an explicit legacy-hook migration path: remove `.claude/hooks/instructions-loaded-check.sh`, replace legacy settings entries instead of appending, make `check` flag legacy hook drift, update `/gdlc-update`, and add a CLI regression seeded with v0.2.1 state.

2. **P2 — Empty-stub state is internally contradictory.**  
Evidence: [skills/gdlc-setup/SKILL.md](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-setup/SKILL.md:81) says:
> `Empty stub ... Continue`

But [skills/gdlc-setup/SKILL.md](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-setup/SKILL.md:179) later says:
> `Skip ... if GDLC.md at project root already exists`

A zero-byte `GDLC.md` therefore “continues” into a step that skips writing the case-study body.  
Certify condition: make step-5 explicitly treat zero-byte `GDLC.md` as safe to populate, or remove the empty-stub continue branch and define a different recovery path. Add a contract test for zero-byte `GDLC.md`.

3. **P2 — Step-5.5 idempotency is shallow for non-canonical headers.**  
Evidence: [skills/gdlc-setup/SKILL.md](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-setup/SKILL.md:212) only names the exact canonical header:
> `If ## Related playbooks already exists in GDLC.md, leave it alone`

The test also only checks the canonical casing pattern at [tests/test-skill-contracts.sh](/Users/stefanayala/claude-gdlc-wizard/tests/test-skill-contracts.sh:524):
> `grep -cE '## Related [Pp]laybooks'`

This does not cover `## related playbooks` or `##  Related playbooks`.  
Certify condition: specify and test a case-insensitive, whitespace-tolerant header check, e.g. `^##[[:space:]]+related[[:space:]]+playbooks[[:space:]]*$`.

4. **P2 — CHANGELOG assertion counts are wrong.**  
Evidence: [CHANGELOG.md](/Users/stefanayala/claude-gdlc-wizard/CHANGELOG.md:22) says:
> `7 new contract tests ... (27 → 34 assertions; whole-suite total 102 → 110)`

Actual test output:
```text
tests/test-skill-contracts.sh: Passed: 35, Failed: 0
suite total: 110 passed, 0 failed
```
The diff adds 8 new skill-contract test functions, not 7.  
Certify condition: update the changelog to `8 new contract tests (27 → 35; total 102 → 110)` or remove one assertion if 34 was intended.

5. **P2 — Required `git log --follow` verification on the new hook path currently fails.**  
Evidence:
```text
git log --follow --oneline -- hooks/gdlc-instructions-loaded-check.sh
NO COMMITS
```
The staged diff is a clean rename:
```text
rename hooks/{instructions-loaded-check.sh => gdlc-instructions-loaded-check.sh} (100%)
```
But the requested verification cannot pass until the rename is committed.  
Certify condition: commit the rename and re-run `git log --follow -- hooks/gdlc-instructions-loaded-check.sh`; it must surface the pre-rename commits.

6. **P2 — A stale legacy basename remains in a shipped hook comment.**  
Evidence: [hooks/_find-gdlc-root.sh](/Users/stefanayala/claude-gdlc-wizard/hooks/_find-gdlc-root.sh:3):
> `# Sourced by gdlc-prompt-check.sh and instructions-loaded-check.sh.`

Certify condition: update the comment to `gdlc-instructions-loaded-check.sh`.

**Verification Notes**

Passes: step-0.5 exists before auto-scan/write ordering (`grep '^### step-'` shows step-0.5 at line 65 before step-1 at 87 and step-3 at 126); jq dependency detection ignores script-only `vitest-runner`; `hooks/hooks.json` and `cli/templates/settings.json` command fields reference `gdlc-instructions-loaded-check.sh`; namespace test iterates all `hooks/*.sh`; version parity is `0.2.2` across package, plugin, marketplace, and changelog; v0.2.1 forbidden grep returned zero matches.

Full suite run after `git checkout -- hooks/` passed:
```text
cli=24, hooks=13, install-script=18, plugin=20, skill-contracts=35
total=110 passed, 0 failed
```

Score: 5/10. NOT CERTIFIED.