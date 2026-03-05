#!/usr/bin/env bash
#
# Claude Code TTS - Notification Hook
# Shows desktop notification with sound and speaks high-priority alerts
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load config
CONFIG_FILE="$HOME/.config/claude-code-tts/.env"
[[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"

# Read hook input
HOOK_INPUT=$(cat)
TYPE=$(echo "$HOOK_INPUT" | jq -r '.notification_type // empty' 2>/dev/null)
RAW_MESSAGE=$(echo "$HOOK_INPUT" | jq -r '.message // empty' 2>/dev/null)

# Keep native desktop notification behavior
echo "$HOOK_INPUT" | claude-code-notification --sound Glass

# Respect mute markers for speech only
[[ -f ".tts-muted" ]] && exit 0
[[ -f "$HOME/.tts-muted" ]] && exit 0

VERBOSITY="${TTS_VERBOSITY:-normal}"
VERBOSITY="$(echo "$VERBOSITY" | tr '[:upper:]' '[:lower:]')"

# Quiet mode still announces permission prompts, but skips idle chatter
if [[ "$VERBOSITY" == "quiet" && "$TYPE" != "permission" ]]; then
  exit 0
fi

case "$TYPE" in
  permission)
    MESSAGE="Permission needed"
    if [[ -n "$RAW_MESSAGE" && "$RAW_MESSAGE" != "null" ]]; then
      MESSAGE="Permission needed. $(echo "$RAW_MESSAGE" | tr '\n' ' ' | sed 's/  */ /g' | head -c 120)"
    fi
    ;;
  idle)
    MESSAGE="Claude needs your attention"
    if [[ "$VERBOSITY" == "verbose" && -n "$RAW_MESSAGE" && "$RAW_MESSAGE" != "null" ]]; then
      MESSAGE="$(echo "$RAW_MESSAGE" | tr '\n' ' ' | sed 's/  */ /g' | head -c 120)"
    fi
    ;;
  *)
    # Keep non-priority notification types silent by default
    if [[ "$VERBOSITY" != "verbose" ]]; then
      exit 0
    fi
    MESSAGE="${RAW_MESSAGE:-Notification received}"
    ;;
esac

"$SCRIPT_DIR/play-tts.sh" "$MESSAGE" &

exit 0
