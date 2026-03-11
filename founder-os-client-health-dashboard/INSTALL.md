# Installation Guide: founder-os-client-health-dashboard

> Scans Notion CRM clients, computes 5 health metrics, and outputs a color-coded RAG dashboard with risk flags and recommended actions.

## Prerequisites

- [ ] Claude Code (platform: **Claude Code**)
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH

### MCP Servers Required

- [ ] **Notion** (required) -- CRM client data, health score cache, output database
- [ ] **Gmail** (required) -- Email thread analysis for contact, response time, and sentiment metrics
- [ ] **Google Calendar** (optional) -- Meeting pattern analysis for sentiment scoring

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:

   ```bash
   cp -r founder-os-client-health-dashboard ~/path-to-plugins/
   ```

2. **Configure MCP servers** (see next section).

3. **Verify installation** by running `/client:health-scan`.

## MCP Server Setup

The plugin's `.mcp.json` is pre-configured. Set the following environment variables for each server.

### Notion (Required)

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
5. Share your CRM workspace (Companies database) with the integration
6. **Recommended**: Use the **Founder OS HQ** template, which includes a consolidated "Founder OS HQ - Companies" database with built-in health score properties. The plugin writes health scores directly onto Company pages -- no separate database needed.
7. **Standalone mode** (fallback): If no HQ or Companies database is found, the plugin creates a standalone "Client Health Dashboard - Health Scores" database automatically on first use (lazy creation). No manual database setup required.

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

## Cross-Plugin Integration (Optional)

### Plugin #20 Client Context Loader
If installed, the health dashboard reads cached client dossiers from the "Client Dossiers" database. No additional configuration needed — just ensure both plugins share the same Notion workspace.

### Plugin #11 Invoice Processor
If installed, the health dashboard reads invoice payment data from the "Invoice Processor - Invoices" database. No additional configuration needed.

## Verification

Run the following command to verify your installation:

```
/client:health-scan --limit=3
```

Expected result: A health dashboard showing scores for up to 3 clients, or a message if no active clients are found in CRM.

If you encounter errors:
1. Check that Notion MCP is running (`/mcp` to see server status)
2. Verify your CRM Companies database is shared with the Notion integration
3. Check Gmail credentials paths are correct and OAuth flow was completed
4. For Calendar errors, the plugin will gracefully degrade and use Gmail-only sentiment
