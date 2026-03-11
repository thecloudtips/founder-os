# Notion Workspace Patterns

Detailed reference for natural language to Notion API translation, property mapping, filter construction, and content block patterns.

---

## Natural Language to Filter Translation

### Common Patterns

| User says | Property | Operator | Value |
|-----------|----------|----------|-------|
| "overdue tasks" | Due Date | before | today |
| "tasks due this week" | Due Date | between | start_of_week, end_of_week |
| "tasks due tomorrow" | Due Date | equals | tomorrow's date |
| "completed items" | Status | equals | "Done" or "Complete" |
| "in progress" | Status | equals | "In Progress" |
| "not started" | Status | equals | "Not Started" or "To Do" |
| "high priority" | Priority | equals | "High" or "P1" |
| "assigned to [name]" | Assignee/People | contains | person name |
| "tagged with [tag]" | Tags/Multi-select | contains | tag value |
| "created today" | Created time | equals | today |
| "created this month" | Created time | between | start_of_month, today |
| "updated recently" | Last edited | after | 7 days ago |
| "items with [keyword]" | Title/Rich text | contains | keyword |

### Compound Filters

Natural language often implies multiple conditions. Combine with AND logic by default.

**"Show me overdue high-priority tasks":**
```
filters:
  AND:
    - property: "Due Date", before: today
    - property: "Status", not_equals: "Done"
    - property: "Priority", equals: "High"
```

**"Tasks assigned to Sarah that are in progress":**
```
filters:
  AND:
    - property: "Assignee", contains: "Sarah"
    - property: "Status", equals: "In Progress"
```

**"Items tagged 'Marketing' or 'Sales'":**
```
filters:
  OR:
    - property: "Tags", contains: "Marketing"
    - property: "Tags", contains: "Sales"
```

### Sort Inference

| User says | Sort property | Direction |
|-----------|--------------|-----------|
| "latest", "newest", "most recent" | Last edited time | Descending |
| "oldest", "earliest" | Created time | Ascending |
| "due soonest", "upcoming" | Due Date | Ascending |
| "highest priority" | Priority | Descending |
| "alphabetical", "A-Z" | Title | Ascending |
| (no sort specified) | Last edited time | Descending |

---

## Property Value Mapping

### Status Property

Map natural language to standard Notion status values. Notion's Status property uses three groups: To Do, In Progress, Done.

| User says | Maps to |
|-----------|---------|
| "done", "complete", "finished", "closed" | Done |
| "in progress", "working on it", "started", "active" | In Progress |
| "to do", "not started", "pending", "open", "new" | Not started |
| "blocked", "on hold", "waiting" | In Progress (with note) |

### Select/Multi-Select Properties

When the user specifies a value for a select property, match against existing options:

1. **Exact match** — use the option directly.
2. **Case-insensitive match** — "high" matches "High".
3. **Partial match** — "mktg" could match "Marketing". Confirm with user.
4. **No match** — inform the user that the option doesn't exist. List available options. Ask whether to create a new option or pick an existing one.

### Date Properties

Parse relative and absolute date references:

| User says | Parsed date |
|-----------|-------------|
| "today" | Current date |
| "tomorrow" | Current date + 1 |
| "yesterday" | Current date - 1 |
| "next Monday" | Next occurrence of Monday |
| "next week" | Monday of next week |
| "end of week", "Friday" | Coming Friday |
| "end of month" | Last day of current month |
| "March 15" | March 15 of current/next year |
| "in 3 days" | Current date + 3 |
| "2 weeks from now" | Current date + 14 |

### People Properties

When the user references a person:

1. Search for the user by name in Notion.
2. If multiple matches, disambiguate.
3. If no match, report that the person wasn't found in the workspace.

### Number Properties

Accept numeric values directly. Handle common formats:
- "5" → 5
- "$1,500" → 1500 (strip currency symbol and commas)
- "25%" → 25 (store as number, note if property expects percentage)

---

## Content Block Construction

### Multi-Block Content Examples

**User says:** "Add a project overview section with status, timeline, and team"

Translate to:
```
blocks:
  - heading_2: "Project Overview"
  - heading_3: "Status"
  - paragraph: "[User to fill in current status]"
  - heading_3: "Timeline"
  - paragraph: "[User to fill in timeline details]"
  - heading_3: "Team"
  - bulleted_list_item: "[Team member 1]"
  - bulleted_list_item: "[Team member 2]"
```

**User says:** "Create a meeting notes page with date, attendees, agenda, and action items sections"

Translate to:
```
blocks:
  - heading_2: "Meeting Details"
  - paragraph: "Date: [today's date]"
  - paragraph: "Attendees: [to be filled]"
  - divider
  - heading_2: "Agenda"
  - numbered_list_item: "[Agenda item 1]"
  - divider
  - heading_2: "Discussion Notes"
  - paragraph: "[Notes]"
  - divider
  - heading_2: "Action Items"
  - to_do: "[Action item 1]"
```

### Appending vs Replacing Content

**Append mode** (`--append` flag):
- Fetch the existing page content.
- Add a divider block after existing content.
- Append the new blocks after the divider.
- Never modify or delete existing content.

**Replace mode** (default for property updates):
- Fetch the current property values.
- Apply only the changed properties.
- Leave unchanged properties intact.
- Report what was changed in the before/after summary.

---

## Complex Query Patterns

### Aggregation Questions

When the user asks "how many", "total", or "count" questions:

1. Query the database without a result limit.
2. Count the matching entries.
3. Report the count along with a sample of results.

Example: "How many tasks are overdue?"
- Filter: Due Date before today AND Status not "Done"
- Report: "Found 12 overdue tasks. Here are the top 5 by priority: [list]"

### Comparison Questions

When the user asks "which has the most" or "compare" questions:

1. Query without filters to get all entries.
2. Group by the relevant property.
3. Count per group.
4. Present as a summary table.

Example: "Which project has the most open tasks?"
- Query all tasks where Status is not "Done"
- Group by Project property
- Count per project
- Report: "Project Alpha: 15, Project Beta: 8, Project Gamma: 3"

### Timeline Questions

When the user asks about ranges or periods:

1. Set date filters for the specified period.
2. Sort by date ascending to show chronological order.
3. Present with date context.

Example: "What was added last week?"
- Filter: Created time between last Monday and last Sunday
- Sort: Created time ascending
- Report: "7 items were created last week: [chronological list]"

---

## Error Recovery Patterns

### Ambiguous Page Names

When `notion-search` returns multiple pages with similar titles:

```
Found 3 pages matching "Meeting Notes":
1. Meeting Notes (under Team Wiki, edited 2 days ago)
2. Meeting Notes (under Q1 Planning, edited 2 weeks ago)
3. Meeting Notes - Template (under Templates, edited 3 months ago)

Which one? (Enter number or provide more context)
```

### Property Type Mismatches

When the user tries to set a value incompatible with the property type:

- "Set the date to high" → Report: "The 'Due Date' property expects a date value. Did you mean to update the 'Priority' property instead?"
- "Set status to 42" → Report: "'Status' accepts values like 'To Do', 'In Progress', or 'Done'. Which would you like?"

### Missing Properties

When the user references a property that doesn't exist on the page or database:

1. List the available properties.
2. Suggest the closest match.
3. Ask for confirmation before proceeding.

Example: "Set the owner to Sarah" when there's no "Owner" property:
→ "This database doesn't have an 'Owner' property. Available people properties: 'Assignee', 'Reviewer'. Did you mean 'Assignee'?"
