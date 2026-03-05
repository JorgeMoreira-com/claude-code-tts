# Claude Code TTS

Give your Claude Code AI assistant a voice with high-quality text-to-speech.

## Features

- High-quality, human-like speech
- **Streaming audio** — pipes directly to player with no temp files (ffplay/mpv)
- **Smart interruption** — TTS stops instantly when you submit a new prompt
- **Status line** — see TTS provider, voice, and playback state in the status bar
- Multiple voice options per provider
- Works on macOS, Linux, and WSL
- Choose between providers based on quality and cost

## Providers

| Provider | Model | Price | Quality | Latency | Default |
|----------|-------|-------|---------|---------|---------|
| Inworld | TTS 1.5 Max | $10/1M chars | #1 ranked | ~200ms | ✓ |
| Inworld | TTS 1.5 Mini | $5/1M chars | Good | ~120ms | |
| Groq | Orpheus | $22/1M chars | Good | Fast | |

**Default configuration:** Inworld provider with Luna voice and TTS 1.5 Max model.

## Installation

### 1. Install the Plugin

```bash
/install claude-code-tts
```

### 2. Set Up Your Provider

**Option A: Interactive setup (easiest)**

After installing the plugin, run:
```
/claude-code-tts:setup
```

Claude will guide you through selecting a provider and entering your API key.

**Option B: Manual configuration**

See provider-specific sections below.

### 3. Restart Claude Code

The TTS will automatically activate on the next session.

> **Note:** If a project has custom `enabledPlugins` in its `.claude/settings.json`, you'll need to add `"claude-code-tts@claude-code-tts": true` to that project's config.

## Provider Configuration

### Inworld (Default)

Best quality TTS at the lowest price. This is the default provider.

1. Sign up at [platform.inworld.ai](https://platform.inworld.ai/)
2. Get your API key and base64 encode it:
   ```bash
   echo -n 'your-api-key' | base64
   ```
3. Configure:
   ```bash
   mkdir -p ~/.config/claude-code-tts
   cat > ~/.config/claude-code-tts/.env << 'EOF'
   TTS_PROVIDER=inworld
   INWORLD_API_KEY=your-base64-encoded-key
   INWORLD_MODEL=inworld-tts-1.5-max
   INWORLD_VOICE=Luna
   EOF
   chmod 600 ~/.config/claude-code-tts/.env
   ```

**Inworld Voices:**

| Voice | Gender |
|-------|--------|
| `Luna` | Female (default) |
| `Dennis` | Male |
| `Timothy` | Male |
| `Ronald` | Male |
| `Wendy` | Female |

**Inworld Models:**

| Model | Use Case |
|-------|----------|
| `inworld-tts-1.5-max` | Best quality (default) |
| `inworld-tts-1.5-mini` | Faster, lower latency |

### Groq

Sign up at [console.groq.com](https://console.groq.com/keys) (free tier available)

```bash
mkdir -p ~/.config/claude-code-tts
cat > ~/.config/claude-code-tts/.env << 'EOF'
TTS_PROVIDER=groq
GROQ_API_KEY=your-api-key-here
EOF
chmod 600 ~/.config/claude-code-tts/.env
```

Or use an environment variable in your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
export GROQ_API_KEY='your-api-key-here'
```

**Groq Voices:**

| Voice | Gender |
|-------|--------|
| `hannah` | Female (default) |
| `autumn` | Female |
| `diana` | Female |
| `austin` | Male |
| `daniel` | Male |
| `troy` | Male |

## Streaming Audio

When `ffplay` (from ffmpeg) or `mpv` is installed, audio is piped directly from the API to the player with no temporary files. This reduces latency and disk I/O.

- **Groq**: `curl | ffplay` — true end-to-end streaming, audio starts before download completes
- **Inworld**: base64 decode piped to ffplay — no temp file, but API response is still buffered (JSON format)
- **Fallback**: if only `afplay`/`paplay`/`aplay` are available, temp files are used (same as before)

Player detection order: `ffplay` > `mpv` > `afplay` > `paplay` > `aplay`. Override with `TTS_PLAYER` in config.

```bash
# Install ffplay (recommended)
brew install ffmpeg    # macOS
apt install ffmpeg     # Linux
```

## Smart Interruption

TTS playback is automatically killed when you submit a new prompt. No more waiting for long audio to finish before Claude responds.

The `UserPromptSubmit` hook sends SIGTERM to the active player process and releases the playback lock, so the next response can play immediately.

You can also manually stop all audio:
```bash
scripts/stop.sh
```

## Status Line

Show TTS state in the Claude Code status bar. Output format: `TTS: inworld/max/Luna` or `TTS: groq/hannah MUTED >>>`.

Add to `~/.claude/settings.json` (uses version-resilient path that survives plugin updates):
```json
{
  "statusLine": {
    "type": "command",
    "command": "bash -c '\"$(ls -td ~/.claude/plugins/cache/claude-code-tts/claude-code-tts/*/ 2>/dev/null | head -1)scripts/tts-status.sh\"'"
  }
}
```

## How It Works

The plugin uses hooks to automatically trigger TTS at key moments:

| Hook | Trigger | Example |
|------|---------|---------|
| **SessionStart** | New session begins | "TTS ready" |
| **Stop** | Claude finishes responding | Summarizes the response |
| **Notification** | Permission or idle alerts | "Permission needed" |
| **SubagentStop** | Spawned agent finishes | "Research agent completed. Found 3 issues." |
| **PreToolUse** | Before running commands | "Installing dependencies" |
| **PostToolUse** | After successful commands | "Build succeeded" |
| **PostToolUseFailure** | After failed commands | "Tests failed" |
| **UserPromptSubmit** | User sends a new prompt | Kills active TTS playback |

The tool hooks recognize common commands like git, npm, pytest, docker, cargo, and go, announcing them in natural language with configurable verbosity.

When using the `/claude-code-tts:tts` skill, Claude will also speak during tasks as it works.

## Smart Summarization

The plugin uses a 3-tier strategy to produce clean spoken summaries:

### How It Works

| Strategy | When | Latency | Quality |
|----------|------|---------|---------|
| **TTS Markers** (primary) | Claude includes `<!-- TTS: "..." -->` in response | Instant | Best — Claude writes the spoken version |
| **Claude CLI** (fallback) | Marker missing, `TTS_SUMMARIZE=true` | ~3-5 sec | Good — Haiku summarizes |
| **First sentence** (last resort) | Claude CLI fails or `TTS_SUMMARIZE=false` | Instant | Basic |

The TTS skill instructs Claude to include an invisible HTML comment marker at the end of each response with a natural, spoken summary. The Stop hook extracts this marker instantly — no API call, no markdown parsing, no tables or code leaking into speech.

When the marker is missing (e.g., Claude didn't follow instructions), the plugin falls back to Claude CLI summarization, then to first-sentence extraction.

### Configuration

```bash
TTS_SUMMARIZE=false     # Skip Claude CLI fallback, use first-sentence only
TTS_SUMMARY_WORDS=20    # Max words for Claude CLI summaries (default: 25)
```

### Reduce Hook Chatter

```bash
TTS_VERBOSITY=normal    # quiet, normal (default), verbose
```

- `quiet`: speaks final responses and failures, minimizes intermediate announcements
- `normal`: balanced start/stop and major tool announcements
- `verbose`: also announces generic shell activity and richer idle details

### Example

**Claude's response** (what you see):
> I've analyzed the authentication module and found three security vulnerabilities...
> | Issue | Severity | ... (table follows)

**What TTS speaks** (from the invisible marker):
> "Found three security vulnerabilities in the authentication module. The JWT validation has missing expiration checks."

## Mute/Unmute

```bash
# Mute TTS in current project
touch .tts-muted

# Unmute
rm .tts-muted

# Mute globally
touch ~/.tts-muted
```

## Pricing Comparison

| Provider | Model | Cost per 1M chars |
|----------|-------|-------------------|
| Inworld | TTS 1.5 Mini | $5 |
| Inworld | TTS 1.5 Max | $10 |
| Groq | Orpheus | $22 |

**Typical usage costs:**

| Usage | Inworld Max | Groq |
|-------|-------------|------|
| 1,000 messages (~100 chars each) | ~$1.00 | ~$2.20 |
| Typical dev session | < $0.05 | < $0.10 |
| Heavy daily use | < $0.50/day | < $1/day |

## Plugin Structure

```
claude-code-tts/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── hooks/
│   └── hooks.json           # Hook definitions
├── skills/
│   ├── tts/
│   │   └── SKILL.md         # TTS protocol skill
│   └── setup/
│       └── SKILL.md         # Interactive setup wizard
├── scripts/
│   ├── audio-utils.sh               # Shared audio utilities (player detection, streaming, locking)
│   ├── play-tts.sh                  # Main TTS router
│   ├── play-tts-groq.sh            # Groq provider script
│   ├── play-tts-inworld.sh         # Inworld provider script
│   ├── summarize-with-claude.sh    # Claude CLI summarization
│   ├── session-start.sh            # SessionStart hook handler
│   ├── stop-hook.sh                # Stop hook handler
│   ├── notification-hook.sh        # Notification hook handler
│   ├── subagent-stop-hook.sh       # SubagentStop hook handler
│   ├── pre-tool-use-hook.sh        # PreToolUse hook handler
│   ├── post-tool-use-hook.sh       # PostToolUse hook handler
│   ├── post-tool-use-failure-hook.sh # PostToolUseFailure hook handler
│   ├── user-prompt-hook.sh         # UserPromptSubmit hook (kills TTS on new prompt)
│   ├── tool-announcements.sh       # Shared tool announcement logic
│   ├── tts-status.sh               # Status line output script
│   └── stop.sh                     # Kill audio playback
├── README.md
└── LICENSE
```

## Platform Support

| Platform | Status | Audio Player |
|----------|--------|--------------|
| **macOS** | Fully supported | `ffplay` (streaming) > `mpv` > `afplay` (built-in) |
| **Linux** | Fully supported | `ffplay` > `mpv` > `paplay` > `aplay` |
| **WSL** | Supported | Requires audio player configured |
| **Windows** | Not supported | No native bash support |

The plugin uses cross-platform locking (`mkdir` atomic operation) to queue audio playback, preventing overlapping TTS messages on all supported platforms.

## Requirements

- [Claude Code CLI](https://claude.ai/code)
- `curl` (pre-installed on most systems)
- `jq` (required for hook parsing and Inworld provider, install via `brew install jq` or `apt install jq`)
- Audio player: `ffplay` (recommended, enables streaming) or `mpv`, `afplay` (macOS), `paplay`/`aplay` (Linux)

## Troubleshooting

**No audio playing**
- Check API key is configured: `cat ~/.config/claude-code-tts/.env`
- Test manually: `~/.claude/plugins/cache/claude-code-tts/claude-code-tts/*/scripts/play-tts.sh "test"`

**API errors**
- Verify your API key is valid
- For Inworld: ensure the key is base64 encoded
- Check rate limits on free tier

**Claude not speaking**
- Run `/plugins` to verify installation
- Restart Claude Code session

**Plugin not active in specific project**
- If the project has `.claude/settings.json` with custom `enabledPlugins`, add:
  ```json
  "enabledPlugins": {
    "claude-code-tts@claude-code-tts": true
  }
  ```
- Or remove the `enabledPlugins` section to inherit global settings

## License

MIT License - see [LICENSE](LICENSE)

## Credits

- [Inworld AI](https://inworld.ai) - Recommended TTS provider
- [Canopy Labs Orpheus](https://huggingface.co/canopylabs/orpheus-3b-0.1-ft) - Groq TTS model
- [Groq](https://groq.com) - Alternative inference provider
