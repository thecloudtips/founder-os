---
name: Meeting Context
description: "Deep-dives into a single meeting to build a comprehensive preparation dossier. Activates when the user wants to prep for a specific meeting, research attendees, find related documents, or asks 'what should I know before this call?' Pulls from Calendar, Gmail, Notion CRM, and Google Drive to surface attendee profiles, open items, related docs, and communication history."
globs:
  - "commands/prep.md"
  - "commands/prep-today.md"
  - "teams/agents/calendar-agent.md"
  - "teams/agents/notion-agent.md"
  - "teams/agents/gmail-agent.md"
  - "teams/agents/drive-agent.md"
  - "teams/agents/prep-lead.md"
---

## Overview

Gather deep context for a single calendar event and produce a comprehensive preparation dossier. Unlike daily briefing meeting prep (which processes all meetings at surface level), this skill focuses on one meeting at a time -- deeper attendee profiling, Google Drive document search, and full open items compilation. Treat the calendar event as the anchor, fan out across Gmail, Notion CRM, Notion notes, and Google Drive, then synthesize into an actionable dossier. Degrade gracefully when any source is unavailable.

## Event Identity Resolution

Extract these fields from the target calendar event before enrichment:

| Field | Source | Fallback |
|-------|--------|----------|
| **event_id** | Calendar event ID | Abort if missing |
| **title** | Event summary | "[No Title]" |
| **start_time** | Start datetime | Abort if missing |
| **end_time** | End datetime | start_time + 30 min (mark estimated) |
| **attendees** | Attendee list (email, name, RSVP) | User-only if empty |
| **location** | Location or conferenceData | "Not specified" |
| **description** | Event body | Empty string |
| **recurrence** | RRULE or recurringEventId | null (treat as ad-hoc) |
| **organizer** | Organizer email/name | First attendee |

Validate before proceeding: reject cancelled events, warn on declined events ("You declined this -- proceed anyway?"), flag tentative RSVP in output header, append "[Past event -- prep for reference only]" for events that have already occurred.

## Meeting Classification

Categorize into exactly one type. Classification drives enrichment depth and recommendation style.

| Type | Detection Signals | Enrichment Depth |
|------|-------------------|------------------|
| **external-client** | Attendee domain differs from user's org AND appears in CRM | Maximum -- all sources, full profiles, Drive, deals |
| **one-on-one** | Exactly 2 attendees (user + 1) | Maximum -- deep relationship focus |
| **ad-hoc** | No recurrence; first-time attendee set | High -- extra research, Drive search, inferred agenda |
| **recurring** | Has RRULE; occurred 2+ times | Standard -- delta from last occurrence |
| **group-meeting** | 4+ attendees | Standard -- top attendees profiled, rest listed |
| **internal-sync** | All attendees share org domain; recurring | Light -- agenda + open items only |

Apply in specificity order: external-client > one-on-one > ad-hoc > recurring > group-meeting > internal-sync.

### Importance Scoring (1-5)

| Factor | Weight | 5 | 3 | 1 |
|--------|--------|---|---|---|
| Attendee seniority | 0.30 | C-suite/VP | Manager | Unknown |
| External vs internal | 0.25 | External client | Cross-team | Same-team |
| New vs recurring | 0.25 | First meeting | Ad-hoc, known contacts | Recurring |
| Deal proximity | 0.20 | Negotiation/Proposal stage | Qualified/Lead | No deal or Closed |

Compute weighted sum, round to nearest integer.

## Attendee Context Lookup

Build a deep profile for each attendee via four steps. Process attendees in parallel.

### Step 1: Identity Resolution

1. Extract email, display name, and RSVP status from the event.
2. Classify domain as internal or external.
3. For external: search Notion CRM Contacts by email (exact), then display name (case-insensitive partial), then email domain against CRM Companies.
4. For internal: search Notion for pages linked to the person's name.
5. Record match confidence: "exact" / "name" / "company" / "none".

### Step 2: Gmail Cross-Reference (90-day window)

Search Gmail for threads with each attendee's email. Extract per attendee:

- **Thread count** and **last interaction date/summary**.
- **Unanswered emails**: Threads where attendee sent last message; flag subject, date, days waiting.
- **Recent topics**: Subject lines and summaries of the 5 most recent threads.
- **Sentiment indicators**: Threads containing negative-signal keywords (urgent, disappointed, escalation, overdue, issue, problem, concerned) in last 30 days.

### Step 3: Notion CRM Cross-Reference

When a CRM Contact match exists, retrieve: role/title, company (name, status, industry), contact type (Decision Maker / Champion / User / Influencer / Blocker), all active deals (name, stage, value, close date), last CRM interaction (date, type, summary), relationship status (Active <30d, Cooling 30-90d, Dormant >90d, New), and total communication history depth.

### Step 4: Notion Notes Cross-Reference

Search Notion pages for attendee name, company, and deal names. Extract: all action items (with open/closed status), key decisions from prior meetings, 3 most recent meeting notes mentioning this attendee, and any open commitments the user made to this attendee.

### Attendee Output Structure

```
- Name: [display name] ([RSVP])
- Email: [email] | Match: [exact/name/company/none]
- Role: [title] | Company: [company (status)] | Type: [Decision Maker/etc.]
- Relationship: [Active/Cooling/Dormant/New] | Volume: [N threads, 90d]
- Last Interaction: [date] via [channel] -- [summary]
- Sentiment Flags: [flags] or "None"
- Pending Items: [unanswered emails + open action items]
- Active Deals: [deal, stage, value] or "None"
- Prior Meetings: [3 most recent with dates] or "None found"
```

## Google Drive Document Search

Execute three parallel queries against Google Drive:

1. **Title query**: Documents matching the meeting title (strip "Weekly", "Sync", "Call", "Meeting" first).
2. **Attendee query**: Documents shared with or created by external attendees (180-day window).
3. **Company query**: For external-client meetings, documents containing the company name (180-day window).

Rank results by: modified in last 7 days (+3), modified in last 30 days (+2), shared with attendee (+2), title matches meeting keyword (+2), user-created (+1), presentation or spreadsheet (+1). Surface top 3 with title, type, modified date, link, and one-line relevance note.

## Open Items Compilation

Compile all pending items into four categories. Deduplicate across sources by matching action verb + subject phrase; when an item appears in both email and Notion, keep the richer version and note both sources.

- **You owe**: Unanswered emails to attendees (subject, person, days waiting), open Notion tasks assigned to user involving attendees, overdue commitments from meeting notes or email (item, promised date, days overdue).
- **Owed to you**: User's emails awaiting reply 3+ business days (subject, person, days waiting), Notion tasks assigned to attendees (title, assignee, due date), pending deliverables attendees committed to.
- **Shared/unclear**: Items with ambiguous ownership -- include full context for clarification during meeting.
- **Resolved since last meeting**: For recurring meetings only, items open at last occurrence now resolved (limit 5, include resolution summary).

## Output Format

```
## Meeting Prep: [Title]
**Time**: [start] - [end] ([duration]) | [day, date]
**Type**: [type] | **Importance**: [score]/5
**Location**: [link/room] | **RSVP**: [status]

### Attendees ([count])
[Profiles ordered: external > internal, seniority desc, alpha]
[10+ attendees: top 5 profiled, rest as "Also attending: [names]"]

### Agenda
[Explicit items from description, then [Inferred] items from context]
[Recurring: [New since last meeting] delta items]

### Related Documents
[Top 3 Drive docs: title, type, date, link, relevance]

### Open Items
- **You owe**: [items] | **Owed to you**: [items]
- **Shared**: [items] | **Resolved**: [items, recurring only]

### Recent Context
[Last 5 interactions: date, channel, summary, follow-ups]

### Prep Recommendations
[3-5 tailored to meeting type]
```

Tailor recommendations by type: external-client (deal status, pricing prep, unresolved issues), one-on-one (feedback, tasks, milestones), internal-sync (status, blockers, prior actions), ad-hoc (research attendees, identify purpose), recurring (last-meeting delta, stale items), group-meeting (user's contribution, shared docs, stakeholders).

## Event Filtering Rules

- **Declined**: Exclude unless user explicitly requests prep.
- **Cancelled**: Return error.
- **Tentative**: Include, flag "[Tentative]".
- **All-day**: Include only with attendees, mark "[All-Day]".
- **Focus/OOO blocks**: Skip titles containing "Focus", "Block", "OOO", "Out of Office", "Do Not Book", "No Meetings" (case-insensitive).
- **Solo events**: Skip events with no attendees besides the user.

## Graceful Degradation

Never fail silently. Always state which sources were unavailable and what context is missing.

| Source Unavailable | Fields Affected | Still Produce | Output Note |
|-------------------|-----------------|---------------|-------------|
| **Gmail** | Thread count, email interactions, unanswered emails, sentiment, recent topics | Event details, Notion profiles, Drive docs, Notion action items, agenda | "Gmail not connected -- email history unavailable" |
| **Notion** | Role, company, contact type, deals, relationship status, action items, prior meetings | Event details, email context, Drive docs, unanswered emails, agenda | "Notion not connected -- CRM and notes unavailable" |
| **Google Drive** | Related documents section | All other sections unaffected | "Drive not connected -- document search skipped" |
| **Calendar degraded** | Attendee list may be empty | Work with available fields | "No attendees found -- context limited to title and description" |
| **All sources down** | Everything except calendar fields | Minimal dossier: event details, names, description-based agenda, generic recommendations | "Limited context -- connect Gmail, Notion, and Drive for full prep" |

For partial attendee data: no CRM match but has email = proceed with email-only, mark CRM as "Not found in CRM"; CRM match but no email = proceed with CRM-only, mark as "No recent email history (90d)"; neither = calendar-only, mark as "New contact -- no prior history". Never omit an attendee due to missing data.

## Edge Cases

- **No description**: Infer agenda from title, email threads, and Drive docs. Flag: "Agenda inferred -- no event description provided."
- **10+ attendees**: Profile top 5 (external first, then active deals, then recent interactions, then organizer). List rest as "Also attending" with name/email/RSVP only. Still compile open items for all.
- **Changed attendees on recurring**: Compare with last instance. Highlight "New this session: [names]" and "Not attending: [names]". Full profile for newly added attendees.
- **Past events**: Generate prep for reference. Adjust recommendations to retrospective: "Review what was discussed" not "Prepare to discuss."
- **Overlapping events**: Flag: "Scheduling conflict: overlaps with [title] [time]-[time]."
- **Forwarded invites**: When organizer differs from inviter, note both and profile both as key attendees.
