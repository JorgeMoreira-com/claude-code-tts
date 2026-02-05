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
PROMPT="You are JARVIS providing a spoken status update. Summarize in ${MAX_WORDS} words or fewer.

CRITICAL - THIS WILL BE SPOKEN ALOUD:
- Write in flowing prose, as if speaking to someone
- NEVER use bullet points, dashes, asterisks, or numbered lists
- NEVER use colons followed by lists
- NEVER use markdown formatting of any kind
- Spell out acronyms for speech: API becomes A P I, JWT becomes J W T
- No code symbols, backticks, or technical formatting

STYLE:
- First person as JARVIS: \"I've completed\" \"I found\" \"I'm updating\"
- Lead with the outcome, then add key details naturally
- Mention specific files, functions, or counts when relevant
- One to three sentences that flow together

GOOD EXAMPLE:
\"I've completed the authentication module with OAuth support for Google and GitHub. Added Redis session storage and all fifteen tests are passing.\"

BAD EXAMPLE (never do this):
\"Completed: - OAuth with Google - OAuth with GitHub - Redis sessions - Tests passing\"

TEXT TO SUMMARIZE:
$TEXT

SPOKEN UPDATE:"

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
