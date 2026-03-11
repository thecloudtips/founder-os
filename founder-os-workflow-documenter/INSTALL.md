# Installation Guide: founder-os-workflow-documenter

> Transforms workflow descriptions into structured 7-section SOPs with Mermaid diagrams

## Prerequisites

- [ ] Claude Code installed
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH

### MCP Servers Required

- [ ] **Notion** -- Store and retrieve SOPs (writes to "[FOS] Workflows" DB with Type="SOP")
- [ ] **Filesystem** -- Read input files and write SOP documents

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:

   ```bash
   cp -r founder-os-workflow-documenter ~/path-to-plugins/
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
5. Share your target workspace pages with the integration

SOPs are written to the "[FOS] Workflows" database (Type="SOP"). If that database does not exist, the plugin falls back to "Founder OS HQ - Workflows", then the legacy "Workflow Documenter - SOPs" database. The plugin does not create either database — set up the HQ database using the Notion HQ consolidation process or create it manually from `_infrastructure/notion-db-templates/hq-workflows.json`.

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
1. Replace `/path/to/allowed/directory` with the directory where you want SOPs saved
2. The filesystem server will only access files within this directory

## Verification

Run the following command to verify your installation:

```
/workflow:document "Test process: step 1 do A, step 2 do B, step 3 do C"
```

Expected result: A 7-section SOP document displayed in chat with a Mermaid flowchart, saved to `sops/sop-test-process-[date].md`.

If you encounter errors:
1. Check that all required MCP servers are running
2. Verify API keys and credentials are correct
3. Ensure the plugin folder is in the correct location
4. Check Node.js and npx versions

## Notion-Free Mode

If you prefer not to use Notion, use the `--format=file` flag:

```
/workflow:document "your workflow" --format=file
```

This skips all Notion operations and outputs only to local Markdown files.
