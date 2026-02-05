#!/usr/bin/env bash
#
# Stop hook for Claude Code TTS
# Reads the last assistant message and speaks a summary
#
# Summarization modes (set TTS_SUMMARIZE in config):
#   - "true" or "claude" (default): Use Claude CLI for smart summarization (~3-5 sec)
#   - "false": Simple first-sentence extraction (instant, no extra latency)
#
# This uses a command hook instead of a prompt hook to avoid
# the "Unknown skill: TTS" error that occurs when Claude's
# response text goes through skill detection.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load config
CONFIG_FILE="$HOME/.config/claude-code-tts/.env"
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract transcript path from hook input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // empty')

# If no transcript or file doesn't exist, allow and exit
if [[ -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]]; then
  exit 0
fi

# Get the last assistant message from the transcript
# The transcript is JSONL format with one message per line
LAST_ASSISTANT=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)

if [[ -z "$LAST_ASSISTANT" ]]; then
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
  exit 0
fi

# Summarize the text based on configuration
# TTS_SUMMARIZE: "true"/"claude" (default) = use Claude CLI, "false" = simple extraction
TTS_SUMMARY_WORDS="${TTS_SUMMARY_WORDS:-25}"

if [[ "${TTS_SUMMARIZE:-true}" == "false" ]]; then
  # Simple first-sentence extraction (instant, opt-in for lower latency)
  SUMMARY=$(echo "$FINAL_TEXT" | sed 's/\. .*/\./' | head -c 300)
else
  # Use Claude CLI for intelligent summarization (default)
  SUMMARY=$("$SCRIPT_DIR/summarize-with-claude.sh" "$FINAL_TEXT" "$TTS_SUMMARY_WORDS" 2>/dev/null)

  # Fall back to simple extraction if Claude CLI fails
  if [[ -z "$SUMMARY" ]]; then
    SUMMARY=$(echo "$FINAL_TEXT" | sed 's/\. .*/\./' | head -c 300)
  fi
fi

# Clean up the text - remove newlines and extra spaces
SUMMARY=$(echo "$SUMMARY" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

# Speak the summary if we have content
if [[ -n "$SUMMARY" && ${#SUMMARY} -gt 5 ]]; then
  "$SCRIPT_DIR/play-tts.sh" "$SUMMARY" &
fi

exit 0
