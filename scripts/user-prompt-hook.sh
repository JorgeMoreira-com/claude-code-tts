#!/usr/bin/env bash
#
# Claude Code TTS - UserPromptSubmit Hook
# Kills active TTS playback when the user submits a new prompt
#

# Hooks must consume stdin
cat > /dev/null

PID_FILE="/tmp/claude-tts.pid"

# Kill active TTS player process
# The background subshell in the provider script handles lock release after wait returns
if [[ -f "$PID_FILE" ]]; then
  PID=$(cat "$PID_FILE" 2>/dev/null)
  if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
    kill -TERM "$PID" 2>/dev/null
    # Brief wait, then force kill if still alive
    sleep 0.1
    kill -0 "$PID" 2>/dev/null && kill -9 "$PID" 2>/dev/null
  fi
fi

exit 0
