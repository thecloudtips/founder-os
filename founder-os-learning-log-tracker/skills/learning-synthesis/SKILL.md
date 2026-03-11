---
name: Learning Synthesis
description: "Synthesizes weekly learning summaries with theme detection, streak tracking, and trend analysis. Activates when the user wants a weekly learning review, insight trends, streak check, or asks 'what themes emerged from my learnings this week?' Covers pattern recognition, cross-learning connections, and growth metrics."
globs:
  - "commands/learn-weekly.md"
---

# Learning Synthesis

Aggregate, analyze, and synthesize a week's learnings into themes, connections, and streak metrics. Used by: `/learn:weekly`.

## Purpose and Context

Transform raw daily learnings into actionable weekly intelligence. Detect recurring themes, identify cross-topic connections, track learning consistency via streaks, and compare activity trends to the previous week. Output is stored in a dedicated Weekly Insights Notion database and displayed as a formatted chat summary.

---

## Notion Databases

### Read From: `[FOS] Learnings` (fallback: `Founder OS HQ - Learnings`, then `Learning Log Tracker - Learnings`)

Search for "[FOS] Learnings" first. If not found, try "Founder OS HQ - Learnings". If not found, fall back to "Learning Log Tracker - Learnings". Query entries where `Week` matches the target week (format: `YYYY-WNN`). This retrieves all learnings for the synthesis window.

### Write To: `[FOS] Weekly Insights` (fallback: `Founder OS HQ - Weekly Insights`, then `Learning Log Tracker - Weekly Insights`)

Use dynamic database discovery: search the workspace for a database titled "[FOS] Weekly Insights". If not found, try "Founder OS HQ - Weekly Insights". If not found, fall back to "Learning Log Tracker - Weekly Insights". If none is found, report: "Weekly Insights database not found. Ensure the Founder OS HQ workspace template is installed in your Notion workspace." Do not create the database automatically.

#### Schema

| Property | Type | Notes |
|----------|------|-------|
| Week | title | ISO week identifier as `YYYY-WNN`. Primary key for upsert. |
| Summary | rich_text | Narrative 3-5 sentence synthesis of the week's learnings. |
| Top Themes | multi_select | 2-4 most frequent topic categories from the week. |
| Learning Count | number | Total number of learnings logged during the week. |
| Most Active Topic | select | Single topic with the highest frequency for the week. |
| Key Connections | rich_text | Prose identifying 2-3 cross-learning patterns. |
| Learnings List | rich_text | Scannable bulleted index of all learning titles. |
| Streak Days | number | Consecutive weeks with at least one learning logged. |
| Vs Last Week | select | `More active`, `Same pace`, or `Less active`. |
| Source Mix | rich_text | Breakdown of learning sources (e.g., "Experience: 3, Reading: 2"). |
| Generated At | date | ISO 8601 timestamp when the synthesis was generated. |

#### Idempotent Upsert Rule

Search the database for a page whose `Week` (title) matches the target week string. If a match exists, update all properties. If no match exists, create a new page. This allows re-running `/learn:weekly` for the same week to refresh the analysis.

---

## Week Boundary Calculation

Determine the target week window:

- Default: the current ISO week (Monday 00:00 to Sunday 23:59)
- Override: `--week=YYYY-WNN` flag specifies an explicit week
- ISO weeks start on Monday and end on Sunday
- Calculate the Monday and Sunday dates from the ISO week number

Example: `2026-W10` → Monday 2026-03-02 through Sunday 2026-03-08.

---

## Theme Detection

Analyze the Topics distribution across all learnings in the target week. For the full algorithm including frequency counting, minimum thresholds, and selection rules, read `${CLAUDE_PLUGIN_ROOT}/skills/learning-synthesis/references/theme-detection-algorithm.md`.

### Quick Reference

- Count the frequency of each topic across all learnings in the week
- Select the 2-4 most frequent topics as Top Themes
- If fewer than 3 learnings, select the top 1-2 topics instead
- The single most frequent topic becomes `Most Active Topic`
- When there is a tie for Most Active Topic, prefer the topic that appeared in the most recent learning

---

## Key Connections

Identify 2-3 cross-learning patterns where insights from different topics reinforce, contrast, or build upon each other.

### Connection Detection

- Find pairs of learnings that share at least one Topic but differ in at least one other Topic
- Prioritize pairs where insights have complementary or contrasting content
- Describe each connection as a brief prose sentence explaining the relationship

Example: "Your Technical insight about error handling patterns reinforced your Process learning about code review checklists — both point toward catching issues earlier in the development cycle."

When fewer than 3 learnings exist for the week, or all learnings share identical Topics, note "No cross-topic connections detected this week."

---

## Streak Calculation

Track consecutive weeks of learning activity. For the full backwards-scan algorithm, gap detection, and display formatting, read `${CLAUDE_PLUGIN_ROOT}/skills/learning-synthesis/references/streak-calculation.md`.

### Quick Reference

- Query the `Weekly Insights` database ordered by `Week` title descending
- Starting from the target week, scan backwards checking for consecutive week entries
- A streak breaks when a week has no corresponding entry (gap detected)
- Store the streak count in `Streak Days` (named for the metric, counts weeks)
- Display format: "N weeks" with fire emoji 🔥 for streaks of 4+ weeks
- First-ever weekly summary: display "Starting your streak! 🌱"

---

## Trend Comparison

Compare the target week's Learning Count to the previous week's Learning Count using 20% thresholds:

| Condition | Vs Last Week Value |
|---|---|
| Current > Previous × 1.2 | `More active` |
| Current < Previous × 0.8 | `Less active` |
| Otherwise | `Same pace` |

When the previous week has no entry in the Weekly Insights database, skip the comparison and note "No previous week data for comparison."

---

## Source Mix

Count the occurrences of each Source Type across the week's learnings. Format as a comma-separated breakdown:

```
Experience: 3, Reading: 2, Conversation: 1
```

Order by frequency descending. Omit source types with zero occurrences.

---

## Learnings List

Generate a scannable bulleted list of all learning titles from the week:

```
• Granular Try-Catch Blocks for Async Errors
• Kickoff Questionnaires Reduce Client Scope Creep
• Notion API Pagination Requires Has_More Check
```

Order by `Logged At` ascending (chronological).

---

## Summary Generation

Write a 3-5 sentence narrative synthesis covering:

1. Total learning volume and how it compares to the trend
2. Dominant themes and what they suggest about current focus
3. Notable connections or patterns across learnings
4. One forward-looking insight or recommendation

Write in a professional but conversational tone. Use specific references to individual learnings when relevant.

---

## Output Format

### Chat Output (always displayed)

```
## 📊 Weekly Learning Insights — [YYYY-WNN]

**[N] learnings** logged this week | Streak: [N] weeks [emoji] | [Vs Last Week]

### 🎯 Top Themes
[Topic1], [Topic2], [Topic3]
Most active: [Topic] ([count] learnings)

### 📝 Summary
[3-5 sentence narrative synthesis]

### 🔗 Key Connections
- [Connection 1 prose]
- [Connection 2 prose]

### 📋 All Learnings
[Bulleted list of titles with dates]

### 📊 Source Mix
[Source breakdown]
```

### Notion Output (when --output includes notion or both)

Store all computed values in the Weekly Insights database using the schema above.

### File Output (when --output=PATH specified)

Write the chat format to the specified file path.

---

## Empty Week Handling

When no learnings exist for the target week:

1. Do not create a Weekly Insights entry
2. Display: "No learnings logged for [YYYY-WNN]. Use `/learn:log` to capture insights throughout the week."
3. Show the current streak status (which will have broken if this is the current week)

---

## Edge Cases

### Notion Unavailable
Report the error clearly. Display whatever synthesis is possible from cached data, or report that synthesis requires Notion access.

### Single Learning Week
Generate the full synthesis even for a single learning. Theme detection selects the learning's topics. Connections section notes "Only one learning this week — log more for cross-topic connections." Streak still counts.

### Very High Volume Weeks
For weeks with more than 20 learnings, the Learnings List in chat output should cap at 15 entries with a "... and N more" suffix. The full list is stored in Notion regardless.

---

## Additional Resources

### Reference Files

For detailed algorithms, consult:
- **`${CLAUDE_PLUGIN_ROOT}/skills/learning-synthesis/references/theme-detection-algorithm.md`** — Frequency counting methodology, minimum thresholds based on learning count, Top Themes selection rules, and tie-breaking logic
- **`${CLAUDE_PLUGIN_ROOT}/skills/learning-synthesis/references/streak-calculation.md`** — Backwards-scan algorithm for consecutive week detection, gap identification, display formatting rules, and edge cases for streak reset
