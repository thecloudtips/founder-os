# Installation Guide: Meeting Prep Autopilot

> Automatically gathers attendee context, past threads, shared documents, and agenda notes to assemble a structured meeting prep brief before every calendar event.

## Prerequisites

- [ ] Claude Code installed
- [ ] Node.js 18+ and npx available on your system
- [ ] `gws` CLI installed and authenticated (for Google Calendar, Gmail, and Drive access)
- [ ] Notion workspace for meeting notes and prep output

### Required Services

| Service | Required | How |
|---------|----------|-----|
| Google Calendar | Yes | `gws` CLI |
| Gmail | Yes | `gws` CLI |
| Notion | Yes | `@modelcontextprotocol/server-notion` (MCP) |
| Google Drive | Optional | `gws` CLI |

### Already Using Daily Briefing Generator (#02)?

If you have the Daily Briefing Generator plugin installed and `gws` is already authenticated, you can reuse the same authentication:

- **Google Calendar, Gmail, and Drive** all use the `gws` CLI. If `gws auth login` has been completed, these services are ready.
- **Notion** uses the same API key. Your existing `NOTION_API_KEY` variable works as-is -- just share any new databases with the same integration.

If `gws` is already authenticated and Notion is configured, skip to [Step 4: Plugin Installation](#step-4-plugin-installation).

## Step 1: Install and Authenticate the gws CLI

The `gws` CLI provides access to Google Calendar, Gmail, and Google Drive from the command line.

1. Install the `gws` CLI (see the gws documentation for platform-specific instructions)
2. Authenticate with your Google account:
   ```bash
   gws auth login
   ```
3. Verify the CLI is working:
   ```bash
   which gws
   gws calendar +agenda --today --format json
   ```
4. The `gws` CLI handles OAuth and token management automatically. No separate credentials files or environment variables are needed for Google services.

## Step 2: Verify Google Service Access

Confirm each Google service is accessible via gws:

```bash
# Calendar
gws calendar +agenda --today --format json

# Gmail
gws gmail users messages list --params '{"userId":"me","q":"is:inbox","maxResults":1}' --format json

# Drive (optional)
gws drive files list --params '{"q":"trashed=false","pageSize":1,"fields":"files(id,name)"}' --format json
```

If any command fails, re-run `gws auth login` and ensure the necessary scopes are authorized.

## Step 3: Notion Setup

1. Go to [notion.so/my-integrations](https://www.notion.so/my-integrations)
2. Click **New integration**
3. Name it "Founder OS" or "Meeting Prep Autopilot"
4. Select the workspace where meeting prep notes will be stored
5. Copy the API key (starts with `ntn_` or `secret_`)
6. Set the environment variable:
   ```bash
   export NOTION_API_KEY="your-notion-api-key"
   ```
7. Share any existing meeting or task databases with the integration:
   - Open the database page
   - Click the "..." menu > **Connections** > Add your integration

The plugin writes to the shared **"[FOS] Meetings"** database. If that database does not exist, it tries **"Founder OS HQ - Meetings"**, then falls back to the legacy **"Meeting Prep Autopilot - Prep Notes"** database. If none exists, the plugin outputs to chat only (no database is lazy-created). To set up the shared database, see the Founder OS HQ setup guide.

## Step 4: Plugin Installation

1. Copy the plugin folder into your Claude Code plugins directory:
   ```bash
   cp -r founder-os-meeting-prep-autopilot ~/path-to-claude-code-plugins/
   ```

2. Verify all prerequisites are met:
   ```bash
   which gws && echo "gws CLI: OK" || echo "gws CLI: MISSING"
   echo $NOTION_API_KEY
   ```

3. Restart Claude Code to load the plugin.

## Configuration Notes

- **Notion environment variable** (`NOTION_API_KEY`) can be set in your shell profile (`~/.zshrc`, `~/.bashrc`) or in a `.env` file if your Claude Code setup supports it.
- **Notion database**: The plugin writes to "[FOS] Meetings" (shared with P07 Meeting Intelligence Hub). Falls back to "Founder OS HQ - Meetings", then "Meeting Prep Autopilot - Prep Notes" if the HQ databases are not found. No database is lazy-created.
- **Google Drive is purely additive.** Meeting prep briefs are fully functional without it. Add Google Drive later at any time by ensuring the Drive scope is authorized in `gws auth login`.
- **gws authentication** is managed by the gws CLI. Run `gws auth login` once to authorize all Google services (Calendar, Gmail, Drive). No separate credentials files or token paths are needed.
- **Credential reuse across plugins.** All Founder OS plugins that use Google services share the same `gws` CLI authentication.

## Verification

Run the following command to verify the plugin is working:

```
/meeting:prep
```

Expected: The plugin scans your upcoming calendar events, gathers attendee context and relevant email threads, and presents a structured meeting prep brief. If Notion is connected, the prep brief is also saved for later reference.

### Verification Checklist

- [ ] `gws` CLI installed (`which gws` returns a path)
- [ ] Google Calendar accessible (`gws calendar +agenda --today --format json` returns data)
- [ ] Gmail accessible (`gws gmail users messages list --params '{"userId":"me","q":"is:inbox","maxResults":1}' --format json` returns data)
- [ ] Notion MCP connects (can search or create databases)
- [ ] `/meeting:prep` returns a structured meeting prep brief (not an error)
- [ ] Google Drive accessible via gws (optional -- shared documents appear in prep brief)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "gws CLI not available" | Install the gws CLI and run `gws auth login` to authenticate |
| Calendar or Gmail commands fail | Run `gws auth login` to re-authenticate; ensure Calendar and Gmail scopes are authorized |
| "Notion MCP not available" | Verify `NOTION_API_KEY` is set and the integration has workspace access |
| Notion database not found | Share the target database with your Notion integration via the Connections menu |
| Gmail returns no results for attendees | Verify attendee email addresses are present on the calendar event; check that Gmail scope is authorized in gws |
| Google Drive documents not appearing | Run `gws auth login` and ensure the Drive scope is authorized |
| "Unknown command" error | Re-copy the plugin folder, ensure the `commands/` directory is present, and restart Claude Code |
| Partial prep brief (some sections empty) | Google Drive is optional. For required services, verify `which gws` returns a path and `gws auth login` has been completed |
| Already configured for Daily Briefing but errors | The same `gws` CLI authentication is shared across all Founder OS plugins that use Google services |
