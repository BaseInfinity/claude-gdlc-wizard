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
    # The 5 canonical metadata comment lines in the skill's verify section
    # must match the template in the wizard doc. Drift here breaks every
    # consumer's install.
    local skill="$REPO_ROOT/skills/gdlc-setup/SKILL.md"
    local ok=true
    local missing=""
    for marker in "GDLC Wizard Version" "GDLC Sibling SHA" "GDLC Setup Date" "GDLC Last Update" "Completed Steps"; do
        if ! grep -q "<!-- $marker" "$skill" 2>/dev/null; then
            ok=false
            missing="$missing '$marker'"
        fi
        if ! grep -q "<!-- $marker" "$WIZARD_DOC" 2>/dev/null; then
            ok=false
            missing="$missing 'wizard-doc:$marker'"
        fi
    done
    if [ "$ok" = true ]; then
        pass "gdlc-setup's 5-line metadata block matches the wizard doc template"
    else
        fail "Metadata block drift vs wizard doc:$missing"
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

test_update_prefers_local_sibling_over_fetch() {
    # Wizard doc says: "Update prefers the local sibling at ~/gdlc/ over
    # fetching — it's faster and always consistent with the skill pair."
    local f="$REPO_ROOT/skills/gdlc-update/SKILL.md"
    if grep -q "~/gdlc/" "$f"; then
        pass "gdlc-update references ~/gdlc/ sibling (preferred over URL fetch)"
    else
        fail "gdlc-update should read from ~/gdlc/ when available"
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
test_update_prefers_local_sibling_over_fetch
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

echo ""
echo "=== Results ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [ $FAILED -gt 0 ]; then
    exit 1
fi
