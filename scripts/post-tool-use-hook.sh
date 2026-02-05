#!/usr/bin/env bash
#
# PostToolUse hook for Claude Code TTS
# Announces when certain tools complete (especially Bash commands)
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract tool name
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# Only announce for Bash commands
if [[ "$TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

# Get the command that was run
COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Check if command succeeded or failed
# tool_response contains stdout, stderr, and exit code info
STDERR=$(echo "$HOOK_INPUT" | jq -r '.tool_response.stderr // empty' 2>/dev/null)
EXIT_CODE=$(echo "$HOOK_INPUT" | jq -r '.tool_response.exit_code // 0' 2>/dev/null)

# Determine success/failure
if [[ "$EXIT_CODE" != "0" ]] || [[ -n "$STDERR" && "$STDERR" != "null" ]]; then
  STATUS="failed"
else
  STATUS="completed"
fi

# Parse the command to create a friendly description
BASE_CMD=$(echo "$COMMAND" | awk '{print $1}')

case "$BASE_CMD" in
  git)
    SUBCMD=$(echo "$COMMAND" | awk '{print $2}')
    case "$SUBCMD" in
      push)   MESSAGE="Push $STATUS" ;;
      pull)   MESSAGE="Pull $STATUS" ;;
      commit) MESSAGE="Commit $STATUS" ;;
      clone)  MESSAGE="Clone $STATUS" ;;
      merge)  MESSAGE="Merge $STATUS" ;;
      rebase) MESSAGE="Rebase $STATUS" ;;
      *)      MESSAGE="Git $SUBCMD $STATUS" ;;
    esac
    ;;
  npm|yarn|pnpm)
    SUBCMD=$(echo "$COMMAND" | awk '{print $2}')
    case "$SUBCMD" in
      install|i) MESSAGE="Dependencies installed" ;;
      test)
        if [[ "$STATUS" == "failed" ]]; then
          MESSAGE="Tests failed"
        else
          MESSAGE="Tests passed"
        fi
        ;;
      build)
        if [[ "$STATUS" == "failed" ]]; then
          MESSAGE="Build failed"
        else
          MESSAGE="Build succeeded"
        fi
        ;;
      *)         MESSAGE="$BASE_CMD $SUBCMD $STATUS" ;;
    esac
    ;;
  pytest|jest|mocha|vitest)
    if [[ "$STATUS" == "failed" ]]; then
      MESSAGE="Tests failed"
    else
      MESSAGE="Tests passed"
    fi
    ;;
  docker)
    SUBCMD=$(echo "$COMMAND" | awk '{print $2}')
    MESSAGE="Docker $SUBCMD $STATUS"
    ;;
  make)
    if [[ "$STATUS" == "failed" ]]; then
      MESSAGE="Build failed"
    else
      MESSAGE="Build complete"
    fi
    ;;
  cargo)
    SUBCMD=$(echo "$COMMAND" | awk '{print $2}')
    case "$SUBCMD" in
      build) MESSAGE="Cargo build $STATUS" ;;
      test)
        if [[ "$STATUS" == "failed" ]]; then
          MESSAGE="Tests failed"
        else
          MESSAGE="Tests passed"
        fi
        ;;
      *)     MESSAGE="Cargo $SUBCMD $STATUS" ;;
    esac
    ;;
  go)
    SUBCMD=$(echo "$COMMAND" | awk '{print $2}')
    case "$SUBCMD" in
      build) MESSAGE="Go build $STATUS" ;;
      test)
        if [[ "$STATUS" == "failed" ]]; then
          MESSAGE="Tests failed"
        else
          MESSAGE="Tests passed"
        fi
        ;;
      *)     MESSAGE="Go $SUBCMD $STATUS" ;;
    esac
    ;;
  *)
    # Skip other commands to avoid noise
    exit 0
    ;;
esac

# Speak the announcement
"$SCRIPT_DIR/play-tts.sh" "$MESSAGE" &

exit 0
