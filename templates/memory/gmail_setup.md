---
name: Gmail Access via GWS
description: GWS plugin provides Gmail read/send/triage access via CLI commands
type: reference
---

Gmail is accessible via the GWS plugin (not MCP tools).

- **Triage inbox:** `gws gmail +triage`
- **Read message:** `gws gmail users messages get --params '{"userId":"me","id":"<msgId>","format":"full"}'`
- **Send email:** see `gws gmail +send` skill
- **Reply:** see `gws gmail +reply` skill
- **Body is base64-encoded** in the `data` field of `payload.parts[].body` — decode with `base64 -d`
- {{USER_NAME}}'s email: {{WORK_EMAIL}}
