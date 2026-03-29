#!/bin/bash
# mira-assistant-setup uninstaller — Conservative teardown
# Prompts before every removal. Never touches system packages or global Claude settings.

set -euo pipefail

AUTO_YES=false
if [[ "${1:-}" == "--yes" || "${1:-}" == "-y" ]]; then
  AUTO_YES=true
fi

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'; GREEN='\033[0;32m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

removed=()
preserved=()

# ── Helpers ───────────────────────────────────────────────────────────────────
confirm() {
  if $AUTO_YES; then return 0; fi
  echo -ne "${YELLOW}$1${RESET} (y/N) "
  read -r yn
  [[ "$yn" == "y" || "$yn" == "Y" ]]
}

info()    { echo -e "${CYAN}▸ $*${RESET}"; }
success() { echo -e "${GREEN}✓ $*${RESET}"; }
skip()    { echo -e "  ${BOLD}Skipped:${RESET} $*"; }

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}Mira Assistant Uninstaller${RESET}"
echo "This script removes components installed by setup.sh."
echo -e "${YELLOW}System packages (brew, Python) and Claude plugins are never touched.${RESET}"
echo ""

# ── 1. Detect & remove workspace directory ───────────────────────────────────
info "Step 1: Assistant workspace directory"

WORKSPACE=""

# Try to find it from a .app bundle in ~/Applications
if ls ~/Applications/*.app 2>/dev/null | head -1 | grep -q ".app"; then
  for app in ~/Applications/*.app; do
    launcher="$app/Contents/MacOS/launcher"
    # Launcher scripts use: cd 'WORKSPACE' or WORKSPACE="path"
    if [[ -f "$launcher" ]]; then
      candidate=$(grep -oE "cd '([^']+)'" "$launcher" 2>/dev/null | head -1 | sed "s/cd '//;s/'//")
      [[ -z "$candidate" ]] && candidate=$(grep -oE 'WORKSPACE="([^"]+)"' "$launcher" 2>/dev/null | head -1 | sed 's/WORKSPACE="//;s/"//')
      if [[ -n "$candidate" && -d "$candidate" ]]; then
        WORKSPACE="$candidate"
        break
      fi
    fi
  done
fi

# Fall back: look for common naming patterns
if [[ -z "$WORKSPACE" ]]; then
  for candidate in ~/*_Assistant ~/Desktop/*_Assistant ~/Documents/*_Assistant; do
    if [[ -d "$candidate" ]]; then
      WORKSPACE="$candidate"
      break
    fi
  done
fi

if [[ -n "$WORKSPACE" ]]; then
  echo "  Detected workspace: $WORKSPACE"
  if confirm "Remove workspace directory '$WORKSPACE'?"; then
    rm -rf "$WORKSPACE"
    removed+=("Workspace: $WORKSPACE")
    success "Removed $WORKSPACE"
  else
    preserved+=("Workspace: $WORKSPACE")
    skip "$WORKSPACE"
  fi
else
  echo -n "  Could not auto-detect workspace. Enter path to remove (or press Enter to skip): "
  if ! $AUTO_YES; then
    read -r user_path
    if [[ -n "$user_path" && -d "$user_path" ]]; then
      if confirm "Remove workspace directory '$user_path'?"; then
        rm -rf "$user_path"
        removed+=("Workspace: $user_path")
        success "Removed $user_path"
      else
        preserved+=("Workspace: $user_path")
        skip "$user_path"
      fi
    else
      skip "No workspace path provided or directory not found"
      preserved+=("Workspace: (not found)")
    fi
  else
    skip "No workspace detected (--yes mode, skipping)"
    preserved+=("Workspace: (not found — skipped)")
  fi
fi

# ── 2. Remove launcher .app from ~/Applications ───────────────────────────────
info "Step 2: Launcher .app bundle(s) in ~/Applications/"

app_count=0
for app in ~/Applications/*.app; do
  [[ -d "$app" ]] || continue
  # Only remove apps that contain our launcher marker
  if grep -qr 'mira-assistant' "$app" 2>/dev/null || \
     grep -qr 'claude.*--project-dir' "$app" 2>/dev/null; then
    if confirm "Remove launcher '$(basename "$app")'?"; then
      rm -rf "$app"
      removed+=("Launcher: $app")
      success "Removed $(basename "$app")"
      app_count=$((app_count + 1))
    else
      preserved+=("Launcher: $app")
      skip "$app"
    fi
  fi
done

if [[ $app_count -eq 0 ]]; then
  skip "No matching launcher .app found in ~/Applications/"
  preserved+=("Launcher: (none found)")
fi

# ── 3. gstack skills ──────────────────────────────────────────────────────────
info "Step 3: gstack skills (~/.claude/skills/gstack)"

GSTACK_DIR="$HOME/.claude/skills/gstack"
if [[ -d "$GSTACK_DIR" ]]; then
  if confirm "Remove gstack skills at '$GSTACK_DIR'?"; then
    rm -rf "$GSTACK_DIR"
    removed+=("gstack skills: $GSTACK_DIR")
    success "Removed gstack skills"
  else
    preserved+=("gstack skills: $GSTACK_DIR")
    skip "$GSTACK_DIR"
  fi
else
  skip "gstack skills not found at $GSTACK_DIR"
  preserved+=("gstack skills: (not installed)")
fi

# ── 4. Whisper model ──────────────────────────────────────────────────────────
info "Step 4: Whisper model file"

WHISPER_MODEL="$HOME/.local/share/whisper-cpp/models/ggml-base.en.bin"
if [[ -f "$WHISPER_MODEL" ]]; then
  size=$(du -sh "$WHISPER_MODEL" 2>/dev/null | cut -f1)
  if confirm "Remove Whisper model ($size) at '$WHISPER_MODEL'?"; then
    rm -f "$WHISPER_MODEL"
    removed+=("Whisper model: $WHISPER_MODEL")
    success "Removed Whisper model"
    # Remove parent dir if now empty
    rmdir "$(dirname "$WHISPER_MODEL")" 2>/dev/null || true
    rmdir "$HOME/.local/share/whisper-cpp" 2>/dev/null || true
  else
    preserved+=("Whisper model: $WHISPER_MODEL")
    skip "$WHISPER_MODEL"
  fi
else
  skip "Whisper model not found at $WHISPER_MODEL"
  preserved+=("Whisper model: (not installed)")
fi

# ── 5. Discord config ─────────────────────────────────────────────────────────
info "Step 5: Discord bot config (~/.claude/channels/discord/.env)"

DISCORD_ENV="$HOME/.claude/channels/discord/.env"
if [[ -f "$DISCORD_ENV" ]]; then
  if confirm "Remove Discord bot config at '$DISCORD_ENV'? (contains bot token)"; then
    rm -f "$DISCORD_ENV"
    removed+=("Discord config: $DISCORD_ENV")
    success "Removed Discord config"
    rmdir "$(dirname "$DISCORD_ENV")" 2>/dev/null || true
  else
    preserved+=("Discord config: $DISCORD_ENV")
    skip "$DISCORD_ENV"
  fi
else
  skip "Discord config not found at $DISCORD_ENV"
  preserved+=("Discord config: (not installed)")
fi

# ── 6. VibeVoice (if installed) ───────────────────────────────────────────────
info "Step 6: VibeVoice premium TTS (if installed)"

vv_installed=false
if python3 -c "import vibevoice" 2>/dev/null; then
  vv_installed=true
fi

HF_VIBE_CACHE="$HOME/.cache/huggingface/hub/models--microsoft--VibeVoice-Realtime-0.5B"

if $vv_installed || [[ -d "$HF_VIBE_CACHE" ]]; then
  if $vv_installed; then
    echo "  Found: vibevoice Python package"
  fi
  if [[ -d "$HF_VIBE_CACHE" ]]; then
    size=$(du -sh "$HF_VIBE_CACHE" 2>/dev/null | cut -f1)
    echo "  Found: VibeVoice model cache ($size) at $HF_VIBE_CACHE"
  fi

  if confirm "Remove VibeVoice package and/or model cache?"; then
    if $vv_installed; then
      pip3 uninstall -y vibevoice 2>/dev/null && \
        { removed+=("VibeVoice: pip package"); success "Uninstalled vibevoice pip package"; } || \
        echo "  Warning: pip uninstall failed (may need sudo or venv)"
    fi
    if [[ -d "$HF_VIBE_CACHE" ]]; then
      rm -rf "$HF_VIBE_CACHE"
      removed+=("VibeVoice: model cache ($HF_VIBE_CACHE)")
      success "Removed VibeVoice model cache"
    fi
  else
    preserved+=("VibeVoice: (kept)")
    skip "VibeVoice"
  fi
else
  skip "VibeVoice not installed"
  preserved+=("VibeVoice: (not installed)")
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}────────────────────────────────────────${RESET}"
echo -e "${BOLD}Uninstall summary${RESET}"
echo ""

if [[ ${#removed[@]} -gt 0 ]]; then
  echo -e "${RED}Removed:${RESET}"
  for item in "${removed[@]}"; do
    echo "  ✗ $item"
  done
else
  echo -e "${GREEN}Nothing was removed.${RESET}"
fi

echo ""
echo -e "${GREEN}Preserved (untouched):${RESET}"
for item in "${preserved[@]}"; do
  echo "  ✓ $item"
done

echo ""
echo -e "  ✓ Homebrew packages (whisper-cpp, ffmpeg, node, bun, jq)"
echo -e "  ✓ Claude Code plugins (discord, gws, remember, etc.)"
echo -e "  ✓ Global Claude settings (~/.claude/settings.json)"
echo -e "  ✓ Other Claude workspaces"
echo ""
echo -e "${BOLD}Done.${RESET}"
