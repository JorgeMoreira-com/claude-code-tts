#!/usr/bin/env bash
#
# Shared message generation for tool hooks.
#

CONFIG_FILE="$HOME/.config/claude-code-tts/.env"
if [[ -f "$CONFIG_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
fi

tts_verbosity() {
  local level="${TTS_VERBOSITY:-normal}"
  level=$(echo "$level" | tr '[:upper:]' '[:lower:]')
  case "$level" in
    quiet|normal|verbose) echo "$level" ;;
    *) echo "normal" ;;
  esac
}

tool_is_bash() {
  [[ "$1" == "Bash" ]]
}

tool_base_cmd() {
  echo "$1" | awk '{print $1}'
}

tool_sub_cmd() {
  echo "$1" | awk '{print $2}'
}

pre_tool_message() {
  local command="$1"
  local verbosity
  verbosity="$(tts_verbosity)"

  if [[ "$verbosity" == "quiet" ]]; then
    return 0
  fi

  local base_cmd
  local subcmd
  base_cmd="$(tool_base_cmd "$command")"
  subcmd="$(tool_sub_cmd "$command")"

  case "$base_cmd" in
    git)
      case "$subcmd" in
        push) echo "Pushing to remote repository" ;;
        pull) echo "Pulling from remote repository" ;;
        commit) echo "Creating a git commit" ;;
        clone) echo "Cloning a repository" ;;
        checkout) echo "Switching branches" ;;
        merge) echo "Merging branches" ;;
        rebase) echo "Rebasing commits" ;;
        *) [[ "$verbosity" == "verbose" ]] && echo "Running git ${subcmd:-command}" ;;
      esac
      ;;
    npm|yarn|pnpm)
      case "$subcmd" in
        install|i) echo "Installing dependencies" ;;
        run) echo "Running npm script" ;;
        test) echo "Running tests" ;;
        build) echo "Building the project" ;;
        *) [[ "$verbosity" == "verbose" ]] && echo "Running $base_cmd ${subcmd:-command}" ;;
      esac
      ;;
    docker)
      [[ "$verbosity" == "verbose" ]] && echo "Running docker ${subcmd:-command}" || echo "Running docker task"
      ;;
    pytest|jest|mocha|vitest)
      echo "Running tests"
      ;;
    make)
      [[ "$verbosity" == "verbose" ]] && echo "Running make ${subcmd:-task}" || echo "Running make task"
      ;;
    cargo)
      [[ "$verbosity" == "verbose" ]] && echo "Running cargo ${subcmd:-command}" || echo "Running cargo task"
      ;;
    go)
      [[ "$verbosity" == "verbose" ]] && echo "Running go ${subcmd:-command}" || echo "Running go task"
      ;;
    python|python3)
      [[ "$verbosity" == "verbose" ]] && echo "Running Python script"
      ;;
    node)
      [[ "$verbosity" == "verbose" ]] && echo "Running Node script"
      ;;
    curl|wget)
      [[ "$verbosity" == "verbose" ]] && echo "Fetching from URL"
      ;;
    *)
      [[ "$verbosity" == "verbose" ]] && echo "Running shell command"
      ;;
  esac
}

post_tool_success_message() {
  local command="$1"
  local verbosity
  verbosity="$(tts_verbosity)"

  if [[ "$verbosity" == "quiet" ]]; then
    return 0
  fi

  local base_cmd
  local subcmd
  base_cmd="$(tool_base_cmd "$command")"
  subcmd="$(tool_sub_cmd "$command")"

  case "$base_cmd" in
    git)
      case "$subcmd" in
        push) echo "Push completed" ;;
        pull) echo "Pull completed" ;;
        commit) echo "Commit completed" ;;
        clone) echo "Clone completed" ;;
        merge) echo "Merge completed" ;;
        rebase) echo "Rebase completed" ;;
        *) [[ "$verbosity" == "verbose" ]] && echo "Git ${subcmd:-command} completed" ;;
      esac
      ;;
    npm|yarn|pnpm)
      case "$subcmd" in
        install|i) echo "Dependencies installed" ;;
        test) echo "Tests passed" ;;
        build) echo "Build succeeded" ;;
        *) [[ "$verbosity" == "verbose" ]] && echo "$base_cmd ${subcmd:-command} completed" ;;
      esac
      ;;
    pytest|jest|mocha|vitest)
      echo "Tests passed"
      ;;
    docker)
      [[ "$verbosity" == "verbose" ]] && echo "Docker ${subcmd:-command} completed" || echo "Docker task completed"
      ;;
    make)
      [[ "$subcmd" == "test" ]] && echo "Tests passed" || echo "Build complete"
      ;;
    cargo)
      case "$subcmd" in
        test) echo "Tests passed" ;;
        build) echo "Cargo build completed" ;;
        *) [[ "$verbosity" == "verbose" ]] && echo "Cargo ${subcmd:-command} completed" ;;
      esac
      ;;
    go)
      case "$subcmd" in
        test) echo "Tests passed" ;;
        build) echo "Go build completed" ;;
        *) [[ "$verbosity" == "verbose" ]] && echo "Go ${subcmd:-command} completed" ;;
      esac
      ;;
    *)
      [[ "$verbosity" == "verbose" ]] && echo "Shell command completed"
      ;;
  esac
}

post_tool_failure_message() {
  local command="$1"
  local verbosity
  verbosity="$(tts_verbosity)"

  local base_cmd
  local subcmd
  base_cmd="$(tool_base_cmd "$command")"
  subcmd="$(tool_sub_cmd "$command")"

  case "$base_cmd" in
    npm|yarn|pnpm|pytest|jest|mocha|vitest|cargo|go)
      if [[ "$subcmd" == "test" || "$base_cmd" =~ ^(pytest|jest|mocha|vitest)$ ]]; then
        echo "Tests failed"
      else
        echo "$base_cmd command failed"
      fi
      ;;
    make)
      [[ "$subcmd" == "test" ]] && echo "Tests failed" || echo "Build failed"
      ;;
    git)
      echo "Git ${subcmd:-command} failed"
      ;;
    docker)
      echo "Docker ${subcmd:-command} failed"
      ;;
    *)
      if [[ "$verbosity" == "quiet" ]]; then
        echo "Command failed"
      else
        echo "Shell command failed"
      fi
      ;;
  esac
}
