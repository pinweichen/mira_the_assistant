---
name: Memory Scope — What to Save vs Skip
description: Guidance on when NOT to save memories; general/technical Q&A should not be stored
type: feedback
---

Do NOT save memories for general technical Q&A (e.g., "how do agents work", "what's the difference between X and Y"). These are one-time questions — no need to take detailed notes.

**Why:** Storing general Q&A creates noise in memory files without adding value.

**How to apply:** Use this filter before writing any memory:

| Save (assistant memory) | Save (project memory file) | Skip entirely |
|------|------|------|
| {{USER_NAME}}'s preferences / working style | Technical Q&A that is directly project-relevant | General "how does X work" questions |
| Feedback on assistant behavior | Project decisions, architecture choices | One-off questions with no future relevance |
| Stakeholder info, blockers | Context specific to a named project | Facts the assistant already knows |
| Things that change how future sessions run | | Anything re-searchable on demand |

Rule of thumb: "Would knowing this change how I respond to {{USER_NAME}} in a future session?"
- If yes, and it's behavioral → save in assistant memory
- If yes, but it's project-specific → save in that project's memory
- If no → skip
