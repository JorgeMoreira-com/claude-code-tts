# Claude Code TTS

Give your Claude Code AI assistant a voice with high-quality text-to-speech.

## Features

- High-quality, human-like speech
- Multiple voice options per provider
- Auto-cleanup of audio files
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

## How It Works

The plugin uses hooks to automatically trigger TTS at key moments:

- **SessionStart** - Announces when a new session begins
- **Stop** - Speaks a summary when Claude finishes a task
- **Notification** - Alerts you when background tasks complete

When using the `/claude-code-tts:tts` skill, Claude will also speak during tasks:

1. **Start** - Announces what it's about to do
2. **Progress** - Updates during file edits/reads
3. **End** - Summarizes the result

## Smart Summarization

By default, TTS uses Claude CLI (Haiku model) to create intelligent summaries of Claude's responses. This provides much better quality than simple text extraction.

### How It Works

| Mode | Latency | Quality | Cost |
|------|---------|---------|------|
| `TTS_SUMMARIZE=true` (default) | ~3-5 sec | Smart summary | Uses your Claude subscription |
| `TTS_SUMMARIZE=false` | Instant | First sentence only | Free |

### Disable Summarization (Optional)

If you prefer instant responses without the summarization latency, add to `~/.config/claude-code-tts/.env`:

```bash
TTS_SUMMARIZE=false     # Use simple first-sentence extraction
```

### Customize Summary Length

```bash
TTS_SUMMARY_WORDS=20    # Max words in summary (default: 15)
```

### Example

**Claude's response:**
> "I've analyzed the authentication module and identified three potential security vulnerabilities in the JWT validation logic. The token expiration check wasn't properly handling edge cases..."

**With summarization enabled:**
> "Found three JWT security vulnerabilities in the authentication module."

**Without summarization (default):**
> "I've analyzed the authentication module and identified three potential security vulnerabilities in the JWT validation logic."

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
│   ├── play-tts.sh              # Main TTS router
│   ├── play-tts-groq.sh         # Groq provider script
│   ├── play-tts-inworld.sh      # Inworld provider script
│   ├── summarize-with-claude.sh # Claude CLI summarization
│   ├── session-start.sh         # SessionStart hook handler
│   ├── stop-hook.sh             # Stop hook handler
│   ├── notification-hook.sh     # Notification hook handler
│   └── stop.sh                  # Kill audio playback
├── README.md
└── LICENSE
```

## Requirements

- [Claude Code CLI](https://claude.ai/code)
- `curl` (pre-installed on most systems)
- `jq` (for Inworld provider)
- Audio player: `afplay` (macOS), `paplay` (Linux/PulseAudio), or `aplay` (Linux/ALSA)

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
