# Integration Test Plan: CRM Sync Hub

Plugin #21 | Standalone | Claude Code

## Prerequisites

- Claude Code with Notion, Gmail, and gws CLI (`gws calendar`)s configured
- Notion workspace with CRM Pro template (Companies, Contacts, Communications, Deals databases)
- Gmail account with sent emails
- Google Calendar with past and upcoming meetings
- At least one CRM client with a known email domain

## Test Scenarios

### Scenario 1: Single Email Sync
**Command**: `/crm:sync-email [thread_id]`
**Preconditions**: gws CLI (Gmail) configured, known thread_id from sent folder, matching client in CRM
**Expected behavior**:
- Retrieves email thread from Gmail
- Matches sender/recipients to CRM client (shows confidence tier)
- Generates 2-3 sentence AI summary
- Creates Communications DB record with Title, Type, Date, Contact, Company, Summary, Sentiment
- Displays confirmation with client name, confidence, and summary preview
**Pass criteria**: Communications record created with all required fields populated

### Scenario 2: Batch Email Sync (7 days)
**Command**: `/crm:sync-email --since=7d`
**Preconditions**: gws CLI (Gmail) configured, sent emails in last 7 days
**Expected behavior**:
- Scans sent folder for threads in date range
- Filters: skips internal emails, automated emails, very short threads
- Checks Communications DB for already-synced threads
- Processes each unsynced thread through the full pipeline
- Produces batch status report with Synced/Updated/Skipped/Unmatched/Failed counts
**Pass criteria**: Batch report displayed, new records created, no duplicates

### Scenario 3: Single Meeting Sync
**Command**: `/crm:sync-meeting [event_id]`
**Preconditions**: gws CLI (Calendar) configured, known event_id, matching client in CRM
**Expected behavior**:
- Retrieves event from Google Calendar
- Matches attendees to CRM client
- Generates summary from title, description, attendees
- Creates Communications DB record with Type "Meeting Held" (past) or "Meeting Scheduled" (future + --upcoming)
**Pass criteria**: Communications record created with correct activity type

### Scenario 4: Batch Meeting Sync with Upcoming
**Command**: `/crm:sync-meeting --since=7d --upcoming`
**Preconditions**: gws CLI (Calendar) configured, past and future meetings
**Expected behavior**:
- Scans past 7 days AND next 7 days of meetings
- Filters: skips cancelled, declined, all-day, internal-only meetings
- Past meetings logged as "Meeting Held", future as "Meeting Scheduled"
- Batch report displayed
**Pass criteria**: Both past and future meetings logged with correct types

### Scenario 5: Client Matching — All Confidence Tiers
**Command**: `/crm:sync-email` (batch with varied emails)
**Preconditions**: CRM with known company domains AND personal email contacts
**Expected behavior**:
- Company domain email → HIGH confidence match
- Known contact email → EXACT confidence match
- Personal email with fuzzy name match → LOW confidence
- Unknown email → NONE (collected as unmatched)
**Pass criteria**: Each match tier produces correct confidence and behavior

### Scenario 6: Deduplication — Re-sync Same Thread
**Command**: `/crm:sync-email [thread_id]` (run twice)
**Preconditions**: Thread already synced from first run
**Expected behavior**:
- First run: creates new Communications record
- Second run: detects existing record, applies idempotent update
- No duplicate record created
- Updated fields reflect latest data, preserved fields untouched
**Pass criteria**: Single Communications record after two syncs

### Scenario 7: CRM Context View
**Command**: `/crm:context "Acme Corp"`
**Preconditions**: Notion MCP configured, Acme Corp exists in Companies DB with contacts, communications, and deals
**Expected behavior**:
- Matches client name to Companies DB
- Displays: company profile, key contacts table, recent activities table, open deals table
- Shows health indicators (contact recency, engagement, pipeline, sentiment)
- READ-ONLY — no records created or modified
**Pass criteria**: Full CRM context view displayed with all 4 sections

### Scenario 8: Dry Run Mode
**Command**: `/crm:sync-email --since=7d --dry-run`
**Preconditions**: gws CLI (Gmail) configured, recent sent emails
**Expected behavior**:
- Fetches emails and performs matching and summarization normally
- Does NOT write to Notion
- All output prefixed with [DRY RUN]
- Batch report shows what would have been synced
- Communications DB unchanged after command
**Pass criteria**: Preview displayed, zero Notion writes

### Scenario 9: Database Discovery — HQ and Fallback Names
**Command**: `/crm:sync-email [thread_id]` (with various DB naming scenarios)
**Preconditions**: Notion MCP configured
**Expected behavior**:
- Searches for "[FOS] Communications" first, then "Founder OS HQ - Communications"
- If not found, falls back to "Communications" or "CRM - Communications" or "CRM Pro - Communications"
- If no database found under any name, reports error: "Communications database not found. Ensure the Founder OS HQ workspace template or CRM Pro template is installed."
- Same discovery pattern applies to Companies, Contacts, and Deals databases (HQ name first, then fallback)
**Pass criteria**: Correct database discovered under any accepted name; clear error when none found

### Scenario 10: Edge Cases
**Commands**: Various
**Test cases**:
- Email with no body → summary generated from subject line only
- Meeting with no title → "Untitled Meeting" used, summary from attendees
- Email to multiple clients → highest confidence match used
- Very long email thread (10+ messages) → summarizes latest exchange only
- Cancelled meeting → skipped by default
- `--client="Unknown Corp"` → company not found, error with suggestion
**Pass criteria**: Each edge case handled gracefully without errors

## Acceptance Criteria Coverage

| Spec Criterion | Covered By |
|----------------|-----------|
| `/crm:sync-email [thread_id]` logs to client record | Scenarios 1, 2 |
| `/crm:sync-meeting [event_id]` logs meeting | Scenarios 3, 4 |
| `/crm:context [client]` loads for call prep | Scenario 7 |
| Auto-matches emails to clients | Scenario 5 |
| Deduplicates activities | Scenario 6 |
| Batch mode with --since | Scenarios 2, 4 |
| Dry run mode | Scenario 8 |
| DB discovery (HQ + fallback) | Scenario 9 |
| Edge case handling | Scenario 10 |

## Notes

- Notion MCP server and gws CLI must be configured for full testing
- CRM Pro template should have at least 2-3 test companies with contacts and deals
- Test with both exact-match and fuzzy-match client scenarios
- Verify idempotent behavior by running sync commands multiple times
- Check Notion DB after each test to confirm records are correct
