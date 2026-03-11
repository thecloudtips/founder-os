---
name: Activity Logging
description: "Creates and manages activity records in the CRM Communications database with AI-generated summaries. Activates when the user wants to log an email or meeting to CRM, record a client interaction, or asks 'save this to the client record.' Handles idempotent operations, deduplication, and AI summarization."
---

## Overview

Create and manage activity records in the CRM Pro Communications database. Each synced email or meeting becomes a Communications record with an AI-generated summary, participant list, and unique identifier for deduplication. The skill ensures idempotent operations -- re-syncing the same activity updates rather than duplicates.

This skill handles the write layer only: activity record creation, summary generation, deduplication, and batch processing. Client resolution (matching email addresses and attendee names to CRM records) is delegated to the client-matching skill. Command-layer orchestration, source data fetching from Gmail and Calendar, and user-facing output formatting are handled by the commands (`crm:sync-email`, `crm:sync-meeting`).

## CRM Pro Communications Database Schema

Search for the database by title: "[FOS] Communications", "Founder OS HQ - Communications", "Communications", or "CRM - Communications" (in that priority order). Use dynamic database discovery -- search by title using the Notion search API, never hardcode database IDs. Prefer "[FOS] Communications" when it exists; otherwise prefer "Founder OS HQ - Communications", then the prefixed form ("CRM - Communications") over the short form. Cache the discovered database ID for the duration of the current command execution.

If the database is not found, report the absence to the calling skill and stop. Error message: "Communications database not found. Ensure the Founder OS HQ workspace template or CRM Pro template is installed in your Notion workspace."

### Required Properties

Create each activity record with these properties:

| Property | Type | Source | Description |
|----------|------|--------|-------------|
| Title | title | Generated | AI summary headline (max 80 chars) |
| Type | select | Mapped | "Email Sent", "Email Received", "Meeting Held", "Meeting Scheduled" |
| Date | date | Source data | ISO 8601 timestamp of when the activity occurred |
| Contact | relation | client-matching skill | Matched contact Notion page ID |
| Company | relation | client-matching skill | Matched company Notion page ID |
| Summary | rich_text | AI-generated | 2-3 sentence summary of content |
| Sentiment | select | AI-classified | "Positive", "Neutral", "Negative" |

For the full list of optional properties beyond this core set, see `${CLAUDE_PLUGIN_ROOT}/skills/crm/activity-logging/references/activity-schema.md`.

## Activity Type Mapping

Map each source activity to the correct Type select value:

| Source | Activity | Type Value |
|--------|----------|------------|
| Gmail sent folder | Email user sent | "Email Sent" |
| Gmail inbox | Email user received | "Email Received" |
| Calendar past event | Meeting that occurred (start time is in the past) | "Meeting Held" |
| Calendar future event | Upcoming meeting (start time is in the future) | "Meeting Scheduled" |

Apply these mapping rules:
1. Determine Gmail folder from the email's label metadata. Emails with the "SENT" label are "Email Sent"; all others default to "Email Received".
2. Determine meeting temporal status by comparing the event's start time to the current timestamp. Events in the past are "Meeting Held"; events in the future are "Meeting Scheduled".
3. When re-syncing a previously logged meeting whose start time has now passed, update the Type from "Meeting Scheduled" to "Meeting Held" as part of the idempotent update.

## AI Summary Generation Guidelines

Generate a concise 2-3 sentence summary for each activity. Write in plain English. Avoid jargon. A founder should understand the gist of the interaction in under 5 seconds.

### Email Summaries

- **Sentence 1**: State what the email was about -- the topic, request, or response being communicated.
- **Sentence 2**: Highlight key decisions, commitments, or action items mentioned in the body.
- **Sentence 3** (include only when substantive): Note next steps or follow-up expectations.

For the Title field, extract the email subject line. Strip "Re:", "Fwd:", "RE:", "FW:", and "Fwd:" prefixes (including nested multiples like "Re: Re: Re:"). Truncate at 80 characters. Capitalize the first letter of the result if it is not already capitalized.

### Meeting Summaries

- **Sentence 1**: State the meeting purpose and list key participants by name.
- **Sentence 2**: Summarize key topics discussed or decisions made, drawing from the event title, description, and any attached notes.
- **Sentence 3** (include only when substantive): Note action items or follow-ups assigned during the meeting.

For the Title field, use the calendar event title directly. Truncate at 80 characters. Do not modify the casing of meeting titles.

### Sentiment Classification

Classify each activity into one of three sentiment values:

- **Positive**: The communication contains enthusiasm, agreement, gratitude, forward momentum, praise, expansion signals, or collaborative tone. Examples: "Great work on the deliverable", "Looking forward to phase 2", "Thanks for the quick turnaround."
- **Neutral**: The communication is factual, routine, or administrative. No strong emotional signals in either direction. Examples: scheduling confirmations, status updates, invoice submissions, routine check-ins.
- **Negative**: The communication contains complaints, concerns, delays, cancellations, frustration, escalation language, or withdrawal signals. Examples: "Disappointed with the timeline", "Need to discuss the missed deadline", "Cancelling our next meeting."

When signals are mixed (e.g., gratitude for past work but concern about upcoming deadlines), classify based on the dominant tone. When truly ambiguous, default to Neutral.

For detailed signal word lists and classification examples for each activity type, see `${CLAUDE_PLUGIN_ROOT}/skills/crm/activity-logging/references/activity-schema.md`.

## Deduplication Strategy

Prevent duplicate records when the same activity is synced multiple times. Use a two-step search before every write operation.

### Email Deduplication

Use the Gmail Thread ID as the logical unique key. First check whether the Communications DB has a "Thread ID" property (an optional rich_text field). If it exists, query by exact Thread ID match for precise deduplication. If the property does not exist, approximate deduplication with a combined search:

1. Before creating a new record, query the Communications DB with a compound filter:
   - Title contains the email subject line (stripped of Re:/Fwd: prefixes), AND
   - Date matches the email date (same calendar day), AND
   - Type is "Email Sent" or "Email Received"
2. If one or more matching records are found: treat the first match as the existing record. Apply the idempotent update logic (see below) rather than creating a new record.
3. If no matching records are found: create a new record with all required properties.

### Meeting Deduplication

Use the Calendar Event ID as the logical unique key. First check whether the Communications DB has a "Thread ID" property (which stores both Thread IDs and Event IDs). If it exists, query by exact Event ID match. If the property does not exist, approximate deduplication with a combined search:

1. Before creating a new record, query the Communications DB with a compound filter:
   - Title contains the meeting title, AND
   - Date matches the event date (same calendar day), AND
   - Type is "Meeting Held" or "Meeting Scheduled"
2. If one or more matching records are found: treat the first match as the existing record. Apply the idempotent update logic.
3. If no matching records are found: create a new record with all required properties.

### Deduplication Search Optimization

When processing a batch of activities, perform the deduplication search as a single bulk query rather than one query per activity. Fetch all Communications records within the date range of the batch, then match locally against each incoming activity. This reduces Notion API calls from O(n) to O(1).

## Idempotent Update Logic

When an existing record is found during deduplication, update it using these rules:

1. **Summary**: Replace the existing summary with the newly generated summary if the new version is longer or more complete. If the existing summary is richer (e.g., manually edited by the user to add context), preserve the existing summary. Detect manual edits by checking whether the existing summary differs structurally from a generated summary pattern.
2. **Type**: Update if the activity status changed. The only valid transition is "Meeting Scheduled" to "Meeting Held" when the meeting's start time has passed. Never downgrade "Meeting Held" back to "Meeting Scheduled".
3. **Sentiment**: Update if the new classification differs from the existing value AND the new data provides a clearer signal (e.g., a longer email thread now available). When the existing Sentiment was set to a non-default value, prefer the existing value unless the new data is substantially different.
4. **Contact and Company relations**: Never overwrite existing relation values with empty values. Only update relations if the new match has a higher confidence score (from the client-matching skill) than the original match. Add newly matched contacts without removing existing ones.
5. **Date**: Do not update the Date field on an existing record. The original activity date is immutable.
6. **Title**: Do not update the Title field on an existing record. Manual title edits by the user must be preserved.

## Batch Write Pattern

When processing multiple activities in a single command invocation (e.g., `crm:sync-email --days=7`), follow this batch sequence:

1. **Collect**: Gather all activities to write into a list. Each item includes the source data, generated summary, mapped type, and client-matching results.
2. **Deduplicate search**: Query the Communications DB once for all records within the batch's date range. Build a local lookup index keyed by Title + Date + Type.
3. **Classify operations**: For each incoming activity, check the local index:
   - Match found: classify as UPDATE operation.
   - No match found: classify as CREATE operation.
   - Activity already exists and no fields differ: classify as SKIP (no write needed).
4. **Execute creates**: Process all CREATE operations first. Write new records to the Communications DB.
5. **Execute updates**: Process all UPDATE operations. Apply the idempotent update rules to each matched record.
6. **Report results**: Return a batch summary to the calling command:
   ```
   created_count: N    // New records written
   updated_count: N    // Existing records updated with new data
   skipped_count: N    // Records unchanged, no write needed
   failed_count: N     // Records that failed to write (with error details)
   unmatched_count: N  // Activities where client-matching returned NONE
   ```

### Batch Size Limits

Process activities in batches of 50. When the total exceeds 50, split into sequential batches of 50 and process each batch fully before starting the next. This avoids Notion API rate limiting. Between batches, pause for 1 second.

## Edge Cases

### Missing Contact or Company Match

When the client-matching skill returns confidence NONE for an activity's participants:
- Still log the activity with Title, Type, Date, Summary, and Sentiment populated.
- Leave the Contact and Company relation properties empty.
- Append a flag to the record: add "[Unmatched]" prefix to the Title field.
- Collect all unmatched activities and surface them to the user at the end of batch processing for manual linking.

### Very Long Email Threads

When an email thread contains more than 10 messages:
- Summarize only the 3 most recent messages in the thread.
- Note the total thread length in the Summary: "Thread contains N messages. Summary covers the latest exchange."
- Use the most recent message's date as the activity Date.

### All-Day Calendar Events

When a calendar event is marked as all-day (no specific start/end time):
- Use the event's date with a time of 00:00:00 in the local timezone.
- Set the Type based on whether the event date is past or future.
- Note in the Summary: "All-day event."

### Recurring Meetings

Each occurrence of a recurring meeting is a separate activity record. Do not collapse recurring instances into a single record. Deduplicate each occurrence independently by matching on both the meeting title and the specific occurrence date.

### Cancelled Meetings

Skip cancelled meetings by default. Do not create Communications records for cancelled events. When the `--include-cancelled` flag is set on the command, log cancelled meetings with:
- Type: "Meeting Scheduled" (regardless of date)
- Append "[Cancelled]" to the Title
- Set Sentiment to "Neutral"

### Draft Emails

Skip draft emails (Gmail "DRAFT" label). Only sync sent and received emails. Draft emails are incomplete communications and should not appear in the CRM activity log.

### Notion API Failure Mid-Batch

When a Notion API call fails during batch processing:
1. Log the failed activity with the error message.
2. Continue processing the remaining activities in the batch. Do not abort the entire batch for a single failure.
3. After the batch completes, report all failures in the batch summary with enough detail for the user to retry manually: "Failed to write: [Title] ([Date]) -- Error: [message]."
4. If more than 50% of writes in a batch fail, pause and warn: "High failure rate detected. Check Notion connectivity before continuing."

### Empty Summary Input

When the source data provides insufficient content to generate a meaningful summary (e.g., an email with an empty body or a meeting with no title):
- For emails with empty body: use the subject line as the full summary. If the subject is also empty, set Summary to "Email with no subject or body content."
- For meetings with no title: set Title to "Untitled Meeting" and generate Summary from the attendee list and time: "Meeting with [attendees] on [date]."

## Graceful Degradation

- **Notion unavailable**: Cannot proceed. The Communications database is required for all write operations. Report the error and stop: "Notion unavailable -- cannot log activities to CRM."
- **client-matching skill unavailable**: Log activities without Contact and Company relations. Set all matches to NONE confidence. Warn: "Client matching unavailable -- activities logged without client associations."
- **Gmail unavailable**: Cannot sync emails. Report the error for email sync commands and stop. Meeting sync commands are unaffected.
- **Calendar unavailable**: Cannot sync meetings. Report the error for meeting sync commands and stop. Email sync commands are unaffected.

Never fail silently. Always report which operations succeeded and which failed.

## Additional Resources

For the detailed activity schema with all optional fields, full summary templates with examples for each activity type, sentiment signal word lists, title generation rules, and error recovery procedures, consult `${CLAUDE_PLUGIN_ROOT}/skills/crm/activity-logging/references/activity-schema.md`.

For the standardized summary format template used during generation, consult `${CLAUDE_PLUGIN_ROOT}/templates/activity-summary.md`.
