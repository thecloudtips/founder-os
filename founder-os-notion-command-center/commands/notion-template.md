---
description: Deploy a pre-built Notion database template or list available templates
argument-hint: "[template-name] [--parent=NAME]"
allowed-tools: ["Read"]
---

# Notion Template

Deploy a pre-built business database template or list available templates. Templates provide complete Notion database schemas with properties, options, and suggested views — ready for immediate use.

## Load Skills

Read the notion-database-design skill at `${CLAUDE_PLUGIN_ROOT}/skills/notion-database-design/SKILL.md` for schema design best practices and template deployment protocol.

Read the notion-operations skill at `${CLAUDE_PLUGIN_ROOT}/skills/notion-operations/SKILL.md` for Notion MCP tool usage, workspace discovery, and database creation operations.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `[template-name]` (optional) -- name of the template to deploy. If omitted, list all available templates. Accepts exact names ("CRM Contacts") and common variations ("CRM", "contacts", "project", "calendar", "meetings", "wiki").
- `--parent=NAME` (optional) -- name of the parent page under which to create the database. If omitted, ask the user where to create it.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Step 1: List or Select Template

### No template name provided

Display the template catalog:

```
Available Notion Database Templates:

1. CRM Contacts — Track business contacts, leads, and client relationships (12 properties)
2. Project Tracker — Track projects with tasks, deadlines, and ownership (10 properties)
3. Content Calendar — Plan and track content creation across channels (11 properties)
4. Meeting Notes — Record meeting details, decisions, and action items (8 properties)
5. Knowledge Wiki — Organize team knowledge and reference material (9 properties)

Deploy with: /notion:template [name]
Example: /notion:template "Project Tracker" --parent="My Workspace"
```

Stop here. Wait for the user to invoke the command again with a template name.

### Template name provided

Match the user's input to a template. Accept these variations:

| User input | Maps to |
|-----------|---------|
| "CRM", "CRM Contacts", "contacts", "crm" | CRM Contacts |
| "Project", "Project Tracker", "tasks", "task tracker" | Project Tracker |
| "Content", "Content Calendar", "editorial", "calendar" | Content Calendar |
| "Meeting", "Meeting Notes", "meetings" | Meeting Notes |
| "Wiki", "Knowledge Wiki", "knowledge base", "kb" | Knowledge Wiki |

If the input doesn't match any template, display: "Unknown template '[input]'. Available templates:" followed by the catalog list.

## Step 2: Resolve Parent

If `--parent=NAME` is provided:
1. Search Notion for the parent page using `notion-search`.
2. Disambiguate if multiple matches (numbered list with context).
3. If not found, offer to create at workspace root.

If `--parent` is omitted:
- Ask: "Where should the [Template Name] database be created? Provide a parent page name, or say 'workspace root'."

## Step 3: Load Template Schema

Read the complete template definition from `${CLAUDE_PLUGIN_ROOT}/skills/notion-database-design/references/templates.md`. Each template defines:
- Property names and types
- Default options for Select/Multi-select properties
- Suggested default view (Board, Table, or Calendar)

## Step 4: Confirm Before Creating

Present the full schema for user approval:

```
Deploying: [Template Name]
Parent: [Parent page name]

| Property | Type | Options/Config |
|----------|------|----------------|
| [Name] | Title | -- |
| [Status] | Status | [options] |
| ... | ... | ... |

Properties: [count]
Suggested view: [view type] by [property]

Create this database? (yes / no / modify)
```

If the user says "modify", ask which properties to add, remove, or change. Apply modifications and re-present. Use the notion-database-design skill's property type selection table for any new properties.

If the user says "no", stop. Display: "Template deployment canceled."

## Step 5: Create Database

1. Call `notion-create-database` with the resolved parent, template title, and complete property schema from the template definition.
2. If creation succeeds, display:

```
Database deployed: [Template Name]
Parent: [Parent page name]
Properties: [count] properties configured
Suggested view: [view type] grouped/sorted by [property]
URL: [Notion URL]

Tip: Open the database in Notion to switch to the suggested [view type] view.
```

3. If creation fails, report the error with common fixes:
   - Parent page not shared with integration → share the page
   - Duplicate database name → the database may already exist
   - API error → retry or check Notion status

## Graceful Degradation

**Notion MCP unavailable**: Stop execution. Display:
"Notion MCP server is not connected. The Notion Command Center requires Notion to function.
See `${CLAUDE_PLUGIN_ROOT}/INSTALL.md` for setup instructions."

**Parent page not found**: Offer to create at workspace root or ask for alternative name.

**Database creation fails**: Report the specific error. Suggest checking that the parent page is shared with the Notion integration.

**Permission errors**: Report that the Notion integration may not have permission to create databases under the specified parent.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/notion:template
/notion:template CRM Contacts --parent="Sales"
/notion:template "Project Tracker"
/notion:template wiki --parent="Team Knowledge"
/notion:template meetings
/notion:template Content Calendar --parent="Marketing"
```
