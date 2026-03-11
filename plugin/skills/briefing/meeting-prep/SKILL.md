---
name: Meeting Preparation
description: "Analyzes today's calendar events and generates meeting prep notes with attendee context, pending items, and communication history. Activates for meeting preparation, calendar review, daily meeting summaries, or 'who am I meeting with today?' Classifies meetings by type, scores importance, and cross-references attendees against Gmail and Notion CRM."
globs:
  - "teams/agents/calendar-agent.md"
---

## Overview

Analyze today's calendar events and generate structured preparation notes for each meeting. For every event, extract attendee identities, cross-reference them with Gmail and Notion for relationship context, surface pending action items and unanswered communications, and produce a prioritized prep brief. Treat calendar data as the primary source for scheduling facts (time, duration, recurrence, attendees) while enriching with email history and CRM data. Process all meetings in start-time order, flag high-priority meetings for attention, and degrade gracefully when enrichment sources are unavailable.

## Meeting Classification Framework

Categorize every calendar event into exactly one meeting type. Classification drives the depth of prep notes generated and the enrichment sources consulted.

### Meeting Types

| Type | Detection Signals | Prep Depth |
|------|-------------------|------------|
| **external-client** | Attendee email domains differ from user's org domain; attendee appears in CRM Contacts or Companies | Full (all sources) |
| **internal-sync** | All attendees share the user's org domain; recurring cadence (weekly/biweekly) | Light (agenda + open items only) |
| **one-on-one** | Exactly 2 attendees (user + 1 other) | Full (relationship-focused) |
| **group-meeting** | 4+ attendees, mixed domains or single domain | Standard (agenda + key attendee context) |
| **recurring** | Event has recurrence rule (RRULE); has occurred at least twice before | Standard (delta from last occurrence) |
| **ad-hoc** | No recurrence rule; first-time event with these attendees | Full (extra context needed) |

Apply classification rules in specificity order: external-client > one-on-one > ad-hoc > recurring > group-meeting > internal-sync. When multiple types apply (e.g., a recurring one-on-one with a client), select the most specific type -- in this example, external-client.

### Meeting Importance Scoring

Score each meeting 1-5 to determine prep priority and output ordering. Calculate from four weighted factors:

| Factor | Weight | Scoring |
|--------|--------|---------|
| Attendee seniority | 0.30 | 5 if C-suite/VP present, 4 if Director, 3 if Manager, 2 if IC, 1 if unknown |
| External vs internal | 0.25 | 5 if external client/partner, 3 if cross-team internal, 1 if same-team internal |
| New vs recurring | 0.25 | 5 if first meeting with any attendee, 3 if ad-hoc with known contacts, 1 if recurring |
| Deal proximity | 0.20 | 5 if attendee linked to active deal in Negotiation/Proposal stage, 3 if Qualified/Lead stage, 1 if no deal or Closed |

Compute weighted sum and round to nearest integer. Meetings scoring 4-5 receive a priority flag in the output.

## Attendee Context Lookup

For each attendee on a calendar event, build a context profile by cross-referencing available data sources. Process attendees in parallel when possible.

### Step 1: Identity Resolution

1. Extract attendee email address and display name from the calendar event.
2. Determine domain -- classify as internal (matches user's org domain) or external.
3. For external attendees, search Notion CRM Contacts database by email address (exact match). If no match, search by display name using case-insensitive partial matching.
4. For internal attendees, search Notion for any pages or database entries linked to the person's name.

### Step 2: Gmail Cross-Reference

Search Gmail for threads involving each attendee's email address within the last 90 days.

Extract per attendee:
- **Thread count**: Total number of email threads in the window.
- **Last interaction date**: Date of the most recent email sent or received.
- **Last interaction summary**: Subject line and one-sentence summary of the most recent thread.
- **Unanswered emails**: Threads where the attendee sent the last message and the user has not replied. Flag these as pending responses.
- **Recent topics**: Subject lines of the 3 most recent threads, used to identify likely discussion topics for the meeting.

### Step 3: Notion CRM Cross-Reference

When a CRM Contact match exists, retrieve:
- **Role/Title**: Job title or organizational role.
- **Company**: Parent company name and status (Active, Prospect, Churned, Partner).
- **Contact type**: Decision Maker, Champion, User, Influencer, or Blocker.
- **Related deals**: Active deals linked to the contact's company -- extract deal name, stage, and value.
- **Last CRM interaction**: Most recent Communications entry for this contact -- date, type, and summary.
- **Relationship status**: Derive from last contact date -- Active (<30 days), Cooling (30-90 days), Dormant (>90 days).

### Step 4: Notion Notes Cross-Reference

Search Notion pages for the attendee's name or company name:
- Extract action items assigned to or by the attendee from meeting notes.
- Extract decisions made in previous meetings involving the attendee.
- Identify the most recent meeting note that mentions the attendee, and extract its date and key outcomes.

### Attendee Context Output

Assemble per-attendee context into this structure:

```
- Name: [display name]
- Email: [email]
- Role: [title at company] or "Unknown"
- Company: [company name] or "Internal"
- Contact Type: [Decision Maker/Champion/etc.] or "N/A"
- Relationship Status: [Active/Cooling/Dormant/New]
- Last Interaction: [date] via [email/meeting/note] -- [one-line summary]
- Pending Items: [list of unanswered emails or open action items]
- Active Deals: [deal name, stage] or "None"
```

## Prep Note Generation

Generate one prep note per calendar event. Structure every prep note with the same sections for consistency.

### Agenda Summary

1. Check the event description field for an existing agenda. If present, extract and reformat as bullet points.
2. If no description exists, infer likely agenda topics from: the event title, recent email threads with attendees (subject lines), and any open action items involving attendees.
3. For recurring meetings, compare with the last occurrence -- surface any items that were discussed but not resolved, and any new items that emerged since the last meeting.
4. Limit inferred agenda to 3-5 items. Label inferred items as "[Inferred]" to distinguish from explicit agenda points.

### Attendee Context Section

Include the attendee context output (from the lookup step above) for each participant. Order attendees by: external before internal, then by seniority (highest first), then alphabetically.

### Open Items

Compile all pending items related to the meeting's attendees and topics:
- **Unanswered emails**: Threads where the user owes a response to any attendee.
- **Pending action items**: Tasks from Notion or previous meeting notes assigned to the user that involve any attendee.
- **Overdue commitments**: Items promised to attendees that are past their expected completion date.
- **Awaiting from others**: Items where attendees owe the user a response or deliverable.

Deduplicate by matching action verb + subject phrase. When the same item appears in both email and Notion, keep the version with more context and note both sources.

### Recent Communications Summary

Summarize the last 3 relevant interactions with the meeting's attendees (across email, calendar, and notes). For each interaction include:
- Date and channel (email/meeting/note).
- One-sentence summary of what was discussed or decided.
- Any follow-up items that resulted.

Sort by date, most recent first.

### Preparation Recommendations

Generate 2-4 actionable recommendations tailored to the meeting type and context:

| Meeting Type | Recommendation Focus |
|-------------|---------------------|
| external-client | Review deal status, prepare answers to likely pricing/timeline questions, note any unresolved issues |
| one-on-one | Review pending feedback items, check on previously assigned tasks, note career or project milestones |
| internal-sync | Prepare status update, flag blockers, review action items from last sync |
| ad-hoc | Research attendees if new contacts, prepare introductory context, review the meeting request thread |
| recurring | Review notes from last occurrence, prepare delta updates, flag stale recurring items for removal |
| group-meeting | Identify the user's expected contribution, prepare any assigned presentation materials, review shared documents |

## Output Format

Order all meetings by start time. Place priority-flagged meetings (importance score 4-5) at the top of the output regardless of time, under a "Priority Meetings" header.

### Per-Meeting Structure

```
### [Meeting Title]
**Time**: [start time] - [end time] ([duration])
**Type**: [meeting type] | **Importance**: [score]/5 [PRIORITY flag if 4-5]
**Location**: [meeting link or room] or "Not specified"

#### Attendees
[Attendee context blocks, one per participant]

#### Agenda
[Bullet list -- explicit agenda items first, then inferred items marked with [Inferred]]

#### Open Items
- **You owe**: [items the user needs to address before or during this meeting]
- **Owed to you**: [items attendees should be delivering]
- **Overdue**: [past-due items involving any attendee]

#### Recent Context
[Last 3 interactions summary]

#### Prep Recommendations
[2-4 actionable recommendations]
```

## Event Filtering Rules

Not all calendar events warrant prep notes. Apply these filters before processing:

- **Skip declined events**: RSVP status is "declined" -- exclude entirely.
- **Skip cancelled events**: Event status is "cancelled" -- exclude entirely.
- **Include tentative events**: RSVP status is "tentative" -- include but append a "[Tentative]" flag to the meeting title.
- **All-day events**: Include only if they have attendees (skip all-day reminders, holidays, or blocks with no attendees). Mark as "[All-Day]" in the time field.
- **Focus time / OOO blocks**: Skip events where the title contains "Focus", "Block", "OOO", "Out of Office", "Do Not Book", or "No Meetings" (case-insensitive).
- **Events with no attendees**: Skip events where the user is the only participant (personal calendar blocks).

## Graceful Degradation

Produce useful prep notes even when enrichment sources are unavailable.

### Gmail Unavailable
- Set attendee "Last Interaction" and "Pending Items" from email to "Email data unavailable".
- Skip the unanswered emails section under Open Items.
- Omit email-sourced entries from Recent Communications Summary.
- Still produce agenda summary, attendee list (from calendar data), and basic prep recommendations.
- Note in the prep output: "Email context unavailable -- prep notes based on calendar and Notion data only."

### Notion Unavailable
- Set attendee Role, Company, Contact Type, and Active Deals to "CRM data unavailable".
- Skip action items from Notion notes under Open Items.
- Omit note-sourced entries from Recent Communications Summary.
- Still produce agenda summary (from event description and title), attendee list (names and emails from calendar), and basic prep recommendations.
- Note in the prep output: "CRM/notes context unavailable -- prep notes based on calendar and email data only."

### Both Gmail and Notion Unavailable
- Produce a minimal prep note using only calendar data: meeting title, time, duration, attendee names and emails, location, and event description.
- Generate basic prep recommendations based on meeting type classification alone.
- Note in the prep output: "Limited context available -- prep notes based on calendar data only. Connect Gmail and Notion for enriched preparation."

### Partial Data
- When an attendee has no CRM match but does have email history, proceed with email-only context. Mark CRM fields as "Not found in CRM".
- When an attendee has a CRM match but no email history, proceed with CRM-only context. Mark email fields as "No recent email history".
- Never omit an attendee from the prep note due to missing enrichment data. Always include at minimum their name and email from the calendar event.

## Edge Cases

### Events with No Description
Rely on title-based topic inference and attendee email history to build the agenda summary. Flag the agenda as entirely inferred: "No event description provided -- agenda inferred from context."

### Large Meetings (10+ Attendees)
Limit individual attendee context to the top 5 most relevant attendees, determined by: external contacts first, then contacts with active deals, then contacts with recent interactions. List remaining attendees by name only under a "Also attending" subsection.

### Back-to-Back Meetings
When two meetings are scheduled with zero gap between them, flag the transition in both prep notes: "Immediately followed by [next meeting title]" and "Immediately preceded by [previous meeting title]". Suggest preparing materials for both meetings in advance.

### Recurring Meeting with Changed Attendees
When a recurring meeting instance has attendees added or removed compared to the recurring series definition, highlight the delta: "New this session: [names]" and "Not attending this session: [names]".

### Same Attendee in Multiple Meetings
Compute attendee context once and reuse across all meetings for that attendee. Do not repeat the full cross-reference lookup. Reference the first meeting's attendee block and note "See [first meeting title] for full context" in subsequent appearances.
