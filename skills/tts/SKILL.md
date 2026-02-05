---
name: claude-code-tts/tts
description: Text-to-speech protocol for Claude Code
---

# Claude Code TTS Protocol

**Announce actions as you work using TTS.** This keeps the user informed of progress, especially when they're not watching the terminal.

## TTS Command

```bash
Bash: ${CLAUDE_PLUGIN_ROOT}/scripts/play-tts.sh "[message]"
```

## When to Announce

### Task Lifecycle (Required)
| Point | What to Say |
|-------|-------------|
| **Start** | What you're about to do: "Implementing the login feature" |
| **End** | The result: "Login feature complete. Tests passing." |

### During Work (Announce All)
| Action | Example |
|--------|---------|
| **File reads** | "Reading the user controller" |
| **File edits** | "Updating authentication logic in auth.ts" |
| **File creation** | "Creating new test file for user service" |
| **Bash commands** | "Running npm install" |
| **Git operations** | "Committing changes to main" |
| **Test runs** | "Running the test suite" |
| **Search/grep** | "Searching for database connection code" |
| **Web searches** | "Researching React hooks best practices" |
| **API calls** | "Fetching repository data from GitHub" |
| **Spawning agents** | "Starting a research agent to explore the codebase" |
| **Planning** | "Analyzing the project structure" |

### Special Events (Always Announce)
| Event | Example |
|-------|---------|
| **Errors** | "Build failed. Checking the error log." |
| **Retries** | "First approach failed. Trying alternative method." |
| **Waiting for input** | "I need your decision before continuing." |
| **Discoveries** | "Found a potential issue in the config file." |
| **Completions** | "All tests passing. Ready for review." |

## Rules

1. **Never skip announcements** - Keep user informed of all actions
2. **Keep messages concise** - Under 150 characters, natural speech
3. **Be specific** - Include file names, function names, counts
4. **Announce errors immediately** - Don't leave user wondering
5. **Group rapid actions** - "Reading three config files" not three separate calls

## Message Style

Write as JARVIS giving status updates:
- First person: "I'm updating...", "I found...", "I've completed..."
- Natural speech: No code symbols, spell out acronyms
- Action-focused: Lead with verbs

**Good:** "I'm updating the authentication logic in auth.ts to fix the token expiration bug."
**Bad:** "Editing auth.ts"

## Voices

**Inworld:** Luna (default), Dennis, Timothy, Ronald, Wendy
**Groq:** hannah, autumn, diana, austin, daniel, troy

## Mute

Create `.tts-muted` file in project root to silence TTS temporarily.
