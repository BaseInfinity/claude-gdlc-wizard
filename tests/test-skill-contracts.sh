#!/bin/bash
# Skill contract tests (GDLC Prove It Gate).
#
# These are not existence tests — existence is the easy part. They verify that
# each skill's self-documented contract is coherent and stays in sync with the
# wizard doc it depends on. When drift appears (step list changes, metadata
# schema changes, label map changes), these fail loud.
#
# Examples of contracts proven here:
# - gdlc-setup promises an 8-step flow and a 5-line metadata block — do the
#   skill + wizard doc agree on both?
# - gdlc-feedback promises stock GitHub labels only (bug/enhancement/question)
#   and a [<type>] title prefix — are all 5 types mapped correctly?
# - Managed files referenced by skills must appear in the wizard doc's
#   managed-files table.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WIZARD_DOC="$REPO_ROOT/CLAUDE_CODE_GDLC_WIZARD.md"
PASSED=0
FAILED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { echo -e "${GREEN}PASS${NC}: $1"; PASSED=$((PASSED + 1)); }
fail() { echo -e "${RED}FAIL${NC}: $1"; FAILED=$((FAILED + 1)); }

echo "=== GDLC Skill Contract Tests ==="
echo ""

# --- Frontmatter (all 4 skills) ---

test_all_skills_have_effort_high() {
    local ok=true
    local missing=""
    for skill in gdlc gdlc-setup gdlc-update gdlc-feedback; do
        local file="$REPO_ROOT/skills/$skill/SKILL.md"
        if ! grep -q "^effort: high$" "$file" 2>/dev/null; then
            ok=false
            missing="$missing $skill"
        fi
    done
    if [ "$ok" = true ]; then
        pass "All 4 skills declare 'effort: high' in frontmatter"
    else
        fail "Skills missing 'effort: high':$missing"
    fi
}

test_all_skills_have_description() {
    local ok=true
    local missing=""
    for skill in gdlc gdlc-setup gdlc-update gdlc-feedback; do
        local file="$REPO_ROOT/skills/$skill/SKILL.md"
        if ! grep -qE "^description: .{40,}$" "$file" 2>/dev/null; then
            ok=false
            missing="$missing $skill"
        fi
    done
    if [ "$ok" = true ]; then
        pass "All 4 skills declare a substantive 'description' (>=40 chars)"
    else
        fail "Skills missing substantive description:$missing"
    fi
}

test_all_skills_have_arghint() {
    # Each skill takes arguments, so each must declare argument-hint
    local ok=true
    local missing=""
    for skill in gdlc gdlc-setup gdlc-update gdlc-feedback; do
        local file="$REPO_ROOT/skills/$skill/SKILL.md"
        if ! grep -q "^argument-hint:" "$file" 2>/dev/null; then
            ok=false
            missing="$missing $skill"
        fi
    done
    if [ "$ok" = true ]; then
        pass "All 4 skills declare 'argument-hint' in frontmatter"
    else
        fail "Skills missing argument-hint:$missing"
    fi
}

# --- gdlc-setup contract ---

test_setup_mandates_wizard_doc_read() {
    local f="$REPO_ROOT/skills/gdlc-setup/SKILL.md"
    if grep -qi "MANDATORY FIRST ACTION" "$f" \
        && grep -q "CLAUDE_CODE_GDLC_WIZARD.md" "$f"; then
        pass "gdlc-setup mandates reading CLAUDE_CODE_GDLC_WIZARD.md first"
    else
        fail "gdlc-setup should declare MANDATORY FIRST ACTION to read wizard doc"
    fi
}

test_setup_has_all_eight_steps() {
    local f="$REPO_ROOT/skills/gdlc-setup/SKILL.md"
    local ok=true
    local missing=""
    for step in "step-0.1" "step-0.2" "step-1" "step-2" "step-3" "step-4" "step-5" "step-6" "step-7"; do
        if ! grep -q "### $step " "$f" 2>/dev/null && ! grep -q "### $step$" "$f" 2>/dev/null; then
            ok=false
            missing="$missing $step"
        fi
    done
    if [ "$ok" = true ]; then
        pass "gdlc-setup declares all 9 execution steps (step-0.1 .. step-7)"
    else
        fail "gdlc-setup missing step headings:$missing"
    fi
}

test_setup_metadata_block_matches_wizard_doc() {
    # The 5 canonical metadata comment lines must (a) appear in both files and
    # (b) match LINE-FOR-LINE. Marker-presence alone is a tautology — Codex
    # round-1 (Phase 1) found drift between `X.Y.Z` and `<VERSION_FROM_CHANGELOG>`
    # that the old marker-only check passed. This is the exact-byte assertion.
    local skill="$REPO_ROOT/skills/gdlc-setup/SKILL.md"
    local doc="$WIZARD_DOC"
    local ok=true
    local missing=""
    # First: marker presence (cheap fail-fast).
    for marker in "GDLC Wizard Version" "GDLC Sibling SHA" "GDLC Setup Date" "GDLC Last Update" "Completed Steps"; do
        grep -q "<!-- $marker" "$skill" 2>/dev/null || { ok=false; missing="$missing '$marker'"; }
        grep -q "<!-- $marker" "$doc"   2>/dev/null || { ok=false; missing="$missing 'wizard-doc:$marker'"; }
    done
    if [ "$ok" = false ]; then
        fail "Metadata block marker(s) missing:$missing"
        return
    fi
    # Then: exact-line block comparison from "<!-- GDLC Wizard Version" through "<!-- Completed Steps".
    local skill_block doc_block
    skill_block="$(awk '/<!-- GDLC Wizard Version/{found=1} found{print; if(/<!-- Completed Steps/){exit}}' "$skill")"
    doc_block="$(awk '/<!-- GDLC Wizard Version/{found=1} found{print; if(/<!-- Completed Steps/){exit}}' "$doc")"
    if [ "$skill_block" = "$doc_block" ]; then
        pass "gdlc-setup's 5-line metadata block matches the wizard doc EXACTLY (line-level)"
    else
        printf "skill block:\n%s\n\ndoc block:\n%s\n" "$skill_block" "$doc_block" >&2
        fail "Metadata block drift (line-level — placeholders differ between skill and wizard doc)"
    fi
}

test_setup_scaffolds_feedback_log() {
    local f="$REPO_ROOT/skills/gdlc-setup/SKILL.md"
    if grep -q ".gdlc/feedback-log.md" "$f"; then
        pass "gdlc-setup scaffolds .gdlc/feedback-log.md"
    else
        fail "gdlc-setup must create .gdlc/feedback-log.md for the feedback loop"
    fi
}

test_setup_never_vendors_playbook() {
    # Rule 3 of the setup skill: never copy ~/gdlc/GDLC.md into the consumer.
    # This must be called out explicitly (so humans editing the skill don't
    # undo it).
    local f="$REPO_ROOT/skills/gdlc-setup/SKILL.md"
    if grep -q "Never copy the playbook" "$f"; then
        pass "gdlc-setup enforces 'never vendor the playbook' rule"
    else
        fail "gdlc-setup must enforce 'never vendor the playbook' (rule #3)"
    fi
}

test_setup_refuses_overwriting_existing_stub() {
    # Rule 2: GDLC.md at project root is sacred — never overwrite.
    local f="$REPO_ROOT/skills/gdlc-setup/SKILL.md"
    if grep -q "Never overwrite an existing case-study" "$f" \
        || grep -q "do NOT overwrite" "$f"; then
        pass "gdlc-setup refuses to overwrite existing case-study GDLC.md"
    else
        fail "gdlc-setup must refuse to overwrite an existing GDLC.md"
    fi
}

# --- gdlc-update contract ---

test_update_references_changelog() {
    local f="$REPO_ROOT/skills/gdlc-update/SKILL.md"
    if grep -qi "CHANGELOG" "$f"; then
        pass "gdlc-update references CHANGELOG (diff source)"
    else
        fail "gdlc-update must read CHANGELOG to compute rule diff"
    fi
}

test_update_uses_npx_check_for_drift() {
    # v0.2.1: drift detection delegates to the local CLI (`npx claude-gdlc-wizard check`)
    # instead of `diff -q ~/gdlc/...`. The CLI compares installed files against
    # repo templates and reports MATCH/CUSTOMIZED/MISSING/DRIFT — same job, no
    # sibling clone required. Apply path uses `npx claude-gdlc-wizard init --force`.
    local f="$REPO_ROOT/skills/gdlc-update/SKILL.md"
    if grep -q "npx claude-gdlc-wizard check\|claude-gdlc-wizard check" "$f"; then
        pass "gdlc-update delegates drift detection to npx claude-gdlc-wizard check"
    else
        fail "gdlc-update must use 'npx claude-gdlc-wizard check' for drift (replaces ~/gdlc/ diff)"
    fi
}

# --- gdlc-feedback contract ---

test_feedback_uses_stock_labels_only() {
    # Stefan's explicit rule: stock labels (bug / enhancement / question) only.
    # No custom feedback:* labels (previous versions of the skill had these
    # and were rejected upstream).
    local f="$REPO_ROOT/skills/gdlc-feedback/SKILL.md"
    local ok=true
    local problems=""
    # Must mention stock labels
    grep -q '\`bug\`' "$f" && grep -q '\`enhancement\`' "$f" && grep -q '\`question\`' "$f" || {
        ok=false; problems="$problems stock-labels-not-declared"
    }
    # Must NOT reference legacy custom labels
    if grep -qE 'feedback:earned-rule|feedback:playbook|feedback:bug|feedback:wizard|feedback:question' "$f"; then
        ok=false; problems="$problems legacy-custom-labels-present"
    fi
    if [ "$ok" = true ]; then
        pass "gdlc-feedback uses stock labels only (bug/enhancement/question)"
    else
        fail "gdlc-feedback label contract broken:$problems"
    fi
}

test_feedback_has_five_canonical_types() {
    local f="$REPO_ROOT/skills/gdlc-feedback/SKILL.md"
    local ok=true
    local missing=""
    for t in "earned-rule-candidate" "playbook-gap" "playbook-bug" "wizard-bug" "methodology-question"; do
        grep -q "$t" "$f" || { ok=false; missing="$missing $t"; }
    done
    if [ "$ok" = true ]; then
        pass "gdlc-feedback documents all 5 canonical type identifiers"
    else
        fail "gdlc-feedback missing canonical types:$missing"
    fi
}

test_feedback_prefixes_title_with_type() {
    local f="$REPO_ROOT/skills/gdlc-feedback/SKILL.md"
    if grep -q '\[<type>\]' "$f" || grep -q "\`\[<type>\]\`" "$f"; then
        pass "gdlc-feedback prefixes issue titles with [<type>]"
    else
        fail "gdlc-feedback must prefix issue titles with [<type>] for filtering"
    fi
}

test_feedback_has_auto_context_allowlist() {
    # Privacy invariant: the skill MUST declare an explicit allowlist for
    # auto-attached context, not a blanket "include everything".
    local f="$REPO_ROOT/skills/gdlc-feedback/SKILL.md"
    if grep -qi "allowlist" "$f" && grep -qi "EXCLUDED" "$f"; then
        pass "gdlc-feedback has an explicit auto-context allowlist with EXCLUDED class"
    else
        fail "gdlc-feedback must declare allowlist + EXCLUDED class for privacy"
    fi
}

test_feedback_never_writes_gdlc_body() {
    local f="$REPO_ROOT/skills/gdlc-feedback/SKILL.md"
    if grep -qi "never" "$f" && grep -qi "GDLC.md" "$f"; then
        # Tighten: must specifically say never writes body
        if grep -qi "never.*GDLC.md" "$f" || grep -qi "never writes\|never touches" "$f"; then
            pass "gdlc-feedback declares it never writes to the consumer GDLC.md body"
        else
            fail "gdlc-feedback must explicitly declare it never writes to GDLC.md body"
        fi
    else
        fail "gdlc-feedback must explicitly declare it never writes to GDLC.md body"
    fi
}

# --- Wizard doc contract ---

test_wizard_doc_has_template_section() {
    if grep -q "^## Case-study GDLC.md template" "$WIZARD_DOC"; then
        pass "Wizard doc has '## Case-study GDLC.md template' section"
    else
        fail "Wizard doc missing '## Case-study GDLC.md template' section"
    fi
}

test_wizard_doc_has_canonical_label_map() {
    if grep -q "Canonical type.*label map\|canonical type.*label map" "$WIZARD_DOC"; then
        pass "Wizard doc declares canonical type → label map"
    else
        fail "Wizard doc should declare the canonical type → label map"
    fi
}

test_wizard_doc_has_setup_step_registry() {
    local f="$WIZARD_DOC"
    if grep -q "^## Setup step registry" "$f"; then
        pass "Wizard doc has Setup step registry section"
    else
        fail "Wizard doc missing Setup step registry section"
    fi
}

test_wizard_doc_has_managed_files_table() {
    if grep -q "^## Managed files" "$WIZARD_DOC"; then
        pass "Wizard doc has Managed files section"
    else
        fail "Wizard doc missing Managed files section"
    fi
}

test_wizard_doc_url_base_is_gdlc_not_sdlc() {
    # Regression: ensure no copy-paste from claude-sdlc-wizard leaked through.
    if grep -q "BaseInfinity/sdlc\|claude-sdlc-wizard" "$WIZARD_DOC"; then
        fail "Wizard doc references sdlc — possible copy-paste leftover"
    else
        pass "Wizard doc has no stale sdlc-wizard references"
    fi
}

# --- v0.2.1 forbidden-pattern tests (skill behavioral migration) ---

test_no_skill_references_legacy_gdlc_path() {
    # ~/gdlc/ was the v0.1.x sibling location. v0.2.1 migrated to project-local
    # paths + WebFetch + `npx claude-gdlc-wizard check`. Skills must not
    # reference ~/gdlc/ at runtime — that path is no longer required to exist.
    local fail_count=0
    local bad=""
    for skill in gdlc gdlc-setup gdlc-update gdlc-feedback; do
        local f="$REPO_ROOT/skills/$skill/SKILL.md"
        local hits
        hits="$(grep -c "~/gdlc/" "$f" 2>/dev/null || true)"
        [ -z "$hits" ] && hits=0
        if [ "$hits" -gt 0 ]; then
            fail_count=$((fail_count + hits))
            bad="$bad $skill($hits)"
        fi
    done
    if [ "$fail_count" -eq 0 ]; then
        pass "No skill references legacy ~/gdlc/ sibling path"
    else
        fail "Skills still contain $fail_count ~/gdlc/ reference(s):$bad — must use project-local or WebFetch"
    fi
}

test_no_skill_references_legacy_repo() {
    # BaseInfinity/gdlc is the deprecated framework repo (Path A consolidated
    # everything into BaseInfinity/claude-gdlc-wizard). Skills must reference
    # the active repo. Pattern: BaseInfinity/gdlc not followed by `-` (so the
    # `gdlc-wizard` substring inside `claude-gdlc-wizard` doesn't false-positive).
    local fail_count=0
    local bad=""
    for skill in gdlc gdlc-setup gdlc-update gdlc-feedback; do
        local f="$REPO_ROOT/skills/$skill/SKILL.md"
        local hits
        hits="$(grep -cE "BaseInfinity/gdlc([^-]|$)" "$f" 2>/dev/null || true)"
        [ -z "$hits" ] && hits=0
        if [ "$hits" -gt 0 ]; then
            fail_count=$((fail_count + hits))
            bad="$bad $skill($hits)"
        fi
    done
    if [ "$fail_count" -eq 0 ]; then
        pass "No skill references deprecated BaseInfinity/gdlc (use BaseInfinity/claude-gdlc-wizard)"
    else
        fail "Skills still contain $fail_count BaseInfinity/gdlc reference(s):$bad — Path A consolidated to claude-gdlc-wizard"
    fi
}

test_update_keep_mine_is_noop() {
    # v0.2.1 finding 1 (Codex round 1): step-7 must explicitly document that
    # "keep mine" decisions are no-ops (preserve CUSTOMIZED state). The previous
    # form ran `init --force` which overwrites unconditionally — that destroyed
    # any keep-mine intent. Step-7 now does per-file apply; this contract test
    # locks in the no-op semantics.
    local f="$REPO_ROOT/skills/gdlc-update/SKILL.md"
    if grep -qi "keep mine.*do nothing\|CUSTOMIZED state persists\|keep mine.*no-op" "$f"; then
        pass "gdlc-update step-7 documents 'keep mine' as a no-op (CUSTOMIZED preserved)"
    else
        fail "gdlc-update step-7 must document that 'keep mine' preserves CUSTOMIZED state (no overwrite)"
    fi
}

test_update_check_only_runs_drift() {
    # v0.2.1 finding 2 (Codex round 1): `check-only` previously short-circuited
    # at step-3 when version matched latest, which violated the argument contract
    # at the bottom of the skill ("run through step-5, print report, stop").
    # The fix: step-3 ALWAYS runs through step-5 in check-only mode, even on
    # version-match — drift detection is the whole point of check-only.
    local f="$REPO_ROOT/skills/gdlc-update/SKILL.md"
    if grep -qi "check-only.*always continue\|always continue through step-5" "$f"; then
        pass "gdlc-update check-only always runs drift detection (no short-circuit on version match)"
    else
        fail "gdlc-update must guarantee check-only runs through step-5 even when version matches latest"
    fi
}

test_setup_step_0_2_delegates_to_cli_check() {
    # v0.2.1 finding 3 (Codex round 1): step-0.2's partial test list missed
    # settings.json + 3 hook files. Delegating to `npx claude-gdlc-wizard check`
    # covers the full surface in one shot and stays in sync with `cli/init.js::FILES`.
    local f="$REPO_ROOT/skills/gdlc-setup/SKILL.md"
    if awk '/### step-0.2/,/### step-1/' "$f" | grep -q "npx claude-gdlc-wizard check"; then
        pass "gdlc-setup step-0.2 delegates verification to npx claude-gdlc-wizard check"
    else
        fail "gdlc-setup step-0.2 must delegate full-surface verification to the CLI"
    fi
}

test_wizard_doc_no_legacy_paths() {
    # The shipped wizard doc should also be free of legacy ~/gdlc/ paths and
    # BaseInfinity/gdlc references after v0.2.1. Historical context belongs in
    # CHANGELOG.md, not the canonical contract doc.
    local fail_count=0
    local bad=""
    local hits1 hits2
    hits1="$(grep -c "~/gdlc/" "$WIZARD_DOC" 2>/dev/null || true)"
    hits2="$(grep -cE "BaseInfinity/gdlc([^-]|$)" "$WIZARD_DOC" 2>/dev/null || true)"
    [ -z "$hits1" ] && hits1=0
    [ -z "$hits2" ] && hits2=0
    if [ "$hits1" -gt 0 ]; then fail_count=$((fail_count + hits1)); bad="$bad ~/gdlc/($hits1)"; fi
    if [ "$hits2" -gt 0 ]; then fail_count=$((fail_count + hits2)); bad="$bad BaseInfinity/gdlc($hits2)"; fi
    if [ "$fail_count" -eq 0 ]; then
        pass "Wizard doc has no legacy ~/gdlc/ or BaseInfinity/gdlc references"
    else
        fail "Wizard doc contains $fail_count legacy reference(s):$bad"
    fi
}

# --- Run ---

test_all_skills_have_effort_high
test_all_skills_have_description
test_all_skills_have_arghint
test_setup_mandates_wizard_doc_read
test_setup_has_all_eight_steps
test_setup_metadata_block_matches_wizard_doc
test_setup_scaffolds_feedback_log
test_setup_never_vendors_playbook
test_setup_refuses_overwriting_existing_stub
test_update_references_changelog
test_update_uses_npx_check_for_drift
test_feedback_uses_stock_labels_only
test_feedback_has_five_canonical_types
test_feedback_prefixes_title_with_type
test_feedback_has_auto_context_allowlist
test_feedback_never_writes_gdlc_body
test_wizard_doc_has_template_section
test_wizard_doc_has_canonical_label_map
test_wizard_doc_has_setup_step_registry
test_wizard_doc_has_managed_files_table
test_wizard_doc_url_base_is_gdlc_not_sdlc
test_no_skill_references_legacy_gdlc_path
test_no_skill_references_legacy_repo
test_wizard_doc_no_legacy_paths
test_update_keep_mine_is_noop
test_update_check_only_runs_drift
test_setup_step_0_2_delegates_to_cli_check

echo ""
echo "=== Results ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [ $FAILED -gt 0 ]; then
    exit 1
fi
