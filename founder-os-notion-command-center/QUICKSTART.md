# Quick Start: founder-os-notion-command-center

> Control your Notion workspace with plain English

**Plugin #17** | **Pillar**: MCP & Integrations | **Platform**: Claude Code

## Available Commands

| Command | Description |
|---------|-------------|
| `/notion:create [description]` | Create pages or databases from natural language |
| `/notion:query [question]` | Search and query your Notion workspace |
| `/notion:update [page] [changes]` | Modify page properties or append content |
| `/notion:template [name]` | Deploy pre-built database templates |

## Usage Examples

### Example 1: Create a Page

```
/notion:create Meeting notes for the Q2 kickoff --parent="Team Wiki"
```

**What happens:** Creates a new page titled "Q2 Kickoff Meeting Notes" under the "Team Wiki" page with a meeting notes structure.

### Example 2: Create a Database

```
/notion:create A project tracker with status, priority, assignee, and due date
```

**What happens:** Auto-detects "project tracker" as a database, designs a schema with Status, Priority (Select), Assignee (People), and Due Date properties, shows the schema for confirmation, then creates it.

### Example 3: Search for a Page

```
/notion:query Find the onboarding guide
```

**What happens:** Searches your Notion workspace for pages matching "onboarding guide" and returns a ranked list with previews and links.

### Example 4: Query a Database

```
/notion:query What are my overdue tasks? --db="Project Tracker"
```

**What happens:** Translates "overdue tasks" into a filter (Due Date < today AND Status != Done), queries the "Project Tracker" database, and returns formatted results.

### Example 5: Update a Page

```
/notion:update "Project Alpha" set status to Done and priority to High
```

**What happens:** Finds the "Project Alpha" page, shows the planned changes (Status: In Progress -> Done, Priority: Medium -> High), and applies them after confirmation.

### Example 6: Append Content

```
/notion:update "Meeting Notes" --append ## Action Items\n- Review budget by Friday\n- Send proposal to client
```

**What happens:** Appends a new "Action Items" section with a checklist to the "Meeting Notes" page.

### Example 7: Deploy a Template

```
/notion:template CRM Contacts --parent="Sales"
```

**What happens:** Deploys a full CRM database with 12 pre-configured properties (Name, Company, Email, Phone, Status, Source, Tags, etc.) under the "Sales" page.

### Example 8: List Available Templates

```
/notion:template
```

**What happens:** Lists all 5 available templates: CRM Contacts, Project Tracker, Content Calendar, Meeting Notes, Knowledge Wiki.

## Tips

- Auto-detection works well: say "tracker" or "database" for databases, "page" or "notes" for pages
- Use `--parent=NAME` to place content under a specific page
- Use `--db=NAME` to target a specific database when querying
- All write operations ask for confirmation before executing
- The plugin only needs Notion MCP -- no other servers required

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Notion MCP server is not connected" | Set `NOTION_API_KEY` environment variable |
| "Could not find page" | Share the page with your Notion integration |
| Ambiguous search results | Provide a more specific page name or use a direct Notion URL |
| "Property not found" | The plugin will list available properties -- pick the right one |

## Next Steps

1. Try the basic commands above
2. Deploy a template to set up your first database
3. Check `INSTALL.md` for advanced configuration
