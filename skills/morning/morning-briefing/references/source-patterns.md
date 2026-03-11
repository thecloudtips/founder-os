# Source Patterns Reference

Detailed per-source query construction, extraction rules, filtering logic, and edge case handling for the morning-briefing skill's five-source gathering pipeline. Each section covers one source in the pipeline order defined in `${CLAUDE_PLUGIN_ROOT}/skills/morning/morning-briefing/SKILL.md`.

---

## Gmail Patterns

### Query Construction

Build Gmail search queries using the gws CLI (Gmail) `search_emails` tool. Construct the primary query as:

```
is:unread after:{cutoff_date}
```

Format `cutoff_date` as `YYYY/MM/DD` (Gmail search uses forward slashes, not hyphens). When the overnight window spans a single calendar day, this query captures all unread emails from that day forward. When the window crosses midnight, the `after:` filter uses the earlier date, and apply timestamp-level filtering on the results to exclude messages outside the precise window.

For workspaces with high email volume (more than 50 unread results), add a secondary query to ensure high-priority emails are not missed:

```
is:unread after:{cutoff_date} (is:important OR label:starred)
```

Merge results from both queries, deduplicating by message ID.

### Thread Collapsing Rules

Gmail threads may contain multiple unread messages. Collapse each thread to a single entry:

1. Group unread messages by thread ID.
2. Select the latest message in the thread (most recent `internalDate`) as the representative.
3. Use the representative message for all extracted fields except thread count.
4. Set thread count to the number of unread messages in the thread.
5. Apply the highest applicable quadrant from any message in the thread. If one message classifies as Q2 but a later reply classifies as Q1, assign Q1 to the thread entry.
6. Use the latest message's timestamp for recency weighting.

### Priority Signal Keywords

Scan the subject line and first 200 characters of the body for these keyword categories. Perform case-insensitive whole-word matching.

**Urgency keywords** (push toward Q1 or Q3):
- "urgent", "ASAP", "deadline", "overdue", "time-sensitive", "immediate", "EOD", "end of day", "expires today", "final notice", "last chance", "action required today"

**Importance keywords** (push toward Q1 or Q2):
- "action required", "approval needed", "please review", "signature required", "invoice", "proposal", "contract", "escalation", "blocking", "critical", "budget", "revenue", "client issue"

**Low-priority keywords** (push toward Q3 or Q4):
- "FYI", "no action needed", "for your records", "newsletter", "digest", "unsubscribe", "weekly update", "automated notification", "noreply", "do-not-reply"

Apply keyword signals as modifiers, not overrides. A "newsletter" from a Tier 1 client still warrants classification as Q2 rather than Q4. When urgency and importance keywords co-occur, classify as Q1.

### Sender Tier Classification

Classify each sender into one of six tiers. Use any available context from CRM data (P20/P21 Notion databases), prior interaction history, or the user's contact metadata.

| Tier | Description | Examples | Quadrant Influence |
|------|-------------|----------|--------------------|
| Tier 1: Key clients | Contacts associated with active client accounts, deals, or projects | Client project leads, account holders | Push toward Q1 or Q2 |
| Tier 2: Leadership | Direct manager, C-suite executives, board members | CEO, CTO, VP, direct supervisor | Push toward Q1 or Q2 |
| Tier 3: Direct reports | Team members who report to the user | Engineers, designers, coordinators on user's team | Push toward Q2 |
| Tier 4: External VIPs | High-value external contacts without active client status | Investors, advisors, key partners, prospects | Push toward Q2 |
| Tier 5: Known internal | Colleagues and cross-functional peers | Other department leads, internal collaborators | Neutral |
| Tier 6: Unknown external | First-time senders, cold outreach, unrecognized domains | Recruiters, sales outreach, unknown addresses | Push toward Q3 or Q4 |

When sender identity cannot be resolved (no CRM match, no prior history), default to Tier 6 unless the email domain matches the user's organization (then default to Tier 5).

### Highlight Extraction Fields

For each email qualifying as a briefing highlight, extract the following structured record:

| Field | Description | Format | Max Length |
|-------|-------------|--------|------------|
| sender | Display name and email address | "Jane Smith (jane@acme.com)" | -- |
| subject | Full subject line, truncated | Plain text | 80 characters |
| summary | One-line core content summary | Plain text, English | 100 characters |
| quadrant | Eisenhower matrix assignment | Q1, Q2, or Q3 | -- |
| action_needed | Whether user must act | "Yes: [action phrase]" or "No" | -- |
| recency | When the email arrived | Relative timestamp ("2h ago", "yesterday") | -- |
| thread_count | Unread messages in thread | Integer (1 if standalone) | -- |

**Summary generation rules:**
1. Extract the first substantive sentence from the body (skip greetings, pleasantries, quoted text, signatures).
2. Truncate at the nearest word boundary if exceeding 100 characters, append "...".
3. For empty bodies or attachment-only emails, use "Attachment: [filename]" or "Empty body -- subject only."
4. For calendar invites, use "Meeting invite: [event title] on [date/time]."
5. For forwarded emails, summarize the forwarding sender's intent, not the forwarded content.

### Gmail Edge Cases

**Partial results**: When the Gmail API returns a timeout or rate limit error mid-fetch, process whatever emails were retrieved. Append metadata: `partial_note: "Scanned N of estimated M unread emails."` Set source status to "partial".

**Zero unread**: Return email count 0, empty highlights list, status "available". Do not generate placeholder content.

**Reply-all storms**: When a thread accumulates 5+ messages within 1 hour from 3+ distinct senders and the content is repetitive (acknowledgments, "+1", "thanks"), collapse to a single Q4 entry and exclude from highlights.

**Foreign language emails**: Extract sender and subject in the original language. Generate the summary in English. Note the detected language in parentheses after the summary when it is not English.

---

## Calendar Patterns

### Query Construction

Fetch today's events using the Google gws CLI (Calendar) tools. Query the user's primary calendar for events where:
- `timeMin` = start of today (00:00:00 in user's local timezone, converted to UTC).
- `timeMax` = end of today (23:59:59 in user's local timezone, converted to UTC).
- `singleEvents` = true (expand recurring events into individual instances).
- `orderBy` = startTime.

When the user's timezone is unknown, default to the system timezone and note the assumption in output metadata.

### Event Filtering

Exclude events matching any of these criteria (check in order):

1. **Declined events**: Attendee response status is "declined" for the current user.
2. **Cancelled events**: Event status field is "cancelled".
3. **Focus/OOO blocks**: Title contains "Focus", "Focus Time", "Block", "Blocked", "OOO", "Out of Office", "Do Not Disturb" (case-insensitive substring match). Also match common calendar app auto-created focus blocks: "Focus time" (Google Calendar), "Focus Plan" (Viva).
4. **Personal reminders**: Event has zero attendees (only the organizer, who is the current user). Exception: retain the event if the title contains "deadline", "due", or "launch" (personal deadline reminders are relevant).

Log the count of filtered events in metadata: `events_filtered: N`.

### Meeting Type Classification

Classify each surviving event into exactly one type. Apply rules in priority order -- first match wins:

| Priority | Type | Detection Rule |
|----------|------|----------------|
| 1 | external-client | At least one attendee email domain differs from the user's domain AND (event title matches known client name OR attendee matches CRM contact) |
| 2 | one-on-one | Exactly 2 attendees total (user + 1 other) |
| 3 | ad-hoc | Non-recurring event with 3+ attendees, created within the last 48 hours |
| 4 | recurring | Event has a recurrence rule (`recurrence` field is non-empty) |
| 5 | group-meeting | 5+ attendees, non-recurring |
| 6 | internal-sync | Default fallback for all events not matching above rules |

When CRM data is unavailable for external-client detection, fall back to domain comparison only: any attendee with an email domain different from the user's domain triggers external-client classification.

### Importance Scoring

Score each event from 1 to 5 using four weighted factors. Compute each factor as a 0-1 normalized value, multiply by weight, sum, and scale to 1-5.

| Factor | Weight | Scoring Logic |
|--------|--------|---------------|
| Attendee seniority | 0.30 | 1.0 if any attendee title contains "CEO", "CTO", "VP", "Director", "Head of", "C-suite", "Board"; 0.5 if "Manager", "Lead", "Senior"; 0.0 otherwise |
| External vs internal | 0.25 | 1.0 if meeting type is external-client; 0.5 if any external attendee present; 0.0 if all internal |
| New vs recurring | 0.25 | 1.0 if first occurrence (no recurrence rule and no prior instance in last 30 days); 0.5 if recurring but infrequent (monthly or less); 0.0 if weekly or more frequent |
| Deal proximity | 0.20 | 1.0 if event title or attendees match an active deal/proposal in CRM; 0.5 if match to a known client without active deal; 0.0 if no CRM match |

**Score mapping**: Raw weighted sum ranges from 0.0 to 1.0. Map to integer scale: 0.0-0.2 = 1, 0.2-0.4 = 2, 0.4-0.6 = 3, 0.6-0.8 = 4, 0.8-1.0 = 5.

When CRM data is unavailable, default deal proximity to 0.0 and note the limitation.

### Event Extraction Fields

For each qualifying event, extract:

| Field | Description | Format |
|-------|-------------|--------|
| title | Event summary/title | Plain text |
| start_time | Event start | ISO 8601 datetime |
| duration | Length in minutes | Integer |
| attendee_count | Total attendees including user | Integer |
| meeting_type | Classified type | One of the 6 types |
| importance_score | Weighted score | Integer 1-5 |
| location | Meeting location or video link | URL or text, null if absent |

### Calendar Edge Cases

**All-day events**: Include all-day events but set duration to 0 and start_time to the start of the day. Classify normally.

**Overlapping events**: Report each event individually. Do not merge or flag overlaps -- that is the priority-synthesis skill's responsibility.

**Events starting before today but ending today**: Include the event. Use the original start time. Set a flag `started_yesterday: true`.

---

## Notion Patterns

### Task Database Discovery

Search the user's Notion workspace for databases that function as task trackers. Use the same auto-discovery algorithm as P05 Weekly Review Compiler:

1. Call the Notion MCP `search` tool with query terms: "tasks", "to-do", "backlog", "sprint", "projects".
2. Filter results to databases only (exclude pages).
3. For each candidate database, retrieve its schema (properties).
4. Qualify a database as a task database when it contains BOTH:
   - A **Status** property (type: status, select, or multi_select) with values resembling completion states ("Done", "Completed", "Complete", "Closed", "Finished", "Archived").
   - A **Date** property (type: date) with a name containing "Due", "Deadline", "Date", or "Target" (case-insensitive).
5. Accept all qualifying databases. When multiple match, query all of them and merge results.

Cache discovered database IDs for the duration of the session. Do not re-discover on subsequent queries within the same morning sync run.

### Due Today Filter

Query each discovered task database with a compound filter:

**Primary filter** (due today or overdue, not completed):
```
AND:
  - Due Date <= today
  - Status NOT IN ["Done", "Completed", "Complete", "Closed", "Finished", "Archived"]
```

**Secondary filter** (completed overnight):
```
AND:
  - Status IN ["Done", "Completed", "Complete", "Closed", "Finished"]
  - Last Edited Time >= overnight_window_cutoff
```

Combine results from both filters. Tag each task with its source filter: "due_today", "overdue", or "completed_overnight".

### Status Tracking

For tasks matching the secondary filter (completed overnight), verify the completion was recent by checking the `Last Edited Time` property. Notion does not expose property-level change history, so treat any task with a completion status AND a Last Edited Time within the overnight window as a probable overnight completion.

When the Last Edited Time property is unavailable on a database, skip overnight completion tracking for that database and note the limitation.

### Task Extraction Fields

For each qualifying task, extract:

| Field | Description | Format |
|-------|-------------|--------|
| title | Task title / page name | Plain text |
| status | Current status value | Text |
| due_date | Due date | ISO 8601 date |
| project | Parent database name or project property | Text |
| priority | Priority property value if present | Text or number, null if absent |
| source_filter | How the task qualified | "due_today", "overdue", or "completed_overnight" |
| days_overdue | Days past due (0 if due today) | Integer |

### Notion Edge Cases

**No task databases found**: Set status to "available" (Notion MCP works, but no task databases exist). Return task count 0, empty items list, overdue 0. Append metadata: `note: "No task databases discovered in workspace."`.

**Multiple databases with overlapping tasks**: Deduplicate by page ID across databases. When the same page appears in multiple database query results, keep the instance from the primary (first-discovered) database.

**Tasks with no due date**: Exclude from results. Tasks without dates cannot be classified as due today or overdue.

**Recurring tasks**: Treat each instance independently. If a recurring task is due today, include it regardless of prior completions.

---

## Slack Patterns

### Channel Scanning

List all channels the user has joined using the Slack MCP `list_channels` tool. Apply channel filtering:

1. If a configured channel list exists (provided via command flag or plugin configuration), scan only those channels.
2. If no channel list is configured, scan all joined channels.
3. Exclude archived channels.
4. Exclude channels with zero messages in the overnight window (check `latest` message timestamp before fetching full history).

For each qualifying channel, fetch message history within the overnight window using the `channel_history` tool with `oldest` set to the cutoff timestamp (Unix epoch format).

### Message Window Filtering

Filter fetched messages to include only those with a timestamp (`ts` field) within the overnight window. Slack's `channel_history` API may return messages slightly outside the requested range -- apply a strict timestamp comparison on all results.

### Noise Filtering Pipeline

Apply P19's six-category noise filter in order. Each filter removes messages from the working set before the next filter runs.

| Order | Category | Detection | Exception |
|-------|----------|-----------|-----------|
| 1 | Channel management | `subtype` is "channel_join", "channel_leave", "channel_topic", "channel_purpose", "pinned_item" | None -- always noise |
| 2 | Bot messages | `subtype` is "bot_message" OR `bot_id` field is present | Retain if message text contains `<@{current_user_id}>` (direct mention in bot message) |
| 3 | Social/off-topic | Emoji-only (text matches `^[:a-z_]+:$`), GIF-only (contains giphy/tenor URL with no other text), greetings ("good morning", "happy friday" with no substantive follow-up) | Retain if posted in a non-social channel (channel importance modifier >= +5) |
| 4 | Duplicates | Same sender + text similarity > 90% (Jaccard on word sets) within 10-minute window across channels | Keep the version in the higher-importance channel |
| 5 | Link dumps | Message is a URL with no commentary (text matches `^https?://\S+$` or contains only a URL and whitespace) | Retain if engagement (replies + reactions) >= 3 |
| 6 | Low-signal acks | Message matches "ok", "got it", "will do", "thanks", "thx", "ty", "+1", "ack" (case-insensitive, with optional punctuation) | Retain if message is a reply that confirms assignment ("will do" in response to a task assignment) |

### Signal Scoring

Compute a 4-factor signal score (0-100) for each message surviving noise filtering. Use the same algorithm as P19:

**Factor 1: Message Type (0-40 points)**

| Type | Points |
|------|--------|
| decision | 40 |
| action_assignment | 35 |
| announcement | 30 |
| question | 20 |
| status_update | 15 |
| fyi | 10 |
| discussion | 10 |
| other | 5 |

Classify message type by keyword detection: "decided", "decision", "agreed", "approved" = decision; "please", "can you", "@name to" = action_assignment; "announcing", "heads up", "FYI everyone" = announcement; sentences ending in "?" = question; "update:", "status:" = status_update.

**Factor 2: Engagement (0-25 points)**
- Reply count x 3, capped at 15 points.
- Reaction count x 2, capped at 10 points.
- Sum both sub-scores.

**Factor 3: Recency (0-20 points)**

| Age | Points |
|-----|--------|
| < 2 hours | 20 |
| 2-6 hours | 16 |
| 6-12 hours | 12 |
| 12-24 hours | 8 |
| 1-3 days | 4 |
| > 3 days | 0 |

**Factor 4: Channel Importance (-5 to +15 points)**
- +15: "leadership", "exec", "board", "strategy", "decisions"
- +10: "engineering", "product", "design", "sales"
- +5: "general", "announcements", "important"
- +0: Default
- -5: "random", "social", "off-topic", "fun", "watercooler"

Final score: `clamp(type + engagement + recency + channel_modifier, 0, 100)`.

### @Mention Detection

Detect three mention types for the current user:

1. **Direct mention**: Text contains `<@{user_id}>`.
2. **Broadcast mention**: Text contains `@channel`, `@here`, or `@everyone`.
3. **Name mention**: Text contains the user's display name or real name as a whole word (case-insensitive).

Direct mentions override noise filtering -- restore any noise-filtered message containing a direct mention and promote it to P2 minimum. Broadcast mentions in filtered messages promote to P3 minimum.

### Slack Extraction Fields

For each surfaced message, extract:

| Field | Description | Format |
|-------|-------------|--------|
| channel | Channel name | Text |
| sender | Sender display name | Text |
| message_preview | Message text truncated | Plain text, 100 characters max |
| signal_score | Computed score | Integer 0-100 |
| is_mention | Whether user was mentioned | Boolean |
| mention_type | Type of mention if applicable | "direct", "broadcast", "name", or null |
| timestamp | Message time | ISO 8601 datetime |
| thread_reply_count | Replies if threaded | Integer or null |

### Slack Edge Cases

**High-volume channels**: When a channel returns more than 200 messages in the overnight window, process only the most recent 200. Append metadata: `truncated: true, total_available: N`.

**Thread-only replies**: When a reply is posted in a thread but not broadcast to the channel, include it only if it contains a direct mention or scores P1/P2 on its own merits.

**Slack Connect channels**: Treat messages from external organizations the same as internal messages. Apply the same scoring and filtering rules.

---

## Drive Patterns

### Query Construction

Search for files modified within the overnight window using the Google gws CLI (Drive) search tool. Construct the query as:

```
modifiedTime > '{cutoff_iso}'
```

Format `cutoff_iso` as an RFC 3339 datetime string (e.g., `2026-03-04T19:00:00Z`). Request file metadata fields: name, mimeType, modifiedTime, lastModifyingUser, owners, shared, sharingUser, permissions.

When the query returns more than 50 results, add a secondary filter to prioritize shared and commented files:

```
modifiedTime > '{cutoff_iso}' and (sharedWithMe = true or starred = true)
```

Merge and deduplicate results by file ID.

### Result Filtering

Apply these filters to reduce results to meaningful overnight activity:

1. **Skip self-only edits**: Exclude files where the `lastModifyingUser` is the current user AND no other user has edited, commented, or shared the file within the window. The morning briefing surfaces activity from others, not the user's own work.
2. **Skip trashed files**: Exclude files with `trashed: true`.
3. **Skip binary non-documents**: Exclude file types that cannot be meaningfully summarized: images (JPEG, PNG, GIF, SVG), videos (MP4, MOV), audio (MP3, WAV), archives (ZIP, TAR).
4. **Prioritize shared files**: Files where `sharingUser` has a timestamp within the overnight window rank higher -- someone actively shared this with the user.
5. **Prioritize commented files**: Files with new comments (detected via Drive comments API if available, or inferred from modifiedTime change without content change) rank higher.

### Surface Criteria

Include a file in the results when it meets at least one of these conditions:
- The file was shared with the user during the overnight window.
- The file received new comments during the overnight window.
- The file was created during the overnight window by someone other than the current user in a shared folder.
- The file was modified by someone other than the current user during the overnight window AND the file is in a shared folder or explicitly shared with the user.

### Drive Extraction Fields

For each qualifying file, extract:

| Field | Description | Format |
|-------|-------------|--------|
| file_name | File name/title | Plain text |
| file_type | Document type | "Docs", "Sheets", "Slides", "PDF", "other" |
| modifier | Last person who modified | Display name |
| modified_time | Last modification timestamp | ISO 8601 datetime |
| shared_with | List of people the file is shared with | List of display names or "N people" |
| activity_type | Why the file surfaced | "shared", "commented", "created", "modified" |
| file_url | Direct link to the file | Google Drive URL |

### Drive Edge Cases

**Google Workspace files vs uploaded files**: Google Docs, Sheets, and Slides have mimeType prefixes `application/vnd.google-apps.*`. Uploaded PDFs, DOCXs, and other formats have standard MIME types. Handle both categories but prioritize Workspace-native files for relevance.

**Shared drives**: Include results from shared drives the user has access to. Shared drive files follow the same filtering and extraction rules as personal drive files.

**Large result sets**: When more than 50 files qualify after filtering, return only the top 20 ranked by: activity_type priority (shared > commented > created > modified), then by modified_time descending. Append metadata: `truncated: true, total_qualifying: N`.

**Files with restricted access**: When a file appears in search results but the current user lacks read access (permissions error on content fetch), include the file metadata but set a flag: `access_restricted: true`. Do not attempt to read or summarize the file content.
