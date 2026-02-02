---
name: claude-code-tts/setup
description: Interactive setup wizard for Claude Code TTS plugin
---

# TTS Setup Wizard

Guide the user through configuring the Claude Code TTS plugin.

## Step 1: Check Current Configuration

Run this command to check if already configured:

```bash
if [[ -f ~/.config/claude-code-tts/.env ]]; then
  echo "CONFIG_EXISTS=true"
  grep -q "GROQ_API_KEY" ~/.config/claude-code-tts/.env && echo "KEY_SET=true" || echo "KEY_SET=false"
else
  echo "CONFIG_EXISTS=false"
fi
```

If already configured, ask user if they want to reconfigure.

## Step 2: Get API Key

Use the AskUserQuestion tool to collect the API key:

**Question:** "Enter your API key (get one free at console.groq.com/keys)"

**Important:** The user will select "Other" and paste their key.

## Step 3: Create Config

Once you have the API key, run:

```bash
mkdir -p ~/.config/claude-code-tts
echo "GROQ_API_KEY=USER_API_KEY_HERE" > ~/.config/claude-code-tts/.env
chmod 600 ~/.config/claude-code-tts/.env
echo "Config saved to ~/.config/claude-code-tts/.env"
```

Replace `USER_API_KEY_HERE` with the actual key provided.

## Step 4: Test the Configuration

Test the API key works:

```bash
source ~/.config/claude-code-tts/.env
curl -s -w "%{http_code}" -o /dev/null \
  -X POST "https://api.groq.com/openai/v1/audio/speech" \
  -H "Authorization: Bearer $GROQ_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"canopylabs/orpheus-v1-english","voice":"hannah","input":"Setup complete","response_format":"wav"}'
```

- If response is `200`: Success! Tell the user TTS is ready.
- If response is `401`: Invalid API key, ask user to check and retry.
- If response is `429`: Rate limited, but key is valid.

## Step 5: Voice Selection (Optional)

Ask the user if they want to set a default voice:

| Voice | Gender |
|-------|--------|
| hannah | Female (default) |
| autumn | Female |
| diana | Female |
| austin | Male |
| daniel | Male |
| troy | Male |

If they choose a voice other than hannah, add to config:
```bash
echo "TTS_VOICE=chosen_voice" >> ~/.config/claude-code-tts/.env
```

## Completion

Tell the user:
- TTS is configured and ready
- Restart Claude Code to activate the hooks
- They can mute anytime with `touch .tts-muted`
