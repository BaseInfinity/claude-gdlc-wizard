#!/usr/bin/env bash
# Light GDLC hook — baseline reminder every prompt (~80 tokens).
# Full guidance in skill: .claude/skills/gdlc/

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./_find-gdlc-root.sh
source "$HOOK_DIR/_find-gdlc-root.sh"

if find_gdlc_root; then
    PROJECT_DIR="$GDLC_ROOT"
else
    exit 0
fi

if [ ! -s "$PROJECT_DIR/GDLC.md" ]; then
    cat << 'SETUP'
GDLC SETUP NOT COMPLETE: GDLC.md is missing.

MANDATORY FIRST ACTION: Invoke Skill tool, skill="gdlc-setup"
Do NOT proceed with any playtest / game-quality task until setup is complete.
Tell the user: "I need to run the GDLC setup wizard first to scaffold your case study."
SETUP
    exit 0
fi

cat << 'EOF'
GDLC BASELINE:
1. PICK THE RIGHT CYCLE: gameplay-matrix / art-craft-review / pipeline-contract-audit
2. NEVER COMBINE ROSTERS — run cycles sequentially when multiple surfaces touched (pipeline -> gameplay -> art)
3. TRIANGULATE P0s — 2+ personas concur before promoting to ratchet
4. RED BEFORE GREEN — every P0 earns a regression test before the fix
5. STOCK LABELS ONLY — /gdlc-feedback uses bug / enhancement / question

AUTO-INVOKE SKILL (Claude MUST do this FIRST):
- playtest / balance check / craft review / pipeline audit / ship game feature -> Invoke: Skill tool, skill="gdlc"
- DON'T invoke for: questions, explanations, reading game code, simple queries
- DON'T wait for the user to type /gdlc — AUTO-INVOKE based on task type

Quick refs: GDLC.md (case study) | CLAUDE_CODE_GDLC_WIZARD.md (wizard) | .claude/skills/gdlc/SKILL.md
EOF

# Dual-channel install check — CLI skills AND the Claude plugin both provide
# /gdlc-* commands; running both duplicates them. This lives on
# UserPromptSubmit because InstructionsLoaded stdout is discarded by Claude
# Code (issue #14) — a warning there never reaches anyone.
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
