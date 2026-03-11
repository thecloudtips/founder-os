---
name: Task Curation
description: "Filters and prioritizes Notion tasks by due date for daily briefing inclusion. Activates when the user wants to see tasks due today, overdue items, daily task lists, or asks 'what do I need to do today?' Auto-discovers task databases, groups by project, flags overdue items, and handles multiple databases gracefully."
globs:
  - "teams/agents/notion-agent.md"
---

## Overview

Filter Notion tasks by due date, order by priority, group by project or database source, and flag overdue items. Produce a structured task list suitable for inclusion in a daily briefing. Search across multiple task databases using dynamic discovery -- never hardcode database IDs. Aggregate results from all discovered databases into a single unified list. Report summary statistics alongside the task list: total due today, total overdue, total upcoming.

## Notion Task Database Discovery

Locate task databases by searching Notion for databases matching common naming patterns. Try each pattern in order and collect all matches:

1. **Founder OS HQ integration**: "[FOS] Tasks" first, then "Founder OS HQ - Tasks" (consolidated task database from P01, P04, P06)
2. **Primary names**: "Tasks", "To-Do", "To Do", "Action Items", "Project Tasks"
3. **Prefixed names**: databases containing "Tasks" or "Action Items" in the title (catches "Marketing Tasks", "Dev Action Items", etc.)
4. **Inbox Zero legacy**: "Inbox Zero - Action Items" (fallback for non-HQ users)

Use the Notion search API with `filter.object: "database"` for each pattern. Collect all unique database IDs. Deduplicate by ID when multiple search patterns return the same database.

When no task database is found after trying all patterns, report the source as "unavailable" and include zero tasks with a note: "No task database discovered in Notion -- verify database exists and integration has access."

### Required Database Properties

For each discovered database, detect which properties are present. Map property names flexibly -- different databases use different naming conventions:

- **Title property** (always present): The task name. Use whatever the database's title property is.
- **Due date**: Look for properties named "Due", "Due Date", "Deadline", "Date", or any date-type property containing "due" in the name.
- **Status**: Look for "Status", "State", "Stage", or any select/status-type property. Map values to two buckets: **completed** ("Done", "Completed", "Closed", "Archived", "Resolved") and **active** (everything else).
- **Priority**: Look for "Priority", "Urgency", "P-Level", or any select-type property containing "priority" in the name.
- **Project**: Look for "Project", "Category", "Area", "Team", or any select/relation-type property indicating grouping context.

When a property is missing, skip the logic that depends on it. A database without a due date property contributes zero tasks to date-based filtering. A database without a priority property uses positional ordering only.

## Filtering Rules

Apply date-based filters relative to today's date at processing time. Evaluate each task against three buckets in this order:

### Overdue Tasks
Include when ALL of the following hold:
- Due date property exists and its value is before today (strictly less than today's date)
- Status does not map to the completed bucket
- Task is not archived or deleted

### Due Today
Include when ALL of the following hold:
- Due date property exists and its value equals today's date
- Status does not map to the completed bucket

### Upcoming (Next 2 Days)
Include when ALL of the following hold:
- Due date property exists and its value is tomorrow or the day after tomorrow
- Status does not map to the completed bucket

### Exclusions
Always exclude:
- Tasks with status mapping to the completed bucket
- Tasks in archived or trashed state
- Tasks without a due date property (exclude from all three date buckets entirely -- do not guess dates)
- Tasks with a due date more than 2 days in the future

## Priority Ordering

Assign a numeric sort weight to each task based on its priority property value. Lower weight means higher priority (sorts first).

### Priority Property Mapping

Map priority values to sort weights using flexible pattern matching:

| Priority Value | Sort Weight | Label |
|---------------|-------------|-------|
| P0, Critical, Urgent, Highest | 1 | Critical |
| P1, High, Important | 2 | High |
| P2, Medium, Normal, Default | 3 | Medium |
| P3, Low, Minor | 4 | Low |
| P4, Backlog, Someday, Lowest | 5 | Backlog |
| (no priority set) | 3 | Medium |

Match case-insensitively. When a priority value does not match any pattern above, assign sort weight 3 (Medium) as default.

### Composite Sort Order

Sort tasks using a multi-key sort. Apply keys in this order:

1. **Date bucket** (ascending): Overdue = 0, Due Today = 1, Upcoming = 2
2. **Priority weight** (ascending): Critical first, Backlog last
3. **Due date** (ascending): Earlier dates first within the same priority level. Overdue tasks with the oldest due date sort first within the overdue bucket.
4. **Project name** (alphabetical, ascending): Alphabetical tiebreaker when all other keys are equal

When no priority property exists in a database, omit key 2 and sort by date bucket, due date, then project name.

## Grouping Strategy

After sorting, organize tasks into display groups for the briefing output:

### Primary Grouping: By Project

Group tasks by their project/category property value. Use the database name as fallback when no project property exists.

- Create one group per unique project name
- Within each group, maintain the composite sort order established above
- Sort groups alphabetically by project name
- Place an "Ungrouped" section last for tasks without a project property

### Overdue Highlighting

Flag every overdue task with `overdue: true`. Include the number of days overdue in the task metadata, calculated as: today's date minus the task's due date.

Within each project group, overdue tasks appear first (enforced by the composite sort order's date bucket key).

## Output Format

Produce structured output containing two sections: summary statistics and the grouped task list.

### Summary Statistics

```
total_due_today: [count]
total_overdue: [count]
total_upcoming: [count]
total_tasks: [sum of above]
databases_searched: [count]
databases_with_results: [count]
```

### Task List Structure

For each task, include:

- **title**: Task name from the title property
- **project**: Project/category name, or database name as fallback, or "Ungrouped"
- **priority**: Normalized label (Critical, High, Medium, Low, Backlog)
- **due_date**: ISO date string (YYYY-MM-DD)
- **status**: Raw status value from the database
- **overdue**: Boolean -- true if due date is before today
- **days_overdue**: Integer -- number of days past due (0 if not overdue)
- **source_database**: Name of the Notion database this task came from
- **notion_url**: URL to the Notion page for direct access

Group tasks under their project name. Within each project, list tasks in composite sort order.

## Edge Cases

### No Tasks Due
When all three date buckets return zero tasks across all discovered databases, report a clear day. Set all summary counts to 0. Include a positive note: "No tasks due today, none overdue, and nothing upcoming in the next 2 days." Do not fabricate tasks or pull from other date ranges.

### All Overdue
When every returned task falls in the overdue bucket (zero due today, zero upcoming), flag the output as attention needed. Prepend a warning to the summary: "All returned tasks are overdue -- no new tasks due today. Review and reschedule or complete overdue items." Continue producing the full grouped output as normal.

### No Task Database Found
When dynamic discovery finds zero matching databases, set task source status to "unavailable." Return zero tasks with summary counts all at 0. Include a diagnostic note: "No task database discovered -- verify Notion databases exist with supported names (Tasks, To-Do, Action Items, Project Tasks) and that the Notion integration has access."

### Tasks Without Due Dates
Exclude entirely from date-based filtering. Do not include in any bucket. Do not count in summary statistics. These tasks are invisible to the daily briefing -- they belong in backlog views, not date-driven curation.

### Multiple Databases With Overlapping Tasks
When the same task appears in multiple databases (detected by identical title AND identical due date), keep the instance from the first-discovered database only. Deduplicate before grouping.

### Database Access Errors
When a discovered database returns a permission error or API failure during query, skip that database. Decrement `databases_with_results` accordingly. Add a note to the output: "Database '[name]' was discovered but returned an access error -- results may be incomplete." Continue processing remaining databases.
