# /founder-os:setup:verify

Run health checks on the Founder OS installation.

## Usage

```
/founder-os:setup:verify
```

## Instructions

Run each check below and report results as a table with Pass/Fail status.

### 1. Notion Connectivity

- Search Notion for databases with `[FOS]` prefix using the Notion MCP search tool.
- Count how many of the 22 expected databases exist.
- List any missing databases by name.

### 2. gws CLI Authentication

- Run `gws auth status` via bash to check Google authentication.
- If authenticated, run `gws gmail list --limit=1` to confirm Gmail access.
- Run `gws calendar list --limit=1` to confirm Calendar access.

### 3. Plugin Symlinks

- Check that `.claude/plugins/` directory exists in the project root.
- Count symlinks pointing to `founder-os-*` directories.
- Report any broken symlinks.

### 4. MCP Configuration

- Read `.mcp.json` in the project root.
- Verify `notion` server entry exists with `NOTION_API_KEY` env var.
- Verify `filesystem` server entry exists with `WORKSPACE_DIR` path.

### 5. Environment Variables

- Check that `.env` file exists.
- Verify `NOTION_API_KEY` is set and not a placeholder.
- Verify `WORKSPACE_DIR` is set and the directory exists.
- Report optional vars (SLACK_BOT_TOKEN, WEB_SEARCH_API_KEY) as configured/not configured.

### Output Format

```
Founder OS Health Check
=======================

| Check              | Status | Details                    |
|--------------------|--------|----------------------------|
| Notion API         | ✓ Pass | Connected, 22/22 databases |
| gws CLI            | ✓ Pass | Gmail + Calendar confirmed |
| Plugin Symlinks    | ✓ Pass | 33 plugins linked          |
| MCP Config         | ✓ Pass | notion + filesystem        |
| Environment        | ✓ Pass | All required vars set      |
| Slack (optional)   | — Skip | Token not configured       |

Result: 5/5 required checks passed
```
