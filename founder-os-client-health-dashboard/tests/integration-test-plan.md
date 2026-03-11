# Integration Test Plan: Client Health Dashboard

## Overview

This test plan validates the P10 Client Health Dashboard plugin against all acceptance criteria. Tests cover both commands (`/client:health-scan`, `/client:health-report`), both skills (client-health-scoring, sentiment-analysis), Notion integration, cross-plugin integration (P20, P11), and edge cases.

## Prerequisites

- Plugin installed in Claude Code
- Notion MCP configured with valid API key and CRM workspace access
- gws CLI (Gmail) configured with valid OAuth credentials
- Google gws CLI (Calendar) configured (for Calendar tests)
- At least 3 active clients in Notion CRM Companies database
- Some email history with at least 2 clients

---

## Test 1: Full Client Health Scan

**Priority**: P0
**Command**: `/client:health-scan`
**Expected**:
- Discovers CRM Companies database dynamically (no hardcoded IDs)
- Retrieves all Active/Prospect clients
- Computes 5 metrics per client (Last Contact, Response Time, Open Tasks, Payment, Sentiment)
- Classifies each client as Green/Yellow/Red
- Displays dashboard sorted by score ascending (at-risk first)
- Sources Used field populated accurately

---

## Test 2: Single Client Scan

**Priority**: P0
**Command**: `/client:health-scan --client="Acme Corp"`
**Expected**:
- Fuzzy matches client name against CRM Companies
- Scans only the matched client
- Displays full metric breakdown for that client
- Updates health properties on the Company page (or caches in standalone Health Scores DB in fallback mode)

---

## Test 3: Status Filter

**Priority**: P0
**Command**: `/client:health-scan --status=red`
**Expected**:
- Only displays clients with Red status (score < 50)
- Yellow and Green clients excluded from output
- Count reflects filtered results

---

## Test 4: Limit Filter

**Priority**: P1
**Command**: `/client:health-scan --limit=3`
**Expected**:
- Shows only 3 clients (lowest scores first)
- All tiers may be represented depending on scores

---

## Test 5: Cache Behavior

**Priority**: P0
**Command**: `/client:health-scan` (run twice within 24 hours)
**Expected**:
- First run: Computes fresh scores, updates health properties on Company pages
- Second run: Uses cached scores from Company page `Last Scanned` property (no recomputation)
- Cache hit visible in output (faster response, same scores)

---

## Test 6: Cache Refresh

**Priority**: P0
**Command**: `/client:health-scan --refresh`
**Expected**:
- Bypasses 24h cache entirely
- Recomputes all scores from fresh source data
- Last Scanned timestamp updated to now

---

## Test 7: Companies DB Discovery

**Priority**: P0
**Command**: `/client:health-scan`
**Expected**:
- Plugin searches for "Founder OS HQ - Companies" first
- If found, uses HQ Companies DB and updates Company pages with health properties
- If not found, searches for "Companies" or "CRM - Companies" and uses that
- Health scores written as property updates on existing Company pages (no separate DB created)
- Subsequent runs read cached scores from `Last Scanned` property on Company pages

---

## Test 7b: Fallback to Standalone Health Scores DB

**Priority**: P1
**Setup**: Ensure no "Founder OS HQ - Companies", "Companies", or "CRM - Companies" database exists in Notion
**Command**: `/client:health-scan`
**Expected**:
- Plugin searches for Companies databases, finds none
- Falls back to searching for "Client Health Dashboard - Health Scores" database
- If standalone DB not found, lazy-creates it with 12 properties matching DB template
- Health score records created in the standalone database
- Subsequent runs find and reuse the standalone database

---

## Test 8: Client Health Report - Basic

**Priority**: P0
**Command**: `/client:health-report Acme Corp`
**Expected**:
- Fuzzy matches client name
- Displays overall score with RAG badge
- Per-metric breakdown table with scores, weights, and details
- Risk flags listed (if any)
- Recommended actions based on low-scoring metrics
- Recent activity timeline (last 5 emails, last 3 meetings)

---

## Test 9: Client Health Report - No Argument

**Priority**: P1
**Command**: `/client:health-report`
**Expected**:
- Lists first 10 active clients from CRM
- Prompts user to select a client
- Proceeds with report after selection

---

## Test 10: Client Health Report - No Match

**Priority**: P1
**Command**: `/client:health-report "Nonexistent Company"`
**Expected**:
- Clear error: "No client matching 'Nonexistent Company' found in CRM."

---

## Test 11: Sentiment Analysis - Email Only

**Priority**: P0
**Setup**: Gmail connected, Calendar disconnected
**Command**: `/client:health-report [client_with_emails]`
**Expected**:
- Sentiment computed from email signals only (100% email weight)
- Note in output: "Calendar unavailable -- using email-only sentiment"
- Sentiment score is numeric 0-100

---

## Test 12: Sentiment Analysis - Both Sources

**Priority**: P1
**Setup**: Both Gmail and Calendar connected
**Command**: `/client:health-report [client_with_meetings]`
**Expected**:
- Email sentiment (55% weight) + Meeting sentiment (45% weight)
- Both per-source breakdowns shown
- Meeting signals detected (frequency, cancellations, etc.)

---

## Test 13: Graceful Degradation - Without Gmail

**Priority**: P0
**Setup**: gws CLI (Gmail) disconnected
**Command**: `/client:health-scan`
**Expected**:
- Last Contact and Response Time set to neutral defaults (50)
- Sentiment returns null/default
- Warning in output about Gmail unavailability
- Dashboard still displays with available data

---

## Test 14: Graceful Degradation - Without Calendar

**Priority**: P1
**Setup**: Google gws CLI (Calendar) disconnected
**Command**: `/client:health-scan`
**Expected**:
- No error or crash
- Sentiment uses email-only scoring
- Last Contact based on Gmail only
- No warning needed (Calendar is silently optional)

---

## Test 15: Graceful Degradation - Without Notion

**Priority**: P0
**Setup**: Notion MCP disconnected
**Command**: `/client:health-scan`
**Expected**:
- Error reported: "Notion unavailable -- cannot access CRM or output database"
- Plugin stops gracefully (Notion is required)

---

## Test 16: Cross-Plugin Integration - P20 Dossier

**Priority**: P1
**Setup**: Plugin #20 installed, "Client Dossiers" DB exists with fresh dossiers
**Command**: `/client:health-scan`
**Expected**:
- Reads cached dossier for each client (checks Stale flag and Generated At)
- Supplements Open Tasks metric from dossier "Open Items"
- "Dossiers" appears in Sources Used
- If dossier is stale (>24h), falls back to direct queries

---

## Test 17: Cross-Plugin Integration - P11 Invoice

**Priority**: P1
**Setup**: Plugin #11 installed, "Invoice Processor - Invoices" DB exists
**Command**: `/client:health-scan`
**Expected**:
- Reads invoice records for each client
- Payment Score computed from paid-on-time ratio and overdue count
- "Invoices" appears in Sources Used

---

## Test 18: P11 Not Installed

**Priority**: P1
**Setup**: No "Invoice Processor - Invoices" database in Notion
**Command**: `/client:health-scan`
**Expected**:
- Payment Score set to 75 (neutral default)
- Note: "Invoice data unavailable"
- No error or crash

---

## Test 19: Risk Flag Detection

**Priority**: P1
**Command**: `/client:health-scan`
**Setup**: At least one client with: no recent email (30+ days), overdue tasks, and negative sentiment
**Expected**:
- Risk flags detected: "No Recent Contact", "Overdue Tasks", "Negative Sentiment"
- Flags displayed in dashboard Risk Flags column
- Multiple flags can apply to same client

---

## Test 20: Idempotent Updates

**Priority**: P1
**Command**: `/client:health-scan` (run twice)
**Expected**:
- First run: Updates health properties on Company pages (or creates records in fallback mode)
- Second run with --refresh: Overwrites health properties on the same Company pages
- No duplicate records or pages created
- Company page identity used as unique key (or Client Name in fallback mode)

---

## Test 21: RAG Classification Boundaries

**Priority**: P2
**Expected**:
- Score 80 = Green (boundary)
- Score 79 = Yellow (boundary)
- Score 50 = Yellow (boundary)
- Score 49 = Red (boundary)

---

## Test 22: Edge Cases

### 22a: New Client (< 30 days in CRM)
**Expected**: "New Client" risk flag, Last Contact minimum score of 40

### 22b: No Email History
**Expected**: Last Contact = 0, Response Time = 50, "No Recent Contact" flag

### 22c: No Tasks
**Expected**: Open Tasks = 100 (no overdue = perfect score)

### 22d: Client Name Not Found
**Command**: `/client:health-scan --client="zzz_no_match"`
**Expected**: "No client matching 'zzz_no_match' found."

### 22e: All Data Missing (CRM record only)
**Expected**: Neutral defaults applied, "Limited data available" warning, completeness = "partial"

### 22f: Mixed Sentiment Signals
**Expected**: Weighted average computed, "Mixed Sentiment Signals" note in output

---

## Test Summary

| # | Test Case | Priority | Acceptance Criterion |
|---|-----------|----------|---------------------|
| 1 | Full health scan | P0 | Core scanning with 5 metrics |
| 2 | Single client scan | P0 | --client flag works |
| 3 | Status filter | P0 | --status filters by RAG tier |
| 4 | Limit filter | P1 | --limit caps results |
| 5 | Cache behavior | P0 | 24h TTL works |
| 6 | Cache refresh | P0 | --refresh bypasses cache |
| 7 | Companies DB discovery | P0 | HQ / Companies DB detection + page updates |
| 7b | Fallback standalone DB | P1 | Lazy-create Health Scores DB when no Companies DB |
| 8 | Health report basic | P0 | Single-client deep dive |
| 9 | Health report no arg | P1 | Interactive client picker |
| 10 | Health report no match | P1 | Graceful error |
| 11 | Sentiment email-only | P0 | Works without Calendar |
| 12 | Sentiment both sources | P1 | Email + Meeting weighted |
| 13 | Degradation no Gmail | P0 | Neutral defaults |
| 14 | Degradation no Calendar | P1 | Silent fallback |
| 15 | Degradation no Notion | P0 | Error + stop |
| 16 | P20 integration | P1 | Reads cached dossiers |
| 17 | P11 integration | P1 | Reads invoice data |
| 18 | P11 not installed | P1 | Neutral Payment default |
| 19 | Risk flag detection | P1 | Flags correctly detected |
| 20 | Idempotent updates | P1 | No duplicates on re-run |
| 21 | RAG boundaries | P2 | Classification thresholds |
| 22a-f | Edge cases | P2 | Robustness |
