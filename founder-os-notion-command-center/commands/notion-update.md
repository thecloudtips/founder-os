---
description: Update a Notion page's properties or append content using natural language
argument-hint: "[page] [changes] [--append]"
allowed-tools: ["Read"]
---

# Notion Update

Find a Notion page by title or URL, then update its properties or append content based on a natural language description of changes. Confirm before executing.

## Load Skills

Read the notion-operations skill at `${CLAUDE_PLUGIN_ROOT}/skills/notion-operations/SKILL.md` for Notion MCP tool usage, workspace discovery, page operations (reading, updating), property value mapping, and content block formatting.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `[page]` (required) -- the page title or Notion URL to update. If the input contains a Notion URL (starts with `https://www.notion.so/` or `https://notion.so/`), use it directly. Otherwise, treat as a title search query.
- `[changes]` (required) -- the natural language description of what to change. Everything after the page identifier. If no changes are described, prompt the user: "What changes would you like to make to this page?" Wait for a response.
- `--append` (optional flag) -- append content to the page body instead of updating properties. Without this flag, changes are interpreted as property updates by default.

**Argument parsing heuristic**: The page identifier is the first quoted string, or the first recognizable Notion URL, or the text before common change verbs ("set", "change", "update", "mark", "add"). Everything after is the change description.

Examples:
- `"Project Alpha" set status to Done` → page="Project Alpha", changes="set status to Done"
- `https://notion.so/abc123 add a note about the delay` → page=URL, changes="add a note about the delay"
- `Weekly Report mark as complete` → page="Weekly Report", changes="mark as complete"

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Step 1: Find the Page

1. **URL provided**: Call `notion-fetch` with the URL directly. Skip to Step 2.
2. **Title search**: Call `notion-search` with the page title.
3. **Single match**: Proceed to Step 2.
4. **Multiple matches**: Present a disambiguated list following the notion-operations skill's disambiguation rules:

```
Found [N] pages matching "[title]":
1. [Title] (under [Parent], edited [date])
2. [Title] (under [Parent], edited [date])
3. [Title] (under [Parent], edited [date])

Which page? (Enter number)
```

Wait for the user's selection.

5. **No matches**: Report: "Could not find a page matching '[title]'. Check the spelling or provide a direct Notion URL." Suggest broader search terms.

## Step 2: Read Current State

1. Call `notion-fetch` to read the full page.
2. Extract current properties (name, type, current value for each).
3. Extract current body content (summarize structure: number of blocks, headings, lists).
4. Store this state for the before/after comparison.

## Step 3: Parse Changes

Determine what the user wants to change and map to API operations.

### Property Updates (default mode, no --append flag)

Apply the property value mapping from the notion-operations skill:

1. **Identify target properties** -- match the user's language to existing page properties:
   - "set status to Done" → Status property
   - "change priority to High" → Priority property (Select)
   - "update the date to next Friday" → Date property
   - "assign to Sarah" → People property
   - "tag it as Marketing" → Multi-select property
   - "set the amount to 5000" → Number property
   - "mark as checked/complete/done" → Checkbox property or Status property

2. **Validate** -- check that the target property exists on the page and the value is compatible. Consult `${CLAUDE_PLUGIN_ROOT}/skills/notion-operations/references/workspace-patterns.md` for the full property value mapping table.

3. **Handle mismatches**:
   - Property not found: List available properties and suggest the closest match.
   - Value incompatible: Explain what values the property accepts.
   - Ambiguous target: Ask which property the user means.

### Content Append (--append flag)

1. Parse the content from the changes description.
2. Apply content block formatting rules from the notion-operations skill.
3. Content will be appended after existing page content with a divider separator.

## Step 4: Confirm Changes

Present a summary of planned changes before executing:

### For property updates:

```
Updating: [Page Title]
URL: [Notion URL]

Changes:
| Property | Current | New |
|----------|---------|-----|
| Status | In Progress | Done |
| Priority | Medium | High |
| Due Date | (empty) | 2026-03-15 |

Apply these changes? (yes / no)
```

### For content append:

```
Appending to: [Page Title]
URL: [Notion URL]

New content to add:
---
[formatted content preview]
---

This will be added after the existing [N] blocks on the page.

Append this content? (yes / no)
```

Wait for the user's confirmation. If the user says "no", ask what they'd like to change.

## Step 5: Execute and Report

1. **Execute** -- call `notion-update-page` with the changes.
2. **Report** -- show the before/after summary:

### For property updates:

```
Updated: [Page Title]

| Property | Before | After |
|----------|--------|-------|
| Status | In Progress | Done |
| Priority | Medium | High |

URL: [Notion URL]
```

### For content append:

```
Content appended to: [Page Title]
Added: [count] blocks ([brief description])
URL: [Notion URL]
```

## Graceful Degradation

**Notion MCP unavailable**: Stop execution. Display:
"Notion MCP server is not connected. The Notion Command Center requires Notion to function.
See `${CLAUDE_PLUGIN_ROOT}/INSTALL.md` for setup instructions."

**Page not found**: Suggest alternative search terms or ask for a direct URL.

**Update fails**: Report the error. Common causes:
- Property is read-only (Created Time, Created By, Last Edited)
- Value format doesn't match property type
- Page is locked or archived
- Integration doesn't have write access

**Permission errors**: Report that the Notion integration may not have write access to this page. Suggest checking the integration's page permissions.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/notion:update "Project Alpha" set status to Done
/notion:update "Q2 Marketing Plan" change priority to High and assign to Sarah
/notion:update https://notion.so/abc123 mark as complete
/notion:update "Weekly Report" update the due date to next Friday
/notion:update "Team Meeting Notes" --append Add action item: Review budget proposal by EOW
/notion:update "Client Brief" --append ## Next Steps\n- Schedule kickoff call\n- Send NDA
```
