#!/usr/bin/env bash
#
# Claude Code TTS
# Main router script
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Mute check - check both project and home
[[ -f ".tts-muted" ]] && exit 0
[[ -f "$HOME/.tts-muted" ]] && exit 0

# Route to Groq (audio files are auto-deleted after playback)
exec "$SCRIPT_DIR/play-tts-groq.sh" "$1" "$2"
