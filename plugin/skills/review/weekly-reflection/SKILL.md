---
name: Weekly Reflection
description: "Generates a structured 6-section weekly review page in Notion from tasks, calendar, and email data. Activates for weekly reviews, end-of-week summaries, 'what did I accomplish?', weekly wins/blockers, or any retrospective on the past week. Auto-discovers task databases, detects blockers via multi-signal analysis, and generates next-week priorities."
globs:
  - "commands/review.md"
---

## Overview

Generate a structured 6-section weekly review page in Notion by auto-discovering task databases, gathering calendar events and email threads, detecting blockers, and producing next-week priorities. The full pipeline runs in a single agent pass (no agent teams). Record each review in a tracking database for historical reference.

For detailed section templates see `${CLAUDE_PLUGIN_ROOT}/skills/review/weekly-reflection/references/review-structure.md`. For source-specific query patterns see `${CLAUDE_PLUGIN_ROOT}/skills/review/weekly-reflection/references/data-sources.md`.

## Week Boundaries

Define the review period as a full Monday-through-Sunday week.

### Boundary Rules

1. Compute the review week from the current date. If today is Monday through Saturday, the review covers the immediately preceding Monday 00:00:00 through Sunday 23:59:59. If today is Sunday, the review covers the current week (Monday 00:00:00 through today 23:59:59).
2. When the user provides a `--date` flag with a date (e.g., `--date=2026-02-23`), resolve to the Monday-Sunday window containing that date.
3. Express all boundary timestamps in the user's local timezone. Derive timezone from calendar events or system locale.
4. Use ISO format `YYYY-MM-DD` for all date references in the review content and database records.
5. Label the review with the Monday date: "Weekly Review -- 2026-03-02" (the Monday of the review week).

### Duplicate Prevention

Before generating a new review, query the briefings database for an existing row matching the Monday date AND Type = "Weekly Review". If a review already exists for that week, update the existing page and row rather than creating a duplicate. Append a note to the page: "Updated at [timestamp] -- replaces earlier review."

## Data Source Discovery & Gathering

Gather data from three sources in sequence: Notion task databases, Google Calendar events, and Gmail threads.

### Source 1: Notion Task Databases (auto-discovered)

Auto-discover task databases rather than requiring the user to specify database IDs.

#### Discovery Algorithm

1. Call the Notion search API with `filter: { property: "object", value: "database" }` to retrieve all accessible databases.
2. For each discovered database, inspect its properties schema. A database qualifies as a task database when it contains both:
   - A **Status** property (type: `status` or `select`) with at least one option matching "Done", "Complete", "Completed", or "Closed" (case-insensitive).
   - A **Date** property (type: `date`) named "Due Date", "Date", "Completed Date", "Done Date", or "Last Edited" (case-insensitive, partial match acceptable).
3. Rank qualifying databases by relevance: databases with a property named "Due Date" or "Completed Date" rank higher than those relying on "Last Edited".
4. Report discovered databases before proceeding: "Found [N] task databases: [DB Name 1], [DB Name 2], ..."
5. If zero databases qualify, warn: "No task databases discovered. Notion tasks section will be empty." Continue with remaining sources.

#### Task Retrieval

For each qualifying database, query for tasks matching the review week:

- **Completed tasks**: Status in ("Done", "Complete", "Completed", "Closed") AND completion/last-edited date within the Monday-Sunday window.
- **Carryover tasks**: Status in ("In Progress", "Doing", "In Review") AND task existed before the review week's Monday. Unfinished items carried into the week.
- **Overdue tasks**: Due date before Monday AND status NOT in completed set.

Extract for each task: title, status, database name (source), due date, priority (if property exists), and project or category (if property exists).

### Source 2: Google Calendar Events

Query Google Calendar for events within the Monday 00:00:00 to Sunday 23:59:59 window.

- Retrieve all events including recurring instances.
- Extract: event title, start/end time, attendee count, external attendee presence.
- Compute: total events, total meeting hours, busiest and lightest days.
- Classify events: internal (same domain), external (different domain), solo (no attendees).
- When gws CLI is unavailable for Calendar, set status to "unavailable" and skip. Do not fail the review.

### Source 3: Gmail Threads

Query Gmail for sent and received threads within the review week window.

- Search sent mail: `after:YYYY/MM/DD before:YYYY/MM/DD in:sent`.
- Count total sent emails and unique recipients.
- Identify high-volume threads (5+ messages in a single thread).
- Detect unanswered inbound threads (received, no reply from user).
- When gws CLI is unavailable for Gmail, set status to "unavailable" and skip.

## Review Section Structure

Assemble the review page with exactly 6 sections in this order. For detailed templates, content examples, and the complete example output, see `${CLAUDE_PLUGIN_ROOT}/skills/review/weekly-reflection/references/review-structure.md`.

| # | Section | Primary Source | Purpose |
|---|---------|----------------|---------|
| 1 | Executive Summary | All sources (metrics) | Top-line metrics callout, week assessment, highlight win or risk |
| 2 | Wins by Project | Notion completed tasks | Celebrate completed work grouped by project |
| 3 | Meetings & Outcomes | Google Calendar | Summarize meeting load, list meetings with extracted outcomes |
| 4 | Blockers & Risks | Multi-signal (all sources) | Surface blocked, overdue, and stagnant items |
| 5 | Carryover Items | Notion open tasks | List incomplete tasks carrying into next week, grouped by priority |
| 6 | Next Week Priorities & Calendar Preview | Notion tasks + Calendar | AI-ranked top-5 priorities plus next week's calendar shape |

### Section Formatting Rules

- Use Heading 2 blocks for each section header.
- Use divider blocks between sections.
- Bold all metrics and quantitative summaries.
- Use bulleted lists for task enumerations and meeting lists.
- Use callout blocks with warning icons for blockers and risks.
- Keep individual items to one line. Summaries precede detail lists.

## Blocker & Risk Detection

Identify blockers through multi-signal analysis across all three data sources.

### Detection Signals

Evaluate these 5 signals independently, then merge results:

1. **Explicit Blocked Status**: Tasks with status "Blocked", "On Hold", "Waiting", or "Stalled" (case-insensitive). Confidence: high.
2. **Overdue Tasks**: Due date before review week's Monday, still incomplete. 7+ days overdue = elevated severity. Confidence: high.
3. **Stagnant Tasks**: "In Progress" with no property changes during the entire review week (no status change, no edited timestamp within the window). Confidence: medium.
4. **High-Volume Unresolved Threads**: Gmail threads with 5+ messages and no resolution signal ("done", "resolved", "approved", "completed") in the final 2 messages. Confidence: low.
5. **Meeting-Heavy Days with Low Completion**: Calendar days with 4+ hours of meetings and zero completed tasks that day. Confidence: low.

### Severity Classification

Classify each detected blocker into one of three severity tiers:

| Severity | Criteria |
|----------|----------|
| Critical | Explicit "Blocked" status OR overdue by 14+ days |
| Warning | Overdue by 1-13 days OR stagnant for 5+ days |
| Watch | Stagnant for 2-4 days OR unresolved thread OR meeting-heavy day |

Present blockers sorted by severity (Critical first), then by age (oldest first within each tier).

## Next Week Priority Generation

Generate a ranked top-5 priority list for the coming week.

### Priority Candidate Pool

Build the candidate pool from three sources:

1. **Tasks due next week**: Tasks with due dates in the next Monday-Sunday window. Primary candidates.
2. **Carryover tasks**: Incomplete tasks from the current week still in "In Progress" or equivalent.
3. **Overdue tasks**: Tasks past their due date that remain incomplete. Receive a priority boost.

### Ranking Algorithm

Score each candidate on 3 factors (0-100 each), then compute a weighted composite:

| Factor | Weight | Scoring Logic |
|--------|--------|---------------|
| Due date urgency | 0.50 | Mon=100, Tue=85, Wed=70, Thu=55, Fri=40. Overdue=100. No date=20. |
| Carryover penalty | 0.30 | New=0. 1 week=40. 2 weeks=70. 3+ weeks=100. |
| Priority property | 0.20 | Critical/Urgent=100, High=75, Medium=50, Low=25. No property=50. |

Composite = (urgency x 0.50) + (carryover x 0.30) + (priority x 0.20).

Select top 5 by composite score. Present numbered 1-5 with source database, due date, and one-line ranking rationale.

When fewer than 5 candidates exist, present all. When zero exist: "No upcoming tasks found. Consider reviewing project backlogs."

## Notion Output & Database Recording

### Review Page Creation

Create the weekly review as a Notion page in the consolidated "[FOS] Briefings" database (or legacy fallback).

- **Title**: "Weekly Review -- [YYYY-MM-DD]" using the Monday date of the review week.
- **Icon**: Use a clipboard emoji as the page icon.
- Apply the 6-section structure with Heading 2, divider, bulleted list, and callout blocks as specified in the section formatting rules.

### Database Discovery

1. Search Notion for a database titled "[FOS] Briefings".
2. If found, use it.
3. If not found, try "Founder OS HQ - Briefings".
4. If not found, fall back to "Weekly Review Compiler - Reviews".
5. If none is found, skip Notion recording and output the review to chat only. Do NOT create a new database.

### Database Schema

The consolidated "[FOS] Briefings" database uses these properties (relevant to this plugin):

| Property | Type | Description |
|----------|------|-------------|
| Date | title | Week ending date in YYYY-MM-DD format -- primary lookup key (was "Week Ending") |
| Type | select | Set to "Weekly Review" for this plugin |
| Content | rich_text | Executive summary (was "Executive Summary") |
| Tasks Completed | number | Total completed tasks count |
| Meetings Held | number | Total meetings count for the week |
| Email Threads | number | Active email threads count |
| Sources Used | multi_select | Which sources contributed data (Notion, Calendar, Gmail) |
| Generated At | date | Timestamp of review generation |

**Property mapping notes:**
- Old "Week Ending" title maps to "Date" in the consolidated DB.
- Old "Executive Summary" maps to "Content". Store the 2-3 sentence overview there.
- The "Type" property must always be set to "Weekly Review".
- Section-specific rich_text properties (Wins, Meetings Summary, Blockers, Carryover Items, Next Week Priorities) are stored in the review page body, not as separate DB properties in the consolidated DB.

### Row Creation

After publishing the review page, create or update a row with all metrics populated. Always set Type = "Weekly Review". Include only sources that successfully returned data in Sources Used.

## Partial Data Handling

Notion is the primary source; Calendar and Gmail are supplementary.

### Notion Available (minimum requirement)

When Notion is available, always generate the review. Sections 1, 4, and 5 populate from Notion alone. Sections 2, 3, and 6 degrade gracefully.

### Calendar Unavailable

- Omit the Meetings & Collaboration section body. Replace with: "Calendar data unavailable -- meeting summary skipped."
- Exclude meeting-heavy-day signals from blocker detection.
- Do not include "Calendar" in Sources Used.

### Gmail Unavailable

- Omit the Communication Summary section body. Replace with: "Gmail data unavailable -- email summary skipped."
- Exclude unresolved-thread signals from blocker detection.
- Do not include "Gmail" in Sources Used.

### All Sources Unavailable

When Notion itself is unreachable, do not generate a review. Return: "Weekly review generation failed -- Notion is required but unavailable. Check MCP server configuration."

### Empty Results

When a source returns successfully but has no data for the week (zero completed tasks, zero meetings, zero emails), include the section with an appropriate empty-state message. This is normal for light weeks, not an error.

## Additional Resources

Consult these reference files for detailed implementation guidance:

- `${CLAUDE_PLUGIN_ROOT}/skills/review/weekly-reflection/references/data-sources.md` -- Notion query filter construction, Calendar API parameters, Gmail search syntax, field extraction schemas, and source-specific edge cases.
- `${CLAUDE_PLUGIN_ROOT}/skills/review/weekly-reflection/references/review-structure.md` -- Detailed templates for each of the 6 review sections, content examples, Notion block type mapping, and formatting constraints.
