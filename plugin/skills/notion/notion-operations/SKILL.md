---
name: Notion Operations
description: "Handles Notion workspace operations: page creation, database queries, content updates, and workspace search. Activates when the user wants to create, search, query, update, or browse anything in Notion — even casual 'find that page in Notion' or 'add this to my database.' Covers MCP tool usage, workspace discovery, and batch operations."
version: 1.0.0
---

# Notion Operations

Interact with Notion workspaces through the Notion MCP server. This skill provides the operational knowledge for translating natural language requests into Notion API calls via MCP tools, covering page creation, database operations, content updates, and workspace search.

Referenced by all four commands: `/founder-os:notion:create`, `/founder-os:notion:query`, `/founder-os:notion:update`, `/founder-os:notion:template`.

## Notion MCP Tools Reference

The Notion MCP server exposes these tools. Use them as the sole interface to Notion — never construct raw API calls.

| Tool | Purpose | Key Parameters |
|------|---------|----------------|
| `notion-search` | Find pages and databases by title/content | `query` (string) |
| `notion-fetch` | Read a page or database by URL or ID | `url` (Notion URL or page ID) |
| `notion-create-pages` | Create one or more pages | `pages` (array of page objects) |
| `notion-update-page` | Update page properties or content | `pageId`, `properties`, `content` |
| `notion-create-database` | Create a database with schema | `parent`, `title`, `properties` |
| `notion-move-pages` | Move pages to a different parent | `pageIds`, `newParentId` |
| `notion-duplicate-page` | Duplicate an existing page | `pageId` |

## Workspace Discovery

Before performing operations, understand the workspace structure. This is critical when the user references pages by name rather than URL.

**Discovery pipeline:**

1. **Search by name** — call `notion-search` with the page/database name the user provides.
2. **Disambiguate** — if multiple results match, present the user with a numbered list showing title, parent location, and last edited date. Ask them to pick.
3. **Fetch details** — once identified, call `notion-fetch` to read the full page content or database schema.

**Disambiguation rules:**
- Present at most 5 candidates.
- Include the parent page/database name for context (e.g., "Meeting Notes" under "Q1 Planning" vs. "Meeting Notes" under "Team Wiki").
- If only one result matches, proceed without asking.
- If zero results match, suggest alternative search terms based on partial matches.

## Page Operations

### Creating Pages

Translate the user's natural language description into a page creation call.

**Creation pipeline:**

1. **Determine parent** — if `--parent=NAME` is provided, search for and resolve the parent page. If omitted, create at workspace root.
2. **Parse content** — extract the page title and body content from the user's description.
3. **Format content blocks** — convert plain text into Notion block types:
   - Paragraphs → `paragraph` blocks
   - Bullet lists → `bulleted_list_item` blocks
   - Numbered lists → `numbered_list_item` blocks
   - Headings → `heading_1`, `heading_2`, `heading_3` blocks
   - Code blocks → `code` blocks
   - Checkboxes/to-dos → `to_do` blocks
4. **Create** — call `notion-create-pages` with the parent, title, and content blocks.
5. **Confirm** — report the created page title and URL.

### Reading Pages

Fetch and present page content in a readable format.

1. Call `notion-fetch` with the page URL or ID.
2. Extract the title from the `Title` property.
3. Extract body content, preserving block structure (headings, lists, paragraphs).
4. For database entries, extract all properties as key-value pairs above the body content.

### Updating Pages

Map natural language change descriptions to property updates or content modifications.

**Update pipeline:**

1. **Find the page** — search by title or accept a URL. Disambiguate if needed.
2. **Fetch current state** — read the page to understand existing properties and content.
3. **Parse changes** — determine what the user wants to change:
   - Property updates: "set status to Done", "change priority to High", "update the date to next Friday"
   - Content append: "add a section about X", "append these notes"
   - Content replacement: "change the title to Y", "update the description"
4. **Map to API calls** — translate changes into `notion-update-page` parameters.
5. **Confirm before executing** — show a summary of planned changes. Proceed only after user confirms.
6. **Execute and report** — apply changes, then show a before/after summary.

**Property value mapping:**
- "Done", "complete", "finished" → Status property: "Done"
- "High", "urgent", "important" → Select property: "High"
- "next Friday", "March 15" → Date property: parse to ISO date
- "yes", "true", "checked" → Checkbox property: true
- "tag it as X" → Multi-select property: add "X"

Consult `${CLAUDE_PLUGIN_ROOT}/skills/notion/notion-operations/references/workspace-patterns.md` for the full property value mapping table and advanced update patterns.

## Database Operations

### Creating Databases

Database creation is handled jointly with the `notion-database-design` skill (see `${CLAUDE_PLUGIN_ROOT}/skills/notion/notion-database-design/SKILL.md`). This skill provides the operational execution; the design skill provides schema translation.

1. Resolve the parent page (databases must have a parent page).
2. Receive the property schema from the design skill or from a template.
3. Call `notion-create-database` with parent, title, and property definitions.
4. Confirm creation with the database title, URL, and property summary.

### Querying Databases

Translate natural language questions into database queries with filters and sorts.

**Query pipeline:**

1. **Identify the database** — search by name using `notion-search`, or accept `--db=NAME` flag.
2. **Fetch schema** — read the database to discover its properties (names, types, options).
3. **Translate question to filter** — map the user's natural language to filter conditions:
   - "overdue tasks" → `Due Date` before today AND `Status` is not "Done"
   - "high priority items" → `Priority` equals "High"
   - "tasks assigned to me" → `Assignee` contains current user
   - "created this week" → `Created` after Monday of current week
4. **Apply sort** — infer sort order from the question:
   - "latest" / "newest" / "recent" → sort by date descending
   - "oldest" / "first" → sort by date ascending
   - "highest priority" → sort by priority descending
   - Default: sort by last edited descending
5. **Execute query** — use `notion-fetch` on the database with filter/sort parameters.
6. **Format results** — present as formatted cards with key properties.

**Result card format:**
```
### [Title]
- Status: [value]
- Priority: [value]
- Due: [date]
- [other relevant properties]
→ [Notion URL]
```

Limit results to `--limit=N` (default 10). If more results exist, note the total count.

Consult `${CLAUDE_PLUGIN_ROOT}/skills/notion/notion-operations/references/workspace-patterns.md` for NL-to-filter translation examples and complex filter patterns.

## Search Strategies

Notion search has specific behaviors that affect how queries should be constructed.

**Key behaviors:**
- Search is **title-weighted** — page titles match more strongly than body content.
- Boolean operators (`AND`, `OR`, `NOT`) are **not supported** — use simple keyword phrases.
- Short queries (2-4 words) perform better than long phrases.
- Database entries and pages both appear in results.

**Search approach by intent:**

| User intent | Strategy |
|------------|----------|
| Find a specific page | Search by exact title keywords |
| Browse a topic | Search by topic keyword, scan results |
| Query database records | First find the database, then query with filters |
| Explore workspace | Search with broad terms, present top results as an overview |

**Empty result handling:**
1. Retry with a shorter query (drop adjectives and qualifiers).
2. Try common synonyms for the key terms.
3. If still empty, report "No matching pages found" and suggest the user check that the content has been shared with the Notion integration.

## Content Block Formatting

When creating or appending content, convert user text to appropriate Notion block types.

**Detection rules:**
- Lines starting with `- ` or `* ` → `bulleted_list_item`
- Lines starting with `1. `, `2. ` → `numbered_list_item`
- Lines starting with `[ ] ` or `[x] ` → `to_do`
- Lines starting with `# ` → `heading_1`, `## ` → `heading_2`, `### ` → `heading_3`
- Lines wrapped in triple backticks → `code`
- Lines starting with `> ` → `quote`
- Horizontal rules (`---`) → `divider`
- All other text → `paragraph`

Preserve inline formatting: **bold**, *italic*, `code`, ~~strikethrough~~, [links](url).

## Graceful Degradation

- **Notion MCP unavailable**: Report clearly that the Notion connection is not available. Suggest checking that the `NOTION_API_KEY` is set and the MCP server is running. Do not attempt any Notion operations.
- **Page not found**: After search returns empty, suggest the user verify the page name or provide a direct URL.
- **Permission errors**: Report that the integration may not have access to the requested page. Suggest sharing the page with the Notion integration.
- **Rate limits**: If a rate-limit error occurs, wait briefly and retry once. If it persists, report the issue and suggest trying again in a moment.

## Additional Resources

### Reference Files

For detailed patterns and advanced techniques, consult:
- **`${CLAUDE_PLUGIN_ROOT}/skills/notion/notion-operations/references/workspace-patterns.md`** — NL-to-filter translation examples, property value mapping tables, complex query patterns, and multi-block content construction examples
