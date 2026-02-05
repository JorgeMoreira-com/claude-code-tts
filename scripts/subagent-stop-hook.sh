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

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract the agent type from the SubagentStop input
AGENT_TYPE=$(echo "$HOOK_INPUT" | jq -r '.agent_type // empty' 2>/dev/null)

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

# Speak the announcement
"$SCRIPT_DIR/play-tts.sh" "$MESSAGE" &

exit 0
