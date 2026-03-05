#!/usr/bin/env bash
#
# Claude Code TTS
# Inworld TTS API Provider
# Cost: $10 per million characters (Max), $5 per million characters (Mini)
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/audio-utils.sh"

TEXT="$1"

# Load config for default voice and model
CONFIG_FILE="$HOME/.config/claude-code-tts/.env"
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

VOICE="${2:-${INWORLD_VOICE:-Luna}}"
MODEL="${INWORLD_MODEL:-inworld-tts-1.5-max}"

# Validate
if [[ -z "$TEXT" ]]; then
  echo "Usage: $0 \"text\" [voice]"
  echo "Voices: Luna, Dennis, Timothy, Ronald, Wendy, etc."
  echo "Models: inworld-tts-1.5-max (quality), inworld-tts-1.5-mini (speed)"
  exit 1
fi

# Check API key (already loaded from config above, or from environment)
if [[ -z "$INWORLD_API_KEY" ]]; then
  echo "Error: INWORLD_API_KEY not set"
  echo ""
  echo "Setup:"
  echo "  mkdir -p ~/.config/claude-code-tts"
  echo "  cat > ~/.config/claude-code-tts/.env << 'EOF'"
  echo "  TTS_PROVIDER=inworld"
  echo "  INWORLD_API_KEY=your-base64-encoded-key"
  echo "  INWORLD_MODEL=inworld-tts-1.5-max"
  echo "  INWORLD_VOICE=Dennis"
  echo "  EOF"
  echo "  chmod 600 ~/.config/claude-code-tts/.env"
  echo ""
  echo "Get your API key at: https://platform.inworld.ai/"
  echo "Note: API key must be base64 encoded"
  exit 1
fi

# Escape text for JSON
ESCAPED=$(printf '%s' "$TEXT" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' ')

# Call Inworld API (returns base64 audio directly - synchronous, no queue polling)
RESPONSE=$(curl -s -X POST "https://api.inworld.ai/tts/v1/voice" \
  -H "Authorization: Basic $INWORLD_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"text\":\"$ESCAPED\",\"voiceId\":\"$VOICE\",\"modelId\":\"$MODEL\"}")

# Extract base64 audio and decode
AUDIO=$(echo "$RESPONSE" | jq -r '.audioContent // empty')
if [[ -z "$AUDIO" ]]; then
  ERROR=$(echo "$RESPONSE" | jq -r '.error // .message // "Unknown error"')
  echo "Inworld API error: $ERROR"
  exit 2
fi

# Detect player (may be pre-set by router)
PLAYER="${TTS_DETECTED_PLAYER:-$(detect_player)}"

# Play audio with lock + PID tracking, in background so script returns immediately
(
  acquire_lock

  if player_supports_stdin "$PLAYER"; then
    # Streaming path: pipe decoded audio directly to player (no temp file)
    echo "$AUDIO" | base64 -d | play_audio_stdin "$PLAYER" &
    write_pid $!
    wait $!
  else
    # Fallback path: write temp file for players that don't support stdin
    OUTPUT="/tmp/inworld-tts-$$-$RANDOM.mp3"
    echo "$AUDIO" | base64 -d > "$OUTPUT"
    play_audio_file "$OUTPUT" "$PLAYER" &
    write_pid $!
    wait $!
    rm -f "$OUTPUT"
  fi

  clean_pid
  release_lock
) 2>/dev/null &

echo "🎤 $VOICE"
