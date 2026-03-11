# Installation Guide: Knowledge Base Q&A

> Search your Notion workspace and Google Drive for sourced answers with citations.

## Prerequisites

- [ ] Claude Code installed
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH

### MCP Servers Required

- [ ] **Notion** -- Knowledge base search and query tracking (Required)
- [ ] **gws CLI** -- Document search across Google Drive files (Optional)

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:

   ```bash
   cp -r founder-os-knowledge-base-qa ~/path-to-plugins/
   ```

2. **Configure MCP servers** (see next section).

3. **Verify installation** by running `/kb:ask "What is our refund policy?"`.

## MCP Server Setup

The plugin includes a pre-configured `.mcp.json`. Set the environment variables below.

### Notion (Required)

**Setup steps:**
1. Go to https://www.notion.so/my-integrations
2. Click "New integration"
3. Name it (e.g., "Knowledge Base Q&A")
4. Select your workspace
5. Copy the Internal Integration Secret
6. Set the environment variable:
   ```bash
   export NOTION_API_KEY="your-notion-integration-secret"
   ```

**Share pages with the integration:**
- Open each Notion page or database you want searchable
- Click the "..." menu → "Connections" → Add your integration
- The plugin can only search pages shared with the integration

**Required capabilities:**
- Read content
- Search (for `notion-search`)

### Google Drive via gws CLI (Optional)

The plugin works without Google Drive -- it will search Notion only. To add Drive search:

**Setup steps:**
1. Install the gws CLI tool and authenticate with `gws auth login`
2. Verify access by running:
   ```bash
   which gws || echo "gws CLI not available"
   gws drive files list --params '{"q":"name contains '\''test'\''","pageSize":5}' --format json
   ```

## Configuration

The `.mcp.json` file is pre-configured. Environment variables to set:

| Variable | Required | Description |
|----------|----------|-------------|
| `NOTION_API_KEY` | Yes | Notion integration secret |

## Verification

Run these commands to verify setup:

```
/kb:ask "test question"
```

**Expected**: An answer attempt (even if no content is found yet, it should connect to Notion successfully).

```
/kb:index --scope=notion
```

**Expected**: A summary of indexed Notion pages with classification breakdown.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Notion MCP server is not connected" | Check `NOTION_API_KEY` is set and valid |
| No results found | Share Notion pages with the integration (Connections menu) |
| "Google Drive not available" | Install gws CLI and run `gws auth login`, or use `--sources=notion` |
| Rate limiting errors | Reduce scope with `--scope=notion` or wait and retry |
| Index shows 0 sources | Ensure pages are shared with the Notion integration |

## Notion Database Setup

The plugin uses a single consolidated Notion database for both queries and sources:

- **[FOS] Knowledge Base** -- Stores both query records (Type="Query") and source index records (Type="Source")

If the consolidated database is not found, the plugin falls back to the legacy database names:
- "Knowledge Base Q&A - Queries" (for `/kb:ask` logging)
- "Knowledge Base Q&A - Sources" (for `/kb:index` cataloging)

If neither the consolidated nor legacy databases exist, the plugin skips Notion storage and outputs results to chat only. Databases are not auto-created.
