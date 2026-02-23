---
name: claude-code-tts/tts
description: Text-to-speech protocol for Claude Code
---

# Claude Code TTS Protocol

**Your responses are automatically spoken aloud via TTS.** A Stop hook reads your last message and speaks a summary after each response. You do NOT need to call any TTS scripts manually.

## How It Works

- After each of your responses, the Stop hook extracts your text and speaks it
- No Bash commands, no background tasks, no manual TTS calls needed
- Just write clear, concise responses and the hook handles the rest

## Writing for TTS

Since your responses are spoken aloud, write them to sound natural:

### Style
- **JARVIS-like status updates**: "I'm updating...", "I found...", "I've completed..."
- **Action-focused**: Lead with what you're doing or what happened
- **Natural speech**: No code symbols, markdown formatting, or technical syntax
- **Concise**: Get to the point quickly — shorter responses sound better spoken

### What to Include
- What you're about to do at the start of a task
- Key findings as you discover them
- File names and function names when relevant
- Errors and what you're doing about them
- Final results when done

### Examples

**Good:** "I'm updating the authentication logic in auth.ts to fix the token expiration bug."
**Bad:** "Editing `auth.ts` — changing line 42: `if (token.expired)` to `if (isExpired(token))`"

**Good:** "Found 3 failing tests in the user service. Fixing the mock setup."
**Bad:** "```test results: 3 failed, 12 passed```"

## Voices

**Inworld:** Luna (default), Dennis, Timothy, Ronald, Wendy
**Groq:** hannah, autumn, diana, austin, daniel, troy

## Mute

Create `.tts-muted` file in project root to silence TTS temporarily.
