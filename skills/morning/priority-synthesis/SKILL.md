---
name: Priority Synthesis
description: "Ranks and synthesizes priorities across all morning data sources into a unified action list. Activates when the user wants to know what to do first, needs morning priorities ranked, or asks 'what's most important today?' Provides cross-source scoring, Top-N extraction, and urgency windowing."
globs:
  - "commands/morning-sync.md"
  - "commands/morning-quick.md"
---

## Overview

Rank and synthesize action items across all morning data sources into a unified priority list and structured briefing. Consume the `gathered_data` output produced by the morning-briefing skill -- containing email, calendar, task, Slack, and Drive payloads -- and produce two outputs: a prioritized action list with urgency windowing, and section-assembled briefing content for Notion storage or chat display. Operate as the second phase of the morning sync pipeline, transforming raw gathered data into decision-ready morning intelligence.

## Cross-Source Priority Scoring

Apply a unified 0-100 scoring system across all source types. Every item receives a base score by type, then additive modifiers adjust upward. Cap the final score at 100.

### Base Scores by Source Type

| Item Type | Base Range |
|-----------|-----------|
| Q1 email (urgent + important) | 80-100 |
| Meeting in next 2 hours | 75-95 |
| Overdue task | 70-90 |
| Slack @mention | 60-80 |
| Q2 email (important, not urgent) | 50-70 |
| Task due today | 40-60 |
| Meeting later today | 30-50 |
| Drive doc shared with user | 20-40 |
| Q3 email | 15-30 |
| Slack highlight (no mention) | 10-25 |
| Drive doc updated | 5-15 |

Within each range, place items higher when they carry more context signals (longer threads, more attendees, closer deadlines) and lower when signals are weak.

### Scoring Modifiers

Apply these additive modifiers after the base score. Multiple modifiers stack. Always cap at 100.

| Modifier | Points | Trigger |
|----------|--------|---------|
| Key client or leadership sender | +15 | Sender matches known client contact or leadership role |
| Deadline today | +10 | Explicit deadline set for today |
| Unanswered 24h+ | +10 | No reply from user for over 24 hours |
| External meeting attendee | +10 | At least one attendee from external domain |
| Thread with 3+ messages | +5 | Email or Slack thread with 3+ messages |
| Task linked to active deal | +5 | Notion task associated with open CRM deal |

Formula: `final_score = min(base_score + sum(applicable_modifiers), 100)`. Record the breakdown for debug transparency.

## Top-N Priority Extraction

Extract the highest-scoring items into a ranked priority list. Default: 5 priorities. Configurable via `--priorities=N` (range 3-15). Sort by final_score descending; break ties by time sensitivity (sooner deadline wins).

### Cross-Source Deduplication Before Ranking

Deduplicate items representing the same concern across sources before ranking:

- **Same person in email + calendar**: Merge into single item, keep higher score, combine context.
- **Task mentioned in email thread**: Keep task entry, append email context, suppress email from list.
- **Meeting prep matching task**: Consolidate under meeting entry, note task status.
- **Same topic in Slack + email**: Keep email (richer context), note Slack timestamp.
- **Drive doc + email notification**: Keep Drive entry, suppress email notification.

Fuzzy matching thresholds: person names match on normalized first + last (ignore case, middle initials); project names use substring match after removing "Project", "Re:", "Fwd:" prefixes; subject keywords match when 3+ non-stopword tokens overlap.

### Priority Item Schema

Each priority item must include:

| Field | Format | Constraint |
|-------|--------|------------|
| Rank | Integer | 1 through N |
| Score | Integer | 0-100 |
| Source | Label | Email, Calendar, Task, Slack, or Drive |
| Action | String | Imperative verb phrase, max 80 chars |
| Context | String | One-line relevance explanation, max 100 chars |
| Time Sensitivity | String | Relative reference ("meeting in 45min", "due today", "overdue 2 days") |

Start every action with an imperative verb mapped by source type:

- **Email actions**: "Reply to...", "Review email from...", "Approve request from...", "Forward to..."
- **Calendar actions**: "Prepare for...", "Join meeting with...", "Review agenda for...", "Resolve conflict with..."
- **Task actions**: "Complete...", "Follow up on...", "Submit...", "Finalize...", "Update status of..."
- **Slack actions**: "Respond to...", "Review thread about...", "Address question from...", "Acknowledge message from..."
- **Drive actions**: "Review document...", "Comment on...", "Approve changes to...", "Download and review..."

Never start an action with a passive construction or a noun. Every action statement must read as a direct instruction the user can execute immediately.

## Urgency Window Grouping

Group priority items into four time-based windows. Assign each item to the earliest applicable window:

| Window | Criteria |
|--------|----------|
| **Next 2 Hours** | Meeting or deadline within 120 minutes |
| **Before Noon** | Due/scheduled between 2 hours from now and 12:00 PM local |
| **Today** | Due today, no specific morning urgency |
| **This Week** | High-priority carry-over, not due today |

Within each window, sort by final_score descending.

### Owner Assignment

Default the owner of every action item to the user. Override only when the item explicitly indicates waiting on another party:

- "Awaiting response from [name]" -- owner is [name]; user action becomes "Follow up if no response by [time]"
- "Blocked by [name]'s approval" -- owner is [name]; user action becomes "Check status with [name]"
- "Delegated to [name]" -- owner is [name]; user action becomes "Verify completion by [name]"

All other items remain owned by the user with the original imperative action intact.

## Morning-Specific Urgency Signals

Identify and flag these morning-critical patterns. When detected, escalate the item to "Next 2 Hours" regardless of original grouping and prepend an alert indicator:

1. **Unprepared meeting**: Event within 2 hours, no prep document or agenda found. Flag: "No prep found."
2. **Overdue carry-over**: Task due yesterday or earlier, still incomplete. Flag: "Overdue [N] days."
3. **Overnight urgent email**: Q1 email from key client received after 6 PM yesterday, unanswered. Flag: "Overnight from [client]."
4. **Leadership Slack mention**: Direct @mention from leadership posted outside business hours. Flag: "Leadership mention."
5. **Calendar conflict**: Overlapping meeting time ranges. Flag: "Conflict: [Event A] overlaps [Event B]."
6. **Review deadline today**: Drive document shared with review-by-today request. Flag: "Review due today."

When multiple signals apply to one item, list all applicable flags.

## Section Assembly for Notion Page

Assemble briefing content in this structure for `/founder-os:morning:sync` Notion output. The briefing is stored in the "[FOS] Briefings" database with Type = "Morning Sync" (falls back to "Founder OS HQ - Briefings", then "Morning Sync - Briefings"). Use Heading 2 blocks for section headers with divider blocks between sections. Omit sections where the source was unavailable, except Top Priorities and Quick Stats (always present).

```
# Morning Sync - [YYYY-MM-DD]

## Top Priorities
[Ranked list: each line = Rank. Action - Source Time Sensitivity (Score: N)]

## Schedule Overview
[Chronological meetings with importance flags, attendee counts, conflict alerts]

## Email Highlights
[Q1 then Q2 emails: Subject - Sender - Required action - One-line summary]

## Tasks & Deadlines
[Grouped by project: overdue first (flagged), then due today, sorted by priority]

## Slack Highlights (if available)
[@mentions first, then channel highlights, grouped by channel]

## Drive Updates (if available)
[Shared documents first, then recently modified, with title/user/timestamp]

## Quick Stats
- Emails: [unread] unread, [highlights] need attention
- Meetings: [count] today ([priority_count] high-priority)
- Tasks: [due] due today, [overdue] overdue
- Slack: [highlights] highlights, [mentions] @mentions
- Drive: [updates] updates
- Sources: [comma-separated available sources]
- Window: [overnight window, e.g., "Since 6:00 PM yesterday"]
```

Use callout blocks with warning icons for urgency-flagged items. Use toggle blocks for meeting details. Use bulleted lists for email and task items. Bold all action-required items. Keep every line item to one line. Use relative time for events within 4 hours, absolute times for all others.

## Quick Summary Format

For `/founder-os:morning:quick`, produce a compact chat-only format. No Notion page. Designed to be read in under 30 seconds. Maximum 15 lines.

```
Morning Quick - [YYYY-MM-DD]

Top [N] priorities:
1. [Action] - [Source] [Time sensitivity]
2. [Action] - [Source] [Time sensitivity]
3. ...

Today: [N] meetings | [N] emails need attention | [N] tasks due | [N] overdue
```

Omit scores in quick format -- rank order implies priority. Omit source categories from the stats line when that source was unavailable.

## Edge Cases

### Zero Items from All Sources

Produce an "All Clear" message. Notion format: heading "All Clear" with body "No urgent items this morning. Consider reviewing weekly goals or tackling backlog tasks." Quick format: single line "All clear -- no urgent items." Still output Quick Stats with zeros.

### Single Source Only

Produce full structure but include only the available source's section plus Top Priorities and Quick Stats. Omit empty source sections entirely. For unavailable required sources (Email, Calendar, Tasks), note in Quick Stats: "[Source]: unavailable".

### High Volume (20+ High-Priority Items)

When more than 20 items score above 50: cap Top Priorities at 10, append "+[N] more high-priority items. Focus on top 10 first." In quick format, show top 5 with "+[N] more in full sync." Add "High Volume Day" callout at the top of the Notion briefing.

### All Internal Meetings

When every calendar event is an internal sync (no external attendees, recurring, title contains "standup"/"sync"/"1:1"/"check-in"): move Schedule Overview below Email Highlights, reduce meeting base scores by 10, note in Quick Stats "All meetings are internal today."

### Timezone Handling

Use the user's local timezone for all time calculations and display. For cross-timezone meetings, show local time as primary with original timezone in parentheses.

### Stale Source Data

When a source's most recent item predates the overnight window (default: 6 PM previous day), flag as potentially stale. Prepend notice in relevant section: "Data may be stale -- last activity [timestamp]."
