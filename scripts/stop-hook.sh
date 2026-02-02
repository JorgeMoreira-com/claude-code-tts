#!/usr/bin/env bash
#
# Stop hook for Claude Code TTS
# Reads the last assistant message and speaks the first sentence
#
# This uses a command hook instead of a prompt hook to avoid
# the "Unknown skill: TTS" error that occurs when Claude's
# response text goes through skill detection.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract transcript path from hook input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // empty')

# If no transcript or file doesn't exist, approve and exit
if [[ -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]]; then
  echo '{"decision":"approve"}'
  exit 0
fi

# Get the last assistant message from the transcript
# The transcript is JSONL format with one message per line
LAST_ASSISTANT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)

if [[ -z "$LAST_ASSISTANT" ]]; then
  echo '{"decision":"approve"}'
  exit 0
fi

# Extract text content from the message
# Assistant messages have content array with text blocks
FINAL_TEXT=$(echo "$LAST_ASSISTANT" | jq -r '
  .message.content // [] |
  map(select(.type == "text")) |
  map(.text) |
  join(" ")
' 2>/dev/null)

# Skip if no text content
if [[ -z "$FINAL_TEXT" || "$FINAL_TEXT" == "null" ]]; then
  echo '{"decision":"approve"}'
  exit 0
fi

# Extract first sentence (simple heuristic summarization)
# Stop at first period followed by space, or limit to 300 chars
FIRST_SENTENCE=$(echo "$FINAL_TEXT" | sed 's/\. .*/\./' | head -c 300)

# Clean up the text - remove newlines and extra spaces
FIRST_SENTENCE=$(echo "$FIRST_SENTENCE" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

# Speak the first sentence if we have content
if [[ -n "$FIRST_SENTENCE" && ${#FIRST_SENTENCE} -gt 5 ]]; then
  "$SCRIPT_DIR/play-tts.sh" "$FIRST_SENTENCE" &
fi

echo '{"decision":"approve"}'
