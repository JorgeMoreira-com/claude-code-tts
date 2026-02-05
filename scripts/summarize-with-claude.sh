#!/usr/bin/env bash
#
# Claude Code TTS - Summarization Script
# Uses Claude CLI to create concise TTS-friendly summaries
#
# Usage: summarize-with-claude.sh "long text to summarize" [max_words]
#

TEXT="$1"
MAX_WORDS="${2:-25}"

# Validate input
if [[ -z "$TEXT" ]]; then
  echo "Usage: $0 \"text\" [max_words]"
  exit 1
fi

# Skip if text is already short enough
WORD_COUNT=$(echo "$TEXT" | wc -w | tr -d ' ')
if [[ "$WORD_COUNT" -le "$MAX_WORDS" ]]; then
  echo "$TEXT"
  exit 0
fi

# Build a JARVIS-style prompt for natural, thorough TTS summaries
PROMPT="You are JARVIS providing a status update. Summarize in ${MAX_WORDS} words or fewer.

RULES:
- Speak in first person as JARVIS: \"I have completed...\" \"I found...\" \"I've updated...\"
- Include key details: file names, function names, error types, counts
- Make it speakable: spell out acronyms (API = A P I, JWT = J W T), no code symbols
- Prioritize: outcome first, then key details, then context
- Sound natural and conversational, not robotic
- No questions, no offers to help, just the status update

EXAMPLES:
- \"I've completed the authentication module. Implemented OAuth with Google and GitHub, added Redis session storage, and all tests are passing.\"
- \"I found three security vulnerabilities in the JWT validation. The token expiration and clock sync issues need attention.\"
- \"I've updated the user controller at src/controllers/user.ts. Added input validation and rate limiting.\"

TEXT TO SUMMARIZE:
$TEXT

JARVIS STATUS UPDATE:"

# Use Claude CLI with haiku model for speed and cost efficiency
# --print: non-interactive output mode
# --model haiku: fastest/cheapest model, perfect for summarization
# --tools "": disable all tools, we just want text generation
SUMMARY=$(echo "$PROMPT" | claude --print --model haiku --tools "" 2>/dev/null | head -1)

# If Claude CLI fails, fall back to first sentence extraction
if [[ -z "$SUMMARY" || $? -ne 0 ]]; then
  # Simple fallback: extract first sentence
  SUMMARY=$(echo "$TEXT" | sed 's/\. .*/\./' | head -c 200)
fi

# Clean up the output - remove any extra whitespace
echo "$SUMMARY" | tr '\n' ' ' | sed 's/  */ /g; s/^ *//; s/ *$//'
