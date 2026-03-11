# MCP Server Configurations

Reference configurations for the MCP servers used across the Founder OS plugin ecosystem. Each plugin picks the servers it needs by copying the relevant entries into its own `.mcp.json`.

## Overview

| Tool / Server | Package / CLI | Auth Required | Plugin Count |
|---------------|---------------|---------------|--------------|
| **Notion** (MCP) | `@modelcontextprotocol/server-notion` | Yes (API key) | 21 |
| **Filesystem** (MCP) | `@modelcontextprotocol/server-filesystem` | No | 13 |
| **Slack** (MCP) | `@anthropic/mcp-server-slack` | Yes (Bot token) | 2 |
| **Web Search** (MCP) | `@anthropic/mcp-server-web-search` | Yes (API key) | 1 |
| **gws CLI** (Gmail) | `gws` CLI tool | Yes (OAuth via `gws auth login`) | 9 |
| **gws CLI** (Calendar) | `gws` CLI tool | Yes (OAuth via `gws auth login`) | 8 |
| **gws CLI** (Drive) | `gws` CLI tool | Yes (OAuth via `gws auth login`) | 13 |

## Google Workspace Access: gws CLI

As of March 2026, all Google Workspace access (Gmail, Calendar, Drive) uses the **gws CLI tool** instead of MCP servers. The gws CLI is installed system-wide and authenticated once — no per-plugin credential configuration needed.

### Setup

```bash
# 1. Install gws CLI (if not already installed)
# See gws documentation for installation

# 2. Authenticate (one-time)
gws auth login

# 3. Verify access
gws gmail +triage --max 1 --format json      # Gmail
gws calendar +agenda --today --format json    # Calendar
gws drive files list --params '{"q":"trashed=false","pageSize":1}' --format json  # Drive
```

### Why gws CLI instead of MCP?

- **Single authentication** — one `gws auth login` covers Gmail, Calendar, and Drive
- **No npm packages** — no `@anthropic/mcp-server-gmail` etc. to install per-plugin
- **No credential files** — no `GMAIL_CREDENTIALS_PATH` / `GMAIL_TOKEN_PATH` env vars
- **JSON output** — `--format json` provides machine-readable output parsed with `jq`
- **Helper commands** — `+triage`, `+send`, `+agenda`, `+insert`, `+upload` for common operations

### Shared gws Skills

Reusable gws CLI reference skills are at `_infrastructure/gws-skills/`:

| Skill | Purpose |
|-------|---------|
| `gws-common` | Auth checks, global flags, error handling |
| `gmail-read` | Search, list, get messages/threads |
| `gmail-write` | Send, draft, trash, modify labels |
| `calendar-read` | List events, check availability |
| `calendar-write` | Create/update/delete events |
| `drive-read` | Search, list, get, export files |
| `drive-write` | Upload, create, update files |
| `gws-migration-notes` | MCP-to-gws mapping reference |

## MCP Server Setup (Notion, Filesystem, Slack, Web Search)

### Setup Priority Order

1. **Notion** (P0) — Required by 21 plugins, CRM backbone, output storage
2. **Filesystem** (P1) — Required by 13 plugins, no auth needed
3. **Slack** (P2) — Required by 2 plugins
4. **Web Search** (P2) — Required by 1 plugin

### Environment Variables

#### Notion
| Variable | Description | How to Get |
|----------|-------------|------------|
| `NOTION_API_KEY` | Internal integration token | Create at https://www.notion.so/my-integrations, copy "Internal Integration Secret" |

#### Filesystem
| Variable | Description | How to Get |
|----------|-------------|------------|
| `WORKSPACE_DIR` | Root directory the server can access | Set to your working directory (e.g., `~/founderOS-workspace`) |

## How to Add an MCP Server to a Plugin

Each plugin has a `.mcp.json` file at its root. To add a server:

1. Open the reference config for the server you need (e.g., `notion.json`)
2. Copy the server entry into your plugin's `.mcp.json` under the `mcpServers` key
3. Only include the `command`, `args`, and `env` fields

### Single-server example (Notion only)

```json
{
  "mcpServers": {
    "notion": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-notion"],
      "env": {
        "NOTION_API_KEY": "${NOTION_API_KEY}"
      }
    }
  }
}
```

### Multi-server example

See `combined-example.json` for a full multi-server configuration.

## Validation

| Tool / Server | Validation Test |
|---------------|----------------|
| **Notion** | Search for a known page: the server should return results from your workspace |
| **Filesystem** | List files in WORKSPACE_DIR: the server should return directory contents |
| **gws (Gmail)** | `gws gmail +triage --max 5 --format json` — should return recent emails |
| **gws (Calendar)** | `gws calendar +agenda --today --format json` — should return today's events |
| **gws (Drive)** | `gws drive files list --params '{"q":"trashed=false","pageSize":3}' --format json` — should return files |

## Deprecated

The following MCP server configs have been deprecated in favor of the gws CLI tool. Archived copies are in `deprecated/`:

| File | Replaced By |
|------|-------------|
| `deprecated/gmail.json` | `gws gmail` commands |
| `deprecated/google-calendar.json` | `gws calendar` commands |
| `deprecated/google-drive.json` | `gws drive` commands |

## File Inventory

| File | Purpose |
|------|---------|
| `notion.json` | Notion MCP server reference config |
| `filesystem.json` | Filesystem MCP server reference config |
| `slack.json` | Slack MCP server reference config |
| `web-search.json` | Web Search MCP server reference config |
| `combined-example.json` | Multi-server `.mcp.json` example |
| `deprecated/` | Archived Google MCP configs (replaced by gws CLI) |
| `README.md` | This documentation |
