---
name: Morning Briefing
description: "Gathers overnight data from Gmail, Calendar, Notion, Slack, and Drive into a consolidated morning update. Activates when the user wants a morning sync, overnight catch-up, or asks 'what happened while I was away?' Handles multi-source data gathering with overnight window calculation and graceful degradation when sources are unavailable."
globs:
  - "commands/morning-sync.md"
  - "commands/morning-quick.md"
---

## Overview

Gather overnight data from five sources -- Gmail, Google Calendar, Notion, Slack, and Google Drive -- into a single structured dataset for priority synthesis and briefing assembly. Operate as an orchestrator that directly calls gws CLI and MCP tools rather than delegating to agent teams. Reuse domain knowledge from established plugins: P02 Daily Briefing Generator for email prioritization and calendar scoring, P19 Slack Digest Engine for message noise filtering and signal scoring, and P18 Google Drive Brain for file search and relevance ranking. This skill handles data collection and normalization only -- priority ranking, cross-source correlation, and final briefing formatting belong to the priority-synthesis skill and command layer respectively.

## Overnight Window Calculation

Calculate the overnight window before initiating any source queries. All five sources use the same cutoff timestamp to ensure consistent time boundaries across the briefing.

### Default Window

Set the default overnight window to 12 hours back from the current time. When the current time is 7:00 AM, the window covers from 7:00 PM the previous evening through the present moment.

### Configurable Window

Accept a `--since` flag to override the default. Parse the following formats:

| Format | Example | Resolution |
|--------|---------|------------|
| Hours suffix | `8h`, `24h` | Current time minus N hours |
| ISO datetime | `2026-03-04T22:00:00` | Exact cutoff timestamp |

When the `--since` value is unparseable, fall back to the 12-hour default and append a warning: "Could not parse --since value '[input]', using default 12-hour window."

### Cutoff Timestamp

Store the resolved cutoff as an ISO 8601 datetime. Pass this timestamp to every source query. Record both the cutoff datetime and the window duration in the output metadata for downstream consumption.

## Five-Source Gathering Pipeline

Process sources in the following fixed order. Complete each source before starting the next. Record timing and status for every source regardless of outcome.

### Source 1: Gmail (Required)

Scan unread emails received within the overnight window. Construct a Gmail search query using `is:unread after:{cutoff_date}` where `cutoff_date` is the overnight window cutoff formatted as `YYYY/MM/DD`.

Apply P02's email-prioritization patterns to classify each unread email using the Eisenhower matrix (Q1: Urgent and Important, Q2: Important, Q3: Urgent, Q4: Neither). Use sender tier classification, subject keyword signals, action-required flag detection, and recency weighting as defined in P02's email-prioritization skill.

Collapse threads to a single entry using the latest message per thread. Extract up to 10 highlights ordered by quadrant then sender tier then recency.

For each highlight, extract: sender (display name and email), subject (truncated at 80 characters), summary (100 characters max), quadrant assignment, action needed (boolean with action phrase), and recency (relative timestamp).

Return:
- `email_count`: Total unread emails in the overnight window.
- `highlights`: List of up to 10 structured highlight records.
- `unread_total`: Total unread count across all time (not just the window).
- `status`: "available", "unavailable", or "partial".

When gws CLI is unavailable for Gmail, set status to "unavailable", all counts to 0, highlights to an empty list, and continue to the next source.

### Source 2: Google Calendar (Required)

Fetch all events for today (start of day 00:00 to end of day 23:59 in the user's local timezone).

Filter out events matching any of these criteria:
- RSVP status is "declined".
- Event status is "cancelled".
- Title contains "Focus", "Block", or "OOO" (case-insensitive).
- Event has zero attendees (personal reminders).

Classify each remaining event by meeting type using this priority order (first match wins):
1. **external-client**: At least one attendee domain differs from the user's domain AND the event title or attendees match known client contacts.
2. **one-on-one**: Exactly two attendees (user + one other).
3. **ad-hoc**: Non-recurring event with 3+ attendees.
4. **recurring**: Event has a recurrence rule.
5. **group-meeting**: 5+ attendees, non-recurring.
6. **internal-sync**: Default fallback for all other events.

Score importance on a 1-5 scale using four weighted factors:
- Attendee seniority (0.30): Higher when attendees include leadership or C-suite titles.
- External vs internal (0.25): External attendees score higher.
- New vs recurring (0.25): First-time meetings score higher than recurring.
- Deal proximity (0.20): Higher when attendees or title match active deals or proposals.

For each event, extract: title, start time, duration in minutes, attendee count, meeting type, and importance score.

Return:
- `meeting_count`: Number of qualifying events.
- `events`: List of structured event records sorted by start time.
- `status`: "available", "unavailable", or "partial".

### Source 3: Notion (Required)

Search for task databases in the user's Notion workspace. Identify databases containing both a Status property and a Date property (Due Date, Deadline, or similar). Use the same auto-discovery algorithm as P05 Weekly Review Compiler -- search all accessible databases and qualify by the presence of completion-like status values.

Query discovered databases for tasks matching either condition:
- Due Date equals today.
- Due Date is before today AND Status is not "Done", "Completed", or "Archived" (overdue items).

Additionally, search for tasks where Status changed to "Done" or "Completed" within the overnight window to surface overnight completions.

For each task, extract: task title, current status, due date, project or parent database name, and priority property if available.

Return:
- `task_count`: Total tasks due today plus overdue.
- `items`: List of structured task records.
- `overdue`: Count of overdue items specifically.
- `status`: "available", "unavailable", or "partial".

### Source 4: Slack (Optional)

If Slack MCP is available, scan channels for unread messages posted within the overnight window. List joined channels and filter to configured channels if a channel list is specified, otherwise scan all joined channels.

Apply P19's noise filtering pipeline in order: channel management messages, automated bot messages, social and off-topic content, repeated and duplicate messages, link dumps without context, low-signal acknowledgments. Discard messages matching any noise category unless they contain a direct @mention of the current user.

For surviving messages, compute P19's 4-factor signal score: message type (0-40) + engagement (0-25) + recency (0-20) + channel importance (-5 to +15). Surface only messages scoring P1 (75-100) or P2 (50-74), plus all direct @mentions regardless of score.

For each surfaced message, extract: channel name, sender display name, message preview (truncated at 100 characters), signal score, and is_mention boolean.

Return:
- `slack_highlights`: Count of surfaced messages.
- `items`: List of structured message records.
- `status`: "available" or "unavailable".

If Slack MCP is unavailable, return status "unavailable", slack_highlights as 0, items as an empty list. Do not log a warning or error -- optional source unavailability is normal.

### Source 5: Google Drive (Optional)

If Google gws CLI is available for Drive, search for files modified after the overnight window cutoff. Construct a Drive search query filtering by `modifiedTime > '{cutoff_iso}'`.

Filter results:
- Skip files owned by the current user that have no external edits, comments, or shares within the window.
- Surface files that were shared with the user during the window.
- Surface files with new comments added during the window.
- Surface files created during the window by other users in shared folders.

For each qualifying file, extract: file name, file type (Docs/Sheets/Slides/PDF/other), last modifier name, modified timestamp, and shared-with list.

Return:
- `drive_updates`: Count of qualifying file updates.
- `items`: List of structured file records.
- `status`: "available" or "unavailable".

If Google gws CLI is unavailable for Drive, return status "unavailable", drive_updates as 0, items as an empty list. Do not log a warning or error.

## Source Status Reporting

Track the status of each source throughout the gathering pipeline. Assign one of three statuses per source:

| Status | Meaning |
|--------|---------|
| available | MCP server connected, data retrieved successfully |
| unavailable | gws CLI unavailable or authentication not configured or connection failed |
| partial | MCP server connected but returned incomplete data (timeout, rate limit, API error) |

### Required vs Optional Source Handling

**Required sources** (Gmail, Calendar, Notion): Log a warning when any required source returns "unavailable" but continue the pipeline. Include the warning in the output metadata so the command layer can surface it to the user.

**Optional sources** (Slack, Drive): Silently set counts to 0 and status to "unavailable". Do not log warnings. Omit the corresponding section entirely from the final briefing -- do not render an empty section or a "Slack unavailable" placeholder.

### Sources Used List

Compile a `sources_used` list containing only sources with status "available" or "partial". Use this list for Notion DB metadata when logging the briefing.

## Graceful Degradation Rules

Determine the briefing tier based on the number of available required sources:

| Available Required Sources | Briefing Tier | Behavior |
|---------------------------|---------------|----------|
| 3 (Gmail + Calendar + Notion) | Full briefing | Include all available optional sources |
| 2 of 3 required | Partial briefing | Proceed with warning identifying the missing required source |
| 1 of 3 required | Minimal briefing | Proceed with prominent warning, recommend configuring missing sources |
| 0 required | Abort | Return actionable error listing which MCP servers to configure with package names |

The abort error message must include specific MCP server package names:
- Gmail: `gws` CLI (Gmail)
- Google Calendar: `gws` CLI (Calendar)
- Notion: `@modelcontextprotocol/server-notion`

Never error or abort due to optional source unavailability. A briefing with zero optional sources and all three required sources is a full briefing.

## Output Contract

Produce a structured `gathered_data` object consumed by the priority-synthesis skill. Maintain this exact shape regardless of which sources are available -- unavailable sources return zero counts and empty lists.

```
gathered_data:
  overnight_window:
    since: [ISO 8601 cutoff datetime]
    hours: [window duration as number]
  sources:
    gmail: [available | unavailable | partial]
    calendar: [available | unavailable | partial]
    notion: [available | unavailable | partial]
    slack: [available | unavailable | partial]
    drive: [available | unavailable | partial]
  sources_used: [list of source names with status available or partial]
  briefing_tier: [full | partial | minimal]
  email:
    count: [N]
    highlights: [list of highlight records]
    unread_total: [N]
  calendar:
    count: [N]
    events: [list of event records]
  tasks:
    count: [N]
    items: [list of task records]
    overdue: [N]
  slack:
    highlights: [N]
    items: [list of message records]
  drive:
    updates: [N]
    items: [list of file records]
```

Pass this object directly to the priority-synthesis skill without modification. The priority-synthesis skill consumes the gathered data, applies cross-source correlation and priority ranking, and produces the formatted briefing.

## Company Relation

Populate the Company relation when the briefing is dominated by one client's emails/meetings. After gathering data from all sources, examine email sender domains and calendar meeting attendees. If 50% or more of the summarized items (email highlights + calendar events) relate to a single client, search the "[FOS] Companies" database (fall back to "Founder OS HQ - Companies") by domain match from email addresses or meeting attendee domains. If a matching Company is found, include its page ID in the output so the command layer can set the Company relation on the Briefings row.

## Reference

For detailed per-source query construction patterns, extraction field specifications, filtering rules, and edge case handling, consult:
`${CLAUDE_PLUGIN_ROOT}/skills/morning/morning-briefing/references/source-patterns.md`
