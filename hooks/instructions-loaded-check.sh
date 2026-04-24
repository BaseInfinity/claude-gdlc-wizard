#\!/bin/bash
# InstructionsLoaded hook — validates GDLC files exist at session start.
# Fires when Claude loads instructions (session start / resume).
# Available since Claude Code v2.1.69.
# Note: no set -e — this hook must always exit 0 so it can't block a session.

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$HOOK_DIR/_find-gdlc-root.sh"

if find_gdlc_root; then
    PROJECT_DIR="$GDLC_ROOT"
else
    exit 0
fi

if [ \! -f "$PROJECT_DIR/GDLC.md" ]; then
    echo "WARNING: Missing GDLC wizard file: GDLC.md"
    echo "Invoke Skill tool, skill=\"gdlc-setup\" to scaffold it."
fi

# Dual-channel install nudge
if [ -d "$PROJECT_DIR/.claude/skills/gdlc-update" ]; then
    for plugin_path in "$HOME/.claude/plugins-local/gdlc-wizard-wrap" "$HOME/.claude/plugins/cache/gdlc-wizard-local"; do
        if [ -d "$plugin_path" ]; then
            echo "WARNING: dual-install detected — CLI skills in .claude/skills/ AND Claude plugin at:"
            echo "  $plugin_path"
            echo "  Duplicate /gdlc-update commands come from running both channels. Pick one:"
            echo "    - Keep plugin: remove .claude/skills/gdlc-* from this project"
            echo "    - Keep CLI:    /plugin uninstall gdlc-wizard (or remove the plugin dir)"
            break
        fi
    done
fi

exit 0
