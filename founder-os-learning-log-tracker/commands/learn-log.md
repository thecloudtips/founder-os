---
description: Capture a learning insight with auto-tagging and related insights
argument-hint: "[insight text] [--source=experience|reading|conversation|experiment|observation] [--context=additional context] [--company=NAME]"
allowed-tools: ["Read"]
---

# /learn:log

Capture a daily learning with auto-generated title, topic detection, source classification, and related past insight linking. Save to the Learning Log Tracker Notion database.

## Load Skills

Read the learning-capture skill before starting any step:

1. `${CLAUDE_PLUGIN_ROOT}/skills/learning-capture/SKILL.md`

Apply learning-capture for all database operations, title generation, topic detection, source classification, related insights, and guardrails.

## Parse Arguments

Extract from `$ARGUMENTS`:

- **insight** (required positional) — the full learning text. Everything that is not a `--` flag. If no insight text is provided, ask: "What did you learn? Describe your insight, observation, or takeaway." Then wait for input.
- `--source=TYPE` (optional) — one of: experience, reading, conversation, experiment, observation. Case-insensitive. If not provided, auto-detect from insight text using the source type detection rules in the learning-capture skill.
- `--context=TEXT` (optional) — additional context such as project name, meeting reference, or situation. Stored in the Context property.
- `--company=NAME` (optional) — explicitly associate this learning with a client company. The value should match a company name in [FOS] Companies.

If `$ARGUMENTS` is empty, prompt: "What did you learn today? Share an insight, observation, or takeaway." Then wait for input before continuing.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Step 1: Verify Notion Availability

Check that the Notion MCP server is connected. If Notion is unavailable, display the learning in chat format (title, topics, source) so the user can log it manually later, then stop. Display:

```
⚠️ Notion is not available. Here's your learning for manual logging:

Title: [auto-generated title]
Topics: [detected topics]
Source: [source type]
Insight: [full text]

Reconnect Notion and run /learn:log again to save.
```

## Step 2: Validate Input

Apply the capture guardrails from the learning-capture skill:

- If insight text is fewer than 15 characters, display: "Learning is too short (minimum 15 characters). Please share a more complete insight." Then wait for revised input.
- If insight text exceeds 2000 characters, display: "Learning text exceeds 2000 characters. Please shorten it or split into multiple learnings." Then wait for revised input.

## Step 3: Detect Source Type

If `--source` was provided, use it directly (case-insensitive match to one of the 5 source types).

If `--source` was not provided, auto-detect from the insight text using the source type inference signals table in the learning-capture skill. When inference is ambiguous, default to `Experience`.

## Step 4: Auto-Detect Topics

Run the topic detection algorithm from the learning-capture skill:

1. Read `${CLAUDE_PLUGIN_ROOT}/skills/learning-capture/references/topic-detection-algorithm.md` for the full algorithm.
2. Match keywords against the 10-category taxonomy.
3. Select 1-3 topics that score above the 2-point threshold.
4. If no topics meet the threshold, apply the source-type fallback rule.

## Step 5: Generate Title

Generate a 5-8 word title from the insight text following the title generation rules in the learning-capture skill:

- Title Case, max 80 characters
- Start with a noun or gerund
- Capture the core takeaway
- Omit articles where possible
- Never start with "I learned" or "Learning about"

## Step 6: Check for Duplicates

Search the discovered learnings database for an entry where:
- `Title` matches the generated title (case-insensitive)
- `Logged At` falls on today's date

If a duplicate exists, present the existing entry and ask: "A similar learning was already logged today: '[existing title]'. Would you like to (1) update it with this new content, (2) save under a different title, or (3) cancel?" Wait for response.

## Step 7: Find Related Insights

Read `${CLAUDE_PLUGIN_ROOT}/skills/learning-capture/references/related-insights-algorithm.md` for the full algorithm.

1. Query the database for entries sharing Topics with the new learning.
2. Score by topic overlap.
3. Select the top 2-3 related insights above the 3.0 threshold.
4. If no related insights found (new database or rare topics), proceed without related links.

## Step 8: Calculate Week

Calculate the ISO week from the current date and format as `YYYY-WNN`.

## Step 8b: Resolve Company

When creating a learning entry in [FOS] Learnings, populate the Company relation if `--company` is provided or if the insight text mentions a known client name:

1. If `--company=NAME` was provided, search [FOS] Companies for a matching company name (case-insensitive). If found, use its page ID for the Company relation.
2. If `--company` was not provided, scan the insight text for mentions of known company names from [FOS] Companies. If a match is found, use its page ID.
3. If no company match is found (or [FOS] Companies is unavailable), leave Company empty and proceed.

## Step 9: Save to Notion

### Locate or Create the Database

Search the Notion workspace for a database named "[FOS] Learnings". If not found, try "Founder OS HQ - Learnings". If not found, fall back to "Learning Log Tracker - Learnings". If none is found, report: "Learnings database not found. Ensure the Founder OS HQ workspace template is installed in your Notion workspace." Then stop.

### Create the Page

Create a new Notion page with these property values:

- **Title**: the generated title
- **Insight**: the full learning text
- **Topics**: detected topic categories (multi_select)
- **Source Type**: detected or specified source type (select)
- **Context**: `--context` value or empty
- **Related IDs**: comma-separated page IDs of related insights (or empty)
- **Related Titles**: comma-separated titles of related insights (or empty)
- **Week**: ISO week identifier (e.g., `2026-W10`)
- **Logged At**: current date and time in ISO 8601
- **Company**: resolved company relation page ID (or empty if no match)

## Step 10: Display Confirmation

Display the confirmation with related insights:

```
✅ Learning captured!

📝 [Title]
🏷️ Topics: [Topic1], [Topic2]
📖 Source: [Source Type]
📅 Week: [YYYY-WNN]

🔗 Related Insights:
  • [Related Title 1]
  • [Related Title 2]
  • [Related Title 3]

Use /learn:search to find past learnings | /learn:weekly for your weekly summary
```

If no related insights were found, replace the Related Insights section with:
```
🔗 No related past insights found yet. Keep logging — connections build over time!
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Graceful Degradation

- **Notion unavailable**: Display learning in chat format at Step 1. Do not discard.
- **Input too short/long**: Reject with clear message at Step 2. Ask for revision.
- **No topic matches**: Apply source-type fallback. Note assumption.
- **Duplicate detected**: Surface conflict at Step 6. Never silently overwrite.
- **No related insights**: Skip related section, display encouragement message.
- **Empty database**: First learning — skip related insights, note "First entry in your learning log!"

## Usage Examples

```
/learn:log "Discovered that batch processing Notion API calls with 10-item chunks reduces rate limit errors by 90%"
/learn:log "Had a great conversation with Alex about how weekly retros improve team velocity when done right" --source=conversation
/learn:log "Reading about the PARA method changed how I think about organizing project notes" --source=reading --context="Tiago Forte's book"
/learn:log "Acme Corp's onboarding process taught me that early kickoff meetings reduce churn" --company="Acme Corp"
/learn:log
```
