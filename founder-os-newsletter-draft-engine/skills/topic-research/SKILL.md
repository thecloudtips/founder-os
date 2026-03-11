---
name: Topic Research
description: "Performs multi-source web research to discover, score, and organize findings for newsletter content. Activates when the user wants to research a topic, find trending material, gather sources for a newsletter, or asks 'what's new in [topic]?' Searches across web, GitHub, Reddit, and blogs with recency scoring and deduplication."
globs:
  - "commands/newsletter-research.md"
  - "commands/newsletter-draft.md"
---

## Overview

Conduct multi-source web research for a given topic to produce a structured set of findings ready for the newsletter outline and drafting phases. Formulate 5-8 targeted search queries per topic across multiple source types (general web, GitHub, Reddit, Quora, official blogs). Parse results into structured findings with title, source, URL, summary, date, and relevance score. Apply recency scoring to weight recent content higher. Deduplicate findings that appear across multiple sources. Categorize each finding by type. Produce a research summary organized by category and recency for handoff to the outline phase.

## Multi-Source Query Strategy

Generate 5-8 search queries per topic, distributed across source types to maximize coverage and diversity of perspectives.

### Query Formulation Rules

1. Start with the raw topic provided by the user (e.g., "AI code review tools").
2. Expand the topic into facets: what it is, why it matters, who uses it, what changed recently, and what the community thinks.
3. Formulate one query per facet, targeting a specific source type.
4. Include at least one query for each of the four required source types: general web, GitHub, Reddit, and official/blog sources. Quora is optional but recommended when the topic has a Q&A dimension.
5. Append temporal qualifiers to queries when recency matters (e.g., "2026", "this month", "latest").
6. Avoid overly broad queries. Prefer specific noun phrases over single keywords.

### Source Type Distribution

| Source Type | Queries | Purpose |
|-------------|---------|---------|
| General Web | 1-2 | Broad coverage, news articles, analysis pieces |
| GitHub (`site:github.com`) | 1-2 | Trending repos, new releases, changelogs, tools |
| Reddit (`site:reddit.com`) | 1 | Community sentiment, discussions, pain points |
| Official Blogs / Changelogs | 1-2 | Authoritative announcements, product updates |
| Quora (`site:quora.com`) | 0-1 | Expert Q&A, alternative perspectives |

For detailed query templates and examples per source type, see `${CLAUDE_PLUGIN_ROOT}/skills/topic-research/references/query-patterns.md`.

### Query Output Format

Produce a query plan before executing searches:

```
Query Plan for: "[Topic]"
1. [general] "exact query string"
2. [github]  "site:github.com exact query string"
3. [reddit]  "site:reddit.com exact query string"
4. [blog]    "exact query string"
5. [general] "exact query string"
...
```

Display the query plan to the user before proceeding so they can refine or redirect.

## Finding Extraction

Parse each search result into a structured finding object. Extract consistently regardless of source type.

### Finding Structure

Each finding contains:

- **title**: Headline or page title from the search result. Clean up trailing site names (remove " - Medium", " : r/programming", etc.).
- **source**: Human-readable source name (e.g., "GitHub", "TechCrunch", "r/programming", "Official Blog").
- **source_type**: One of the five categories defined in Source Categorization below.
- **url**: Full URL of the source page. Validate that the URL is well-formed.
- **summary**: 2-3 sentence summary of the key point. Write in neutral, informative tone. Do not copy verbatim from the source -- synthesize the main takeaway.
- **date**: Publication or last-updated date in ISO format (YYYY-MM-DD). When no date is available, set to `null` and note "Date unavailable" in the summary.
- **relevance_score**: Float 0.0-1.0 measuring how directly the finding relates to the research topic. See Relevance Scoring below.
- **recency_score**: Float 0.0-1.0 based on age of the content. See Recency Scoring below.
- **combined_score**: `(relevance_score * 0.6) + (recency_score * 0.4)`. Used for final ranking.
- **source_urls**: Array of URLs. Initially contains only the primary URL. Grows during deduplication when the same finding appears from multiple sources.

### Relevance Scoring

Assign a relevance score from 0.0 to 1.0 based on topical alignment:

| Score Range | Criteria |
|-------------|----------|
| 0.8-1.0 | Directly addresses the topic. Contains the topic's key terms in title or first paragraph. Provides actionable or newsworthy information. |
| 0.5-0.79 | Related to the topic but covers a broader or adjacent subject. Mentions the topic but is not primarily about it. |
| 0.2-0.49 | Tangentially related. Shares a category or domain but the specific topic is secondary. |
| 0.0-0.19 | Minimally related. Only surface-level keyword overlap. Discard findings below 0.2. |

Filter out findings with relevance_score below 0.2 before further processing. They add noise without value.

## Recency Scoring

Weight recent findings higher to prioritize fresh content for the newsletter.

### Scoring Tiers

| Age | Recency Score | Label |
|-----|---------------|-------|
| 0-7 days | 1.0 | Fresh -- highest newsletter value |
| 8-14 days | 0.7 | Recent -- strong newsletter value |
| 15-30 days | 0.4 | Aging -- include only if highly relevant |
| 31-60 days | 0.2 | Stale -- include only for foundational context |
| 60+ days or unknown | 0.1 | Old -- exclude unless seminal/canonical |

### Date Handling

- Calculate age as calendar days between the finding's date and today's date.
- When date is `null`, assign recency_score of 0.1 (assume old).
- When a finding shows only a month without a day, use the 15th of that month.
- When a finding shows only a year, use July 1st of that year.

## Deduplication

Detect the same news, announcement, or topic covered by multiple sources and merge into a single finding with multiple source URLs.

### Detection Criteria

Two findings are duplicates when they meet ANY of these conditions:

1. **URL match**: Identical URLs after normalizing (strip trailing slashes, remove UTM parameters, normalize http/https).
2. **Title similarity**: Titles share 70%+ word overlap after removing stop words and lowering case.
3. **Content match**: Summaries describe the same specific event, release, or announcement (same product name + same version number, or same company + same action).

### Merge Strategy

When duplicates are detected:

1. Keep the finding with the highest relevance_score as the primary.
2. Append the duplicate's URL to the primary's `source_urls` array.
3. If the duplicate has a more recent date, update the primary's date.
4. If the duplicate has a higher relevance_score, update the primary's score.
5. Append unique details from the duplicate's summary to the primary (only if they add new information, not redundant phrasing).
6. Discard the duplicate finding from the results list.

### Source Diversity Bonus

After deduplication, findings that retain 3+ source URLs receive a +0.1 combined_score bonus (cap at 1.0). Multi-source coverage indicates a high-signal topic worth featuring in the newsletter.

## Source Categorization

Tag each finding with exactly one source type:

| Category | Tag | Detection Rules |
|----------|-----|-----------------|
| Official Release | `official-release` | URL contains company blog domain, changelog, or release notes page. Title mentions version numbers, "announces", "launches", "introduces", "releases". |
| Blog Post | `blog-post` | URL from known blog platforms (Medium, Substack, Dev.to, personal blogs) or contains `/blog/` in path. Analysis, opinion, or tutorial content. |
| GitHub Repository | `github-repo` | URL matches `github.com/[owner]/[repo]`. Content describes a tool, library, or open-source project. |
| Community Discussion | `community-discussion` | URL from Reddit, Quora, Hacker News, Stack Overflow, or forum domains. Content is a question, discussion thread, or community commentary. |
| Tutorial | `tutorial` | Content is primarily instructional. Contains step-by-step instructions, code examples, or "how to" framing. |

When a finding could match multiple categories, prefer the more specific tag: `official-release` > `tutorial` > `blog-post` > `community-discussion`.

## Research Summary Structure

Organize the final output for handoff to the outline phase. The summary serves as the raw material the newsletter-writing skill uses to build sections.

### Output Format

```markdown
# Research Summary: [Topic]
Generated: [YYYY-MM-DD]
Queries executed: [N]
Total findings: [N] (after dedup)

## Key Takeaways
- [1-sentence summary of the most important finding]
- [1-sentence summary of the second most important finding]
- [1-sentence summary of the third most important finding]

## Findings by Category

### Official Releases
| # | Title | Date | Score | Sources |
|---|-------|------|-------|---------|
| 1 | [title] | [date] | [combined] | [count] |
[detail block per finding]

### Blog Posts
[same table format]

### GitHub Repositories
[same table format]

### Community Discussions
[same table format]

### Tutorials
[same table format]

## Timeline View (Last 30 Days)
- [date]: [finding title] ([source_type])
- [date]: [finding title] ([source_type])
...

## Research Gaps
- [Areas where queries returned insufficient results]
- [Suggested follow-up queries to fill gaps]
```

### Detail Block Per Finding

Below each category table, include an expandable detail block per finding:

```markdown
**[#] [Title]** (Score: [combined_score])
Source: [source] | Date: [date] | Type: [source_type]
URLs: [url1], [url2], ...
Summary: [2-3 sentence summary]
Newsletter angle: [1-sentence suggestion for how to use this in the newsletter]
```

The "Newsletter angle" field is critical -- provide a concrete suggestion for how the finding could be framed in the newsletter (e.g., "Lead with this as the main story", "Use as a supporting data point", "Good for a 'tools to watch' sidebar").

### Ordering Rules

1. Within each category, sort findings by combined_score descending.
2. In the Timeline View, sort by date descending (most recent first).
3. In Key Takeaways, select the top 3 findings by combined_score regardless of category.

## Research Gaps Analysis

After completing all queries, identify gaps in the research:

- Categories with zero findings -- note the category and suggest a refined query.
- Topic facets not covered by any finding -- suggest additional search angles.
- Time periods with no results -- note whether the topic may be too new or too niche for broad coverage.

Include 2-3 suggested follow-up queries the user can run to fill gaps. Format each as a ready-to-execute query string with its target source type.

## Edge Cases

### Ambiguous Topic
When the topic is too broad (single word like "AI" or "marketing"), ask the user to narrow: "Topic '[topic]' is broad. Suggest a more specific angle: [3 suggestions based on the word]." Do not proceed with research until the topic is refined. A well-scoped topic yields 5-8 focused queries; an ambiguous topic yields noise.

### No Results
When queries return zero relevant findings (all below 0.2 relevance), report: "No relevant findings for '[topic]' across [N] queries. Consider these alternative angles: [suggestions]." Never fabricate findings.

### Rate Limits
When web search returns errors or rate limits, report the error and provide partial results from successful queries. Note which source types were skipped: "Research incomplete -- [source_type] queries failed. Partial results from [N] successful queries below."

### Non-English Topics
When the topic involves non-English content or markets, include at least one query in the relevant language if the user indicates the newsletter targets that audience. Default to English queries unless instructed otherwise.

## Graceful Degradation

If web search is unavailable entirely, report: "Web search unavailable -- cannot perform topic research. Provide URLs or content directly for manual analysis." Do not attempt to generate findings from training data alone. Research must be grounded in current web results.

If Notion is available, log the research summary to the **"[FOS] Research"** database with `Type = "Newsletter Research"`. If Notion is unavailable, output everything to chat. Never fail because of missing optional MCP servers.

## Notion Database Discovery

Do NOT create databases. Discover existing ones using this fallback chain:

1. Search Notion for **"[FOS] Research"**.
2. If not found, try **"Founder OS HQ - Research"**.
3. If not found, fall back to **"Newsletter Engine - Research"** (legacy name).
4. If none is found, skip Notion logging silently and output to chat only.

When writing to the Research database, always set the **Type** property to `"Newsletter Research"` to distinguish from other research types (e.g., Competitive Analysis from P15).
