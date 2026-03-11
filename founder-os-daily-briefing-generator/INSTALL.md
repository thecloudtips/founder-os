# Installation Guide: Daily Briefing Generator

> Parallel-gathering plugin that pulls today's calendar events, priority emails, due tasks, and optional Slack mentions -- assembling a structured daily briefing in Notion.

## Prerequisites

- [ ] Claude Code installed
- [ ] Node.js 18+ and npx available on your system
- [ ] gws CLI installed and authenticated (`which gws` should return a path)
- [ ] Google account with Calendar and Gmail access
- [ ] Notion workspace for task tracking and briefing output

### Services Required

| Service | Required | Method |
|---------|----------|--------|
| Google Calendar | Yes | gws CLI (`gws calendar`) |
| Gmail | Yes | gws CLI (`gws gmail`) |
| Notion | Yes | MCP server (`@modelcontextprotocol/server-notion`) |
| Slack | Optional | MCP server (`@anthropic/mcp-server-slack`) |

## Step 1: gws CLI Setup (Google Calendar & Gmail)

The gws CLI provides access to Google Calendar and Gmail. It replaces the previous MCP server approach.

1. Install the gws CLI if not already installed. Verify with:
   ```bash
   which gws
   ```
2. Authenticate the gws CLI with your Google account:
   ```bash
   gws auth login
   ```
3. Verify Calendar access:
   ```bash
   gws calendar +agenda --today --format json
   ```
4. Verify Gmail access:
   ```bash
   gws gmail +triage --max 5 --format json
   ```

Both Calendar and Gmail share the same gws authentication. No separate token files are needed.

## Step 2: Notion Setup

1. Go to [notion.so/my-integrations](https://www.notion.so/my-integrations)
2. Click **New integration**
3. Name it "Founder OS" or "Daily Briefing Generator"
4. Select the workspace where briefings will be stored
5. Copy the API key (starts with `ntn_` or `secret_`)
6. Set the environment variable:
   ```bash
   export NOTION_API_KEY="your-notion-api-key"
   ```
7. Share any existing task databases with the integration:
   - Open the database page
   - Click the "..." menu > **Connections** > Add your integration

The plugin writes to the consolidated "[FOS] Briefings" database. If that database does not exist, it tries "Founder OS HQ - Briefings", then falls back to the legacy "Daily Briefing Generator - Briefings" database. It does not create a new database -- ensure at least one of these databases exists in your Notion workspace.

## Step 3: Slack Setup (Optional)

Slack adds team channel highlights and direct mentions to your daily briefing.

1. Go to [api.slack.com/apps](https://api.slack.com/apps) and click **Create New App**
2. Choose **From scratch**, name it "Daily Briefing", and select your workspace
3. Navigate to **OAuth & Permissions** and add these **Bot Token Scopes**:
   - `channels:history` -- read messages in public channels
   - `channels:read` -- list and view public channels
   - `chat:write` -- post messages (for optional briefing delivery)
   - `search:read` -- search messages and files
4. Click **Install to Workspace** and authorize
5. Copy the **Bot User OAuth Token** (starts with `xoxb-`)
6. Set the environment variable:
   ```bash
   export SLACK_BOT_TOKEN="xoxb-your-slack-bot-token"
   ```
7. Invite the bot to channels you want included in briefings:
   - In each Slack channel, type `/invite @Daily Briefing`

If Slack is not configured, the plugin gracefully skips Slack data and assembles the briefing from Calendar, Gmail, and Notion sources only.

## Step 4: Plugin Installation

1. Copy the plugin folder into your Claude Code plugins directory:
   ```bash
   cp -r founder-os-daily-briefing-generator ~/path-to-claude-code-plugins/
   ```

2. The `.mcp.json` in the plugin root is pre-configured for Notion and Slack MCP servers. Verify gws CLI and required environment variables are set:
   ```bash
   which gws
   echo $NOTION_API_KEY
   ```

3. Restart Claude Code to load the plugin.

## Configuration Notes

- **Environment variables** can be set in your shell profile (`~/.zshrc`, `~/.bashrc`) or in a `.env` file if your Claude Code setup supports it.
- **Notion databases**: The plugin uses the consolidated "[FOS] Briefings" database (falls back to "Founder OS HQ - Briefings", then "Daily Briefing Generator - Briefings"). The database must already exist in your workspace.
- **Slack is purely additive.** The briefing is fully functional without it. Add Slack later at any time by setting the `SLACK_BOT_TOKEN` variable and restarting.
- **gws CLI authentication** is persisted after initial login. You only need to run `gws auth login` once.

## Verification

Run the following command to verify the plugin is working:

```
/daily:briefing
```

Expected: The plugin gathers today's calendar events, priority emails, and due tasks, then presents a structured daily briefing. If Notion is connected, the briefing is also saved to the "[FOS] Briefings" database (or fallback "Founder OS HQ - Briefings" / legacy "Daily Briefing Generator - Briefings" database).

### Verification Checklist

- [ ] gws CLI is installed (`which gws` returns a path)
- [ ] gws CLI can access Calendar (`gws calendar +agenda --today --format json` returns events)
- [ ] gws CLI can access Gmail (`gws gmail +triage --max 5 --format json` returns emails)
- [ ] Notion MCP connects (can search or create databases)
- [ ] `/daily:briefing` returns a structured briefing (not an error)
- [ ] Slack MCP connects (optional -- mentions and highlights appear in briefing)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "gws CLI unavailable" | Install the gws CLI and run `gws auth login` to authenticate |
| Calendar data not returning | Run `gws calendar +agenda --today --format json` to verify access; re-authenticate with `gws auth login` if needed |
| Authentication expired | Run `gws auth login` to re-authenticate with Google |
| "Notion MCP not available" | Verify `NOTION_API_KEY` is set and the integration has workspace access |
| Notion database not found | Share the target database with your Notion integration via the Connections menu |
| Gmail returns no results | Run `gws gmail +triage --max 5 --format json` to verify access; try `--hours=48` to widen the lookback window |
| Slack data missing from briefing | Confirm `SLACK_BOT_TOKEN` is set, the bot is installed to the workspace, and invited to relevant channels |
| "Unknown command" error | Re-copy the plugin folder, ensure the `commands/` directory is present, and restart Claude Code |
| Partial briefing (some sections empty) | Slack MCP is optional and may not be configured -- this is expected. For Gmail/Calendar, verify gws CLI is installed and authenticated. For Notion, check the NOTION_API_KEY env var |
