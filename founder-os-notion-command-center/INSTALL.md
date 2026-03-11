# Installation Guide: founder-os-notion-command-center

> Control your Notion workspace with plain English

## Prerequisites

- [ ] Claude Code installed
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH

### MCP Servers Required

- [ ] **Notion** (`@modelcontextprotocol/server-notion`) -- Full Notion API access

This plugin requires only the Notion MCP server. No other MCP servers are needed.

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:

   ```bash
   cp -r founder-os-notion-command-center ~/path-to-plugins/
   ```

2. **Configure the Notion MCP server** (see next section).

3. **Verify installation** (see [Verification](#verification) section).

## MCP Server Setup

### Step 1: Create a Notion Integration

1. Go to [https://www.notion.so/my-integrations](https://www.notion.so/my-integrations)
2. Click **"New integration"**
3. Name it (e.g., "Founder OS" or "Claude Code")
4. Select your workspace
5. Under **Capabilities**, ensure these are enabled:
   - Read content
   - Update content
   - Insert content
   - Read user information (for People properties)
6. Click **Submit**
7. Copy the **Internal Integration Secret** (starts with `ntn_`)

### Step 2: Share Pages with the Integration

The Notion integration can only access pages explicitly shared with it.

1. Open each top-level page you want the plugin to access
2. Click the **"..."** menu in the top-right corner
3. Click **"Connections"** > **"Add connections"**
4. Search for your integration name and select it
5. Click **"Confirm"**

**Tip**: Share a parent page to grant access to all its children. For full workspace access, share your top-level pages.

### Step 3: Set the API Key

Set the `NOTION_API_KEY` environment variable:

```bash
# Add to your shell profile (~/.zshrc, ~/.bashrc, etc.)
export NOTION_API_KEY="ntn_your_integration_secret_here"
```

### Step 4: Verify the MCP Configuration

The plugin's `.mcp.json` is pre-configured:

```json
{
  "mcpServers": {
    "notion": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-notion"],
      "env": {
        "NOTION_API_KEY": "${NOTION_API_KEY}"
      }
    }
  }
}
```

No changes needed if your `NOTION_API_KEY` environment variable is set.

## Verification

Start a Claude Code session and try:

```
/notion:query What pages do I have?
```

Expected result: A list of Notion pages accessible to your integration.

If you see "Notion MCP server is not connected":
1. Check that `NOTION_API_KEY` is set: `echo $NOTION_API_KEY`
2. Verify npx works: `npx -y @modelcontextprotocol/server-notion --help`
3. Ensure pages are shared with the integration

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Notion MCP server is not connected" | Check `NOTION_API_KEY` is exported in your shell profile |
| "Could not find page" | Share the page with your Notion integration |
| "Permission error" | Verify integration has Read + Update + Insert capabilities |
| "Rate limit" | Wait a moment and retry; Notion limits API calls |
| npx errors | Ensure Node.js 18+ is installed: `node --version` |
