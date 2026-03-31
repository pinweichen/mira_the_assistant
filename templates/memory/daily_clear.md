---
name: Daily Context Clear & Dream Schedule
description: 4 AM daily cron clears context window. Dream memory consolidation runs at session exit (not a 24-hour timer).
type: feedback
---

Clear the context window every day at 4 AM so each day starts fresh.

**Why:** Keeps sessions clean and avoids stale context accumulating overnight.

**How to apply:** At session start, create a recurring cron job: `cron: "3 4 * * *"`, `prompt: "/clear"`, `recurring: true`. Since cron jobs are session-only, this must be recreated each time the assistant starts.

*(Dream trigger preference lives in `feedback_dream_trigger.md`)*
