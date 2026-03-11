# Installation Guide: founder-os-multi-tool-morning-sync

> Consolidate overnight updates from 5 sources into a prioritized morning briefing

## Prerequisites

- [ ] Claude Code installed
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH

### MCP Servers Required

- [ ] **Gmail** -- Scan overnight emails (required)
- [ ] **Google Calendar** -- Today's events (required)
- [ ] **Notion** -- Task tracking and briefing storage (required)

### MCP Servers Optional

- [ ] **Slack** -- Channel highlights and @mentions
- [ ] **Google Drive** -- Document updates

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:

   ```bash
   cp -r founder-os-multi-tool-morning-sync ~/path-to-plugins/
   ```

2. **Configure MCP servers** (see next section).

3. **Verify installation** (see [Verification](#verification) section).

## MCP Server Setup

The `.mcp.json` file in the plugin root is pre-configured. Update the environment variables below.

### Gmail (Required)

```bash
# Verify gws CLI access:
gws gmail +triage --max 1 --format json
```

**Setup steps:**
1. Install gws CLI and run `gws auth login` to authenticate
2. Download OAuth 2.0 credentials as `credentials.json`
3. Run the gws CLI (`gws gmail`) once to complete OAuth flow and generate `token.json`
4. Update paths in `.mcp.json`

### Google Calendar (Required)

```bash
# Verify gws CLI access:
gws calendar +agenda --today --format json
```

**Setup steps:**
1. Enable the Google Calendar API in the same Google Cloud project
2. Reuse the same OAuth credentials (Gmail and Calendar share the same project)
3. The token may need re-authorization to include calendar scopes

### Notion (Required)

```json
{
  "notion": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-notion"],
    "env": {
      "NOTION_API_KEY": "your-notion-api-key"
    }
  }
}
```

**Setup steps:**
1. Go to https://www.notion.so/my-integrations
2. Create a new integration
3. Copy the API key
4. Replace `your-notion-api-key` in `.mcp.json`
5. Share your target workspace pages with the integration

### Slack (Optional)

```json
{
  "slack": {
    "command": "npx",
    "args": ["-y", "@anthropic/mcp-server-slack"],
    "disabled": true,
    "env": {
      "SLACK_BOT_TOKEN": "xoxb-your-slack-bot-token"
    }
  }
}
```

**Setup steps:**
1. Create a Slack app at https://api.slack.com/apps
2. Add bot token scopes: `channels:history`, `channels:read`, `users:read`
3. Install the app to your workspace
4. Copy the Bot User OAuth Token
5. Set `"disabled": false` in `.mcp.json` to enable

### Google Drive (Optional)

```bash
# Verify gws CLI access:
gws drive files list --params '{"q":"trashed=false","pageSize":1}' --format json
```

**Setup steps:**
1. Enable the Google Drive API in the same Google Cloud project
2. Reuse the same OAuth credentials
3. Set `"disabled": false` in `.mcp.json` to enable

## Verification

Run the following command to verify your installation:

```
/morning:quick
```

Expected result: A chat summary showing today's priorities, schedule, and source counts. If any required source is unavailable, you'll see a specific error message with the missing MCP server package name.

For full verification:

```
/morning:sync --output=chat
```

Expected result: A comprehensive morning briefing in chat (without Notion write), showing all gathered data across available sources.

If you encounter errors:
1. Check that all required MCP servers are running
2. Verify API keys and credentials are correct
3. Ensure the plugin folder is in the correct location
4. Check Node.js and npx versions

## Minimal Mode (No Optional Sources)

The plugin works with just the 3 required sources (Gmail, Calendar, Notion). Slack and Drive sections are automatically omitted when those servers are not configured.
