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

# Extract assistant message directly from hook input when available
LAST_ASSISTANT_MESSAGE=$(echo "$HOOK_INPUT" | jq -c '.last_assistant_message // empty' 2>/dev/null)

extract_text_from_message() {
  local message_json="$1"
  echo "$message_json" | jq -r '
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
  ' 2>/dev/null
}

FINAL_TEXT=""

if [[ -n "$LAST_ASSISTANT_MESSAGE" && "$LAST_ASSISTANT_MESSAGE" != "null" ]]; then
  FINAL_TEXT="$(extract_text_from_message "$LAST_ASSISTANT_MESSAGE")"
fi

# Fallback to transcript parsing if payload message is missing
if [[ -z "$FINAL_TEXT" || "$FINAL_TEXT" == "null" ]]; then
  TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)

  if [[ -z "$TRANSCRIPT_PATH" || ! -f "$TRANSCRIPT_PATH" ]]; then
    exit 0
  fi

  LAST_ASSISTANT=$(jq -sc '
    map(select(.role == "assistant" and .message != null)) | last // empty
  ' "$TRANSCRIPT_PATH" 2>/dev/null)

  if [[ -n "$LAST_ASSISTANT" && "$LAST_ASSISTANT" != "null" ]]; then
    FINAL_TEXT="$(extract_text_from_message "$LAST_ASSISTANT")"
  fi
fi

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
