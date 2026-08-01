#!/bin/bash
# Hook behavior tests — run the real hook scripts and verify output.
# Covers: gdlc-prompt-check, _find-gdlc-root.

set -e

# Portable locale: an inherited broken LC_ALL makes bash emit setlocale
# warnings on stderr, which tests capturing hook/CLI output would misread.
export LC_ALL=C LANG=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK_DIR="$REPO_ROOT/hooks"
PASSED=0
FAILED=0

# Isolate HOME so _find-gdlc-root doesn't halt the walk-up at the real $HOME.
FAKE_HOME="$(mktemp -d "${TMPDIR:-/tmp}/gdlc-hooks-home-XXXXXX")"
export HOME="$FAKE_HOME"
trap 'rm -rf "$FAKE_HOME"' EXIT

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { echo -e "${GREEN}PASS${NC}: $1"; PASSED=$((PASSED + 1)); }
fail() { echo -e "${RED}FAIL${NC}: $1"; FAILED=$((FAILED + 1)); }

make_project_with_gdlc() {
    local d
    d=$(mktemp -d "${TMPDIR:-/tmp}/gdlc-hooks-proj-XXXXXX")
    echo "# GDLC Case Study — test" > "$d/GDLC.md"
    echo "$d"
}

make_project_without_gdlc() {
    local d
    d=$(mktemp -d "${TMPDIR:-/tmp}/gdlc-hooks-empty-XXXXXX")
    echo "$d"
}

# Fresh-install state: the CLI installed the wizard doc, but gdlc-setup
# hasn't run yet so GDLC.md doesn't exist.
make_project_with_wizard_doc_only() {
    local d
    d=$(mktemp -d "${TMPDIR:-/tmp}/gdlc-hooks-wizard-XXXXXX")
    echo "# Claude Code GDLC Wizard — test" > "$d/CLAUDE_CODE_GDLC_WIZARD.md"
    echo "$d"
}

echo "=== Hook Behavior Tests ==="
echo ""

# --- _find-gdlc-root helper ---

test_find_gdlc_root_finds_project() {
    local d
    d=$(make_project_with_gdlc)
    local result
    result=$(cd "$d" && bash -c "source '$HOOK_DIR/_find-gdlc-root.sh' && find_gdlc_root && echo \"\$GDLC_ROOT\"")
    # macOS mktemp prefixes with /private/ but realpath(.) is canonical.
    if [ -n "$result" ] && [ -f "$result/GDLC.md" ]; then
        pass "_find-gdlc-root finds GDLC.md in project root"
    else
        fail "_find-gdlc-root should find GDLC.md (got: '$result')"
    fi
    rm -rf "$d"
}

test_find_gdlc_root_walks_up() {
    local d
    d=$(make_project_with_gdlc)
    mkdir -p "$d/sub/deep"
    local result
    result=$(cd "$d/sub/deep" && bash -c "source '$HOOK_DIR/_find-gdlc-root.sh' && find_gdlc_root && echo \"\$GDLC_ROOT\"")
    if [ -n "$result" ] && [ -f "$result/GDLC.md" ]; then
        pass "_find-gdlc-root walks up from subdir to find GDLC.md"
    else
        fail "_find-gdlc-root should walk up from subdir"
    fi
    rm -rf "$d"
}

test_find_gdlc_root_finds_wizard_doc_marker() {
    # Fresh install: CLI put down CLAUDE_CODE_GDLC_WIZARD.md but gdlc-setup
    # hasn't created GDLC.md yet. The root finder must still anchor here,
    # otherwise the setup nudge below can never fire (issue #14 finding).
    local d
    d=$(make_project_with_wizard_doc_only)
    local result
    result=$(cd "$d" && bash -c "source '$HOOK_DIR/_find-gdlc-root.sh' && find_gdlc_root && echo \"\$GDLC_ROOT\"") || true
    if [ -n "$result" ] && [ -f "$result/CLAUDE_CODE_GDLC_WIZARD.md" ]; then
        pass "_find-gdlc-root anchors on CLAUDE_CODE_GDLC_WIZARD.md when GDLC.md absent"
    else
        fail "_find-gdlc-root should anchor on the wizard doc (got: '$result')"
    fi
    rm -rf "$d"
}

test_find_gdlc_root_returns_nonzero_when_absent() {
    local d
    d=$(make_project_without_gdlc)
    local exit_code=0
    (cd "$d" && bash -c "source '$HOOK_DIR/_find-gdlc-root.sh' && find_gdlc_root") || exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        pass "_find-gdlc-root returns non-zero when GDLC.md absent"
    else
        fail "_find-gdlc-root should return non-zero when no GDLC.md up the tree"
    fi
    rm -rf "$d"
}

# --- gdlc-prompt-check ---

test_prompt_check_silent_outside_project() {
    local d
    d=$(make_project_without_gdlc)
    local output
    output=$(cd "$d" && bash "$HOOK_DIR/gdlc-prompt-check.sh" 2>&1)
    if [ -z "$output" ]; then
        pass "gdlc-prompt-check is silent when no GDLC project found"
    else
        fail "gdlc-prompt-check should stay silent outside a GDLC project (got output)"
    fi
    rm -rf "$d"
}

test_prompt_check_baseline_when_gdlc_present() {
    local d
    d=$(make_project_with_gdlc)
    local output
    output=$(cd "$d" && bash "$HOOK_DIR/gdlc-prompt-check.sh" 2>&1)
    if echo "$output" | grep -q "GDLC BASELINE"; then
        pass "gdlc-prompt-check prints GDLC BASELINE when GDLC.md present"
    else
        fail "gdlc-prompt-check should print BASELINE (got: $output)"
    fi
    rm -rf "$d"
}

test_prompt_check_setup_notice_when_empty_gdlc() {
    # Empty GDLC.md (zero-byte) means partial state — nudge user to setup.
    local d
    d=$(make_project_without_gdlc)
    touch "$d/GDLC.md"
    local output
    output=$(cd "$d" && bash "$HOOK_DIR/gdlc-prompt-check.sh" 2>&1)
    if echo "$output" | grep -q "SETUP NOT COMPLETE" && echo "$output" | grep -q "gdlc-setup"; then
        pass "gdlc-prompt-check prints SETUP NOT COMPLETE and points to gdlc-setup when GDLC.md empty"
    else
        fail "gdlc-prompt-check should nudge to gdlc-setup when GDLC.md is empty"
    fi
    rm -rf "$d"
}

test_prompt_check_setup_notice_when_wizard_doc_only() {
    # Fresh-install state (wizard installed, setup never run) MUST produce the
    # setup nudge — this was silently dead before issue #14.
    local d
    d=$(make_project_with_wizard_doc_only)
    local output
    output=$(cd "$d" && bash "$HOOK_DIR/gdlc-prompt-check.sh" 2>&1)
    if echo "$output" | grep -q "SETUP NOT COMPLETE" && echo "$output" | grep -q "gdlc-setup"; then
        pass "gdlc-prompt-check nudges to gdlc-setup on fresh install (wizard doc, no GDLC.md)"
    else
        fail "gdlc-prompt-check should emit SETUP NOT COMPLETE on fresh install (got: $output)"
    fi
    rm -rf "$d"
}

test_prompt_check_no_legacy_sibling_path() {
    # Path A removed the ~/gdlc/ sibling clone — consumers never have it, so
    # hook output must not point there. Scan the scripts, not just one string.
    if grep -q '~/gdlc' "$HOOK_DIR"/*.sh; then
        fail "hook scripts reference legacy ~/gdlc/ sibling path (pre-Path-A)"
    else
        pass "hook scripts contain no legacy ~/gdlc/ sibling references"
    fi
}

test_prompt_check_dual_install_warning() {
    # Dual-channel install (CLI skills + plugin) must be surfaced on the
    # UserPromptSubmit hook — InstructionsLoaded stdout is discarded by
    # Claude Code, so a warning there never reaches anyone.
    local d
    d=$(make_project_with_gdlc)
    mkdir -p "$d/.claude/skills/gdlc-update"
    mkdir -p "$HOME/.claude/plugins-local/gdlc-wizard-wrap"
    local output
    output=$(cd "$d" && bash "$HOOK_DIR/gdlc-prompt-check.sh" 2>&1)
    rm -rf "$HOME/.claude/plugins-local/gdlc-wizard-wrap"
    local clean_output
    clean_output=$(cd "$d" && bash "$HOOK_DIR/gdlc-prompt-check.sh" 2>&1)
    if echo "$output" | grep -q "dual-install" \
        && ! echo "$clean_output" | grep -q "dual-install"; then
        pass "gdlc-prompt-check warns on dual-install and stays quiet when single-channel"
    else
        fail "gdlc-prompt-check should emit dual-install warning only when both channels present"
    fi
    rm -rf "$d"
}

test_prompt_check_mentions_three_cycle_types() {
    local d
    d=$(make_project_with_gdlc)
    local output
    output=$(cd "$d" && bash "$HOOK_DIR/gdlc-prompt-check.sh" 2>&1)
    local ok=true
    echo "$output" | grep -q "gameplay-matrix" || ok=false
    echo "$output" | grep -q "art-craft-review" || ok=false
    echo "$output" | grep -q "pipeline-contract-audit" || ok=false
    if [ "$ok" = true ]; then
        pass "gdlc-prompt-check lists all 3 cycle types (gameplay/art/pipeline)"
    else
        fail "gdlc-prompt-check baseline should list all 3 cycle types"
    fi
    rm -rf "$d"
}

test_prompt_check_always_exits_zero() {
    # Hook MUST not block the prompt flow — should always exit 0.
    for scenario in "make_project_with_gdlc" "make_project_without_gdlc" "make_project_with_wizard_doc_only"; do
        local d
        d=$($scenario)
        local exit_code=0
        (cd "$d" && bash "$HOOK_DIR/gdlc-prompt-check.sh" >/dev/null 2>&1) || exit_code=$?
        if [ "$exit_code" -ne 0 ]; then
            fail "gdlc-prompt-check should exit 0 under '$scenario' (got $exit_code)"
            rm -rf "$d"
            return
        fi
        rm -rf "$d"
    done
    pass "gdlc-prompt-check always exits 0 (non-blocking)"
}

# --- Workflow YAML sanity ---

test_ci_workflow_valid_yaml() {
    local wf="$REPO_ROOT/.github/workflows/ci.yml"
    [ -f "$wf" ] || { fail ".github/workflows/ci.yml missing"; return; }
    if python3 -c "import yaml; yaml.safe_load(open('$wf'))" 2>/dev/null; then
        pass ".github/workflows/ci.yml is valid YAML"
    else
        # Fallback — Python's yaml may not be installed; shell-only check of
        # top-level 'name:' / 'jobs:'
        if grep -qE '^(name|jobs):' "$wf"; then
            pass ".github/workflows/ci.yml has top-level name + jobs (PyYAML unavailable)"
        else
            fail ".github/workflows/ci.yml appears malformed"
        fi
    fi
}

test_ci_workflow_runs_test_suite() {
    local wf="$REPO_ROOT/.github/workflows/ci.yml"
    [ -f "$wf" ] || { fail ".github/workflows/ci.yml missing"; return; }
    if grep -q 'tests/\*\.sh' "$wf" || grep -q 'bash "$t"' "$wf"; then
        pass ".github/workflows/ci.yml runs the tests/*.sh suite"
    else
        fail ".github/workflows/ci.yml should iterate tests/*.sh"
    fi
}

# --- Run ---

test_find_gdlc_root_finds_project
test_find_gdlc_root_walks_up
test_find_gdlc_root_finds_wizard_doc_marker
test_find_gdlc_root_returns_nonzero_when_absent
test_prompt_check_silent_outside_project
test_prompt_check_baseline_when_gdlc_present
test_prompt_check_setup_notice_when_empty_gdlc
test_prompt_check_setup_notice_when_wizard_doc_only
test_prompt_check_no_legacy_sibling_path
test_prompt_check_dual_install_warning
test_prompt_check_mentions_three_cycle_types
test_prompt_check_always_exits_zero
test_ci_workflow_valid_yaml
test_ci_workflow_runs_test_suite

echo ""
echo "=== Results ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [ $FAILED -gt 0 ]; then
    exit 1
fi
