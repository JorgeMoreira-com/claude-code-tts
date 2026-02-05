#!/usr/bin/env bash
#
# PreToolUse hook for Claude Code TTS
# Announces before certain tools run (Bash commands, etc.)
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Read hook input from stdin
HOOK_INPUT=$(cat)

# Extract tool name and input
TOOL_NAME=$(echo "$HOOK_INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# Only announce for Bash commands (most interesting to hear about)
if [[ "$TOOL_NAME" != "Bash" ]]; then
  exit 0
fi

# Get the command being run
COMMAND=$(echo "$HOOK_INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [[ -z "$COMMAND" ]]; then
  exit 0
fi

# Parse the command to create a friendly description
# Extract the base command (first word or known command pattern)
BASE_CMD=$(echo "$COMMAND" | awk '{print $1}')

case "$BASE_CMD" in
  git)
    SUBCMD=$(echo "$COMMAND" | awk '{print $2}')
    case "$SUBCMD" in
      push)   MESSAGE="Pushing to remote repository" ;;
      pull)   MESSAGE="Pulling from remote repository" ;;
      commit) MESSAGE="Creating a git commit" ;;
      clone)  MESSAGE="Cloning a repository" ;;
      checkout) MESSAGE="Switching branches" ;;
      merge)  MESSAGE="Merging branches" ;;
      rebase) MESSAGE="Rebasing commits" ;;
      *)      MESSAGE="Running git $SUBCMD" ;;
    esac
    ;;
  npm|yarn|pnpm)
    SUBCMD=$(echo "$COMMAND" | awk '{print $2}')
    case "$SUBCMD" in
      install|i) MESSAGE="Installing dependencies" ;;
      run)       MESSAGE="Running npm script" ;;
      test)      MESSAGE="Running tests" ;;
      build)     MESSAGE="Building the project" ;;
      *)         MESSAGE="Running $BASE_CMD $SUBCMD" ;;
    esac
    ;;
  docker)
    SUBCMD=$(echo "$COMMAND" | awk '{print $2}')
    MESSAGE="Running docker $SUBCMD"
    ;;
  pytest|jest|mocha|vitest)
    MESSAGE="Running tests"
    ;;
  make)
    MESSAGE="Running make build"
    ;;
  cargo)
    SUBCMD=$(echo "$COMMAND" | awk '{print $2}')
    MESSAGE="Running cargo $SUBCMD"
    ;;
  go)
    SUBCMD=$(echo "$COMMAND" | awk '{print $2}')
    MESSAGE="Running go $SUBCMD"
    ;;
  python|python3)
    MESSAGE="Running Python script"
    ;;
  node)
    MESSAGE="Running Node script"
    ;;
  curl|wget)
    MESSAGE="Fetching from URL"
    ;;
  *)
    # For other commands, just skip to avoid noise
    exit 0
    ;;
esac

# Speak the announcement
"$SCRIPT_DIR/play-tts.sh" "$MESSAGE" &

exit 0
