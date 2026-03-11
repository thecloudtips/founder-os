# Founder OS HQ — Installation Guide

This guide walks you through setting up the Founder OS HQ Notion workspace from scratch. The HQ workspace consolidates all plugin databases into a single, organized hierarchy with pre-built relations and a command center dashboard.

---

## Prerequisites

Before you begin, ensure you have:

1. **A Notion account** (free or paid — paid recommended for larger workspaces)
2. **A Notion API integration token** — create one at [notion.so/my-integrations](https://www.notion.so/my-integrations)
   - Click "New integration"
   - Name it something like "Founder OS"
   - Select the workspace you want to use
   - Copy the "Internal Integration Secret" (starts with `ntn_`)

---

## Step 1: Install the HQ Template

Duplicate the Founder OS HQ template into your Notion workspace:

1. Open the Founder OS HQ template (link TBD)
2. Click **Duplicate** in the top-right corner
3. Select your target workspace
4. Wait for the duplication to complete — this creates the full workspace structure with all 21 databases, relations, and the Command Center dashboard

> **Note:** Duplication preserves all database schemas, property types, relations, and rollups. No manual configuration is needed.

---

## Step 2: Verify Installation

Open the duplicated "Founder OS HQ" page and confirm that all 21 databases exist, organized under the following groups:

### CRM (4 databases)

| Database | Purpose |
|----------|---------|
| Founder OS HQ - Companies | Client and vendor company records |
| Founder OS HQ - Contacts | People associated with companies |
| Founder OS HQ - Deals | Sales pipeline and deal tracking |
| Founder OS HQ - Communications | Email and meeting activity log |

### Operations (3 databases)

| Database | Purpose |
|----------|---------|
| Founder OS HQ - Tasks | Action items from all plugins |
| Founder OS HQ - Meetings | Meeting prep, notes, and intelligence |
| Founder OS HQ - Finance | Invoices, expenses, and proposals |

### Intelligence (4 databases)

| Database | Purpose |
|----------|---------|
| Founder OS HQ - Briefings | Daily briefings and morning syncs |
| Founder OS HQ - Knowledge Base | Indexed sources and documents |
| Founder OS HQ - Research | Competitive intel and newsletter research |
| Founder OS HQ - Reports | Generated reports and analyses |

### Content & Deliverables (3 databases)

| Database | Purpose |
|----------|---------|
| Founder OS HQ - Content | Blog posts, LinkedIn posts, newsletters |
| Founder OS HQ - Deliverables | SOWs, proposals, contracts |
| Founder OS HQ - Prompts | Team prompt library |

### Growth & Meta (5 databases)

| Database | Purpose |
|----------|---------|
| Founder OS HQ - Goals | Goal tracking with RAG status |
| Founder OS HQ - Milestones | Goal milestones (linked to Goals) |
| Founder OS HQ - Learnings | Learning log entries |
| Founder OS HQ - Weekly Insights | Weekly learning synthesis |
| Founder OS HQ - Workflows | Workflow definitions and execution history |
| Founder OS HQ - Activity Log | Cross-plugin activity and time savings |
| Founder OS HQ - Intelligence | Learned patterns and self-healing data (Adaptive Intelligence Engine) |

To create the Intelligence database manually if it is missing from the template, use the JSON schema at `_infrastructure/notion-db-templates/hq-intelligence.json`.

If any other database is missing, re-duplicate the template. Do not create databases manually — the relations and rollups depend on exact property names.

---

## Step 3: Configure Notion MCP

### Set the API key

Add your Notion integration token to your environment. The exact method depends on your setup:

**Claude Code `.mcp.json` (per-project):**

```json
{
  "mcpServers": {
    "notion": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-notion"],
      "env": {
        "NOTION_API_KEY": "ntn_your_token_here"
      }
    }
  }
}
```

**Environment variable (global):**

```bash
export NOTION_API_KEY="ntn_your_token_here"
```

### Share databases with the integration

1. Open the top-level "Founder OS HQ" page in Notion
2. Click the **...** menu in the top-right corner
3. Select **Connections** > **Connect to** > your integration name
4. Confirm access — this shares the page and all child databases with the integration

> **Important:** Sharing the parent page shares all databases underneath it. You do not need to share each database individually.

---

## Step 4: Install Plugins

Install any Founder OS plugins you want to use. Each plugin is a standalone directory that you place alongside your project:

```
your-workspace/
  founder-os-inbox-zero/
  founder-os-daily-briefing-generator/
  founder-os-notion-command-center/
  ...
```

Plugins auto-discover HQ databases by searching for the `Founder OS HQ - [Name]` naming convention. No per-plugin database configuration is required.

---

## Step 5: Test Connectivity

Run the following command to verify that the Notion MCP connection is working and all databases are discoverable:

```
/notion:query "Show all databases"
```

You should see all 21 HQ databases listed in the response. If any are missing, verify that:

- The Notion API key is correctly set
- The Founder OS HQ page is shared with your integration
- The database names match the `Founder OS HQ - [Name]` convention

---

## Step 6: Optional — Customize the Command Center

The HQ template includes a Command Center dashboard page with pre-built views. You can customize these to match your workflow:

- **Filter views** by status, date range, or category
- **Add linked views** of databases you use most frequently
- **Pin the Command Center** to your Notion sidebar for quick access
- **Create custom views** for specific reporting needs (e.g., "This Week's Tasks", "Red Health Clients")

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Database not found" errors | Ensure the HQ page is shared with your Notion integration |
| Plugin creates its own database | Plugin may be an older version — update to latest, which searches for HQ databases first |
| Missing relations between databases | Re-duplicate the template; do not manually create databases |
| API rate limits | Notion limits to ~3 requests/second; batch operations may slow down |

---

## Next Steps

- Read the [Migration Guide](MIGRATION.md) if you have existing plugin-specific databases
- Explore individual plugin README files for command documentation
- Run `/morning:sync` to test a multi-source plugin against the HQ workspace
