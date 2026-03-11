---
description: Generate a structured weekly review from tasks, meetings, and emails
argument-hint: "--date=2026-03-03 --output=notion [--schedule=EXPR] [--persistent]"
allowed-tools: ["Read"]
---

# Weekly Review

Generate a comprehensive weekly review by auto-discovering Notion task databases, pulling Google Calendar events, and scanning Gmail threads. Assemble everything into a structured 6-section Notion page covering wins, meetings, communication, blockers, priorities, and reflection.

## Load Skills

Read the weekly-reflection skill at `${CLAUDE_PLUGIN_ROOT}/skills/review/weekly-reflection/SKILL.md` for the complete review pipeline: week boundary rules, database auto-discovery algorithm, 3-source data gathering, blocker detection signals, priority ranking algorithm, and Notion output formatting.

## Parse Arguments

Extract these from `$ARGUMENTS`:
- `--date=YYYY-MM-DD` (date, default: current week) -- any date within the target review week. Resolves to the Monday-Sunday window containing that date.
- `--output=notion|chat|both` (string, default: notion) -- where to deliver the review.

If `--date` is omitted, review the most recent completed week (previous Monday-Sunday). If today is Sunday, review the current week (this Monday through today).

Validate `--date` format (YYYY-MM-DD). Reject malformed dates with a clear error message.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Scheduling Support

If `$ARGUMENTS` contains `--schedule`:
1. Extract the schedule value and any `--persistent` flag
2. Read `_infrastructure/scheduling/SKILL.md` for scheduling bridge logic
3. Read `_infrastructure/scheduling/references/schedule-flag-spec.md` for argument parsing
4. Default suggestion if no expression given: `"0 17 * * 5"` (Fridays 5:00pm)
5. Handle the schedule operation (create/disable/status) per the spec
6. Exit after scheduling — do NOT continue to main command logic

## Step 1: Determine Week Boundaries

Calculate the Monday 00:00:00 through Sunday 23:59:59 window containing the `--date` value (or the default week).

- Express all timestamps in the user's local timezone.
- Use ISO format `YYYY-MM-DD` for all date references.
- Label the review with the Monday date: "Weekly Review -- YYYY-MM-DD".

## Step 2: Check for Existing Review

Search Notion for a database titled "[FOS] Briefings". If not found, try "Founder OS HQ - Briefings". If not found, fall back to "Weekly Review Compiler - Reviews".

- If found, look for a row matching the Monday date as the title AND Type = "Weekly Review".
- If a review exists for that week, prepare to update it (do not duplicate). Note: "Updating existing review for week of [Monday date]."
- If neither database is found, Notion recording will be skipped in Step 7 (no database will be created).

## Step 3: Auto-Discover Notion Task Databases

Follow the database auto-discovery algorithm from the weekly-reflection skill:

1. Search Notion for all accessible databases.
2. Qualify databases that have both a Status property (with completion-like values: Done, Complete, Completed, Closed) and a Date property (Due Date, Date, Completed Date, Done Date, or Last Edited).
3. Report discovered databases: "Found [N] task databases: [names]."
4. If zero qualify, warn and continue with Calendar/Gmail only.

For each qualifying database, query for:
- **Completed tasks**: Status in completion set AND date within Mon-Sun window.
- **Carryover tasks**: Status "In Progress" or equivalent, existed before Monday.
- **Overdue tasks**: Due date before Monday, not completed.

Extract: title, status, database name, due date, priority (if exists), project/category (if exists).

## Step 4: Gather Calendar Events

Use Google gws CLI (Calendar) to fetch all events within Monday 00:00:00 to Sunday 23:59:59.

- Extract: event title, start/end time, attendee count, external attendee presence.
- Compute: total events, total meeting hours, busiest and lightest days.
- Classify: internal (same domain), external (different domain), solo (no attendees).

If Google gws CLI is unavailable for Calendar, warn: "Calendar unavailable -- meeting section will show placeholder." Continue with remaining sources.

## Step 5: Gather Gmail Threads

Use gws CLI (Gmail) to scan sent and received threads within the review week.

- Search sent mail: `after:YYYY/MM/DD before:YYYY/MM/DD in:sent`.
- Count total sent emails and unique recipients.
- Identify high-volume threads (5+ messages in a single thread).
- Detect unanswered inbound threads.
- Cap at 10 most active threads.

If gws CLI is unavailable for Gmail, skip silently. Mark Gmail as "unavailable" in sources. This is normal for many users.

## Step 6: Synthesize 6-Section Review

Read `${CLAUDE_PLUGIN_ROOT}/skills/review/weekly-reflection/references/review-structure.md` for detailed section templates. Assemble the review with exactly 6 sections:

### Section 1: Executive Summary
- 2-3 sentence week overview with key metrics: tasks completed, meetings held, blockers detected.
- Week assessment: Productive / Moderate / Light (based on task completion and meeting density).
- Highlight the single most notable win and the most critical blocker.

### Section 2: Wins by Project
- Group completed tasks by source database/project.
- Show task count per group with task names and completion status indicators.
- Include a total count summary at the top.
- Sort groups by completion count (highest first).

### Section 3: Meetings & Outcomes
- Show meeting count, total hours, busiest and lightest days.
- List meetings grouped by day: title, time, attendees, outcome (from event description).
- Highlight external meetings.
- When Calendar unavailable: "Calendar data unavailable -- meeting summary skipped."

### Section 4: Blockers & Risks
Apply multi-signal blocker detection from the skill:
- Explicit blocked status (high confidence).
- Overdue tasks (high confidence).
- Stagnant in-progress tasks with no changes all week (medium confidence).
- High-volume unresolved email threads (low confidence).
- Meeting-heavy days with zero completions (low confidence).

Classify by severity: Critical / Warning / Watch. Sort by severity then age. Group by theme (project or assignee) when 3+ blockers share a common thread.

### Section 5: Carryover Items
- List incomplete tasks from the review week that remain in "In Progress" or equivalent.
- Group by priority tier (Critical/High/Medium/Low).
- Show days in current status for each item.
- Flag tasks stagnant for 14+ days.

### Section 6: Next Week Priorities & Calendar Preview
Build candidate pool (tasks due next week + carryover + overdue). Score using the 3-factor ranking algorithm from the skill:
- Due date urgency (weight 0.50)
- Carryover penalty (weight 0.30)
- Priority property (weight 0.20)

Present top 5 numbered with source, due date, and ranking rationale.

Include a calendar preview for next week: meeting-heavy days, focus blocks (days with fewer than 2 meetings), and the best day for deep work.

## Step 7: Create/Update Notion Page

### Output: Notion (default or `--output=notion` or `--output=both`)

Create (or update) a Notion page in the "[FOS] Briefings" database (fall back to "Founder OS HQ - Briefings", then "Weekly Review Compiler - Reviews"; skip Notion recording if none exists).

- **Title**: "Weekly Review -- [YYYY-MM-DD]" (Monday date).
- **Icon**: Clipboard emoji.
- **Format**: H2 blocks for sections, dividers between sections, callout blocks for metrics and blockers, bulleted lists for tasks/meetings, bold for all quantitative summaries.

Do NOT create a new database if none is found. Output the review to chat instead.

Write a row with all metrics populated. Always set Type = "Weekly Review". Map the executive summary to the "Content" property. Include only sources that returned data in Sources Used.

### Output: Chat (`--output=chat` or `--output=both`)

Display the review directly in the conversation using the format below.

## Step 8: Present Confirmation

Display a summary to the user:

```
## Weekly Review -- [YYYY-MM-DD]

**Status**: Generated successfully
**Notion Page**: [URL] (if --output includes notion)
**Sources**: Notion [status] | Calendar [status] | Gmail [status]
**Quick Stats**: [N] tasks completed | [N] meetings | [N] email threads | [N] blockers

### Wins ([N] tasks across [N] projects)
**[Project/DB Name]** ([N] tasks)
- [Task title] [DONE]
- ...
(Top items shown; full list on Notion page)

### Blockers ([N] detected)
- [Critical/Warning/Watch] [Description] ([days] old)
- ...

### Next Week Top 5
1. [Task title] (due [date]) -- [rationale]
2. ...
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Error Handling

- **Notion MCP not configured**: Halt immediately. Display: "Notion MCP is required for weekly review. See `${CLAUDE_PLUGIN_ROOT}/INSTALL.md` for setup instructions."
- **gws CLI (Calendar) not configured**: Warn and continue. Meeting section shows placeholder.
- **gws CLI (Gmail) not configured**: Skip silently. Communication section shows placeholder.
- **Notion available but zero task databases discovered**: Continue -- generate review with Calendar/Gmail data. Note: "No task databases found. Wins and priorities sections will be empty."
- **Existing review for target week**: Update existing page and row (matched by Date + Type = "Weekly Review"). Note in output: "Updated existing review."
- **No data from any source**: Include sections with empty-state messages ("Quiet week -- no completed tasks found"). This confirms the source was checked.
- **Future date**: Allow (for pre-planning), but warn: "Note: [date] is in the future. Review data may be incomplete."

## Usage Examples

```
/founder-os:review:review                           # Review the most recent completed week
/founder-os:review:review --date=2026-02-24         # Review the week containing Feb 24
/founder-os:review:review --output=chat             # Display review in chat instead of Notion
/founder-os:review:review --output=both             # Both Notion page and chat display
/founder-os:review:review --date=2026-03-03 --output=notion  # Specific week, Notion output
```
