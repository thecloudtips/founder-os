# Installation Guide: LinkedIn Post Generator

> Generate LinkedIn posts from topics, documents, or campaigns with multiple frameworks, audience targeting, and hook optimization

## Prerequisites

- [ ] Claude Code installed
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH

### MCP Servers Required

- [ ] **Filesystem** -- Save generated posts to local files (Required)
- [ ] **Notion** -- Track generated posts and log history (Optional)

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:

   ```bash
   cp -r founder-os-linkedin-post-generator ~/path-to-plugins/
   ```

2. **Configure MCP servers** (see next section).

3. **Verify installation** by running `/linkedin:post "test topic"`.

## MCP Server Setup

### Filesystem (Required)

The Filesystem MCP server allows the plugin to save generated posts to local files. Without it, the plugin cannot persist output.

#### Configure Environment

No environment variables are needed for Filesystem. The server needs access to directories where posts will be saved.

The `.mcp.json` in the plugin root is pre-configured:

```json
{
  "filesystem": {
    "command": "npx",
    "args": [
      "-y",
      "@modelcontextprotocol/server-filesystem",
      "${CLAUDE_PLUGIN_ROOT}/linkedin-posts"
    ]
  }
}
```

The `linkedin-posts/` directory is created automatically on first use. You can adjust the path in `.mcp.json` to allow access to additional directories.

### Notion (Optional)

Notion stores a log of generated posts for tracking, review, and reuse. The plugin writes to the consolidated **"[FOS] Content"** database with `Type="LinkedIn Post"`. If not found, it tries **"Founder OS HQ - Content"**. If the HQ database is not found, it falls back to the legacy **"LinkedIn Post Generator - Posts"** database. The plugin works fully without Notion -- posts display in chat and save to local files instead.

#### Setup Steps

1. Go to https://www.notion.so/my-integrations
2. Create a new integration (name: "Founder OS")
3. Copy the API key
4. Share your target Notion workspace pages with the integration

#### Configure Environment

```bash
export NOTION_API_KEY="ntn_your-key-here"
```

Or add it to your shell profile (~/.zshrc, ~/.bashrc):

```bash
echo 'export NOTION_API_KEY="ntn_your-key-here"' >> ~/.zshrc
```

The `.mcp.json` is pre-configured:

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

#### Notion Database

The plugin discovers existing databases automatically. If you have the **Founder OS HQ** workspace template installed, it writes to "[FOS] Content" (with Type="LinkedIn Post"). If not found, it tries "Founder OS HQ - Content". Otherwise, it falls back to the legacy "LinkedIn Post Generator - Posts" database. No manual database setup required.

## Verification

Run:

```
/linkedin:post "why every founder should write online"
```

Expected result: A LinkedIn post in founder voice with an optimized hook, structured body, and call-to-action. The post file is saved to `linkedin-posts/` and logged to Notion if configured.

If you encounter errors:

| Error | Solution |
|-------|----------|
| "Filesystem MCP server is not connected" | Verify `.mcp.json` paths and that npx is in your PATH |
| "Unable to save post file" | Check write permissions on the `linkedin-posts/` directory |
| "Notion unavailable" | This is a warning, not an error. Posts still display in chat and save locally. |

## Troubleshooting

### Posts Not Saving to Disk

Verify the Filesystem MCP server is running and that the configured directory path exists or is writable. Check that `.mcp.json` includes the correct `@modelcontextprotocol/server-filesystem` entry.

### Notion Not Logging Posts

Confirm `NOTION_API_KEY` is set and valid. Ensure the integration has been shared with at least one workspace page. The database is created lazily on first use -- if you don't see it, run a command once and check again.

### npx Not Found

Ensure Node.js 18+ is installed and `npx` is available in your shell PATH. Run `npx --version` to verify.
