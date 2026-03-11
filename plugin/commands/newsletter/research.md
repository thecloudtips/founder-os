---
description: Deep research across web, GitHub, Reddit, Quora, and official blogs/changelogs for newsletter topics
argument-hint: "[topic] [--sources=web,github,reddit,quora] [--days=N]"
allowed-tools: ["Read"]
---

# Newsletter Research

Perform deep topic research across multiple web sources to gather findings for newsletter content. Searches the web, GitHub, Reddit, Quora, and official blogs/changelogs, then scores and deduplicates results into a structured research summary.

## Load Skill

Read the topic-research skill at `${CLAUDE_PLUGIN_ROOT}/skills/newsletter/topic-research/SKILL.md` for query formulation patterns, source type taxonomy, scoring formulas, deduplication logic, and finding extraction rules.

## Parse Arguments

Extract the topic and flags from `$ARGUMENTS`:
- **topic** (required) — the research topic. This is all text before any `--` flags. If no topic is provided, ask the user: "What topic should I research?"
- `--sources=web,github,reddit,quora` (optional) — comma-separated list of sources to search. Valid values: `web`, `github`, `reddit`, `quora`. Default: `web,github,reddit,quora`.
- `--days=N` (optional) — lookback window in days for recency scoring. Default: 14.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Research Process

1. **Formulate queries**: Based on the topic and the query patterns from the skill, generate 5-8 targeted web search queries. Include:
   - 1-2 general web queries for the topic (broad coverage, news, announcements)
   - 1-2 `site:github.com` queries for trending repos, releases, and open-source activity (only if `github` is in `--sources`)
   - 1-2 `site:reddit.com` queries for community discussions, opinions, and sentiment (only if `reddit` is in `--sources`)
   - 1 `site:quora.com` query for Q&A discussions and expert perspectives (only if `quora` is in `--sources`)
   - 1 query targeting official blogs, changelogs, or release notes for the topic

2. **Execute searches**: Run each formulated query using the WebSearch tool. For each query, extract the top results. If a search fails or returns no results, skip it and continue with remaining queries — never halt the entire research process for a single failed search.

3. **Extract findings**: Parse each search result into a structured finding with these fields:
   - **title**: The result title
   - **source**: The publication or site name
   - **url**: Full URL
   - **summary**: 1-2 sentence summary of the finding's relevance to the topic
   - **date**: Publication date if available, otherwise "Unknown"
   - **source_type**: Classify as one of: `official-release`, `blog-post`, `github-repo`, `community-discussion`, `tutorial`

4. **Score and sort**: Score each finding on two dimensions:
   - **relevance_score** (0.0-1.0): How directly the finding relates to the research topic. Score 1.0 for exact topic matches, 0.7+ for closely related, 0.4-0.6 for tangentially related, below 0.4 for loosely related.
   - **recency_score** (0.0-1.0): Based on the `--days` window. Findings within 7 days = 1.0, within 14 days = 0.7, within 30 days = 0.4, older or unknown = 0.2.
   - **combined_score** = relevance_score x 0.6 + recency_score x 0.4

   Sort all findings by combined_score descending.

5. **Deduplicate**: Merge findings that cover the same news, release, or discussion from different sources. When merging, keep the finding with the highest combined_score as primary and note the alternate sources. Two findings cover "the same news" if they reference the same event, release, or announcement — use title similarity and content overlap to detect this.

6. **Identify themes**: After scoring and deduplication, identify 3-5 key themes that emerge from the findings. A theme is a recurring topic, trend, or narrative that appears across multiple findings.

## Notion Integration

1. **Discover database**: Search Notion for a database named **"[FOS] Research"**. If not found, try **"Founder OS HQ - Research"**. If not found, fall back to **"Newsletter Engine - Research"** (legacy name). If none is found, skip Notion logging silently.
2. **Log research session**: Create a page in the discovered database with the research results. Set `Type = "Newsletter Research"` to distinguish from other research types in the consolidated database.

## Graceful Degradation

If Notion MCP is unavailable or any Notion operation fails:
- Display all research results in chat
- Do not warn or error — chat-only output is fully acceptable
- Omit the "Tracked in Notion" line from the output

## Output Format

After research is complete, display:

```
## Newsletter Research: [Topic]

**Date range scanned**: Last [N] days (since [start date])
**Sources searched**: [list of sources used]
**Total findings**: [count] ([count] after deduplication)
**Tracked in Notion**: Yes / No

---

### Findings by Source Type

| Source Type | Count |
|-------------|-------|
| Official Releases | [n] |
| Blog Posts | [n] |
| GitHub Repos | [n] |
| Community Discussions | [n] |
| Tutorials | [n] |

---

### Top Findings

| # | Score | Title | Source | Type | Date |
|---|-------|-------|--------|------|------|
| 1 | [combined] | [title] | [source] | [type] | [date] |
| 2 | ... | ... | ... | ... | ... |

[For each finding, include the URL as a markdown link on the title]

---

### Key Themes

1. **[Theme name]** — [1-sentence description of the theme and which findings support it]
2. **[Theme name]** — ...
3. **[Theme name]** — ...

---

Run `/founder-os:newsletter:outline` to structure these findings into a newsletter.
```

If no findings are returned from any source:
- Display: "No findings for '[topic]' in the last [N] days. Try broadening the topic or extending the date range with `--days=30`."

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/founder-os:newsletter:research AI agents
/founder-os:newsletter:research "Claude MCP plugins" --days=7
/founder-os:newsletter:research LLM fine-tuning --sources=web,github
/founder-os:newsletter:research "React Server Components" --sources=web,reddit --days=30
/founder-os:newsletter:research Kubernetes --sources=github
```
