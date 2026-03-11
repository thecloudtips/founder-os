# Installation Guide: Google Drive Brain

> Searches, summarizes, and answers questions from Google Drive documents with optional Notion activity tracking.

## Prerequisites

- [ ] Claude Code installed
- [ ] Node.js 18+ installed
- [ ] npx available in your PATH

### MCP Servers Required

- [ ] **Google Drive** (`gws` CLI (Drive)) -- File search and content access (Required)
- [ ] **Notion** (`@modelcontextprotocol/server-notion`) -- Activity logging (Optional)

## Installation

1. **Copy the plugin folder** into your Claude Code plugins directory:

   ```bash
   cp -r founder-os-google-drive-brain ~/path-to-plugins/
   ```

2. **Configure MCP servers** (see next section).

3. **Verify installation** by running `/drive:search test` (see [Verification](#verification) section).

## MCP Server Setup

The plugin includes a pre-configured `.mcp.json`. Set the environment variables below.

### Google Drive (Required)

The gws CLI (`gws drive`) provides file search, folder traversal, and document content extraction. This plugin cannot function without it.

**`.mcp.json` configuration (pre-configured):**

```bash
# Verify gws CLI access:
gws drive files list --params '{"q":"trashed=false","pageSize":1}' --format json
```

**Setup steps:**

1. Go to the [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or reuse an existing one shared with other Google MCP servers)
3. Enable the **Google Drive API**:
   - Navigate to APIs & Services > Library
   - Search for "Google Drive API"
   - Click Enable
4. Create OAuth 2.0 credentials:
   - Go to APIs & Services > Credentials
   - Click "Create Credentials" > "OAuth client ID"
   - Application type: Desktop app
   - Download the credentials JSON file
5. Set environment variables:
   ```bash
   export GOOGLE_CREDENTIALS_PATH="/path/to/credentials.json"
   export GOOGLE_TOKEN_PATH="/path/to/token.json"
   ```
6. On first run, the MCP server will open a browser window for OAuth consent. Approve access to complete authentication. The token will be saved to `GOOGLE_TOKEN_PATH`.

**Required OAuth scopes:**
- `https://www.googleapis.com/auth/drive.readonly` (file search and content reading)

### Notion (Optional)

The Notion MCP server is used only for activity logging -- tracking which searches, summaries, and questions you've run. All four commands (`/drive:search`, `/drive:summarize`, `/drive:ask`, `/drive:organize`) work without Notion. When Notion is unavailable, the plugin skips logging silently.

**`.mcp.json` configuration (pre-configured):**

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
2. Click "New integration"
3. Name it (e.g., "Google Drive Brain")
4. Select your workspace
5. Copy the Internal Integration Secret
6. Set the environment variable:
   ```bash
   export NOTION_API_KEY="your-notion-integration-secret"
   ```
7. Share any parent page where you want the activity log database created with the integration (via the page's "..." menu > "Connections")

**Required capabilities:**
- Read content
- Insert content (for creating the activity log database)

## Configuration

The `.mcp.json` file is pre-configured with both servers. Set the following environment variables:

| Variable | Required | Description |
|----------|----------|-------------|
| `GOOGLE_CREDENTIALS_PATH` | Yes | Path to Google OAuth credentials JSON |
| `GOOGLE_TOKEN_PATH` | Yes | Path to Google OAuth token JSON (created on first auth) |
| `NOTION_API_KEY` | No | Notion integration secret for activity logging |

## Verification

Run the following command to verify Google gws CLI (Drive) is connected:

```
/drive:search test
```

**Expected result:** A list of Drive files matching "test", or a message indicating no results found. Either outcome confirms the gws CLI (`gws drive`) is connected and authenticated.

If you also configured Notion, run:

```
/drive:ask "What files are in my Drive?"
```

**Expected result:** An answer attempt with the query logged to the "[FOS] Activity Log" Notion database (or fallback "Founder OS HQ - Activity Log" / "Google Drive Brain - Activity" if the primary database is not found).

## Troubleshooting

| Issue | Solution |
|-------|----------|
| gws CLI (Drive) not connecting | Verify `GOOGLE_CREDENTIALS_PATH` points to a valid OAuth credentials JSON file. Re-run authentication if the token has expired. |
| "Google Drive API not enabled" | Go to Google Cloud Console > APIs & Services > Library and enable the Google Drive API for your project. |
| Notion logging not working | Check that `NOTION_API_KEY` is set and valid. Verify the integration has been shared with a Notion page. This is optional -- all commands work without it. |
| File not found errors | The file may not be accessible to the authenticated Google account. Check sharing permissions in Google Drive. |
| OAuth consent screen not appearing | Ensure `GOOGLE_TOKEN_PATH` directory exists and is writable. Delete any stale token file and re-authenticate. |
| Rate limiting from Google | Reduce search scope with `--in` flag to target specific folders, or wait and retry. |

## Optional: Notion Database Setup

The plugin logs activity to a shared Notion database:

- **[FOS] Activity Log** -- Tracks searches, summaries, questions, and organize suggestions with timestamps and result counts.

If the primary database is not found, the plugin falls back to "Founder OS HQ - Activity Log", then to a legacy database named "Google Drive Brain - Activity". If none exists, activity logging is silently skipped. The plugin does not create the database automatically -- use the Founder OS HQ workspace template to provision it.
