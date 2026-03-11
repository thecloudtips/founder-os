# Integration Test Plan: Action Item Extractor

## Overview

This test plan validates the P04 Action Item Extractor plugin against all acceptance criteria. Tests cover both commands (`/actions:extract`, `/actions:extract-file`), the action-extraction skill, Notion integration, and edge cases.

## Prerequisites

- Plugin installed in Claude Code
- Notion MCP configured with valid API key
- Notion integration has workspace access
- gws CLI installed and authenticated (for optional Drive tests)

---

## Test 1: Basic Text Extraction

**Command**: `/actions:extract`
**Input**:
```
Meeting notes: John will review the API spec by Friday. Sarah to update the deployment docs.
```
**Expected**:
- 2 action items extracted
- Source type: "Meeting Transcript"
- Item 1: Title starts with "Review", Owner = "John", Deadline = coming Friday
- Item 2: Title starts with "Update", Owner = "Sarah", Deadline = null
- Both created in Notion with Status = "To Do"

---

## Test 2: File-Based Extraction

**Command**: `/actions:extract-file`
**Setup**: Create a test file `test-notes.md` with 3+ action items
**Input**: `/actions:extract-file test-notes.md`
**Expected**:
- File read successfully using built-in Read tool
- Action items extracted and displayed
- Source title derived from file content or filename
- Notion tasks created with correct Source Type

---

## Test 3: Owner Identification — @mentions and Context

**Input**:
```
@Mike to draft the project charter. Have Lisa handle the budget review. The team should prepare for the demo. I will send the final report.
```
**Expected**:
- Item 1: Owner = "Mike" (explicit @mention)
- Item 2: Owner = "Lisa" (named delegation)
- Item 3: Owner = "user" with delegation note (team reference)
- Item 4: Owner = "user" (self-commitment)

---

## Test 4: Deadline Detection — Explicit and Implied

**Input**:
```
Tasks: 1. Submit the report by January 15, 2026. 2. Review the deck ASAP. 3. Schedule follow-up for next week. 4. Update the docs by EOW. 5. Prepare the presentation (no specific date).
```
**Expected**:
- Item 1: Deadline = 2026-01-15
- Item 2: Deadline = today's date (ASAP = today)
- Item 3: Deadline = next Monday
- Item 4: Deadline = coming Friday
- Item 5: Deadline = null, description includes "No deadline specified"

---

## Test 5: Notion Task Creation with HQ Properties

**Input**: Any text producing at least 1 action item
**Expected Notion task properties** (in "[FOS] Tasks" database):
- Title: Verb-first, max 80 chars
- Description: Full context from source
- Type: "Action Item"
- Source Plugin: "Action Extractor"
- Owner: Inferred or "user"
- Deadline: ISO date or empty
- Priority: Number 1-5
- Status: "To Do"
- Source Type: Correct select value
- Source Title: Extracted from content
- Extracted At: Current timestamp
- Company: Populated if owner matches a CRM contact's company (empty otherwise)
- Contact: Populated if owner matches a CRM contact (empty otherwise)

---

## Test 6: Graceful Degradation Without Notion

**Setup**: Disable Notion MCP (remove or invalidate API key)
**Input**: Any text with action items
**Expected**:
- Action items extracted successfully
- Results displayed as structured text in chat
- Warning message: "Notion unavailable — displaying results in chat..."
- No error or crash

---

## Test 7: Duplicate Detection (Type-Scoped)

**Setup**: Run extraction twice with same input
**First run**: Creates Notion tasks normally
**Second run (same input)**:
**Expected**:
- Duplicate tasks detected (verb+noun match within 14 days)
- Duplicate query filters by `Type = "Action Item"` to avoid false positives against Follow-Up or Email Task records
- Duplicates marked with "Duplicate detected" status
- No new Notion pages created for duplicates
- Near-duplicates (same noun, different verb) create new tasks with cross-reference

---

## Test 8: Multiple Source Types

### 8a: Meeting Transcript

**Input**:
```
Speaker 1 (John): Let's finalize the timeline. I'll send the updated schedule by tomorrow.
Speaker 2 (Sarah): Sounds good. I'll review it and get back to you by Friday.
Action Items:
- John to send updated schedule
- Sarah to review and provide feedback
```
**Expected**: Source Type = "Meeting Transcript", 4 items extracted (2 from dialogue + 2 from AI list)

### 8b: Email Thread

**Input**:
```
From: alice@example.com
Subject: Project Update
Date: Feb 25, 2026

Please review the attached proposal by Thursday. Bob, can you coordinate with the design team?
```
**Expected**: Source Type = "Email", 2 items extracted

### 8c: Document

**Input**:
```
# Project Plan

## Action Items
1. Complete phase 1 deliverables
2. Schedule client review meeting
3. Update project documentation
```
**Expected**: Source Type = "Document", 3 items extracted

---

## Test 9: Database Discovery and Fallback

**Setup**: Ensure "[FOS] Tasks" database exists in Notion (provisioned by HQ setup)
**Input**: Any text with action items

### 9a: HQ Database Present
**Expected**:
- Plugin searches for "[FOS] Tasks" first
- Database found
- Tasks created with `Type = "Action Item"` and `Source Plugin = "Action Extractor"`

### 9b: HQ Database Missing, Legacy Present
**Setup**: Remove HQ DB, ensure "Action Item Extractor - Tasks" exists
**Expected**:
- Plugin searches for "[FOS] Tasks", then "Founder OS HQ - Tasks" — not found
- Falls back to "Action Item Extractor - Tasks"
- Tasks created in legacy database

### 9c: Neither Database Present
**Setup**: Remove both databases
**Expected**:
- Plugin searches for both databases — neither found
- Plugin does NOT create a database
- Graceful degradation: results displayed in chat with warning

---

## Test 10: Edge Cases

### 10a: Empty Input

**Command**: `/actions:extract` (with no text)
**Expected**: "No text provided. Paste the content you want to extract action items from, or use `/actions:extract-file [path]` to process a file."

### 10b: No Action Items Found

**Input**: "The weather was nice today. We had a good discussion about team culture."
**Expected**: "No action items detected in the provided text."

### 10c: Ambiguous Owners

**Input**: "Someone should update the docs. The report needs to be reviewed."
**Expected**: Both items assigned to "user" with "Owner unclear from context" note

### 10d: File Not Found

**Command**: `/actions:extract-file /nonexistent/file.md`
**Expected**: "File not found: /nonexistent/file.md. Check the path and try again."

### 10e: Empty File

**Setup**: Create an empty file
**Command**: `/actions:extract-file empty.md`
**Expected**: "File is empty: empty.md. No content to extract action items from."

### 10f: Vague Requests

**Input**: "Let's circle back on this. We should catch up sometime."
**Expected**: Items created with "Follow up on [topic]", deadline = null, priority = 1

### 10g: Conditional Actions

**Input**: "If the client approves the budget, then send the contract to legal."
**Expected**: Item created with condition noted in description, priority reduced by 1

### 10h: Interactive File Search

**Command**: `/actions:extract-file` (no path)
**Expected**: Prompts user or offers to search for transcript/notes files using Glob

---

## Test Summary

| # | Test Case | Priority | Acceptance Criterion |
|---|-----------|----------|---------------------|
| 1 | Basic text extraction | P0 | Core functionality |
| 2 | File-based extraction | P0 | Core functionality |
| 3 | Owner identification | P0 | @mentions and context clues |
| 4 | Deadline detection | P0 | Explicit and implied dates |
| 5 | Notion task creation (HQ props) | P0 | Type, Source Plugin, Company/Contact |
| 6 | Graceful degradation | P0 | Works without Notion |
| 7 | Duplicate detection (type-scoped) | P1 | 14-day window, verb+noun, Type filter |
| 8 | Multiple source types | P1 | Transcript, email, document |
| 9a-c | DB discovery and fallback | P1 | HQ first, legacy fallback, no auto-create |
| 10a-h | Edge cases | P2 | Robustness |
