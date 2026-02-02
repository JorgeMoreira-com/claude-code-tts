#!/usr/bin/env bash
#
# Stop all TTS audio playback
#

pkill -f afplay 2>/dev/null
pkill -f paplay 2>/dev/null
pkill -f aplay 2>/dev/null
echo "Audio stopped"
