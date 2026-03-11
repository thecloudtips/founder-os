---
description: Generate a structured daily briefing from calendar, email, tasks, and Slack data
argument-hint: "--team --hours=12 --date=2026-02-25 [--schedule=EXPR] [--persistent]"
allowed-tools: ["Read"]
---

# Daily Briefing

Generate a comprehensive daily briefing by pulling data from Google Calendar, Gmail, Notion tasks, and optionally Slack. Assemble everything into a structured Notion page with meeting prep, email highlights, task priorities, and team activity.

## Parse Arguments

Extract these from `$ARGUMENTS`:
- `--team` (boolean, default: false) -- activate full parallel-gathering pipeline with dedicated agents per source
- `--hours=N` (integer, default: 12) -- email lookback window in hours
- `--date=YYYY-MM-DD` (date, default: today) -- date to generate the briefing for

If `--date` is omitted, use today's date. If `--date` is provided, validate the format (YYYY-MM-DD) and reject malformed dates with a clear error message.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Observation: Start
Before executing, record a pre_command event to the Intelligence event store (`_infrastructure/intelligence/.data/intelligence.db`):
- Event type: `pre_command`
- Plugin: `daily-briefing`
- Command: `daily-briefing`
- Generate a session_id (UUID) and reuse it for all subsequent events in this execution
- Payload: record input parameters, context files loaded, and any memories injected
- If the Intelligence database does not exist, skip observation silently and continue execution

## Intelligence: Apply Learned Patterns
Before executing the main logic, check for learned patterns in the Intelligence database (`_infrastructure/intelligence/.data/intelligence.db`):
1. Query: `SELECT instruction, description FROM patterns WHERE (plugin = 'daily-briefing' OR plugin IS NULL) AND (command = 'daily-briefing' OR command IS NULL) AND status IN ('active', 'approved') ORDER BY confidence DESC`
2. If patterns found, apply each instruction as additional context for this execution
3. Notify: `[Intel] Applying learned preference: "{description}"` for each pattern applied
4. If the Intelligence database does not exist, skip silently and continue execution

## Self-Healing: Error Recovery
If any error occurs during this command:
1. Classify the error using rules from `_infrastructure/intelligence/self-healing/SKILL.md`
2. Check if healing is enabled: query `SELECT value FROM config WHERE key = 'healing.enabled'` from Intelligence DB
3. For transient errors: retry with exponential backoff (2s, 5s, 15s)
4. For recoverable errors: look up fix in healing_patterns table, apply if found
5. For degradable errors: consult fallback registry in `_infrastructure/intelligence/self-healing/fallback-registry/SKILL.md`, execute fallback path
6. For fatal errors: stop and present error with suggested fix
7. Always notify: `[Heal] {description of what happened and what was done}`
8. Record error event to Intelligence DB with recovery_attempted field
9. If Intelligence DB is unavailable, fall back to existing error handling (no self-healing)

## Scheduling Support

If `$ARGUMENTS` contains `--schedule`:
1. Extract the schedule value and any `--persistent` flag
2. Read `_infrastructure/scheduling/SKILL.md` for scheduling bridge logic
3. Read `_infrastructure/scheduling/references/schedule-flag-spec.md` for argument parsing
4. Default suggestion if no expression given: `"30 7 * * 1-5"` (Weekdays 7:30am)
5. Handle the schedule operation (create/disable/status) per the spec
6. Exit after scheduling — do NOT continue to main command logic

## Mode 1: Default (Single-Agent Briefing)

When `--team` is NOT present:

1. Read the briefing-assembly skill at `${CLAUDE_PLUGIN_ROOT}/skills/briefing-assembly/SKILL.md` for the briefing structure, section ordering rules, and Notion page format.
2. Read the meeting-prep skill at `${CLAUDE_PLUGIN_ROOT}/skills/meeting-prep/SKILL.md` for meeting classification rules, prep note generation, and attendee context.
3. Read the email-prioritization skill at `${CLAUDE_PLUGIN_ROOT}/skills/email-prioritization/SKILL.md` for priority scoring rubric and highlight extraction.
4. Read the task-curation skill at `${CLAUDE_PLUGIN_ROOT}/skills/task-curation/SKILL.md` for task grouping, priority sorting, and overdue handling.
5. **Check for existing briefing**:
   - Search Notion for a database titled "[FOS] Briefings".
   - If not found, try "Founder OS HQ - Briefings". If not found, fall back to "Daily Briefing Generator - Briefings".
   - If found, look for an entry matching today's date (or the `--date` value) AND Type = "Daily Briefing".
   - If a briefing already exists for that date and type, update it in place (do not create a duplicate). Note: "Updating existing briefing for [date]."
   - If no database is found, skip Notion recording. Do NOT create a new database.
6. **Calendar**: Use the gws CLI to fetch all events for the target date. Run `gws calendar +agenda --today --format json` (or use `gws calendar events list` with date params for a specific date). For each event:
   - Classify as: `internal-meeting`, `external-meeting`, `focus-block`, `recurring-standup`, or `personal` (per meeting-prep skill).
   - Generate 2-3 line prep notes for meetings with external attendees or 3+ participants.
   - Flag scheduling conflicts (overlapping events).
7. **Email**: Use the gws CLI to search for unread emails within the `--hours` lookback window. Run `gws gmail +triage --max 50 --format json` for a quick triage, or `gws gmail users messages list` with query params for targeted searches. Apply the priority scoring rubric from the email-prioritization skill. Extract the top 10 highlights:
   - For each: subject, sender, priority score (1-5), one-line summary, and recommended action.
   - Group by: `needs-reply`, `needs-review`, `fyi`.
8. **Tasks**: Search Notion for tasks with due date equal to the target date, plus any overdue tasks. Group by project. Sort within each group by priority (P1 > P2 > P3). For overdue tasks, include days overdue and escalation note if > 7 days.
9. **Slack** (optional): If Slack MCP is configured, fetch mentions and direct messages from the last `--hours` hours. Extract key threads requiring attention. If Slack MCP is not available, skip silently and mark Slack as "unavailable" in sources.
10. **Assemble Notion page**: Create (or update) a Notion page following the briefing-assembly skill structure. Title: "Daily Briefing -- [YYYY-MM-DD]". Sections in order:
    - Schedule Overview (timeline with prep notes)
    - Priority Emails (top 10 highlights table)
    - Tasks & Deadlines (grouped by project)
    - Slack Activity (if available)
    - Quick Stats summary block
11. **Record stats**: Write a row to the "[FOS] Briefings" database (or fallback DB) with all metrics. Always set Type = "Daily Briefing". Map the briefing link to the "Content" property.
12. Present the briefing URL and summary to the user.

### Output Format (Default Mode)

```
## Daily Briefing -- [YYYY-MM-DD]

**Status**: Generated successfully
**Notion Page**: [URL]
**Sources**: Calendar [check] | Gmail [check] | Tasks [check] | Slack [status]
**Quick Stats**: [N] meetings | [N] priority emails | [N] tasks due ([N] overdue)
**Generated in**: [elapsed time]

### Schedule ([N] events)
- [HH:MM] - [HH:MM] | [Event title] ([classification])
  Prep: [2-3 line prep note if applicable]
- ...
(Top 5 shown; full schedule on Notion page)

### Priority Emails ([N] highlights)
1. **[Subject]** from [Sender] -- Priority [N] -- [Recommended action]
2. ...
(Top 5 shown; full list on Notion page)

### Tasks Due ([N] total, [N] overdue)
**[Project Name]**
- [ ] [Task title] (P[N]) [OVERDUE: N days if applicable]
- ...
(Full list on Notion page)
```

## Mode 2: Team Pipeline (`--team`)

When `--team` IS present:

1. Read the pipeline configuration at `${CLAUDE_PLUGIN_ROOT}/teams/config.json`.
2. **Phase 1 -- Parallel Gathering**: Launch all 4 gatherer agents simultaneously:
   - **Calendar Agent** -- Fetch and classify all events for the target date, generate prep notes, detect conflicts. Reads its definition from `${CLAUDE_PLUGIN_ROOT}/teams/agents/calendar-agent.md`.
   - **Gmail Agent** -- Search unread emails within the `--hours` window, apply priority scoring, extract highlights. Reads its definition from `${CLAUDE_PLUGIN_ROOT}/teams/agents/gmail-agent.md`.
   - **Notion Agent** -- Query tasks due on target date plus overdue items, group by project, sort by priority. Reads its definition from `${CLAUDE_PLUGIN_ROOT}/teams/agents/notion-agent.md`.
   - **Slack Agent** -- If Slack MCP is configured, fetch mentions and DMs. If unavailable, return immediately with status "unavailable". Reads its definition from `${CLAUDE_PLUGIN_ROOT}/teams/agents/slack-agent.md`.
3. Wait for all gatherers to complete or timeout after 30 seconds. Any agent that times out is marked as "timed out" in the pipeline report. The pipeline continues as long as at least 2 agents return data.
4. **Phase 2 -- Synthesis**: Launch the **Briefing Lead** agent:
   - Reads its definition from `${CLAUDE_PLUGIN_ROOT}/teams/agents/briefing-lead.md`.
   - Merges all gatherer outputs into a unified briefing.
   - Creates (or updates) the Notion page with the full briefing.
   - Writes stats to the "[FOS] Briefings" database (fall back to "Founder OS HQ - Briefings", then "Daily Briefing Generator - Briefings"; skip if none exists). Always sets Type = "Daily Briefing".
   - Calculates a "day complexity" score (Low/Medium/High/Critical) based on meeting density, email urgency, and overdue task count.
5. Present the final briefing URL and pipeline execution summary.

### Output Format (Team Mode)

```
## Daily Briefing -- [YYYY-MM-DD]

**Status**: Generated successfully (team pipeline)
**Notion Page**: [URL]
**Day Complexity**: [Low/Medium/High/Critical]
**Sources**: Calendar [status] | Gmail [status] | Tasks [status] | Slack [status]
**Quick Stats**: [N] meetings | [N] priority emails | [N] tasks due ([N] overdue)

### Pipeline Execution
| Agent          | Status    | Duration | Items Found |
|----------------|-----------|----------|-------------|
| Calendar Agent | [status]  | [time]   | [N] events  |
| Gmail Agent    | [status]  | [time]   | [N] emails  |
| Notion Agent   | [status]  | [time]   | [N] tasks   |
| Slack Agent    | [status]  | [time]   | [N] threads |
| Briefing Lead  | [status]  | [time]   | --          |
**Total pipeline time**: [elapsed]

[Same schedule/email/task sections as default mode]
```

## Observation: End
After execution completes, record a post_command event to the Intelligence event store:
- Event type: `post_command`
- Use the same session_id from the start observation
- Outcome: `success` | `failure` | `degraded`
- Payload: { outcome summary, items processed, outputs created }
- Duration: milliseconds elapsed since pre_command event
- If any errors occurred during execution, also record an error event with the error type, message, and whether recovery was attempted

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Error Handling

- **Notion MCP not configured**: Halt immediately. Display: "Notion MCP is required for briefing output. See `${CLAUDE_PLUGIN_ROOT}/INSTALL.md` for setup instructions."
- **gws CLI not available for Gmail**: Warn: "Gmail unavailable -- email section will be empty." Continue with remaining sources.
- **gws CLI not available for Calendar**: Warn: "Google Calendar unavailable -- schedule section will be empty." Continue with remaining sources.
- **Fewer than 2 sources available**: Halt. Display: "Need at least 2 data sources to generate a meaningful briefing. Currently available: [list]. See INSTALL.md to configure gws CLI or additional MCP servers."
- **Existing briefing for target date**: Update the existing Notion page and database row. Do not create a duplicate. Note in output: "Updated existing briefing."
- **No events/emails/tasks found**: Include the section with "None found" rather than omitting it. This confirms the source was checked.
- **Slack not configured**: Skip silently. Mark as "unavailable" in sources. This is expected for many users.
- **Date in the future**: Allow it (user may be pre-planning), but warn: "Note: [date] is in the future. Calendar events and task deadlines will be shown, but email data may be limited."

## Usage Examples

```
/daily:briefing                          # Quick single-agent briefing for today
/daily:briefing --team                   # Full parallel pipeline for today
/daily:briefing --hours=24               # Look back 24h for emails
/daily:briefing --team --date=2026-02-24 # Yesterday's briefing, full pipeline
/daily:briefing --date=2026-02-26        # Tomorrow's briefing (pre-planning)
```
