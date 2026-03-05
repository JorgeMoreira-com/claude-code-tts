#!/usr/bin/env bash
#
# PreToolUse hook for Claude Code TTS
# Announces before certain tools run (Bash commands, etc.)
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/tool-announcements.sh"

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract tool name and input
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# Only announce for Bash commands (most interesting to hear about)
if [[ "$TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

# Get the command being run
COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

MESSAGE="$(pre_tool_message "$COMMAND")"

if [[ -z "$MESSAGE" ]]; then
  exit 0
fi

# Speak the announcement
"$SCRIPT_DIR/play-tts.sh" "$MESSAGE" &

exit 0
