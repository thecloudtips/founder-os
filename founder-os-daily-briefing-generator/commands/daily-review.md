---
description: Review and update today's daily briefing with new information received since it was generated
argument-hint: "--date=2026-02-25"
allowed-tools: ["Read"]
---

# Review & Update Daily Briefing

Find an existing daily briefing for the specified date, check all sources for changes since it was generated, and append an "Updates Since Morning" section to the Notion briefing page.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `--date=YYYY-MM-DD` (date, default: today's date) -- the date of the briefing to review and update

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Process

1. Read the briefing-assembly skill at `${CLAUDE_PLUGIN_ROOT}/skills/briefing-assembly/SKILL.md` for Notion page format, database schema, section structure, and quality standards.

2. **Locate existing briefing**:
   - Search Notion for the "[FOS] Briefings" database using the search API by title.
   - If not found, try "Founder OS HQ - Briefings". If not found, fall back to "Daily Briefing Generator - Briefings".
   - If no database is found, halt with: "No briefing database found. Run `/daily:briefing` first to generate your initial briefing."
   - Query the database for a row where the Date property matches the specified date AND Type = "Daily Briefing".
   - If no row exists for the date and type, inform the user: "No briefing found for [date]. Run `/daily:briefing` first to generate one."

3. **Extract baseline timestamp**:
   - Read the "Generated At" property from the matching database row.
   - This timestamp is the cutoff -- only surface changes that occurred after this time.
   - Store the original "Generated At" value for display in the update summary.

4. **Check calendar updates** (if gws CLI is available -- verify with `which gws`):
   - Retrieve today's events using `gws calendar +agenda --today --format json` and compare against the Schedule Overview section in the existing briefing.
   - Identify changes since the Generated At timestamp:
     - New meetings added to the calendar.
     - Cancelled or deleted meetings.
     - Time or location changes for existing meetings.
     - New attendee additions or RSVPs.
   - For each change, note the meeting title and what changed.

5. **Check email updates** (if gws CLI is available -- verify with `which gws`):
   - Search for unread emails received after the Generated At timestamp using `gws gmail users messages list --params '{"userId":"me","q":"is:unread after:YYYY/MM/DD","maxResults":50}' --format json`.
   - Read the email-prioritization skill at `${CLAUDE_PLUGIN_ROOT}/skills/email-prioritization/SKILL.md` for the Eisenhower matrix, sender tier classification, and scoring signals.
   - Apply the same priority scoring from the email-prioritization skill to new emails.
   - Only surface Q1 and Q2 emails. Ignore Q3 and Q4 emails -- the morning briefing already covers lower-priority items.
   - Extract highlights using the same format: sender, subject, summary, quadrant, action needed.

6. **Check task updates** (if Notion MCP is available):
   - Search the user's task databases for changes since the Generated At timestamp.
   - Identify:
     - Newly completed tasks (status changed to Done/Complete since Generated At).
     - New overdue items (tasks whose due date has now passed).
     - Newly assigned tasks (tasks created or assigned to the user since Generated At).
   - For each change, note the task title, project, and what changed.

7. **Determine if updates exist**:
   - If no changes were found across all sources, output the no-changes message (see Output Format below) and stop. Do not modify the Notion page.

8. **Assemble update section**:
   - Build an "Updates Since Morning" section with the following sub-sections.
   - Only include sub-sections that have actual changes. Omit any sub-section with zero items.
   - **Schedule Changes**: List each calendar change with the meeting title and description of the change (added, cancelled, rescheduled, new attendees).
   - **New Priority Emails**: List each new Q1/Q2 email with sender, subject, one-line summary, and required action. Q1 emails first, then Q2.
   - **Task Updates**: List completed tasks, new overdue items, and newly assigned tasks. Group by change type.
   - Include a timestamp header: "Updated at [HH:MM AM/PM]".

9. **Append to Notion page**:
   - Retrieve the Briefing field (rich_text with the page URL) from the database row. Use the URL to locate the Notion page. If the URL is missing, search for a page titled "Daily Briefing -- [YYYY-MM-DD]" as fallback.
   - Append the following blocks to the bottom of the existing briefing page:
     - A divider block for visual separation from the original briefing.
     - A Heading 2 block: "Updates Since Morning".
     - A paragraph block with the timestamp: "Updated at [HH:MM AM/PM] -- changes since [original Generated At time]".
     - Sub-headings (Heading 3) and bulleted lists for each included sub-section.
     - Use callout blocks with warning icons for new Q1 emails and newly overdue tasks.
   - Do not modify any existing content on the page. Append only.

10. **Update database entry**:
    - Update the "Generated At" property to the current timestamp.
    - Adjust metric counts if changes affect them:
      - Increment Email Count by the number of new Q1/Q2 emails surfaced.
      - Increment Task Count if new tasks were assigned.
      - Update Overdue Tasks count if new overdue items appeared.
      - Update Meeting Count if meetings were added or cancelled.

## Output Format

When updates are found:

```
## Briefing Update -- [YYYY-MM-DD] at [HH:MM AM/PM]

**Changes since [original Generated At time]:**
- Schedule: [N] changes ([description: e.g., 1 new meeting, 1 cancelled])
- Emails: [N] new priority emails
- Tasks: [N] updates ([description: e.g., 2 completed, 1 new overdue])

**Notion Page**: [page URL] (updated)
```

Only include source lines that have changes. Omit lines with zero changes.

When no changes are found:

```
No changes since your morning briefing at [Generated At time]. Everything is on track.
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Error Handling

- **No briefing database found**: Halt with message suggesting `/daily:briefing` first.
- **No briefing for the specified date**: Inform the user and suggest running `/daily:briefing` to generate one.
- **Notion MCP unavailable**: Output the assembled update section as formatted markdown to the console. Note: "Notion is unavailable -- displaying update in console. Briefing page was not modified."
- **gws CLI unavailable for Gmail**: Skip email updates. Report only calendar and task changes. Note which sources were checked in the output.
- **gws CLI unavailable for Calendar**: Skip calendar updates. Report only email and task changes.
- **All update sources unavailable**: Inform the user: "Cannot check for updates -- no data sources are reachable. Verify MCP server connections."
- **Briefing URL missing from database row**: Search Notion for a page titled "Daily Briefing -- [YYYY-MM-DD]" as a fallback. If still not found, output the update to the console.

## Usage Examples

```
/daily:review                    # Review today's briefing for updates
/daily:review --date=2026-02-24  # Review yesterday's briefing for updates
```
