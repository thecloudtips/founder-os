---
description: Generate a deep meeting prep document with attendee context, open items, and framework-based talking points for a specific calendar event
argument-hint: "[event_id] --team --hours=2160 --output=both"
allowed-tools: ["Read", "Bash"]
---

# Meeting Prep

Generate a comprehensive meeting preparation document for a specific calendar event by pulling data from Google Calendar, Gmail, Notion CRM/notes, and optionally Google Drive. Produce attendee profiles, open items, recent context, and framework-based talking points. Save the prep document to a Notion database and display a summary in chat.

## Parse Arguments

Extract these from `$ARGUMENTS`:
- `event_id` (optional positional, first non-flag argument) -- the Google Calendar event ID to prep for. If omitted, show a numbered list of today's remaining meetings and ask the user to pick one.
- `--team` (boolean, default: false) -- activate the full parallel-gathering pipeline with dedicated agents per source
- `--hours=N` (integer, default: 2160, i.e. 90 days) -- email lookback window in hours for attendee correspondence search
- `--output=VALUE` (string, one of: `notion`, `chat`, `both`; default: `both`) -- where to deliver the prep document

If `event_id` is omitted:
1. Use the `gws` CLI to fetch all events for today from now through end of day. Run `gws calendar +agenda --today --format json` or use `gws calendar events list --params '{"calendarId":"primary","timeMin":"ISO","timeMax":"ISO","singleEvents":true,"orderBy":"startTime"}' --format json` with appropriate time bounds.
2. Filter out events matching the exclusion rules from the meeting-context skill: cancelled events, events with titles containing "Focus", "Block", "OOO", "Out of Office", "Do Not Book", "No Meetings" (case-insensitive), and solo events with no attendees besides the user.
3. Present a numbered list to the user:
   ```
   Today's remaining meetings:
   1. [HH:MM] - [HH:MM] | [Event Title] ([N] attendees)
   2. [HH:MM] - [HH:MM] | [Event Title] ([N] attendees)
   ...
   Enter a number to select, or provide an event_id directly:
   ```
4. Wait for the user to pick a number. Map their selection to the corresponding event_id and proceed.

If `event_id` is provided, validate it by fetching the event using `gws calendar events get --params '{"calendarId":"primary","eventId":"EVENT_ID"}' --format json`. If the event is not found, halt with: "Event not found. Check the event_id or run `/meeting:prep` with no arguments to select from today's meetings."

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Mode 1: Default (Single-Agent Prep)

When `--team` is NOT present:

1. Read the meeting-context skill at `${CLAUDE_PLUGIN_ROOT}/skills/meeting-context/SKILL.md` for event identity resolution, meeting classification, attendee context lookup, open items compilation, document search, and graceful degradation rules.
2. Read the talking-points skill at `${CLAUDE_PLUGIN_ROOT}/skills/talking-points/SKILL.md` for framework selection logic, talking point generation rules, opener/close structure, and context-aware customization.
3. **Check for existing meeting record**:
   - Search Notion for a database titled "[FOS] Meetings". If not found, try "Founder OS HQ - Meetings". If not found, fall back to "Meeting Prep Autopilot - Prep Notes".
   - If a database is found, look for an entry where the Event ID (rich_text) property matches the target event_id. Note: the Event ID may have been created by P07 Meeting Intelligence Hub -- if a record already exists for this Event ID, UPDATE it with prep fields rather than creating a duplicate.
   - If a prep note already exists for this event, update it in place (do not create a duplicate). Note: "Updating existing meeting record for [event title]."
   - If no database is found, warn: "No Meetings database found in Notion. Prep will be displayed in chat only. Create '[FOS] Meetings' or run another meetings plugin first." Continue without Notion storage.
4. **Calendar**: Use `gws calendar events get --params '{"calendarId":"primary","eventId":"EVENT_ID"}' --format json` to fetch the target event. Apply the event identity resolution rules from the meeting-context skill to extract all fields (title, start/end time, attendees, location, description, recurrence, organizer). Validate the event: reject cancelled events, warn on declined events, flag tentative RSVP, append "[Past event]" note for events that have already occurred. Classify the meeting type using the meeting-context skill classification table. Compute the importance score (1-5) using the weighted scoring rubric.
5. **Gmail**: Use `gws gmail users messages list --params '{"userId":"me","q":"from:EMAIL OR to:EMAIL after:YYYY/MM/DD","maxResults":50}' --format json` to search for email threads with each attendee's email address within the `--hours` lookback window. Use `gws gmail users messages get --params '{"userId":"me","id":"MSG_ID","format":"full"}' --format json` to retrieve full message details. For each attendee extract: thread count, last interaction date/summary, unanswered emails (subject, date, days waiting), recent topics (5 most recent thread subjects/summaries), and sentiment indicators (negative-signal keywords in last 30 days). If the gws CLI is not available, skip with warning and continue.
6. **Notion CRM & Notes**: Search Notion for CRM contact records matching each attendee (by email exact match, then name partial match, then company domain). For matched contacts retrieve: role/title, company, contact type, active deals, last CRM interaction, relationship status, and communication history depth. Also search Notion pages for meeting notes mentioning attendees, extracting action items (open/closed), key decisions, and open commitments. If Notion MCP is unavailable, halt (see Error Handling).
7. **Google Drive** (optional): Use `gws drive files list --params '{"q":"name contains '\''TERM'\''","pageSize":20,"fields":"files(id,name,mimeType,modifiedTime,webViewLink)"}' --format json` to execute search queries per the meeting-context skill -- title query, attendee query, and company query. Rank and surface top 3 relevant documents with title, type, modified date, link, and relevance note. If the gws CLI is not available, skip silently and mark Drive as "unavailable" in sources.
8. **Build attendee profiles**: For each attendee, compile the full profile per the meeting-context skill's Attendee Output Structure. Order profiles: external attendees first, then internal, sorted by seniority descending, then alphabetical. For meetings with 10+ attendees, fully profile the top 5 and list the rest as "Also attending: [names]".
9. **Compile open items**: Aggregate pending items into four categories per the meeting-context skill: "You owe", "Owed to you", "Shared/unclear", and "Resolved since last meeting" (recurring only). Deduplicate across sources.
10. **Generate talking points**: Apply the talking-points skill. Select the framework based on meeting type classification. Generate 3-5 talking points (exactly 2 for meetings 15 minutes or less). Produce the suggested opener, proposed next steps (2-3 with owner and deadline), meeting close, and "Do NOT mention" list if applicable. Apply all context-aware customizations (deal stage, relationship status, unanswered items).
11. **Assemble prep document**: Build the full prep document following the output format below. If `--output` is `notion` or `both`, create (or update) a Notion page titled "Meeting Prep: [Event Title] -- [YYYY-MM-DD]" containing the full document.
12. **Record in database**: Write (or update) a row in the "[FOS] Meetings" database (or fallback database) with prep-specific fields: Meeting Title, Event ID, Date, Attendees, Meeting Type, Importance Score, Prep Notes (full prep content), Talking Points (generated discussion guide), Sources Used (multi_select of data sources used), and Generated At. If the meeting is with a known client (external attendee matched in CRM), set the Company relation to the matched company. Only write the fields owned by P03 -- do not overwrite P07 fields (Summary, Decisions, Follow-Ups, Topics, Source Type, Transcript File, Duration) if they already have values.
13. **Present to user**: If `--output` is `chat` or `both`, display the prep summary in chat. If `--output` is `notion`, display only the Notion page URL and a one-line summary.

### Output Format (Default Mode)

```
## Meeting Prep: [Event Title]

**Status**: Generated successfully
**Notion Page**: [URL] (if output includes notion)
**Sources**: Calendar [check] | Gmail [status] | Notion [status] | Drive [status]
**Generated in**: [elapsed time]

---

**Time**: [start] - [end] ([duration]) | [day, date]
**Type**: [meeting type] | **Importance**: [score]/5
**Location**: [link/room] | **RSVP**: [user's status]

### Attendees ([count])

| Name | Role / Company | Relationship | Last Contact | Pending Items |
|------|---------------|-------------|--------------|---------------|
| [name] ([RSVP]) | [title], [company] | [Active/Cooling/Dormant/New] | [date] via [channel] | [count] items |
| ... | ... | ... | ... | ... |

[For 10+ attendees: "Also attending: [names]"]

### Agenda
- [Explicit items from event description]
- [Inferred] [items from email/note context]
- [New since last meeting] [delta items for recurring meetings]

### Open Items
**You owe:**
- [item] -- to [person] -- [days waiting/overdue]
**Owed to you:**
- [item] -- from [person] -- [days waiting]
**Shared/unclear:**
- [item with context]
**Resolved since last meeting:** (recurring only)
- [item] -- [resolution summary]

### Recent Context
- [date] | [channel] | [summary] | Follow-up: [status]
- ... (last 5 interactions)

### Relevant Documents
1. [Doc title] ([type]) -- Modified [date] -- [relevance note] -- [link]
2. ...
3. ...

### Discussion Guide
**Framework**: [Framework Name] ([Meeting Type])

**Opener**: [1-2 sentence suggested opener]

**Talking Points**:
1. **[Action verb] [topic]** -- [context and rationale]
2. **[Action verb] [topic]** -- [context and rationale]
3. **[Action verb] [topic]** -- [context and rationale]

**Do NOT Mention**: (if applicable)
> - [Item with rationale]

**Proposed Next Steps**:
- [ ] [Action] -- Owner: [name] -- By: [date]
- [ ] [Action] -- Owner: [name] -- By: [date]

**Close**: [1-sentence summary and next interaction confirmation]
```

## Mode 2: Team Pipeline (`--team`)

When `--team` IS present:

1. Read the pipeline configuration at `${CLAUDE_PLUGIN_ROOT}/teams/config.json`.
2. **Phase 1 -- Parallel Gathering**: Launch all 4 gatherer agents simultaneously:
   - **Calendar Agent** -- Fetch the target event, resolve identity fields, classify meeting type, compute importance score, detect scheduling conflicts. Reads its definition from `${CLAUDE_PLUGIN_ROOT}/teams/agents/calendar-agent.md`.
   - **Gmail Agent** -- Search email threads with each attendee within the `--hours` window, extract thread counts, unanswered emails, recent topics, and sentiment indicators. Reads its definition from `${CLAUDE_PLUGIN_ROOT}/teams/agents/gmail-agent.md`.
   - **Notion Agent** -- Pull CRM contact data (role, company, deals, relationship status), past meeting notes, open action items, and commitments from Notion. Reads its definition from `${CLAUDE_PLUGIN_ROOT}/teams/agents/notion-agent.md`.
   - **Drive Agent** -- Search Google Drive for documents relevant to the meeting topic and attendees via the `gws` CLI. If gws is unavailable, return immediately with status "unavailable". Reads its definition from `${CLAUDE_PLUGIN_ROOT}/teams/agents/drive-agent.md`.
3. Wait for all gatherers to complete or timeout after 30 seconds. Any agent that times out is marked as "timed out" in the pipeline report. The pipeline continues as long as at least 2 agents return data (per `minimum_gatherers_required: 2` in config.json).
4. **Phase 2 -- Synthesis**: Launch the **Prep Lead** agent:
   - Reads its definition from `${CLAUDE_PLUGIN_ROOT}/teams/agents/prep-lead.md`.
   - Reads the talking-points skill at `${CLAUDE_PLUGIN_ROOT}/skills/talking-points/SKILL.md`.
   - Merges all gatherer outputs into attendee profiles, open items, recent context, and relevant documents.
   - Selects the appropriate talking point framework based on meeting type, generates 3-5 talking points, opener, close, and "Do NOT mention" list.
   - Creates (or updates) the Notion page with the full prep document.
   - Writes (or updates) the row in the "[FOS] Meetings" database (or fallback), following the same DB discovery and P03-owned field rules as Mode 1 step 3 and step 12.
5. Present the final prep document (per `--output` flag) and pipeline execution summary.

### Output Format (Team Mode)

```
## Meeting Prep: [Event Title]

**Status**: Generated successfully (team pipeline)
**Notion Page**: [URL] (if output includes notion)
**Type**: [meeting type] | **Importance**: [score]/5
**Sources**: Calendar [status] | Gmail [status] | Notion [status] | Drive [status]
**Generated in**: [elapsed time]

### Pipeline Execution
| Agent          | Status    | Duration | Items Found         |
|----------------|-----------|----------|---------------------|
| Calendar Agent | [status]  | [time]   | 1 event, [N] attendees |
| Gmail Agent    | [status]  | [time]   | [N] threads         |
| Notion Agent   | [status]  | [time]   | [N] contacts, [N] items |
| Drive Agent    | [status]  | [time]   | [N] documents       |
| Prep Lead      | [status]  | [time]   | --                  |
**Total pipeline time**: [elapsed]

---

[Same full prep document sections as default mode: Time/Type/Location, Attendees table, Agenda, Open Items, Recent Context, Relevant Documents, Discussion Guide with talking points]
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Error Handling

- **Notion MCP not configured**: Halt immediately. Display: "Notion MCP is required for meeting prep output and CRM context. See `${CLAUDE_PLUGIN_ROOT}/INSTALL.md` for setup instructions."
- **gws CLI not available (Calendar)**: Halt immediately. Display: "The gws CLI is required to fetch calendar event details. Install gws and authenticate with `gws auth login`. See `${CLAUDE_PLUGIN_ROOT}/INSTALL.md` for setup instructions."
- **gws CLI not available (Gmail)**: Warn: "Gmail unavailable via gws -- email history, unanswered items, and sentiment indicators will be empty." Continue with remaining sources.
- **gws CLI not available (Drive)**: Skip silently. Mark as "unavailable" in sources. This is expected for many users.
- **Event not found**: Halt. Display: "Event not found for the given event_id. Run `/meeting:prep` with no arguments to select from today's remaining meetings."
- **Cancelled event**: Halt. Display: "This event has been cancelled. No prep document generated."
- **Declined event**: Warn: "You declined this event. Proceed with prep anyway?" Wait for user confirmation before continuing.
- **Existing meeting record for this event**: Update the existing Notion page and database row in place. Do not create a duplicate. The record may have been created by P07 Meeting Intelligence Hub -- update only P03-owned fields. Note in output: "Updated existing meeting record."
- **No attendees besides user**: Halt. Display: "This event has no other attendees. Meeting prep requires at least one other participant."
- **No email threads found for any attendee**: Include the email sections with "No email history found (within [N]-hour lookback)" rather than omitting them. This confirms the source was checked.
- **No CRM match for attendee**: Include the attendee with available data. Mark CRM fields as "Not found in CRM". Never omit an attendee due to missing data.
- **Fewer than 2 gatherers return data (team mode)**: Halt. Display: "Pipeline requires at least 2 data sources. Only [N] returned data. Check MCP server connections."
- **Past event**: Allow prep generation. Append "[Past event -- prep for reference only]" to the output header. Adjust talking point recommendations to retrospective framing.
- **Future event (more than 7 days out)**: Allow. Warn: "Note: This event is [N] days away. Context may change before the meeting."

## Usage Examples

```
/meeting:prep                                    # Show today's meetings, pick one interactively
/meeting:prep abc123                             # Prep for specific event ID
/meeting:prep --team                             # Interactive selection, full parallel pipeline
/meeting:prep abc123 --team                      # Specific event, full parallel pipeline
/meeting:prep abc123 --hours=720                 # 30-day email lookback instead of 90
/meeting:prep abc123 --output=notion             # Save to Notion only, no chat output
/meeting:prep abc123 --output=chat               # Chat only, skip Notion save
/meeting:prep --team --output=both               # Interactive + pipeline + both outputs
```
