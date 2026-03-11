# Integration Test Plan: Client Context Loader

## Overview

Test scenarios for Plugin #20 — Client Context Loader. Covers both command modes, cache behavior, partial source failures, fuzzy matching, and CRM enrichment writeback.

### Prerequisites

- CRM Pro template with at least 2 test companies in the Companies database
- Each test company should have linked Contacts, Deals, and Communications entries
- `gws` CLI installed and authenticated (`gws auth login`)
- Gmail access via `gws gmail` with email history to at least one test company contact
- Google Calendar access via `gws calendar` with at least one meeting involving a test company contact (optional)
- Google Drive access via `gws drive` with at least one document mentioning a test company (optional)

---

## Test Scenarios

### 1. Basic CRM Lookup (Default Mode)

**Command**: `/client:load "Test Company A"`

**Expected**:
- Plugin discovers Companies database using discovery order: "[FOS] Companies" → "Founder OS HQ - Companies" → "Companies" → fallback "Client Dossiers"
- Searches Companies database by name
- Returns dossier with Profile section populated (company name, industry, contacts, deals)
- Completeness score reflects available data
- Result is cached as dossier properties on the matching Companies page (Dossier, Dossier Completeness, Dossier Generated At, Dossier Stale)

**Verify**:
- [ ] Company profile matches CRM data
- [ ] Contacts are listed with emails
- [ ] Active deals are shown
- [ ] Completeness score is > 0.0
- [ ] Companies page has Dossier property populated
- [ ] Dossier Generated At is set to current timestamp
- [ ] Dossier Stale is false

---

### 2. Full Parallel Pipeline (Team Mode)

**Command**: `/client:load "Test Company A" --team`

**Expected**:
- All 5 gatherer agents launch simultaneously
- Each gatherer returns structured output (or "unavailable" for unconfigured sources)
- Context Lead synthesizes all outputs into unified dossier
- Pipeline execution summary shows timing per agent
- Dossier is cached on the Companies page (Dossier properties updated)
- CRM enrichments are written to the same Companies page (health score) and related DBs (risk level, sentiment)

**Verify**:
- [ ] All configured sources return data
- [ ] Unconfigured sources return "unavailable" (not error)
- [ ] Dossier contains all 7 sections
- [ ] Health score is calculated (0-100)
- [ ] Companies page Dossier property is populated
- [ ] Client Health Score written to same Companies page

---

### 3. Partial Source Failure

**Command**: `/client:load "Test Company A" --team` (with gws Drive access unavailable)

**Expected**:
- CRM, Email, Calendar, Notes agents succeed
- Docs agent returns `status: "unavailable"`
- Context Lead continues synthesis with available data
- Completeness score is lower but dossier is still produced
- Documents section notes "unavailable"

**Verify**:
- [ ] Pipeline does not fail
- [ ] Completeness breakdown shows Documents = 0.0 (unavailable)
- [ ] Other sections are fully populated
- [ ] Metadata distinguishes "unavailable" from "no data found"

---

### 4. Cache Hit

**Command**: `/client:load "Test Company A"` (second time within 24h)

**Expected**:
- Plugin finds cached dossier on the Companies page (Dossier Generated At within 24h, Dossier Stale = false)
- Returns cached data from the Dossier property with note: "Using cached dossier (generated X ago)"
- No MCP calls to gather fresh data
- Significantly faster than first load

**Verify**:
- [ ] Cache hit is detected via Dossier Generated At + Dossier Stale fields
- [ ] Cached data is returned (not re-gathered)
- [ ] `from_cache: true` in metadata
- [ ] Staleness message is accurate

---

### 5. Cache Refresh

**Command**: `/client:load "Test Company A" --refresh`

**Expected**:
- `--refresh` flag bypasses cache
- Fresh data is gathered from all sources
- Companies page Dossier properties are updated with fresh data
- Dossier reflects latest data

**Verify**:
- [ ] Cache is bypassed despite existing Dossier on Companies page
- [ ] Fresh data is gathered
- [ ] Dossier Generated At is updated with new timestamp
- [ ] Dossier Stale is set to false
- [ ] `from_cache: false` in metadata

---

### 6. Client Brief Generation

**Command**: `/client:brief "Test Company A"` (after a successful /client:load)

**Expected**:
- Plugin reads cached dossier
- Generates 1-page executive brief
- Brief includes: Profile, Recent Activity, Open Items, Upcoming, Sentiment & Risk, Key Documents
- Format is clean, printable markdown

**Verify**:
- [ ] Brief uses cached data (no re-gathering)
- [ ] All sections are present (empty sections say "No data available")
- [ ] Health score and risk flags are included
- [ ] Brief is concise (< 500 words)

---

### 7. Client Not Found

**Command**: `/client:load "Nonexistent Company XYZ"`

**Expected**:
- CRM search returns no matches
- Plugin attempts Gmail fallback search
- If still no data: returns "Client not found" with suggestions
- No cache entry created

**Verify**:
- [ ] No error thrown
- [ ] Helpful message suggesting to check spelling
- [ ] Fallback search attempted (if Gmail configured)
- [ ] Completeness score is 0.0

---

### 8. Fuzzy Name Matching

**Command**: `/client:load "Acme"` (when CRM has "Acme Corp" or "Acme Corporation")

**Expected**:
- Fuzzy matching finds "Acme Corp" as a partial match
- Match confidence is reported (e.g., 0.8 for partial match)
- If multiple fuzzy matches: top 3 presented for user confirmation

**Verify**:
- [ ] Partial match is found
- [ ] Match confidence < 1.0 (not exact)
- [ ] Correct company is returned
- [ ] Multiple matches trigger user selection prompt

---

### 9. Completeness Scoring

**Command**: `/client:load "Test Company B" --team` (company with minimal data)

**Expected**:
- Company exists in CRM with sparse data (few contacts, no deals)
- Email search returns few results
- Completeness score reflects data gaps
- Per-component breakdown shows which areas lack data

**Verify**:
- [ ] Score is lower than a well-populated client
- [ ] Breakdown shows 0.0 or 0.5 for sparse components
- [ ] Data gaps are flagged
- [ ] Dossier is still produced (graceful handling)

---

### 10. CRM Enrichment Writeback

**Command**: `/client:load "Test Company A" --team` (first run)

**Expected**:
- After synthesis, Context Lead writes enrichments:
  - Companies page (same page as dossier): Client Health Score (0-100), Dossier, Dossier Completeness, Dossier Generated At, Dossier Stale
  - Deals: Risk Level (Low/Medium/High)
  - Communications: Sentiment (Positive/Neutral/Negative) with "[Auto]" prefix
- Only writes when match confidence >= 0.8
- Does not overwrite manually-entered values

**Verify**:
- [ ] Client Health Score appears on same Companies page as dossier
- [ ] Dossier properties are all populated on the Companies page
- [ ] Risk Level appears on active Deals
- [ ] Sentiment appears on most recent Communication
- [ ] "[Auto]" prefix distinguishes auto-set values
- [ ] Values are reasonable given the test data

---

## Edge Case Scenarios

### 11. No Notion MCP Configured

**Command**: `/client:load "Any Company"`

**Expected**: Halts with "Notion MCP is required. See INSTALL.md for setup instructions."

### 12. gws CLI Not Available

**Command**: `/client:load "Test Company A"`

**Expected**: Warns about missing gws CLI. Continues with CRM-only dossier. Email sections are empty.

### 13. Client Brief Without Prior Load

**Command**: `/client:brief "Never Loaded Company"`

**Expected**: Informs user no dossier exists. Suggests running `/client:load` first. Offers partial brief from CRM-only data.

### 14. Stale Cache Brief

**Command**: `/client:brief "Test Company A"` (with Dossier Generated At older than 24h)

**Expected**: Reads stale Dossier property from Companies page. Generates brief from stale data with staleness warning. Suggests refreshing with `/client:load --refresh`.

### 15. Companies DB Discovery Order

**Command**: `/client:load "Test Company A"` (with "[FOS] Companies" database present)

**Expected**:
- Plugin discovers "[FOS] Companies" as primary database
- Does NOT search for standalone "Client Dossiers" database
- Dossier is written as properties on the HQ Companies page

**Verify**:
- [ ] "[FOS] Companies" is used when available
- [ ] Falls back to "Founder OS HQ - Companies", then "Companies" when primary DB not found
- [ ] Falls back to lazy-created "Client Dossiers" only when no Companies DB exists
- [ ] No duplicate dossier entries across databases
