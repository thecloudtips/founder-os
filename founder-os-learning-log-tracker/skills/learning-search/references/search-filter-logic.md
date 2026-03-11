# Search Filter Logic

Detailed filter pipeline construction, Notion query building, and composite relevance scoring for the `/learn:search` command.

## Filter Pipeline Order

Apply filters sequentially in this fixed order. Each stage narrows the result set. Never reorder stages — the pipeline assumes Stage 1 output feeds Stage 2, and Stage 2 output feeds Stage 3.

### Stage 1: Topic Filter

Construct a Notion filter for the `Topics` multi_select property:

```json
{
  "property": "Topics",
  "multi_select": {
    "contains": "[topic_name]"
  }
}
```

Resolve the user's input against the 10 predefined topics using case-insensitive prefix matching. Accept the shortest unambiguous prefix:

- "tech" matches "Technical"
- "biz" or "bus" matches "Business"
- "strat" matches "Strategy"
- "mis" matches "Mistake"
- "peo" or "people" matches "People"
- "tool" matches "Tool"
- "win" matches "Win"
- "idea" matches "Idea"
- "ind" matches "Industry"
- "proc" matches "Process"

If the input does not match any topic prefix, do not discard it. Instead, reclassify the input as a keyword and pass it to Stage 3. Never error on an unrecognized topic — treat it as a search term.

When the user supplies multiple topics separated by commas, construct an AND compound filter requiring all topics to be present on the entry. Do not use OR for multi-topic queries — the intent is intersection, not union.

### Stage 2: Date Filter

Construct a Notion filter for the `Logged At` date property:

```json
{
  "property": "Logged At",
  "date": {
    "on_or_after": "[resolved_date]"
  }
}
```

Resolve the date value from the `--since` flag using these rules:

- `Nd` format (e.g., `30d`, `7d`): Subtract N days from today's date. Convert the result to an ISO 8601 date string (`YYYY-MM-DD`). Use midnight UTC as the boundary.
- `YYYY-MM-DD` format: Use the value directly without transformation. Validate that the date is not in the future — if it is, clamp to today's date and note the adjustment.
- `YYYY-MM` format: Expand to the first day of that month (`YYYY-MM-01`).
- No `--since` flag provided: Omit the date filter entirely from the compound filter. Do not default to any lookback window.

Never combine `on_or_after` with `on_or_before` — the search is always open-ended toward the present.

### Stage 3: Keyword Filter

For keyword filtering, construct a compound OR filter that searches across three text properties simultaneously:

```json
{
  "or": [
    { "property": "Title", "title": { "contains": "[keyword]" } },
    { "property": "Insight", "rich_text": { "contains": "[keyword]" } },
    { "property": "Context", "rich_text": { "contains": "[keyword]" } }
  ]
}
```

Use the `contains` operator for all three properties. Notion's `contains` is case-insensitive by default — do not attempt manual case normalization.

When the user supplies multiple keywords separated by spaces, treat each word as an independent keyword and construct a nested AND of ORs. Each keyword must appear in at least one of the three properties:

```json
{
  "and": [
    { "or": [/* keyword_1 across Title, Insight, Context */] },
    { "or": [/* keyword_2 across Title, Insight, Context */] }
  ]
}
```

This ensures all keywords are present somewhere in the entry, but they do not need to appear in the same property.

### Combining Filters

When multiple stages are active, combine them with a top-level AND:

```json
{
  "and": [
    { /* Stage 1: topic filter */ },
    { /* Stage 2: date filter */ },
    { /* Stage 3: keyword filter */ }
  ]
}
```

Omit any stage that is not active. If only one stage is active, use its filter directly without wrapping in AND. If zero stages are active, omit the `filter` key entirely from the query.

## Notion Query Construction

Build the complete database query object:

```json
{
  "database_id": "[learnings_db_id]",
  "filter": { /* combined filter from above, or omit key */ },
  "sorts": [
    { "property": "Logged At", "direction": "descending" }
  ],
  "page_size": 50
}
```

Always sort by `Logged At` descending as the initial Notion-side sort. This ensures the freshest entries arrive first from the API. Re-sort locally by composite relevance score after receiving results — the Notion sort serves only as a sensible default ordering before scoring is applied.

Set `page_size` to 50. Do not use `start_cursor` for pagination. A single query is the maximum — 50 results is the hard ceiling per search invocation.

Resolve `[learnings_db_id]` using the database discovery pattern: search Notion for a database titled "[FOS] Learnings" first, then try "Founder OS HQ - Learnings", then fall back to "Learning Log Tracker - Learnings". Cache the ID for the duration of the session. If no database exists, report that no learnings have been logged yet and suggest running `/learn:log` first.

## Composite Relevance Scoring

After fetching results from Notion, calculate a local relevance score for each entry. This score determines final display order.

### Scoring Formula

```
score = title_match + insight_match + context_match + topic_bonus + recency_modifier
```

| Component | Points | Condition |
|---|---|---|
| title_match | +3 | Keyword appears in Title (case-insensitive substring match) |
| insight_match | +2 | Keyword appears in Insight text (case-insensitive substring match) |
| context_match | +1 | Keyword appears in Context text (case-insensitive substring match) |
| topic_bonus | +2 | Active topic filter matches one of the entry's Topics values exactly |
| recency_recent | +1 | Logged At is within the last 7 days from today |
| recency_old | -1 | Logged At is more than 90 days ago |

### Score Calculation Rules

Apply each component independently. Components are purely additive — a single entry can accumulate points from every applicable component.

- Maximum possible score per entry: 3 + 2 + 1 + 2 + 1 = **9**
- Minimum possible score per entry: 0 + 0 + 0 + 0 + (-1) = **-1**

When multiple keywords are active, evaluate title_match, insight_match, and context_match for each keyword independently and sum all points. An entry matching two keywords in the title receives 3 + 3 = 6 points from the title component alone.

When no keyword is active (topic-only or date-only search), skip title_match, insight_match, and context_match entirely. Apply only topic_bonus and recency_modifier to each entry. This prevents entries from clustering at score 0 when no text matching is possible.

Recency is mutually exclusive: an entry is either recent (+1), old (-1), or neither (0). An entry aged between 8 and 90 days receives no recency modifier.

### Re-sorting

Sort the scored results by:

1. Composite score descending (highest relevance first)
2. Tiebreak: `Logged At` descending (most recent first among equal scores)

Apply the `--limit` value (default: 10) after scoring and sorting. Never apply the limit before scoring — score all 50 fetched results first, then truncate to the requested limit.

## Edge Cases

### No Filters Active

When the user runs `/learn:search` with no arguments — no topic, no date, and no keyword:

- Omit the `filter` key from the Notion query entirely.
- Return the 10 most recent learnings sorted by `Logged At` descending.
- Prepend to the output: "Showing most recent learnings. Add a topic or keyword to narrow results."

### Single-Character Keywords

Reject keywords shorter than 2 characters before constructing the Notion filter. Display: "Keyword too short. Use at least 2 characters for search." Do not include the rejected keyword in the query. If all keywords are rejected, fall back to the no-keyword path (topic and date filters only).

### Empty Results

When the query returns zero results, report clearly: "No learnings found matching your search." Follow with suggestions based on which filters were active — suggest broadening the date range, trying a different topic, or using fewer keywords. Never return an empty list without guidance.

### Pagination Boundary

If the Notion API response includes a `has_more: true` indicator, note the total count in the output: "Showing top [limit] of 50+ matching learnings. Narrow your filters for more precise results." Do not issue a follow-up query with `start_cursor`. The 50-result ceiling is absolute — accept that some results may be excluded and rely on the date and topic filters to keep the result set relevant.
