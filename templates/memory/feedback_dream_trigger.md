---
name: Dream Consolidation Trigger Preference
description: Dream should run at every session exit (tied to 4 AM cron), not on a 24-hour timer. Both dream and daily_clear are kept.
type: feedback
---

Run dream memory consolidation on every session exit — not gated by 24-hour timer.

**Why:** The 4 AM cron that clears context naturally controls when major sessions end, so dream fires at the right time without a separate time gate.

**How to apply:**
- `should-dream.sh` always exits 0 — no `.last-dream` timestamp check needed
- Dream and daily context clear are both kept (they're complementary, not redundant)
- If someone asks about reinstalling dream: do NOT add back a 24-hour time gate
