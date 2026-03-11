# Data Sources Reference

Detailed algorithms, processing rules, edge case handling, and output schemas for the three data sources that feed the Weekly Review Compiler: Notion task databases, Google Calendar events, and Gmail threads.

---

## 1. Notion Task Databases (Required)

### Auto-Discovery Algorithm

Discover all Notion databases in the workspace that track completable tasks. Do not hardcode database IDs. Follow this search sequence:

1. Call the Notion MCP `search` endpoint with an empty query and `filter.object = "database"` to retrieve all accessible databases.
2. For each returned database, inspect its `properties` object for a property matching the Status pattern (see below).
3. A database qualifies as a task source if it has at least one property meeting **both** criteria:
   - Property type is `status`, `select`, or `checkbox`.
   - Property contains completion-like values or is named with a completion-like label.
4. Collect all qualifying databases into a `discovered_sources` list.
5. If zero databases qualify, fall back to a keyword search: call `search` with queries `"Tasks"`, `"Projects"`, `"To Do"`, and `"Tracker"` (one call per keyword). Inspect returned databases using the same property criteria.
6. If still zero databases qualify after fallback, report the empty state (see Edge Cases below).

### Status Property Detection

Identify the Status-like property by checking property names and values in this priority order:

| Priority | Property Name Match (case-insensitive) | Qualifying Type | Completion Values |
|----------|----------------------------------------|-----------------|-------------------|
| 1 | `Status` | status, select | Done, Complete, Completed, Closed, Shipped, Resolved |
| 2 | `State` | status, select | Done, Complete, Completed, Closed |
| 3 | `Done` or `Completed` | checkbox | `true` |
| 4 | Any property | status | Any option in the "Complete" group (Notion status type groups) |

When a database has multiple properties matching the pattern, use the highest-priority match. Do not combine multiple status properties from the same database.

### Completion Value Matching

Match completion values case-insensitively. Accept these canonical values and their common variants:

- **Done**: `Done`, `DONE`, `done`
- **Complete**: `Complete`, `Completed`, `COMPLETE`, `COMPLETED`
- **Closed**: `Closed`, `CLOSED`, `closed`
- **Shipped**: `Shipped`, `SHIPPED`
- **Resolved**: `Resolved`, `RESOLVED`

For checkbox-type properties, match `true` (checked). For Notion native `status` type properties, also accept any option placed in the "Complete" group by the database designer, regardless of label.

### Task Query Construction

For each discovered database, construct a filter to retrieve tasks completed during the review week (Monday 00:00:00 through Sunday 23:59:59 in the user's local timezone):

```
filter = {
  "and": [
    { "property": "[status_property_name]", "[type]": { "equals": "[completion_value]" } },
    { "property": "[date_property_name]", "date": { "on_or_after": "[monday_iso]" } },
    { "property": "[date_property_name]", "date": { "on_or_before": "[sunday_iso]" } }
  ]
}
```

Detect the date property for completion timing using this priority:

1. A property named `Completed At`, `Completed Date`, `Done Date`, or `Closed Date` (exact date of completion).
2. A property named `Last Edited` or `Last Modified` (approximate but available on most databases).
3. The Notion system `last_edited_time` (always available, least precise because any edit counts).

If no explicit completion date property exists, use `last_edited_time` and note in the output: "Completion dates inferred from last-edit timestamps."

### Task Aggregation

After querying all discovered databases, aggregate results into a unified task list:

1. **Group by source**: Organize tasks by their originating database name. Preserve the database title as the group label (e.g., "Product Roadmap", "Client Projects", "Personal Tasks").
2. **Extract per task**: Task title (from the Name/Title property), completion date (from the date property used in the query), and any project or category tag if a `Select` or `Multi-select` property named `Project`, `Category`, `Type`, or `Tag` exists.
3. **Count per group**: Calculate `completed_count` for each database source.
4. **Calculate totals**: Sum all `completed_count` values into `total_completed`.
5. **Sort groups**: Order groups by `completed_count` descending (most productive area first).
6. **Sort tasks within groups**: Order by completion date ascending (chronological narrative of the week).
7. **Deduplicate across databases**: If the same task title appears in multiple databases with completion dates within 24 hours of each other, keep only the instance from the higher-priority database (the one with more total tasks). Flag the duplicate for transparency: "Possible duplicate removed: [title]".

### Output Schema

Produce this structure for downstream consumption by the weekly-reflection skill:

```
notion_tasks: {
  total_completed: <int>,
  source_count: <int>,              # number of databases pulled from
  completion_date_method: "explicit" | "last_edited",
  groups: [
    {
      source_db: "<database title>",
      completed_count: <int>,
      tasks: [
        { title: "<string>", completed_at: "<ISO date>", project: "<string|null>" }
      ]
    }
  ],
  duplicates_removed: <int>
}
```

### Edge Cases

**Zero databases discovered**: When no qualifying task databases are found after both the full scan and keyword fallback:
- Set `total_completed` to 0 and `source_count` to 0.
- Do not treat this as an error. Report in the review: "No task databases with completion tracking were found in the workspace."
- The review proceeds using Calendar and Gmail sources only.

**Multiple databases discovered**: When more than one database qualifies (common in workspaces with per-project boards):
- Pull completed tasks from all qualifying databases. Do not prompt the user to select one.
- Cap at 10 databases maximum. If more than 10 qualify, sort by total item count descending and take the top 10. Log: "Found [N] task databases. Using the 10 largest."
- Run deduplication across all sources (see Deduplicate step above).

**Very large task volume (>100 completed tasks in a week)**: When a single week yields more than 100 completed tasks across all sources:
- Include all tasks in the aggregation (do not truncate the data).
- In the review output, display the top 20 tasks per group sorted by project tag, then append: "[X] additional tasks completed. Full list available in source databases."
- Set a `high_volume` flag in the output schema for the reflection skill to adjust its summarization (broader strokes, fewer per-task details).

**Database with no date property**: When a qualifying database has a status property but no date-type property at all:
- Use the Notion system `last_edited_time` for filtering and sorting.
- Add a note: "Database '[name]' has no date property. Using last-edited timestamp."
- Accept that some tasks may be false positives (edited during the week but completed earlier).

**Archived or deleted databases**: The Notion search API may return archived databases. Check the `archived` field on each database object. Skip any database where `archived = true`.

---

## 2. Google Calendar Events (Recommended)

### Time Window Definition

Define the review window as Monday through Sunday of the target week:
- **Start**: Monday 00:00:00 in the user's local timezone, converted to UTC for the Calendar API query.
- **End**: Sunday 23:59:59 in the user's local timezone, converted to UTC.
- Default to the most recently completed week (the Monday-Sunday period ending before today). If today is Monday, review the prior week. If today is any other day, review the week containing the most recent Monday through the most recent Sunday.

Override the default window when the command receives a `--date=YYYY-MM-DD` flag. Interpret the provided date as any day within the desired review week, then expand to the enclosing Monday-Sunday range.

### Event Retrieval

Call the Google gws CLI (Calendar) to list events within the time window:

1. Query the user's primary calendar. Do not query shared or subscribed calendars unless explicitly requested via `--calendars=all`.
2. Expand recurring events into individual instances (set `singleEvents=true` in the API call).
3. Retrieve all events regardless of RSVP status. Filter after retrieval.
4. Request these fields per event: `id`, `summary` (title), `start`, `end`, `attendees`, `description`, `location`, `recurringEventId`, `status`, `organizer`.

### Event Filtering

Exclude events that do not represent actual meetings or work sessions:

| Rule | Detection | Action |
|------|-----------|--------|
| Cancelled events | `status = "cancelled"` | Skip silently |
| Declined events | User's attendee entry has `responseStatus = "declined"` | Skip silently |
| All-day events | `start` contains `date` key (no `dateTime`) | Skip silently |
| Focus/block time | Title contains "Focus", "Block", "OOO", "Out of Office", "Busy", "Do Not Book" (case-insensitive) | Skip silently |
| Holds | Title contains "Hold", "Tentative", "TBD", "Placeholder" (case-insensitive) AND zero non-organizer attendees | Skip silently |

### Event Classification

Classify each remaining event into one of six types based on attendee composition and event metadata. Apply rules in this order (first match wins):

1. **One-on-One**: Exactly 2 attendees total (user + 1 other), neither is a room resource.
2. **External**: At least one attendee has an email domain different from the user's domain. Determine the user's domain from the calendar owner email.
3. **Recurring Internal**: `recurringEventId` is present AND all attendees share the user's email domain.
4. **Group Internal**: 3 or more attendees, all sharing the user's email domain, no `recurringEventId`.
5. **Ad-hoc**: No attendees besides the user (solo calendar block that passed filtering), OR 2+ attendees with no recurring pattern.
6. **Unclassified**: Fallback when none of the above rules match. Treat as internal for counting purposes.

### Outcome Extraction

Attempt to extract meeting outcomes or notes from each event:

1. Check the event `description` field for content added after the event's start time. Calendar descriptions often contain post-meeting notes appended by the organizer.
2. Look for keywords in the description indicating outcomes: "decided", "agreed", "action item", "next step", "follow up", "outcome", "result", "conclusion", "takeaway".
3. If outcome keywords are found, extract the sentence or bullet point containing the keyword and up to two surrounding sentences for context.
4. If no outcome content is found in the description, set `outcome` to `null`. Do not fabricate outcomes.

### Aggregation

Produce per-type counts and a chronological event list:

```
calendar_events: {
  total_events: <int>,
  total_hours: <float>,          # sum of all event durations in hours
  by_type: {
    "one_on_one": <int>,
    "external": <int>,
    "recurring_internal": <int>,
    "group_internal": <int>,
    "ad_hoc": <int>,
    "unclassified": <int>
  },
  events: [
    {
      title: "<string>",
      date: "<ISO date>",
      start_time: "<HH:MM>",
      duration_minutes: <int>,
      type: "<classification>",
      attendee_count: <int>,
      outcome: "<string|null>"
    }
  ],
  busiest_day: "<weekday name>",   # day with most events
  filtered_count: <int>            # events excluded by filter rules
}
```

Sort `events` by `date` ascending, then `start_time` ascending within the same day.

Calculate `busiest_day` by counting events per weekday (Monday through Friday; exclude Saturday and Sunday from the comparison unless they have more events than any weekday).

### Edge Cases

**Zero events after filtering**: When all calendar events in the window are filtered out (or none existed):
- Set `total_events` to 0 and all `by_type` counts to 0.
- Report in the review: "No qualifying meetings this week."
- The review proceeds. A meeting-free week is still a valid review (task-focused week).

**Very high meeting volume (>40 events in a week)**: When more than 40 qualifying events exist:
- Include all events in the data (do not truncate).
- Set a `high_volume` flag for the reflection skill.
- In the review output, summarize by type and day rather than listing every event individually. Append: "[N] meetings this week across [days] days. Top external meetings listed below."
- List only external and one-on-one meetings individually (max 15). Group remaining internal meetings by recurring series title with count.

**Multi-day events**: Events spanning midnight (start on one day, end on the next):
- Attribute the event to the start date for counting purposes.
- Calculate duration using actual start and end times (may exceed 8 hours).
- If duration exceeds 8 hours, flag as "extended event" and verify it is not an all-day event miscategorized (all-day events should have been filtered).

**Recurring events with identical titles**: When a recurring series produces multiple events in the week (e.g., "Daily Standup" x5):
- List each instance individually in the events array (they are distinct meetings).
- In the review summary, group them: "Daily Standup (x5, Mon-Fri)".
- Count each instance toward `total_events` and the appropriate `by_type` bucket.

---

## 3. Gmail Thread Analysis (Optional)

Gmail is an optional data source. When the gws CLI is unavailable for Gmail or returns an authentication error, skip this entire section silently. Do not display an error or warning in the review output. Omit the "Active Email Threads" section from the review entirely.

### Sent Folder Scanning

Scan the user's Gmail Sent folder for the review week window (Monday 00:00:00 through Sunday 23:59:59):

1. Query the gws CLI (Gmail) for sent messages using a date filter: `after:YYYY/MM/DD before:YYYY/MM/DD` matching the Monday-to-Sunday window.
2. Retrieve message metadata: `threadId`, `subject`, `to` (recipients), `date`, `from`.
3. Group messages by `threadId` to identify threads.

### Active Thread Filtering

Apply the engagement threshold to identify threads where the user was actively involved, not just sending one-off messages:

1. Count the number of messages sent by the user within each thread during the review week.
2. **Retain only threads where the user sent 2 or more messages.** A single sent message (initial outreach, quick reply) does not indicate sustained engagement. Two or more replies signal an active conversation worth reflecting on.
3. From the retained threads, extract:
   - `subject`: The thread subject line. Strip `Re:`, `Fwd:`, and `RE:` prefixes.
   - `participants`: All unique email addresses in the `to`, `cc`, and `from` fields across the thread (excluding the user's own address). Map email addresses to display names when available in the message headers.
   - `sent_count`: Number of messages the user sent in this thread during the week.
   - `last_sent`: Timestamp of the user's most recent sent message in the thread.
   - `thread_length`: Total number of messages in the thread (sent + received), if available from the thread metadata.

### Thread Ranking and Capping

Cap the output at 10 threads maximum to keep the review focused:

1. Rank retained threads by a composite score: `score = sent_count * 2 + thread_length`.
2. Sort by score descending. Higher scores indicate more active, substantive conversations.
3. Take the top 10 threads.
4. If fewer than 10 threads meet the 2-message threshold, include all qualifying threads.

### Exclusion Rules

Filter out threads that do not represent meaningful work communication:

| Rule | Detection | Action |
|------|-----------|--------|
| Automated threads | Subject contains "noreply", "notification", "automated", "auto-reply", "unsubscribe" (case-insensitive) | Exclude |
| Internal-only threads | All participants share the user's email domain AND thread is purely logistical (subject contains "lunch", "parking", "office", "badge") | Exclude |
| Mailing list threads | Headers contain `List-Unsubscribe` or `Precedence: list` | Exclude |
| Calendar invites | Subject starts with "Invitation:", "Accepted:", "Declined:", "Updated invitation:" | Exclude |

Apply exclusion rules before the 2-message engagement filter to reduce unnecessary processing.

### Output Schema

```
gmail_threads: {
  status: "available" | "unavailable",
  total_sent_messages: <int>,        # all sent messages in the week (pre-filter)
  qualifying_threads: <int>,          # threads meeting the 2-message threshold
  capped: <bool>,                     # true if qualifying_threads > 10
  threads: [
    {
      subject: "<string>",
      participants: ["<display name or email>"],
      sent_count: <int>,
      last_sent: "<ISO datetime>",
      thread_length: <int|null>,
      score: <int>
    }
  ]
}
```

When Gmail is unavailable, return:

```
gmail_threads: {
  status: "unavailable",
  total_sent_messages: 0,
  qualifying_threads: 0,
  capped: false,
  threads: []
}
```

### Edge Cases

**gws CLI (Gmail) unavailable**: When the gws CLI is unavailable or authentication not configured, fails to connect, or returns an authentication error:
- Set `status` to `"unavailable"`. Return the empty schema above.
- Do not retry. Do not prompt the user to configure Gmail.
- The review proceeds without the email section. This is the expected graceful degradation behavior.

**Zero qualifying threads**: When Gmail is available but no threads meet the 2-message engagement threshold:
- Set `qualifying_threads` to 0 and `threads` to an empty array.
- Report in the review: "No active email threads this week (no threads with 2+ sent messages)."
- This is distinct from Gmail being unavailable. The section still appears in the review, but with the empty-state message.

**Very high sent volume (>200 sent messages in a week)**: When the user sent more than 200 messages in the week:
- Process all messages for thread grouping (do not truncate the input).
- The 10-thread cap on output keeps the review manageable regardless of input volume.
- Log `total_sent_messages` accurately for the review summary (e.g., "215 emails sent across 47 threads, 12 with sustained engagement").

**Threads spanning multiple weeks**: When a thread has activity both inside and outside the review week:
- Count only the user's sent messages within the Monday-Sunday window toward `sent_count`.
- Include `thread_length` as the total thread length (all time) for context, but base the engagement filter solely on within-week sent count.
- Extract participants from the full thread (not just within-week messages) to capture all conversation members.

**Shared mailbox or alias**: When the user sends from multiple addresses (aliases or delegated accounts):
- Treat all addresses associated with the authenticated Gmail account as "the user."
- Exclude all of the user's addresses from the `participants` list.
- Count sent messages from any alias toward the same thread's `sent_count`.

---

## Source Priority and Composition

When assembling the final review, weight the three sources as follows:

| Source | Required | Section in Review | Weight in Reflection |
|--------|----------|-------------------|---------------------|
| Notion Tasks | Yes | "Completed Tasks" / "Wins" | Primary (drives the accomplishments narrative) |
| Google Calendar | Yes | "Meeting Summary" | Secondary (provides context and time allocation) |
| Gmail Threads | No | "Active Conversations" | Tertiary (supplements with communication activity) |

### Minimum Viable Review

A review requires at least one source to produce meaningful content. The minimum viable combinations:

- **Tasks only**: Valid review. Focus on accomplishments and next-week priorities.
- **Calendar only**: Valid review. Focus on meeting load, external engagements, and time allocation.
- **Gmail only**: Not sufficient as the sole source (Gmail is optional and cannot anchor a review).
- **Tasks + Calendar**: Standard review. Full accomplishments and time context.
- **Tasks + Calendar + Gmail**: Complete review. All sections populated.
- **Calendar + Gmail (no tasks)**: Valid but note: "No completed tasks tracked this week. Review focuses on meetings and communication."

### Calendar-Only Week

When Notion returns zero completed tasks but Calendar has events:
- Open the review with: "This week's review focuses on meetings and collaboration. No task completions were tracked in Notion."
- Emphasize meeting outcomes, external engagements, and time allocation patterns.
- Prompt the reflection skill to generate "next week priorities" based on meeting follow-ups and calendar commitments rather than task momentum.

### Empty Week

When all three sources return zero data (no tasks, no meetings, no qualifying email threads):
- Generate a minimal review: "No activity captured this week across task databases, calendar, or email."
- Prompt the user: "This may indicate a data access issue. Verify that Notion databases have completion tracking enabled and that Google Calendar contains events for the target week."
- Do not fabricate content. An empty review is preferable to hallucinated accomplishments.
