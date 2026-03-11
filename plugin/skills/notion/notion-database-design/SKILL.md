---
name: Notion Database Design
description: "Designs and creates Notion databases from natural language descriptions with typed properties. Activates when the user wants to build a database, design a schema, set up a tracker, deploy a template, or asks 'create a table in Notion for [thing].' Includes 5 pre-built business templates and smart property type inference."
version: 1.0.0
---

# Notion Database Design

Translate natural language descriptions into well-structured Notion database schemas. This skill handles property type selection, schema design best practices, and deployment of pre-built business templates. Used jointly with the `notion-operations` skill, which handles the actual API calls.

Referenced by `/founder-os:notion:create` (when creating databases) and `/founder-os:notion:template`.

## Natural Language to Schema Translation

Parse the user's description to identify entities, attributes, and relationships, then map each attribute to the appropriate Notion property type.

**Translation pipeline:**

1. **Extract entities** — identify what the database tracks (tasks, contacts, projects, content, etc.).
2. **Extract attributes** — identify mentioned properties from the description. Look for nouns that describe fields: "name", "status", "due date", "priority", "email", "category".
3. **Infer implicit attributes** — add standard properties that the user likely expects even if not explicitly stated:
   - Every tracker gets a Status property (unless the user explicitly excludes it)
   - Date-oriented entities get a Date property
   - People-oriented entities get a Name (title) property
4. **Map types** — assign each attribute the best Notion property type based on its semantics.
5. **Design options** — for Select/Multi-select properties, propose 3-5 default options based on the entity type.
6. **Present schema** — show the user the proposed schema as a formatted table before creating.

## Property Type Selection

Choose the most appropriate property type for each attribute. Default to the simplest type that fits.

| Semantic pattern | Property type | Examples |
|-----------------|---------------|----------|
| Primary identifier | Title | Name, Task, Item, Subject |
| Long text, notes | Rich text | Description, Notes, Details |
| Workflow state | Status | Status (To Do / In Progress / Done) |
| Single category | Select | Priority, Type, Category, Phase |
| Multiple labels | Multi-select | Tags, Skills, Departments |
| Calendar/deadline | Date | Due Date, Start Date, Created |
| True/false toggle | Checkbox | Done, Approved, Published, Active |
| Web address | URL | Website, Link, Resource URL |
| Email address | Email | Contact Email, Email |
| Phone | Phone | Phone Number, Mobile |
| Quantity/amount | Number | Amount, Hours, Score, Count |
| Person assignment | People | Assignee, Owner, Reviewer |
| File attachment | Files | Attachments, Documents, Images |
| Connected record | Relation | Project, Client, Parent Task |
| Computed value | Formula | Full Name (first + last), Days Until Due |
| Aggregation | Rollup | Task Count, Total Hours |

Consult `${CLAUDE_PLUGIN_ROOT}/skills/notion/notion-database-design/references/property-types.md` for complete property type specifications, configuration options, and advanced patterns.

## Schema Design Best Practices

### Naming Conventions

- Use **Title Case** for property names: "Due Date" not "due_date" or "due date".
- Keep names short and descriptive: "Priority" not "Task Priority Level".
- Use standard names for common concepts: "Status" (not "State"), "Due Date" (not "Deadline"), "Assignee" (not "Assigned To").
- Avoid abbreviations unless universally understood: "URL" is fine, "Desc" is not.

### Property Ordering

Present properties in this order in the schema:

1. **Title** (always first — Notion requires exactly one Title property)
2. **Status** (if applicable)
3. **Key categorization** (Select/Multi-select: Priority, Type, Tags)
4. **Dates** (Due Date, Start Date)
5. **People** (Assignee, Owner)
6. **Numbers** (Amount, Score)
7. **Text** (Description, Notes)
8. **References** (URL, Email, Phone, Relations)
9. **Toggles** (Checkboxes at the end)

### Required vs Optional

- Title property is always required (Notion enforces this).
- Status property: include unless explicitly excluded.
- All other properties are optional — include only what the user described or what is standard for the entity type.
- Do not bloat schemas. A good database has 5-10 properties. Exceeding 15 suggests the schema should be split into related databases.

### Default Views

When describing the schema to the user, suggest a default view:

| Entity type | Suggested view |
|------------|----------------|
| Tasks/Projects | Board grouped by Status |
| Contacts/CRM | Table sorted by Name |
| Content/Calendar | Calendar by Date |
| Meetings/Events | Calendar by Date |
| Knowledge/Wiki | Table sorted by Last Edited |

## Pre-Built Templates

Five business-essential templates are available for instant deployment via `/founder-os:notion:template`. Each template defines a complete schema with property types, options, and suggested views.

| Template | Entity | Properties | View |
|----------|--------|------------|------|
| CRM Contacts | Contact records | 12 props | Table by Name |
| Project Tracker | Project tasks | 10 props | Board by Status |
| Content Calendar | Content pieces | 11 props | Calendar by Publish Date |
| Meeting Notes | Meeting records | 8 props | Table by Date |
| Knowledge Wiki | Knowledge articles | 9 props | Table by Last Edited |

When the user runs `/founder-os:notion:template` without a name, list all 5 templates with a one-line description. When a template name is specified, load the full schema definition and create the database.

Consult `${CLAUDE_PLUGIN_ROOT}/skills/notion/notion-database-design/references/templates.md` for the complete property definitions, default options, and view configurations for each template.

## Schema Confirmation Protocol

Before creating any database, present the schema to the user for approval.

**Confirmation format:**

```
📊 Database: [Title]
Parent: [Parent page name or "Workspace root"]

| Property | Type | Options/Config |
|----------|------|----------------|
| Name | Title | — |
| Status | Status | To Do, In Progress, Done |
| Priority | Select | High, Medium, Low |
| Due Date | Date | — |
| Assignee | People | — |
| ... | ... | ... |

Suggested view: [Board/Table/Calendar] grouped/sorted by [property]

Create this database? (yes/no/modify)
```

If the user says "modify", ask which properties to add, remove, or change. Update the schema and re-present.

## Edge Cases

- **User describes a simple list**: Create a minimal database with Title + one relevant property (Status or Checkbox). Do not over-engineer.
- **User wants a spreadsheet**: Notion databases are not spreadsheets. If the user describes a data table with purely numeric columns, create it but note that Notion is optimized for structured records, not raw data grids.
- **Duplicate property names**: Notion doesn't allow duplicate property names. If the user's description implies two properties with the same name, disambiguate: "Start Date" and "End Date" rather than two "Date" properties.
- **Relation requests**: When the user wants to link databases, both databases must exist. Create the primary database first, then create or link the related database. Note this to the user.

## Additional Resources

### Reference Files

For detailed property specifications and template schemas, consult:
- **`${CLAUDE_PLUGIN_ROOT}/skills/notion/notion-database-design/references/property-types.md`** — Complete Notion property type reference with configuration options, format specifications, and advanced patterns
- **`${CLAUDE_PLUGIN_ROOT}/skills/notion/notion-database-design/references/templates.md`** — Full schema definitions for all 5 business templates with property details, default options, and view configurations
