#!/usr/bin/env bash
#
# Stop all TTS audio playback
#

PID_FILE="/tmp/claude-tts.pid"
LOCK_DIR="/tmp/claude-tts.lock.d"

# Kill tracked player process first (most precise)
if [[ -f "$PID_FILE" ]]; then
  PID=$(cat "$PID_FILE" 2>/dev/null)
  if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
    kill -TERM "$PID" 2>/dev/null
    sleep 0.1
    kill -0 "$PID" 2>/dev/null && kill -9 "$PID" 2>/dev/null
  fi
  rm -f "$PID_FILE"
fi

# Also kill any stray player processes
pkill -f ffplay 2>/dev/null
pkill -f "mpv --no-video" 2>/dev/null
pkill -f afplay 2>/dev/null
pkill -f paplay 2>/dev/null
pkill -f aplay 2>/dev/null

# Release lock
rmdir "$LOCK_DIR" 2>/dev/null

echo "Audio stopped"
