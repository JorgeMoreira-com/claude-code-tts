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

has_key_in_config() {
  local key_name="$1"
  grep -q "^${key_name}=." "$CONFIG_FILE" 2>/dev/null
}

# Check for either provider key from environment or config file
HAS_GROQ_ENV="no"
HAS_INWORLD_ENV="no"
[[ -n "${GROQ_API_KEY:-}" ]] && HAS_GROQ_ENV="yes"
[[ -n "${INWORLD_API_KEY:-}" ]] && HAS_INWORLD_ENV="yes"

if [[ "$HAS_GROQ_ENV" == "yes" || "$HAS_INWORLD_ENV" == "yes" ]] || \
   has_key_in_config "GROQ_API_KEY" || has_key_in_config "INWORLD_API_KEY"; then
  # Substitute ${CLAUDE_PLUGIN_ROOT} with actual path so Claude can use it
  sed "s|\${CLAUDE_PLUGIN_ROOT}|$PLUGIN_ROOT|g" "$PLUGIN_ROOT/skills/tts/SKILL.md"
else
  echo "TTS is not configured. Run /claude-code-tts:setup to configure your TTS provider." >&2
fi
