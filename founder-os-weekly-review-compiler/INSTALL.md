# Installation Guide: Weekly Review Compiler

> Generate a structured weekly review Notion page from auto-discovered task databases, Google Calendar events, and Gmail threads

## Prerequisites

- [ ] Claude Code installed
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH

### MCP Servers Required

- [ ] **Notion** -- Auto-discover task databases and store review pages (Required)
- [ ] **Google Calendar** -- Meeting data and time allocation (Required)
- [ ] **Gmail** -- Email thread activity (Optional)

## Installation

1. **Copy the plugin folder** into your plugins directory:

   ```bash
   cp -r founder-os-weekly-review-compiler ~/path-to-plugins/
   ```

2. **Configure MCP servers** (see next section).

3. **Verify installation** by running `/weekly:review --output=chat`.

## MCP Server Setup

### Notion (Required)

Notion is the primary data source and output destination. Without it, the plugin cannot function.

#### Setup Steps

1. Go to https://www.notion.so/my-integrations
2. Create a new integration (name: "Founder OS")
3. Copy the API key
4. Share your target Notion workspace pages with the integration

#### Configure Environment

```bash
export NOTION_API_KEY="ntn_your-key-here"
```

The `.mcp.json` is pre-configured:

```json
{
  "notion": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-notion"],
    "env": {
      "NOTION_API_KEY": "${NOTION_API_KEY}"
    }
  }
}
```

#### Notion Database

The plugin writes to the consolidated "[FOS] Briefings" database (with Type = "Weekly Review"). If that database does not exist, it tries "Founder OS HQ - Briefings", then falls back to the legacy "Weekly Review Compiler - Reviews" database. It does not create a new database -- ensure at least one of these databases exists in your workspace. Task databases are auto-discovered -- no configuration required.

### Google Calendar (Required)

Google Calendar provides meeting data, time allocation analysis, and next-week calendar preview.

#### Setup Steps

1. Create OAuth credentials at https://console.cloud.google.com
2. Enable the Google Calendar API
3. Download credentials JSON

#### Configure Environment

```bash
export GOOGLE_CREDENTIALS_PATH="/path/to/credentials.json"
export GOOGLE_TOKEN_PATH="/path/to/token.json"
```

The `.mcp.json` is pre-configured:

```bash
# Verify gws CLI access:
gws calendar +agenda --today --format json
```

### Gmail (Optional)

Gmail provides email thread activity for the communication summary section. The plugin works fully without Gmail -- the communication section shows a placeholder.

#### Setup Steps

1. Use the same Google Cloud project as Calendar (or create separate credentials)
2. Enable the Gmail API
3. Download credentials JSON

#### Configure Environment

```bash
# No credential files needed — gws CLI manages authentication
# Run `gws auth login` to authenticate
```

The `.mcp.json` is pre-configured:

```bash
# Verify gws CLI access:
gws gmail +triage --max 1 --format json
```

## Verification

Run:

```
/weekly:review --output=chat
```

Expected result: A structured weekly review displayed in chat covering the most recently completed week. Notion task databases are auto-discovered and reported.

If you encounter errors:

| Error | Solution |
|-------|----------|
| "Notion MCP is required for weekly review" | Check NOTION_API_KEY is set and valid |
| "Calendar unavailable" | This is a warning. Check GOOGLE_CREDENTIALS_PATH and GOOGLE_TOKEN_PATH |
| "No task databases found" | Ensure Notion databases have Status and Date properties. Review continues with Calendar/Gmail data. |
| "Gmail data unavailable" | This is normal. Gmail is optional. |

## Troubleshooting

### No Task Databases Discovered

The auto-discovery algorithm looks for databases with a Status property (containing "Done", "Complete", etc.) and a Date property. If your databases use non-standard names:
- Rename the status property to "Status"
- Add a date property named "Due Date" or "Completed Date"

### Wrong Week Reviewed

By default, the plugin reviews the most recently completed week (previous Monday-Sunday). Use `--date=YYYY-MM-DD` to specify any date within the target week.

### Duplicate Reviews

The plugin automatically detects and updates existing reviews for the same week. Running the command twice for the same week updates the existing Notion page rather than creating a duplicate.
