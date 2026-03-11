---
description: Generate a weekly learning synthesis with themes, connections, and streak tracking
argument-hint: "[--week=YYYY-WNN] [--output=notion|chat|both|PATH] [--schedule=EXPR] [--persistent]"
allowed-tools: ["Read", "Write"]
---

# /founder-os:learn:weekly

Synthesize a week's learnings into themes, connections, streak metrics, and trend comparisons. Store the synthesis in the Weekly Insights Notion database and display a formatted summary.

## Load Skills

Read the learning-synthesis skill before starting any step:

1. `${CLAUDE_PLUGIN_ROOT}/skills/learn/learning-synthesis/SKILL.md`

Apply learning-synthesis for all week calculations, theme detection, connection analysis, streak tracking, trend comparison, and output formatting.

## Parse Arguments

Extract from `$ARGUMENTS`:

- `--week=YYYY-WNN` (optional) — target ISO week. Default: current week. Example: `--week=2026-W10`.
- `--output=VALUE` (optional) — output destination. Options: `notion` (database only), `chat` (chat only), `both` (default: database + chat), or a file path (e.g., `./reports/weekly.md`).

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Scheduling Support

If `$ARGUMENTS` contains `--schedule`:
1. Extract the schedule value and any `--persistent` flag
2. Read `_infrastructure/scheduling/SKILL.md` for scheduling bridge logic
3. Read `_infrastructure/scheduling/references/schedule-flag-spec.md` for argument parsing
4. Default suggestion if no expression given: `"0 16 * * 5"` (Fridays 4:00pm)
5. Handle the schedule operation (create/disable/status) per the spec
6. Exit after scheduling — do NOT continue to main command logic

## Step 1: Verify Notion Availability

Check that the Notion MCP server is connected. If unavailable, display:

```
⚠️ Notion is not available. Weekly synthesis requires database access.
Check your Notion MCP connection and try again.
```

Then stop.

## Step 2: Resolve Target Week

If `--week` was provided, parse the ISO week identifier and calculate the Monday-Sunday date range.

If no `--week` flag, calculate the current ISO week and its date range.

Display: "Analyzing learnings for week [YYYY-WNN] ([Monday date] – [Sunday date])..."

## Step 3: Fetch Learnings

Query the learnings database (discovered as "[FOS] Learnings", "Founder OS HQ - Learnings", or fallback "Learning Log Tracker - Learnings") for entries where `Week` equals the target week identifier (e.g., `2026-W10`).

If no learnings exist for the target week:

```
📭 No learnings logged for [YYYY-WNN] ([Monday] – [Sunday]).

Use /founder-os:learn:log to capture insights throughout the week.
Current streak status: [streak info if available]
```

Then stop. Do not create a Weekly Insights entry for an empty week.

## Step 4: Detect Themes

Read `${CLAUDE_PLUGIN_ROOT}/skills/learn/learning-synthesis/references/theme-detection-algorithm.md` for the full algorithm.

1. Count topic frequencies across all fetched learnings.
2. Select Top Themes (2-4 topics based on learning count thresholds).
3. Identify the Most Active Topic.

## Step 5: Identify Connections

Apply the connection detection logic from the learning-synthesis skill:

1. Find pairs of learnings with shared + different topics.
2. Score and select top 2-3 connections.
3. Write prose descriptions for each connection.

If fewer than 3 learnings or all identical topics, note the limitation.

## Step 6: Calculate Streak

Read `${CLAUDE_PLUGIN_ROOT}/skills/learn/learning-synthesis/references/streak-calculation.md` for the full algorithm.

1. Query the Weekly Insights database for past entries.
2. Include the current week as a virtual entry.
3. Scan backwards through consecutive ISO weeks.
4. Stop at the first gap.
5. Format the streak with appropriate emoji.

## Step 7: Compare Trend

Fetch the previous week's entry from the Weekly Insights database.

Compare Learning Count using 20% thresholds:
- Current > Previous × 1.2 → "More active"
- Current < Previous × 0.8 → "Less active"
- Otherwise → "Same pace"

If no previous week entry exists, note "No previous week data for comparison."

## Step 8: Compute Source Mix

Count occurrences of each Source Type across the week's learnings. Format as: "Experience: 3, Reading: 2, Conversation: 1". Order by frequency descending. Omit zero-count types.

## Step 9: Build Learnings List

Generate a bulleted list of all learning Titles ordered by `Logged At` ascending (chronological).

Cap the chat display at 15 entries with "... and N more" suffix for weeks with 20+ learnings. Store the full list in Notion regardless.

## Step 10: Write Summary

Generate a 3-5 sentence narrative synthesis covering:
1. Total learning volume and trend comparison
2. Dominant themes and what they suggest about current focus
3. Notable connections or patterns
4. One forward-looking insight or recommendation

Professional but conversational tone. Reference specific learning titles when relevant.

## Step 11: Save to Notion

If output includes `notion` or `both`:

### Locate or Create the Database

Search for "[FOS] Weekly Insights". If not found, try "Founder OS HQ - Weekly Insights". If not found, fall back to "Learning Log Tracker - Weekly Insights". If none is found, report: "Weekly Insights database not found. Ensure the Founder OS HQ workspace template is installed in your Notion workspace." Then stop.

### Upsert the Entry

Search for an existing entry with `Week` matching the target. Update if found, create if not.

Set all 11 properties:
- **Week**: target ISO week identifier
- **Summary**: narrative synthesis
- **Top Themes**: selected theme topics (multi_select)
- **Learning Count**: total learnings in the week
- **Most Active Topic**: highest-frequency topic (select)
- **Key Connections**: prose connection descriptions
- **Learnings List**: bulleted title index
- **Streak Days**: consecutive weeks count
- **Vs Last Week**: trend comparison value
- **Source Mix**: source type breakdown
- **Generated At**: current timestamp

## Step 12: Display Chat Output

If output includes `chat` or `both` (default):

```
## 📊 Weekly Learning Insights — [YYYY-WNN]

**[N] learnings** logged this week | Streak: [N] weeks [emoji] | [Vs Last Week]

### 🎯 Top Themes
[Topic1], [Topic2], [Topic3]
Most active: [Topic] ([count] learnings)

### 📝 Summary
[3-5 sentence narrative]

### 🔗 Key Connections
- [Connection 1]
- [Connection 2]
- [Connection 3]

### 📋 All Learnings
• [Title 1] (Mon)
• [Title 2] (Tue)
• [Title 3] (Wed)
...

### 📊 Source Mix
[Source breakdown]
```

## Step 13: File Output

If `--output` is a file path, write the chat format to the specified path.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Graceful Degradation

- **Notion unavailable**: Error at Step 1. Cannot synthesize without database.
- **Empty week**: Friendly message at Step 3. Do not create empty Weekly Insights entry.
- **Single learning**: Full synthesis still runs. Note limited connections.
- **No previous week data**: Skip trend comparison, note absence.
- **First-ever synthesis**: Streak = 1, display "Starting your streak! 🌱".

## Usage Examples

```
/founder-os:learn:weekly
/founder-os:learn:weekly --week=2026-W09
/founder-os:learn:weekly --output=both
/founder-os:learn:weekly --output=./reports/week-10.md
```
