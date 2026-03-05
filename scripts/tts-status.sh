#!/usr/bin/env bash
#
# Claude Code TTS - Status Line
# Outputs TTS provider/voice/state for use in Claude Code statusLine config
#
# Usage in ~/.claude/settings.json:
#   "statusLine": "~/.claude/plugins/cache/.../scripts/tts-status.sh"
#

CONFIG_FILE="$HOME/.config/claude-code-tts/.env"
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

PROVIDER="${TTS_PROVIDER:-inworld}"
PID_FILE="/tmp/claude-tts.pid"

# Build provider/voice/model label
case "$PROVIDER" in
  groq)
    VOICE="${TTS_VOICE:-hannah}"
    LABEL="groq/$VOICE"
    ;;
  inworld|*)
    VOICE="${INWORLD_VOICE:-Luna}"
    MODEL="${INWORLD_MODEL:-inworld-tts-1.5-max}"
    # Shorten model name: inworld-tts-1.5-max -> max, inworld-tts-1.5-mini -> mini
    SHORT_MODEL="${MODEL##*-}"
    LABEL="inworld/$SHORT_MODEL/$VOICE"
    ;;
esac

STATUS="TTS: $LABEL"

# Check mute status (global only - project mute not reliably detectable here)
if [[ -f "$HOME/.tts-muted" ]]; then
  STATUS="$STATUS MUTED"
fi

# Check if audio is currently playing
if [[ -f "$PID_FILE" ]]; then
  PID=$(cat "$PID_FILE" 2>/dev/null)
  if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
    STATUS="$STATUS >>>"
  fi
fi

echo "$STATUS"
