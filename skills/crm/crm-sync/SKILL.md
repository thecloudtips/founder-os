---
name: CRM Sync
description: "Orchestrates the full sync pipeline from Gmail and Calendar data to CRM Communications records in Notion. Activates when the user wants to sync emails or meetings to CRM, log client activities, or asks 'update my CRM with recent communications.' Handles single-item and batch sync with deduplication and error recovery."
---

## Overview

Orchestrate the complete sync pipeline from source data (Gmail, Google Calendar) to CRM Pro Communications database in Notion. The workflow follows a linear pipeline: fetch source data, match to client, generate summary, log activity, report results. Support both single-item sync (one thread or event) and batch mode (scan recent items). Coordinate between the client-matching and activity-logging skills for their respective steps.

This skill handles the top-level workflow orchestration only. Client name resolution and confidence scoring are delegated to the client-matching skill. Communication record creation, deduplication, and summary generation are delegated to the activity-logging skill.

## Single-Item Sync Workflow

### Email Sync (`/founder-os:crm:sync-email [thread_id]`)

Execute the following steps in order:

1. **Fetch**: Use gws CLI (Gmail) to retrieve the email thread by `thread_id`. Extract: subject, participants (from/to/cc), latest message body, sent date, thread length (number of messages). If the thread contains multiple messages, capture the full chronological exchange for context.
2. **Match**: Invoke the client-matching algorithm on all non-user email addresses extracted from the thread participants. Use the highest-confidence match result. If the `--client` flag is provided, skip matching entirely and resolve the specified client name directly against the Companies DB.
3. **Summarize**: Generate an AI summary following the activity-logging skill guidelines. Classify the sentiment of the exchange (positive, neutral, negative). Keep the summary to 2-3 sentences capturing the key topic and any commitments or next steps.
4. **Log**: Create or update a Communications DB record via the activity-logging skill. Link the record to the matched company and contact. Set the activity type to "Email". Pass the thread_id as the source identifier for deduplication.
5. **Confirm**: Display the result to the user: activity logged, client matched (with confidence percentage), summary preview. If the match confidence is MEDIUM or lower, display a warning and ask the user to confirm the match before proceeding.

### Meeting Sync (`/founder-os:crm:sync-meeting [event_id]`)

Execute the following steps in order:

1. **Fetch**: Use Google gws CLI (Calendar) to retrieve the event by `event_id`. Extract: title, description, attendees (with RSVP status), start time, end time, location (physical or virtual meeting link), recurrence info. Calculate the meeting duration in minutes.
2. **Match**: Invoke client-matching on all non-user attendee email addresses. Use the highest-confidence match result. If the `--client` flag is provided, skip matching and resolve the specified client directly.
3. **Summarize**: Generate an AI summary from the meeting title, description, and attendee list. When the description is empty, construct the summary from the title and attendee context alone. Note the meeting duration and attendee count.
4. **Log**: Create or update a Communications DB record via the activity-logging skill. Link to the matched company and contact. Set the activity type to "Meeting". Pass the event_id as the source identifier for deduplication.
5. **Confirm**: Display the result with logged activity details, matched client, and confidence score.

## Batch Mode Workflow

Batch mode processes multiple items from a configurable time window. Use it for catching up on unsynced activities or for regular periodic sync runs.

### Common Batch Logic (Both Email and Meeting)

1. **Scan**: Fetch recent items within the lookback window (default: 7 days, configurable via the `--since` flag). For parsing rules on the `--since` flag format, see `${CLAUDE_PLUGIN_ROOT}/skills/crm/crm-sync/references/sync-patterns.md`.
   - Email: Scan the Gmail sent folder for threads with messages in the date range. Also scan the inbox for received threads if `--include-received` is set.
   - Meeting: Scan Google Calendar for events in the date range. Exclude declined and cancelled events by default.
2. **Filter already-synced**: For each item, check the Communications DB for existing records using the deduplication logic from the activity-logging skill (match on source identifier: thread_id for emails, event_id for meetings). Skip items that already have a synced record. Count these as "Skipped (already synced)" in the batch report.
3. **Process each**: Run the single-item workflow (steps 1-5) for each unsynced item. Process items sequentially to avoid overwhelming the Notion API.
4. **Handle failures**: If client matching fails for an item (no match found and no `--client` override), collect it in the "unmatched" list. Do not halt the batch. Continue processing remaining items. Present the full unmatched list at the end for user resolution.
5. **Report**: Display the batch status report with counts for each outcome category.

### Batch Status Report Format

Present the following report after every batch operation completes:

```
## CRM Sync Complete

**Source**: Gmail Sent / Google Calendar
**Period**: [start_date] to [end_date]
**Duration**: [processing_time]

| Status | Count |
|--------|-------|
| Synced (new) | X |
| Updated (existing) | X |
| Skipped (already synced) | X |
| Unmatched (needs review) | X |
| Failed | X |
| **Total processed** | **X** |

### Unmatched Items (if any)
- [subject/title] -- [email/attendee] -- No CRM match found
```

When all items are successfully synced with zero unmatched and zero failed, append a single confirmation line: "All activities synced successfully."

## Dry Run Mode

When the `--dry-run` flag is set on any command:

- Execute Steps 1-3 (fetch, match, summarize) normally.
- Skip Step 4 entirely. Do NOT write to Notion. Do NOT create or update any Communications DB records.
- Display what WOULD be logged: the full activity details, matched client name with confidence, and generated summary.
- Prefix all output lines with `[DRY RUN]` so the user can clearly distinguish dry run output from actual sync results.
- In batch mode, produce the standard batch status report but with a `[DRY RUN]` header. All items that would have been synced appear under "Synced (new)" or "Updated (existing)" as a preview.
- Use dry run to preview batch operations before committing, especially for large time windows or first-time sync runs.

## Context Command Workflow (`/founder-os:crm:context [client]`)

This command is READ-ONLY. It never writes to the CRM.

1. **Match**: Resolve the client name using the client-matching skill against the Companies DB. Accept fuzzy matches but display the match confidence. If multiple companies match at MEDIUM confidence or above, present a numbered list and ask the user to select.
2. **Fetch CRM data**: Pull from all 4 CRM Pro databases in parallel:
   - **Company profile** from Companies DB: name, status, industry, owner, creation date, any custom properties.
   - **Key contacts** from Contacts DB: all contacts related to the matched company. Display name, email, role, last activity date.
   - **Recent communications** from Communications DB: last 30 days by default, configurable via the `--days` flag. Show activity type, date, summary, and linked contact.
   - **Open deals** from Deals DB: all deals with status not "Closed Won" or "Closed Lost". Show deal name, stage, value, expected close date.
3. **Display**: Format as a concise CRM context view. This is intentionally lighter than P20's `/founder-os:client:load` dossier -- focus on structured CRM data rather than cross-source intelligence gathering. For the detailed output format template, see `${CLAUDE_PLUGIN_ROOT}/skills/crm/crm-sync/references/sync-patterns.md`.

## Error Handling

Handle errors at each step without halting the overall workflow:

- **Unmatched client**: In single-item mode, prompt the user to select from partial matches, manually specify a client, or skip the sync. In batch mode, collect unmatched items silently and present them in the end-of-batch report for bulk resolution.
- **Missing CRM DB**: If the Communications DB does not exist on first sync attempt, search for databases named "[FOS] Communications", "Founder OS HQ - Communications", "Communications", "CRM - Communications", or "CRM Pro - Communications" (in that priority order). If not found, report: "Communications database not found. Ensure the Founder OS HQ workspace template or CRM Pro template is installed in your Notion workspace." Cache the database ID for all subsequent operations within the session.
- **Gmail API error**: Report the specific error message, skip the affected item, and continue processing the batch. Increment the "Failed" counter. Include the failed item subject in a failures list appended to the batch report.
- **Calendar API error**: Handle identically to Gmail errors. Report, skip, continue, count.
- **Notion write error**: If a Communications DB write fails, retry once after a 2-second pause. If the retry also fails, count as "Failed" and continue. Do not retry more than once per item.
- **Partial data**: If an email has no body or a meeting has no description, proceed with available data. Generate a shorter summary from subject/title and participants alone. Never skip an item solely because of missing optional fields.
- **Rate limiting**: If Notion returns a 429 (rate limit) response, pause for 5 seconds and retry. If rate limiting persists across 3 consecutive requests, pause for 30 seconds before resuming. See `${CLAUDE_PLUGIN_ROOT}/skills/crm/crm-sync/references/sync-patterns.md` for detailed rate limiting patterns.

## Lazy Notion DB Creation

If the Communications database does not exist when the first sync operation runs:

1. Search Notion for databases with titles matching "[FOS] Communications", "Founder OS HQ - Communications", "Communications", "CRM - Communications", or "CRM Pro - Communications" (in that priority order).
2. If found, use the existing database. Store its ID for the remainder of the session.
3. If not found, report the absence: "Communications database not found. Ensure the Founder OS HQ workspace template or CRM Pro template is installed in your Notion workspace." Do not create the database automatically.
4. Cache the discovered database ID for all subsequent operations in the session.

Apply the same discovery pattern to the Companies, Contacts, and Deals databases when needed by the `/founder-os:crm:context` command. Search for "[FOS] Companies" first, then "Founder OS HQ - Companies", then fall back to "Companies" or "CRM - Companies". Search for "[FOS] Contacts" first, then "Founder OS HQ - Contacts", then fall back to "Contacts" or "CRM - Contacts". Search for "[FOS] Deals" first, then "Founder OS HQ - Deals", then fall back to "Deals" or "CRM - Deals". Prefer to find existing databases rather than creating new ones.

## Graceful Degradation

- **Notion unavailable**: Cannot proceed. Notion is required for both reading the client list and writing Communication records. Report the error clearly and stop. Do not attempt partial sync to local files.
- **Gmail unavailable**: Cannot sync emails, but can still sync meetings and serve context. Report: "Gmail unavailable -- email sync commands disabled for this session."
- **Calendar unavailable**: Cannot sync meetings, but can still sync emails and serve context. Report: "Google Calendar unavailable -- meeting sync commands disabled for this session."
- **Both Gmail and Calendar unavailable**: Only the `/founder-os:crm:context` command remains functional (reading from Notion only). Report the limitation.

Never fail the entire plugin because a single source is unavailable. Degrade gracefully per source and clearly communicate which commands are available given the current MCP server status.

## Additional Resources

For advanced batch processing patterns, rate limiting strategies, `--since` flag parsing rules, CRM context view format template, cross-plugin integration notes, and batch filter rules, consult `${CLAUDE_PLUGIN_ROOT}/skills/crm/crm-sync/references/sync-patterns.md`.
