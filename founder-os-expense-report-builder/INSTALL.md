# Installation Guide: founder-os-expense-report-builder

> Generates comprehensive expense reports from processed invoices and local receipt files

## Prerequisites

- [ ] Claude Code (platform: **Claude Code**)
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH

### MCP Servers Required

- [ ] **Filesystem** (required) -- Read receipt/invoice files and write generated reports
- [ ] **Notion** (optional) -- Query P11 Invoice Processor database, track generated reports
- [ ] **gws CLI** (optional) -- Access receipts folder from Google Drive via gws CLI

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:
   ```bash
   cp -r founder-os-expense-report-builder ~/path-to-plugins/
   ```

2. **Configure MCP servers** (see next section).

3. **Verify installation** by running `/expense:summary` to check basic functionality.

## MCP Server Setup

The `.mcp.json` file in the plugin root is pre-configured. Update credentials as needed.

### Filesystem (Required)

Pre-configured to use `${workspaceRoot}`. No additional setup needed -- filesystem access is scoped to your project directory.

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
3. Copy the API key and replace `your-notion-api-key` in `.mcp.json`
4. Share your "Founder OS HQ - Finance" database with the integration (or legacy "Invoice Processor - Invoices" if not using HQ template)
5. Share your "Founder OS HQ - Reports" database with the integration (or legacy "Expense Report Builder - Reports")
6. If using the Founder OS HQ template, both databases are pre-created -- no lazy creation needed

### Google Drive via gws CLI (Optional)

The plugin uses the `gws` CLI tool to access receipts stored in Google Drive. No MCP server is needed for Drive access.

**Setup steps:**
1. Install the gws CLI tool and authenticate with `gws auth login`
2. Verify access by running:
   ```bash
   which gws || echo "gws CLI not available"
   gws drive files list --params '{"q":"name contains '\''receipt'\''","pageSize":5}' --format json
   ```

## Verification

Run:
```
/expense:summary
```

Expected result: A summary of expenses for the current month, or "No expenses found" if no data exists yet.

If you encounter errors:
1. Check that required MCP servers (filesystem) are accessible
2. Verify Notion API key and database sharing (if using Notion)
3. Ensure the plugin folder is in the correct location
4. Check Node.js and npx versions
