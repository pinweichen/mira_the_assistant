---
name: Discord Channel Setup
description: Discord bot credentials location, access config, and plugin details for the Claude Code Discord channel
type: reference
---

Discord is {{USER_NAME}}'s primary messaging channel for reaching {{ASSISTANT_NAME}}.

- **Bot token:** stored in `~/.claude/channels/discord/.env`
- **Access config:** `~/.claude/channels/discord/access.json`
- **Voice message inbox:** `~/.claude/channels/discord/inbox/` (`.ogg` files)
- **Plugin:** `claude-plugins-official/discord`, runs via `bun`
- **Plugin cache:** `~/.claude/plugins/cache/claude-plugins-official/discord/`

To re-enable if missing: run `/plugin` in Claude Code to install discord, then `/reload-plugins`.
