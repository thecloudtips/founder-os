# Installation Guide: founder-os-contract-analyzer

> Analyzes legal contracts to extract key terms, flag risky clauses, and compare against standard templates.

## Prerequisites

- [ ] Claude Code installed
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH

### MCP Servers Required

- [ ] **Filesystem** (required) -- Read contract files from the local filesystem
- [ ] **Notion** (optional) -- Store analysis results in a tracking database

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:

   ```bash
   cp -r founder-os-contract-analyzer ~/.claude/plugins/
   ```

2. **Configure MCP servers** (see next section).

3. **Verify installation** by running `/contract:analyze` in Claude Code.

## MCP Server Setup

### Filesystem (Required)

The Filesystem MCP server allows the plugin to read contract files from your local filesystem.

```json
{
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/your/contracts"],
    "env": {
      "WORKSPACE_DIR": "/path/to/your/contracts"
    }
  }
}
```

**Setup steps:**
1. Decide which directory contains your contracts (e.g., `~/Documents/contracts`)
2. Update the path in both the `args` array and `WORKSPACE_DIR` environment variable
3. The plugin will be able to read any file within this directory

### Notion (Optional)

Notion integration enables persistent storage of contract analysis results.

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
2. Create a new integration named "Contract Analyzer"
3. Copy the Internal Integration Secret
4. Replace `your-notion-api-key` with the copied key
5. The plugin writes to the consolidated **"Founder OS HQ - Deliverables"** database (with Type = "Contract"). If the HQ database does not exist, it falls back to the legacy "Contract Analyzer - Analyses" database. If neither exists, results are displayed in chat only. See `_infrastructure/notion-db-templates/hq-deliverables.json` for the HQ database schema.

**Without Notion:** The plugin works fully without Notion. Analysis results are displayed in chat instead of being saved to a database.

## Configuration

The `.mcp.json` file in the plugin root is pre-configured. Update the placeholder values:

1. Replace `${WORKSPACE_DIR}` with the absolute path to your contracts directory
2. Replace `${NOTION_API_KEY}` with your Notion integration key (or remove the notion entry if not using Notion)

## Verification

Run the following command to verify installation:

```
/contract:analyze path/to/any/contract.pdf
```

Expected result: A structured analysis report showing contract type, key terms, risk assessment, and recommendations.

If you encounter errors:
1. Check that the Filesystem MCP server is running and the path is correct
2. Verify the contract file exists and is a supported format (PDF, DOCX, MD, TXT)
3. If using Notion, verify the API key is valid and the integration has workspace access
4. Ensure Node.js and npx are available in your PATH

## Customizing Standard Terms

To customize the comparison baseline used by `/contract:compare`:

1. Copy `templates/standard-terms.md` to a new location
2. Modify the Standard Range, Acceptable, and Red Flag values to match your risk tolerance
3. Use `--standards=path/to/your/custom-terms.md` when running the compare command
