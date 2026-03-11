# Activity Schema

Complete property schema, summary templates, sentiment classification signals, title generation rules, and batch processing guidance for the activity-logging skill. Consult this reference when creating or updating Communications records in the CRM Pro Notion database.

## Full Communications DB Property Schema

### Required Properties

These properties must be populated on every activity record. See the SKILL.md for sourcing and generation rules.

| Property | Notion Type | Constraints | Description |
|----------|-------------|-------------|-------------|
| Title | title | Max 80 chars | AI summary headline or cleaned subject/event title |
| Type | select | Enum: "Email Sent", "Email Received", "Meeting Held", "Meeting Scheduled" | Activity classification |
| Date | date | ISO 8601 with timezone | When the activity occurred |
| Contact | relation | → Contacts DB | Matched contact Notion page ID from client-matching skill |
| Company | relation | → Companies DB | Matched company Notion page ID from client-matching skill |
| Summary | rich_text | Max 2000 chars | AI-generated 2-3 sentence summary |
| Sentiment | select | Enum: "Positive", "Neutral", "Negative" | AI-classified communication tone |

### Optional Properties

Populate these properties when the source data provides the information. Do not create these properties on the Notion database -- they exist only when the CRM Pro template includes them. Check for their existence before writing. Skip silently if the property does not exist on the database.

| Property | Notion Type | Constraints | Description |
|----------|-------------|-------------|-------------|
| Direction | select | Enum: "Inbound", "Outbound" | Whether the user initiated or received the communication |
| Channel | select | Enum: "Email", "Meeting", "Call", "Chat" | Communication channel (always "Email" or "Meeting" for this plugin) |
| Thread ID | rich_text | Gmail Thread ID or Calendar Event ID | Source system unique identifier for deduplication |
| Participants | rich_text | Comma-separated names | All participants in the activity beyond the primary contact |
| Attachments | checkbox | true/false | Whether the email had attachments or the meeting had shared documents |
| Duration | number | Minutes | Meeting duration in minutes (meetings only) |
| Follow-Up Required | checkbox | true/false | Whether the summary indicates pending action items or follow-ups |
| Tags | multi_select | Free-form | Topic tags extracted from the content (e.g., "invoice", "proposal", "feedback") |
| Source | rich_text | Max 200 chars | Origin identifier: "Gmail Sync" or "Calendar Sync" |
| Synced At | date | ISO 8601 | Timestamp when the record was written to Notion (not the activity date) |

### Direction Mapping

Determine the Direction value from the activity Type:

| Type | Direction |
|------|-----------|
| Email Sent | Outbound |
| Email Received | Inbound |
| Meeting Held | Inbound (default -- meetings are bilateral) |
| Meeting Scheduled | Inbound (default) |

Override the default for meetings when the user is the event organizer: set Direction to "Outbound" if the user's email address matches the event organizer field.

## Summary Templates and Examples

### Email Sent Example

**Source data:**
- Subject: "Re: Q3 Website Redesign Proposal"
- Body: Discussion about revised pricing for the website redesign project. User confirms the $15,000 budget and requests a kickoff meeting next week.
- Recipient: Sarah Chen at Brightwave Digital

**Generated record:**
```
Title:       Q3 Website Redesign Proposal
Type:        Email Sent
Date:        2026-02-28T14:23:00-10:00
Contact:     [Sarah Chen page ID]
Company:     [Brightwave Digital page ID]
Summary:     Confirmed the $15,000 budget for the Q3 website redesign project
             with Brightwave Digital. Requested a kickoff meeting next week to
             align on deliverables and timeline.
Sentiment:   Positive
Direction:   Outbound
```

### Email Received Example

**Source data:**
- Subject: "Fwd: Re: Invoice #2847 Payment Status"
- Body: Client reports that payment for invoice #2847 was delayed due to internal accounting review. Expects payment within 5 business days. Apologizes for the delay.
- Sender: Marcus Rivera at Coral Bay Properties

**Generated record:**
```
Title:       Invoice #2847 Payment Status
Type:        Email Received
Date:        2026-02-27T09:15:00-10:00
Contact:     [Marcus Rivera page ID]
Company:     [Coral Bay Properties page ID]
Summary:     Marcus Rivera reported that payment for invoice #2847 is delayed
             due to an internal accounting review at Coral Bay Properties.
             Payment is expected within 5 business days.
Sentiment:   Neutral
Direction:   Inbound
```

### Meeting Held Example

**Source data:**
- Event title: "Monthly Retainer Review - Island Breeze Co"
- Description: "Review October deliverables, discuss November priorities"
- Attendees: Lani Kahale, David Park, user
- Start time: 2026-02-26T10:00:00-10:00 (past)
- Duration: 45 minutes

**Generated record:**
```
Title:       Monthly Retainer Review - Island Breeze Co
Type:        Meeting Held
Date:        2026-02-26T10:00:00-10:00
Contact:     [Lani Kahale page ID]
Company:     [Island Breeze Co page ID]
Summary:     Monthly retainer review with Lani Kahale and David Park from
             Island Breeze Co. Covered October deliverables and discussed
             priorities for November.
Sentiment:   Neutral
Direction:   Inbound
Duration:    45
```

### Meeting Scheduled Example

**Source data:**
- Event title: "Discovery Call - New Client: Pacific Edge Labs"
- Description: empty
- Attendees: Kenji Tanaka, user
- Start time: 2026-03-05T14:00:00-10:00 (future)
- Duration: 30 minutes

**Generated record:**
```
Title:       Discovery Call - New Client: Pacific Edge Labs
Type:        Meeting Scheduled
Date:        2026-03-05T14:00:00-10:00
Contact:     [Kenji Tanaka page ID]
Company:     [Pacific Edge Labs page ID]
Summary:     Discovery call scheduled with Kenji Tanaka from Pacific Edge Labs
             to explore a potential new engagement. No agenda provided.
Sentiment:   Neutral
Direction:   Outbound
Duration:    30
```

## Sentiment Classification Signal Words

Use these signal word lists to inform sentiment classification. These are indicators, not strict rules -- evaluate signals in context. A signal word used sarcastically or negatively inverts its meaning.

### Positive Indicators

Classify as Positive when 2 or more of these signals are present, or when 1 strong signal dominates the tone:

**Gratitude signals:**
- "thank you", "thanks so much", "many thanks", "appreciate", "grateful"

**Enthusiasm signals:**
- "excited", "thrilled", "great news", "fantastic", "excellent", "amazing"
- "love it", "perfect", "exactly what we needed", "well done"

**Forward momentum signals:**
- "looking forward to", "let's proceed", "ready to move forward", "next steps"
- "can't wait to get started", "eager to begin", "phase 2", "expand", "scale up"

**Agreement signals:**
- "sounds good", "I agree", "approved", "green light", "go ahead"
- "on board", "aligned", "makes sense", "confirmed"

**Praise signals:**
- "great work", "outstanding", "exceeded expectations", "impressed"
- "above and beyond", "top-notch", "highly recommend"

### Neutral Indicators

Classify as Neutral when the communication is primarily factual, administrative, or informational with no strong emotional signals:

**Administrative signals:**
- "please find attached", "as discussed", "for your records", "FYI"
- "scheduling", "confirming", "following up on", "as agreed"

**Status update signals:**
- "update on", "progress report", "status:", "completed", "in progress"
- "on track", "per the timeline", "milestone reached"

**Routine signals:**
- "weekly sync", "monthly review", "check-in", "agenda for"
- "minutes from", "recap", "summary of", "as planned"

### Negative Indicators

Classify as Negative when 1 or more of these signals are present. Negative signals carry more weight than positive signals -- a single strong negative indicator overrides multiple mild positive signals.

**Frustration signals:**
- "disappointed", "concerned", "unacceptable", "not satisfied"
- "still waiting", "falling behind", "missed deadline", "dropped the ball"
- "frustrating", "not what I expected", "per my last email"

**Escalation signals:**
- "need to escalate", "speak with your manager", "formal complaint"
- "legal", "breach", "termination", "cancel", "reconsider our arrangement"
- "putting you on notice", "SLA violation", "written notice"

**Delay and problem signals:**
- "delayed", "pushed back", "postponed", "on hold", "blocked"
- "issue with", "problem with", "broken", "failed", "regression"
- "cannot proceed", "unable to", "unfortunately"

**Withdrawal signals:**
- "pausing the project", "stepping back", "need to reevaluate"
- "reconsidering", "exploring other options", "considering alternatives"

## Title Generation Rules

Apply these rules when generating the Title property for a Communications record:

### Prefix Stripping

Remove these prefixes from email subject lines. Apply stripping iteratively until no more prefixes remain (handles nested prefixes like "Re: Fwd: Re:"):

- `Re:` and `RE:` (with or without trailing space)
- `Fwd:` and `FWD:` and `FW:` (with or without trailing space)
- `[EXTERNAL]` and `[EXT]` (common email gateway tags)
- `Automatic reply:` and `Auto:` (out-of-office prefixes)

### Formatting

1. After stripping prefixes, trim leading and trailing whitespace.
2. If the first character is lowercase, capitalize it.
3. Do not otherwise modify casing -- preserve the original casing from the source.
4. If the result exceeds 80 characters, truncate to 77 characters and append "..." to indicate truncation.
5. If the result is empty after stripping (subject was only prefixes), set Title to "Untitled Email" for emails or "Untitled Meeting" for meetings.

### Meeting Titles

Use the calendar event title directly without prefix stripping. Meeting titles do not have Re:/Fwd: conventions. Apply only the length truncation rule (80 chars max with "..." suffix).

### Special Characters

Preserve special characters in titles. Do not strip or escape characters like `#`, `&`, `@`, `/`, or parentheses. These often carry meaning in subject lines (e.g., "Invoice #2847", "Q&A Session").

## Batch Processing Limits and Recommendations

### Rate Limiting

- **Notion API limit**: Respect the Notion API rate limit of 3 requests per second for the integration token.
- **Batch size**: Process a maximum of 50 activity records per batch. Split larger sets into sequential batches.
- **Inter-batch pause**: Wait 1 second between batches to avoid rate limit bursts.
- **Retry policy**: When a single Notion API call returns a 429 (rate limited) or 5xx (server error), wait 2 seconds and retry once. If the retry fails, log the activity as failed and continue with the next item.

### Recommended Batch Sizes by Command

| Command | Typical Volume | Recommended Batch Size |
|---------|---------------|----------------------|
| `crm:sync-email --days=1` | 10-30 emails | Single batch (no splitting needed) |
| `crm:sync-email --days=7` | 50-200 emails | Batches of 50 |
| `crm:sync-email --days=30` | 200-1000 emails | Batches of 50, warn user about duration |
| `crm:sync-meeting --days=7` | 5-20 meetings | Single batch |
| `crm:sync-meeting --days=30` | 20-80 meetings | Batches of 50 |

### Progress Reporting

For batches exceeding 50 items, report progress after each batch completes:
```
Batch 1/4 complete: 48 created, 2 updated, 0 failed
Batch 2/4 complete: 45 created, 3 updated, 2 failed
...
```

## Error Recovery

### Notion API Failure Mid-Batch

When the Notion API becomes unavailable during batch processing:

1. **Capture state**: Record which activities have been successfully written and which remain unprocessed.
2. **Report partial results**: Output the batch summary with all successful writes and a list of unprocessed items.
3. **Provide retry guidance**: Tell the user how to resume: "N activities were not synced. Re-run the command with the same parameters -- deduplication will skip already-synced records and process only the remaining items."
4. **Do not roll back**: Successfully written records remain in the Communications DB. The idempotent design ensures re-running the full batch is safe -- duplicates will be detected and skipped.

### Stale Database Cache

When a cached database ID becomes invalid (Notion returns 404 for the database):

1. Clear the cached database ID.
2. Re-run dynamic database discovery to find the current database.
3. If discovery fails, report: "Communications database not found. It may have been deleted or renamed. Check your Notion workspace."
4. Do not attempt to create a new Communications database -- the CRM Pro template manages database lifecycle.

### Malformed Source Data

When source data from Gmail or Calendar is incomplete or malformed:

1. **Missing date**: Skip the activity. Log: "Skipped activity with missing date: [Title or subject]."
2. **Missing subject/title**: Proceed with "Untitled Email" or "Untitled Meeting" as the Title. Generate Summary from body content or attendee list.
3. **Invalid email addresses in participants**: Skip matching for that participant. Log the invalid address. Still create the activity record with whatever valid matches were found.
4. **Encoding issues**: When text contains garbled characters from encoding mismatches, process the readable portions. Note in Summary: "Some content could not be decoded."

### Conflict Resolution

When two batch operations race against each other (e.g., user runs two sync commands simultaneously):

1. The deduplication search will catch most conflicts -- the second write will find the first write's records and update rather than duplicate.
2. If a true conflict occurs (two creates for the same activity happen before either dedup search completes), the result is two records with similar titles and dates. On the next sync run, the dedup search will find both records and update the first match, leaving the second as an orphan.
3. Advise users to avoid running concurrent sync commands against the same date range. The commands are designed for sequential execution.
