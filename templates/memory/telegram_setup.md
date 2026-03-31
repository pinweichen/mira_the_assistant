---
name: Telegram Channel Setup
description: Telegram bot credentials location, access config, and plugin details for the Claude Code Telegram channel
type: reference
---

Telegram is an alternative messaging channel for reaching {{ASSISTANT_NAME}} (secondary to Discord).

- **Bot token:** stored in `~/.claude/channels/telegram/.env` (`TELEGRAM_BOT_TOKEN=...`)
- **Access config:** `~/.claude/channels/telegram/access.json`
- **Plugin:** `telegram@claude-plugins-official`

To re-enable if missing: run `/plugin install telegram@claude-plugins-official` in Claude Code, then `/reload-plugins`.
Then run `/telegram:configure` to set the bot token.
