#!/bin/bash
# Test Claude Code plugin format
# Validates .claude-plugin/plugin.json, .claude-plugin/marketplace.json,
# hooks/hooks.json, hook-script executability, and CLI-to-plugin parity.

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
    # Run CLI into a fresh temp dir, then diff installed skills and hooks
    # against the plugin source.
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
    for hook in gdlc-prompt-check.sh instructions-loaded-check.sh _find-gdlc-root.sh; do
        local installed="$d/.claude/hooks/$hook"
        local source="$REPO_ROOT/hooks/$hook"
        [ -f "$installed" ] || { ok=false; continue; }
        [ -f "$source" ] || { ok=false; continue; }
        if ! diff -q "$installed" "$source" >/dev/null 2>&1; then
            ok=false
        fi
    done
    if [ "$ok" = true ]; then
        pass "CLI-installed skills + hooks match plugin source byte-for-byte"
    else
        fail "CLI init should install files identical to plugin source"
    fi
    rm -rf "$d"
}

# --- hooks/hooks.json (plugin format) ---

test_hooks_json_exists() {
    if [ -f "$REPO_ROOT/hooks/hooks.json" ]; then
        pass "hooks.json exists at hooks/hooks.json"
    else
        fail "hooks.json should exist at hooks/hooks.json for plugin format"
    fi
}

test_hooks_json_valid() {
    local file="$REPO_ROOT/hooks/hooks.json"
    [ -f "$file" ] || { fail "hooks.json missing"; return; }
    if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
        pass "hooks.json is valid JSON"
    else
        fail "hooks.json should be valid JSON"
    fi
}

test_hooks_json_uses_plugin_root() {
    # In plugin format, hook paths must resolve from $CLAUDE_PLUGIN_ROOT,
    # not $CLAUDE_PROJECT_DIR. Mixing them breaks plugin installs.
    local file="$REPO_ROOT/hooks/hooks.json"
    [ -f "$file" ] || { fail "hooks.json missing"; return; }
    if grep -q 'CLAUDE_PLUGIN_ROOT' "$file" && ! grep -q 'CLAUDE_PROJECT_DIR' "$file"; then
        pass "hooks.json uses CLAUDE_PLUGIN_ROOT (not CLAUDE_PROJECT_DIR)"
    else
        fail "hooks.json should use \${CLAUDE_PLUGIN_ROOT} only, not CLAUDE_PROJECT_DIR"
    fi
}

test_hooks_json_event_parity() {
    # Plugin-format hooks.json must describe the same events as the
    # CLI-format settings.json template — otherwise plugin-installed users
    # and CLI-installed users get different behavior.
    local hooks_file="$REPO_ROOT/hooks/hooks.json"
    local settings_file="$REPO_ROOT/cli/templates/settings.json"
    [ -f "$hooks_file" ] && [ -f "$settings_file" ] || { fail "hooks/settings file(s) missing"; return; }
    local hooks_events settings_events
    hooks_events=$(python3 -c "
import json
with open('$hooks_file') as f: d = json.load(f)
print(' '.join(sorted(d.get('hooks', {}).keys())))
" 2>/dev/null)
    settings_events=$(python3 -c "
import json
with open('$settings_file') as f: d = json.load(f)
print(' '.join(sorted(d.get('hooks', {}).keys())))
" 2>/dev/null)
    if [ "$hooks_events" = "$settings_events" ]; then
        pass "hooks.json events match CLI settings.json events ($hooks_events)"
    else
        fail "Event mismatch: hooks.json='$hooks_events' settings.json='$settings_events'"
    fi
}

test_plugin_hook_scripts_exist() {
    local ok=true
    local missing=""
    for script in gdlc-prompt-check.sh instructions-loaded-check.sh _find-gdlc-root.sh; do
        if [ ! -f "$REPO_ROOT/hooks/$script" ]; then
            ok=false
            missing="$missing $script"
        fi
    done
    if [ "$ok" = true ]; then
        pass "All hook scripts present at hooks/"
    else
        fail "hooks/ missing:$missing"
    fi
}

test_plugin_hook_scripts_executable() {
    local ok=true
    local missing=""
    # _find-gdlc-root.sh is sourced, not executed — no +x required.
    for script in gdlc-prompt-check.sh instructions-loaded-check.sh; do
        if [ ! -x "$REPO_ROOT/hooks/$script" ]; then
            ok=false
            missing="$missing $script"
        fi
    done
    if [ "$ok" = true ]; then
        pass "Executable hook scripts (gdlc-prompt-check, instructions-loaded) have +x"
    else
        fail "hooks/ non-executable:$missing"
    fi
}

# --- marketplace.json ---

test_marketplace_json_exists() {
    if [ -f "$REPO_ROOT/.claude-plugin/marketplace.json" ]; then
        pass "marketplace.json exists at .claude-plugin/marketplace.json"
    else
        fail "marketplace.json should exist at .claude-plugin/marketplace.json"
    fi
}

test_marketplace_json_valid() {
    local file="$REPO_ROOT/.claude-plugin/marketplace.json"
    [ -f "$file" ] || { fail "marketplace.json missing"; return; }
    if python3 -c "import json; json.load(open('$file'))" 2>/dev/null; then
        pass "marketplace.json is valid JSON"
    else
        fail "marketplace.json should be valid JSON"
    fi
}

test_marketplace_json_has_plugin() {
    local file="$REPO_ROOT/.claude-plugin/marketplace.json"
    [ -f "$file" ] || { fail "marketplace.json missing"; return; }
    local count
    count=$(python3 -c "
import json
with open('$file') as f: d = json.load(f)
print(len(d.get('plugins', [])))
" 2>/dev/null)
    if [ "$count" -ge 1 ]; then
        pass "marketplace.json lists at least 1 plugin"
    else
        fail "marketplace.json should list at least 1 plugin"
    fi
}

test_marketplace_plugin_version_matches_package() {
    local mkt_file="$REPO_ROOT/.claude-plugin/marketplace.json"
    local pkg_file="$REPO_ROOT/package.json"
    [ -f "$mkt_file" ] || { fail "marketplace.json missing"; return; }
    local mkt_ver pkg_ver
    mkt_ver=$(python3 -c "
import json
with open('$mkt_file') as f: d = json.load(f)
print(d['plugins'][0].get('version',''))
" 2>/dev/null)
    pkg_ver=$(python3 -c "import json; print(json.load(open('$pkg_file')).get('version',''))" 2>/dev/null)
    if [ "$mkt_ver" = "$pkg_ver" ]; then
        pass "marketplace.json plugin version ($mkt_ver) matches package.json"
    else
        fail "marketplace.json plugin version ($mkt_ver) should match package.json ($pkg_ver)"
    fi
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
test_hooks_json_exists
test_hooks_json_valid
test_hooks_json_uses_plugin_root
test_hooks_json_event_parity
test_plugin_hook_scripts_exist
test_plugin_hook_scripts_executable
test_marketplace_json_exists
test_marketplace_json_valid
test_marketplace_json_has_plugin
test_marketplace_plugin_version_matches_package

echo ""
echo "=== Results ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [ $FAILED -gt 0 ]; then
    exit 1
fi
