#!/usr/bin/env bash
#
# SubagentStop hook for Claude Code TTS
# Announces when a spawned subagent completes its task
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract the task description from the subagent
DESCRIPTION=$(echo "$HOOK_INPUT" | jq -r '.tool_input.description // .tool_input.prompt // "a task" | .[0:100]' 2>/dev/null)

# Clean up description for speech
if [[ -n "$DESCRIPTION" && "$DESCRIPTION" != "null" ]]; then
  # Truncate and clean for TTS
  DESCRIPTION=$(echo "$DESCRIPTION" | tr '\n' ' ' | sed 's/  */ /g' | head -c 80)
  MESSAGE="Subagent finished: $DESCRIPTION"
else
  MESSAGE="A background agent has completed its task."
fi

# Speak the announcement
"$SCRIPT_DIR/play-tts.sh" "$MESSAGE" &

echo '{"decision":"approve"}'
