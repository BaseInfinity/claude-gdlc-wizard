#!/bin/bash
# Test Claude Code plugin format (step-1 scope)
# Validates .claude-plugin/plugin.json + skills/ parity with CLI install.
# marketplace.json, hooks/hooks.json, and hook scripts are scoped for a
# later step — this suite is intentionally narrow.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PASSED=0
FAILED=0

export HOME="$(mktemp -d "${TMPDIR:-/tmp}/gdlc-plugin-test-home-XXXXXX")"
trap 'rm -rf "$HOME"' EXIT

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { echo -e "${GREEN}PASS${NC}: $1"; PASSED=$((PASSED + 1)); }
fail() { echo -e "${RED}FAIL${NC}: $1"; FAILED=$((FAILED + 1)); }

echo "=== Plugin Format Tests ==="
echo ""

# --- plugin.json ---

test_plugin_json_exists() {
    if [ -f "$REPO_ROOT/.claude-plugin/plugin.json" ]; then
        pass "plugin.json exists at .claude-plugin/plugin.json"
    else
        fail "plugin.json should exist at .claude-plugin/plugin.json"
    fi
}

test_plugin_json_valid() {
    local file="$REPO_ROOT/.claude-plugin/plugin.json"
    [ -f "$file" ] || { fail "plugin.json missing (skip validate)"; return; }
    if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
        pass "plugin.json is valid JSON"
    else
        fail "plugin.json should be valid JSON"
    fi
}

test_plugin_json_name() {
    local file="$REPO_ROOT/.claude-plugin/plugin.json"
    [ -f "$file" ] || { fail "plugin.json missing"; return; }
    local name
    name=$(python3 -c "import json; print(json.load(open('$file')).get('name',''))" 2>/dev/null)
    if [ "$name" = "gdlc-wizard" ]; then
        pass "plugin.json name is 'gdlc-wizard'"
    else
        fail "plugin.json name should be 'gdlc-wizard', got '$name'"
    fi
}

test_plugin_json_kebab_case_name() {
    local file="$REPO_ROOT/.claude-plugin/plugin.json"
    [ -f "$file" ] || { fail "plugin.json missing"; return; }
    local name
    name=$(python3 -c "import json; print(json.load(open('$file')).get('name',''))" 2>/dev/null)
    if echo "$name" | grep -qE '^[a-z][a-z0-9-]*$'; then
        pass "plugin.json name is kebab-case"
    else
        fail "plugin.json name must be kebab-case, got '$name'"
    fi
}

test_plugin_json_required_fields() {
    local file="$REPO_ROOT/.claude-plugin/plugin.json"
    [ -f "$file" ] || { fail "plugin.json missing"; return; }
    local ok=true
    for field in name version description author license; do
        local val
        val=$(python3 -c "import json; d=json.load(open('$file')); print(d.get('$field',''))" 2>/dev/null)
        if [ -z "$val" ]; then
            ok=false
        fi
    done
    if [ "$ok" = true ]; then
        pass "plugin.json has name, version, description, author, license"
    else
        fail "plugin.json should have name, version, description, author, license"
    fi
}

test_plugin_json_version_matches_package() {
    local plugin_file="$REPO_ROOT/.claude-plugin/plugin.json"
    local pkg_file="$REPO_ROOT/package.json"
    [ -f "$plugin_file" ] || { fail "plugin.json missing"; return; }
    local plugin_ver pkg_ver
    plugin_ver=$(python3 -c "import json; print(json.load(open('$plugin_file')).get('version',''))" 2>/dev/null)
    pkg_ver=$(python3 -c "import json; print(json.load(open('$pkg_file')).get('version',''))" 2>/dev/null)
    if [ "$plugin_ver" = "$pkg_ver" ]; then
        pass "plugin.json version ($plugin_ver) matches package.json"
    else
        fail "plugin.json version ($plugin_ver) should match package.json ($pkg_ver)"
    fi
}

# --- Skills at canonical location ---

test_plugin_skills_exist() {
    local ok=true
    local missing=""
    for skill in gdlc gdlc-setup gdlc-update gdlc-feedback; do
        if [ ! -f "$REPO_ROOT/skills/$skill/SKILL.md" ]; then
            ok=false
            missing="$missing $skill"
        fi
    done
    if [ "$ok" = true ]; then
        pass "All 4 skill SKILL.md files exist at skills/"
    else
        fail "skills/ missing:$missing"
    fi
}

# --- npm package.json plumbing ---

test_package_json_includes_plugin_dirs() {
    local file="$REPO_ROOT/package.json"
    local ok=true
    python3 -c "
import json, sys
with open('$file') as f:
    d = json.load(f)
files = d.get('files', [])
needed = ['skills/', '.claude-plugin/', 'cli/']
for n in needed:
    if n not in files:
        sys.exit(1)
" 2>/dev/null || ok=false
    if [ "$ok" = true ]; then
        pass "package.json files field includes skills/, .claude-plugin/, cli/"
    else
        fail "package.json files should include skills/, .claude-plugin/, cli/"
    fi
}

test_package_json_declares_bin() {
    local file="$REPO_ROOT/package.json"
    local ok=true
    python3 -c "
import json, sys
with open('$file') as f:
    d = json.load(f)
b = d.get('bin', {})
if isinstance(b, dict):
    if 'gdlc-wizard' not in b:
        sys.exit(1)
elif isinstance(b, str):
    pass  # shortcut form
else:
    sys.exit(1)
" 2>/dev/null || ok=false
    if [ "$ok" = true ]; then
        pass "package.json declares a 'gdlc-wizard' bin entry"
    else
        fail "package.json should declare bin.gdlc-wizard pointing at cli/bin/gdlc-wizard.js"
    fi
}

test_cli_installs_from_plugin_source() {
    # Run CLI into a fresh temp dir, then diff each installed skill against the plugin source
    local CLI="$REPO_ROOT/cli/bin/gdlc-wizard.js"
    if [ ! -f "$CLI" ]; then
        fail "CLI missing at $CLI — skipping parity test"
        return
    fi
    local d
    d=$(mktemp -d "${TMPDIR:-/tmp}/gdlc-plugin-parity-XXXXXX")
    (cd "$d" && node "$CLI" init >/dev/null 2>&1)
    local ok=true
    for skill in gdlc gdlc-setup gdlc-update gdlc-feedback; do
        local installed="$d/.claude/skills/$skill/SKILL.md"
        local source="$REPO_ROOT/skills/$skill/SKILL.md"
        [ -f "$installed" ] || { ok=false; continue; }
        [ -f "$source" ] || { ok=false; continue; }
        if ! diff -q "$installed" "$source" >/dev/null 2>&1; then
            ok=false
        fi
    done
    if [ "$ok" = true ]; then
        pass "CLI-installed skills match plugin source skills"
    else
        fail "CLI init should install skills identical to plugin skills/"
    fi
    rm -rf "$d"
}

# --- Run ---

test_plugin_json_exists
test_plugin_json_valid
test_plugin_json_name
test_plugin_json_kebab_case_name
test_plugin_json_required_fields
test_plugin_json_version_matches_package
test_plugin_skills_exist
test_package_json_includes_plugin_dirs
test_package_json_declares_bin
test_cli_installs_from_plugin_source

echo ""
echo "=== Results ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [ $FAILED -gt 0 ]; then
    exit 1
fi
