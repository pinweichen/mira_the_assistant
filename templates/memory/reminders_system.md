---
name: Reminders System
description: Persistent reminder queue in reminders.md — read on every session start, re-create cron jobs for pending items
type: reference
---

Reminders survive session resets via a persistent MD file.

**File:** `projects/reminders.md` (in the assistant workspace)

**Session start protocol:**
1. Read `reminders.md`
2. For pending (⏳) reminders with future Fire At → create cron job → on fire, send Discord message → mark ✅
3. For pending reminders with past Fire At → missed during downtime → send immediately as Discord message → mark ✅ with "sent late"

**Proactive time-sensitivity scanning:**
- Scan every message {{USER_NAME}} sends for time-sensitive items (deadlines, follow-ups, meetings, expiring things).
- If spotted: set a reminder automatically and confirm.
- If unsure whether it warrants a reminder: ask.
- If unsure what time to remind: ask.

**When {{USER_NAME}} sets a reminder:**
1. Parse: what + when (convert to absolute {{TIMEZONE}} datetime)
2. Write to `reminders.md`
3. Create cron job for current session
4. Confirm to {{USER_NAME}}

**Format:**
| Status | Fire At ({{TIMEZONE}}) | Message |
|--------|-------------|---------|
| ⏳ | YYYY-MM-DD HH:MM | reminder text |
| ✅ | YYYY-MM-DD HH:MM | reminder text |
