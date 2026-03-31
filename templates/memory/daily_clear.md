---
name: Daily Context Clear
description: 4 AM cron job clears context; assistant recreates state each session from memory + task board
type: reference
---

A cron job at 4 AM clears the Claude Code conversation context daily.

**Why:** Prevents stale context from accumulating. Each session starts fresh with only what's needed.

**How to apply:** Don't rely on conversation history persisting across days. At session start:
1. Load hippocampus.md (keyword index)
2. Check task board (projects/tasks.md)
3. Check calendar for today
4. Surface top priorities

All persistent knowledge lives in memory files and the task board, not conversation context.
