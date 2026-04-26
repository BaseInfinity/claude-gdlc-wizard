#!/bin/bash
# Test CLI distribution tool (claude-gdlc-wizard)
# Scope: CLI installs settings.json + 3 hook files + 4 skills + wizard doc
# + .gitignore entries. Tests run the real binary end-to-end.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/cli/bin/gdlc-wizard.js"
PASSED=0
FAILED=0

# Isolate tests from real HOME so plugin install detection doesn't false-trigger
# in dev environments that already have the plugin installed.
export HOME="$(mktemp -d "${TMPDIR:-/tmp}/gdlc-cli-test-home-XXXXXX")"
trap 'rm -rf "$HOME"' EXIT

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

pass() { echo -e "${GREEN}PASS${NC}: $1"; PASSED=$((PASSED + 1)); }
fail() { echo -e "${RED}FAIL${NC}: $1"; FAILED=$((FAILED + 1)); }

make_temp() {
    local d
    d=$(mktemp -d "${TMPDIR:-/tmp}/gdlc-cli-test-XXXXXX")
    echo "$d"
}

echo "=== CLI Distribution Tests ==="
echo ""

# Guard: CLI must exist to run any of these tests
if [ ! -f "$CLI" ]; then
    fail "CLI binary does not exist at $CLI — all tests skipped"
    echo ""
    echo "=== Results ==="
    echo "Passed: $PASSED"
    echo "Failed: $FAILED"
    exit 1
fi

# --- Arg parsing tests ---

test_help() {
    if node "$CLI" --help 2>&1 | grep -qi "usage"; then
        pass "--help shows usage"
    else
        fail "--help should show usage text"
    fi
}

test_version() {
    local cli_version pkg_version
    cli_version=$(node "$CLI" --version 2>&1)
    pkg_version=$(node -e "console.log(require('$REPO_ROOT/package.json').version)")
    if [ "$cli_version" = "$pkg_version" ]; then
        pass "--version ($cli_version) matches package.json"
    else
        fail "--version ($cli_version) should match package.json ($pkg_version)"
    fi
}

test_no_args_shows_help() {
    local output
    output=$(node "$CLI" 2>&1 || true)
    if echo "$output" | grep -qi "usage"; then
        pass "no-args shows usage"
    else
        fail "no-args should show usage text"
    fi
}

test_unknown_command() {
    local exit_code=0
    node "$CLI" bogus >/dev/null 2>&1 || exit_code=$?
    if [ "$exit_code" = "1" ]; then
        pass "unknown command exits 1"
    else
        fail "unknown command should exit 1, got $exit_code"
    fi
}

# --- init tests ---

test_dry_run_no_files() {
    local d
    d=$(make_temp)
    (cd "$d" && node "$CLI" init --dry-run >/dev/null 2>&1)
    if [ ! -d "$d/.claude" ] && [ ! -f "$d/CLAUDE_CODE_GDLC_WIZARD.md" ]; then
        pass "init --dry-run creates no files"
    else
        fail "init --dry-run should not create any files"
    fi
    rm -rf "$d"
}

test_creates_all_files() {
    local d
    d=$(make_temp)
    (cd "$d" && node "$CLI" init >/dev/null 2>&1)
    local count=0
    [ -f "$d/.claude/settings.json" ] && count=$((count + 1))
    [ -f "$d/.claude/hooks/_find-gdlc-root.sh" ] && count=$((count + 1))
    [ -f "$d/.claude/hooks/gdlc-prompt-check.sh" ] && count=$((count + 1))
    [ -f "$d/.claude/hooks/gdlc-instructions-loaded-check.sh" ] && count=$((count + 1))
    [ -f "$d/.claude/skills/gdlc/SKILL.md" ] && count=$((count + 1))
    [ -f "$d/.claude/skills/gdlc-setup/SKILL.md" ] && count=$((count + 1))
    [ -f "$d/.claude/skills/gdlc-update/SKILL.md" ] && count=$((count + 1))
    [ -f "$d/.claude/skills/gdlc-feedback/SKILL.md" ] && count=$((count + 1))
    [ -f "$d/CLAUDE_CODE_GDLC_WIZARD.md" ] && count=$((count + 1))
    if [ "$count" -eq 9 ]; then
        pass "init creates all 9 expected files (settings + 3 hook files + 4 skills + wizard doc)"
    else
        fail "init should create 9 files, found $count"
    fi
    rm -rf "$d"
}

test_hooks_executable() {
    local d
    d=$(make_temp)
    (cd "$d" && node "$CLI" init >/dev/null 2>&1)
    local ok=true
    [ -x "$d/.claude/hooks/gdlc-prompt-check.sh" ] || ok=false
    [ -x "$d/.claude/hooks/gdlc-instructions-loaded-check.sh" ] || ok=false
    if [ "$ok" = true ]; then
        pass "init sets the 2 gdlc hook scripts executable"
    else
        fail "init should chmod +x gdlc-prompt-check.sh and gdlc-instructions-loaded-check.sh"
    fi
    rm -rf "$d"
}

test_settings_json_valid_with_two_events() {
    local d
    d=$(make_temp)
    (cd "$d" && node "$CLI" init >/dev/null 2>&1)
    local hook_count
    hook_count=$(python3 -c "
import json
with open('$d/.claude/settings.json') as f:
    d = json.load(f)
print(len(d.get('hooks', {})))
" 2>/dev/null)
    if [ "$hook_count" = "2" ]; then
        pass "settings.json is valid JSON with 2 hook events (UserPromptSubmit + InstructionsLoaded)"
    else
        fail "settings.json should declare 2 hook events, got: $hook_count"
    fi
    rm -rf "$d"
}

test_settings_json_uses_project_dir() {
    local d
    d=$(make_temp)
    (cd "$d" && node "$CLI" init >/dev/null 2>&1)
    if grep -q 'CLAUDE_PROJECT_DIR' "$d/.claude/settings.json"; then
        pass "settings.json uses \$CLAUDE_PROJECT_DIR (CLI mode)"
    else
        fail "settings.json should reference \$CLAUDE_PROJECT_DIR for hook paths"
    fi
    rm -rf "$d"
}

test_hook_content_is_gdlc_specific() {
    local d
    d=$(make_temp)
    (cd "$d" && node "$CLI" init >/dev/null 2>&1)
    local ok=true
    grep -q "GDLC BASELINE" "$d/.claude/hooks/gdlc-prompt-check.sh" || ok=false
    grep -q "gdlc-setup" "$d/.claude/hooks/gdlc-prompt-check.sh" || ok=false
    grep -q "GDLC wizard file" "$d/.claude/hooks/gdlc-instructions-loaded-check.sh" || ok=false
    # Regression: no leftover SDLC markers
    if grep -q "SDLC BASELINE\|setup-wizard\|SDLC.md" "$d/.claude/hooks/gdlc-prompt-check.sh"; then
        ok=false
    fi
    if [ "$ok" = true ]; then
        pass "Installed hooks are GDLC-specific (no stale SDLC markers)"
    else
        fail "Installed hooks should contain GDLC BASELINE/gdlc-setup and no SDLC leftovers"
    fi
    rm -rf "$d"
}

test_dir_structure() {
    local d
    d=$(make_temp)
    (cd "$d" && node "$CLI" init >/dev/null 2>&1)
    local ok=true
    [ -d "$d/.claude/skills/gdlc" ] || ok=false
    [ -d "$d/.claude/skills/gdlc-setup" ] || ok=false
    [ -d "$d/.claude/skills/gdlc-update" ] || ok=false
    [ -d "$d/.claude/skills/gdlc-feedback" ] || ok=false
    if [ "$ok" = true ]; then
        pass "init creates correct .claude/skills/ subdirectory structure"
    else
        fail "init should create .claude/skills/{gdlc,gdlc-setup,gdlc-update,gdlc-feedback}"
    fi
    rm -rf "$d"
}

test_wizard_doc() {
    local d
    d=$(make_temp)
    (cd "$d" && node "$CLI" init >/dev/null 2>&1)
    if [ -f "$d/CLAUDE_CODE_GDLC_WIZARD.md" ] \
        && grep -q "Claude Code GDLC Wizard" "$d/CLAUDE_CODE_GDLC_WIZARD.md"; then
        pass "init copies wizard doc with expected content"
    else
        fail "init should copy CLAUDE_CODE_GDLC_WIZARD.md containing 'Claude Code GDLC Wizard' header"
    fi
    rm -rf "$d"
}

test_skill_frontmatter() {
    local d
    d=$(make_temp)
    (cd "$d" && node "$CLI" init >/dev/null 2>&1)
    local ok=true
    grep -q "^name: gdlc$" "$d/.claude/skills/gdlc/SKILL.md" || ok=false
    grep -q "^name: gdlc-setup$" "$d/.claude/skills/gdlc-setup/SKILL.md" || ok=false
    grep -q "^name: gdlc-update$" "$d/.claude/skills/gdlc-update/SKILL.md" || ok=false
    grep -q "^name: gdlc-feedback$" "$d/.claude/skills/gdlc-feedback/SKILL.md" || ok=false
    grep -q "^effort: high$" "$d/.claude/skills/gdlc/SKILL.md" || ok=false
    grep -q "^effort: high$" "$d/.claude/skills/gdlc-setup/SKILL.md" || ok=false
    if [ "$ok" = true ]; then
        pass "All 4 installed skills have correct name + effort frontmatter"
    else
        fail "Installed skills missing expected name or 'effort: high' frontmatter"
    fi
    rm -rf "$d"
}

test_cli_installs_from_source() {
    # Plugin parity — CLI must install byte-identical copies of the plugin skills
    local d
    d=$(make_temp)
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
        pass "CLI-installed skills match plugin source byte-for-byte (parity)"
    else
        fail "CLI init should install skills identical to skills/ source"
    fi
    rm -rf "$d"
}

test_skip_existing() {
    local d
    d=$(make_temp)
    mkdir -p "$d/.claude/skills/gdlc"
    echo "existing-content" > "$d/.claude/skills/gdlc/SKILL.md"
    local output
    output=$(cd "$d" && node "$CLI" init 2>&1)
    if echo "$output" | grep -q "SKIP"; then
        local content
        content=$(cat "$d/.claude/skills/gdlc/SKILL.md")
        if [ "$content" = "existing-content" ]; then
            pass "init skips existing files without --force and preserves content"
        else
            fail "init should not overwrite existing files without --force"
        fi
    else
        fail "init should report SKIP for existing files"
    fi
    rm -rf "$d"
}

test_force_overwrite() {
    local d
    d=$(make_temp)
    mkdir -p "$d/.claude/skills/gdlc"
    echo "old-content" > "$d/.claude/skills/gdlc/SKILL.md"
    (cd "$d" && node "$CLI" init --force >/dev/null 2>&1)
    local content
    content=$(cat "$d/.claude/skills/gdlc/SKILL.md")
    if [ "$content" != "old-content" ]; then
        pass "init --force overwrites existing files"
    else
        fail "init --force should overwrite existing files"
    fi
    rm -rf "$d"
}

# --- .gitignore tests ---

test_gitignore_append() {
    local d
    d=$(make_temp)
    (cd "$d" && node "$CLI" init >/dev/null 2>&1)
    local ok=true
    grep -q ".claude/plans/" "$d/.gitignore" || ok=false
    grep -q ".claude/settings.local.json" "$d/.gitignore" || ok=false
    if [ "$ok" = true ]; then
        pass ".gitignore gets required entries"
    else
        fail ".gitignore should contain .claude/plans/ and .claude/settings.local.json"
    fi
    rm -rf "$d"
}

test_gitignore_no_dupes() {
    local d
    d=$(make_temp)
    (cd "$d" && node "$CLI" init >/dev/null 2>&1)
    (cd "$d" && node "$CLI" init --force >/dev/null 2>&1)
    local count
    count=$(grep -c ".claude/plans/" "$d/.gitignore")
    if [ "$count" -eq 1 ]; then
        pass ".gitignore entries not duplicated on re-run"
    else
        fail ".gitignore should have exactly 1 .claude/plans/ entry, found $count"
    fi
    rm -rf "$d"
}

# --- check tests ---

test_check_match_on_fresh_install() {
    local d
    d=$(make_temp)
    (cd "$d" && node "$CLI" init >/dev/null 2>&1)
    local output
    output=$(cd "$d" && node "$CLI" check 2>&1 || true)
    local match_count
    match_count=$(echo "$output" | grep -c "MATCH" || true)
    # settings + 3 hook files + 4 skills + 1 wizard doc + 1 .gitignore = 10 MATCH
    if [ "$match_count" -ge 9 ]; then
        pass "check reports MATCH for fresh install ($match_count matches)"
    else
        fail "check should report MATCH for all fresh files, found $match_count"
    fi
    rm -rf "$d"
}

test_check_missing_exits_nonzero() {
    local d
    d=$(make_temp)
    local exit_code=0
    (cd "$d" && node "$CLI" check >/dev/null 2>&1) || exit_code=$?
    if [ "$exit_code" -eq 1 ]; then
        pass "check exits 1 when files missing"
    else
        fail "check should exit 1 when wizard files missing, got $exit_code"
    fi
    rm -rf "$d"
}

test_check_missing_reports() {
    local d
    d=$(make_temp)
    local output
    output=$(cd "$d" && node "$CLI" check 2>&1 || true)
    if echo "$output" | grep -q "MISSING"; then
        pass "check reports MISSING for absent files"
    else
        fail "check should emit 'MISSING' when wizard files absent"
    fi
    rm -rf "$d"
}

test_check_json_is_valid() {
    local d
    d=$(make_temp)
    (cd "$d" && node "$CLI" init >/dev/null 2>&1)
    local output
    output=$(cd "$d" && node "$CLI" check --json 2>&1 || true)
    if echo "$output" | python3 -c "import json, sys; json.load(sys.stdin)" 2>/dev/null; then
        pass "check --json outputs valid JSON"
    else
        fail "check --json should output valid JSON"
    fi
    rm -rf "$d"
}

# --- npm tarball-shape + shebang byte guards (Codex round-1 P0 fixes) ---

# package.json `files` array MUST include "hooks/" — without it, the npm
# tarball ships without the hook scripts, and cli/init.js's FILES array
# (which references hooks/_find-gdlc-root.sh, hooks/gdlc-prompt-check.sh,
# hooks/gdlc-instructions-loaded-check.sh) breaks 100% of npx installs.
test_package_files_includes_hooks() {
    local pkg="$REPO_ROOT/package.json"
    if jq -e '.files | index("hooks/")' "$pkg" > /dev/null 2>&1; then
        pass "package.json files array includes hooks/ (npm tarball will ship hooks)"
    else
        fail "package.json files array missing hooks/ — npm install would ship without hook scripts and CLI init would fail"
    fi
}

# Hook shebangs must start with literal #!/ (bytes 0x23 0x21 0x2f), not the
# escaped #\! form (bytes 0x23 0x5c 0x21). The escaped form passes when run
# as `bash script.sh` but fails on direct execution by Claude Code.
test_hook_shebang_bytes_clean() {
    local fail_count=0
    local bad=""
    for h in "$REPO_ROOT/hooks/"*.sh; do
        [ -f "$h" ] || continue
        local first3
        first3="$(head -c 3 "$h" | xxd -p)"
        if [ "$first3" = "23212f" ]; then
            :
        else
            fail_count=$((fail_count + 1))
            bad="$bad $(basename "$h"):0x$first3"
        fi
    done
    if [ $fail_count -eq 0 ]; then
        pass "all hook shebangs start with literal #!/ (no escaped-bang bytes)"
    else
        fail "$fail_count hook(s) have malformed shebang:$bad"
    fi
}

# --- Legacy hook migration regression (v0.2.1 → v0.2.2 namespace rename) ---
#
# Seeds a v0.2.1-style state (legacy `instructions-loaded-check.sh` hook file
# on disk + matching settings.json entry referencing the legacy basename),
# then runs `init` and verifies:
#   - the legacy file is gone,
#   - the namespaced `gdlc-instructions-loaded-check.sh` is installed,
#   - settings.json has exactly one InstructionsLoaded entry pointing at the
#     namespaced basename (not appended alongside the legacy entry).

seed_v021_legacy_state() {
    local d="$1"
    mkdir -p "$d/.claude/hooks"
    # Legacy hook file with realistic-ish content
    cat > "$d/.claude/hooks/instructions-loaded-check.sh" <<'LEGACY'
#!/usr/bin/env bash
# v0.2.1 legacy hook — pre-rename basename
echo '{"systemMessage": "[GDLC SETUP]"}'
LEGACY
    chmod +x "$d/.claude/hooks/instructions-loaded-check.sh"
    # settings.json with the legacy hook entry
    cat > "$d/.claude/settings.json" <<'SETTINGS'
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/gdlc-prompt-check.sh" }
        ]
      }
    ],
    "InstructionsLoaded": [
      {
        "hooks": [
          { "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/instructions-loaded-check.sh" }
        ]
      }
    ]
  }
}
SETTINGS
}

test_init_removes_legacy_hook_file() {
    local d
    d=$(make_temp)
    seed_v021_legacy_state "$d"
    (cd "$d" && node "$CLI" init --force >/dev/null 2>&1)
    local ok=true
    [ ! -f "$d/.claude/hooks/instructions-loaded-check.sh" ] || ok=false
    [ -f "$d/.claude/hooks/gdlc-instructions-loaded-check.sh" ] || ok=false
    if [ "$ok" = true ]; then
        pass "init --force removes legacy instructions-loaded-check.sh and installs namespaced replacement"
    else
        fail "init --force should remove .claude/hooks/instructions-loaded-check.sh AND install gdlc-instructions-loaded-check.sh"
    fi
    rm -rf "$d"
}

test_init_replaces_legacy_settings_entry() {
    local d
    d=$(make_temp)
    seed_v021_legacy_state "$d"
    (cd "$d" && node "$CLI" init --force >/dev/null 2>&1)
    # After migration, InstructionsLoaded should have exactly ONE entry, and it
    # should reference the namespaced basename, not the legacy basename.
    local entry_count
    entry_count=$(python3 -c "
import json
with open('$d/.claude/settings.json') as f:
    d = json.load(f)
entries = d['hooks'].get('InstructionsLoaded', [])
print(len(entries))
" 2>/dev/null)
    local has_namespaced
    has_namespaced=$(python3 -c "
import json
with open('$d/.claude/settings.json') as f:
    d = json.load(f)
entries = d['hooks'].get('InstructionsLoaded', [])
flat = [h.get('command','') for e in entries for h in e.get('hooks', [])]
namespaced = any('gdlc-instructions-loaded-check.sh' in c for c in flat)
legacy = any(c.endswith('instructions-loaded-check.sh') and 'gdlc-' not in c.split('/')[-1] for c in flat)
print('1' if (namespaced and not legacy) else '0')
" 2>/dev/null)
    if [ "$entry_count" = "1" ] && [ "$has_namespaced" = "1" ]; then
        pass "init --force replaces legacy InstructionsLoaded entry (1 entry, namespaced only)"
    else
        fail "init --force should leave a single InstructionsLoaded entry referencing gdlc-instructions-loaded-check.sh (entries=$entry_count, namespaced-only=$has_namespaced)"
    fi
    rm -rf "$d"
}

test_check_flags_legacy_hook_drift() {
    local d
    d=$(make_temp)
    (cd "$d" && node "$CLI" init >/dev/null 2>&1)
    # Drop the legacy artifact onto a clean v0.2.2 install so check sees BOTH
    # current files AND the legacy leftover.
    cat > "$d/.claude/hooks/instructions-loaded-check.sh" <<'LEGACY'
#!/usr/bin/env bash
echo legacy
LEGACY
    chmod +x "$d/.claude/hooks/instructions-loaded-check.sh"
    local output
    output=$(cd "$d" && node "$CLI" check 2>&1) || true
    local exit_code=0
    (cd "$d" && node "$CLI" check >/dev/null 2>&1) || exit_code=$?
    if echo "$output" | grep -q "DRIFT" && \
       echo "$output" | grep -q "instructions-loaded-check.sh" && \
       [ "$exit_code" -eq 1 ]; then
        pass "check flags legacy instructions-loaded-check.sh as DRIFT and exits 1"
    else
        fail "check should report DRIFT on legacy hook leftover and exit 1 (exit=$exit_code)"
    fi
    rm -rf "$d"
}

# --- Run ---

test_help
test_version
test_no_args_shows_help
test_unknown_command
test_dry_run_no_files
test_creates_all_files
test_hooks_executable
test_settings_json_valid_with_two_events
test_settings_json_uses_project_dir
test_hook_content_is_gdlc_specific
test_dir_structure
test_wizard_doc
test_skill_frontmatter
test_cli_installs_from_source
test_skip_existing
test_force_overwrite
test_gitignore_append
test_gitignore_no_dupes
test_check_match_on_fresh_install
test_check_missing_exits_nonzero
test_check_missing_reports
test_check_json_is_valid
test_package_files_includes_hooks
test_hook_shebang_bytes_clean
test_init_removes_legacy_hook_file
test_init_replaces_legacy_settings_entry
test_check_flags_legacy_hook_drift

echo ""
echo "=== Results ==="
echo "Passed: $PASSED"
echo "Failed: $FAILED"

if [ $FAILED -gt 0 ]; then
    exit 1
fi
