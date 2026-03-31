#!/bin/bash
# Transcribe audio file using whisper-cli
# Usage: ./transcribe.sh <audio_file>
# Supports: ogg, mp3, wav, flac
# Output: plain text to stdout

MODEL="$HOME/.local/share/whisper-cpp/models/ggml-base.en.bin"
INPUT="$1"

if [ -z "$INPUT" ]; then
  echo "Usage: $0 <audio_file>" >&2
  exit 1
fi

# Convert to wav if not already (whisper-cli works best with wav)
TMPWAV=""
EXT="${INPUT##*.}"
if [ "$EXT" != "wav" ]; then
  TMPWAV=$(mktemp /tmp/whisper_XXXXXX.wav)
  ffmpeg -i "$INPUT" -ar 16000 -ac 1 -y "$TMPWAV" 2>/dev/null
  INPUT="$TMPWAV"
fi

# Transcribe — output text only, no timestamps
whisper-cli -m "$MODEL" -f "$INPUT" --no-timestamps 2>/dev/null | sed '/^$/d'

# Clean up temp file
if [ -n "$TMPWAV" ]; then
  rm -f "$TMPWAV"
fi
