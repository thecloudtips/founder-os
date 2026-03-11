# Integration Test Plan: Daily Briefing Generator

## Overview

This test plan covers end-to-end scenarios for the Daily Briefing Generator plugin (#02), mapping to acceptance criteria from the plugin spec. The plugin uses a parallel-gathering pattern: 4 gatherer agents (Calendar, Gmail, Notion, Slack) fetch data simultaneously, then a Briefing Lead agent synthesizes everything into a structured Notion page. Tests require gws CLI for Google Calendar and Gmail, Notion MCP server connection, and optionally Slack MCP.

## Test Environment

- Claude Code with plugin installed
- gws CLI installed and authenticated (`which gws` returns a path, `gws auth login` completed)
- Google Calendar accessible via gws CLI with a test account containing events for target dates
- Gmail accessible via gws CLI with a test account containing unread emails
- Notion MCP configured with workspace access and task databases
- Slack MCP configured (optional, for Slack integration tests)
- Test data prepared:
  - Calendar events for today: at least 5 varied events (internal meetings, external meetings, focus blocks, recurring standups)
  - Unread emails: at least 10 emails spanning priority levels (urgent client requests, FYI updates, newsletters)
  - Notion tasks: at least 8 tasks due today across 2+ projects, plus 3 overdue tasks
  - Slack mentions: at least 2 DMs and 3 channel mentions (for Slack-enabled tests)

---

## Scenario 1: Basic Single-Agent Briefing (Default Mode)

**Goal**: Verify that `/daily:briefing` generates a complete Notion page with all required sections and records stats in the database.

**Preconditions**:
- gws CLI installed and authenticated with Calendar access; 5+ events for today
- gws CLI authenticated with Gmail access; 10+ unread emails in the last 12 hours
- Notion MCP configured with tasks due today

**Steps**:
1. Ensure no "[FOS] Briefings" database exists yet (covered separately in Scenario 11)
2. Run `/daily:briefing`
3. Inspect the Notion page created
4. Verify the output summary shown to the user

**Expected Results**:
- Notion page created with title "Daily Briefing -- [YYYY-MM-DD]"
- Page contains 5 sections in order: Schedule Overview, Priority Emails, Tasks & Deadlines, Slack Activity, Quick Stats
- Schedule Overview lists all calendar events with times, titles, and classifications (`internal-meeting`, `external-meeting`, `focus-block`, `recurring-standup`, or `personal`)
- Meetings with external attendees or 3+ participants include 2-3 line prep notes
- Priority Emails section shows up to 10 highlights grouped by `needs-reply`, `needs-review`, `fyi`
- Each email highlight includes: subject, sender, priority score (1-5), one-line summary, recommended action
- Tasks & Deadlines grouped by project, sorted by priority within each group (P1 > P2 > P3)
- Slack Activity section shows "unavailable" if Slack is not configured (no error)
- Quick Stats summary block shows meeting count, email count, task count, and overdue count
- Output summary displays: Status, Notion Page URL, Sources used, Quick Stats, and elapsed time
- "[FOS] Briefings" database row created with correct metrics
- Elapsed time reported in the output

**Acceptance Criteria Covered**: AC-1 (generates Notion page), AC-2 (meetings with prep notes), AC-3 (priority emails), AC-4 (tasks due today)

---

## Scenario 2: Full Team Pipeline

**Goal**: Verify that `--team` activates the parallel-gathering pipeline with all 5 agents reporting execution details.

**Preconditions**:
- gws CLI installed and authenticated for Calendar and Gmail access
- Notion and Slack MCP servers configured
- Test data seeded for each source

**Steps**:
1. Run `/daily:briefing --team`
2. Observe pipeline execution output
3. Inspect the Notion page and database entry

**Expected Results**:
- Phase 1 (Parallel Gathering): All 4 gatherer agents launch simultaneously:
  - Calendar Agent fetches events and generates prep notes
  - Gmail Agent scans unread emails and applies priority scoring
  - Notion Agent queries due tasks and overdue items
  - Slack Agent fetches mentions and DMs
- Phase 2 (Synthesis): Briefing Lead merges all outputs into a unified briefing
- Pipeline execution summary table shown with 5 rows:
  - Calendar Agent: status, duration, items found
  - Gmail Agent: status, duration, items found
  - Notion Agent: status, duration, items found
  - Slack Agent: status, duration, items found
  - Briefing Lead: status, duration
- All 5 agents show "Done" or "Complete" status
- Total pipeline time reported
- Day Complexity score shown (Low/Medium/High/Critical)
- Notion page created with the same 5-section structure as default mode
- Database row created with all metrics and sources marked as used

**Acceptance Criteria Covered**: AC-1 (generates Notion page), AC-2 (meetings with prep notes), AC-3 (priority emails), AC-4 (tasks due today), AC-5 (generates in <30 seconds)

---

## Scenario 3: Partial Data -- Gmail Unavailable

**Goal**: Verify graceful degradation when gws CLI Gmail access is unavailable, producing a briefing with a warning instead of an error.

**Preconditions**:
- gws CLI Gmail access disabled (unauthenticated or CLI not installed)
- gws CLI Calendar access available; Notion MCP configured with test data

**Steps**:
1. Disable gws CLI Gmail access (e.g., rename gws binary or revoke Gmail scope)
2. Run `/daily:briefing`
3. Inspect the generated Notion page and output summary

**Expected Results**:
- Warning displayed: "Gmail unavailable -- email section will be empty."
- Pipeline does NOT halt (Gmail is a required source per spec, but the plugin degrades gracefully when 2+ sources remain)
- Notion page created with all 5 sections
- Priority Emails section shows "None found" or equivalent empty state (section is present, not omitted)
- Schedule Overview and Tasks & Deadlines sections populated normally
- Sources status shows: Calendar (check) | Gmail (unavailable) | Tasks (check) | Slack (status)
- Database row records Gmail as not used in "Sources Used"
- No stack traces or unhandled errors

**Acceptance Criteria Covered**: AC-1 (generates Notion page with partial data)

---

## Scenario 4: Slack Not Configured

**Goal**: Verify Slack is skipped silently when not configured, with no error and no missing section in the briefing.

**Preconditions**:
- Slack MCP not configured
- gws CLI authenticated for Calendar and Gmail; Notion MCP configured with test data

**Steps**:
1. Ensure Slack MCP is not present in .mcp.json
2. Run `/daily:briefing --team`
3. Inspect pipeline execution summary and Notion page

**Expected Results**:
- Slack Agent reports status "unavailable" immediately in the pipeline table (does not timeout)
- Pipeline continues without error -- minimum 2 gatherers satisfied (Calendar, Gmail, Notion)
- No error message about Slack -- skip is silent
- Notion page contains Slack Activity section with "unavailable" note (section exists but empty)
- Pipeline summary shows "Slack not configured" or "unavailable" for Slack Agent row
- Sources status: Calendar (check) | Gmail (check) | Tasks (check) | Slack (unavailable)
- Database row does not include "Slack" in Sources Used multi-select
- Briefing quality is unaffected by Slack absence

**Acceptance Criteria Covered**: AC-1 (generates Notion page), AC-5 (generates in <30 seconds)

---

## Scenario 5: Custom Email Lookback Window

**Goal**: Verify the `--hours` argument controls the email search window.

**Preconditions**:
- gws CLI authenticated with Gmail access
- Test emails sent at different times:
  - 5 emails received in the last 6 hours
  - 5 emails received between 6-24 hours ago
  - 5 emails received more than 24 hours ago

**Steps**:
1. Run `/daily:briefing --hours=24`
2. Note the email count in the output
3. Run `/daily:briefing --hours=6` (using a different `--date` to avoid duplicate detection)
4. Note the email count in the second run

**Expected Results**:
- With `--hours=24`: emails from the last 24 hours are included (approximately 10 emails)
- With `--hours=6`: only emails from the last 6 hours are included (approximately 5 emails)
- Default `--hours=12` (when flag is omitted) captures emails from the last 12 hours
- Email highlights in the Notion page reflect the specified lookback window
- Priority scoring is applied consistently regardless of lookback window size

**Acceptance Criteria Covered**: AC-3 (lists priority emails requiring response)

---

## Scenario 6: Empty Calendar

**Goal**: Verify the briefing handles a day with no calendar events gracefully.

**Preconditions**:
- gws CLI authenticated with Calendar access
- No events scheduled for the target date
- gws CLI authenticated with Gmail access; Notion MCP configured with data for the target date

**Steps**:
1. Choose a date with no calendar events
2. Run `/daily:briefing --date=[empty-date]`
3. Inspect the Schedule Overview section

**Expected Results**:
- Schedule Overview section is present in the Notion page (not omitted)
- Section content shows "No meetings scheduled today" or equivalent empty-state message
- No scheduling conflict warnings
- No prep notes generated (nothing to prep for)
- Quick Stats shows "0 meetings"
- Database row records Meeting Count as 0
- Remaining sections (emails, tasks) populate normally
- Day Complexity score is lower due to zero meeting density (if using `--team`)

**Acceptance Criteria Covered**: AC-2 (shows today's meetings -- handles empty case)

---

## Scenario 7: Overdue Tasks

**Goal**: Verify that overdue tasks are flagged with the number of days overdue and escalation notes.

**Preconditions**:
- Notion MCP configured with tasks that have past due dates:
  - 1 task overdue by 2 days
  - 1 task overdue by 5 days
  - 1 task overdue by 10 days (> 7 days, should trigger escalation note)
- Tasks due today also present for comparison

**Steps**:
1. Run `/daily:briefing`
2. Inspect the Tasks & Deadlines section on the Notion page

**Expected Results**:
- Overdue tasks appear in the Tasks & Deadlines section alongside today's tasks
- Each overdue task shows the number of days overdue (e.g., "OVERDUE: 2 days", "OVERDUE: 5 days", "OVERDUE: 10 days")
- Tasks overdue by more than 7 days include an escalation note (per task-curation skill)
- Overdue tasks are visually distinguishable from on-time tasks
- Quick Stats shows the correct overdue count (3 in this case)
- Database row records the accurate Overdue Tasks count
- Overdue tasks are sorted by priority within their project groups, not by days overdue

**Acceptance Criteria Covered**: AC-4 (shows tasks due today from Notion)

---

## Scenario 8: Duplicate Briefing -- Re-Run for Same Date

**Goal**: Verify that running the briefing command again for the same date updates the existing page and database row instead of creating duplicates.

**Preconditions**:
- A briefing already exists for today (run `/daily:briefing` first)
- "[FOS] Briefings" database contains a row for today
- Notion page "Daily Briefing -- [YYYY-MM-DD]" exists

**Steps**:
1. Run `/daily:briefing` to generate the initial briefing (note the Notion page URL and DB row)
2. Wait a few minutes, then run `/daily:briefing` again
3. Check the Notion workspace for the database and page

**Expected Results**:
- Output includes note: "Updating existing briefing for [date]." (or "Updated existing briefing.")
- The existing Notion page is updated in place (same URL, same page ID)
- No second page titled "Daily Briefing -- [YYYY-MM-DD]" is created
- The database still contains exactly one row for the target date (not two)
- Database row metrics are refreshed with current data (meeting count, email count, etc.)
- "Generated At" timestamp is updated to the re-run time
- Notion page content reflects the latest data from all sources

**Acceptance Criteria Covered**: AC-1 (generates Notion page -- no duplicate creation)

---

## Scenario 9: Daily Review with Changes

**Goal**: Verify `/daily:review` detects changes since the morning briefing and appends an "Updates Since Morning" section to the existing Notion page.

**Preconditions**:
- A briefing was generated earlier today via `/daily:briefing`
- After generation, the following changes occurred:
  - 1 new calendar event added
  - 1 existing meeting cancelled
  - 2 new high-priority emails received (Q1 or Q2)
  - 1 task marked as completed in Notion
  - 1 task became overdue (due time has passed)

**Steps**:
1. Run `/daily:review`
2. Inspect the Notion page for the appended section
3. Verify the database row was updated

**Expected Results**:
- Output summary shows changes since the original Generated At time:
  - Schedule: 2 changes (1 new meeting, 1 cancelled)
  - Emails: 2 new priority emails
  - Tasks: 2 updates (1 completed, 1 new overdue)
- Notion page has a divider block appended after the original content
- "Updates Since Morning" heading (H2) appears below the divider
- Timestamp paragraph: "Updated at [HH:MM AM/PM] -- changes since [original Generated At]"
- Sub-sections (H3) only appear for sources with changes:
  - Schedule Changes: lists the new and cancelled meetings
  - New Priority Emails: lists Q1/Q2 emails with sender, subject, summary, action
  - Task Updates: lists completed tasks, new overdue items
- Callout blocks with warning icons for Q1 emails and newly overdue tasks
- Original briefing content above the divider is NOT modified
- Database row "Generated At" updated to current timestamp
- Database row metrics incremented appropriately (Email Count +2, Overdue Tasks updated)
- Notion Page URL in output matches the existing page (same URL)

**Acceptance Criteria Covered**: AC-1 (updates Notion page), AC-3 (priority emails), AC-4 (tasks)

---

## Scenario 10: Daily Review with No Changes

**Goal**: Verify `/daily:review` reports cleanly when nothing has changed since the morning briefing.

**Preconditions**:
- A briefing was generated earlier today
- No new emails, calendar changes, or task updates have occurred since generation

**Steps**:
1. Run `/daily:review` immediately after generating a briefing (minimal time for changes)
2. Inspect the output

**Expected Results**:
- Output message: "No changes since your morning briefing at [Generated At time]. Everything is on track."
- Notion page is NOT modified (no divider or update section appended)
- Database row is NOT modified (Generated At timestamp unchanged)
- No error messages or warnings
- Command completes quickly (no full data re-fetch needed once zero changes confirmed)

**Acceptance Criteria Covered**: AC-1 (Notion page integrity preserved)

---

## Scenario 11: Consolidated DB Discovery and Fallback

**Goal**: Verify that the plugin discovers the consolidated "[FOS] Briefings" database, falls back to the legacy "Daily Briefing Generator - Briefings" database, and does not create a new database if neither exists.

**Preconditions**:
- All required MCP servers configured (Calendar, Gmail, Notion)

**Steps**:
1. **Sub-scenario A**: Ensure "[FOS] Briefings" database exists. Run `/daily:briefing`. Verify it writes to the consolidated DB with Type = "Daily Briefing".
2. **Sub-scenario B**: Remove "[FOS] Briefings", ensure legacy "Daily Briefing Generator - Briefings" exists. Run `/daily:briefing`. Verify it falls back to the legacy DB.
3. **Sub-scenario C**: Remove both databases. Run `/daily:briefing`. Verify no database is created and the briefing is output to chat only.
4. **Sub-scenario D**: With "[FOS] Briefings" present, run `/daily:briefing` twice for the same date. Verify idempotent upsert by Date + Type = "Daily Briefing".

**Expected Results**:
- Sub-scenario A: Row created in "[FOS] Briefings" with Type = "Daily Briefing" and Content property populated
- Sub-scenario B: Row created in legacy DB (fallback works)
- Sub-scenario C: Briefing output to chat, no database created, no error
- Sub-scenario D: Exactly one row for the date with Type = "Daily Briefing" (updated, not duplicated)
- All rows include Type = "Daily Briefing" select property
- Briefing link stored in "Content" property (not "Briefing")

**Acceptance Criteria Covered**: AC-1 (generates Notion page)

---

## Scenario 12: Minimum Gatherer Threshold Failure

**Goal**: Verify the pipeline halts with a clear error when fewer than 2 data sources are available.

**Preconditions**:
- Only Notion MCP configured (gws CLI not installed or not authenticated for Calendar and Gmail)
- Slack MCP not configured
- Result: only 1 of 3 required sources available

**Steps**:
1. Disable gws CLI access (uninstall or revoke auth) for Calendar and Gmail (keep only Notion MCP)
2. Run `/daily:briefing --team`
3. Observe the error output

**Expected Results**:
- Pipeline halts before attempting any data gathering
- Error message: "Need at least 2 data sources to generate a meaningful briefing. Currently available: [Notion]. See INSTALL.md to configure gws CLI or additional MCP servers."
- No Notion page created
- No database row created
- No partial results shown
- Clean exit with no stack traces
- The error references INSTALL.md for setup guidance

**Acceptance Criteria Covered**: AC-1 (error handling -- prevents low-quality briefing from insufficient sources)

---

## Scenario 13: Notion MCP Unavailable -- Hard Halt

**Goal**: Verify that missing Notion MCP causes an immediate halt since Notion is the required output target.

**Preconditions**:
- Notion MCP disabled (unset NOTION_API_KEY or remove from .mcp.json)
- gws CLI authenticated for Calendar and Gmail

**Steps**:
1. Disable Notion MCP
2. Run `/daily:briefing`
3. Run `/daily:briefing --team`

**Expected Results**:
- Both modes halt immediately with clear error message
- Error: "Notion MCP is required for briefing output. See [INSTALL.md path] for setup instructions."
- No data fetched from Calendar or Gmail via gws CLI (no wasted API calls)
- No partial processing attempted
- Clean exit, no stack traces

**Acceptance Criteria Covered**: AC-1 (Notion required for output)

---

## Scenario 14: Performance -- Under 30 Seconds

**Goal**: Verify the briefing generates within the 30-second acceptance criterion under normal conditions.

**Preconditions**:
- gws CLI authenticated; Notion MCP configured; typical data volumes:
  - 5-10 calendar events
  - 20-30 unread emails
  - 10-15 tasks due today

**Steps**:
1. Run `/daily:briefing` and record the elapsed time from the output
2. Run `/daily:briefing --team` and record the total pipeline time from the execution summary
3. Repeat each 3 times and note the average

**Expected Results**:
- Default mode: completes in under 30 seconds (average across 3 runs)
- Team mode: total pipeline time under 30 seconds (parallel gathering should be faster than sequential)
- Elapsed time is reported in the output summary
- Individual agent durations (team mode) are reported in the pipeline execution table
- No agent exceeds the 30-second per-agent timeout defined in teams/config.json
- Briefing Lead synthesis completes within 10 seconds of receiving all gatherer outputs

**Acceptance Criteria Covered**: AC-5 (generates in <30 seconds)

---

## Scenario 15: Meeting Prep Notes for External Meetings

**Goal**: Verify that external meetings and meetings with 3+ participants include contextual prep notes in the briefing.

**Preconditions**:
- gws CLI authenticated with Calendar access; events configured:
  - 1 external meeting (attendees from outside the organization domain)
  - 1 internal meeting with 4 participants
  - 1 internal 1:1 meeting (2 participants, no prep notes expected)
  - 1 recurring standup (no prep notes expected)

**Steps**:
1. Run `/daily:briefing`
2. Inspect the Schedule Overview section on the Notion page

**Expected Results**:
- External meeting includes 2-3 line prep notes with attendee context
- Internal meeting with 4 participants includes 2-3 line prep notes
- Internal 1:1 meeting has NO prep notes (below the 3-participant threshold)
- Recurring standup has NO prep notes (classified as `recurring-standup`)
- Prep notes are relevant to the meeting topic (not generic filler)
- Scheduling conflicts (overlapping events) are flagged if present
- Each event shows its classification label

**Acceptance Criteria Covered**: AC-2 (shows today's meetings with prep notes)

---

## Scenario 16: Daily Review -- No Existing Briefing

**Goal**: Verify `/daily:review` provides a clear message when no briefing exists for the specified date.

**Preconditions**:
- No briefing has been generated for the target date
- "[FOS] Briefings" database may or may not exist

**Steps**:
1. Run `/daily:review --date=2025-01-01` (a date with no briefing)
2. Observe the output

**Expected Results**:
- If database exists but no row for the date: "No briefing found for 2025-01-01. Run `/daily:briefing` first to generate one."
- If database does not exist: "No briefing database found. Run `/daily:briefing` first to generate your initial briefing."
- No Notion page modifications
- No errors or stack traces
- Command exits cleanly

**Acceptance Criteria Covered**: AC-1 (error handling for review command)

---

## Summary Matrix

| Scenario | Command | Acceptance Criteria | MCP Required |
|----------|---------|-------------------|--------------|
| 1. Basic Single-Agent Briefing | `/daily:briefing` | AC-1, AC-2, AC-3, AC-4 | Calendar, Gmail, Notion |
| 2. Full Team Pipeline | `/daily:briefing --team` | AC-1, AC-2, AC-3, AC-4, AC-5 | Calendar, Gmail, Notion, Slack |
| 3. Gmail Unavailable | `/daily:briefing` | AC-1 | Calendar, Notion |
| 4. Slack Not Configured | `/daily:briefing --team` | AC-1, AC-5 | Calendar, Gmail, Notion |
| 5. Custom Email Lookback | `/daily:briefing --hours=N` | AC-3 | Gmail |
| 6. Empty Calendar | `/daily:briefing` | AC-2 | Calendar, Gmail, Notion |
| 7. Overdue Tasks | `/daily:briefing` | AC-4 | Notion |
| 8. Duplicate Briefing | `/daily:briefing` (re-run) | AC-1 | Calendar, Gmail, Notion |
| 9. Review with Changes | `/daily:review` | AC-1, AC-3, AC-4 | Calendar, Gmail, Notion |
| 10. Review No Changes | `/daily:review` | AC-1 | Calendar, Gmail, Notion |
| 11. Consolidated DB Discovery | `/daily:briefing` | AC-1 | Calendar, Gmail, Notion |
| 12. Min Gatherer Threshold | `/daily:briefing --team` | AC-1 | Notion only |
| 13. Notion Unavailable | `/daily:briefing` | AC-1 | Calendar, Gmail |
| 14. Performance | `/daily:briefing`, `--team` | AC-5 | Calendar, Gmail, Notion |
| 15. Meeting Prep Notes | `/daily:briefing` | AC-2 | Calendar |
| 16. Review No Briefing | `/daily:review` | AC-1 | Notion |
