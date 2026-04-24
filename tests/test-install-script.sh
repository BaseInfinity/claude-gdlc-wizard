#!/bin/bash
# Test install.sh — curl | bash installer for claude-gdlc-wizard
# Step-1 scope: structural tests only. Live `cat install.sh | bash` tests are
# gated behind CLAUDE_GDLC_WIZARD_NPM_PUBLISHED=1 because claude-gdlc-wizard
# is not on npm yet — piping would always fail. Once published, flip the gate.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_SCRIPT="$REPO_ROOT/install.sh"

PASSED=0
FAILED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { echo -e "${GREEN}PASS${NC}: $1"; PASSED=$((PASSED + 1)); }
fail() { echo -e "${RED}FAIL${NC}: $1"; FAILED=$((FAILED + 1)); }

if [ ! -f "$INSTALL_SCRIPT" ]; then
    echo -e "${RED}FAIL${NC}: install.sh does not exist — all tests skipped"
    echo ""
    echo "=== Results ==="
    echo "Passed: 0"
    echo "Failed: 1"
    exit 1
fi

# --- Structural tests ---

test_script_exists() {
    if [ -f "$INSTALL_SCRIPT" ]; then
        pass "install.sh exists"
    else
        fail "install.sh does not exist"
    fi
}

test_script_is_executable() {
    if [ -x "$INSTALL_SCRIPT" ]; then
        pass "install.sh is executable"
    else
        fail "install.sh is not executable"
    fi
}

test_has_bash_shebang() {
    local first_line
    first_line=$(head -1 "$INSTALL_SCRIPT")
    if echo "$first_line" | grep -q '#!/usr/bin/env bash\|#!/bin/bash'; then
        pass "install.sh has bash shebang"
    else
        fail "install.sh shebang: got '$first_line'"
    fi
}

test_shebang_no_escaped_bang() {
    # Regression: heredoc-created scripts can end up with #\! instead of #!,
    # which yields 'exec format error' when piped from curl.
    local first_bytes
    first_bytes=$(xxd -l 2 -p "$INSTALL_SCRIPT")
    if [ "$first_bytes" = "2321" ]; then
        pass "Shebang is literal #! (first 2 bytes = 0x2321)"
    else
        fail "Shebang bytes are '$first_bytes', expected '2321'"
    fi
}

test_has_strict_mode() {
    if grep -q 'set -euo pipefail' "$INSTALL_SCRIPT"; then
        pass "install.sh uses 'set -euo pipefail'"
    else
        fail "install.sh missing 'set -euo pipefail'"
    fi
}

test_has_download_guard() {
    # Script body must be wrapped in { } to prevent partial execution when a
    # curl pipe is cut mid-transfer.
    local body_start body_end
    body_start=$(grep -n '^{' "$INSTALL_SCRIPT" | head -1 | cut -d: -f1)
    body_end=$(tail -1 "$INSTALL_SCRIPT")
    if [ -n "$body_start" ] && echo "$body_end" | grep -q '^}'; then
        pass "install.sh has { } download guard"
    else
        fail "install.sh missing { } download guard"
    fi
}

test_checks_node() {
    if grep -q 'command -v node' "$INSTALL_SCRIPT"; then
        pass "install.sh checks for Node.js"
    else
        fail "install.sh does not check for Node.js"
    fi
}

test_checks_node_version() {
    if grep -q '18' "$INSTALL_SCRIPT" && grep -qE 'node -v|node --version' "$INSTALL_SCRIPT"; then
        pass "install.sh checks Node.js >= 18"
    else
        fail "install.sh does not check Node.js >= 18"
    fi
}

test_checks_npm() {
    if grep -q 'command -v npm' "$INSTALL_SCRIPT" || grep -q 'command -v npx' "$INSTALL_SCRIPT"; then
        pass "install.sh checks for npm/npx"
    else
        fail "install.sh does not check for npm/npx"
    fi
}

test_handles_global_flag() {
    if grep -q '\-\-global' "$INSTALL_SCRIPT"; then
        pass "install.sh handles --global flag"
    else
        fail "install.sh does not handle --global flag"
    fi
}

test_handles_help_flag() {
    local output
    output=$(bash "$INSTALL_SCRIPT" --help 2>&1) || true
    if echo "$output" | grep -qi 'usage\|install\|gdlc'; then
        pass "install.sh --help shows usage info"
    else
        fail "install.sh --help did not show usage info"
    fi
}

test_no_hardcoded_tmp() {
    if grep -q '"/tmp' "$INSTALL_SCRIPT"; then
        fail "install.sh has hardcoded /tmp path (use \$TMPDIR)"
    else
        pass "install.sh has no hardcoded /tmp paths"
    fi
}

test_colors_conditional_on_terminal() {
    if grep -qE '\-t 1|tput' "$INSTALL_SCRIPT"; then
        pass "install.sh conditionalizes colors on a terminal"
    else
        fail "install.sh does not guard color codes with '-t 1' or tput"
    fi
}

test_references_correct_package() {
    if grep -q 'claude-gdlc-wizard' "$INSTALL_SCRIPT"; then
        pass "install.sh references 'claude-gdlc-wizard' npm package"
    else
        fail "install.sh should reference 'claude-gdlc-wizard'"
    fi
}

test_does_not_reference_sdlc_package() {
    # Guard against a copy-paste leftover from the sdlc-wizard template.
    if grep -q 'agentic-sdlc-wizard\|claude-sdlc-wizard' "$INSTALL_SCRIPT"; then
        fail "install.sh still references an sdlc package name (copy-paste leftover)"
    else
        pass "install.sh has no stale sdlc-wizard package references"
    fi
}

test_has_error_function() {
    if grep -q 'error()' "$INSTALL_SCRIPT"; then
        pass "install.sh has error() helper"
    else
        fail "install.sh missing error() helper"
    fi
}

test_rejects_unknown_args() {
    local output
    output=$(bash "$INSTALL_SCRIPT" --foo 2>&1) || true
    if echo "$output" | grep -qi 'unknown option'; then
        pass "install.sh rejects unknown arguments"
    else
        fail "install.sh does not reject unknown arguments (got: '$output')"
    fi
}

test_npx_auto_confirm() {
    # Regression: npx without -y hangs when piped from curl (stdin exhausted).
    if grep -q 'npx -y' "$INSTALL_SCRIPT"; then
        pass "install.sh uses 'npx -y' for auto-confirm"
    else
        fail "install.sh must use 'npx -y' (piped stdin cannot answer prompts)"
    fi
}

# --- Live tests (gated — npm package not published yet) ---

run_live_tests=0
if [ "${CLAUDE_GDLC_WIZARD_NPM_PUBLISHED:-0}" = "1" ]; then
    run_live_tests=1
fi

make_temp() {
    local d
    d=$(mktemp -d "${TMPDIR:-/tmp}/gdlc-install-test-XXXXXX")
    echo "$d"
}

test_piped_install_creates_files() {
    local dir
    dir=$(make_temp)
    (cd "$dir" && cat "$INSTALL_SCRIPT" | bash) >/dev/null 2>&1
    local expected_files=(
        ".claude/skills/gdlc/SKILL.md"
        ".claude/skills/gdlc-setup/SKILL.md"
        ".claude/skills/gdlc-update/SKILL.md"
        ".claude/skills/gdlc-feedback/SKILL.md"
        "CLAUDE_CODE_GDLC_WIZARD.md"
    )
    local missing=0
    for f in "${expected_files[@]}"; do
        [ -f "$dir/$f" ] || missing=$((missing + 1))
    done
    if [ "$missing" -eq 0 ]; then
        pass "Piped install (curl|bash) creates all 5 wizard files"
    else
        fail "Piped install missing $missing of 5 expected files"
    fi
    rm -rf "$dir"
}

test_piped_help_works() {
    local output
    output=$(cat "$INSTALL_SCRIPT" | bash -s -- --help 2>&1) || true
    if echo "$output" | grep -qi 'usage\|install\|gdlc'; then
        pass "Piped --help works (cat script | bash -s -- --help)"
    else
        fail "Piped --help did not show usage"
    fi
}

# --- Run ---

test_script_exists
test_script_is_executable
test_has_bash_shebang
test_shebang_no_escaped_bang
test_has_strict_mode
test_has_download_guard
test_checks_node
test_checks_node_version
test_checks_npm
test_handles_global_flag
test_handles_help_flag
test_no_hardcoded_tmp
test_colors_conditional_on_terminal
test_references_correct_package
test_does_not_reference_sdlc_package
test_has_error_function
test_rejects_unknown_args
test_npx_auto_confirm

if [ "$run_live_tests" = "1" ]; then
    echo ""
    echo "--- Live install tests (npm-gated) ---"
    test_piped_install_creates_files
    test_piped_help_works
else
    echo ""
    echo "Live install tests skipped: set CLAUDE_GDLC_WIZARD_NPM_PUBLISHED=1 once the npm package is published."
fi

echo ""
echo "=== Results ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [ $FAILED -gt 0 ]; then
    exit 1
fi
