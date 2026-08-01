#!/usr/bin/env bash
# Shared helper: walk up from CWD to find the nearest GDLC project root.
# Sourced by gdlc-prompt-check.sh.
# Anchors on GDLC.md (setup complete) OR CLAUDE_CODE_GDLC_WIZARD.md (fresh
# install — CLI ran but gdlc-setup hasn't). Without the second anchor the
# setup nudge can never fire on a fresh install (issue #14).
# Lets a hook fire from a subdir inside a GDLC project (monorepo support).

# find_gdlc_root — walks up from pwd, stops at $HOME (exclusive) or /.
# Sets GDLC_ROOT to the found directory, or empty string if not found.
find_gdlc_root() {
    local check_dir
    check_dir="$(pwd)"
    GDLC_ROOT=""
    while [ "$check_dir" != "/" ] && [ "$check_dir" != "$HOME" ] && [ -n "$check_dir" ]; do
        if [ -f "$check_dir/GDLC.md" ] || [ -f "$check_dir/CLAUDE_CODE_GDLC_WIZARD.md" ]; then
            GDLC_ROOT="$check_dir"
            return 0
        fi
        check_dir="$(dirname "$check_dir")"
    done
    return 1
}
