# Installation Guide: Slack Digest Engine

> Scan Slack channels to create structured digests with decisions, action items, key threads, and @mentions

## Prerequisites

- [ ] Claude Code installed
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH

### MCP Servers Required

- [ ] **Slack** -- Read channels, DMs, and search messages (Required)
- [ ] **Notion** -- Store digest history (Optional)

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:

   ```bash
   cp -r founder-os-slack-digest-engine ~/path-to-plugins/
   ```

2. **Configure MCP servers** (see next section).

3. **Verify installation** by running `/slack:digest --all --since=1h`.

## MCP Server Setup

### Slack (Required)

The Slack MCP server is the core dependency. Without it, neither command will function.

#### Step 1: Create a Slack App

1. Go to https://api.slack.com/apps
2. Click "Create New App" > "From scratch"
3. Name it (e.g., "Founder OS Digest") and select your workspace

#### Step 2: Add Bot Scopes

Navigate to **OAuth & Permissions** > **Bot Token Scopes** and add:

| Scope | Purpose |
|-------|---------|
| `channels:history` | Read message history from public channels |
| `channels:read` | List channels and get channel info |
| `chat:write` | Send messages (for future extensions) |
| `search:read` | Search messages across workspace |
| `im:history` | Read DM history (only needed for `--include-dms`) |

#### Step 3: Install App to Workspace

1. Navigate to **Install App** in your Slack App settings
2. Click "Install to Workspace"
3. Authorize the requested permissions
4. Copy the **Bot User OAuth Token** (starts with `xoxb-`)

#### Step 4: Invite Bot to Channels

The bot can only read channels it has been invited to.

```
/invite @your-bot-name
```

Run this in each channel you want to scan. Alternatively, use `--all` which scans all channels the bot has access to.

#### Step 5: Configure Environment

Set the `SLACK_BOT_TOKEN` environment variable:

```bash
export SLACK_BOT_TOKEN="xoxb-your-token-here"
```

Or add it to your shell profile (~/.zshrc, ~/.bashrc):

```bash
echo 'export SLACK_BOT_TOKEN="xoxb-your-token-here"' >> ~/.zshrc
```

The `.mcp.json` in the plugin root is pre-configured to use this variable:

```json
{
  "slack": {
    "command": "npx",
    "args": ["-y", "@anthropic/mcp-server-slack"],
    "env": {
      "SLACK_BOT_TOKEN": "${SLACK_BOT_TOKEN}"
    }
  }
}
```

### Notion (Optional)

Notion stores digest history for review and comparison. The plugin works fully without Notion — digests display in chat instead.

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

The plugin writes to the consolidated "[FOS] Briefings" database (with Type = "Slack Digest"). If that database does not exist, it tries "Founder OS HQ - Briefings", then falls back to the legacy "Slack Digest Engine - Digests" database. It does not create a new database -- ensure at least one of these databases exists in your workspace.

## Verification

Run:

```
/slack:digest --all --since=1h
```

Expected result: A structured digest showing messages from the last hour across all bot-accessible channels.

If you encounter errors:

| Error | Solution |
|-------|----------|
| "Slack MCP server is not connected" | Check SLACK_BOT_TOKEN is set and valid |
| "Unable to scan any channels" | Invite the bot to channels via `/invite @bot-name` |
| "Rate limit hit" | Wait 60 seconds and retry with fewer channels |
| "Notion unavailable" | This is a warning, not an error. Digest still displays in chat. |

## Troubleshooting

### Bot Not Seeing Messages

The most common issue. The bot must be explicitly invited to each channel:
```
/invite @your-bot-name
```

### Token Expired

Slack bot tokens don't expire, but if you regenerate the token in the Slack App settings, update the `SLACK_BOT_TOKEN` environment variable.

### Missing im:history Scope

If `--include-dms` returns no results, verify the `im:history` scope was added and the app was re-installed to the workspace after adding the scope.
