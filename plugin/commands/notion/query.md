---
description: Search Notion and query databases using natural language questions
argument-hint: "[question] [--db=NAME] [--limit=N]"
allowed-tools: ["Read"]
---

# Notion Query

Search Notion pages and query databases using natural language. Translate questions into search queries or database filters, execute via Notion MCP, and present formatted results.

## Load Skills

Read the notion-operations skill at `${CLAUDE_PLUGIN_ROOT}/skills/notion/notion-operations/SKILL.md` for Notion MCP tool usage, workspace discovery, search strategies, and database querying with NL-to-filter translation.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `[question]` (required) -- the natural language question or search query. This is all non-flag text. If empty, prompt the user: "What would you like to search for in Notion?" Wait for a response.
- `--db=NAME` (optional) -- target a specific database by name. When provided, the query is treated as a database filter/sort operation rather than a general search.
- `--limit=N` (optional) -- maximum results to display. Default: `10`. Accepts 1-50. Values outside range are clamped silently.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Step 1: Determine Query Type

Classify the question into one of three query modes:

**Database query** (when `--db` is provided OR question targets a known database):
- The user specified `--db=NAME` explicitly.
- The question references a specific database: "show me tasks from Project Tracker", "what's in the CRM", "query the content calendar".
- Signals: "show me", "list", "filter", "find in [database]", "what tasks", "which items".

**Page search** (when looking for specific documents):
- The user wants to find a specific page or document.
- Signals: "find the page about", "where is", "search for", "look up".

**Workspace browse** (when exploring broadly):
- The user wants an overview of what exists.
- Signals: "what pages do I have", "show me everything about", "browse", "what's in my workspace".

## Step 2: Execute Query

### Database Query Mode

1. **Find the database** -- if `--db=NAME` is provided, search Notion for a database with that name. If the question mentions a database name without `--db`, extract and search for it.
2. **Fetch schema** -- read the database to discover its properties (names, types, available options).
3. **Translate question to filter** -- apply the NL-to-filter translation rules from the notion-operations skill:
   - "overdue tasks" → Due Date before today AND Status not "Done"
   - "high priority" → Priority equals "High"
   - "assigned to Sarah" → Assignee contains "Sarah"
   - "created this week" → Created after start of current week
   - Consult `${CLAUDE_PLUGIN_ROOT}/skills/notion/notion-operations/references/workspace-patterns.md` for the full translation table.
4. **Apply sort** -- infer sort order from the question (latest → date desc, highest priority → priority desc, default → last edited desc).
5. **Execute** -- query the database via Notion MCP with filters and sort.
6. **Cap results** -- limit to `--limit` (default 10).

### Page Search Mode

1. **Extract search terms** -- pull key terms from the question. Strip question words and filler.
2. **Search Notion** -- call `notion-search` with the extracted terms.
3. **If sparse results** -- retry with a shorter/broader query.
4. **Cap results** -- limit to `--limit` (default 10).

### Workspace Browse Mode

1. **Search with broad terms** -- extract the topic from the question and search.
2. **Group results** -- if results span multiple databases and pages, group them by type.
3. **Cap results** -- limit to `--limit` (default 10).

## Step 3: Format Results

### Database Query Results

Present as formatted cards:

```
## Query Results: [Database Name]

Showing [N] of [total] results · Filtered by: [filter description] · Sorted by: [sort description]

---

### 1. [Title]
- Status: [value]
- Priority: [value]
- Due: [date]
- [other relevant properties]
→ [Notion URL]

### 2. [Title]
...

---
*[total] total results · Queried [database name]*
```

Only show properties that have values (skip empty/null properties). Show the most relevant properties first (Status, Priority, dates, assignees).

### Page Search Results

Present as a ranked list:

```
## Search Results

Found [N] pages matching "[search terms]"

---

### 1. [Page Title]
[150-char preview of page content]
Last edited: [date] · Parent: [parent name]
→ [Notion URL]

### 2. [Page Title]
...

---
*[N] results found*
```

### Aggregation Results

When the question asks "how many", "total", or "count":

```
## [Database Name]: [Count Description]

**[Count]** [items matching description]

Top [5] by [sort criteria]:
1. [Title] - [key property]
2. ...

---
*Queried [database name] · [total] entries checked*
```

## Step 4: Handle Empty Results

If no results are found:

1. Report: "No results found for '[question]'."
2. If a database was queried, show the filter that was applied so the user can adjust.
3. Suggest alternative queries:
   - Broader terms (drop adjectives/qualifiers)
   - Check if the database name is correct
   - Verify the Notion integration has access to the relevant pages
4. If the user might be looking for content in a different database, suggest: "Try specifying a database with --db=NAME."

## Graceful Degradation

**Notion MCP unavailable**: Stop execution. Display:
"Notion MCP server is not connected. The Notion Command Center requires Notion to function.
See `${CLAUDE_PLUGIN_ROOT}/INSTALL.md` for setup instructions."

**Database not found**: When `--db=NAME` finds no match, list available databases the integration can access and suggest the closest match.

**Ambiguous database name**: If multiple databases match `--db=NAME`, present a numbered list and ask the user to pick.

**Permission errors**: Report that the Notion integration may not have access to the requested content.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/founder-os:notion:query What are my overdue tasks? --db="Project Tracker"
/founder-os:notion:query Find the onboarding guide
/founder-os:notion:query Show me all high-priority items assigned to Sarah --db="Tasks"
/founder-os:notion:query How many open deals do we have? --db="CRM"
/founder-os:notion:query What pages do I have about marketing strategy?
/founder-os:notion:query List content published this month --db="Content Calendar" --limit=20
```
