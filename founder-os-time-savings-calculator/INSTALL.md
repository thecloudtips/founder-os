# Installation Guide: founder-os-time-savings-calculator

> Scans all Founder OS plugins and calculates time saved, dollar value, and ROI

## Prerequisites

- [ ] Claude Code installed
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH

### MCP Servers Required

- [ ] **Notion** -- Scan plugin databases and store report tracking data
- [ ] **Filesystem** -- Write report files to local disk

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:

   ```bash
   cp -r founder-os-time-savings-calculator ~/path-to-plugins/
   ```

2. **Configure MCP servers** (see next section).

3. **Verify installation** (see [Verification](#verification) section).

## MCP Server Setup

The `.mcp.json` file in the plugin root is pre-configured. Update the environment variables below.

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
5. Share your target workspace pages with the integration (including the consolidated "Founder OS HQ" databases or legacy plugin databases you want scanned)

### Filesystem (Required)

```json
{
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/allowed/directory"],
    "env": {}
  }
}
```

**Setup steps:**
1. Replace `/path/to/allowed/directory` with the directory where you want reports saved
2. The filesystem server will only access files within this directory

## Configuration

After enabling MCP servers:

1. Open `.mcp.json` and verify both servers are enabled
2. Replace all placeholder values with your actual credentials and paths
3. Run `/savings:configure` to set your hourly rate and customize time estimates

## Verification

Run the following command to verify your installation:

```
/savings:quick
```

Expected result: A chat-only summary showing any completed tasks found across your Founder OS plugin databases, with time savings estimates.

If you encounter errors:
1. Check that all required MCP servers are running
2. Verify your Notion API key is correct
3. Ensure all plugin databases are shared with your Notion integration
4. Check Node.js and npx versions
