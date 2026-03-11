# Installation Guide: founder-os-newsletter-draft-engine

> Researches topics across web, GitHub, Reddit, and Quora, then generates structured newsletter drafts in founder voice.

## Prerequisites

- [ ] Claude Code (platform: **Claude Code**)
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH

### MCP Servers Required

- [ ] **Web Search** (required) -- Built-in WebSearch tool, no configuration needed
- [ ] **Filesystem** (required) -- Reading source material and writing newsletter output
- [ ] **Notion** (optional) -- Research session tracking and newsletter history (uses consolidated "[FOS] Research" and "[FOS] Content" databases, falls back to "Founder OS HQ - " prefixed names, then legacy "Newsletter Engine - Research" if not found)
- [ ] **gws CLI** (optional) -- Access to existing research documents in Google Drive

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:

   ```bash
   cp -r founder-os-newsletter-draft-engine ~/path-to-plugins/
   ```

2. **Create the newsletters output directory:**

   ```bash
   mkdir -p founder-os-newsletter-draft-engine/newsletters
   ```

3. **Configure MCP servers** (see next section).

4. **Verify installation** by running `/newsletter:research "test topic"`.

## MCP Server Setup

The plugin's `.mcp.json` is pre-configured. Set the following environment variables for each server.

### Web Search (Required)

No MCP configuration needed. The Newsletter Draft Engine uses the built-in WebSearch tool provided by Claude Code. This tool is always available and does not require any credentials or server setup.

To verify it is working, ask Claude to search for any topic. If results are returned, Web Search is ready.

### Filesystem (Required)

```json
{
  "filesystem": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-filesystem",
      "${CLAUDE_PLUGIN_ROOT}"
    ]
  }
}
```

**Setup steps:**
1. The Filesystem MCP server is configured to access the plugin directory by default via `${CLAUDE_PLUGIN_ROOT}`
2. No additional credentials are needed
3. Ensure the `newsletters/` subdirectory exists for output:
   ```bash
   mkdir -p newsletters
   ```
4. Newsletter drafts are written to `newsletters/[topic-slug]-[YYYY-MM-DD].md`

### Notion (Optional)

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
5. The plugin discovers existing databases automatically. If you have the **Founder OS HQ** workspace template installed, it writes to "[FOS] Research" (with Type="Newsletter Research") and "[FOS] Content" (with Type="Newsletter"). It also checks "Founder OS HQ - Research" and "Founder OS HQ - Content" as fallbacks. Otherwise, it falls back to the legacy "Newsletter Engine - Research" database. No manual database setup required.

### Google Drive via gws CLI (Optional)

The plugin uses the `gws` CLI tool to access research documents stored in Google Drive. No MCP server is needed for Drive access.

**Setup steps:**
1. Install the gws CLI tool and authenticate with `gws auth login`
2. Verify access by running:
   ```bash
   which gws || echo "gws CLI not available"
   gws drive files list --params '{"q":"name contains '\''research'\''","pageSize":5}' --format json
   ```

## Verification

Run the following command to verify your installation:

```
/newsletter:research "AI trends" --days=7
```

Expected result: A structured research summary with findings from the web, scored by recency and relevance. The output is displayed in chat and optionally saved to Notion.

If you encounter errors:
1. Verify the Filesystem MCP is running (`/mcp` to see server status)
2. Confirm the `newsletters/` output directory exists
3. Web Search is built-in and should always work -- if it does not, check your Claude Code version
4. For Notion/Drive errors, the plugin will gracefully degrade and show results in chat
