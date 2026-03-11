# Installation Guide: founder-os-proposal-automator

> Generates professional client proposals with 7 sections and 3 pricing packages

## Prerequisites

- [ ] Claude Code (platform: **Claude Code**)
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH

### MCP Servers Required

- [ ] **Filesystem** (required) -- Read brief files and write generated proposals
- [ ] **Notion** (optional) -- CRM context lookup and proposal tracking
- [ ] **gws CLI** (optional) -- Store proposals in Google Drive

_Refer to the [MCP Server Setup](#mcp-server-setup) section below for configuration details._

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:

   ```bash
   cp -r founder-os-proposal-automator ~/path-to-plugins/
   ```

2. **Configure MCP servers** (see next section).

3. **Verify installation** by running `/proposal:create` in Claude Code.

## MCP Server Setup

The `.mcp.json` file in the plugin root is pre-configured. Update credentials as needed.

### Filesystem (Required)

```json
{
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/workspace"]
  }
}
```

Replace `/path/to/workspace` with your project root directory.

### Notion (Optional)

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
4. Share your CRM Pro databases (Companies, Contacts, Deals) with the integration
5. Share the **"Founder OS HQ - Deliverables"** database with the integration (see `_infrastructure/notion-db-templates/` for the HQ template). The plugin writes proposals to this consolidated database with Type="Proposal". If not found, it falls back to the legacy "Proposal Automator - Proposals" database.

### gws CLI (Optional — for Google Drive storage)

Install the gws CLI tool and authenticate with `gws auth login` to enable storing generated proposals in Google Drive.

```bash
# Verify gws is installed
which gws || echo "gws CLI not available — install from https://github.com/tmc/gws"

# Authenticate with Google
gws auth login
```

Once authenticated, proposals can be uploaded to Drive folders via Bash commands using `gws drive +upload`.

## Verification

Run the following command to verify your installation:

```
/proposal:create
```

Expected result: The plugin should ask for a client name and begin collecting project brief details.

If you encounter errors:
1. Check that the Filesystem MCP server is running
2. Verify Notion API key if using CRM context
3. Verify gws CLI is installed and authenticated if using Google Drive storage
4. Ensure the plugin folder is in the correct location
5. Check Node.js and npx versions
