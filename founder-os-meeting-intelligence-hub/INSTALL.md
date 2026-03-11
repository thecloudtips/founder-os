# Installation Guide: founder-os-meeting-intelligence-hub

> Multi-source transcript aggregator with intelligence extraction

## Prerequisites

- [ ] Claude Code
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH

### MCP Servers Required

- [ ] **Notion** (required) -- Meeting notes source + intelligence output database
- [ ] **Filesystem** (required) -- Read local transcript files (.txt, .json, .srt, .vtt, .md)
- [ ] **Google Drive** (optional) -- Access Gemini-generated meeting transcripts
- [ ] **Gmail** (optional) -- Email context enrichment for meetings

_Refer to the [MCP Server Setup](#mcp-server-setup) section below for configuration details._

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:

   ```bash
   cp -r founder-os-meeting-intelligence-hub ~/path-to-plugins/
   ```

2. **Configure MCP servers** (see next section).

3. **Verify installation** by running `/meeting:intel --help`.

## MCP Server Setup

Edit the `.mcp.json` file in the plugin root to configure MCP servers.

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
4. Share your target databases/pages with the integration

### Filesystem (Required)

Already configured in `.mcp.json`. No additional setup needed.

```json
{
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem"]
  }
}
```

### Google Drive (Optional)

Install and authenticate gws CLI to enable Drive access:

```bash
# Verify gws CLI access:
gws drive files list --params '{"q":"trashed=false","pageSize":1}' --format json
```

**Setup steps:**
1. Create a Google Cloud project
2. Enable the Google Drive API
3. Download OAuth credentials JSON
4. Set the paths in your `.mcp.json`

### Gmail (Optional)

Remove the underscore prefix from `_gmail` in `.mcp.json` to enable:

```bash
# Verify gws CLI access:
gws gmail +triage --max 1 --format json
```

**Setup steps:**
1. Create a Google Cloud project (or reuse Drive project)
2. Enable the Gmail API
3. Download OAuth credentials JSON
4. Set the paths in your `.mcp.json`

## Configuration

After enabling MCP servers:

1. Open `.mcp.json` and enable required servers (remove underscore prefix for optional ones)
2. Replace all placeholder values with your actual credentials and paths
3. Notion and Filesystem are already enabled by default
4. Google Drive and Gmail are optional -- the plugin works without them

## Notion Database

The plugin writes to the shared **"[FOS] Meetings"** database. If that database does not exist, it tries **"Founder OS HQ - Meetings"**, then falls back to the legacy **"Meeting Intelligence Hub - Analyses"** database. If none exists, the plugin outputs to chat only (no database is lazy-created).

The "[FOS] Meetings" database is shared with P03 Meeting Prep Autopilot. Both plugins use the Event ID as a shared idempotent key -- when one plugin creates a record, the other updates it rather than creating a duplicate.

**P07-owned fields**: Source Type, Transcript File, Summary, Decisions, Follow-Ups, Topics, Duration, Company (relation)

To set up the shared database, see the Founder OS HQ setup guide.

## Verification

Run the following command to verify your installation:

```
/meeting:analyze test-notes.txt
```

Expected result: The plugin should analyze the file and display extracted intelligence (summary, decisions, follow-ups, topics).

If you encounter errors:
1. Check that Notion and Filesystem MCP servers are running
2. Verify your Notion API key is correct
3. Ensure the plugin folder is in the correct location
4. Check Node.js and npx versions
