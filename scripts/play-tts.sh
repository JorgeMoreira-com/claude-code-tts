#!/usr/bin/env bash
#
# Claude Code TTS
# Main router script - routes to configured provider
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Mute check - check both project and home
[[ -f ".tts-muted" ]] && exit 0
[[ -f "$HOME/.tts-muted" ]] && exit 0

# Load shared audio utilities and detect player
source "$SCRIPT_DIR/audio-utils.sh"
export TTS_DETECTED_PLAYER
TTS_DETECTED_PLAYER="$(detect_player)"

# Load config for provider selection
CONFIG_FILE="$HOME/.config/claude-code-tts/.env"
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

# Route based on provider
# Default: inworld (best quality at lowest price)
case "${TTS_PROVIDER:-inworld}" in
  groq)
    exec "$SCRIPT_DIR/play-tts-groq.sh" "$1" "$2"
    ;;
  inworld|*)
    exec "$SCRIPT_DIR/play-tts-inworld.sh" "$1" "$2"
    ;;
esac
