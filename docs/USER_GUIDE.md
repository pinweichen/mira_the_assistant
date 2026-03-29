# Mira Assistant Setup - User Guide

A complete walkthrough for installing, using, and customizing your AI executive assistant.

---

## Table of Contents

1. [What is Mira Assistant?](#what-is-mira-assistant)
2. [Before You Start](#before-you-start)
3. [Installation Walkthrough](#installation-walkthrough)
4. [Using Your Assistant](#using-your-assistant)
5. [Voice Messages](#voice-messages)
6. [Calendar and Scheduling](#calendar-and-scheduling)
7. [Task Management](#task-management)
8. [Discord Integration](#discord-integration)
9. [Customization](#customization)
10. [Uninstalling](#uninstalling)
11. [Troubleshooting](#troubleshooting)
12. [Architecture Reference](#architecture-reference)

---

## 1. What is Mira Assistant?

Mira is an AI executive assistant powered by Claude Code. Once installed, it runs as a persistent Claude Code session that can:

- **Manage your tasks** -- parse verbal/text task dumps into organized action items, schedule them on your calendar, track time estimates vs actuals
- **Handle your calendar** -- check availability, schedule meetings with external attendees, protect focus time, send calendar invites
- **Transcribe voice messages** -- receive Discord voice messages, transcribe them with whisper-cpp, and reply with voice or text
- **Draft communications** -- write emails, Slack messages, status updates, meeting notes in your tone
- **Track projects** -- maintain a master project tracker with status, deadlines, blockers, and owners
- **Prep for meetings** -- generate briefing docs with context, key points, and questions to ask

Everything runs locally on your Mac. Your data stays on your machine.

---

## 2. Before You Start

### Required

| Requirement | How to Check | How to Get It |
|---|---|---|
| macOS (Apple Silicon or Intel) | You're on a Mac | -- |
| Claude Code CLI | Run `claude --version` in Terminal | Install from [claude.ai/code](https://claude.ai/code) |
| Claude Pro, Max, or Team subscription | Check [claude.ai/settings](https://claude.ai/settings) | Subscribe at [claude.ai](https://claude.ai) |
| Terminal.app | Already installed on every Mac | -- |
| ~500MB free disk space | `df -h ~` | Free up space |

### Optional (for full features)

| Feature | Requirement |
|---|---|
| Google Calendar access | Claude **Max** or **Team** subscription (gws plugin) |
| Discord messaging | A Discord bot token ([create one here](https://discord.com/developers/applications)) |
| Premium AI voice (VibeVoice) | Python 3.9+, ~2.5GB disk space |

### Creating a Discord Bot (if you want Discord integration)

1. Go to [discord.com/developers/applications](https://discord.com/developers/applications)
2. Click **New Application**, give it a name (e.g., "Mira")
3. Go to **Bot** in the left sidebar
4. Click **Reset Token** and copy the token -- you'll need it during setup
5. Under **Privileged Gateway Intents**, enable **Message Content Intent**
6. Go to **OAuth2 > URL Generator**
   - Scopes: select **bot**
   - Bot Permissions: select **Read Messages/View Channels**, **Send Messages**, **Attach Files**, **Read Message History**
7. Copy the generated URL, open it in your browser, and invite the bot to your server

Save that bot token somewhere safe. The installer will ask for it.

---

## 3. Installation Walkthrough

### Step 1: Clone and Run

Open Terminal and run:

```bash
git clone https://github.com/USER/mira-assistant-setup.git
cd mira-assistant-setup
./setup.sh
```

### Step 2: The Installer Phases

The installer runs 9 phases. Here's what happens at each one and what you need to do:

---

#### Phase 0: Preflight Checks

```
╔══════════════════════════════════════════╗
║  Claude Code Executive Assistant Setup   ║
╚══════════════════════════════════════════╝

This will install:
  * System dependencies (whisper-cpp, ffmpeg, node, bun, jq)
  * Claude Code plugins (discord, remember, claude-md-management,
                         hookify, superpowers, gws)
  * gstack skills
  * Whisper speech-to-text model (~150MB)
  * Voice setup (optional)
  * Personalized assistant workspace
  * macOS launcher app

Continue? (Y/n):
```

**What to do:** Press Enter (or type `Y`) to continue.

The installer checks that you have macOS, Homebrew, and the Claude CLI. If Homebrew is missing, it offers to install it for you.

---

#### Phase 1: System Dependencies

Installs via Homebrew: `whisper-cpp`, `ffmpeg`, `node`, `bun`, `jq`

**What to do:** Nothing. This is automatic. Already-installed packages are skipped.

Typical output:
```
[1/9] Installing system dependencies...
  ✓ whisper-cpp (already installed)
  ✓ ffmpeg (already installed)
  Installing node...
  ✓ node installed
  ✓ bun (already installed)
  ✓ jq (already installed)
```

---

#### Phase 2: Claude Code Plugins

Installs 6 plugins into Claude Code:

| Plugin | Purpose |
|---|---|
| `discord` | Send and receive Discord messages |
| `remember` | Persistent memory across sessions |
| `claude-md-management` | Manages CLAUDE.md files |
| `hookify` | Event-driven hooks for automation |
| `superpowers` | Extended Claude Code capabilities |
| `gws` | Google Calendar and email access |

**What to do:** Nothing. Automatic. If a plugin install hangs, press Enter or type `y`.

---

#### Phase 3: gstack Skills

Clones the gstack skill library to `~/.claude/skills/gstack/`.

**What to do:** Nothing. If it fails (repo might be private), the installer prints manual instructions and continues.

---

#### Phase 4: Whisper Model

Downloads the English speech-to-text model (~150MB) to `~/.local/share/whisper-cpp/models/ggml-base.en.bin`.

**What to do:** Wait for the download. If your internet drops, the installer retries up to 3 times.

---

#### Phase 5: Voice Setup

This is interactive. You'll see a menu:

```
  Choose a voice for your assistant's replies:

  Standard voices (macOS say -- zero install):
    1) Allison (Enhanced)  -- Female
    2) Ava (Premium)       -- Female
    3) Samantha (Enhanced) -- Female
    4) Zoe (Enhanced)      -- Female
    5) Tom (Enhanced)      -- Male
    6) Evan (Enhanced)     -- Male
    7) Daniel              -- Male (built-in)

  Premium AI voice:
    8) VibeVoice AI        -- Premium quality (Python + ~2.5GB download)

    9) Skip -- no voice replies

  Select [1-9]:
```

**What to do:** Type a number and press Enter.

- **Options 1-7**: Uses macOS built-in text-to-speech. Zero additional downloads. If the voice isn't installed on your system, the installer tells you how to download it from System Settings.
- **Option 8**: VibeVoice is a high-quality neural voice. Requires Python and a 2.5GB model download. The installer handles everything.
- **Option 9**: Skip voice entirely. Your assistant will only reply with text.

**Recommended:** Option 1 (Allison) for most users. It's high quality and usually pre-installed.

After selecting, you'll be asked if you want to preview the voice. Say yes to hear it.

---

#### Phase 6: Personalization Prompts

This is where you make it yours. You'll be asked 8 questions:

```
  Assistant name [Mira]:
  Workspace directory [~/Mira_Assistant]:
  Your first name (required):
  Your role [professional]:
  Concurrent projects to track [5]:
  Working hours [9am - 6pm ET]:
  Timezone [America/New_York]:
  Work email (required):
  Auto-add Google Meet links to meetings? (y/N):
```

**What to do for each prompt:**

| Prompt | What to Enter | Default (press Enter) |
|---|---|---|
| Assistant name | Keep "Mira" unless you want a different name | Mira |
| Workspace directory | Where your assistant's files live | ~/Mira_Assistant |
| Your first name | Your name (e.g., "Sarah") | *required* |
| Your role | Brief description (e.g., "product manager at Acme") | professional |
| Projects to track | Number of concurrent projects | 5 |
| Working hours | Your schedule (e.g., "8am - 5pm PT") | 9am - 6pm ET |
| Timezone | IANA timezone (e.g., "America/Chicago") | America/New_York |
| Work email | Your work email for calendar invites | *required* |
| Google Meet | Whether to auto-add Meet links to new meetings | no |

**Tip:** For most prompts, pressing Enter accepts the default in brackets. Only "Your first name" and "Work email" are required.

---

#### Phase 7: Discord Setup

```
  Set up Discord messaging? (y/N):
```

**What to do:**
- Type `y` if you have a Discord bot token ready (from the "Before You Start" section)
- Type `n` or press Enter to skip (you can set this up later)

If you say yes:
```
  Enter your Discord bot token (input hidden):
```

Paste your bot token. The characters won't appear on screen (this is normal, it's hidden for security). Press Enter.

---

#### Phase 8: Launcher App

```
  The launcher can start your assistant without per-action prompts.
  This uses Claude Code's --dangerously-skip-permissions flag.

  What this means:
    * Your assistant runs tools (bash, file I/O) without asking each time
    * Convenient for a trusted personal assistant
    * Only enable if you trust the CLAUDE.md in your workspace

  Enable auto-approve mode? (y/N):
```

**What to do:**
- Type `y` for convenience -- the assistant runs without asking permission for each action. This is what most people want for a personal assistant.
- Type `n` if you prefer the assistant to ask before each action (more cautious, but interrupts the flow).

---

#### Phase 9: Done!

```
  ┌─────────────────────────────────────────────┐
  │  Mira Assistant is ready!                    │
  └─────────────────────────────────────────────┘

  Installed:
    Workspace : /Users/you/Mira_Assistant
    Launcher  : ~/Applications/Mira.app
    Voice     : Allison (macOS say)
    Discord   : configured ✓
    Mode      : auto-approve (--dangerously-skip-permissions)

  How to start:
    * Double-click ~/Applications/Mira.app
    * Or: cd "/Users/you/Mira_Assistant" && ./start.sh

  Launch your assistant now? (y/N):
```

**What to do:** Type `y` to start immediately, or `n` to start later.

---

## 4. Using Your Assistant

### Starting Mira

Three ways to start your assistant:

**Option A: Double-click the app** (recommended)
1. Open Finder
2. Navigate to ~/Applications/
3. Double-click **Mira.app**
4. Drag it to the Dock for quick access in the future

**Option B: Terminal command**
```bash
cd ~/Mira_Assistant && ./start.sh
```

**Option C: Manual**
```bash
cd ~/Mira_Assistant
claude --channels plugin:discord@claude-plugins-official
```

### What Happens on Startup

When Mira starts, she offers a brief check-in:

```
Good morning, Sarah. Here's your day:

1. 10:00 AM - Sprint planning (30 min)
2. 2:00 PM - 1:1 with Jordan
3. Overdue: Follow up with design team (due yesterday)

2 unscheduled tasks in the backlog. Want me to find time for them?
```

She checks:
- Today's Google Calendar events
- Your task board (`projects/tasks.md`) for scheduled and overdue items
- Your project tracker (`projects/tracker.md`) for approaching deadlines

### Talking to Mira

Just type naturally. Mira understands informal, conversational requests:

**Task management:**
- "I need to review the Q3 budget, write the board update, and follow up with marketing about the launch date"
- "What's on my plate today?"
- "Mark the budget review as done, it took about 45 minutes"

**Calendar:**
- "Schedule a meeting with Sarah at sarah@acme.com about the partnership, sometime this week"
- "What does my Thursday look like?"
- "Block 2 hours tomorrow morning for deep work"

**Email drafts:**
- "Draft a follow-up email to Jordan about the design review we had Tuesday"
- "Write a status update for the Falcon project"

**Research:**
- "Summarize what we know about the competitor's new pricing model"
- "Prep me for my meeting with the CFO tomorrow"

---

## 5. Voice Messages

### Sending Voice Messages to Mira (via Discord)

1. Open Discord on your phone or desktop
2. Go to the DM channel with your Mira bot
3. Record a voice message (hold the mic button)
4. Send it

Mira will:
1. Download the audio file
2. Convert it to the right format with ffmpeg
3. Transcribe it with whisper-cpp
4. Show you the transcription
5. Respond to what you said

### Receiving Voice Replies

If you set up a voice in Phase 5, Mira can reply with audio:

- She generates speech using your chosen voice
- Converts it to Discord-compatible format (opus/ogg)
- Sends it as an audio attachment in Discord
- Falls back to text for code, tables, links, and long lists

### Example Flow

```
You (voice message): "Hey Mira, can you check if I have anything
                      tomorrow afternoon and schedule a 30-minute
                      call with Alex at alex@startup.com?"

Mira: [transcription] "Hey Mira, can you check if I have anything
       tomorrow afternoon and schedule a 30-minute call with Alex
       at alex@startup.com?"

Mira: Checking your calendar for tomorrow afternoon...

      You're free from 1:00 PM - 5:00 PM. Here are some options:
        A) 1:00 PM - 1:30 PM
        B) 2:00 PM - 2:30 PM
        C) 3:30 PM - 4:00 PM

      Which works?

You: B

Mira: Created:
      Meeting: Call with Alex
      When: Tomorrow 2:00 - 2:30 PM
      Attendees: you + alex@startup.com
      Alex will receive a calendar invite.

Mira (voice reply): [audio] "Done! I scheduled your call with Alex
                     for tomorrow at 2 PM. He'll get an invite."
```

---

## 6. Calendar and Scheduling

### Prerequisites

Google Calendar access requires:
- Claude **Max** or **Team** subscription
- The **gws** plugin (installed during setup)
- First-time Google OAuth (Claude prompts you automatically)

### First-Time Setup

The first time Mira tries to access your calendar, Claude will open a browser window asking you to sign in with Google and grant calendar permissions. This is a one-time setup.

### What Mira Can Do

| Action | How to Ask |
|---|---|
| Check your schedule | "What's on my calendar today?" |
| Find free time | "When am I free this week?" |
| Schedule a meeting | "Schedule a call with Alex at alex@acme.com" |
| Check mutual availability | "Find a time that works for me and sarah@acme.com" |
| Create a focus block | "Block 2 hours tomorrow for deep work" |
| Reschedule | "Move my 2pm to 3pm" |
| Cancel | "Cancel my meeting with Sarah tomorrow" |
| Recurring meetings | "Set up a weekly 1:1 with Jordan, Tuesdays at 10am" |

### How Meeting Scheduling Works

1. You tell Mira who, when, and what
2. Mira parses the request and asks for anything missing (email, time, etc.)
3. Mira checks your calendar for conflicts
4. If no time specified, Mira suggests 2-3 open slots
5. Mira shows a confirmation summary:
   ```
   Meeting: Q3 Planning with Sarah
   When: Thursday 2:00 - 2:30 PM
   Attendees: sarah@acme.com
   Google Meet: yes
   ```
6. You confirm, Mira creates the event
7. Attendees receive email invites automatically

### Calendar Tips

- Mira checks **all** your calendars (work, personal, family) before scheduling
- Default meeting duration is 30 minutes unless you specify otherwise
- Google Meet links are added based on your setup preference (Phase 6 prompt)
- Your work email receives invites for all events so they appear in Outlook/etc.

---

## 7. Task Management

### How the Task Board Works

Your tasks live in `~/Mira_Assistant/projects/tasks.md`. This is the single source of truth.

Tasks flow through stages:

```
Unscheduled  -->  Scheduled (with calendar time block)  -->  Completed
```

### Adding Tasks

Just tell Mira informally:

```
You: I need to finish the quarterly report, review the new hire's
     PR, and send that follow-up to the legal team about the contract

Mira: Got it. Here's what I parsed:

      1. Finish quarterly report
         Project: Q3 Reporting | Priority: P1 | Est: 2 hours

      2. Review new hire's PR
         Project: Engineering | Priority: P1 | Est: 30 min

      3. Follow up with legal about contract
         Project: Legal/Compliance | Priority: P2 | Est: 15 min

      Add these to the task board? I can also schedule them if
      you'd like.
```

Mira never adds tasks without your confirmation.

### Scheduling Tasks

```
You: Yeah, schedule all three. Put the quarterly report in a
     focus block tomorrow morning.

Mira: Checking your calendar...

      Scheduled:
      * Quarterly report -- Tomorrow 9:00-11:00 AM (calendar event created)
      * Review PR -- Tomorrow 11:00-11:30 AM (calendar event created)
      * Legal follow-up -- Tomorrow 2:00-2:15 PM (calendar event created)

      You'll get calendar invites at your work email.
```

### Time Tracking

When you complete a task, tell Mira how long it actually took:

```
You: Done with the quarterly report. Took about 2.5 hours.

Mira: Logged. Estimated 2h, actual 2.5h. I'll adjust future
      estimates for similar tasks.
```

Mira maintains a weekly summary of estimated vs actual time, and uses that data to get better at estimating.

### Project Tracker

The master project tracker lives at `~/Mira_Assistant/projects/tracker.md`. Mira updates it as you share information:

```
You: The Falcon project is blocked -- waiting on the API docs from
     the partner team. They said end of week.

Mira: Updated tracker:
      Falcon | Status: At Risk | Blocker: Waiting on partner API docs
      Follow-up date: Friday
```

---

## 8. Discord Integration

### How It Works

When Mira is running, she monitors your Discord DMs through the bot you created. You can message her from your phone, desktop, or web.

### What You Can Do via Discord

Everything you can do in the Terminal session, you can also do via Discord:
- Send text messages (task dumps, questions, requests)
- Send voice messages (transcribed automatically)
- Receive text replies
- Receive voice replies (if voice is enabled)
- Receive file attachments (reports, drafts, etc.)

### Tips

- Mira only responds in channels/DMs where the bot is present
- Voice messages are transcribed and shown back to you before Mira responds
- For long or complex requests, text is better than voice (less transcription ambiguity)
- Mira falls back to text for code, tables, and links even if voice is enabled

---

## 9. Customization

### Changing Mira's Personality

Edit `~/Mira_Assistant/.claude/CLAUDE.md`. This is the file that defines who Mira is and how she behaves. You can change:

- Communication style (more formal, more casual, etc.)
- Responsibilities (add new ones, remove ones you don't need)
- Session start behavior (what she checks on startup)
- Working hours and scheduling preferences

### Changing Permissions

Edit `~/Mira_Assistant/.claude/settings.local.json`. This controls what tools Mira can use without asking. The default set includes:

- Google Calendar tools (list, create, update, delete events, check availability)
- Discord tools (fetch messages, reply, download attachments, react)
- Whisper transcription commands
- FFmpeg audio conversion
- macOS `say` for voice output

To add a new permission, add it to the `allow` array. To restrict something, remove it.

### Templates

Your workspace includes editable templates in `~/Mira_Assistant/templates/`:

| File | Purpose |
|---|---|
| `email-followup.md` | Template for follow-up emails |
| `meeting-notes.md` | Template for meeting notes |
| `status-update.md` | Template for project status updates |

Edit these to match your style. Mira uses them as starting points when drafting.

### Changing the Voice

To change the voice after installation:

1. Edit `~/Mira_Assistant/.claude/CLAUDE.md`
2. Find the "Voice Replies" section
3. Change the voice name in the `say -v` command (e.g., `say -v "Tom"`)
4. Make sure the voice is installed: System Settings > Accessibility > Spoken Content > Manage Voices

### Re-running Setup

You can safely re-run `./setup.sh` at any time. It's idempotent:
- Already-installed packages, plugins, and models are skipped
- Existing workspace files are NOT overwritten
- You'll be prompted again for personalization (but existing files won't change)

---

## 10. Uninstalling

```bash
cd mira-assistant-setup
./uninstall.sh
```

The uninstaller is conservative. It prompts before every removal:

```
▸ Step 1: Assistant workspace directory
  Detected workspace: /Users/you/Mira_Assistant
  Remove workspace directory '/Users/you/Mira_Assistant'? (y/N)
```

### What Gets Removed (with your confirmation)

| Component | Location |
|---|---|
| Workspace directory | ~/Mira_Assistant/ |
| Launcher app | ~/Applications/Mira.app |
| gstack skills | ~/.claude/skills/gstack/ |
| Whisper model | ~/.local/share/whisper-cpp/models/ggml-base.en.bin |
| Discord config | ~/.claude/channels/discord/.env |
| VibeVoice (if installed) | pip package + model cache |

### What Is Always Preserved

| Component | Why |
|---|---|
| Homebrew packages | May be used by other tools |
| Claude Code plugins | May be shared across projects |
| Global Claude settings | Affects all Claude Code sessions |
| Other Claude workspaces | Not ours to touch |

### Non-interactive Mode

To remove everything without prompts:
```bash
./uninstall.sh --yes
```

---

## 11. Troubleshooting

### "claude: command not found"

The Claude Code CLI isn't installed or isn't on your PATH.

**Fix:** Install from [claude.ai/code](https://claude.ai/code). After install, restart Terminal or run `source ~/.zshrc`.

### "Homebrew not found"

**Fix:** The installer offers to install it. Or manually: visit [brew.sh](https://brew.sh).

### Voice not working / "Voice X is not installed"

The enhanced/premium macOS voices need to be downloaded separately.

**Fix:**
1. Open **System Settings**
2. Go to **Accessibility > Spoken Content**
3. Click **System Voice > Manage Voices**
4. Find your voice (e.g., "Allison") and click the download arrow
5. Wait for download to complete

### Google Calendar not connecting

Possible causes:
- You need a Claude **Max** or **Team** subscription
- The gws plugin wasn't installed (run `claude plugin add gws`)
- OAuth hasn't been completed yet (Mira will prompt you on first calendar access)

### Discord bot not responding

Check:
1. Is the bot online? Check Discord > your server > member list
2. Is the bot invited to the right server/channel?
3. Is Message Content Intent enabled? (Discord Developer Portal > Bot > Privileged Gateway Intents)
4. Is Mira running? (Check Terminal)

### Whisper model download failed

**Fix:** Run setup again (it retries), or manually download:
```bash
mkdir -p ~/.local/share/whisper-cpp/models
curl -fL -o ~/.local/share/whisper-cpp/models/ggml-base.en.bin \
  https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin
```

### "Permission denied" when running setup.sh

**Fix:**
```bash
chmod +x setup.sh
./setup.sh
```

### Mira can't write/read files

The settings.local.json might be missing permissions.

**Fix:** Check `~/Mira_Assistant/.claude/settings.local.json` and verify the permissions array includes what Mira needs.

### Want to start over completely

```bash
./uninstall.sh --yes
./setup.sh
```

---

## 12. Architecture Reference

### File Layout After Installation

```
~/Mira_Assistant/                    # Your workspace (name may vary)
├── .claude/
│   ├── CLAUDE.md                    # Mira's personality and instructions
│   └── settings.local.json          # Tool permissions
├── .remember/                       # Persistent memory (managed by plugin)
├── projects/
│   ├── tasks.md                     # Task board (daily schedule, backlog)
│   └── tracker.md                   # Master project tracker
├── templates/
│   ├── email-followup.md            # Email template
│   ├── meeting-notes.md             # Meeting notes template
│   └── status-update.md             # Status update template
├── tools/
│   └── transcribe.sh               # Voice transcription helper script
└── start.sh                         # Terminal launcher script

~/Applications/Mira.app              # macOS launcher (double-click to start)

~/.claude/
├── plugins/                         # Claude Code plugins
│   ├── discord/
│   ├── remember/
│   ├── gws/
│   └── ...
├── skills/
│   └── gstack/                      # gstack skill library
└── channels/
    └── discord/
        └── .env                     # Discord bot token (chmod 600)

~/.local/share/whisper-cpp/models/
└── ggml-base.en.bin                 # Whisper speech-to-text model (~150MB)
```

### How Mira Processes a Voice Message

```
Discord voice message (.ogg)
       │
       ▼
  Download attachment
       │
       ▼
  ffmpeg: convert .ogg → .wav (16kHz, mono, PCM)
       │
       ▼
  whisper-cli: transcribe .wav → text
       │
       ▼
  Show transcription to user
       │
       ▼
  Generate response (text)
       │
       ├──── Text reply → Discord message
       │
       └──── Voice reply (if enabled):
                │
                ▼
             say/VibeVoice: text → .aiff/.wav
                │
                ▼
             ffmpeg: convert → .ogg (opus)
                │
                ▼
             Send as Discord attachment
```

### How Meeting Scheduling Works

```
User request ("schedule with Sarah")
       │
       ▼
  Parse: attendee, email, time, duration
       │
       ▼
  Missing info? ──yes──▶ Ask user (single follow-up)
       │ no
       ▼
  Time specified? ──no──▶ gcal_find_meeting_times
       │ yes                      │
       ▼                          ▼
  gcal_find_my_free_time    Suggest 2-3 slots
       │                          │
       ▼                          ▼
  Conflict? ──yes──▶ Suggest nearest open slot
       │ no
       ▼
  Show confirmation summary
       │
       ▼
  User approves? ──no──▶ Adjust and re-confirm
       │ yes
       ▼
  gcal_create_event (attendees get email invites)
```

---

## Quick Reference Card

| Action | Command / Phrase |
|---|---|
| Start Mira | Double-click ~/Applications/Mira.app |
| Start from Terminal | `cd ~/Mira_Assistant && ./start.sh` |
| Add tasks | "I need to do X, Y, and Z" |
| Check schedule | "What's on my calendar today?" |
| Schedule meeting | "Schedule a call with Name at email@example.com" |
| Send voice message | Record in Discord DM with Mira bot |
| Draft email | "Draft a follow-up to Name about Topic" |
| Check projects | "How are my projects looking?" |
| Mark task done | "Done with X, took about 30 minutes" |
| Re-run setup | `cd mira-assistant-setup && ./setup.sh` |
| Uninstall | `cd mira-assistant-setup && ./uninstall.sh` |
