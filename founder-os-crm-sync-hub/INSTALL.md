# Installation Guide: founder-os-crm-sync-hub

> Sync email and calendar activities to Notion CRM Pro with intelligent client matching, AI-generated summaries, and deduplication.

## Prerequisites

- [ ] Claude Code installed
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH
- [ ] Notion workspace with CRM Pro template (Companies, Contacts, Deals databases)

### MCP Servers Required

- [ ] **Notion** (required) — Read and write CRM databases (Companies, Contacts, Communications)
- [ ] **Gmail** (required) — Retrieve email threads for syncing
- [ ] **Google Calendar** (required) — Retrieve calendar events for syncing

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:

   ```bash
   cp -r founder-os-crm-sync-hub ~/.claude/plugins/
   ```

2. **Configure MCP servers** (see next section).

3. **Verify installation** by running `/crm:sync-email --dry-run` in Claude Code.

## MCP Server Setup

### Notion (Required)

The Notion MCP server connects to your CRM Pro databases for reading client data and writing synced activities.

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
2. Create a new integration named "CRM Sync Hub"
3. Copy the Internal Integration Secret
4. In `.mcp.json`, replace `${NOTION_API_KEY}` with the copied key
5. Share your CRM workspace pages with the integration (Companies, Contacts, Communications, and Deals databases)

**Notion databases:** This plugin uses shared Founder OS HQ databases. It searches for "[FOS] Communications", "[FOS] Companies", "[FOS] Contacts", and "[FOS] Deals" first, then "Founder OS HQ - Communications", "Founder OS HQ - Companies", "Founder OS HQ - Contacts", and "Founder OS HQ - Deals", then falls back to legacy names ("Communications", "CRM - Communications", "Companies", "CRM - Companies", etc.). Use the Founder OS HQ workspace template to provision these databases. Plugin #20 (Client Context Loader) uses the same databases.

### Gmail (Required)

The gws CLI (`gws gmail`) retrieves email threads from your sent folder for syncing to the CRM.

```bash
# Verify gws CLI access:
gws gmail +triage --max 1 --format json
```

**Setup steps:**
1. Go to https://console.cloud.google.com/ and create a project (or use an existing one)
2. Enable the Gmail API for your project
3. Create OAuth 2.0 credentials (Desktop application type)
4. Download the credentials JSON file
5. In `.mcp.json`, replace `${GMAIL_CREDENTIALS_PATH}` with the absolute path to your credentials file
6. Replace `${GMAIL_TOKEN_PATH}` with the path where the OAuth token should be stored (e.g., `~/.gmail-token.json`)
7. On first run, you will be prompted to authorize Gmail access in your browser

### Google Calendar (Required)

The gws CLI (`gws calendar`) retrieves calendar events for syncing meetings to the CRM.

```bash
# Verify gws CLI access:
gws calendar +agenda --today --format json
```

**Setup steps:**
1. In the same Google Cloud project, enable the Google Calendar API
2. Use the same OAuth 2.0 credentials file (or create separate credentials)
3. In `.mcp.json`, replace `${GOOGLE_CREDENTIALS_PATH}` with the absolute path to your credentials file
4. Replace `${GOOGLE_TOKEN_PATH}` with the path where the Calendar OAuth token should be stored (e.g., `~/.gcal-token.json`)
5. On first run, you will be prompted to authorize Calendar access in your browser

**Tip:** If you already have Gmail and Google Calendar configured for other Founder OS plugins (#01 Inbox Zero, #02 Daily Briefing, #03 Meeting Prep), you can reuse the same credentials and token paths.

## Configuration

The `.mcp.json` file in the plugin root is pre-configured with placeholder values. Update all placeholders:

1. Replace `${NOTION_API_KEY}` with your Notion integration key
2. Replace `${GMAIL_CREDENTIALS_PATH}` with the absolute path to your Gmail credentials file
3. Replace `${GMAIL_TOKEN_PATH}` with the path for your Gmail OAuth token
4. Replace `${GOOGLE_CREDENTIALS_PATH}` with the absolute path to your Calendar credentials file
5. Replace `${GOOGLE_TOKEN_PATH}` with the path for your Calendar OAuth token

**Updated `.mcp.json` example:**
```bash
# Verify gws CLI access:
gws gmail +triage --max 1 --format json
gws calendar +agenda --today --format json
```

## Verification

Run the following command to verify installation:

```
/crm:sync-email --dry-run
```

Expected result: The plugin scans your Gmail sent folder for the last 7 days, matches email threads to CRM clients, and displays a preview of what would be synced — without writing anything to Notion.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Gmail unavailable" | Verify gws CLI is available for Gmail in `.mcp.json` and credentials are valid |
| "Google Calendar unavailable" | Verify Google gws CLI is available for Calendar and Calendar API is enabled |
| "Notion unavailable" | Verify Notion API key is valid and integration has workspace access |
| "Communications database not found" | Ensure the Founder OS HQ workspace template or CRM Pro template is installed. The plugin searches for "[FOS] Communications" first, then "Founder OS HQ - Communications", then falls back to "Communications" or "CRM - Communications". |
| "No client found matching..." | Check that your Companies database has the client. Use `/crm:context` to verify |
| OAuth prompt does not appear | Delete the token file and restart Claude Code to trigger re-authorization |
| "npx not found" | Ensure Node.js 18+ is installed and npx is in your PATH (`npx --version`) |
| Duplicate records appearing | Check that deduplication is working — records match on Title + Date + Type |
