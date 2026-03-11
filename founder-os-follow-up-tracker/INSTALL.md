# Installation Guide: founder-os-follow-up-tracker

> Scans Gmail sent folder for emails awaiting response, detects promises, drafts nudge emails, and creates calendar reminders.

## Prerequisites

- [ ] Claude Code (platform: **Claude Code**)
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH

### MCP Servers Required

- [ ] **Gmail** (required) -- Email scanning, thread reading, draft creation
- [ ] **Notion** (optional) -- Persistent follow-up tracking database
- [ ] **Google Calendar** (optional) -- Reminder event creation

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:

   ```bash
   cp -r founder-os-follow-up-tracker ~/path-to-plugins/
   ```

2. **Configure MCP servers** (see next section).

3. **Verify installation** by running `/followup:check`.

## MCP Server Setup

The plugin's `.mcp.json` is pre-configured. Set the following environment variables for each server.

### Gmail (Required)

```bash
# Verify gws CLI access:
gws gmail +triage --max 1 --format json
```

**Setup steps:**
1. Create a Google Cloud project at https://console.cloud.google.com
2. Enable the Gmail API
3. Create OAuth 2.0 credentials (Desktop application)
4. Download the credentials JSON file
5. Set environment variables:
   ```bash
   # No credential files needed — gws CLI manages authentication
   # Run `gws auth login` to authenticate
   ```
6. On first use, complete the OAuth flow in your browser

### Notion (Optional)

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

**Setup steps:**
1. Go to https://www.notion.so/my-integrations
2. Create a new integration with "Read content" and "Insert content" capabilities
3. Copy the Internal Integration Token
4. Set environment variable:
   ```bash
   export NOTION_API_KEY="ntn_your_integration_token"
   ```
5. The plugin writes to the shared **"[FOS] Tasks"** database with `Type = "Follow-Up"`. Ensure the HQ database is provisioned (see `_infrastructure/notion-db-templates/`). If the HQ database is not found, the plugin tries "Founder OS HQ - Tasks", then falls back to the legacy "Follow-Up Tracker - Follow-Ups" database. The plugin does **not** create databases automatically.

### Google Calendar (Optional)

```bash
# Verify gws CLI access:
gws calendar +agenda --today --format json
```

**Setup steps:**
1. Use the same Google Cloud project from Gmail setup
2. Enable the Google Calendar API
3. The same OAuth credentials can be reused
4. Set environment variables:
   ```bash
   export GOOGLE_CREDENTIALS_PATH="/path/to/credentials.json"
   export GOOGLE_TOKEN_PATH="/path/to/calendar-token.json"
   ```

## Verification

Run the following command to verify your installation:

```
/followup:check --days=3
```

Expected result: A table of emails awaiting response from the last 3 days, or a message confirming no pending follow-ups.

If you encounter errors:
1. Check that gws CLI (Gmail) is running (`/mcp` to see server status)
2. Verify credentials paths are correct and files exist
3. Ensure OAuth flow was completed for Gmail
4. For Notion/Calendar errors, the plugin will gracefully degrade and show results in chat
