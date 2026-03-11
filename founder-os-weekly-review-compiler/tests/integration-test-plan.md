# Integration Test Plan: Weekly Review Compiler

## Test Environment

- Notion workspace with 2+ databases containing Status and Date properties
- At least 5 completed tasks across databases within the past week
- Google Calendar with events in the past week (mix of internal and external)
- Gmail configured (optional -- some tests verify graceful degradation without it)
- Notion integration API key configured

## Test Scenarios

### Scenario 1: Default Weekly Review (All Sources Available)

**Command**: `/weekly:review`

**Expected**:
- Reviews the most recently completed week (previous Monday-Sunday)
- Auto-discovers task databases
- Pulls calendar events and Gmail threads
- Creates a 6-section Notion page in "[FOS] Briefings" database

**Verify**:
- [ ] Week boundaries correctly resolve to previous Monday-Sunday
- [ ] Task databases auto-discovered (names reported in output)
- [ ] Completed tasks grouped by project
- [ ] Calendar events classified (internal/external/one-on-one)
- [ ] Meeting hours and density calculated
- [ ] Gmail threads filtered (2+ sent messages threshold)
- [ ] Blockers detected from multiple signals
- [ ] Next-week priorities scored and ranked top 5
- [ ] Notion page created with correct title format "Weekly Review -- YYYY-MM-DD"
- [ ] Database row populated with all metrics and Type = "Weekly Review"
- [ ] Sources Used reflects which MCP servers returned data
- [ ] Confirmation summary displayed to user

### Scenario 2: Specific Week via --date

**Command**: `/weekly:review --date=2026-02-24`

**Expected**:
- Reviews the week containing Feb 24 (Mon Feb 23 - Sun Mar 1)
- Uses the same pipeline as default but with explicit date

**Verify**:
- [ ] Week boundaries resolve to Mon Feb 23 - Sun Mar 1
- [ ] Title is "Weekly Review -- 2026-02-23" (Monday date)
- [ ] Tasks filtered to the correct date window
- [ ] Calendar events filtered to the correct date window

### Scenario 3: Chat-Only Output

**Command**: `/weekly:review --output=chat`

**Expected**:
- Full review displayed in conversation
- No Notion page created

**Verify**:
- [ ] All 6 sections rendered in chat
- [ ] No Notion write operations
- [ ] Confirmation summary shows no Notion URL

### Scenario 4: Both Output

**Command**: `/weekly:review --output=both`

**Expected**:
- Review displayed in chat AND saved to Notion

**Verify**:
- [ ] Chat output matches Notion page content
- [ ] Notion page URL displayed in confirmation

### Scenario 5: Idempotent Re-Run

**Command**: `/weekly:review` (run twice for the same week)

**Expected**:
- Second run updates the existing review page
- No duplicate row in the database

**Verify**:
- [ ] Existing review detected by Date + Type = "Weekly Review": "Updating existing review for week of [date]"
- [ ] Notion page updated (not duplicated)
- [ ] Database row updated (not duplicated)
- [ ] Generated At timestamp updated to second run time
- [ ] Type property remains "Weekly Review"

### Scenario 6: Calendar Unavailable

**Setup**: Disconnect Google gws CLI (Calendar)

**Command**: `/weekly:review --output=chat`

**Expected**:
- Warning about Calendar unavailability
- Meetings section shows placeholder
- Review proceeds with Notion data only

**Verify**:
- [ ] Warning displayed: "Calendar unavailable"
- [ ] Section 2 shows: "Calendar data unavailable -- meeting summary skipped."
- [ ] Meeting-heavy-day blocker signal excluded
- [ ] "Calendar" not in Sources Used
- [ ] Section 6 calendar preview omitted
- [ ] All other sections populated normally

### Scenario 7: Gmail Unavailable

**Setup**: Disconnect gws CLI (Gmail)

**Command**: `/weekly:review --output=chat`

**Expected**:
- Gmail skipped silently
- Communication section shows placeholder
- Review proceeds normally

**Verify**:
- [ ] No error or warning about Gmail
- [ ] Section 3 shows: "Gmail data unavailable -- email summary skipped."
- [ ] Unresolved-thread blocker signal excluded
- [ ] "Gmail" not in Sources Used
- [ ] All other sections populated normally

### Scenario 8: Zero Task Databases Discovered

**Setup**: Use a Notion workspace with no qualifying task databases

**Command**: `/weekly:review --output=chat`

**Expected**:
- Warning: "No task databases discovered"
- Review continues with Calendar and Gmail data
- Wins and priorities sections show empty state

**Verify**:
- [ ] Warning message displayed
- [ ] Section 1 metrics show 0 tasks completed
- [ ] Section 2 (Wins) shows empty-state message
- [ ] Section 5 (Priorities) shows: "No upcoming tasks found"
- [ ] Calendar and Gmail sections populated normally

### Scenario 9: Consolidated DB Discovery and Fallback

**Setup**: Test three sub-scenarios for database discovery

**Sub-scenario A**: "[FOS] Briefings" database exists
**Command**: `/weekly:review`
**Verify**:
- [ ] Writes to "[FOS] Briefings" with Type = "Weekly Review"
- [ ] Content property contains executive summary
- [ ] Idempotent upsert by Date + Type = "Weekly Review"

**Sub-scenario B**: Only legacy "Weekly Review Compiler - Reviews" database exists
**Command**: `/weekly:review`
**Verify**:
- [ ] Falls back to legacy database
- [ ] Review page created as row in legacy DB

**Sub-scenario C**: Neither database exists
**Command**: `/weekly:review`
**Verify**:
- [ ] No database is created
- [ ] Review output to chat only
- [ ] No error or stack trace

### Scenario 10: Future Date Warning

**Command**: `/weekly:review --date=2026-12-01`

**Expected**:
- Warning about future date
- Review generated with incomplete data

**Verify**:
- [ ] Warning: "Note: [date] is in the future. Review data may be incomplete."
- [ ] Pipeline runs without error
- [ ] Sections show empty-state messages where no data exists

### Scenario 11: High Task Volume (>100 completed)

**Setup**: Workspace with many databases and high completion volume

**Command**: `/weekly:review --output=chat`

**Expected**:
- All tasks counted accurately
- Display capped at 20 per group with overflow message

**Verify**:
- [ ] Total count accurate in Executive Summary
- [ ] Per-project groups cap display at 20 items
- [ ] Overflow message: "[X] additional tasks completed"
- [ ] No performance degradation or timeout

### Scenario 12: Blocker Multi-Signal Detection

**Setup**: Create tasks with various blocker signals:
- One task with "Blocked" status
- One task overdue by 14+ days
- One task "In Progress" with no edits for 7+ days

**Command**: `/weekly:review --output=chat`

**Expected**:
- All three blocker types detected
- Classified by severity: Critical/Warning/Watch

**Verify**:
- [ ] Explicit blocked task classified as Critical
- [ ] 14+ day overdue task classified as Critical
- [ ] Stagnant task classified as Warning or Watch
- [ ] Sorted by severity (Critical first)
- [ ] Blocker count accurate in Executive Summary

## Edge Cases

### Invalid Date Format

**Command**: `/weekly:review --date=not-a-date`

**Verify**:
- [ ] Clear error message about invalid date format
- [ ] No partial review generated

### Notion MCP Unavailable

**Setup**: Disconnect Notion MCP

**Command**: `/weekly:review`

**Verify**:
- [ ] Immediate halt with clear message
- [ ] Reference to INSTALL.md for setup instructions

### Empty Week (Zero Data From All Sources)

**Verify**:
- [ ] Review generated with empty-state messages in all sections
- [ ] "Quiet week" messaging (not error messaging)
- [ ] No fabricated content
