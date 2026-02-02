# Claude Code TTS

Give your Claude Code AI assistant a voice with high-quality text-to-speech.

## Features

- High-quality, human-like speech
- 6 voice options (3 female, 3 male)
- Auto-cleanup of audio files
- Works on macOS, Linux, and WSL
- Affordable pricing (~$22 per million characters)

## Installation

### 1. Get an API Key

**Default Provider: Groq**

Sign up at [console.groq.com](https://console.groq.com/keys) (free tier available)

### 2. Set Your API Key

**Option A: Interactive setup (easiest)**

After installing the plugin, run:
```
/claude-code-tts:setup
```

Claude will guide you through entering your API key and testing the configuration.

**Option B: Config file (manual)**

```bash
mkdir -p ~/.config/claude-code-tts
echo "GROQ_API_KEY=your-api-key-here" > ~/.config/claude-code-tts/.env
chmod 600 ~/.config/claude-code-tts/.env
```

**Option C: Environment variable**

Add to your shell profile (`~/.zshrc` or `~/.bashrc`):

```bash
export GROQ_API_KEY='your-api-key-here'
```

### 3. Install the Plugin

```bash
/install claude-code-tts
```

### 4. Restart Claude Code

The TTS will automatically activate on the next session.

> **Note:** If a project has custom `enabledPlugins` in its `.claude/settings.json`, you'll need to add `"claude-code-tts@claude-code-tts": true` to that project's config.

## How It Works

Once installed, Claude will speak at three points during tasks:

1. **Start** - Announces what it's about to do
2. **Progress** - Updates during file edits/reads
3. **End** - Summarizes the result

## Mute/Unmute

```bash
# Mute TTS in current project
touch .tts-muted

# Unmute
rm .tts-muted

# Mute globally
touch ~/.tts-muted
```

## Available Voices

| Voice | Gender |
|-------|--------|
| `hannah` | Female (default) |
| `autumn` | Female |
| `diana` | Female |
| `austin` | Male |
| `daniel` | Male |
| `troy` | Male |

## Pricing

The default TTS provider costs **~$22 per million characters**.

| Usage | Cost |
|-------|------|
| 1,000 messages (~100 chars each) | ~$2.20 |
| Typical dev session | < $0.10 |
| Heavy daily use | < $1/day |

## Plugin Structure

```
claude-code-tts/
├── .claude-plugin/
│   └── plugin.json       # Plugin manifest
├── hooks/
│   └── hooks.json        # SessionStart hook
├── skills/
│   ├── tts/
│   │   └── SKILL.md      # TTS protocol
│   └── setup/
│       └── SKILL.md      # Interactive setup wizard
├── scripts/
│   ├── play-tts.sh       # Main router
│   ├── play-tts-groq.sh  # Provider script
│   └── stop.sh           # Kill audio
├── README.md
└── LICENSE
```

## Requirements

- [Claude Code CLI](https://claude.ai/code)
- `curl` (pre-installed on most systems)
- Audio player: `afplay` (macOS), `paplay` (Linux/PulseAudio), or `aplay` (Linux/ALSA)

## Troubleshooting

**No audio playing**
- Check API key is configured: `cat ~/.config/claude-code-tts/.env` or `echo $GROQ_API_KEY`
- Test manually: `~/.claude/plugins/claude-code-tts/scripts/play-tts.sh "test"`

**API errors**
- Verify your API key is valid
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

- [Canopy Labs Orpheus](https://huggingface.co/canopylabs/orpheus-3b-0.1-ft) - TTS model
- [Groq](https://groq.com) - Default inference provider
