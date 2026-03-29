#!/bin/zsh
# Start {{ASSISTANT_NAME}} Assistant

# Ensure claude is on PATH (common install locations)
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:/usr/local/bin:$PATH"
[[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null

cd "$(dirname "$0")"
exec claude --channels plugin:discord@claude-plugins-official {{SKIP_PERMISSIONS_FLAG}}
