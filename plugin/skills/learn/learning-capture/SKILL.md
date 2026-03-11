---
name: Learning Capture
description: "Captures and stores learnings, insights, and observations in the Learning Log. Activates when the user wants to log something they learned, capture an insight, record an observation, or says 'I just realized [something]' — even if they don't explicitly say 'log a learning.' Handles categorization, tagging, and source attribution."
globs:
  - "commands/learn-log.md"
---

# Learning Capture

Capture daily learnings with auto-generated titles, topic detection, source classification, and related-insight linking. Used by: `/founder-os:learn:log`.

## Purpose and Context

Store a growing knowledge base of learnings, insights, and observations. Each learning entry includes an auto-generated title, 1-3 topic tags from a 10-category taxonomy, a classified source type, and links to related past insights. The Notion database is the single source of truth. All capture logic operates through the patterns defined in this skill.

---

## Notion Database

**Database name**: Search for `[FOS] Learnings` first, then fall back to `Founder OS HQ - Learnings`, then `Learning Log Tracker - Learnings`.

Use dynamic database discovery: search the workspace for a database titled "[FOS] Learnings". If not found, try "Founder OS HQ - Learnings". If not found, fall back to "Learning Log Tracker - Learnings". If none is found, report: "Learnings database not found. Ensure the Founder OS HQ workspace template is installed in your Notion workspace." Do not create the database automatically.

### Schema

| Property | Type | Notes |
|----------|------|-------|
| Title | title | Auto-generated 5-8 word summary. Title Case. Max 80 characters. |
| Insight | rich_text | Full learning text as provided by the user (15-2000 characters). |
| Topics | multi_select | 1-3 auto-detected topic categories from the 10-category taxonomy. |
| Source Type | select | One of 5 source types: Experience, Reading, Conversation, Experiment, Observation. |
| Context | rich_text | Optional additional context provided via `--context` flag. |
| Related IDs | rich_text | Comma-separated page IDs of 2-3 most related past learnings. |
| Related Titles | rich_text | Comma-separated titles of related past learnings for quick scanning. |
| Week | rich_text | ISO week identifier as `YYYY-WNN` (e.g., `2026-W10`). |
| Logged At | date | ISO 8601 timestamp when the learning was captured. |
| Company | relation | Relation to [FOS] Companies DB. Populate when the learning/insight mentions or relates to a known company. Auto-detect by matching company names in the insight text against [FOS] Companies, or use the explicit `--company` flag value. Leave empty if no company association is detected. |

### Idempotent Upsert Rule

Search the database for a page whose `Title` matches the auto-generated title AND whose `Logged At` falls on the same calendar day. If a match exists, update the existing page. If no match exists, create a new page. This allows multiple distinct learnings per day while preventing accidental duplicates from re-runs.

---

## Title Generation

Generate a concise 5-8 word summary from the learning insight text. Apply these rules:

- Use Title Case (capitalize first letter of each major word)
- Maximum 80 characters
- Start with a noun or gerund (e.g., "Effective Error Handling in Async Code")
- Capture the core takeaway, not just the topic
- Omit articles (a, an, the) where possible for brevity
- Never start with "I learned" or "Learning about"

**Examples:**
| Insight text | Generated title |
|---|---|
| "Today I realized that async error handling works much better when you wrap each await in its own try-catch rather than one big block" | "Granular Try-Catch Blocks for Async Errors" |
| "Had a great chat with Sarah about how onboarding clients with a kickoff questionnaire reduces scope creep by 40%" | "Kickoff Questionnaires Reduce Client Scope Creep" |
| "Reading about how Notion's API handles pagination taught me to always check has_more before assuming results are complete" | "Notion API Pagination Requires Has_More Check" |

---

## Source Type Detection

Classify how the learning was acquired. Use the `--source` flag value when provided. When no flag is given, infer the source type from the insight text using these signals:

| Source Type | Inference Signals |
|---|---|
| Experience | "I did", "I tried", "I built", "working on", "in production", "deployed", "shipped", personal action verbs |
| Reading | "I read", "article", "book", "blog post", "documentation", "paper", "according to", citation-like language |
| Conversation | "talked to", "discussed with", "meeting with", "someone told me", "heard from", named people, dialogue references |
| Experiment | "tested", "experimented", "A/B test", "benchmarked", "compared", "measured", "hypothesis", data-driven language |
| Observation | "noticed", "observed", "pattern", "trend", "seems like", "interesting that", passive discovery language |

When inference is ambiguous (signals for multiple types), select the strongest match. When no signals are detected, default to `Experience` and note the assumption.

---

## Topic Auto-Detection

Detect 1-3 topic categories from the 10-category taxonomy. For the full detection algorithm including keyword signals, scoring thresholds, multi-topic handling, and fallback logic, read `${CLAUDE_PLUGIN_ROOT}/skills/learn/learning-capture/references/topic-detection-algorithm.md`.

### Topic Taxonomy (Quick Reference)

| Topic | Focus Area |
|---|---|
| Technical | Code, architecture, APIs, debugging, infrastructure |
| Process | Workflows, methodologies, project management, operations |
| Business | Revenue, clients, pricing, market, growth, financials |
| People | Team dynamics, leadership, communication, relationships |
| Tool | Software tools, platforms, integrations, configurations |
| Strategy | Long-term planning, positioning, competitive moves, vision |
| Mistake | Errors, failures, things to avoid, lessons from going wrong |
| Win | Successes, achievements, things that worked well |
| Idea | New concepts, possibilities, creative solutions, what-ifs |
| Industry | Market trends, competitor moves, regulatory changes, sector news |

Custom topics may be added by the user. Store custom topics as new multi_select options.

---

## Related Insights

After capturing a new learning, find 2-3 most related past insights from the database. For the full matching algorithm including overlap scoring, recency tiebreaking, keyword fallback, and empty-result handling, read `${CLAUDE_PLUGIN_ROOT}/skills/learn/learning-capture/references/related-insights-algorithm.md`.

### Quick Reference

- Query the database for entries sharing at least one `Topics` value with the new learning
- Score by topic overlap: `shared_topics / max_topics x 10`
- Minimum score threshold: 3 points
- Tiebreak by `Logged At` descending (most recent first)
- Return maximum 3 related insights
- Store matched page IDs in `Related IDs` and titles in `Related Titles` as comma-separated rich_text
- If no matches meet the threshold, leave Related IDs and Related Titles empty

---

## Capture Guardrails

### Input Validation
- Reject insight text shorter than 15 characters (likely incomplete)
- Reject insight text longer than 2000 characters (exceeds Notion rich_text limit)
- For insights between 15-2000 characters, proceed with capture

### Week Calculation
- Calculate the ISO week from the current date
- Format as `YYYY-WNN` (e.g., `2026-W10`)
- ISO weeks start on Monday and end on Sunday
- Store in the `Week` property for weekly aggregation queries

### Context Field
- Store the `--context` flag value in the `Context` property
- If no `--context` flag is provided, leave `Context` empty
- Context provides supplementary information (project name, meeting reference, etc.)

---

## Edge Cases

### Notion Unavailable
Report the error clearly and display the captured learning in chat format only. Never silently discard a learning. Include the auto-generated title, detected topics, and source type in the chat output so the user can manually log it later.

### Duplicate Detection
If the idempotent check finds a matching Title + same-day entry, present the existing entry and ask whether to update it or save under a modified title. Never silently overwrite.

### No Topic Match
If the topic detection algorithm finds no keyword matches above the scoring threshold, assign the single topic `Idea` as a catch-all. Note the assumption in the chat confirmation.

### Related Insights in Empty Database
On the very first learning logged, there are no past entries to match against. Skip the related-insights step and confirm that the learning was saved without related insights.

---

## Additional Resources

### Reference Files

For detailed algorithms and edge cases, consult:
- **`${CLAUDE_PLUGIN_ROOT}/skills/learn/learning-capture/references/topic-detection-algorithm.md`** — Full 10-category keyword taxonomy with scoring thresholds, multi-topic selection rules, exclusion signals, and source-type fallback logic
- **`${CLAUDE_PLUGIN_ROOT}/skills/learn/learning-capture/references/related-insights-algorithm.md`** — Overlap scoring formula, minimum thresholds, recency tiebreaking, keyword-matching fallback, and empty-result handling
