---
name: Voice Message Preference
description: Reply to Discord voice messages with voice; fall back to text for code/tables/links/structured content
type: feedback
---

Voice replies on Discord, using the configured voice.

**Voice:** {{VOICE_NAME}} ({{VOICE_ENGINE}})

**Rule:** When {{USER_NAME}} sends a voice message, reply with a voice message. If the response contains content that doesn't work as audio (code, tables, links, lists, structured data), send a short voice note saying "This one's better in text" then send the text reply instead.

**Why:** {{USER_NAME}} prefers voice-in, voice-out for conversational Discord messages. Keeps the flow natural.

**How to apply:**
1. Transcribe incoming voice with whisper-cpp
2. If reply is conversational, generate voice reply using: {{TTS_CMD}}
   Then attach the .ogg file to the Discord reply.
3. If reply is longer than 4 sentences, send voice message AND a text summary underneath.
4. If reply requires structured content (code, tables, links, lists), send voice note explaining it can't be a voice message, then send text.
