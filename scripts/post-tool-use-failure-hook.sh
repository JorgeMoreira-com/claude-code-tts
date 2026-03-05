#!/usr/bin/env bash
#
# PostToolUseFailure hook for Claude Code TTS
# Announces when Bash commands fail
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/tool-announcements.sh"

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract tool name
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

if ! tool_is_bash "$TOOL_NAME"; then
  exit 0
fi

# Get the command that failed
COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [[ -z "$COMMAND" || "$COMMAND" == "null" ]]; then
  COMMAND="command"
fi

MESSAGE="$(post_tool_failure_message "$COMMAND")"

if [[ -z "$MESSAGE" ]]; then
  exit 0
fi

"$SCRIPT_DIR/play-tts.sh" "$MESSAGE" &

exit 0
