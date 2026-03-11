---
name: Prompt Management
description: "Manages the team prompt library: storing, retrieving, searching, and organizing reusable prompts. Activates when the user wants to save, find, list, or share prompts, or asks 'show me my saved prompts.' Handles CRUD operations, tagging, versioning, and team sharing workflows."
globs:
  - "commands/prompt-*.md"
---

# Prompt Management

Store, retrieve, search, and track prompts in the Team Prompt Library Notion database. Used by: `/prompt:list` (search and filter), `/prompt:get` (retrieve a single prompt by name), `/prompt:add` (store a new prompt), `/prompt:share` (change visibility to Shared), and `/prompt:optimize` (read prompt content before optimization).

## Purpose and Context

Manage a central library of reusable prompts that a founder and their team can save, discover, and apply across their workflows. Every prompt is stored in Notion with consistent metadata: category, variables, visibility, usage tracking, author, and tags. The Notion database is the single source of truth. All five commands operate against the same database and share the same read/write patterns defined in this skill.

---

## Notion Database

**Database name**: Search for `[FOS] Prompts` first, then fall back to `Founder OS HQ - Prompts`, then `Team Prompt Library - Prompts`.

Use dynamic database discovery: search the workspace for a database titled "[FOS] Prompts". If not found, try "Founder OS HQ - Prompts". If not found, fall back to "Team Prompt Library - Prompts". If none is found, report: "Prompts database not found. Ensure the Founder OS HQ workspace template is installed in your Notion workspace, or run the plugin setup." Do not create the database automatically.

### Schema

| Property | Type | Notes |
|----------|------|-------|
| Name | title | Primary key. Case-insensitive uniqueness enforced on upsert. |
| Content | rich_text | Full prompt text including `{{variable}}` placeholders. |
| Category | select | One of the 6 predefined categories or a custom value. |
| Variables | rich_text | Comma-separated list of detected variable names, e.g. `client_name, tone, deadline`. |
| Visibility | select | `Personal` or `Shared`. Default: `Personal`. |
| Times Used | number | Integer counter. Starts at 0. Incremented on each `/prompt:get`. |
| Author | rich_text | Name or identifier of the person who added the prompt. |
| Tags | multi_select | Freeform tags for cross-category discoverability. |
| Created At | date | ISO 8601 timestamp set on creation. Never overwritten. |
| Last Used | date | ISO 8601 timestamp updated on each `/prompt:get`. |

### Idempotent Upsert Rule

When adding or updating a prompt, search the database for a page whose `Name` matches the target name (case-insensitive). If a match exists, update the existing page rather than creating a new one. If no match exists, create a new page. This prevents duplicate entries when the same prompt is added more than once.

---

## Prompt Categories

Six predefined categories cover the most common use cases. Accept any custom category string when the predefined options do not fit.

| Category | Typical Use Cases |
|----------|--------------------|
| Email Templates | Client outreach, follow-ups, cold intros, status updates |
| Meeting Prompts | Agenda setting, prep briefs, recap writing, talking points |
| Analysis Prompts | Data interpretation, competitor review, financial summary |
| Content Creation | Blog drafts, LinkedIn posts, newsletter sections, social copy |
| Code Assistance | Code review, debugging guidance, documentation generation |
| Research Prompts | Market research, literature summaries, fact-finding briefs |

When the user provides a category that does not match any predefined option exactly, accept it as a custom category and store it verbatim as the `Category` select value. Notion will create a new select option automatically. Do not reject or correct custom categories -- the schema is intentionally open.

If no category is provided, infer the most likely category from the prompt content using the table above. When inference is ambiguous, default to `Research Prompts` and note the assumption.

---

## Variable Syntax and Detection

Prompts support `{{variable}}` placeholders that the user fills in before running the prompt. Use double curly braces with no spaces inside.

### Detection Regex

```
\{\{([a-zA-Z_][a-zA-Z0-9_]*)\}\}
```

This pattern matches `{{variable_name}}` where the variable name starts with a letter or underscore and contains only alphanumeric characters and underscores.

### Detection Rules

- Extract all unique variable names from the prompt's `Content` field at the time the prompt is stored or updated.
- Deduplicate variable names (case-insensitive deduplication -- `{{ClientName}}` and `{{clientname}}` are the same variable).
- Store the deduplicated variable names as a comma-separated string in the `Variables` property.
- If no variables are detected, store an empty string in `Variables`.

### Variable Naming Conventions

Encourage (but do not enforce) these naming conventions when helping users write prompts:

- Use `snake_case` for multi-word names: `{{client_name}}`, `{{tone_of_voice}}`, `{{deadline_date}}`
- Use descriptive names, not positional ones: `{{company_name}}` not `{{var1}}`
- Use `_date` suffix for dates: `{{report_date}}`, `{{meeting_date}}`
- Use `_list` suffix for lists: `{{key_topics_list}}`, `{{attendees_list}}`

When displaying a prompt with variables to the user (e.g., in `/prompt:get`), list the variables separately so the user knows exactly what to fill in before running the prompt.

---

## Visibility Model

Every prompt has one of two visibility states:

| State | Meaning | Who Can See It |
|-------|---------|----------------|
| Personal | Private to the author | Only the user running the command |
| Shared | Available to the whole team | All workspace members |

### Default Behavior

- All new prompts default to `Personal` unless the user specifies otherwise at creation time or uses `/prompt:share`.
- The `/prompt:list` command shows Personal prompts and Shared prompts together, since Claude Code operates in a single-user context. Make no attempt to filter by author identity.
- The `/prompt:share` command changes `Visibility` from `Personal` to `Shared`. Never change `Shared` back to `Personal` without explicit user instruction.

---

## Prompt Naming Conventions

Prompt names must be unique (enforced by the idempotent upsert rule). Encourage these naming patterns when the user does not supply a name:

- Format: `[Audience/Context] [Action] [Object]`
- Examples: `Client Intro Email`, `Weekly Status Update`, `Competitor Analysis Brief`, `Code Review Checklist`
- Keep names under 60 characters for readability in list views.
- Use Title Case for all prompt names.
- Avoid generic names like `Email` or `My Prompt` -- they are unsearchable and collision-prone.

When the user adds a prompt without providing a name, infer a name from the first sentence or purpose of the prompt content. Confirm the inferred name before saving.

---

## Search and Filter Logic (for /prompt:list)

The `/prompt:list` command searches and filters the Notion database. Apply filters in this order:

### 1. Category Filter

If `--category` is specified, return only prompts where `Category` matches the specified value (case-insensitive). Accept partial matches: `--category=email` matches `Email Templates`.

### 2. Visibility Filter

If `--shared` is specified, return only prompts where `Visibility` is `Shared`.
If `--personal` is specified, return only prompts where `Visibility` is `Personal`.
If neither flag is provided, return all prompts regardless of visibility.

### 3. Tag Filter

If `--tag` is specified, return only prompts where `Tags` contains the specified tag (case-insensitive).

### 4. Text Search

If a search query is provided, filter results to prompts where the `Name`, `Tags`, or `Content` contains the query string. Apply text search after category, visibility, and tag filters.

### 5. Sort Order

Default sort: `Times Used` descending (most-used prompts first). This surfaces the most valuable prompts at the top.

When `--recent` is specified, sort by `Created At` descending (newest first) instead.

### 6. Limit

Apply a default limit of 20 results unless `--limit=N` is specified. Never return more than 50 results in a single list response.

### Display Format for List Results

Show results as a numbered list with this information per prompt:

```
N. [Name] — [Category]
   Variables: {{var1}}, {{var2}}  |  Used: X times  |  Visibility: Personal/Shared
   Tags: tag1, tag2
```

If no results match the filters, report the active filters and suggest broader search terms or removing a filter.

---

## Usage Tracking

Track prompt usage to surface the most valuable prompts and provide usage analytics.

### On /prompt:get

Every time a prompt is retrieved via `/prompt:get`:
1. Increment the `Times Used` counter by 1.
2. Set `Last Used` to the current date (ISO 8601, date-only: `YYYY-MM-DD`).

Perform these updates as part of the same Notion page update call that retrieves the prompt content. Do not skip tracking even if the user is just "browsing" -- a retrieval is a retrieval.

### On /prompt:list

Do not increment `Times Used` when listing prompts. List is a browse operation, not a usage event.

### On /prompt:add or /prompt:share

Do not modify `Times Used` or `Last Used` on add or share operations.

---

## Edge Cases and Guardrails

### Duplicate Name Handling

If a user attempts to add a prompt with a name that already exists (case-insensitive match), do not silently overwrite. Present the existing prompt and ask whether to overwrite (update content, category, and tags) or save under a different name. Never create a second entry with an identical name.

### Empty or Minimal Prompts

Reject prompts with fewer than 10 characters of content. Prompts this short are likely errors or placeholders. Ask the user to provide the full prompt text.

### Category Not Found

If the user filters by `--category=X` and no prompts exist in that category, report the empty result explicitly: "No prompts found in category 'X'. Available categories: [list current categories from DB]." Fetch the current category list from the database's select property options rather than hardcoding the predefined list -- custom categories may have been added.

### Variable Extraction on Update

When a prompt's `Content` is updated, re-run variable extraction and overwrite the `Variables` field with the new result. Do not append to the existing Variables list.

### Large Content

Notion's `rich_text` property supports up to 2000 characters per block. If a prompt's `Content` exceeds 2000 characters, split the content across multiple rich_text blocks in the same property, or warn the user that the prompt may be truncated and suggest shortening it or storing the full version as a Notion page child block.

### Graceful Degradation

If the Notion MCP is unavailable, report the error clearly and fall back to displaying prompt output in chat only (for `/prompt:get`) or listing nothing (for `/prompt:list`). Never invent prompt content or fabricate search results when the database cannot be reached.
