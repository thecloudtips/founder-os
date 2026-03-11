# Integration Test Plan: Learning Log Tracker (#29)

## Prerequisites

- Notion MCP server connected and verified
- `NOTION_API_KEY` environment variable set
- Integration shared with target Notion workspace page
- Clean test environment (no existing Learning Log Tracker or Founder OS HQ databases)

---

## Test Cases

### TC-01: First Learning Capture (Full Arguments)

**Command:**
```
/learn:log "Discovered that batch processing Notion API calls with 10-item chunks reduces rate limit errors by 90%" --source=experience --context="Working on the Founder OS plugin pipeline"
```

**Expected:**
- Searches for "[FOS] Learnings" database first, tries "Founder OS HQ - Learnings", falls back to "Learning Log Tracker - Learnings". If none exists, reports error: "Learnings database not found. Ensure the Founder OS HQ workspace template is installed in your Notion workspace."
- Generates title: ~"Batch Processing Reduces Notion API Rate Limits" (5-8 words, Title Case)
- Topics: Technical and/or Tool (auto-detected from "API", "batch processing")
- Source Type: Experience (from --source flag)
- Context: "Working on the Founder OS plugin pipeline"
- Week: current ISO week (e.g., 2026-W10)
- Logged At: today's date
- Related IDs/Titles: empty (first entry)
- Chat confirmation displayed with all fields

### TC-02: Learning Capture with Missing Arguments (Interactive)

**Command:**
```
/learn:log
```

**Expected:**
- Prompts: "What did you learn today? Share an insight, observation, or takeaway."
- Waits for user input
- After input, proceeds with auto-detection for source type and topics
- Saves successfully

### TC-03: Duplicate Detection

**Command:** (run twice with same content)
```
/learn:log "Batch processing reduces API rate limit errors significantly"
```

**Expected:**
- First run: saves normally
- Second run: detects matching Title + same day
- Presents existing entry and asks: update, rename, or cancel
- Does NOT silently create a duplicate

### TC-04: Related Insights Linking

**Setup:** Log at least 3 learnings with overlapping topics (e.g., all tagged "Technical")

**Command:**
```
/learn:log "Found that connection pooling with max 5 connections prevents database timeout errors"
```

**Expected:**
- Auto-detects Topics including "Technical"
- Finds 2-3 related past insights sharing the Technical topic
- Displays related titles in confirmation
- Stores Related IDs and Related Titles in the database entry

### TC-05: Search by Topic

**Setup:** Multiple learnings exist with various topics

**Command:**
```
/learn:search Technical
```

**Expected:**
- Filters to entries where Topics contains "Technical"
- Results sorted by composite score (topic match +2, recency modifier)
- Displays numbered list
- Shows Related Titles for each result
- Respects default limit of 10

### TC-06: Search by Keyword with Date Filter

**Command:**
```
/learn:search "API" --since=7d
```

**Expected:**
- Filters by keyword "API" across Title, Insight, Context
- Filters by Logged At >= 7 days ago
- Results ranked by composite score (title match +3, insight match +2, etc.)
- Only returns entries from last 7 days

### TC-07: Search with No Results

**Command:**
```
/learn:search "quantum computing" --since=1d
```

**Expected:**
- Returns empty result set
- Displays: "No learnings found matching 'quantum computing'"
- Suggests removing date filter
- Shows total count of learnings in database

### TC-08: Weekly Synthesis (Current Week)

**Setup:** At least 3 learnings logged in the current ISO week

**Command:**
```
/learn:weekly
```

**Expected:**
- Fetches all learnings for current ISO week
- Detects Top Themes (2-4 most frequent topics)
- Identifies Most Active Topic
- Generates 2-3 Key Connections (if topics vary)
- Calculates streak (consecutive weeks)
- Compares to previous week (More active / Same pace / Less active, or "No previous data")
- Computes Source Mix
- Generates narrative Summary (3-5 sentences)
- Searches for "[FOS] Weekly Insights" database first, tries "Founder OS HQ - Weekly Insights", falls back to "Learning Log Tracker - Weekly Insights". If none exists, reports error: "Weekly Insights database not found. Ensure the Founder OS HQ workspace template is installed in your Notion workspace."
- Saves all 11 properties to Notion
- Displays formatted chat output with all sections

### TC-09: Weekly Synthesis (Past Week)

**Command:**
```
/learn:weekly --week=2026-W09
```

**Expected:**
- Fetches learnings for the specified past week only
- Generates full synthesis for that week
- Streak calculated as of that week (not today)
- Upserts entry with Week title "2026-W09"

### TC-10: Weekly Synthesis (Empty Week)

**Command:**
```
/learn:weekly --week=2020-W01
```

**Expected:**
- No learnings found for that week
- Displays: "No learnings logged for 2020-W01"
- Suggests using /learn:log
- Does NOT create a Weekly Insights entry
- May show current streak status

---

## Graceful Degradation Tests

### TC-GD-01: Notion Unavailable on Log

**Setup:** Disconnect Notion MCP or use invalid API key

**Command:**
```
/learn:log "Testing graceful degradation"
```

**Expected:**
- Detects Notion unavailability
- Displays learning in chat format (title, topics, source) for manual logging
- Does not error or crash

### TC-GD-02: Notion Unavailable on Search

**Setup:** Disconnect Notion MCP

**Command:**
```
/learn:search Technical
```

**Expected:**
- Reports connection error
- Does not fabricate results

---

## Validation Checklist

| # | Test | Status |
|---|------|--------|
| TC-01 | First learning capture with full arguments | ⬜ |
| TC-02 | Interactive capture with missing arguments | ⬜ |
| TC-03 | Duplicate detection on same-day re-log | ⬜ |
| TC-04 | Related insights linking across learnings | ⬜ |
| TC-05 | Search by topic filter | ⬜ |
| TC-06 | Search by keyword + date filter | ⬜ |
| TC-07 | Search with no results (empty state) | ⬜ |
| TC-08 | Weekly synthesis for current week | ⬜ |
| TC-09 | Weekly synthesis for past week | ⬜ |
| TC-10 | Weekly synthesis for empty week | ⬜ |
| TC-GD-01 | Graceful degradation: log without Notion | ⬜ |
| TC-GD-02 | Graceful degradation: search without Notion | ⬜ |
