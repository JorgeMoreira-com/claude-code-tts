#!/usr/bin/env bash
#
# Claude Code TTS
# Groq Orpheus API Provider
# Cost: $22 per million characters
#

TEXT="$1"

# Load config for default voice
CONFIG_FILE="$HOME/.config/claude-code-tts/.env"
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
VOICE="${2:-${TTS_VOICE:-hannah}}"

# Validate
if [[ -z "$TEXT" ]]; then
  echo "Usage: $0 \"text\" [voice]"
  echo "Voices: hannah, troy, austin, tara, leah, jess, leo, dan, mia, zac"
  exit 1
fi

# Check API key (already loaded from config above, or from environment)
if [[ -z "$GROQ_API_KEY" ]]; then
  echo "Error: GROQ_API_KEY not set"
  echo ""
  echo "Setup (choose one):"
  echo "  1. Config file (recommended):"
  echo "     mkdir -p ~/.config/claude-code-tts"
  echo "     echo 'GROQ_API_KEY=your-key' > ~/.config/claude-code-tts/.env"
  echo "     chmod 600 ~/.config/claude-code-tts/.env"
  echo ""
  echo "  2. Environment variable:"
  echo "     export GROQ_API_KEY='your-key'"
  echo ""
  echo "Get your API key at: https://console.groq.com/keys"
  exit 1
fi

# Use system temp directory (no persistence)
# Note: macOS mktemp doesn't support suffixes after XXXXXX, so we use PID+RANDOM
OUTPUT="/tmp/groq-tts-$$-$RANDOM.wav"

# Escape text for JSON
ESCAPED=$(printf '%s' "$TEXT" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')

# Call Groq API
HTTP=$(curl -s -w "%{http_code}" -o "$OUTPUT" \
  -X POST "https://api.groq.com/openai/v1/audio/speech" \
  -H "Authorization: Bearer $GROQ_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"model\":\"canopylabs/orpheus-v1-english\",\"voice\":\"$VOICE\",\"input\":\"$ESCAPED\",\"response_format\":\"wav\"}")

if [[ "$HTTP" != "200" ]]; then
  echo "Groq API error: HTTP $HTTP"
  [[ -f "$OUTPUT" ]] && cat "$OUTPUT" && rm -f "$OUTPUT"
  exit 2
fi

# Play audio and delete file after playback completes
# Uses locking to queue audio - prevents overlapping TTS messages
# Runs in background subshell so script can return immediately
LOCK_FILE="/tmp/claude-tts.lock"
(
  # Cross-platform lock acquisition
  # Wait for any existing lock to be released (another audio playing)
  while ! mkdir "$LOCK_FILE.d" 2>/dev/null; do
    sleep 0.1
  done

  # Play audio
  if [[ "$(uname -s)" == "Darwin" ]]; then
    afplay "$OUTPUT" 2>/dev/null
  elif command -v paplay &>/dev/null; then
    paplay "$OUTPUT" 2>/dev/null
  elif command -v aplay &>/dev/null; then
    aplay "$OUTPUT" 2>/dev/null
  fi

  # Release lock and cleanup
  rmdir "$LOCK_FILE.d" 2>/dev/null
  rm -f "$OUTPUT"
) &

echo "🎤 $VOICE"
