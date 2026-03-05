#!/usr/bin/env bash
#
# SubagentStop hook for Claude Code TTS
# Announces when a spawned subagent completes its task
#
# SubagentStop input fields (per official docs):
#   - agent_id: unique identifier for the subagent
#   - agent_type: type name (Bash, Explore, Plan, or custom agent names)
#   - agent_transcript_path: path to subagent's transcript
#   - stop_hook_active: whether stop hook is already active
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load config
CONFIG_FILE="$HOME/.config/claude-code-tts/.env"
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

# Respect quiet mode
VERBOSITY="${TTS_VERBOSITY:-normal}"
VERBOSITY="$(echo "$VERBOSITY" | tr '[:upper:]' '[:lower:]')"
if [[ "$VERBOSITY" == "quiet" ]]; then
  exit 0
fi

# Read hook input from stdin
HOOK_INPUT=$(cat)

# If parent Stop hook is active, avoid duplicate summaries by default
STOP_HOOK_ACTIVE=$(echo "$HOOK_INPUT" | jq -r '.stop_hook_active // false' 2>/dev/null)
if [[ "$STOP_HOOK_ACTIVE" == "true" && "${TTS_SUBAGENT_WITH_STOP:-false}" != "true" ]]; then
  exit 0
fi

# Extract the agent type from the SubagentStop input
AGENT_TYPE=$(echo "$HOOK_INPUT" | jq -r '.agent_type // empty' 2>/dev/null)
LAST_ASSISTANT_MESSAGE=$(echo "$HOOK_INPUT" | jq -c '.last_assistant_message // empty' 2>/dev/null)

# Create a friendly message based on agent type
case "$AGENT_TYPE" in
  Bash)
    MESSAGE="Background shell task completed"
    ;;
  Explore)
    MESSAGE="Exploration agent finished"
    ;;
  Plan)
    MESSAGE="Planning agent completed"
    ;;
  "")
    MESSAGE="A background agent has completed"
    ;;
  *)
    # Custom agent name - use it directly
    MESSAGE="$AGENT_TYPE agent completed"
    ;;
esac

# Add a short result summary if available
DETAILS=""
if [[ -n "$LAST_ASSISTANT_MESSAGE" && "$LAST_ASSISTANT_MESSAGE" != "null" ]]; then
  DETAILS=$(echo "$LAST_ASSISTANT_MESSAGE" | jq -r '
    if type == "string" then
      .
    elif type == "object" then
      if has("content") then
        (.content // []
          | map(select(.type == "text") | .text)
          | join(" "))
      elif has("message") then
        (.message.content // []
          | map(select(.type == "text") | .text)
          | join(" "))
      else
        empty
      end
    else
      empty
    end
  ' 2>/dev/null | tr '\n' ' ' | sed 's/  */ /g; s/^ *//; s/ *$//')
fi

if [[ -n "$DETAILS" ]]; then
  # Keep speech concise and avoid reading markdown symbols aloud
  DETAILS=$(echo "$DETAILS" | sed 's/[`*_#>]/ /g' | sed 's/  */ /g')
  DETAILS=$(echo "$DETAILS" | sed 's/\. .*/./' | head -c 140)
  MESSAGE="$MESSAGE. $DETAILS"
fi

# Speak the announcement
"$SCRIPT_DIR/play-tts.sh" "$MESSAGE" &

exit 0
