# Integration Test Plan: Inbox Zero Commander

## Overview

This test plan covers end-to-end scenarios for the Inbox Zero Commander plugin, mapping to acceptance criteria from the plugin spec. Tests require gws CLI access to Gmail and optionally Notion MCP.

## Test Environment

- Claude Code with plugin installed
- `gws` CLI installed and authenticated (`gws auth login`) with a test Gmail account
- Notion MCP configured (for pipeline tests)

---

## Scenario 1: Empty Inbox

**Goal**: Verify graceful handling when no unread emails exist.

**Steps**:
1. Ensure Gmail test account has zero unread emails
2. Run `/inbox:triage`
3. Run `/inbox:triage --team`

**Expected Results**:
- Default mode: "Inbox Zero already achieved!" with all counts at 0
- Team mode: Pipeline completes with `total_emails: 0`, no errors
- Action Agent returns empty `action_items` array
- Response Agent returns empty `drafts` array
- Archive Agent returns empty `archive_recommendations` array

**Acceptance Criteria**: AC-1 (graceful empty inbox handling)

---

## Scenario 2: Mixed Email Categorization (50 Emails)

**Goal**: Verify accurate categorization across all 5 categories.

**Steps**:
1. Seed Gmail test account with 50 diverse emails:
   - 10 action-required (meeting requests, deadline notices, review requests)
   - 8 waiting-on (sent replies awaiting response)
   - 12 FYI (team updates, status reports)
   - 10 newsletters (marketing emails with unsubscribe links)
   - 10 promotions (discount offers, sale announcements)
2. Run `/inbox:triage`
3. Verify each email's assigned category

**Expected Results**:
- Every email has exactly one category
- Every email has a priority score between 1-5
- Category distribution roughly matches seeded proportions
- `needs_response` is true for action_required emails with questions
- `archivable` is true for low-priority promotions/newsletters
- Output sorted by priority (descending), then date (newest first)

**Acceptance Criteria**: AC-2 (5-category classification), AC-3 (priority scoring)

---

## Scenario 3: VIP Sender Handling

**Goal**: Verify VIP senders get priority boost and are never recommended for archiving.

**Steps**:
1. Configure VIP sender list (if user preferences are supported)
2. Send test emails from VIP addresses across multiple categories
3. Run `/inbox:triage --team`

**Expected Results**:
- VIP sender emails receive +1 priority boost (capped at 5)
- VIP boost applied after keyword boost
- VIP emails are NEVER marked `archivable: true`
- VIP emails are NEVER in `archive_recommendations` array
- VIP emails from newsletter/promotions categories still protected

**Acceptance Criteria**: AC-4 (VIP handling), AC-8 (archive safety)

---

## Scenario 4: HQ Database Discovery and Fallback

**Goal**: Verify the plugin discovers consolidated HQ databases and falls back to legacy names.

**Steps**:
1. Ensure "[FOS] Tasks" and "[FOS] Content" databases exist in Notion (deployed via HQ template)
2. Run `/inbox:triage --team` with emails that have action items and need responses
3. Check Notion for new entries in HQ databases

**Expected Results**:
- Action items created in "[FOS] Tasks" with correct properties:
  - Title (title), Description (rich_text), Owner (rich_text), Deadline (date), Priority (number), Status (select), Source Email (url), Email From (rich_text), Email Subject (rich_text)
  - **Type** column set to `"Email Task"` on every record
  - **Source Plugin** column set to `"Inbox Zero"` on every record
  - **Company** relation populated when sender domain matches a CRM company
  - **Contact** relation populated when sender email matches a CRM contact
- Drafts created in "[FOS] Content" with correct properties:
  - Title (title), To (email), Email Body (rich_text), Tone (select), Confidence (number), Status (select), Source Email (url), Needs Review (checkbox), Review Notes (rich_text)
  - **Type** column set to `"Email Draft"` on every record
- Drafts populated with status "To Review"
- Subsequent runs reuse existing databases (no duplicates)

**Fallback Sub-Scenario**:
1. Remove "[FOS] Tasks" and "[FOS] Content" from Notion
2. Create legacy databases "Inbox Zero - Action Items" and "Inbox Zero - Drafts"
3. Run `/inbox:triage --team`
4. Verify action items and drafts are written to legacy databases
5. Verify pipeline completes without errors

**No-DB Sub-Scenario**:
1. Ensure neither HQ nor legacy databases exist
2. Run `/inbox:triage --team`
3. Verify warning is logged about missing databases
4. Verify pipeline completes (action items and drafts in output only, no Notion persistence)

**Acceptance Criteria**: AC-5 (Notion task creation), AC-6 (draft workflow)

---

## Scenario 5: Drafts Workflow End-to-End

**Goal**: Verify the complete draft lifecycle from pipeline to Gmail.

**Steps**:
1. Run `/inbox:triage --team` with emails that need responses
2. Verify drafts appear in Notion "[FOS] Content" (or fallback "Founder OS HQ - Content" / legacy "Inbox Zero - Drafts") with status "To Review" and Type="Email Draft"
3. In Notion, change status of 3 drafts to "Approved"
4. Run `/inbox:drafts_approved`
5. Check Gmail Drafts folder

**Expected Results**:
- Pipeline creates drafts in Notion (NOT Gmail)
- Each draft has: subject, to, body, tone, confidence score
- Low-confidence drafts (< 0.5) have `needs_review: true` with review notes
- `/inbox:drafts_approved` finds the 3 approved entries
- Gmail drafts created and threaded as replies to original emails
- Notion status updated to "Sent to Gmail"
- Summary shows 3/3 successful
- Gmail drafts are in Drafts folder, NOT sent

**Acceptance Criteria**: AC-6 (draft review workflow), AC-7 (Gmail draft creation)

---

## Scenario 6: Notion Unavailable Fallback

**Goal**: Verify pipeline continues without Notion.

**Steps**:
1. Disable Notion MCP (unset `NOTION_API_KEY`)
2. Run `/inbox:triage --team`

**Expected Results**:
- Warning message about Notion not being configured
- Triage Agent runs normally (no Notion dependency)
- Action Agent extracts action items but reports they were not persisted to Notion
- Action items included in output as text (no `notion_task_id`)
- Response Agent drafts responses but cannot save to Notion
- Drafts included in output as text (no `notion_draft_id`)
- Archive Agent runs normally and produces recommendations
- Pipeline completes with partial results, no crash
- `/inbox:drafts_approved` halts with "Notion MCP required" message (neither HQ Content nor legacy Drafts DB found)

**Acceptance Criteria**: AC-9 (graceful degradation without Notion)

---

## Scenario 7: Gmail Unavailable Error

**Goal**: Verify pipeline halts cleanly without Gmail access.

**Steps**:
1. Ensure gws CLI is not available (rename binary or remove from PATH)
2. Run `/inbox:triage`
3. Run `/inbox:triage --team`

**Expected Results**:
- Both modes halt immediately with clear error message ("gws CLI not found")
- Error references INSTALL.md for setup instructions
- No partial processing attempted
- No data sent to Notion
- Clean exit, no stack traces

**Acceptance Criteria**: AC-10 (Gmail required validation)

---

## Scenario 8: Archive Recommend-Only Safety

**Goal**: Verify archive agent never executes archiving.

**Steps**:
1. Run `/inbox:triage --team` with mix of emails including promotions and newsletters
2. Review archive recommendations in output
3. Verify Gmail inbox state

**Expected Results**:
- `archive_recommendations` array populated with email IDs, subjects, categories, and reasons
- Gmail labels applied to emails (Action Required, Waiting On, FYI, Newsletter, Promotions)
- NO emails actually archived from inbox
- Emails with action items NEVER in recommendations
- VIP emails NEVER in recommendations
- Recommendations include human-readable reason per email

**Acceptance Criteria**: AC-8 (recommend-only archiving)

---

## Scenario 9: Action Item Duplicate Detection

**Goal**: Verify duplicate action items are not created on repeated runs.

**Steps**:
1. Run `/inbox:triage --team` — note action items created
2. Run `/inbox:triage --team` again without new emails

**Expected Results**:
- First run: action items created in Notion HQ Tasks DB with Type="Email Task" and Source Plugin="Inbox Zero"
- Second run: duplicates detected (same verb + noun within 14 days, scoped to Type="Email Task" + Source Plugin="Inbox Zero")
- `duplicates_skipped` count > 0 in action summary
- No duplicate entries in Notion database

**Acceptance Criteria**: AC-5 (action item quality)

---

## Scenario 10: Tone Matching Accuracy

**Goal**: Verify response drafts match sender formality.

**Steps**:
1. Send test emails with varying formality:
   - Formal: "Dear Mr. Smith, I am writing to request..."
   - Professional: "Hi John, Following up on our discussion..."
   - Casual: "hey! quick q about the project..."
   - Internal: "FYI - updated the doc, lmk"
2. Run `/inbox:triage --team`
3. Review draft tones in Notion

**Expected Results**:
- Formal email gets Formal draft (salutation, full sentences, "Sincerely")
- Professional email gets Professional draft ("Hi [Name]", clear structure)
- Casual email gets Casual draft (first name, shorter, friendly)
- Internal email gets Internal draft (direct, minimal pleasantries)
- No draft escalates formality beyond one level above sender

**Acceptance Criteria**: AC-11 (tone matching)

---

## Summary Matrix

| Scenario | Acceptance Criteria | MCP Required |
|----------|-------------------|--------------|
| 1. Empty Inbox | AC-1 | gws CLI |
| 2. Mixed Categorization | AC-2, AC-3 | gws CLI |
| 3. VIP Handling | AC-4, AC-8 | gws CLI |
| 4. Notion DB Creation | AC-5, AC-6 | gws CLI, Notion |
| 5. Drafts End-to-End | AC-6, AC-7 | gws CLI, Notion |
| 6. Notion Unavailable | AC-9 | gws CLI |
| 7. Gmail Unavailable | AC-10 | None |
| 8. Archive Safety | AC-8 | gws CLI |
| 9. Duplicate Detection | AC-5 | gws CLI, Notion |
| 10. Tone Matching | AC-11 | gws CLI, Notion |
