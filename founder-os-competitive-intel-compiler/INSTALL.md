# Installation Guide: founder-os-competitive-intel-compiler

> Research competitors via web search and compile structured competitive intelligence reports.

## Prerequisites

- [ ] Claude Code installed
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH
- [ ] Internet access (required for WebSearch tool)

### MCP Servers Required

- [ ] **Filesystem** (required) — Save intelligence reports to local files
- [ ] **Notion** (optional) — Store research results in a tracking database

> **Note on WebSearch**: The web search capability is built into Claude Code as a native tool. No MCP server setup is required for web searching.

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:

   ```bash
   cp -r founder-os-competitive-intel-compiler ~/.claude/plugins/
   ```

2. **Configure MCP servers** (see next section).

3. **Verify installation** by running `/compete:research Notion` in Claude Code.

## MCP Server Setup

### Filesystem (Required)

The Filesystem MCP server allows the plugin to save intelligence reports to your local filesystem.

```json
{
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/your/working/directory"],
    "env": {}
  }
}
```

**Setup steps:**
1. Decide where you want reports saved (e.g., `~/Documents/competitive-intel`)
2. In the plugin's `.mcp.json`, replace `${ALLOWED_PATH}` with that absolute path
3. Reports will be saved as `competitive-intel/[company-slug]-[date].md` within that directory

**Example:**
```json
{
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/yourname/Documents"],
    "env": {}
  }
}
```

### Notion (Optional)

Notion integration stores research results in the consolidated "Founder OS HQ - Research" database (with Type="Competitive Analysis"). The plugin also falls back to the legacy "Competitive Intel Compiler - Research" database name if the HQ database has not been provisioned yet.

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
2. Create a new integration named "Competitive Intel Compiler"
3. Copy the Internal Integration Secret
4. In `.mcp.json`, replace `${NOTION_API_KEY}` with the copied key
5. Provision the "Founder OS HQ - Research" database from the HQ template (see `_infrastructure/notion-db-templates/`), or the plugin will fall back to the legacy "Competitive Intel Compiler - Research" database if it exists

**Without Notion:** The plugin works fully without Notion. Reports are saved to local files and displayed in chat.

## Configuration

The `.mcp.json` file in the plugin root is pre-configured. Update the placeholder values:

1. Replace `${ALLOWED_PATH}` with the absolute path to your working directory
2. Replace `${NOTION_API_KEY}` with your Notion integration key (or remove the notion entry if not using Notion)

**Updated `.mcp.json` example:**
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/Users/yourname/Documents"],
      "env": {}
    }
  }
}
```

## Verification

Run the following command to verify installation:

```
/compete:research Notion
```

Expected result: A structured competitive intelligence report with pricing, features, reviews, positioning analysis, and recommendations.

If you encounter errors:
1. Check that Node.js and npx are available in your PATH (`npx --version`)
2. Verify the Filesystem MCP server path is set to an existing directory
3. Confirm Claude Code has internet access (WebSearch must be enabled)
4. If using Notion, verify the API key is valid and the integration has workspace access
