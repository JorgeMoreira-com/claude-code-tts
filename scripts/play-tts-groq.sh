#!/usr/bin/env bash
#
# Claude Code TTS
# Groq Orpheus API Provider
# Cost: $22 per million characters
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/audio-utils.sh"

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

# Escape text for JSON
ESCAPED=$(printf '%s' "$TEXT" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')

# Detect player (may be pre-set by router)
PLAYER="${TTS_DETECTED_PLAYER:-$(detect_player)}"

# Play audio with lock + PID tracking, in background so script returns immediately
(
  acquire_lock

  if player_supports_stdin "$PLAYER"; then
    # True streaming path: curl pipes directly to player (no temp file at all)
    curl -s -X POST "https://api.groq.com/openai/v1/audio/speech" \
      -H "Authorization: Bearer $GROQ_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"model\":\"canopylabs/orpheus-v1-english\",\"voice\":\"$VOICE\",\"input\":\"$ESCAPED\",\"response_format\":\"wav\"}" \
      | play_audio_stdin "$PLAYER" &
    write_pid $!
    wait $!
  else
    # Fallback path: curl to temp file with HTTP error checking
    OUTPUT="/tmp/groq-tts-$$-$RANDOM.wav"
    HTTP=$(curl -s -w "%{http_code}" -o "$OUTPUT" \
      -X POST "https://api.groq.com/openai/v1/audio/speech" \
      -H "Authorization: Bearer $GROQ_API_KEY" \
      -H "Content-Type: application/json" \
      -d "{\"model\":\"canopylabs/orpheus-v1-english\",\"voice\":\"$VOICE\",\"input\":\"$ESCAPED\",\"response_format\":\"wav\"}")

    if [[ "$HTTP" != "200" ]]; then
      echo "Groq API error: HTTP $HTTP" >&2
      rm -f "$OUTPUT"
    else
      play_audio_file "$OUTPUT" "$PLAYER" &
      write_pid $!
      wait $!
      rm -f "$OUTPUT"
    fi
  fi

  clean_pid
  release_lock
) 2>/dev/null &

echo "🎤 $VOICE"
