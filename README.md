```
███╗   ███╗██╗██████╗  █████╗
████╗ ████║██║██╔══██╗██╔══██╗
██╔████╔██║██║██████╔╝███████║
██║╚██╔╝██║██║██╔══██╗██╔══██║
██║ ╚═╝ ██║██║██║  ██║██║  ██║
╚═╝     ╚═╝╚═╝╚═╝  ╚═╝╚═╝  ╚═╝
```

One-command installer for a Claude Code Executive Assistant with voice, Discord, and Google Calendar.

---

## What You Get

- AI executive assistant running as a Claude Code session
- Voice transcription (speech-to-text via whisper-cpp)
- Voice replies (text-to-speech via macOS `say` or VibeVoice neural TTS)
- Discord messaging integration
- Google Calendar and email access
- Task management, project tracking, and meeting scheduling
- macOS launcher app (double-click to start)

---

## Prerequisites

- macOS (Apple Silicon or Intel)
- [Claude Code CLI](https://claude.ai/code) installed and authenticated (requires Pro, Max, or Team subscription)
- Terminal.app
- ~500MB free disk space (whisper model + optional voice downloads)
- Google Workspace access requires a Google account and `gws auth login`

---

## Quick Start

```bash
git clone https://github.com/USER/mira-assistant-setup.git
cd mira-assistant-setup
./setup.sh
```

The installer walks you through 9 phases, prompting for your name, role, timezone, and preferences. Most steps are automatic.

---

## What Gets Installed

| Component | Location | Approx. Size |
|---|---|---|
| System deps (whisper-cpp, ffmpeg, node, bun, jq) | via Homebrew | ~200MB |
| Claude plugins (discord, remember, claude-md-management, hookify, superpowers) | `~/.claude/plugins/` | ~20MB |
| gstack skills | `~/.claude/skills/gstack/` | ~5MB |
| Whisper model (ggml-base.en.bin) | `~/.local/share/whisper-cpp/models/` | ~150MB |
| Voice — standard (macOS say) | built-in | 0 |
| Voice — premium (VibeVoice, optional) | `~/.local/share/vibevoice/` | ~2.5GB |
| Workspace | `~/{AssistantName}_Assistant/` | ~1MB |
| Launcher app | `~/Applications/{AssistantName}.app` | ~1MB |

---

## Setup Prompts

The installer asks for the following information. All prompts have defaults you can accept by pressing Enter.

| Variable | Prompt | Default |
|---|---|---|
| `ASSISTANT_NAME` | What should your assistant be called? | `Mira` |
| `USER_NAME` | Your name | (required) |
| `USER_ROLE` | Your role or title | `professional` |
| `PROJECT_COUNT` | Concurrent projects to track | `5` |
| `WORK_HOURS` | Working hours | `9am - 6pm ET` |
| `TIMEZONE` | Your timezone | `America/New_York` |
| `WORK_EMAIL` | Your work email address | (required) |
| `GOOGLE_MEET` | Auto-add Google Meet to meetings? | `no` |
| `VOICE_NAME` | Voice selection (see Voice Options below) | `Allison (Enhanced)` |

---

## Voice Options

Voice is configured in an interactive menu during setup.

**1. Standard (macOS say) — recommended for most users**

Zero additional installation. Uses voices already on your Mac. Seven voice choices including Samantha, Alex, and others. Good quality, instant response.

To add more voices: System Settings > Accessibility > Spoken Content > System Voice > Manage Voices.

**2. Premium (VibeVoice) — optional**

Neural TTS with excellent quality. Requires Python 3.10+ and a 2.5GB model download. Runs locally on your machine. The installer handles setup if you choose this option.

**3. Skip — text-only replies**

No voice output. The assistant operates entirely via text in the Claude Code session.

---

## Google Workspace (Calendar, Gmail, Drive)

- Uses the [gws plugin](https://github.com/WadeWarren/gws-claude-plugin) + [gws CLI](https://github.com/googleworkspace/cli)
- The installer adds the gws plugin marketplace, installs the plugin, and installs the gws CLI via npm
- During setup, you'll run `gws auth setup` (creates a Google Cloud project + OAuth credentials) and `gws auth login` (browser-based Google sign-in)
- Supports 92 Google Workspace skills: Calendar, Gmail, Drive, Sheets, Docs, and more
- Works in CLI `--channels` mode (unlike Claude's built-in Google Calendar MCP which is web-only)

---

## Discord Setup

Discord integration is optional. To enable it:

1. Go to [discord.com/developers/applications](https://discord.com/developers/applications) and create a new application
2. Under Bot, create a bot and copy the token
3. Required permissions: Read Messages, Send Messages, Attach Files, Read Message History
4. Invite the bot to your server with those permissions
5. Paste the bot token when the installer prompts for it

The token is stored locally at `~/.claude/channels/discord/.env` with `chmod 600` permissions.

---

## Customization

After installation, all configuration files are yours to edit.

- **Personality and responsibilities** — Edit `CLAUDE.md` in your workspace directory. The assistant reads this on startup.
- **Permissions** — Edit `settings.local.json` in your workspace to adjust which tools and actions the assistant can take.
- **Templates** — All files in the workspace `templates/` directory can be modified freely.
- **Voice** — Change the `VOICE_NAME` setting in `CLAUDE.md` or re-run `./setup.sh` to reconfigure.

---

## Uninstalling

```bash
./uninstall.sh
```

The uninstaller is conservative: it prompts before removing each component and never touches Homebrew packages or Claude plugins that may be shared with other projects. Your workspace files are preserved unless you explicitly confirm their removal.

---

## Troubleshooting

**"claude: command not found"**
Install the Claude Code CLI from [claude.ai/code](https://claude.ai/code) and make sure it is on your PATH before running setup.

**"Homebrew not found"**
The installer detects this and offers to install Homebrew for you. Accept the prompt or install it manually from [brew.sh](https://brew.sh).

**Voice not available in macOS say**
The voice you selected may not be downloaded yet. Go to System Settings > Accessibility > Spoken Content > System Voice > Manage Voices and download it, then re-run `./setup.sh`.

**gstack clone failed**
The gstack repository may be private. The installer will print manual installation instructions if the clone fails. Follow those steps and then re-run `./setup.sh`.

**Google Workspace not working**
Run `gws auth status` to check if you're authenticated. If not, run `gws auth login`. If the gws CLI isn't installed, run `npm install -g @googleworkspace/cli`. If `gws auth setup` hasn't been run yet, run it first to create OAuth credentials.

**Whisper model download failed**
The installer retries up to 3 times automatically. If it still fails, check your internet connection and available disk space (~150MB needed), then re-run `./setup.sh`.

**"claude plugin add" hangs waiting for input**
Some plugin installs may require interactive confirmation. The installer attempts to pass `--yes` where supported. If it hangs, press Enter or type `y` to confirm.

---

## Idempotent

Running `./setup.sh` again is safe. Each phase checks whether its work is already done before acting — installed packages are skipped, existing files are not overwritten, plugins already present are left alone. Re-running after a partial install resumes from where it left off.

---

## License

MIT
