# Installation Guide: Client Context Loader

> Parallel-gathering plugin that assembles complete client dossiers from Notion CRM, Gmail, Google Drive, and Google Calendar.

## Prerequisites

- [ ] Claude Code with Node.js 18+ and npx
- [ ] Notion workspace with CRM Pro template
- [ ] `gws` CLI installed and authenticated for Gmail (required) and optionally Calendar/Drive

### Required Services

| Service | Required | How |
|---------|----------|-----|
| Notion | Yes | MCP server (`@modelcontextprotocol/server-notion`) |
| Gmail | Yes | `gws` CLI (`gws gmail ...`) |
| Google Calendar | Optional | `gws` CLI (`gws calendar ...`) |
| Google Drive | Optional | `gws` CLI (`gws drive ...`) |

## Step 1: CRM Pro Template Setup

This plugin integrates with the **Founder OS HQ** consolidated Notion workspace or a standalone **CRM Pro** template.

### Option A: Founder OS HQ (Recommended)

If you have the Founder OS HQ workspace set up, the plugin automatically discovers the "[FOS] Companies" database (or "Founder OS HQ - Companies") and writes dossiers directly to Company pages. No additional CRM setup is needed.

### Option B: Standalone CRM Pro

If you are not using the HQ workspace, this plugin integrates with the **CRM Pro** Notion template by [Mindful Yesmads](https://www.notion.so/templates/crm-plus).

1. **Duplicate the template** to your Notion workspace
2. The template provides four databases: Companies, Contacts, Deals, Communications
3. Add your client data to the databases (or import existing data)

The plugin discovers databases in this order: "[FOS] Companies" → "Founder OS HQ - Companies" → "Companies" / "CRM - Companies" → fallback standalone "Client Dossiers" database.

### Optional Enrichment Properties

For full plugin functionality, add these custom properties to your CRM Pro databases. If using Founder OS HQ, these are already included in the consolidated schema.

**Companies database:**
- `Client Health Score` (Number, 0-100) — auto-populated by the plugin
- `Dossier` (Rich Text) — stores the full serialized client dossier
- `Dossier Completeness` (Number, 0.0-1.0) — data completeness score
- `Dossier Generated At` (Date) — when the dossier was last assembled
- `Dossier Stale` (Checkbox) — whether the 24h TTL has expired
- `VIP` (Checkbox) — flag high-priority clients

**Contacts database:**
- `Preferred Communication` (Select: Email, Phone, Slack, Video) — contact preference
- `Timezone` (Text) — for scheduling awareness

**Deals database:**
- `Next Action` (Text) — auto-populated next step
- `Risk Level` (Select: Low, Medium, High) — auto-populated by the plugin

**Communications database:**
- `Sentiment` (Select: Positive, Neutral, Negative) — auto-populated by the plugin

These properties are optional. The plugin works with the base CRM Pro template but provides richer insights when these fields exist.

## Step 2: Notion Integration

1. Go to [notion.so/my-integrations](https://www.notion.so/my-integrations)
2. Create a new integration (name it "Founder OS" or "Client Context")
3. Copy the API key
4. Share each CRM Pro database with the integration:
   - Open each database (Companies, Contacts, Deals, Communications)
   - Click "..." menu → "Connections" → Add your integration
5. Set the environment variable:
   ```bash
   export NOTION_API_KEY="your-notion-api-key"
   ```

## Step 3: gws CLI Setup

The plugin uses the `gws` CLI for Gmail, Google Calendar, and Google Drive access.

1. Install the `gws` CLI (see your organization's gws installation guide)
2. Authenticate with your Google account:
   ```bash
   gws auth login
   ```
3. Verify the CLI is available:
   ```bash
   which gws
   ```
4. Test Gmail access:
   ```bash
   gws gmail users messages list --params '{"userId":"me","q":"in:inbox","maxResults":1}' --format json
   ```
5. (Optional) Test Calendar access:
   ```bash
   gws calendar events list --params '{"calendarId":"primary","timeMin":"2026-03-01T00:00:00Z","timeMax":"2026-03-09T00:00:00Z","singleEvents":true}' --format json
   ```
6. (Optional) Test Drive access:
   ```bash
   gws drive files list --params '{"pageSize":1,"fields":"files(id,name)"}' --format json
   ```

## Step 4: Plugin Installation

1. Copy the plugin folder into your Claude Code plugins directory:
   ```bash
   cp -r founder-os-client-context-loader ~/path-to-plugins/
   ```

2. The `.mcp.json` in the plugin root is pre-configured. Verify environment variables are set.

3. Restart Claude Code to load the plugin.

## Verification

Run these commands to verify:

```
/client:load "Test Company"
```

Expected: The plugin searches your CRM databases and returns a dossier (or "client not found" if the company doesn't exist in your CRM).

### Verification Checklist

- [ ] Notion MCP connects (can search databases)
- [ ] `gws` CLI is installed (`which gws` returns a path)
- [ ] Gmail access works via `gws gmail` commands
- [ ] CRM Pro databases are accessible (Companies, Contacts, Deals, Communications found)
- [ ] `/client:load` returns results or "not found" (not an error)
- [ ] Google Calendar access works via `gws calendar` (optional)
- [ ] Google Drive access works via `gws drive` (optional)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Notion MCP is required" | Set `NOTION_API_KEY` env var and restart Claude Code |
| Databases not found | Share each CRM database with your Notion integration |
| "gws CLI unavailable" | Install the gws CLI and run `gws auth login` |
| Gmail errors | Re-authenticate with `gws auth login` |
| Partial dossier | Calendar or Drive may not be accessible via gws — this is OK |
| Stale data | Use `--refresh` flag to bypass the 24h dossier cache |
