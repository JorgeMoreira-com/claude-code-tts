---
name: claude-code-tts/tts
description: Text-to-speech protocol for Claude Code
---

# Claude Code TTS Protocol

**Your responses are automatically spoken aloud via TTS.** End every response with a TTS marker containing a spoken summary. The Stop hook extracts and speaks it.

## TTS Marker (Required)

End every response with this HTML comment marker:

```
<!-- TTS: "Your spoken summary here" -->
```

The marker is invisible to the user but the Stop hook extracts and speaks it instantly.

### Rules
- **Always include the marker** as the very last line of your response
- Write 1-2 sentences of natural, flowing speech inside the quotes
- No code symbols, backticks, markdown, bullet points, or technical syntax
- Spell out acronyms: API becomes "A P I", JWT becomes "J W T"
- First person JARVIS style: "I've completed...", "I found...", "I'm updating..."
- Lead with the outcome, then key details
- Mention specific file names, function names, or counts when relevant

### Examples

Response about fixing a bug:
```
<!-- TTS: "I've fixed the token expiration bug in auth.ts by adding a proper null check on line 47." -->
```

Response with a table of results:
```
<!-- TTS: "All four tests passed. Streaming audio, smart interruption, status line, and the stop script are all working correctly." -->
```

Response about an error:
```
<!-- TTS: "The build failed due to a missing dependency. I'm installing lodash now and retrying." -->
```

### When to skip the marker
- If your response is a single short sentence that's already TTS-friendly, the marker is optional
- Never include a marker in tool-only responses (no visible text)

## Voices

**Inworld:** Luna (default), Dennis, Timothy, Ronald, Wendy
**Groq:** hannah, autumn, diana, austin, daniel, troy

## Mute

Create `.tts-muted` file in project root to silence TTS temporarily.
