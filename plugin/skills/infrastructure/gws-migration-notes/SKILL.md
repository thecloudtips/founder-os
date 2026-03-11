---
name: gws-migration-notes
description: MCP-to-gws CLI migration reference for Founder OS plugins. Use this skill when migrating a plugin from Google MCP servers to gws CLI commands, or when debugging migration issues.
---

## Overview

Side-by-side mapping of Google MCP server tool calls to equivalent gws CLI commands. Use this as a reference when refactoring plugin files.

## MCP Tool to gws Command Mapping

### Gmail

| MCP Tool | gws Command |
|----------|-------------|
| `gmail.search_emails` / `gmail.list_messages` | `gws gmail users messages list --params '{"userId":"me","q":"QUERY"}' --format json` |
| `gmail.get_message` / `gmail.read_email` | `gws gmail users messages get --params '{"userId":"me","id":"ID","format":"full"}' --format json` |
| `gmail.send_email` | `gws gmail +send --to EMAIL --subject 'SUBJ' --body 'TEXT'` |
| `gmail.create_draft` | `gws gmail users drafts create --params '{"userId":"me"}' --json '{"message":{"raw":"BASE64"}}'` |
| `gmail.trash_message` | `gws gmail users messages trash --params '{"userId":"me","id":"ID"}'` |
| `gmail.modify_labels` | `gws gmail users messages modify --params '{"userId":"me","id":"ID"}' --json '{"addLabelIds":[...],"removeLabelIds":[...]}'` |
| `gmail.list_labels` | `gws gmail users labels list --params '{"userId":"me"}' --format json` |

### Calendar

| MCP Tool | gws Command |
|----------|-------------|
| `calendar.list_events` | `gws calendar events list --params '{"calendarId":"primary","timeMin":"ISO","timeMax":"ISO","singleEvents":true,"orderBy":"startTime"}' --format json` |
| `calendar.get_event` | `gws calendar events get --params '{"calendarId":"primary","eventId":"ID"}' --format json` |
| `calendar.create_event` | `gws calendar +insert --summary 'TITLE' --start ISO --end ISO` |
| `calendar.update_event` | `gws calendar events patch --params '{"calendarId":"primary","eventId":"ID"}' --json '{...}'` |
| `calendar.delete_event` | `gws calendar events delete --params '{"calendarId":"primary","eventId":"ID"}'` |
| `calendar.check_availability` | `gws calendar freebusy query --json '{"timeMin":"ISO","timeMax":"ISO","items":[{"id":"primary"}]}' --format json` |

### Drive

| MCP Tool | gws Command |
|----------|-------------|
| `drive.search_files` / `drive.list_files` | `gws drive files list --params '{"q":"QUERY","pageSize":N,"fields":"files(id,name,mimeType)"}' --format json` |
| `drive.get_file` | `gws drive files get --params '{"fileId":"ID","fields":"id,name,mimeType,webViewLink"}' --format json` |
| `drive.read_file` / `drive.export` | `gws drive files export --params '{"fileId":"ID","mimeType":"text/plain"}' --output /tmp/file.txt` |
| `drive.upload_file` | `gws drive +upload ./file.pdf --parent FOLDER_ID` |
| `drive.create_file` | `gws drive files create --params '{}' --json '{"name":"NAME","parents":["ID"]}' --upload ./file` |
| `drive.update_file` | `gws drive files update --params '{"fileId":"ID"}' --upload ./file` |

## File-by-File Migration Checklist

### .mcp.json

Remove these entries entirely:
```json
// REMOVE entries with these packages:
"@anthropic/mcp-server-gmail"
"@anthropic/mcp-server-google-calendar"
"@anthropic/mcp-server-google-drive"
```

Preserve: `@modelcontextprotocol/server-notion`, `@modelcontextprotocol/server-filesystem`, Slack, Web Search entries.

If `.mcp.json` becomes empty (`{"mcpServers": {}}`), that's fine — it means the plugin uses only gws CLI and no MCP servers.

### SKILL.md Files

- Replace "Gmail MCP server" / "Calendar MCP" / "Drive MCP" references with "gws CLI"
- Replace "MCP tool calls" with specific `gws` CLI commands
- Replace "Detect whether the Gmail MCP server is available" with "Verify gws CLI is available by running `which gws`"
- Keep output JSON contracts (the structure your skill returns) UNCHANGED
- Update graceful degradation messages: "MCP server not configured" → "gws CLI unavailable or authentication not configured"

### commands/*.md

- Update tool references from MCP tool names to "Bash" tool with gws commands
- Keep command names and user-facing behavior unchanged

### teams/config.json

- Replace `"tools": ["gmail"]` / `"tools": ["google-calendar"]` / `"tools": ["google-drive"]` with `"tools": ["Bash"]`
- Keep non-Google tools unchanged

### teams/agents/*.md

- Replace MCP availability checks with `which gws` check
- Replace MCP tool invocations with specific gws CLI commands
- Update fallback messages
- Keep agent output contracts unchanged

## Common Gotchas

1. **JSON escaping**: gws `--params` and `--json` flags expect properly escaped JSON strings in shell context. Use single quotes for the outer string, escaped single quotes for inner values.

2. **userId is always "me"**: Unlike MCP which might abstract this, gws always requires `"userId":"me"` in Gmail params.

3. **calendarId is "primary"**: Use `"primary"` for the user's default calendar.

4. **Empty .mcp.json**: If removing all Google MCPs leaves no entries, keep the file with `{"mcpServers": {}}` — the plugin may still need it for future MCP additions.

5. **Base64 encoding for email send**: MCP abstracted this away. With gws, use `+send` helper for simple emails or manually base64-encode MIME for complex ones.

6. **Drive file export vs download**: Google Docs/Sheets/Slides need `export` (converts to requested format). Binary files (PDF, DOCX) use `get` with `alt=media`.
