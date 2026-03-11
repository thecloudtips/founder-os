# Integration Test Plan: Knowledge Base Q&A

## Prerequisites

- Notion MCP server connected with API key
- gws CLI installed and authenticated via `gws auth login` (optional, needed for Drive-specific tests)
- At least 5-10 Notion pages shared with the integration (mix of wiki, meeting notes, process docs)
- At least 2-3 Google Drive documents accessible (if testing Drive)

---

## Core Scenarios

### Scenario 1: Basic Question Answering

**Command:** `/kb:ask "What is our refund policy?"`

**Expected:**
- Searches Notion (and Drive if available) for refund-related content
- Returns a synthesized answer with inline citations [1][2]
- Shows confidence indicator (High, Medium, or Low)
- Displays citation block with source titles and URLs
- Logs query to "[FOS] Knowledge Base" Notion database with Type="Query"

**Verify:**
- Answer contains at least one citation
- Citation numbers match the source block
- Confidence level is displayed
- Notion DB record is created with correct properties including Type="Query"

### Scenario 2: No-Answer Pathway

**Command:** `/kb:ask "What is the meaning of life?"`

**Expected:**
- Searches knowledge base, finds no relevant content
- Returns "could not find a definitive answer" (NOT "I don't know")
- Suggests related documents if any partial matches exist
- Suggests alternative search terms
- Logs to Notion with `Answered: false` and `Confidence: None`

**Verify:**
- No hallucinated answer is provided
- Related docs are suggested if available
- Alternative search terms are offered
- Notion record shows `Answered: false`

### Scenario 3: Document Discovery

**Command:** `/kb:find "onboarding"`

**Expected:**
- Returns up to 10 document cards matching "onboarding"
- Each card shows: title, 150-char excerpt, classification, freshness, score, URL
- Results sorted by relevance score descending
- No Notion logging (ephemeral command)

**Verify:**
- Results are relevant to "onboarding"
- Preview excerpts are meaningful
- Scores are between 0-100
- No record created in Queries DB

### Scenario 4: Document Discovery with Type Filter

**Command:** `/kb:find "deployment" --type=process --limit=5`

**Expected:**
- Returns only documents classified as "process"
- Maximum 5 results
- Each result has classification "process"

**Verify:**
- All returned documents have classification "process"
- Result count is <= 5
- Documents are relevant to "deployment"

### Scenario 5: Source Indexing (Notion Only)

**Command:** `/kb:index --scope=notion`

**Expected:**
- Discovers all accessible Notion pages and databases
- Classifies each source using 9-type taxonomy
- Computes freshness tiers (Fresh/Current/Aging/Stale)
- Extracts 5-8 keywords per source
- Writes to "[FOS] Knowledge Base" Notion database with Type="Source" (or falls back to "Founder OS HQ - Knowledge Base", then legacy "Knowledge Base Q&A - Sources")
- Displays summary with classification × freshness breakdown table

**Verify:**
- Sources DB is discovered in Notion (consolidated first, then legacy fallback; no lazy creation)
- Each source has: Source Title, URL, Source Type, Classification, Freshness, Keywords
- Idempotent: re-running produces same results without duplicates
- Summary table has correct counts

### Scenario 6: Source Indexing (Full)

**Command:** `/kb:index`

**Expected:**
- Indexes both Notion and Google Drive sources
- Notion sources discovered via notion-search
- Drive sources discovered via gws CLI search (docs, PDFs, spreadsheets)
- All sources written to the same Sources DB

**Verify:**
- Both "Notion Page" and "Google Drive" source types appear in results
- Drive documents have correct metadata (title, URL, classification)
- No duplicates between Notion and Drive for same content

### Scenario 7: Multi-Source Question

**Command:** `/kb:ask "How do we deploy to production?" --sources=all`

**Expected:**
- Searches both Notion and Drive
- May synthesize answer from sources across both platforms
- Citations reference both Notion pages and Drive documents

**Verify:**
- Source block includes both Notion and Drive URLs
- Answer coherently combines information from multiple sources

### Scenario 8: Source-Restricted Search

**Command:** `/kb:ask "project timeline" --sources=notion`

**Expected:**
- Searches only Notion, skips Drive entirely
- No mention of Drive in output
- Answer sourced exclusively from Notion pages

**Verify:**
- All cited sources are Notion pages
- No "Drive unavailable" warning (was explicitly excluded, not unavailable)

### Scenario 9: Confidence Levels

**Setup:** Ensure at least one topic has multiple Notion pages with agreeing content, and one topic has sparse content.

**Test High Confidence:**
`/kb:ask "[topic with multiple sources]"`
- Expected: "High" confidence, 2+ citations

**Test Low Confidence:**
`/kb:ask "[topic with sparse content]"`
- Expected: "Low" confidence with warning, 1 citation or suggestion to search differently

**Verify:**
- Confidence labels match the actual source quality
- High confidence has strong, agreeing sources
- Low confidence has appropriate warning

### Scenario 10: Idempotent Index Updates

**Command:** Run `/kb:index --scope=notion` twice.

**Expected:**
- Second run updates existing records (not duplicates)
- Summary shows "updated" count > 0, "new" count = 0
- Sources DB has same number of records after both runs

**Verify:**
- Record count in Sources DB unchanged
- "Indexed At" timestamps updated
- Freshness tiers may change if time has passed

---

## Edge Cases

### Edge 1: Notion MCP Unavailable

**Setup:** Disconnect Notion MCP server.

**Command:** `/kb:ask "anything"`

**Expected:** Stops with clear error message including install instructions referencing `INSTALL.md`. Does NOT attempt to answer without Notion.

### Edge 2: Google Drive Unavailable (gws CLI not installed)

**Setup:** Ensure gws CLI is not installed or not authenticated.

**Command:** `/kb:ask "anything" --sources=all`

**Expected:** Continues with Notion only. May note "Google Drive not available — searching Notion only." Does NOT error or stop.

### Edge 3: Empty Knowledge Base

**Setup:** Share no pages with Notion integration.

**Command:** `/kb:ask "anything"`

**Expected:** No-answer pathway. Suggests sharing pages with the Notion integration.

### Edge 4: Very Long Source Content

**Setup:** Have a Notion page with 10,000+ words.

**Command:** `/kb:ask "[topic from that page]"`

**Expected:** Content extraction caps at 3,000 characters. Answer is based on the most relevant section, not the entire page.

### Edge 5: Notion DB Discovery and Fallback

**Setup:** Delete "[FOS] Knowledge Base" and "Founder OS HQ - Knowledge Base" databases if they exist. Optionally keep or delete legacy databases "Knowledge Base Q&A - Queries" and "Knowledge Base Q&A - Sources".

**Command:** `/kb:ask "test"` then `/kb:index`

**Expected:** Each command searches for "[FOS] Knowledge Base" first, then "Founder OS HQ - Knowledge Base", then falls back to legacy DB names. If none exists, logging/writing is skipped gracefully (no database auto-created). No error about missing databases.

### Edge 6: Same-Day Idempotent Query Logging

**Command:** Run `/kb:ask "same question"` twice on the same day.

**Expected:** Second run updates the existing record in the Knowledge Base DB (with Type="Query") rather than creating a duplicate.

### Edge 7: Special Characters in Query

**Command:** `/kb:ask "what's our SLA for 99.9% uptime?"`

**Expected:** Handles special characters (apostrophe, percent, period) in the query without errors. Search terms are properly sanitized.

### Edge 8: Large Workspace Indexing

**Setup:** Workspace with 100+ accessible pages.

**Command:** `/kb:index`

**Expected:** Progress updates displayed every 10 pages. Completes within reasonable time. Summary shows correct totals. Warns if >500 sources found.

---

## Acceptance Criteria Mapping

| # | Criterion | Test Scenarios |
|---|-----------|----------------|
| 1 | `/kb:ask [question]` returns sourced answer | Scenarios 1, 7, 8, 9 |
| 2 | Cites source documents | Scenarios 1, 7 |
| 3 | Handles "I don't know" gracefully | Scenario 2, Edge 3 |
| 4 | `/kb:find [topic]` lists relevant docs | Scenarios 3, 4 |
| 5 | Works with Notion and Drive | Scenarios 6, 7, Edge 2 |
