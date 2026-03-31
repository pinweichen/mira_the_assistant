#!/bin/bash
# mira-assistant-setup — One-command Claude Code Executive Assistant installer
# macOS v1
#
# Usage: ./setup.sh
# Idempotent: safe to run multiple times; completed phases are skipped.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─── Ensure common install locations are on PATH ─────────────────────────────
# Claude Code installs to ~/.local/bin which may not be in PATH for bash sessions
export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
# Also pick up Homebrew on Apple Silicon
[[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null

# ─── Color helpers ─────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${GREEN}  ✓${NC} $1"; }
warn()    { echo -e "${YELLOW}  ⚠${NC} $1"; }
err()     { echo -e "${RED}  ✗${NC} $1" >&2; }
section() { echo -e "\n${BOLD}${BLUE}$1${NC}"; }

# ─── Input sanitizer for sed (escape & and |) ──────────────────────────────────

sanitize() {
  local val="$1"
  val="${val//\\/\\\\}"   # escape backslashes first
  val="${val//&/\\&}"
  val="${val//|/\\|}"
  val="${val//$'\n'/}"    # strip newlines (prevent sed multi-line injection)
  printf '%s' "$val"      # printf avoids echo interpreting escape sequences
}

# ─── Global state (set across phases) ─────────────────────────────────────────

ASSISTANT_NAME=""
USER_NAME=""
USER_ROLE=""
PROJECT_COUNT=""
WORK_HOURS=""
TIMEZONE=""
WORK_EMAIL=""
GOOGLE_MEET=""
WORKSPACE_DIR=""
VOICE_LANGUAGE=""   # en | zh | ja | ko | es | fr | de | auto
VOICE_ENGINE=""    # say | vibevoice | none
VOICE_NAME=""
SKIP_PERMISSIONS=false

# ─── Resume state ────────────────────────────────────────────────────────────
# Tracks completed phases so re-runs skip finished work.
# Stored at ~/.mira-assistant-setup-state (before we know WORKSPACE_DIR).

STATE_FILE="$HOME/.mira-assistant-setup-state"

_phase_done() {
  grep -qx "$1" "$STATE_FILE" 2>/dev/null
}

_mark_done() {
  echo "$1" >> "$STATE_FILE"
  chmod 600 "$STATE_FILE" 2>/dev/null || true
}

# Save user inputs so re-runs don't re-prompt
_save_inputs() {
  cat > "${STATE_FILE}.vars" << VARS_EOF
ASSISTANT_NAME=$(printf '%q' "$ASSISTANT_NAME")
USER_NAME=$(printf '%q' "$USER_NAME")
USER_ROLE=$(printf '%q' "$USER_ROLE")
PROJECT_COUNT=$(printf '%q' "$PROJECT_COUNT")
WORK_HOURS=$(printf '%q' "$WORK_HOURS")
TIMEZONE=$(printf '%q' "$TIMEZONE")
WORK_EMAIL=$(printf '%q' "$WORK_EMAIL")
GOOGLE_MEET=$(printf '%q' "$GOOGLE_MEET")
WORKSPACE_DIR=$(printf '%q' "$WORKSPACE_DIR")
VOICE_LANGUAGE=$(printf '%q' "$VOICE_LANGUAGE")
VOICE_ENGINE=$(printf '%q' "$VOICE_ENGINE")
VOICE_NAME=$(printf '%q' "$VOICE_NAME")
SKIP_PERMISSIONS=$(printf '%q' "$SKIP_PERMISSIONS")
VARS_EOF
  chmod 600 "${STATE_FILE}.vars"
}

_load_inputs() {
  if [[ -f "${STATE_FILE}.vars" ]]; then
    source "${STATE_FILE}.vars"
    return 0
  fi
  return 1
}

# ══════════════════════════════════════════════════════════════════════════════
# Phase 0: Preflight
# ══════════════════════════════════════════════════════════════════════════════

phase_preflight() {
  # Verify macOS
  if [[ "$(uname)" != "Darwin" ]]; then
    echo "Error: This installer requires macOS." >&2
    exit 1
  fi

  # Verify Homebrew (offer to install if missing)
  if ! command -v brew &>/dev/null; then
    echo "Homebrew not found. Install it? (Y/n)"
    read -r yn
    if [[ "$yn" != "n" && "$yn" != "N" ]]; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      # Source brew environment for Apple Silicon
      if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
      elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
      fi
      # Re-source shell profile so existing PATH entries (e.g. ~/.local/bin) are preserved
      [[ -f "$HOME/.zprofile" ]] && source "$HOME/.zprofile" 2>/dev/null
      [[ -f "$HOME/.zshrc" ]] && source "$HOME/.zshrc" 2>/dev/null
      if ! command -v brew &>/dev/null; then
        echo "Error: Homebrew install failed. Install manually: https://brew.sh" >&2
        exit 1
      fi
    else
      echo "Error: Homebrew is required." >&2
      exit 1
    fi
  fi

  # Verify claude CLI (offer to install if missing)
  if ! command -v claude &>/dev/null; then
    echo "Claude Code CLI not found. Install it? (Y/n)"
    read -r yn
    if [[ "$yn" != "n" && "$yn" != "N" ]]; then
      curl -fsSL https://claude.ai/install.sh | bash
      # Add common install locations to PATH for this session
      export PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH"
      # Source shell profiles to pick up any other PATH entries
      [[ -f "$HOME/.bash_profile" ]] && source "$HOME/.bash_profile" 2>/dev/null
      [[ -f "$HOME/.bashrc" ]] && source "$HOME/.bashrc" 2>/dev/null
      [[ -f "$HOME/.zprofile" ]] && source "$HOME/.zprofile" 2>/dev/null
      [[ -f "$HOME/.zshrc" ]] && source "$HOME/.zshrc" 2>/dev/null
      if ! command -v claude &>/dev/null; then
        echo "Error: Claude Code install failed." >&2
        echo "  Install manually: https://claude.ai/code" >&2
        exit 1
      fi
    else
      echo "Error: Claude Code CLI is required." >&2
      exit 1
    fi
  fi

  # Verify git
  if ! command -v git &>/dev/null; then
    echo "Error: git is required. Install via: xcode-select --install" >&2
    exit 1
  fi

  # Banner
  cat << 'BANNER'

╔══════════════════════════════════════════╗
║  Claude Code Executive Assistant Setup   ║
╚══════════════════════════════════════════╝
BANNER
  echo ""

  # Detect resume
  if [[ -f "$STATE_FILE" ]]; then
    local completed
    completed=$(wc -l < "$STATE_FILE" | tr -d ' ')
    warn "Resuming previous install ($completed/9 phases completed — finished phases will be skipped)"
    echo ""
  fi

  echo "This will install:"
  echo "  • System dependencies (whisper-cpp, ffmpeg, node, bun, jq)"
  echo "  • Claude Code plugins (discord, remember, claude-md-management,"
  echo "                         hookify, superpowers, gws)"
  echo "  • gstack skills"
  echo "  • Whisper speech-to-text model (~150MB)"
  echo "  • Voice setup (optional)"
  echo "  • Personalized assistant workspace"
  echo "  • macOS launcher app"
  echo ""
  echo -n "Continue? (Y/n): "
  read -r confirm
  if [[ "$confirm" == "n" || "$confirm" == "N" ]]; then
    echo "Setup cancelled."
    exit 0
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# Phase 1: System Dependencies
# ══════════════════════════════════════════════════════════════════════════════

phase_system_deps() {
  if _phase_done "system_deps"; then
    section "[1/9] System dependencies — already done, skipping"
    return
  fi
  section "[1/9] Installing system dependencies..."

  # Prevent brew from auto-updating on every install (saves minutes)
  export HOMEBREW_NO_AUTO_UPDATE=1

  # Warn about slow source builds on older macOS
  local macos_ver
  macos_ver=$(sw_vers -productVersion 2>/dev/null | cut -d. -f1)
  if [[ -n "$macos_ver" && "$macos_ver" -lt 14 ]]; then
    warn "macOS $macos_ver detected — Homebrew may compile some packages from source."
    echo "  This can take 15-30 minutes (especially cmake). Please be patient."
    echo ""
  fi

  local pkgs=(whisper-cpp ffmpeg node bun jq)
  for pkg in "${pkgs[@]}"; do
    if brew list "$pkg" &>/dev/null; then
      info "$pkg (already installed)"
    else
      echo "  Installing $pkg... (this may take a while)"
      if brew install "$pkg" 2>&1; then
        info "$pkg installed"
      else
        warn "Failed to install $pkg — continuing (some features may not work)"
      fi
    fi
  done

  # gws CLI (Google Workspace CLI — required for gws plugin)
  if command -v gws &>/dev/null; then
    info "gws CLI (already installed)"
  else
    echo "  Installing gws CLI (Google Workspace)..."
    if npm install -g @googleworkspace/cli 2>&1; then
      info "gws CLI installed"
    else
      warn "Could not install gws CLI"
      echo "    Install manually: npm install -g @googleworkspace/cli"
    fi
  fi
  _mark_done "system_deps"
}

# ══════════════════════════════════════════════════════════════════════════════
# Phase 2: Claude Code Plugins
# ══════════════════════════════════════════════════════════════════════════════

phase_plugins() {
  if _phase_done "plugins"; then
    section "[2/9] Claude Code plugins — already done, skipping"
    return
  fi
  section "[2/9] Installing Claude Code plugins..."

  local plugins=(discord remember claude-md-management hookify superpowers)

  local json="$HOME/.claude/plugins/installed_plugins.json"
  local cache_dir="$HOME/.claude/plugins/cache/claude-plugins-official"

  for plugin in "${plugins[@]}"; do
    # Check if already installed (cache dir or installed_plugins.json)
    if [[ -d "$cache_dir/$plugin" ]]; then
      info "$plugin (already installed)"
      continue
    fi
    if [[ -f "$json" ]] && grep -q "\"${plugin}@" "$json" 2>/dev/null; then
      info "$plugin (already installed)"
      continue
    fi

    echo "  Installing plugin: $plugin..."
    if echo "y" | claude plugin install "$plugin" 2>&1; then
      info "$plugin installed"
    else
      warn "Could not install plugin: $plugin"
      echo "    Install manually: claude plugin install $plugin"
    fi
  done

  # gws plugin (Google Workspace — Calendar, Gmail, Drive, etc.)
  # Requires its own marketplace, then install
  local gws_cache="$HOME/.claude/plugins/cache/gws-marketplace"
  if [[ -d "$gws_cache/gws" ]]; then
    info "gws (already installed)"
  elif [[ -f "$json" ]] && grep -q '"gws@' "$json" 2>/dev/null; then
    info "gws (already installed)"
  else
    echo "  Adding gws marketplace..."
    if claude plugin marketplace add https://github.com/WadeWarren/gws-claude-plugin 2>&1; then
      info "gws marketplace added"
    else
      warn "Could not add gws marketplace"
    fi

    echo "  Installing plugin: gws..."
    if echo "y" | claude plugin install gws 2>&1; then
      info "gws installed"
    else
      warn "Could not install gws plugin"
      echo "    Install manually:"
      echo "      claude plugin marketplace add https://github.com/WadeWarren/gws-claude-plugin"
      echo "      claude plugin install gws"
    fi
  fi
  _mark_done "plugins"
}

# ══════════════════════════════════════════════════════════════════════════════
# Phase 3: gstack Skills
# ══════════════════════════════════════════════════════════════════════════════

phase_gstack() {
  if _phase_done "gstack"; then
    section "[3/9] gstack skills — already done, skipping"
    return
  fi
  section "[3/9] Installing gstack skills..."
  local gstack_dir="$HOME/.claude/skills/gstack"

  if [[ -d "$gstack_dir/.git" ]]; then
    info "gstack already installed, updating..."
    if git -C "$gstack_dir" pull origin main 2>/dev/null; then
      info "gstack updated"
    else
      warn "Could not update gstack (offline or repo access issue)"
    fi
  else
    mkdir -p "$HOME/.claude/skills"
    if git clone https://github.com/garrytan/gstack.git "$gstack_dir" 2>/dev/null; then
      info "gstack installed"
    else
      warn "Could not clone gstack (may be private or network unavailable)"
      echo ""
      echo "  Manual install:"
      echo "    git clone https://github.com/garrytan/gstack.git ~/.claude/skills/gstack"
      echo ""
    fi
  fi
  _mark_done "gstack"
}

# ══════════════════════════════════════════════════════════════════════════════
# Phase 4: Whisper Model
# ══════════════════════════════════════════════════════════════════════════════

phase_whisper() {
  if _phase_done "whisper"; then
    section "[5/9] Whisper model — already done, skipping"
    return
  fi
  section "[5/9] Setting up Whisper speech-to-text model..."
  local model_dir="$HOME/.local/share/whisper-cpp/models"

  # Use English-only model for en, multilingual model for all other languages
  local model_file model_url
  if [[ "$VOICE_LANGUAGE" == "en" || -z "$VOICE_LANGUAGE" ]]; then
    model_file="$model_dir/ggml-base.en.bin"
    model_url="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin"
  else
    model_file="$model_dir/ggml-base.bin"
    model_url="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin"
    info "Using multilingual Whisper model for language: $VOICE_LANGUAGE"
  fi
  local min_size=$(( 100 * 1024 * 1024 ))  # 100MB minimum

  # Check if already present and valid
  if [[ -f "$model_file" ]]; then
    local file_size
    file_size=$(stat -f%z "$model_file" 2>/dev/null || echo 0)
    if [[ "$file_size" -gt "$min_size" ]]; then
      info "Whisper model already present ($(( file_size / 1024 / 1024 ))MB)"
      return
    else
      warn "Existing model looks incomplete ($(( file_size / 1024 / 1024 ))MB) — re-downloading..."
      rm -f "$model_file"
    fi
  fi

  mkdir -p "$model_dir"
  echo "  Downloading ggml-base.en.bin (~150MB)..."

  local attempt=0
  local downloaded=false
  while [[ $attempt -lt 3 ]]; do
    attempt=$(( attempt + 1 ))
    echo "  Attempt $attempt/3..."

    if curl -fL --progress-bar --retry 2 --retry-delay 3 \
        -o "${model_file}.tmp" "$model_url"; then
      local file_size
      file_size=$(stat -f%z "${model_file}.tmp" 2>/dev/null || echo 0)
      if [[ "$file_size" -gt "$min_size" ]]; then
        mv "${model_file}.tmp" "$model_file"
        info "Whisper model downloaded ($(( file_size / 1024 / 1024 ))MB)"
        downloaded=true
        break
      else
        warn "Download incomplete ($(( file_size / 1024 / 1024 ))MB)"
        rm -f "${model_file}.tmp"
      fi
    else
      warn "Download failed (attempt $attempt)"
      rm -f "${model_file}.tmp"
    fi
    [[ $attempt -lt 3 ]] && sleep 5
  done

  if [[ "$downloaded" != true ]]; then
    warn "Could not download Whisper model after 3 attempts"
    echo "  Voice transcription will not work until the model is downloaded."
    echo ""
    echo "  Manual download:"
    echo "    mkdir -p ~/.local/share/whisper-cpp/models"
    echo "    curl -fL -o ${model_file} \\"
    echo "      ${model_url}"
  fi
  _mark_done "whisper"
}

# ══════════════════════════════════════════════════════════════════════════════
# Phase 5: Voice Setup
# ══════════════════════════════════════════════════════════════════════════════

phase_voice() {
  if _phase_done "voice"; then
    section "[4/9] Voice setup — already done, skipping"
    _load_inputs  # restore VOICE_ENGINE/VOICE_NAME for later phases
    return
  fi
  section "[4/9] Voice setup..."
  echo ""
  echo "  Choose a language for voice (speech-to-text and text-to-speech):"
  echo ""
  echo "    1) English"
  echo "    2) Chinese (Mandarin)"
  echo "    3) Japanese"
  echo "    4) Korean"
  echo "    5) Spanish"
  echo "    6) French"
  echo "    7) German"
  echo "    8) Auto-detect (slightly slower transcription)"
  echo ""
  echo -n "  Select [1-8] (default: 1): "
  read -r lang_choice

  case "$lang_choice" in
    1|"") VOICE_LANGUAGE="en" ;;
    2)    VOICE_LANGUAGE="zh" ;;
    3)    VOICE_LANGUAGE="ja" ;;
    4)    VOICE_LANGUAGE="ko" ;;
    5)    VOICE_LANGUAGE="es" ;;
    6)    VOICE_LANGUAGE="fr" ;;
    7)    VOICE_LANGUAGE="de" ;;
    8)    VOICE_LANGUAGE="auto" ;;
    *)    VOICE_LANGUAGE="en"; warn "Invalid selection — defaulting to English" ;;
  esac
  info "Voice language: $VOICE_LANGUAGE"

  echo ""
  echo "  Choose a voice for your assistant's replies:"
  echo ""

  # Show language-appropriate macOS say voices
  case "$VOICE_LANGUAGE" in
    zh)
      echo "  Standard voices (macOS say — zero install):"
      echo "    1) Tingting             — Female (Mandarin)"
      echo "    2) Meijia               — Female (Mandarin)"
      echo ""
      echo "  Premium AI voice:"
      echo "    3) VibeVoice AI         — Premium quality (Python + ~2.5GB download)"
      echo ""
      echo "    4) Skip — no voice replies"
      echo ""
      echo -n "  Select [1-4]: "
      read -r voice_choice
      case "$voice_choice" in
        1) _setup_say_voice "Tingting" ;;
        2) _setup_say_voice "Meijia" ;;
        3) _setup_vibevoice ;;
        4|"") VOICE_ENGINE="none"; VOICE_NAME="none"; info "Skipped voice setup" ;;
        *)     VOICE_ENGINE="none"; VOICE_NAME="none"; warn "Invalid selection — skipping voice setup" ;;
      esac
      ;;
    ja)
      echo "  Standard voices (macOS say — zero install):"
      echo "    1) Kyoko               — Female (Japanese)"
      echo "    2) Otoya               — Male (Japanese)"
      echo ""
      echo "  Premium AI voice:"
      echo "    3) VibeVoice AI         — Premium quality (Python + ~2.5GB download)"
      echo ""
      echo "    4) Skip — no voice replies"
      echo ""
      echo -n "  Select [1-4]: "
      read -r voice_choice
      case "$voice_choice" in
        1) _setup_say_voice "Kyoko" ;;
        2) _setup_say_voice "Otoya" ;;
        3) _setup_vibevoice ;;
        4|"") VOICE_ENGINE="none"; VOICE_NAME="none"; info "Skipped voice setup" ;;
        *)     VOICE_ENGINE="none"; VOICE_NAME="none"; warn "Invalid selection — skipping voice setup" ;;
      esac
      ;;
    ko)
      echo "  Standard voices (macOS say — zero install):"
      echo "    1) Yuna                — Female (Korean)"
      echo ""
      echo "  Premium AI voice:"
      echo "    2) VibeVoice AI         — Premium quality (Python + ~2.5GB download)"
      echo ""
      echo "    3) Skip — no voice replies"
      echo ""
      echo -n "  Select [1-3]: "
      read -r voice_choice
      case "$voice_choice" in
        1) _setup_say_voice "Yuna" ;;
        2) _setup_vibevoice ;;
        3|"") VOICE_ENGINE="none"; VOICE_NAME="none"; info "Skipped voice setup" ;;
        *)     VOICE_ENGINE="none"; VOICE_NAME="none"; warn "Invalid selection — skipping voice setup" ;;
      esac
      ;;
    es)
      echo "  Standard voices (macOS say — zero install):"
      echo "    1) Paulina             — Female (Spanish)"
      echo "    2) Monica              — Female (Spanish)"
      echo "    3) Juan                — Male (Spanish)"
      echo ""
      echo "  Premium AI voice:"
      echo "    4) VibeVoice AI         — Premium quality (Python + ~2.5GB download)"
      echo ""
      echo "    5) Skip — no voice replies"
      echo ""
      echo -n "  Select [1-5]: "
      read -r voice_choice
      case "$voice_choice" in
        1) _setup_say_voice "Paulina" ;;
        2) _setup_say_voice "Monica" ;;
        3) _setup_say_voice "Juan" ;;
        4) _setup_vibevoice ;;
        5|"") VOICE_ENGINE="none"; VOICE_NAME="none"; info "Skipped voice setup" ;;
        *)     VOICE_ENGINE="none"; VOICE_NAME="none"; warn "Invalid selection — skipping voice setup" ;;
      esac
      ;;
    fr)
      echo "  Standard voices (macOS say — zero install):"
      echo "    1) Amelie              — Female (French)"
      echo "    2) Thomas              — Male (French)"
      echo ""
      echo "  Premium AI voice:"
      echo "    3) VibeVoice AI         — Premium quality (Python + ~2.5GB download)"
      echo ""
      echo "    4) Skip — no voice replies"
      echo ""
      echo -n "  Select [1-4]: "
      read -r voice_choice
      case "$voice_choice" in
        1) _setup_say_voice "Amelie" ;;
        2) _setup_say_voice "Thomas" ;;
        3) _setup_vibevoice ;;
        4|"") VOICE_ENGINE="none"; VOICE_NAME="none"; info "Skipped voice setup" ;;
        *)     VOICE_ENGINE="none"; VOICE_NAME="none"; warn "Invalid selection — skipping voice setup" ;;
      esac
      ;;
    de)
      echo "  Standard voices (macOS say — zero install):"
      echo "    1) Anna                — Female (German)"
      echo "    2) Markus              — Male (German)"
      echo ""
      echo "  Premium AI voice:"
      echo "    3) VibeVoice AI         — Premium quality (Python + ~2.5GB download)"
      echo ""
      echo "    4) Skip — no voice replies"
      echo ""
      echo -n "  Select [1-4]: "
      read -r voice_choice
      case "$voice_choice" in
        1) _setup_say_voice "Anna" ;;
        2) _setup_say_voice "Markus" ;;
        3) _setup_vibevoice ;;
        4|"") VOICE_ENGINE="none"; VOICE_NAME="none"; info "Skipped voice setup" ;;
        *)     VOICE_ENGINE="none"; VOICE_NAME="none"; warn "Invalid selection — skipping voice setup" ;;
      esac
      ;;
    *) # en or auto — show English voices
      echo "  Standard voices (macOS say — zero install):"
      echo "    1) Allison (Enhanced)  — Female"
      echo "    2) Ava (Premium)       — Female"
      echo "    3) Samantha (Enhanced) — Female"
      echo "    4) Zoe (Enhanced)      — Female"
      echo "    5) Tom (Enhanced)      — Male"
      echo "    6) Evan (Enhanced)     — Male"
      echo "    7) Daniel              — Male (built-in)"
      echo ""
      echo "  Premium AI voice:"
      echo "    8) VibeVoice AI        — Premium quality (Python + ~2.5GB download)"
      echo ""
      echo "    9) Skip — no voice replies"
      echo ""
      echo -n "  Select [1-9]: "
      read -r voice_choice
      case "$voice_choice" in
        1) _setup_say_voice "Allison" ;;
        2) _setup_say_voice "Ava" ;;
        3) _setup_say_voice "Samantha" ;;
        4) _setup_say_voice "Zoe" ;;
        5) _setup_say_voice "Tom" ;;
        6) _setup_say_voice "Evan" ;;
        7) _setup_say_voice "Daniel" ;;
        8) _setup_vibevoice ;;
        9|"") VOICE_ENGINE="none"; VOICE_NAME="none"; info "Skipped voice setup" ;;
        *)     VOICE_ENGINE="none"; VOICE_NAME="none"; warn "Invalid selection — skipping voice setup" ;;
      esac
      ;;
  esac
  _save_inputs
  _mark_done "voice"
}

# Install/verify a macOS say voice and optionally preview it
_setup_say_voice() {
  local voice="$1"
  VOICE_ENGINE="say"
  VOICE_NAME="$voice"

  if say -v '?' 2>/dev/null | grep -qi "^${voice}[[:space:]]"; then
    info "Voice '$voice' is available"
    echo -n "  Preview? (Y/n): "
    read -r preview
    if [[ "$preview" != "n" && "$preview" != "N" ]]; then
      say -v "$voice" "Hello, I'm your assistant. Ready to help." 2>/dev/null \
        || warn "Preview failed — voice may need to be downloaded"
    fi
  else
    warn "Voice '$voice' is not installed on this system."
    echo ""
    echo "  To install it:"
    echo "  1. Open System Settings → Accessibility → Spoken Content"
    echo "  2. Click 'Manage Voices...'"
    echo "  3. Find '$voice' and click the download arrow"
    echo ""
    echo "  Press Enter to continue with $voice anyway (can install after setup)."
    read -r _ignored
  fi
}

# Install VibeVoice AI premium TTS
_setup_vibevoice() {
  VOICE_ENGINE="vibevoice"
  VOICE_NAME="Carter"
  echo ""
  echo "  Setting up VibeVoice AI (~2.5GB download)..."

  # Ensure Python 3.9+
  if ! command -v python3 &>/dev/null; then
    echo "  Installing Python 3..."
    if ! brew install python 2>&1; then
      warn "Could not install Python — falling back to no voice"
      VOICE_ENGINE="none"; VOICE_NAME="none"; return
    fi
  fi

  local py_minor
  py_minor=$(python3 -c "import sys; print(sys.version_info.minor)" 2>/dev/null || echo 0)
  if [[ "$py_minor" -lt 9 ]]; then
    warn "Python 3.9+ required (found 3.$py_minor). Recommend: brew install python@3.12"
  fi

  # Install vibevoice package
  echo "  Installing vibevoice package..."
  if ! pip3 install vibevoice 2>&1; then
    warn "Could not install vibevoice — falling back to no voice"
    VOICE_ENGINE="none"; VOICE_NAME="none"; return
  fi

  # Ensure huggingface-cli is available
  if ! command -v huggingface-cli &>/dev/null; then
    pip3 install huggingface_hub 2>/dev/null || true
  fi

  # Download model (~2.5GB)
  echo "  Downloading VibeVoice model (~2.5GB, may take several minutes)..."
  if ! huggingface-cli download microsoft/VibeVoice-Realtime-0.5B 2>&1; then
    warn "Could not download VibeVoice model — falling back to no voice"
    echo "  Manual download later: huggingface-cli download microsoft/VibeVoice-Realtime-0.5B"
    VOICE_ENGINE="none"; VOICE_NAME="none"; return
  fi

  info "VibeVoice AI installed (speaker: Carter)"
  echo -n "  Preview? (Y/n): "
  read -r preview
  if [[ "$preview" != "n" && "$preview" != "N" ]]; then
    python3 -m vibevoice.realtime \
      --model microsoft/VibeVoice-Realtime-0.5B \
      --text "Hello, I'm your assistant. Ready to help." \
      --output /tmp/vv_preview.wav 2>/dev/null \
      && afplay /tmp/vv_preview.wav 2>/dev/null \
      || warn "Preview failed — VibeVoice may need additional setup"
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# Phase 6: Project Scaffolding
# ══════════════════════════════════════════════════════════════════════════════

phase_scaffolding() {
  if _phase_done "scaffolding"; then
    section "[6/9] Workspace scaffolding — already done, skipping"
    _load_inputs  # restore all vars for later phases
    return
  fi
  section "[6/9] Setting up your assistant workspace..."
  echo ""

  # ── Gather inputs (restore saved values as defaults if resuming) ─────────────

  local saved_inputs=false
  if _load_inputs && [[ -n "$ASSISTANT_NAME" ]]; then
    saved_inputs=true
    echo "  Found saved inputs from previous run."
    echo "  Press Enter to keep each value, or type a new one."
    echo ""
  fi

  local default_name="${ASSISTANT_NAME:-Mira}"
  echo -n "  Assistant name [$default_name]: "
  read -r input
  ASSISTANT_NAME="${input:-$default_name}"

  # Validate: alphanumeric, spaces, hyphens, underscores only (prevents injection in
  # plist XML, shell scripts, sed patterns, and filesystem paths)
  if [[ ! "$ASSISTANT_NAME" =~ ^[a-zA-Z0-9\ _-]+$ ]]; then
    err "Assistant name must contain only letters, numbers, spaces, hyphens, and underscores."
    exit 1
  fi

  local default_workspace="${WORKSPACE_DIR:-$HOME/${ASSISTANT_NAME}_Assistant}"
  echo -n "  Workspace directory [$default_workspace]: "
  read -r input
  WORKSPACE_DIR="${input:-$default_workspace}"
  WORKSPACE_DIR="${WORKSPACE_DIR/#\~/$HOME}"  # expand leading ~

  local default_user="${USER_NAME:-}"
  while true; do
    if [[ -n "$default_user" ]]; then
      echo -n "  Your first name [$default_user]: "
    else
      echo -n "  Your first name (required): "
    fi
    read -r input
    USER_NAME="${input:-$default_user}"
    [[ -n "$USER_NAME" ]] && break
    warn "Name is required — please enter your name."
  done

  local default_role="${USER_ROLE:-professional}"
  echo -n "  Your role [$default_role]: "
  read -r input
  USER_ROLE="${input:-$default_role}"

  local default_count="${PROJECT_COUNT:-5}"
  echo -n "  Concurrent projects to track [$default_count]: "
  read -r input
  PROJECT_COUNT="${input:-$default_count}"

  local default_hours="${WORK_HOURS:-9am - 6pm ET}"
  echo -n "  Working hours [$default_hours]: "
  read -r input
  WORK_HOURS="${input:-$default_hours}"

  local default_tz="${TIMEZONE:-America/New_York}"
  echo -n "  Timezone [$default_tz]: "
  read -r input
  TIMEZONE="${input:-$default_tz}"

  local default_email="${WORK_EMAIL:-}"
  while true; do
    if [[ -n "$default_email" ]]; then
      echo -n "  Work email [$default_email]: "
    else
      echo -n "  Work email (required): "
    fi
    read -r input
    WORK_EMAIL="${input:-$default_email}"
    [[ -n "$WORK_EMAIL" ]] && break
    warn "Work email is required."
  done

  local default_meet="${GOOGLE_MEET:-no}"
  echo -n "  Auto-add Google Meet links to meetings? (y/N): "
  read -r input
  if [[ -n "$input" ]]; then
    GOOGLE_MEET="no"
    [[ "$input" == "y" || "$input" == "Y" ]] && GOOGLE_MEET="yes"
  else
    GOOGLE_MEET="$default_meet"
  fi

  echo ""

  # ── Sanitize all inputs for sed ──────────────────────────────────────────────

  local s_name;          s_name="$(sanitize "$ASSISTANT_NAME")"
  local s_user;          s_user="$(sanitize "$USER_NAME")"
  local s_role;          s_role="$(sanitize "$USER_ROLE")"
  local s_count;         s_count="$(sanitize "$PROJECT_COUNT")"
  local s_hours;         s_hours="$(sanitize "$WORK_HOURS")"
  local s_tz;            s_tz="$(sanitize "$TIMEZONE")"
  local s_email;         s_email="$(sanitize "$WORK_EMAIL")"
  local s_meet;          s_meet="$(sanitize "$GOOGLE_MEET")"
  local s_vname;         s_vname="$(sanitize "$VOICE_NAME")"
  local s_vengine;       s_vengine="$(sanitize "$VOICE_ENGINE")"

  # Transcription command (macOS whisper-cpp)
  local whisper_model whisper_lang
  if [[ "$VOICE_LANGUAGE" == "en" || -z "$VOICE_LANGUAGE" ]]; then
    whisper_model="ggml-base.en.bin"
    whisper_lang="en"
  else
    whisper_model="ggml-base.bin"
    whisper_lang="$VOICE_LANGUAGE"
  fi
  local transcribe_cmd="whisper-cpp --model ~/.local/share/whisper-cpp/models/${whisper_model} --language ${whisper_lang} --output-txt \"\$1\""
  local s_transcribe;    s_transcribe="$(sanitize "$transcribe_cmd")"

  # TTS command based on voice engine
  local tts_cmd=""
  if [[ "$VOICE_ENGINE" == "say" ]]; then
    tts_cmd="say -v \"$VOICE_NAME\" \"\$TEXT\" -o /tmp/assistant_voice.aiff && ffmpeg -i /tmp/assistant_voice.aiff -c:a libopus -b:a 64k /tmp/assistant_voice.ogg -y"
  elif [[ "$VOICE_ENGINE" == "vibevoice" ]]; then
    tts_cmd="python3 -m vibevoice.realtime --model microsoft/VibeVoice-Realtime-0.5B --text \"\$TEXT\" --output /tmp/assistant_voice.wav && ffmpeg -i /tmp/assistant_voice.wav -c:a libopus -b:a 64k /tmp/assistant_voice.ogg -y"
  fi
  local s_tts; s_tts="$(sanitize "$tts_cmd")"

  # ── Create directory structure ───────────────────────────────────────────────

  if [[ -d "$WORKSPACE_DIR" ]]; then
    warn "Workspace already exists — adding missing files only"
  else
    mkdir -p "$WORKSPACE_DIR"
    info "Created workspace: $WORKSPACE_DIR"
  fi

  # Determine the Claude projects memory path for this workspace
  # Claude Code stores per-project memory at ~/.claude/projects/<escaped-path>/memory/
  local escaped_ws
  escaped_ws=$(echo "$WORKSPACE_DIR" | sed 's|/|-|g')
  MEMORY_DIR="$HOME/.claude/projects/${escaped_ws}/memory"

  mkdir -p \
    "$WORKSPACE_DIR/projects" \
    "$WORKSPACE_DIR/templates" \
    "$WORKSPACE_DIR/tools" \
    "$WORKSPACE_DIR/.claude" \
    "$WORKSPACE_DIR/.remember" \
    "$MEMORY_DIR"

  # ── Template substitution helper ─────────────────────────────────────────────
  # Copies src → dst with all {{VAR}} substitutions applied.
  # Skips if dst already exists (idempotent).

  _apply_template() {
    local src="$1" dst="$2"
    [[ ! -f "$src" ]] && return    # source doesn't exist yet (parallel writer may add it later)
    [[ -f "$dst" ]]  && return    # don't overwrite existing user files

    sed \
      -e "s|{{ASSISTANT_NAME}}|${s_name}|g" \
      -e "s|{{USER_NAME}}|${s_user}|g" \
      -e "s|{{USER_ROLE}}|${s_role}|g" \
      -e "s|{{PROJECT_COUNT}}|${s_count}|g" \
      -e "s|{{WORK_HOURS}}|${s_hours}|g" \
      -e "s|{{TIMEZONE}}|${s_tz}|g" \
      -e "s|{{WORK_EMAIL}}|${s_email}|g" \
      -e "s|{{GOOGLE_MEET}}|${s_meet}|g" \
      -e "s|{{VOICE_NAME}}|${s_vname}|g" \
      -e "s|{{VOICE_ENGINE}}|${s_vengine}|g" \
      -e "s|{{TRANSCRIBE_CMD}}|${s_transcribe}|g" \
      -e "s|{{TTS_CMD}}|${s_tts}|g" \
      "$src" > "$dst"
  }

  # CLAUDE.md — special handling for {{#VOICE_ENABLED}} blocks
  local claude_tpl="$SCRIPT_DIR/templates/CLAUDE.md.template"
  local claude_dst="$WORKSPACE_DIR/.claude/CLAUDE.md"
  if [[ -f "$claude_tpl" && ! -f "$claude_dst" ]]; then
    _apply_template "$claude_tpl" "${claude_dst}.tmp"

    if [[ "$VOICE_ENGINE" == "say" ]]; then
      # Keep say section, remove vibevoice section
      perl -0777 -i -pe \
        's/\{\{#VOICE_VIBEVOICE\}\}.*?\{\{\/VOICE_VIBEVOICE\}\}\n?//gs' \
        "${claude_dst}.tmp"
      sed -i '' \
        -e '/{{#VOICE_SAY}}/d' \
        -e '/{{\/VOICE_SAY}}/d' \
        "${claude_dst}.tmp"
    elif [[ "$VOICE_ENGINE" == "vibevoice" ]]; then
      # Keep vibevoice section, remove say section
      perl -0777 -i -pe \
        's/\{\{#VOICE_SAY\}\}.*?\{\{\/VOICE_SAY\}\}\n?//gs' \
        "${claude_dst}.tmp"
      sed -i '' \
        -e '/{{#VOICE_VIBEVOICE}}/d' \
        -e '/{{\/VOICE_VIBEVOICE}}/d' \
        "${claude_dst}.tmp"
    else
      # No voice — remove both sections
      perl -0777 -i -pe \
        's/\{\{#VOICE_SAY\}\}.*?\{\{\/VOICE_SAY\}\}\n?//gs; s/\{\{#VOICE_VIBEVOICE\}\}.*?\{\{\/VOICE_VIBEVOICE\}\}\n?//gs' \
        "${claude_dst}.tmp"
    fi
    mv "${claude_dst}.tmp" "$claude_dst"
  fi

  # Remaining template files
  local T="$SCRIPT_DIR/templates"
  _apply_template "$T/tasks.md"           "$WORKSPACE_DIR/projects/tasks.md"
  _apply_template "$T/tracker.md"         "$WORKSPACE_DIR/projects/tracker.md"
  _apply_template "$T/email-followup.md"  "$WORKSPACE_DIR/templates/email-followup.md"
  _apply_template "$T/meeting-notes.md"   "$WORKSPACE_DIR/templates/meeting-notes.md"
  _apply_template "$T/status-update.md"   "$WORKSPACE_DIR/templates/status-update.md"
  _apply_template "$T/reminders.md"       "$WORKSPACE_DIR/projects/reminders.md"
  _apply_template "$T/transcribe.sh"      "$WORKSPACE_DIR/tools/transcribe.sh"
  chmod +x "$WORKSPACE_DIR/tools/transcribe.sh" 2>/dev/null || true

  # ── Memory system (hippocampus + topic files) ────────────────────────────────
  # Memory lives in Claude Code's per-project memory dir, NOT the workspace.
  # hippocampus.md = keyword index (loaded at session start)
  # All other files = lazy-loaded on keyword match

  local M="$SCRIPT_DIR/templates/memory"
  for memfile in "$M"/*.md; do
    [[ ! -f "$memfile" ]] && continue
    local fname; fname="$(basename "$memfile")"
    _apply_template "$memfile" "$MEMORY_DIR/$fname"
  done
  info "Memory system initialized ($MEMORY_DIR)"

  # ── Copy curated settings.local.json from template ──────────────────────────
  local settings_dst="$WORKSPACE_DIR/.claude/settings.local.json"
  if [[ ! -f "$settings_dst" ]]; then
    cp "$SCRIPT_DIR/templates/settings.local.json" "$settings_dst"
    info "Created settings.local.json (curated day-1 permissions)"
  fi

  _save_inputs
  _mark_done "scaffolding"
  info "Workspace ready at $WORKSPACE_DIR"
}

# ══════════════════════════════════════════════════════════════════════════════
# Phase 7: Discord Setup
# ══════════════════════════════════════════════════════════════════════════════

phase_discord() {
  if _phase_done "discord"; then
    section "[7/9] Discord setup — already done, skipping"
    return
  fi
  section "[7/9] Discord setup..."
  echo -n "  Set up Discord messaging? (y/N): "
  read -r setup_discord

  if [[ "$setup_discord" == "y" || "$setup_discord" == "Y" ]]; then
    echo ""
    echo "  ┌─────────────────────────────────────────────────────────────┐"
    echo "  │  HOW TO CREATE A DISCORD BOT & GET YOUR TOKEN              │"
    echo "  ├─────────────────────────────────────────────────────────────┤"
    echo "  │                                                             │"
    echo "  │  1. Go to https://discord.com/developers/applications       │"
    echo "  │  2. Click 'New Application' → name it (e.g. '${ASSISTANT_NAME}')      │"
    echo "  │  3. Go to the 'Bot' tab on the left sidebar                 │"
    echo "  │  4. Click 'Reset Token' → copy the token (save it!)        │"
    echo "  │  5. Under 'Privileged Gateway Intents', enable:             │"
    echo "  │       ✓ Message Content Intent                              │"
    echo "  │  6. Go to 'OAuth2' → 'URL Generator'                       │"
    echo "  │       Scopes: bot                                           │"
    echo "  │       Permissions: Read Messages/View Channels,             │"
    echo "  │                    Send Messages, Attach Files,             │"
    echo "  │                    Read Message History                      │"
    echo "  │  7. Copy the generated URL → open in browser → invite bot   │"
    echo "  │     to your server                                          │"
    echo "  │                                                             │"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo ""
    echo -n "  Enter your Discord bot token (input hidden): "
    read -rs bot_token
    echo ""

    if [[ -n "$bot_token" ]]; then
      mkdir -p "$HOME/.claude/channels/discord"
      printf 'DISCORD_TOKEN="%s"\n' "$bot_token" > "$HOME/.claude/channels/discord/.env"
      chmod 600 "$HOME/.claude/channels/discord/.env"
      info "Discord bot token saved"
      echo ""
      echo "  After launching your assistant, pair Discord by running"
      echo "  this command in the Claude Code session:"
      echo ""
      echo "    /discord:access"
      echo ""
      echo "  Then DM your bot on Discord — it will ask you to approve"
      echo "  the pairing in your terminal."
    else
      warn "No token entered — skipping Discord setup"
    fi
  else
    info "Skipped Discord setup"
  fi
  _mark_done "discord"
}

# ── Google Workspace Authentication (part of Phase 7) ──────────────────────

phase_gws_auth() {
  if _phase_done "gws_auth"; then
    return
  fi
  echo ""
  echo -n "  Set up Google Workspace (Calendar, Gmail, Drive)? (y/N): "
  read -r setup_gws

  if [[ "$setup_gws" == "y" || "$setup_gws" == "Y" ]]; then
    if ! command -v gws &>/dev/null; then
      warn "gws CLI not found on PATH — skipping Google Workspace auth"
      echo "    Install it first: npm install -g @googleworkspace/cli"
      echo "    Then run: gws auth setup --login"
      _mark_done "gws_auth"
      return
    fi

    # Check if already authenticated
    if gws auth status 2>/dev/null | grep -q '"token_valid": true'; then
      info "Google Workspace already authenticated"
      _mark_done "gws_auth"
      return
    fi

    # Check if OAuth credentials already exist (setup already done)
    local has_client_secret=false
    if [[ -f "$HOME/.config/gws/client_secret.json" ]]; then
      has_client_secret=true
    fi

    if [[ "$has_client_secret" == false ]]; then
      echo ""
      echo "  ┌─────────────────────────────────────────────────────────────┐"
      echo "  │  GOOGLE WORKSPACE — FIRST-TIME SETUP                       │"
      echo "  ├─────────────────────────────────────────────────────────────┤"
      echo "  │                                                             │"
      echo "  │  The gws CLI needs a Google Cloud project with OAuth        │"
      echo "  │  credentials. There are two ways to set this up:            │"
      echo "  │                                                             │"
      echo "  │  Option A: Automatic (requires gcloud CLI)                  │"
      echo "  │    → 'gws auth setup --login' handles everything            │"
      echo "  │                                                             │"
      echo "  │  Option B: Manual (Google Cloud Console)                    │"
      echo "  │    1. Go to https://console.cloud.google.com                │"
      echo "  │    2. Create a project (or select existing)                 │"
      echo "  │    3. Enable APIs: Calendar, Gmail, Drive, Sheets, Docs    │"
      echo "  │    4. Create OAuth 2.0 credentials (Desktop app type)      │"
      echo "  │    5. Download the JSON → save as:                         │"
      echo "  │       ~/.config/gws/client_secret.json                     │"
      echo "  │    6. Then run: gws auth login                             │"
      echo "  │                                                             │"
      echo "  └─────────────────────────────────────────────────────────────┘"
      echo ""

      if command -v gcloud &>/dev/null; then
        echo "  gcloud CLI detected — running automatic setup..."
        echo ""
        if gws auth setup --login; then
          info "Google Workspace setup and login complete"
          _mark_done "gws_auth"
          return
        else
          warn "Automatic setup had issues"
          echo "    You can retry later: gws auth setup --login"
          echo "    Or set up manually using Option B above"
        fi
      else
        echo "  gcloud CLI not found — choose an option:"
        echo ""
        echo "    (A) Install gcloud first, then run: gws auth setup --login"
        echo "        brew install --cask google-cloud-sdk"
        echo ""
        echo "    (B) Set up manually via Google Cloud Console (see above)"
        echo "        Then run: gws auth login"
        echo ""
        echo -n "  Install gcloud now and run automatic setup? (y/N): "
        read -r install_gcloud

        if [[ "$install_gcloud" == "y" || "$install_gcloud" == "Y" ]]; then
          echo "  Installing Google Cloud SDK..."
          if brew install --cask google-cloud-sdk 2>&1; then
            # Source gcloud PATH
            if [[ -f "$(brew --prefix)/share/google-cloud-sdk/path.bash.inc" ]]; then
              source "$(brew --prefix)/share/google-cloud-sdk/path.bash.inc"
            fi
            info "gcloud installed"
            echo ""
            echo "  Running gws auth setup --login (this opens a browser)..."
            if gws auth setup --login; then
              info "Google Workspace setup and login complete"
              _mark_done "gws_auth"
              return
            else
              warn "Setup had issues — you can retry later: gws auth setup --login"
            fi
          else
            warn "Could not install gcloud"
            echo "    Set up manually using Option B above, then run: gws auth login"
          fi
        else
          echo ""
          echo "  Skipping for now. Set up later using either option above."
        fi
      fi
    else
      # Client secret exists, just need to login
      echo ""
      echo "  OAuth credentials found. Signing in with Google..."
      echo "  (This will open your browser)"
      echo ""
      if gws auth login; then
        info "Google Workspace authenticated"
      else
        warn "Login had issues — you can retry later with: gws auth login"
      fi
    fi
  else
    info "Skipped Google Workspace setup"
    echo "    Set up later: gws auth setup --login"
  fi
  _mark_done "gws_auth"
}

# ══════════════════════════════════════════════════════════════════════════════
# Phase 8: Create Launcher App
# ══════════════════════════════════════════════════════════════════════════════

phase_launcher() {
  if _phase_done "launcher"; then
    section "[8/9] Launcher app — already done, skipping"
    _load_inputs  # restore SKIP_PERMISSIONS and ASSISTANT_NAME for summary
    return
  fi
  section "[8/9] Creating macOS launcher app..."

  # ── Consent prompt for --dangerously-skip-permissions ────────────────────────

  echo ""
  echo "  The launcher can start your assistant without per-action prompts."
  echo "  This uses Claude Code's --dangerously-skip-permissions flag."
  echo ""
  echo "  What this means:"
  echo "    • Your assistant runs tools (bash, file I/O) without asking each time"
  echo "    • Convenient for a trusted personal assistant"
  echo "    • Only enable if you trust the CLAUDE.md in your workspace"
  echo ""
  echo -n "  Enable auto-approve mode? (y/N): "
  read -r consent
  if [[ "$consent" == "y" || "$consent" == "Y" ]]; then
    SKIP_PERMISSIONS=true
    echo "  Auto-approve enabled."
  else
    SKIP_PERMISSIONS=false
    echo "  Auto-approve disabled — assistant will prompt before each action."
  fi

  local skip_flag=""
  [[ "$SKIP_PERMISSIONS" == true ]] && skip_flag="--dangerously-skip-permissions"

  # ── Build macOS .app bundle ───────────────────────────────────────────────────

  local app_dir="$HOME/Applications/${ASSISTANT_NAME}.app"
  local contents_dir="$app_dir/Contents"
  local macos_dir="$contents_dir/MacOS"
  mkdir -p "$macos_dir"

  # Info.plist — use template if it has real content, otherwise write inline
  local plist_tpl="$SCRIPT_DIR/launcher/Info.plist.template"
  local plist_dst="$contents_dir/Info.plist"
  local tpl_lines; tpl_lines=$(wc -l < "$plist_tpl" 2>/dev/null || echo 0)

  if [[ "$tpl_lines" -gt 5 ]]; then
    sed \
      -e "s|{{ASSISTANT_NAME}}|${ASSISTANT_NAME}|g" \
      -e "s|{{WORKSPACE_DIR}}|${WORKSPACE_DIR}|g" \
      "$plist_tpl" > "$plist_dst"
  else
    cat > "$plist_dst" << PLIST_EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>${ASSISTANT_NAME}</string>
  <key>CFBundleDisplayName</key>
  <string>${ASSISTANT_NAME}</string>
  <key>CFBundleIdentifier</key>
  <string>com.claude-assistant.${ASSISTANT_NAME}</string>
  <key>CFBundleVersion</key>
  <string>1.0</string>
  <key>CFBundleExecutable</key>
  <string>launcher</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>LSUIElement</key>
  <false/>
</dict>
</plist>
PLIST_EOF
  fi

  # Launcher script (inside .app/Contents/MacOS/) — use template if available
  local launcher_tpl="$SCRIPT_DIR/launcher/launcher.template"
  local launcher_dst="$macos_dir/launcher"
  local launcher_lines; launcher_lines=$(wc -l < "$launcher_tpl" 2>/dev/null || echo 0)

  if [[ "$launcher_lines" -gt 2 ]]; then
    sed \
      -e "s|{{ASSISTANT_NAME}}|${ASSISTANT_NAME}|g" \
      -e "s|{{WORKSPACE_DIR}}|${WORKSPACE_DIR}|g" \
      -e "s|{{SKIP_PERMISSIONS_FLAG}}|${skip_flag}|g" \
      "$launcher_tpl" > "$launcher_dst"
  else
    # Write launcher inline — opens Terminal at the workspace and runs start.sh
    cat > "$launcher_dst" << LAUNCHER_EOF
#!/bin/zsh
# ${ASSISTANT_NAME} Assistant — macOS App Launcher
open -a Terminal "${WORKSPACE_DIR}/start.sh"
LAUNCHER_EOF
  fi
  chmod +x "$launcher_dst"

  # ── start.sh in workspace root ───────────────────────────────────────────────

  local start_sh="${WORKSPACE_DIR}/start.sh"
  if [[ ! -f "$start_sh" ]]; then
    cat > "$start_sh" << STARTSH_EOF
#!/bin/zsh
# Start ${ASSISTANT_NAME} Assistant
# Usage: ./start.sh

# Ensure claude is on PATH (common install locations)
export PATH="\$HOME/.local/bin:\$HOME/.npm-global/bin:/usr/local/bin:\$PATH"
[[ -f /opt/homebrew/bin/brew ]] && eval "\$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null

cd "${WORKSPACE_DIR}"
exec claude --channels plugin:discord@claude-plugins-official ${skip_flag}
STARTSH_EOF
    chmod +x "$start_sh"
    info "Created start.sh"
  fi

  _save_inputs
  _mark_done "launcher"
  info "Launcher app: ~/Applications/${ASSISTANT_NAME}.app"
  info "Drag it to the Dock for quick access"
}

# ══════════════════════════════════════════════════════════════════════════════
# Phase 9: Summary
# ══════════════════════════════════════════════════════════════════════════════

phase_summary() {
  # Ensure all variables are loaded (needed when earlier phases were skipped)
  [[ -z "$ASSISTANT_NAME" ]] && _load_inputs
  section "[9/9] Setup complete!"
  echo ""
  echo "  ┌─────────────────────────────────────────────┐"
  printf "  │  %-43s │\n" "${ASSISTANT_NAME} Assistant is ready!"
  echo "  └─────────────────────────────────────────────┘"
  echo ""
  echo "  Installed:"
  echo "    Workspace : $WORKSPACE_DIR"
  echo "    Launcher  : ~/Applications/${ASSISTANT_NAME}.app"

  echo "    Language  : ${VOICE_LANGUAGE:-en}"
  case "$VOICE_ENGINE" in
    say)        echo "    Voice     : $VOICE_NAME (macOS say)" ;;
    vibevoice)  echo "    Voice     : VibeVoice AI (speaker: $VOICE_NAME)" ;;
    *)          echo "    Voice     : disabled" ;;
  esac

  if [[ -f "$HOME/.claude/channels/discord/.env" ]]; then
    echo "    Discord   : configured ✓"
  else
    echo "    Discord   : not configured (re-run setup to add)"
  fi

  if command -v gws &>/dev/null && gws auth status 2>/dev/null | grep -q '"token_valid": true'; then
    echo "    Google WS : authenticated ✓"
  elif command -v gws &>/dev/null; then
    echo "    Google WS : gws CLI installed, not authenticated (run: gws auth login)"
  else
    echo "    Google WS : not installed (run: npm install -g @googleworkspace/cli)"
  fi

  if [[ "$SKIP_PERMISSIONS" == true ]]; then
    echo "    Mode      : auto-approve (--dangerously-skip-permissions)"
  else
    echo "    Mode      : interactive (prompts before each action)"
  fi

  echo ""
  echo "  How to start:"
  echo "    • Double-click ~/Applications/${ASSISTANT_NAME}.app"
  echo "    • Or: cd \"$WORKSPACE_DIR\" && ./start.sh"
  echo ""

  # Clean up state files — setup completed successfully
  rm -f "$STATE_FILE" "${STATE_FILE}.vars"

  echo -n "  Launch your assistant now? (y/N): "
  read -r launch_now
  if [[ "$launch_now" == "y" || "$launch_now" == "Y" ]]; then
    echo ""
    echo "  Starting ${ASSISTANT_NAME}..."
    cd "$WORKSPACE_DIR" || exit 1
    local skip_flag=""
    [[ "$SKIP_PERMISSIONS" == true ]] && skip_flag="--dangerously-skip-permissions"
    # shellcheck disable=SC2086
    exec claude --channels plugin:discord@claude-plugins-official $skip_flag
  else
    echo ""
    echo "  All done! Run ./start.sh in your workspace whenever you're ready."
  fi
}

# ══════════════════════════════════════════════════════════════════════════════
# Main
# ══════════════════════════════════════════════════════════════════════════════

main() {
  phase_preflight
  phase_system_deps
  phase_plugins
  phase_gstack
  phase_voice
  phase_whisper
  phase_scaffolding
  phase_discord
  phase_gws_auth
  phase_launcher
  phase_summary
}

main "$@"
