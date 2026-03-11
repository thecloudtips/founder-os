---
name: Briefing Assembly
description: "Synthesizes multi-source data into a structured daily briefing Notion page. Activates when the user wants a morning summary, daily overview, today's briefing, or asks 'what's on my plate today?' Covers schedule, priority emails, tasks, Slack highlights, and quick stats — handles partial data gracefully when sources are unavailable."
globs:
  - "teams/agents/briefing-lead.md"
---

## Overview

Synthesize data from four parallel gatherers (calendar-agent, gmail-agent, notion-agent, slack-agent) into a unified daily briefing page in Notion. Each gatherer delivers a structured payload for its domain -- calendar provides today's events and prep notes, gmail provides priority unread emails, notion provides tasks due today, and slack provides overnight mentions. Merge these payloads into a single briefing page following the five-section structure below. Record briefing metadata in a tracking database. Handle partial data gracefully when gatherers fail or return empty results.

## Briefing Section Structure

Assemble the briefing in this exact section order. Each section maps to one gatherer's output.

### 1. Schedule Overview (from calendar-agent)

Present today's meetings in chronological order:

- Include meeting title, start time, end time, and attendee list for each event.
- Append prep notes from the calendar-agent below each meeting entry. Prep notes summarize prior context, open items with attendees, and suggested talking points.
- Display total meeting count at the top of the section: "N meetings today".
- Flag meetings needing preparation with bold markers. A meeting needs prep when it has 3+ attendees, involves external participants, or the calendar-agent explicitly flagged it.
- For back-to-back meetings (gap < 15 minutes), add a warning note about the tight transition.
- When no meetings exist for today, display: "No meetings scheduled today."

### 2. Priority Emails (from gmail-agent)

Present the highest-priority unread emails sorted by priority level (Q1 first, then Q2):

- Show sender name, subject line, priority level (Q1/Q2/Q3), and required action for each email.
- Display total unread count at the top: "N priority emails requiring attention".
- Limit the list to the top 10 emails. If more exist, append: "+N more in inbox".
- Classify required actions into categories: Reply Needed, Review Required, FYI Only, Approval Needed, Scheduling Request.
- Include a one-line summary of each email's content -- enough to decide whether to act now or defer.
- When no priority emails exist, display: "Inbox clear -- no priority emails."

### 3. Tasks Due Today (from notion-agent)

Present tasks grouped by project, sorted by priority within each group:

- Show task title, priority level, and project name for each task.
- Mark overdue tasks with a flag indicator. A task is overdue when its due date is before today.
- Display counts at the top: "N tasks due today (M overdue)".
- Within each project group, sort by priority: Critical > High > Medium > Low.
- For overdue tasks, include the number of days overdue.
- When no tasks are due, display: "No tasks due today."

### 4. Slack Highlights (from slack-agent, optional)

Present overnight mentions and important messages:

- Show channel name, sender, message snippet, and timestamp for each highlight.
- Group by channel, sorted by recency within each channel.
- Display mention count at the top: "N mentions overnight".
- Distinguish between direct mentions, channel mentions, and thread replies.
- If the slack-agent was not configured, returned no data, or failed entirely, omit this section completely. Do not render an empty section header or placeholder. Slack absence is normal operation, not an error.

### 5. Quick Stats

Compile a summary metrics block from the data above:

| Metric | Source |
|--------|--------|
| Meetings today | Schedule Overview count |
| Priority emails | Priority Emails count |
| Tasks due | Tasks Due Today total count |
| Overdue tasks | Tasks Due Today overdue count |
| Slack mentions | Slack Highlights count (omit row if Slack unavailable) |

Display as a compact inline summary, not a table. Example format: "4 meetings | 7 priority emails | 12 tasks due (3 overdue) | 5 Slack mentions".

## Notion Page Format

Create the briefing as a Notion page with these formatting rules.

### Page Properties

- **Title**: "Daily Briefing -- [YYYY-MM-DD]" using the current date.
- **Icon**: Use a calendar emoji as the page icon.
- Create the page in the "[FOS] Briefings" database (see Database Recording below). If no database exists, fall back to "Founder OS HQ - Briefings", then "Daily Briefing Generator - Briefings". If none exists, create the page as a standalone page in the workspace root.

### Block Structure

Apply these Notion block types for visual hierarchy and scannability:

- **Heading 2 blocks** for each of the five section headers (Schedule Overview, Priority Emails, Tasks Due Today, Slack Highlights, Quick Stats).
- **Callout blocks** for urgent items requiring immediate attention: Q1 priority emails and overdue tasks. Use a warning icon for callouts.
- **Toggle blocks** for meeting prep details. Place the meeting title and time as the toggle summary; collapse prep notes, attendee list, and talking points inside the toggle body. Collapsed by default to keep the briefing scannable.
- **Bulleted list blocks** for task lists and email lists. Each list item is one task or one email entry.
- **Divider blocks** between each major section to create visual separation.
- **Bold text** for action items, overdue flags, and anything requiring the reader's decision.

### Formatting Constraints

- Keep all text concise. Summaries are one line maximum. Prep notes are three lines maximum.
- Use relative time references for today's events ("in 2 hours", "starting now") and absolute times for reference ("9:00 AM -- 10:00 AM").
- Never include full email bodies. Show subject + one-line summary only.
- Never include full task descriptions. Show title + priority + overdue status only.

## Notion Database Recording

Track each generated briefing in the consolidated Founder OS HQ Briefings database for historical reference and analytics.

### Database Discovery

1. Search Notion for a database titled "[FOS] Briefings" using the search API by title.
2. If found, use that database.
3. If not found, try "Founder OS HQ - Briefings".
4. If not found, fall back to "Daily Briefing Generator - Briefings".
5. If none is found, skip Notion recording and log the briefing to chat only. Do NOT create a new database.

### Database Schema

The consolidated "[FOS] Briefings" database uses these properties:

| Property | Type | Description |
|----------|------|-------------|
| Date | title | Briefing date in YYYY-MM-DD format -- primary lookup key |
| Type | select | Briefing type -- set to "Daily Briefing" for this plugin |
| Content | rich_text | Link to the generated briefing Notion page |
| Meeting Count | number | Total meetings for the day |
| Email Count | number | Priority emails surfaced |
| Task Count | number | Tasks due today |
| Overdue Tasks | number | Tasks past their due date |
| Sources Used | multi_select | Which gatherers contributed data (Calendar, Gmail, Notion, Slack) |
| Generated At | date | Timestamp of briefing generation |

**Property mapping note:** The old "Briefing" property maps to "Content" in the consolidated DB. The "Type" property must always be set to "Daily Briefing".

### Row Creation

After publishing the briefing page, create a row in the database with all metrics populated. Always set Type to "Daily Briefing". Include only the sources that successfully returned data in the Sources Used field.

### Duplicate Prevention

Before creating a new briefing, check for an existing row matching BOTH the target date (Date title) AND Type = "Daily Briefing". If a briefing already exists for today with that type, update the existing row and page rather than creating a duplicate. Append a note to the page: "Updated at [timestamp] -- replaces earlier briefing."

## Partial Data Handling

The team config requires a minimum of 2 of 4 gatherers to succeed (minimum_gatherers_required: 2). Handle partial results as follows:

### Successful Gatherer

Include the gatherer's section in the briefing as specified above. Add the source name to the Sources Used field.

### Failed Gatherer (required source)

When calendar-agent, gmail-agent, or notion-agent fails:

- Include the section header in the briefing.
- Replace section content with a notice: "Data unavailable -- [Source] could not be reached. Check MCP server configuration."
- Use a callout block with a warning icon for the notice.
- Set the corresponding metric to 0 in the database row.
- Do not fail the entire briefing. Continue with available data.

### Failed Gatherer (optional source)

When slack-agent fails or is not configured:

- Omit the Slack Highlights section entirely. Do not show an empty section or error notice.
- Omit the Slack mentions row from Quick Stats.
- Do not include "Slack" in Sources Used.
- This is normal operation. Log the absence but do not treat it as an error.

### Minimum Threshold Failure

When fewer than 2 gatherers return data, do not publish a briefing page. Instead:

- Log the failure with details about which gatherers failed and why.
- Return a clear error message: "Daily briefing generation failed -- insufficient data sources. Only [N] of 4 gatherers returned data (minimum 2 required)."
- Do not create a database row for failed generations.

## Output Quality Rules

Apply these standards to every briefing produced.

### Scannability

- The entire briefing should be readable in under 2 minutes.
- Lead each section with its summary metric count before listing details.
- Use short phrases, not full sentences, for list items.
- Bold all action-required items so they stand out during a quick scan.

### Priority Ordering

- Sort meetings chronologically (earliest first) -- time sequence matters for schedule planning.
- Sort emails by priority level (Q1 first, then Q2, then Q3) -- urgency matters for triage.
- Sort tasks by priority within project groups (Critical > High > Medium > Low) -- importance matters for execution.
- Sort Slack mentions by recency (newest first) -- freshness matters for responsiveness.

### Action Highlighting

- Mark every item requiring a decision or response with bold text.
- Group action-required items visually using callout blocks when they are urgent.
- In Quick Stats, bold any metric that exceeds a threshold: overdue tasks > 0, priority emails > 10, meetings > 6.

### Consistency

- Use the same date format throughout: "YYYY-MM-DD" for dates, "h:mm AM/PM" for times.
- Use consistent priority labels: Q1 (urgent + important), Q2 (important, not urgent), Q3 (urgent, not important), Q4 (neither).
- Use consistent status indicators: overdue (flag), needs-prep (bold), action-required (bold), FYI (normal weight).

## Edge Cases

### No Data from Any Source

When all 4 gatherers fail, do not produce a briefing. Return an error and suggest verifying MCP server connectivity. See Minimum Threshold Failure above.

### Very Busy Day (High Volume)

When totals exceed typical thresholds (meetings > 8, emails > 20, tasks > 15), add a "Today is unusually busy" callout at the top of the briefing before the first section. Suggest prioritizing Q1 items only and deferring Q2/Q3 to tomorrow.

### Weekend or Holiday

When the calendar returns no events and the task list is light (< 3 items), adapt the briefing tone. Replace "Schedule Overview" header with "Weekend / Light Day" and omit meeting prep toggles. Focus the briefing on carry-over tasks and deferred emails.

### Stale Gatherer Data

When a gatherer returns data but the data appears stale (e.g., emails from yesterday with no new unread, calendar events from a previous day), include the data but prepend a notice: "Data may be stale -- last updated [timestamp]." Flag the source as potentially stale in the database row.

### Timezone Considerations

Use the user's local timezone for all time references. Retrieve timezone from calendar events or system settings. When displaying meeting times for cross-timezone meetings, show the local time with the original timezone in parentheses for reference.
