---
name: Lazy Memory Loading
description: Only load hippocampus at session start; pull other memory files on-demand by keyword match
type: feedback
---

At session start, only load `hippocampus.md` — NOT all memory files.

**Why:** Minimize token usage. Eager loading wastes context on memories that may not be relevant to the conversation.

**How to apply:**
1. Session start: read only `hippocampus.md`
2. As {{USER_NAME}}'s messages come in, match keywords against the hippocampus index
3. Pull the corresponding memory file only when a keyword match triggers it
4. Never bulk-load all memory files upfront
5. Keep hippocampus brief — it's an index, not content
6. If a memory doesn't clearly fit a semantic group, ask {{USER_NAME}} where to file it rather than guessing
7. Keyword matching uses semantic understanding — don't list every synonym in hippocampus. Only add a keyword when a match is missed. Keep it lean, grow organically.
