---
name: Learning Search
description: "Searches and retrieves past learnings from the Learning Log by topic, category, or date. Activates when the user wants to find past insights, search their learning history, or asks 'what did I learn about [topic]?' Supports keyword search, category filtering, date ranges, and source-based browsing."
globs:
  - "commands/learn-search.md"
---

# Learning Search

Query, filter, and browse past learnings from the Learnings Notion database. Used by: `/learn:search`.

## Purpose and Context

Provide fast, relevant access to previously captured learnings. Support filtering by topic, keyword, date range, and source type. Return ranked results with related-insight cross-references for each match. This skill operates in read-only mode against the discovered Learnings database (see Notion Database Access below).

---

## Notion Database Access

**Database name**: Search for `[FOS] Learnings` first, then fall back to `Founder OS HQ - Learnings`, then `Learning Log Tracker - Learnings`.

Read-only access. Search the workspace for a database titled "[FOS] Learnings". If not found, try "Founder OS HQ - Learnings". If not found, fall back to "Learning Log Tracker - Learnings". If none exists, report that no learnings have been logged yet and suggest using `/learn:log` to start.

### Schema Reference

| Property | Type | Used in Search |
|----------|------|---------------|
| Title | title | Text search, display |
| Insight | rich_text | Text search, display |
| Topics | multi_select | Topic filter, display |
| Source Type | select | Source filter |
| Context | rich_text | Text search |
| Related IDs | rich_text | Cross-reference lookup |
| Related Titles | rich_text | Display |
| Week | rich_text | Date-range filter |
| Logged At | date | Date-range filter, sort, display |

---

## Filter Pipeline

Apply filters in this fixed order: **topic → date → keyword**. Each filter narrows the result set for the next.

### 1. Topic Filter

If the positional argument or `--topic` flag specifies a topic name, filter to entries where `Topics` contains the specified topic (case-insensitive match). Accept partial matches: "tech" matches "Technical".

If the positional argument looks like a general search term rather than a topic name (not matching any of the 10 predefined topics), skip this filter and treat it as a keyword instead.

### 2. Date Filter

If `--since=Nd` or `--since=YYYY-MM-DD` is specified, filter to entries where `Logged At` is on or after the resolved date.

- `--since=7d` → last 7 days from today
- `--since=30d` → last 30 days
- `--since=2026-01-15` → on or after January 15, 2026
- Default when no `--since` flag: no date filter (return all time)

### 3. Keyword Filter

If a keyword is provided (either as the positional argument when not matching a topic, or via additional text), filter to entries where `Title`, `Insight`, or `Context` contains the keyword string. Apply case-insensitive substring matching.

---

## Result Ranking

After filtering, rank results using a composite relevance score. Calculate the score for each result by summing these points:

| Signal | Points |
|--------|--------|
| Keyword match in Title | +3 |
| Keyword match in Insight | +2 |
| Keyword match in Context | +1 |
| Exact topic match (topic filter active) | +2 |
| Recency: logged in last 7 days | +1 |
| Recency: logged more than 90 days ago | -1 |

Sort results by composite score descending. Tiebreak by `Logged At` descending (most recent first).

---

## Display Format

Present results as a numbered list with topic emoji tags and key metadata:

```
### 🔍 Learning Search Results

**Query**: [search terms] | **Filters**: [active filters] | **Results**: N found

1. 📘 **[Title]** — Technical, Process
   _[First 120 chars of Insight text]..._
   📅 [Logged At date] | Source: [Source Type]
   🔗 Related: [Related Titles or "none"]

2. 💡 **[Title]** — Idea, Business
   _[First 120 chars of Insight text]..._
   📅 [Logged At date] | Source: [Source Type]
   🔗 Related: [Related Titles or "none"]
```

### Topic Emoji Mapping

| Topic | Emoji |
|-------|-------|
| Technical | 📘 |
| Process | ⚙️ |
| Business | 💼 |
| People | 👥 |
| Tool | 🔧 |
| Strategy | 🎯 |
| Mistake | ⚠️ |
| Win | 🏆 |
| Idea | 💡 |
| Industry | 🌐 |

Use the emoji of the first topic in the entry's Topics list as the leading icon.

---

## Result Limit

Default: 10 results. Override with `--limit=N`. Maximum: 50 results per query. If more results exist beyond the limit, note the total count and suggest narrowing the search.

---

## Related Insights in Search Results

For each search result, display the `Related Titles` value if non-empty. This provides cross-referencing without additional database queries. If `Related Titles` is empty, display "none".

---

## Empty Results Handling

When no results match the query:

1. Report the active filters clearly: "No learnings found matching [query] with filters [topic/date/keyword]."
2. Suggest broadening the search:
   - Remove the date filter if `--since` is active
   - Try related topic names (e.g., "Try 'Process' instead of 'workflow'")
   - Use a shorter keyword
3. Show the total count of learnings in the database for context: "Your learning log contains N entries total."

---

## Edge Cases

### Database Not Found
If none of the `[FOS] Learnings`, `Founder OS HQ - Learnings`, or `Learning Log Tracker - Learnings` databases exists, report clearly: "No learning log found. Use `/learn:log` to capture your first learning." Do not create the database on read operations.

### Notion Unavailable
Report the connection error and suggest retrying. Do not fabricate search results.

### Ambiguous Positional Argument
When the first argument could be either a topic name or a keyword (e.g., "process" matches the Process topic but could also be a keyword), prioritize topic matching. If the user seems to want keyword search instead, suggest using `--topic=none` or rephrasing.

### Very Broad Queries
For queries with no topic filter, no date filter, and a single common word as keyword, warn that results may be broad and suggest adding a topic or date filter.

---

## Additional Resources

### Reference Files

For detailed filter construction and Notion query patterns, consult:
- **`${CLAUDE_PLUGIN_ROOT}/skills/learning-search/references/search-filter-logic.md`** — Sequential filter pipeline construction, Notion API query building, composite relevance scoring formula, and edge case handling for complex multi-filter queries
