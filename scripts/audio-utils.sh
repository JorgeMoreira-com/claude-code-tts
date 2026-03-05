#!/usr/bin/env bash
#
# Claude Code TTS - Shared Audio Utilities
# Provides player detection, streaming playback, locking, and PID tracking
#

LOCK_DIR="/tmp/claude-tts.lock.d"
PID_FILE="/tmp/claude-tts.pid"

# Detect best available audio player
# Honors TTS_PLAYER config override
detect_player() {
  if [[ -n "$TTS_PLAYER" ]]; then
    echo "$TTS_PLAYER"
    return
  fi
  if command -v ffplay &>/dev/null; then
    echo "ffplay"
  elif command -v mpv &>/dev/null; then
    echo "mpv"
  elif [[ "$(uname -s)" == "Darwin" ]]; then
    echo "afplay"
  elif command -v paplay &>/dev/null; then
    echo "paplay"
  elif command -v aplay &>/dev/null; then
    echo "aplay"
  else
    echo ""
  fi
}

# Check if detected player supports reading from stdin
player_supports_stdin() {
  local player="${1:-$(detect_player)}"
  case "$player" in
    ffplay|mpv) return 0 ;;
    *) return 1 ;;
  esac
}

# Play audio from stdin (pipe) using ffplay or mpv
# Uses exec so the player replaces the subshell — PID tracking kills the right process
play_audio_stdin() {
  local player="${1:-$(detect_player)}"
  case "$player" in
    ffplay)
      exec ffplay -nodisp -autoexit -loglevel quiet - 2>/dev/null
      ;;
    mpv)
      exec mpv --no-video --really-quiet - 2>/dev/null
      ;;
  esac
}

# Play audio from a file using any supported player
# Uses exec so the player replaces the subshell — PID tracking kills the right process
play_audio_file() {
  local file="$1"
  local player="${2:-$(detect_player)}"
  case "$player" in
    ffplay)
      exec ffplay -nodisp -autoexit -loglevel quiet "$file" 2>/dev/null
      ;;
    mpv)
      exec mpv --no-video --really-quiet "$file" 2>/dev/null
      ;;
    afplay)
      exec afplay "$file" 2>/dev/null
      ;;
    paplay)
      exec paplay "$file" 2>/dev/null
      ;;
    aplay)
      exec aplay "$file" 2>/dev/null
      ;;
  esac
}

# Acquire playback lock (blocking - waits for other audio to finish)
# Recovers stale locks left by crashed processes
acquire_lock() {
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    if [[ -f "$PID_FILE" ]]; then
      # Lock held — check if the owning process is still alive
      local stale_pid
      stale_pid=$(cat "$PID_FILE" 2>/dev/null)
      if [[ -n "$stale_pid" ]] && ! kill -0 "$stale_pid" 2>/dev/null; then
        # Owner is dead — break stale lock
        rmdir "$LOCK_DIR" 2>/dev/null
        rm -f "$PID_FILE"
        continue
      fi
    else
      # Lock exists but no PID file — might be between acquire and write_pid
      # Wait briefly then recheck; if still no PID, assume stale
      sleep 0.5
      if [[ ! -f "$PID_FILE" ]] && ! mkdir "$LOCK_DIR" 2>/dev/null; then
        rmdir "$LOCK_DIR" 2>/dev/null
        continue
      fi
    fi
    sleep 0.1
  done
}

# Release playback lock
release_lock() {
  rmdir "$LOCK_DIR" 2>/dev/null
}

# Write current player PID for interruption support
write_pid() {
  echo "$1" > "$PID_FILE"
}

# Clean up PID file
clean_pid() {
  rm -f "$PID_FILE"
}
