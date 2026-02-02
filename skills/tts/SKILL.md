---
name: claude-code-tts/tts
description: Text-to-speech protocol for Claude Code
---

# Claude Code TTS Protocol

**Execute TTS at THREE points for every task:**

1. **Start**: `Bash: ${CLAUDE_PLUGIN_ROOT}/scripts/play-tts.sh "[what you're doing]"`
2. **Progress**: `Bash: ${CLAUDE_PLUGIN_ROOT}/scripts/play-tts.sh "[file edits, reads, findings]"`
3. **End**: `Bash: ${CLAUDE_PLUGIN_ROOT}/scripts/play-tts.sh "[result]"`

**Progress updates required for:**
- Each file edit (announce file + change)
- Each file read when exploring
- Multi-step operations
- Search results

**Rules:**
- Never skip start/progress/end TTS
- Keep messages under 150 characters
- Always announce errors

**Voices:** hannah (default), autumn, diana, austin, daniel, troy

**Mute:** Create `.tts-muted` file in project root to silence TTS
