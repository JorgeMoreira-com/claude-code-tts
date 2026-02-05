#!/usr/bin/env bash
#
# Claude Code TTS
# Inworld TTS API Provider
# Cost: $10 per million characters (Max), $5 per million characters (Mini)
#

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

# Use system temp directory (no persistence)
OUTPUT="/tmp/inworld-tts-$$-$RANDOM.mp3"

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

# Decode base64 audio to file
echo "$AUDIO" | base64 -d > "$OUTPUT"

# Play audio and delete file after playback completes
# Runs in background subshell so script can return immediately
(
  if [[ "$(uname -s)" == "Darwin" ]]; then
    afplay "$OUTPUT" 2>/dev/null
  elif command -v paplay &>/dev/null; then
    paplay "$OUTPUT" 2>/dev/null
  elif command -v aplay &>/dev/null; then
    aplay "$OUTPUT" 2>/dev/null
  fi
  rm -f "$OUTPUT"
) &

echo "🎤 $VOICE"
