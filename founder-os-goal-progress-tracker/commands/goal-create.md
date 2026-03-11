---
description: Create a new goal with optional milestones and deadline
argument-hint: "[goal name] [--target=YYYY-MM-DD] [--category=CAT] [--milestones=M1,M2,M3]"
allowed-tools: ["Read"]
---

# /goal:create

Create a new goal with optional target date, category, and milestones. Save to the Goal Progress Tracker Notion database.

## Load Skills

Read the goal-tracking skill before starting any step:

1. `${CLAUDE_PLUGIN_ROOT}/skills/goal-tracking/SKILL.md`

Apply goal-tracking for all database operations, category detection, naming conventions, progress tracking, RAG status rules, and milestone management.

## Parse Arguments

Extract from `$ARGUMENTS`:

- **goal name** (required positional) — the full goal description. Everything that is not a `--` flag. If no goal name is provided, ask: "What goal would you like to create? Describe it in a short phrase." Then wait for input.
- `--target=YYYY-MM-DD` (optional) — Target Date for the goal. Validate date format (must be valid YYYY-MM-DD).
- `--category=CAT` (optional) — one of: Revenue, Product, Operations, Team, Personal, Technical, Marketing, Other. Case-insensitive. If not provided, auto-detect from goal name using the category taxonomy signals in the goal-tracking skill.
- `--milestones=M1,M2,M3` (optional) — comma-separated milestone names. Creates milestone entries linked to this goal.

If `$ARGUMENTS` is empty, prompt: "What goal would you like to create? Describe it in a short phrase." Then wait for input before continuing.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Step 1: Verify Notion Availability

Check that the Notion MCP server is connected. If Notion is unavailable, display the goal in chat format so the user can log it manually later, then stop. Display:

```
⚠️ Notion is not available. Here's your goal for manual logging:

🎯 Goal: [goal name]
📂 Category: [detected/specified category]
📅 Target: [YYYY-MM-DD or "No deadline"]
🏁 Milestones: [comma-separated list or "None"]

Reconnect Notion and run /goal:create again to save.
```

## Step 2: Validate Input

Apply input validation:

- If goal name is fewer than 3 characters, display: "Goal name is too short (minimum 3 characters). Please provide a more descriptive goal." Then wait for revised input.
- If goal name exceeds 200 characters, display: "Goal name exceeds 200 characters. Please shorten it." Then wait for revised input.
- If `--target` is provided, validate it is a valid date in YYYY-MM-DD format. If the date is in the past, display a warning: "⚠️ Target date [YYYY-MM-DD] is in the past. Proceeding anyway." Continue without blocking.
- If `--target` is provided but the format is invalid, display: "Invalid date format. Please use YYYY-MM-DD (e.g., 2026-06-30)." Then wait for revised input.

## Step 3: Locate Goals Database

Follow the database discovery protocol from the goal-tracking skill:

1. Search the Notion workspace for a database titled "[FOS] Goals". If not found, try "Founder OS HQ - Goals". If not found, fall back to "Goal Progress Tracker - Goals".
2. If found, use it.
3. If none is found, report: "Goals database not found. Ensure the Founder OS HQ workspace template is installed in your Notion workspace." Then stop.

## Step 4: Check for Duplicates

Search the discovered Goals database for an existing goal where:
- `Title` matches the goal name (case-insensitive)

If a duplicate exists, present the existing goal's Status and Progress, then ask: "A goal with this name already exists: '[existing title]' (Status: [status], Progress: [N]%). Would you like to (1) update it, (2) save under a different name, or (3) cancel?" Wait for response.

## Step 5: Detect Category

If `--category` was provided, use it directly (case-insensitive match to one of the 8 categories).

If `--category` was not provided, auto-detect from the goal name using the category taxonomy signals in the goal-tracking skill. When detection is ambiguous, default to `Other`.

## Step 6: Create Goal Page

Create a new Notion page in the discovered Goals database with these property values:

- **Title**: goal name (apply naming conventions from the goal-tracking skill)
- **Description**: empty (user can add later via /goal:update)
- **Status**: "Not Started" (select)
- **Progress**: 0 (number)
- **Target Date**: `--target` value or empty (date)
- **Start Date**: empty (set on first progress update)
- **Category**: detected or specified category (select)
- **RAG Status**: "Not Started" (select)
- **Progress Snapshots**: `[{"date":"YYYY-MM-DD","progress":0}]` (rich_text, using today's date)
- **Notes**: `[YYYY-MM-DD] Goal created.` (rich_text, using today's date)
- **Created At**: current date and time in ISO 8601 (date)

## Step 7: Create Milestones

Skip this step if `--milestones` was not provided.

If `--milestones` was provided:

1. Locate the milestones database following the database discovery protocol from the goal-tracking skill. Search for "[FOS] Milestones" first, try "Founder OS HQ - Milestones", fall back to "Goal Progress Tracker - Milestones". If none is found, report: "Milestones database not found. Ensure the Founder OS HQ workspace template is installed in your Notion workspace." Then stop.
2. Split the `--milestones` value by commas. Trim whitespace from each milestone name.
3. For each milestone, create a Notion page with:
   - **Title**: milestone name
   - **Goal**: relation to the goal page created in Step 6
   - **Status**: "Not Started" (select)
   - **Order**: sequential 1-based integer (1, 2, 3, ...)
4. After all milestones are created, update the Goal page:
   - **Milestone Count**: total number of milestones created (number)
   - **Completed Milestones**: 0 (number)

## Step 8: Display Confirmation

Display the confirmation:

```
✅ Goal created!

🎯 [Goal Name]
📂 Category: [Category]
📅 Target: [YYYY-MM-DD or "No deadline set"]
📊 Progress: ░░░░░░░░░░ 0%

🏁 Milestones: [N milestones created]
  1. [Milestone 1]
  2. [Milestone 2]
  3. [Milestone 3]

Use /goal:update to log progress | /goal:check for status
```

If no milestones were created, replace the Milestones section with:
```
🏁 Milestones: None — track progress manually with /goal:update
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Graceful Degradation

- **Notion unavailable**: Display goal in chat format at Step 1. Do not discard.
- **Input too short/long**: Reject with clear message at Step 2. Ask for revision.
- **Duplicate found**: Surface conflict at Step 4. Never silently overwrite.
- **Invalid date**: Reject with clear format message. Ask for revision.
- **Category ambiguous**: Default to Other. Note assumption.
- **Milestone creation partial failure**: Log successfully created milestones, report which failed, update Milestone Count with actual count.
- **No arguments**: Interactive prompting for goal name.

## Usage Examples

```
/goal:create "Launch MVP by end of Q2" --target=2026-06-30 --category=Product --milestones="Design mockups,Build prototype,User testing,Ship v1"
/goal:create "Reach $50K MRR" --target=2026-12-31 --category=Revenue
/goal:create "Hire senior engineer" --category=Team
/goal:create
```
