# Installation Guide: founder-os-action-item-extractor

> Extracts structured action items from meeting transcripts, email threads, or documents and auto-creates Notion tasks.

## Prerequisites

- [ ] Claude Code installed
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH

### MCP Servers Required

- [ ] **Notion** (required) -- Task storage, database creation, duplicate detection

### Optional CLI Tools

- [ ] **gws CLI** (optional) -- Read source documents from Google Drive. Install and authenticate with `gws auth login`.

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:

   ```bash
   cp -r founder-os-action-item-extractor ~/path-to-plugins/
   ```

2. **Configure MCP servers** (see next section).

3. **Verify installation** (see [Verification](#verification) section).

## MCP Server Setup

Edit the `.mcp.json` file in the plugin root to configure the required MCP servers. For Google Drive access, install the gws CLI tool and authenticate with `gws auth login`.

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
4. Share your target workspace with the integration
5. Replace `your-notion-api-key` in `.mcp.json` with your actual key

This plugin writes to the consolidated "[FOS] Tasks" database (with `Type = "Action Item"`). Provision the HQ database using the template at `_infrastructure/notion-db-templates/hq-tasks.json` before first use. If the HQ database is not found, the plugin tries "Founder OS HQ - Tasks", then falls back to the legacy "Action Item Extractor - Tasks" database. If none exists, results are displayed in chat only.

### Google Drive via gws CLI (Optional)

To read source documents directly from Google Drive, install the gws CLI tool and authenticate:

```bash
# Check if gws is installed
which gws || echo "gws CLI not available"

# Authenticate with Google
gws auth login
```

**Setup steps:**
1. Install the gws CLI tool
2. Run `gws auth login` to authenticate with your Google account
3. Verify access with `gws drive files list --params '{"q":"name contains '\''test'\''","pageSize":5}' --format json`

## Verification

Run the following command to verify your installation:

```
/actions:extract Test action item: Review the project plan by Friday.
```

Expected result: The plugin should extract one action item ("Review the project plan") with a deadline of the coming Friday and create it in your Notion workspace.

If you encounter errors:
1. Check that Notion MCP server is running and API key is correct
2. Verify the Notion integration has access to your workspace
3. Ensure Node.js and npx versions are up to date
4. Check the plugin folder is in the correct location
