**Findings**

1. **P1: `/gdlc-update` does not actually apply updates selectively.**  
   Evidence: [skills/gdlc-update/SKILL.md](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-update/SKILL.md:115) promises per-file decisions including `keep mine`, but step 7 runs `npx claude-gdlc-wizard init --force` at [line 131](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-update/SKILL.md:131). The CLI turns every existing file into `OVERWRITE` when `force` is true in [cli/init.js](/Users/stefanayala/claude-gdlc-wizard/cli/init.js:106), then copies source over dest at [line 135](/Users/stefanayala/claude-gdlc-wizard/cli/init.js:135). Test evidence confirms this behavior: `PASS: init --force overwrites existing files`.  
   Certify condition: implement or document a truly selective apply path that preserves files the user chose to keep or merge manually, and add a regression test for “CUSTOMIZED + keep mine remains CUSTOMIZED after apply.”

2. **P2: `/gdlc-update check-only` can short-circuit before drift detection.**  
   Evidence: [skills/gdlc-update/SKILL.md](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-update/SKILL.md:59) says if installed version matches latest, “stop. Nothing else runs,” before [line 61](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-update/SKILL.md:61) says `check-only` continues through step 5. That contradicts the argument contract at [line 215](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-update/SKILL.md:215).  
   Certify condition: make `check-only` always run drift detection, even when metadata version is current.

3. **P2: `/gdlc-setup` step 0.2 verifies only part of the CLI-installed surface.**  
   Evidence: [skills/gdlc-setup/SKILL.md](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-setup/SKILL.md:41) checks only wizard doc + 4 skills. `cli/init.js::FILES` installs settings + 3 hook files + 4 skills at [cli/init.js](/Users/stefanayala/claude-gdlc-wizard/cli/init.js:20), and the wizard doc is added at [line 111](/Users/stefanayala/claude-gdlc-wizard/cli/init.js:111).  
   Certify condition: step 0.2 should verify the full install surface or delegate to `npx claude-gdlc-wizard check`.

4. **P2: `gdlc-feedback` still contains stale sibling/setup install wording.**  
   Evidence: [skills/gdlc-feedback/SKILL.md](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-feedback/SKILL.md:186) says the skill is created by `/gdlc-setup` and “Installed verbatim from sibling,” but v0.2.1 says skills are installed by the CLI, not setup, in [skills/gdlc-setup/SKILL.md](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-setup/SKILL.md:26).  
   Certify condition: update that managed-files row to project-local CLI install wording.

5. **P2: supporting docs still have stale assertion counts.**  
   Evidence: [TESTING.md](/Users/stefanayala/claude-gdlc-wizard/TESTING.md:44) and [TESTING.md](/Users/stefanayala/claude-gdlc-wizard/TESTING.md:57) still say 96 assertions; [ARCHITECTURE.md](/Users/stefanayala/claude-gdlc-wizard/ARCHITECTURE.md:71) still says skill-contracts has 21 assertions and [line 118](/Users/stefanayala/claude-gdlc-wizard/ARCHITECTURE.md:118) says 96 total. Actual test output: cli=24, hooks=13, install-script=18, plugin=20, skill-contracts=24, total=99 passed.  
   Certify condition: update stale counts to 99 total and 24 skill-contract assertions.

**Verification Evidence**

- Legacy scope grep: `grep -nE "~/gdlc/|BaseInfinity/gdlc([^-]|$)" skills/... CLAUDE_CODE_GDLC_WIZARD.md` returned `NO_MATCH`.
- Feedback repo commands all target the new repo: `gh repo view`, `gh issue create`, and `gh issue view` use `BaseInfinity/claude-gdlc-wizard` at [skills/gdlc-feedback/SKILL.md](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-feedback/SKILL.md:104), [line 146](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-feedback/SKILL.md:146), and [line 158](/Users/stefanayala/claude-gdlc-wizard/skills/gdlc-feedback/SKILL.md:158).
- Regex check: active repo `BaseInfinity/claude-gdlc-wizard` matched `0`; deprecated `BaseInfinity/gdlc/issues` matched `1`.
- Raw playbook URL resolved: `curl` returned `HTTP 200 bytes 26740` for `https://raw.githubusercontent.com/BaseInfinity/claude-gdlc-wizard/main/GDLC.md`.
- Version parity: package, plugin, marketplace, and top changelog all read `0.2.1`.
- `npm pack --dry-run --json` includes `cli/`, `skills/`, `hooks/`, `.claude-plugin/`, `CLAUDE_CODE_GDLC_WIZARD.md`, `CHANGELOG.md`, `README.md`; `GDLC.md` is not shipped.
- Full suites passed: 99 passed, 0 failed.
- Path A recheck passed: `GDLC.md`, `ROADMAP.md`, `FEEDBACK_SKILL_SPEC.md`, and `PLAYBOOK_CHANGELOG.md` exist at repo root; no legacy runtime references remain in skills + wizard doc.

score: 7/10, NOT CERTIFIED.