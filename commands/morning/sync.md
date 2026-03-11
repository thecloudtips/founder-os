---
description: Full morning sync — gather from all sources, synthesize priorities, save to Notion, and display chat summary
argument-hint: "[--since=12h] [--date=YYYY-MM-DD] [--output=both] [--schedule=EXPR] [--persistent]"
allowed-tools: ["Read"]
---

# Morning Sync

Full morning briefing pipeline: gather overnight data from all configured sources, synthesize cross-source priorities, create or update a Notion page, and present a chat summary. This is the comprehensive command — for a quick ephemeral check-in, use `/founder-os:morning:quick` instead.

## Load Skills

Read the morning-briefing skill at `${CLAUDE_PLUGIN_ROOT}/skills/morning/morning-briefing/SKILL.md` for multi-source gathering patterns, overnight window calculation, five-source pipeline, source status reporting, and graceful degradation rules.

Read the priority-synthesis skill at `${CLAUDE_PLUGIN_ROOT}/skills/morning/priority-synthesis/SKILL.md` for cross-source priority scoring, Top-N extraction, urgency windowing, and section assembly format.

Read the briefing template at `${CLAUDE_PLUGIN_ROOT}/templates/briefing-template.md` for the Notion page structure and variable placeholders.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `--since=TIMEFRAME` (optional) — overnight window. Accepts `Nh` (hours) or ISO datetime. Default: `12h`.
- `--date=YYYY-MM-DD` (optional) — target date for the briefing. Default: today. Validate format; reject malformed dates with a clear error message.
- `--output=MODE` (optional) — output destination. Accepts `notion`, `chat`, or `both`. Default: `both`.

If `--date` is provided and is not today, adjust the overnight window to end at midnight of the specified date rather than the current time.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Scheduling Support

If `$ARGUMENTS` contains `--schedule`:
1. Extract the schedule value and any `--persistent` flag
2. Read `_infrastructure/scheduling/SKILL.md` for scheduling bridge logic
3. Read `_infrastructure/scheduling/references/schedule-flag-spec.md` for argument parsing
4. Default suggestion if no expression given: `"0 8 * * 1-5"` (Weekdays 8:00am)
5. Handle the schedule operation (create/disable/status) per the spec
6. Exit after scheduling — do NOT continue to main command logic

## Phase 1: Gather Data

Follow the morning-briefing skill's five-source gathering pipeline in order:

1. **Gmail** (required): Scan unread emails within the overnight window. Apply email-prioritization patterns (Eisenhower matrix). Extract up to 10 highlights. Record email count and unread total.

2. **Google Calendar** (required): Fetch all events for the target date. Filter out declined, cancelled, focus/OOO blocks, and no-attendee events. Classify meeting types and score importance (1-5). Record meeting count.

3. **Notion** (required): Search task databases for items due on the target date or overdue. Surface tasks completed within the overnight window. Record task count and overdue count.

4. **Slack** (optional): If Slack MCP is available, scan for unread messages in the overnight window. Apply noise filtering. Surface @mentions and high-signal messages (P1/P2). If unavailable, silently skip — set counts to 0.

5. **Google Drive** (optional): If gws CLI is available for Drive, search for files modified in the overnight window. Surface shared files and files with new comments. If unavailable, silently skip — set counts to 0.

Track source status (available/unavailable/partial) for each source. Apply graceful degradation rules from the morning-briefing skill:
- 3 required sources available: proceed normally.
- 2 of 3 required: proceed with warning.
- 1 of 3 required: proceed with prominent warning.
- 0 required: abort with actionable error listing MCP server packages to configure.

Assemble the `gathered_data` structure as defined in the morning-briefing skill's output contract.

## Phase 2: Synthesize Priorities

Apply the priority-synthesis skill to the gathered data:

1. Score every item using the unified 0-100 cross-source scoring system.
2. Apply scoring modifiers (key client +15, deadline today +10, thread activity +5, unanswered 24h+ +10, external meeting +10, deal-linked task +5).
3. Deduplicate across sources — merge items about the same topic/person, keep higher score.
4. Extract Top 5 priorities with action statements, source icons, and time sensitivity.
5. Group remaining items by urgency window: "Next 2 hours" / "Before noon" / "Today" / "This week".
6. Identify morning-critical flags: meeting <2h with no prep, overdue tasks, unanswered urgent emails, leadership @mentions, calendar conflicts.

## Phase 3: Notion Page (if output includes notion)

Skip this phase entirely when `--output=chat`.

### Database Lookup

Search Notion for a database titled "[FOS] Briefings". If not found, try "Founder OS HQ - Briefings". If not found, fall back to "Morning Sync - Briefings". If none exists, skip Notion recording and output the briefing to chat only. Do NOT create a new database.

The consolidated "[FOS] Briefings" database uses these properties (relevant to this plugin):

| Property | Type | Description |
|----------|------|-------------|
| Date | title | YYYY-MM-DD format |
| Type | select | Set to "Morning Sync" for this plugin |
| Content | rich_text | Link to the full briefing page (was "Briefing") |
| Email Count | number | |
| Meeting Count | number | |
| Task Count | number | |
| Sources Used | multi_select | Gmail, Calendar, Notion, Slack, Drive |
| Company | relation | Relates to Companies DB; set when 50%+ items are about one client |
| Generated At | date | |

**Property mapping notes:**
- Old "Briefing" property maps to "Content".
- Old "Slack Highlights" and "Drive Updates" counts should be included in the Content body rather than as separate properties.
- Old "Overnight Window" should be included in the Content body.
- The "Type" property must always be set to "Morning Sync".

### Idempotent Upsert

Query the database for a row matching the target date AND Type = "Morning Sync". If found, update the existing row and its linked briefing page. If not found, create a new row with Type = "Morning Sync" and a new briefing page.

### Briefing Page Assembly

Create or update a Notion page using the section structure from the briefing template. Fill each section with the synthesized data:

1. **Top Priorities** — ranked list from Phase 2.
2. **Schedule Overview** — today's meetings in chronological order with importance flags.
3. **Email Highlights** — Q1 and Q2 emails with action indicators.
4. **Tasks & Deadlines** — overdue items first, then due today, then completed overnight.
5. **Slack Highlights** — include section only if Slack was available and returned items.
6. **Drive Updates** — include section only if Drive was available and returned items.
7. **Quick Stats** — summary metrics block.

Link the briefing page URL in the database row's Content field.

Record all metrics in the database row: Email Count, Meeting Count, Task Count, Sources Used list, Generated At timestamp. Always set Type = "Morning Sync". Include Slack Highlights, Drive Updates, and Overnight Window in the Content body.

When creating or updating a Morning Sync briefing in the Briefings database, if 50% or more of the summarized items (email highlights + calendar events) relate to a single client, populate the Company relation with that client. Search "Founder OS HQ - Companies" (fall back to "[FOS] Companies") by matching email sender domains or meeting attendee domains to company records.

## Phase 4: Chat Summary (if output includes chat)

Skip this phase entirely when `--output=notion`.

Present a structured chat summary:

```
## Morning Sync — [YYYY-MM-DD]

**Status**: Generated successfully
**Notion Page**: [URL] (if Notion output was produced)
**Sources**: [source1] [check] | [source2] [check] | [source3] [status]
**Window**: Last [N]h (since [datetime])

### Top Priorities
1. **[Action statement]** — [source] [time sensitivity]
   _[Context]_
2. ...

### Schedule ([N] events, [N] high-priority)
- **[HH:MM]** | [Title] ([type]) [PRIORITY if 4-5]
- ...
(Top 5 shown; full schedule on Notion page)

### Email Highlights ([N] need attention, [total] unread)
1. **[Subject]** — [Sender] | Action: [Yes/No] | [Recency]
2. ...
(Top 5 shown; full list on Notion page)

### Tasks ([N] due today, [N] overdue)
- [ ] [Task title] — [project] [OVERDUE: N days if applicable]
- ...

[If Slack available]
### Slack ([N] highlights, [N] @mentions)
- **#[channel]** — [sender]: [preview]
- ...

[If Drive available]
### Drive ([N] updates)
- **[File name]** — modified by [who] at [time]
- ...

**Generated**: [timestamp]
```

## Edge Cases

### No Data from Any Source
If the gathering phase returns zero items across all sources but sources are available, produce an "All clear" briefing: "No urgent items, no meetings, no overdue tasks. Enjoy your morning."

### Single Source Only
Produce the briefing with available sections. Omit sections for unavailable sources without placeholders.

### Partial Source Data
When a source returns status "partial", include whatever data was retrieved and append a note: "[Source] returned partial results — some items may be missing."

### Large Volume (20+ Priority Items)
Cap the Top Priorities section at 10 items. Note the overflow: "[N] additional items below threshold — see full briefing on Notion page."

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.
