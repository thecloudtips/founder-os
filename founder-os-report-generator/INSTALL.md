# Installation Guide: Report Generator Factory

> Pipeline-based report generation factory that transforms raw data from CSV, JSON, Notion, and text files into polished Markdown reports with Mermaid charts and executive summaries.

## Prerequisites

- [ ] Claude Desktop with the **Code** tab enabled
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH

### MCP Servers

| Server | Required? | Purpose |
|--------|-----------|---------|
| **Filesystem** | Required | Read local data files and write report output |
| **Notion** | Optional | Read from Notion databases, store generated reports |
| **gws CLI** | Optional | Read source documents from Google Drive (CLI tool, not MCP) |

_Refer to the [MCP Server Setup](#mcp-server-setup) section below for configuration details._

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:

   ```bash
   cp -r founder-os-report-generator ~/.claude/plugins/
   ```

2. **Configure MCP servers** (see next section).

3. **Set environment variables** (see [Environment Variables](#environment-variables)).

4. **Verify installation** (see [Verification](#verification)).

## MCP Server Setup

Edit the `.mcp.json` file in the plugin root to configure the MCP servers for your environment. For Google Drive access, install the gws CLI tool and authenticate with `gws auth login` (see below).

### Filesystem (Required)

The Filesystem MCP server provides read/write access to local data files and report output. This is the only required server.

```json
{
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/path/to/your/workspace"]
  }
}
```

**Setup steps:**
1. Decide which directory will contain your data files and report output
2. Replace `/path/to/your/workspace` with that directory path
3. The server will have read/write access only to this directory and its subdirectories

**Important:** The filesystem path determines where the plugin can read source data and write reports. Use a broad workspace path (e.g., your home directory or a projects folder) to allow flexibility.

### Notion (Optional)

Notion enables reading data from Notion databases and storing generated reports in the "Founder OS HQ - Reports" database (falls back to legacy "Report Generator - Reports" if the consolidated database is not found).

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
2. Create a new integration (name it "Report Generator" or similar)
3. Copy the API key (starts with `ntn_`)
4. Share any source databases with the integration (click "..." on the database, then "Connections" > your integration)
5. Paste the API key into `.mcp.json`

**Note:** If Notion is not configured, the plugin gracefully degrades -- reports are written to the local filesystem only and Notion data sources are skipped.

### Google Drive via gws CLI (Optional)

The gws CLI enables reading source documents (spreadsheets, docs) directly from your Google Drive.

```bash
# Check if gws is installed
which gws || echo "gws CLI not available"

# Authenticate with Google
gws auth login

# Verify access
gws drive files list --params '{"q":"name contains '\''test'\''","pageSize":5,"fields":"files(id,name,mimeType,modifiedTime,webViewLink)"}' --format json
```

**Setup steps:**
1. Install the gws CLI tool
2. Run `gws auth login` to authenticate with your Google account
3. Verify access with the command above

**Note:** If the gws CLI is not installed or not authenticated, the plugin gracefully degrades -- Drive-based data sources are skipped and the plugin reads from local files only.

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `WORKSPACE_DIR` | Yes | -- | Path to the directory for reading data and writing reports |
| `NOTION_API_KEY` | No | -- | Notion integration API key (starts with `ntn_`) |

Set these in your shell profile or pass them inline:

```bash
export WORKSPACE_DIR="$HOME/reports"
export NOTION_API_KEY="ntn_your_key_here"
```

## Verification

Run the following command to verify your installation:

```
/report:generate --sources=./sample-data.csv
```

**Expected result:** The plugin reads the specified data file, processes it, and outputs a Markdown report to your workspace directory.

### Quick verification checklist

1. **Filesystem works:**
   ```
   /report:generate --sources=./any-file.csv
   ```
   Should produce a Markdown report without errors.

2. **Notion works (optional):**
   ```
   /report:generate --team --sources=./data.csv
   ```
   In `--team` mode with Notion connected, the QA agent should store the report in the "Founder OS HQ - Reports" Notion database with Type="Business Report".

3. **Templates work:**
   ```
   /report:from-template --template=executive-summary --sources=./data.csv
   ```
   Should produce a report following the executive summary template structure.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Filesystem MCP not configured" | Ensure `WORKSPACE_DIR` is set and the `.mcp.json` filesystem entry points to a valid directory |
| "Permission denied" reading files | Check that the filesystem MCP server path includes the directory containing your data files |
| "Notion MCP not configured" | Set `NOTION_API_KEY` in `.mcp.json` or run without Notion (filesystem-only mode) |
| Notion database not found | Share the target database with your Notion integration (Connections menu) |
| "gws CLI unavailable" | Install the gws CLI tool and run `gws auth login`, or run without Drive |
| Google auth failure | Run `gws auth login` to re-authenticate |
| Template not found | Check `templates/report-templates/` for available templates: `executive-summary`, `full-business-report`, `project-status-report` |
| Empty report output | Verify the source file exists and contains data; try `--sources=./path/to/file` with an absolute path |
| Plugin not loading | Ensure the folder is in `~/.claude/plugins/` and restart Claude Code |
| Mermaid charts not rendering | Charts render in any Markdown viewer with Mermaid support (GitHub, Notion, VS Code preview) |

## Removing a Server

To disable an optional MCP server, remove or comment out its entry in `.mcp.json`. The plugin will automatically skip that data source and continue with the remaining configured servers.
