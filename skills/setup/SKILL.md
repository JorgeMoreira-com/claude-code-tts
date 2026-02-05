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
  cat ~/.config/claude-code-tts/.env | grep -E "^(TTS_PROVIDER|GROQ_API_KEY|INWORLD_API_KEY|TTS_VOICE|INWORLD_VOICE|INWORLD_MODEL)=" | sed 's/\(.*_KEY=\).*/\1***/'
else
  echo "CONFIG_EXISTS=false"
fi
```

If already configured, ask user if they want to reconfigure or switch providers.

## Step 2: Choose Provider

Use the AskUserQuestion tool to ask which provider:

**Question:** "Which TTS provider would you like to use?"

| Provider | Model | Price | Quality |
|----------|-------|-------|---------|
| Inworld | TTS 1.5 Max | $10/1M chars | #1 ranked (Recommended) |
| Inworld | TTS 1.5 Mini | $5/1M chars | Fast, good quality |
| Groq | Orpheus | $22/1M chars | Good |

**Options:**
1. Inworld (Recommended) - Higher quality, lower cost
2. Groq - Current default

## Helper: Update Config Key

Use this function to update or add a key while preserving other settings:

```bash
update_config_key() {
  local key="$1" value="$2"
  local file="$HOME/.config/claude-code-tts/.env"
  mkdir -p "$(dirname "$file")"
  if [[ -f "$file" ]] && grep -q "^${key}=" "$file"; then
    sed -i '' "s|^${key}=.*|${key}=${value}|" "$file"
  else
    echo "${key}=${value}" >> "$file"
  fi
}
```

## Step 3a: Groq Setup (if selected)

### Get API Key

Check if Groq key already exists:
```bash
grep -q "^GROQ_API_KEY=." ~/.config/claude-code-tts/.env 2>/dev/null && echo "GROQ_KEY_EXISTS=true" || echo "GROQ_KEY_EXISTS=false"
```

If key exists, ask if they want to keep it or enter a new one.

If new key needed, use the AskUserQuestion tool:

**Question:** "Enter your Groq API key (get one free at console.groq.com/keys)"

**Important:** The user will select "Other" and paste their key.

### Update Config (Groq)

Update only the relevant keys, preserving any existing Inworld config:

```bash
update_config_key() {
  local key="$1" value="$2"
  local file="$HOME/.config/claude-code-tts/.env"
  mkdir -p "$(dirname "$file")"
  if [[ -f "$file" ]] && grep -q "^${key}=" "$file"; then
    sed -i '' "s|^${key}=.*|${key}=${value}|" "$file"
  else
    echo "${key}=${value}" >> "$file"
  fi
}

update_config_key "TTS_PROVIDER" "groq"
update_config_key "GROQ_API_KEY" "USER_API_KEY_HERE"
chmod 600 ~/.config/claude-code-tts/.env
echo "Config updated - switched to Groq provider"
```

Replace `USER_API_KEY_HERE` with the actual key provided.

### Test Groq

```bash
source ~/.config/claude-code-tts/.env
curl -s -w "%{http_code}" -o /dev/null \
  -X POST "https://api.groq.com/openai/v1/audio/speech" \
  -H "Authorization: Bearer $GROQ_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"canopylabs/orpheus-v1-english","voice":"hannah","input":"Setup complete","response_format":"wav"}'
```

- `200`: Success!
- `401`: Invalid API key
- `429`: Rate limited, but key is valid

### Groq Voice Selection

Ask user for default voice:

| Voice | Gender |
|-------|--------|
| hannah | Female (default) |
| autumn | Female |
| diana | Female |
| austin | Male |
| daniel | Male |
| troy | Male |

If they choose a non-default voice:
```bash
update_config_key "TTS_VOICE" "chosen_voice"
```

## Step 3b: Inworld Setup (if selected)

### Get API Key

Check if Inworld key already exists:
```bash
grep -q "^INWORLD_API_KEY=." ~/.config/claude-code-tts/.env 2>/dev/null && echo "INWORLD_KEY_EXISTS=true" || echo "INWORLD_KEY_EXISTS=false"
```

If key exists, ask if they want to keep it or enter a new one.

If new key needed, use the AskUserQuestion tool:

**Question:** "Enter your Inworld API key. You can find the 'Basic (Base64)' value in your Inworld dashboard - use that directly."

**Instructions to give user:**
1. Sign up at https://platform.inworld.ai/
2. Navigate to API Keys section
3. Create a new API key
4. Copy the **Basic (Base64)** value shown in the dialog
5. Paste that value (it's already base64 encoded)

### Choose Model

Use the AskUserQuestion tool:

**Question:** "Which Inworld model would you like to use?"

**Options:**
1. inworld-tts-1.5-max (Recommended) - Best quality, ~200ms latency
2. inworld-tts-1.5-mini - Faster, ~120ms latency

### Update Config (Inworld)

Update only the relevant keys, preserving any existing Groq config:

```bash
update_config_key() {
  local key="$1" value="$2"
  local file="$HOME/.config/claude-code-tts/.env"
  mkdir -p "$(dirname "$file")"
  if [[ -f "$file" ]] && grep -q "^${key}=" "$file"; then
    sed -i '' "s|^${key}=.*|${key}=${value}|" "$file"
  else
    echo "${key}=${value}" >> "$file"
  fi
}

update_config_key "TTS_PROVIDER" "inworld"
update_config_key "INWORLD_API_KEY" "USER_BASE64_KEY_HERE"
update_config_key "INWORLD_MODEL" "SELECTED_MODEL_HERE"
chmod 600 ~/.config/claude-code-tts/.env
echo "Config updated - switched to Inworld provider"
```

Replace placeholders with actual values.

### Test Inworld

```bash
source ~/.config/claude-code-tts/.env
RESPONSE=$(curl -s -X POST "https://api.inworld.ai/tts/v1/voice" \
  -H "Authorization: Basic $INWORLD_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"text":"Setup complete","voiceId":"Luna","modelId":"'"$INWORLD_MODEL"'"}')
echo "$RESPONSE" | jq -r 'if .audioContent then "SUCCESS: API key valid" else "ERROR: " + (.error // .message // "Unknown error") end'
```

### Inworld Voice Selection

Ask user for default voice:

| Voice | Gender |
|-------|--------|
| Luna | Female (default) |
| Dennis | Male |
| Timothy | Male |
| Ronald | Male |
| Wendy | Female |

If they choose a non-default voice:
```bash
update_config_key "INWORLD_VOICE" "chosen_voice"
```

## Completion

Tell the user:
- TTS is configured and ready
- Provider can be switched anytime by changing `TTS_PROVIDER` in the config
- Both provider keys are preserved, making it easy to switch
- Restart Claude Code to activate the hooks
- They can mute anytime with `touch .tts-muted`

Show their final configuration (masking API keys):
```bash
echo "=== Current TTS Configuration ==="
cat ~/.config/claude-code-tts/.env | sed 's/\(.*_KEY=\).*/\1***/'
```
