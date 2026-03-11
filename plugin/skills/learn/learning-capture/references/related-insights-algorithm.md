# Related Insights Algorithm

Full algorithm for finding 2-3 most related past insights when a new learning is captured. Execute this algorithm immediately after saving a new learning entry to the Notion database. Use the detected Topics from the new entry as the primary matching signal, with a keyword fallback when topic overlap is insufficient.

## Overview

After a new learning is saved with its detected Topics, query the database for past entries that share topic overlap. Score, rank, and return the top matches as cross-references. Store the matched insight references directly on the new learning entry so users see connections without additional lookups.

## Step 1: Query for Candidates

Query the discovered Learnings database (see learning-capture SKILL.md for discovery protocol) using the following constraints:

- Filter: `Topics` contains ANY of the new learning's detected topics.
- Exclude: the newly created entry itself (by page ID). Never return the entry as its own related insight.
- Sort: `Logged At` descending to prefer recent entries in the initial fetch.
- Limit: fetch up to 20 candidates for scoring. Do not paginate beyond 20 results. Twenty candidates provide sufficient coverage for scoring without excessive API calls.

If the new learning has no detected Topics (empty Topics property), skip directly to the Keyword-Matching Fallback section below.

## Step 2: Overlap Scoring

For each candidate returned in Step 1, calculate the overlap score using this formula:

```
score = (shared_topics / max_topics) * 10
```

Where:

- `shared_topics` = number of Topics values that appear in BOTH the new learning and the candidate. Perform case-insensitive comparison when matching topic strings.
- `max_topics` = maximum number of Topics between the two entries, calculated as `max(new_topics_count, candidate_topics_count)`. Use the larger count to penalize asymmetric matches where one entry is far more broadly tagged than the other.

### Score Examples

| New Learning Topics | Candidate Topics | Shared | Max | Score |
|---|---|---|---|---|
| Technical, Process | Technical, Process, Tool | 2 | 3 | 6.7 |
| Business, Strategy | Business | 1 | 2 | 5.0 |
| Technical | Technical | 1 | 1 | 10.0 |
| Idea, Business | Technical, Process | 0 | 2 | 0.0 |

A perfect score of 10.0 means both entries share identical topic sets. A score of 0.0 means zero overlap. Scores between these bounds reflect partial relevance proportional to the degree of shared context.

## Step 3: Minimum Threshold

Discard candidates with scores below **3.0 points**. This threshold ensures only meaningfully related insights are surfaced. A score of 3.0 requires at least one shared topic where the denominator is no larger than 3, filtering out weak single-topic matches against heavily tagged entries.

Do not adjust this threshold dynamically. Apply 3.0 as a hard cutoff for all topic-based scoring.

## Step 4: Tiebreaking

When multiple candidates have the same overlap score, apply these tiebreakers in order:

1. Prefer more recent entries (`Logged At` descending). Recent insights are more likely to be contextually relevant to the user's current work.
2. If still tied (same date), prefer entries with more Topics (richer context). Entries with more topics provide broader connection potential for future cross-references.

Apply tiebreakers strictly in this order. Do not skip to the second tiebreaker without first attempting the first.

## Step 5: Select Top Results

Return the top **3** candidates by score after tiebreaking. If fewer than 3 candidates meet the threshold, return however many qualify (0, 1, or 2). Never pad the results with below-threshold entries to reach 3.

If exactly 0 candidates meet the threshold, proceed to the Keyword-Matching Fallback below.

## Step 6: Store References

For the selected related insights, write two properties on the new learning entry:

- Store their Notion page IDs as a comma-separated string in the new learning's `Related IDs` property.
- Store their Titles as a comma-separated string in the new learning's `Related Titles` property.

Example:

```
Related IDs: "abc123, def456, ghi789"
Related Titles: "Granular Try-Catch Blocks for Async Errors, API Rate Limiting Best Practices, Error Monitoring Dashboard Setup"
```

Maintain the same ordering in both properties so the first ID corresponds to the first title. Use a comma followed by a single space as the delimiter. Do not add trailing commas or extra whitespace.

## Keyword-Matching Fallback

When the topic-based query returns zero candidates above the threshold (e.g., the learning uses a rare topic combination or has no detected topics), fall back to keyword matching:

1. Extract 3-5 significant words from the new learning's Title. Remove stopwords: a, an, the, is, was, to, for, of, in, on, with, that, this, and, or, but. Select the remaining words by order of appearance, taking the first 5 significant words found.
2. Search the database for entries where Title or Insight contains any of these significant words. Use a single Notion database query with an OR filter across the extracted keywords.
3. Score keyword matches: award +1 point per matched word found in the candidate's Title or Insight. Count each keyword at most once per candidate regardless of how many times it appears.
4. Apply the same 3.0 minimum threshold. For keyword scoring, this means at least 3 distinct keyword matches are required.
5. Return top 3 by keyword score, tiebroken by recency (`Logged At` descending).

Proceed to Step 6 to store the results. If the keyword fallback also returns zero results, proceed to Empty-Result Handling.

## Empty-Result Handling

When both topic-based and keyword-based searches return zero results:

- Leave `Related IDs` empty (do not write the property or write an empty string).
- Leave `Related Titles` empty (do not write the property or write an empty string).
- In the chat confirmation message, include this note: "No related past insights found yet. Your learning log will build connections over time."

This outcome is expected for the first few learnings in a new log or when a topic is entirely new to the user's knowledge base. Do not treat zero related insights as an error condition. Do not prompt the user to manually select related entries.

## Performance Considerations

- Fetch at most 20 candidates per query to limit API calls. Do not increase this limit even if the database contains hundreds of entries.
- Score calculations are done locally (no additional Notion queries needed after the initial candidate fetch). Parse the Topics property from the returned candidate pages and compute overlap scores in memory.
- The keyword fallback adds one additional Notion query. Only trigger this fallback when the primary topic-based method yields zero candidates above the threshold. Never run both methods and merge results.
- Store references in a single Notion update call. Combine `Related IDs` and `Related Titles` into one page update request rather than issuing separate updates for each property.
