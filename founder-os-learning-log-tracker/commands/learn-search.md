---
description: Search and browse past learnings by topic, keyword, or date
argument-hint: "[topic-or-keyword] [--since=Nd|YYYY-MM-DD] [--source=TYPE] [--limit=N]"
allowed-tools: ["Read"]
---

# /learn:search

Query the Learning Log Tracker database to find past learnings filtered by topic, keyword, date range, and source type. Display ranked results with related insight cross-references.

## Load Skills

Read the learning-search skill before starting any step:

1. `${CLAUDE_PLUGIN_ROOT}/skills/learning-search/SKILL.md`

Apply learning-search for all filter logic, result ranking, display formatting, and empty result handling.

## Parse Arguments

Extract from `$ARGUMENTS`:

- **topic-or-keyword** (optional positional) — if the value matches one of the 10 predefined topics (case-insensitive prefix match), treat as a topic filter. Otherwise, treat as a keyword search term. If empty, return the most recent learnings with no filters.
- `--since=VALUE` (optional) — date filter. Accepts `Nd` (e.g., `7d`, `30d`) for relative lookback or `YYYY-MM-DD` for absolute date. Entries on or after the resolved date are included.
- `--source=TYPE` (optional) — filter by Source Type (experience, reading, conversation, experiment, observation).
- `--limit=N` (optional) — maximum results to return. Default: 10. Maximum: 50.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Step 1: Verify Notion Availability

Check that the Notion MCP server is connected. If unavailable, display:

```
⚠️ Notion is not available. Cannot search learnings without database access.
Check your Notion MCP connection and try again.
```

Then stop.

## Step 2: Locate Database

Search the Notion workspace for a database named "[FOS] Learnings". If not found, try "Founder OS HQ - Learnings". If not found, fall back to "Learning Log Tracker - Learnings". If none exists, display:

```
📭 No learning log found yet. Use /learn:log to capture your first learning!
```

Then stop. Do not create the database on read operations.

## Step 3: Build Filter Pipeline

Read `${CLAUDE_PLUGIN_ROOT}/skills/learning-search/references/search-filter-logic.md` for the detailed Notion query construction.

Apply filters in the fixed order defined in the learning-search skill:

1. **Topic filter** — if a topic was identified from the positional argument
2. **Date filter** — if `--since` was provided
3. **Source filter** — if `--source` was provided, add a filter for `Source Type` equals the specified value
4. **Keyword filter** — if the positional argument is a keyword (not a topic match)

Combine active filters with AND logic.

## Step 4: Execute Query

Query the Notion database with the constructed filter. Fetch up to 50 results sorted by `Logged At` descending.

## Step 5: Score and Rank Results

Apply the composite relevance scoring from the learning-search skill:

- Title keyword match: +3
- Insight keyword match: +2
- Context keyword match: +1
- Exact topic match: +2
- Recency (last 7 days): +1
- Old (90+ days): -1

Re-sort results by composite score descending, tiebreak by `Logged At` descending.

Apply the `--limit` value (default 10).

## Step 6: Display Results

Format results using the display template from the learning-search skill. Use topic emojis:

```
### 🔍 Learning Search Results

**Query**: [search terms] | **Filters**: [active filters] | **Results**: N found

1. 📘 **Granular Try-Catch Blocks for Async Errors** — Technical, Process
   _Discovered that wrapping each await in its own try-catch rather than one big block..._
   📅 2026-03-05 | Source: Experience
   🔗 Related: API Rate Limiting Best Practices, Error Monitoring Setup

2. 💡 **Notion API Pagination Requires Has_More Check** — Technical, Tool
   _Reading about how Notion's API handles pagination taught me to always check..._
   📅 2026-03-03 | Source: Reading
   🔗 Related: none
```

Topic emoji mapping: Technical=📘, Process=⚙️, Business=💼, People=👥, Tool=🔧, Strategy=🎯, Mistake=⚠️, Win=🏆, Idea=💡, Industry=🌐

## Step 7: Handle Empty Results

If no results match, follow the empty results handling from the learning-search skill:

```
📭 No learnings found matching "[query]" with filters: [active filters].

💡 Suggestions:
  • Remove the date filter to search all time
  • Try a related topic: [suggest 2-3 related topics]
  • Use a shorter or broader keyword

📊 Your learning log contains N entries total.
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Graceful Degradation

- **Notion unavailable**: Error message at Step 1. Do not fabricate results.
- **Database not found**: Friendly message at Step 2 suggesting /learn:log.
- **No results**: Constructive suggestions at Step 7.
- **Ambiguous argument**: Prioritize topic matching over keyword. Note in output.

## Usage Examples

```
/learn:search Technical
/learn:search "error handling" --since=30d
/learn:search --source=reading --limit=20
/learn:search Process --since=7d
/learn:search
```
