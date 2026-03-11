# Integration Test Plan: Smart Follow-Up Tracker

## Overview

This test plan validates the P06 Smart Follow-Up Tracker plugin against all acceptance criteria. Tests cover all three commands (`/followup:check`, `/followup:nudge`, `/followup:remind`), both skills (follow-up-detection, nudge-writing), Notion integration, Calendar integration, and edge cases.

## Prerequisites

- Plugin installed in Claude Code
- gws CLI (Gmail) configured with valid OAuth credentials
- Notion MCP configured with valid API key (for Notion tests)
- Google gws CLI (Calendar) configured (for Calendar tests)
- At least 5 sent emails in Gmail from the last 30 days, with some awaiting replies

---

## Test 1: Basic Follow-Up Scan

**Priority**: P0
**Command**: `/followup:check`
**Expected**:
- Scans Gmail sent folder (default 30 days)
- Identifies emails where user sent the last message
- Displays structured table with: Subject, Recipient, Days Waiting, Priority, Promise Type, Suggested Action
- Results sorted by priority descending, then age descending

---

## Test 2: Follow-Up Scan with Date Filter

**Priority**: P0
**Command**: `/followup:check --days=7`
**Expected**:
- Only shows emails from the last 7 days
- Respects the narrower lookback window
- Fewer results than a 30-day scan

---

## Test 3: Priority Filtering

**Priority**: P0
**Command**: `/followup:check --priority=high`
**Expected**:
- Only displays follow-ups with priority >= 3 (Firm, Urgent, Critical)
- Priority 1-2 items excluded from output
- Count reflects filtered results

---

## Test 4: Nudge Email Drafting

**Priority**: P0
**Command**: `/followup:nudge [thread_id]`
**Setup**: Use a thread ID from a `/followup:check` result where the email is 3-7 days old
**Expected**:
- Fetches full email thread from Gmail
- Auto-selects escalation Level 1 (Gentle) for 3-7 day age
- Drafts a professional nudge email following nudge-writing skill rules
- Creates a Gmail draft (not sent)
- Shows draft preview in chat with To, Subject, Escalation level, Relationship type

---

## Test 5: Promise Detection in Sent Emails

**Priority**: P0
**Command**: `/followup:check`
**Setup**: Send a test email containing "I will send you the proposal by Friday" and wait for it to appear in sent folder
**Expected**:
- Detects outbound promise ("I will send you")
- Promise Type = "Promise Made"
- Promise text extracted and displayed
- Priority boosted if promise deadline has passed

---

## Test 6: Promise Detection in Received Emails

**Priority**: P0
**Command**: `/followup:check`
**Setup**: Have a thread where someone replied "I will get back to you on this" and no further reply arrived
**Expected**:
- Detects inbound promise ("I will get back to you")
- Promise Type = "Promise Received"
- Thread tracked even though user didn't send the last message

---

## Test 7: Notion HQ Database Discovery and Fallback

**Priority**: P1
**Setup**: Ensure "[FOS] Tasks" database exists in Notion (or test fallback with only legacy "Follow-Up Tracker - Follow-Ups")
**Command**: `/followup:check`

### 7a: HQ Database Present
**Expected**:
- Plugin searches for "[FOS] Tasks" database first
- Database found
- Follow-up records created with `Type = "Follow-Up"` and `Source Plugin = "Follow-Up Tracker"`
- Title mapped from Subject, Contact relation set when recipient matches CRM, Company relation set when domain matches
- Default values: Status = "Waiting", Nudge Count = 0
- All reads filtered by `Type = "Follow-Up"`

### 7b: HQ Missing, Legacy Present
**Setup**: Remove HQ database access, ensure legacy "Follow-Up Tracker - Follow-Ups" exists
**Expected**:
- Plugin falls back to legacy database
- Records created/updated in legacy database

### 7c: Neither Database Present
**Setup**: Neither HQ nor legacy database accessible
**Expected**:
- Graceful degradation to chat output
- Warning message displayed
- No database creation attempted

---

## Test 8: Graceful Degradation Without Notion

**Priority**: P0
**Setup**: Disable Notion MCP (remove or invalidate API key)
**Command**: `/followup:check`
**Expected**:
- Follow-ups scanned and displayed normally in chat
- Warning: "Notion unavailable -- displaying results in chat..."
- No error or crash
- All fields visible in chat output

---

## Test 9: Graceful Degradation Without Calendar

**Priority**: P1
**Setup**: Disable Google gws CLI (Calendar)
**Command**: `/followup:remind [thread_id]`
**Expected**:
- Reminder details displayed as structured text in chat
- Suggestion to add reminders manually
- Reference to INSTALL.md for Calendar setup
- No error or crash

---

## Test 10: Exclusion Rules

**Priority**: P1
**Command**: `/followup:check`
**Setup**: Ensure sent folder contains emails to no-reply addresses, newsletter replies, and normal business emails
**Expected**:
- Emails to no-reply/noreply addresses excluded
- Newsletter and mailing list threads excluded
- Auto-reply threads excluded
- Brief confirmation acknowledgments ("Thanks", "Got it") excluded
- Normal business emails included

---

## Test 11: Nudge Escalation Levels

**Priority**: P1
**Command**: `/followup:nudge`
**Test 3 threads with different ages**:

### 11a: Gentle (3-7 days)
**Expected**: Level 1 nudge, 2-3 sentences, warm tone, single question CTA

### 11b: Firm (7-14 days)
**Expected**: Level 2 nudge, 3-4 sentences, references specific date, proposes next step, [Follow-up] in subject

### 11c: Urgent (14+ days)
**Expected**: Level 3 nudge, 4-5 sentences, states urgency directly, offers alternatives, [Follow-up] in subject

---

## Test 12: Idempotent Re-Runs

**Priority**: P1
**Setup**: Run `/followup:check` twice with Notion enabled and "[FOS] Tasks" database present
**Expected**:
- First run: Creates new records in HQ database with `Type = "Follow-Up"`
- Second run: Updates existing records (Days Waiting, Priority recalculated), queried with `Type = "Follow-Up"` filter
- No duplicate entries created
- Thread ID used as unique key within `Type = "Follow-Up"` scope

---

## Test 13: Calendar Reminder Creation

**Priority**: P1
**Command**: `/followup:remind [thread_id]`
**Expected**:
- Creates Google Calendar event with title "Follow up: [subject]"
- Reminder date auto-calculated based on priority
- Event description includes thread context, recipient, days waiting
- 30-minute notification set
- Calendar event link displayed

---

## Test 14: Batch Calendar Reminders

**Priority**: P2
**Command**: `/followup:remind --all`
**Setup**: Run `/followup:check` first to populate pending follow-ups
**Expected**:
- Creates reminders for all pending follow-ups with priority >= 2
- Skips priority 1 (monitor only) items
- Reminder times staggered by 15-minute intervals
- Summary table with all created reminders

---

## Test 15: Nudge Tone Override

**Priority**: P2
**Command**: `/followup:nudge [thread_id] --tone=urgent`
**Setup**: Use a thread that is only 3 days old (would normally be Level 1)
**Expected**:
- Overrides auto-calculated Level 1 with Level 3 (Urgent)
- Nudge drafted with urgent tone despite low age
- [Follow-up] tag added to subject

---

## Test 16: Edge Cases

### 16a: Empty Sent Folder
**Command**: `/followup:check --days=1`
**Setup**: Ensure no emails sent in the last day
**Expected**: "No sent emails found in the last 1 days. Nothing to track."

### 16b: All Emails Have Replies
**Command**: `/followup:check`
**Setup**: All recent sent emails have received replies
**Expected**: "No emails awaiting response in the last 30 days. Inbox is clear!"

### 16c: Invalid Thread ID for Nudge
**Command**: `/followup:nudge nonexistent_thread_id`
**Expected**: Clear error message indicating thread not found

### 16d: Subject Keyword Search
**Command**: `/followup:nudge "quarterly budget"`
**Expected**: Searches sent folder for matching subject, finds most recent match, proceeds with nudge

### 16e: Reminder with Explicit Delay
**Command**: `/followup:remind [thread_id] --in=5d`
**Expected**: Reminder created exactly 5 days from today, regardless of priority

### 16f: Self-Sent Emails
**Setup**: User has sent emails to their own address (notes-to-self)
**Expected**: Self-sent threads excluded from follow-up check results

---

## Test Summary

| # | Test Case | Priority | Acceptance Criterion |
|---|-----------|----------|---------------------|
| 1 | Basic follow-up scan | P0 | Core scanning functionality |
| 2 | Date filter | P0 | --days flag works |
| 3 | Priority filtering | P0 | --priority=high filters correctly |
| 4 | Nudge email drafting | P0 | Gmail draft created |
| 5 | Promise detection (sent) | P0 | Outbound promises tracked |
| 6 | Promise detection (received) | P0 | Inbound promises tracked |
| 7a-c | Notion HQ DB discovery & fallback | P1 | HQ preferred, legacy fallback, graceful degradation |
| 8 | Graceful degradation (Notion) | P0 | Works without Notion |
| 9 | Graceful degradation (Calendar) | P1 | Works without Calendar |
| 10 | Exclusion rules | P1 | No-reply, newsletters filtered |
| 11a-c | Nudge escalation levels | P1 | 3 levels work correctly |
| 12 | Idempotent re-runs | P1 | No duplicates on re-run |
| 13 | Calendar reminder creation | P1 | Single reminder works |
| 14 | Batch calendar reminders | P2 | --all creates multiple |
| 15 | Nudge tone override | P2 | --tone flag overrides |
| 16a-f | Edge cases | P2 | Robustness |
