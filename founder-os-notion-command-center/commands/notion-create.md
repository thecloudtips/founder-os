---
description: Create a Notion page or database from a natural language description
argument-hint: "[description] [--type=page|database] [--parent=NAME]"
allowed-tools: ["Read"]
---

# Notion Create

Create a new Notion page or database from a natural language description. Detect whether the user wants a page or a database, design the appropriate structure, and create it via the Notion MCP server.

## Load Skills

Read the notion-operations skill at `${CLAUDE_PLUGIN_ROOT}/skills/notion-operations/SKILL.md` for Notion MCP tool usage, workspace discovery, page operations, database operations, and content block formatting.

Read the notion-database-design skill at `${CLAUDE_PLUGIN_ROOT}/skills/notion-database-design/SKILL.md` for natural language to schema translation, property type selection, schema design best practices, and pre-built templates.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `[description]` (required) -- the natural language description of what to create. This is all non-flag text. If empty, prompt the user: "What would you like to create in Notion? Describe a page or database." Wait for a response.
- `--type=page|database` (optional) -- explicitly specify the type. If omitted, auto-detect from the description.
- `--parent=NAME` (optional) -- name of the parent page under which to create. If omitted, create at workspace root (pages) or prompt for parent (databases, which require a parent page).

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Step 1: Detect Intent

Determine whether the user wants a page or a database.

**Auto-detection signals:**

Database signals (create a database):
- Words like "tracker", "table", "database", "spreadsheet", "board", "list of [plural noun]", "catalog"
- Descriptions mentioning properties, columns, or fields: "with status, priority, and due date"
- Descriptions implying multiple records: "track my tasks", "manage contacts", "log expenses"

Page signals (create a page):
- Words like "page", "document", "note", "wiki", "article", "brief"
- Descriptions with prose content: "meeting notes for...", "a page about...", "project overview"
- Single-entity descriptions: "a summary of Q4 results", "my weekly plan"

If the `--type` flag is provided, use it directly. If auto-detection is ambiguous, ask the user: "Should I create this as a page (single document) or a database (structured table with multiple entries)?"

## Step 2: Resolve Parent

If `--parent=NAME` is provided:
1. Search Notion for the parent page using `notion-search` with the name.
2. If multiple matches, present a numbered list with parent context and last edited date. Ask the user to pick.
3. If no matches, report: "Could not find a page named '[NAME]'. Would you like to create at the workspace root instead, or provide a different parent name?"

If `--parent` is omitted:
- For pages: create at workspace root.
- For databases: databases require a parent page. Ask: "Which page should this database be created under? (Provide a page name, or say 'workspace root' to use the top level.)" If the user says workspace root, create under a general-purpose parent or at the top level if the API allows.

## Step 3: Create Page

When creating a page:

1. **Extract title** -- identify the page title from the description. If the description is a sentence ("meeting notes for the Q1 kickoff"), derive a concise title ("Q1 Kickoff Meeting Notes").
2. **Extract content** -- identify any initial content the user described. Apply the content block formatting rules from the notion-operations skill to convert text to appropriate Notion block types (paragraphs, headings, lists, to-dos, code blocks).
3. **Create** -- call `notion-create-pages` with the resolved parent, title, and content blocks.
4. **Confirm** -- display the created page:

```
Page created: [Title]
Parent: [Parent name or "Workspace root"]
URL: [Notion URL]
```

## Step 4: Create Database

When creating a database:

1. **Translate schema** -- apply the notion-database-design skill's translation pipeline:
   - Extract entities and attributes from the description.
   - Infer implicit attributes (e.g., Status for trackers).
   - Map each attribute to the appropriate Notion property type.
   - Design default options for Select/Multi-select properties.

2. **Present schema for confirmation** -- show the proposed schema:

```
Database: [Title]
Parent: [Parent page name]

| Property | Type | Options/Config |
|----------|------|----------------|
| [Name] | Title | -- |
| [Status] | Status | To Do, In Progress, Done |
| ... | ... | ... |

Suggested view: [Board/Table/Calendar] grouped/sorted by [property]

Create this database? (yes / no / modify)
```

3. **Handle modification** -- if the user says "modify", ask what to change. Update the schema and re-present.
4. **Create** -- once confirmed, call `notion-create-database` with the parent, title, and full property schema.
5. **Confirm** -- display the created database:

```
Database created: [Title]
Parent: [Parent page name]
Properties: [count] properties configured
Suggested view: [view type]
URL: [Notion URL]
```

## Graceful Degradation

**Notion MCP unavailable**: Stop execution. Display:
"Notion MCP server is not connected. The Notion Command Center requires Notion to function.
Set your `NOTION_API_KEY` environment variable and ensure the Notion integration has access to your workspace pages.
See `${CLAUDE_PLUGIN_ROOT}/INSTALL.md` for setup instructions."

**Parent page not found**: Offer to create at workspace root or ask for alternative name.

**Database creation fails**: Report the error. Common causes: parent page not shared with the integration, property schema validation error. Suggest fixes.

**Permission errors**: Report that the Notion integration may not have access. Suggest sharing the parent page with the integration.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/notion:create A project tracker for our Q2 marketing campaigns with status, priority, owner, and launch date
/notion:create Meeting notes for the weekly standup --parent="Team Wiki"
/notion:create --type=database A CRM for tracking sales leads with name, company, email, status, and deal value
/notion:create --type=page Project brief for the mobile app redesign
/notion:create A simple task list for onboarding new employees --parent="HR"
```
