#!/usr/bin/env bash
#
# Claude Code TTS - Session Start Hook
# Returns skill content if configured, warning if not
#
# Key insight: CLAUDE_PLUGIN_ROOT is only set during hook execution,
# not in subsequent Bash commands. We substitute it here so Claude
# receives the actual resolved path in the skill instructions.
#

CONFIG_FILE="$HOME/.config/claude-code-tts/.env"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(dirname "$(dirname "$0")")}"

if [[ -f "$CONFIG_FILE" ]] && grep -q 'GROQ_API_KEY=.' "$CONFIG_FILE"; then
  # Substitute ${CLAUDE_PLUGIN_ROOT} with actual path so Claude can use it
  sed "s|\${CLAUDE_PLUGIN_ROOT}|$PLUGIN_ROOT|g" "$PLUGIN_ROOT/skills/tts/SKILL.md"
else
  echo "⚠️ TTS NOT CONFIGURED - Run /claude-code-tts:setup to configure your Groq API key"
fi
