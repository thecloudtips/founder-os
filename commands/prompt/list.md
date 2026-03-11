---
description: List and search prompts from your team library
argument-hint: "[category] [--search=keyword] [--limit=N]"
allowed-tools: ["Read"]
---

# /founder-os:prompt:list

List and search prompts from the team prompt library, filtered by category or keyword.

## Load Skills

Read the prompt-management skill at `${CLAUDE_PLUGIN_ROOT}/skills/prompt/prompt-management/SKILL.md` before proceeding.

## Parse Arguments

Extract from `$ARGUMENTS`:
- **category** (optional positional): Filter by prompt category (e.g., `sales`, `support`, `writing`)
- **--search=keyword** (optional): Filter prompts whose name, description, or tags contain the keyword
- **--limit=N** (optional): Maximum number of results to display (default: 20)

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Step 1: Verify Notion Availability

Check that the Notion MCP server is connected. If Notion is unavailable, display:

```
Error: Notion MCP is required for /founder-os:prompt:list.
See ${CLAUDE_PLUGIN_ROOT}/INSTALL.md for setup instructions.
```

Then stop.

## Step 2: Locate the Team Prompt Library Database

Search the user's Notion workspace for a database named "[FOS] Prompts". If not found, try "Founder OS HQ - Prompts". If not found, fall back to "Team Prompt Library - Prompts".

If neither database exists, display:

```
Your Team Prompt Library is empty — no prompts have been added yet.

Get started with:
  /founder-os:prompt:add "My First Prompt" [prompt-text] --category="Email Templates"
```

Then stop.

## Step 3: Query Prompts

Query the discovered prompts database with the following filters applied in combination:

1. If **category** was provided: filter where Category property equals the given category (case-insensitive match).
2. If **--search** was provided: filter where Name, Description, or Tags contain the keyword (use Notion text search across these fields).
3. Apply **--limit** (default 20) to cap the number of results returned.

Sort results by Times Used descending, then by Name ascending as a tiebreaker.

## Step 4: Display Results

If no prompts match the filters, display:

```
No prompts found matching your criteria.

Try:
  /founder-os:prompt:list                  (show all prompts)
  /founder-os:prompt:list --search=email   (search by keyword)
```

If prompts are found, display a formatted table:

```
Team Prompt Library  (showing X of Y total)

Name                     Category     Visibility   Times Used
─────────────────────────────────────────────────────────────
Cold Outreach Opener     sales        team         42
Weekly Status Update     writing      personal     17
Support Escalation       support      team         9
...

Filter: category=sales, search="email", limit=20
```

Column definitions:
- **Name**: The prompt name/title
- **Category**: The prompt category tag
- **Visibility**: `team` (shared) or `personal` (private)
- **Times Used**: Usage count from the Times Used property

If no filters were applied, omit the Filter line at the bottom.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Graceful Degradation

- **Notion unavailable**: Show error message with INSTALL.md reference (see Step 1).
- **Database missing**: Show empty library message with onboarding hint (see Step 2).
- **No results for filters**: Show "no prompts found" message with alternative suggestions (see Step 4).
- **Category property missing on some records**: Display those records with a blank Category column rather than omitting them.
- **Times Used missing**: Display `—` in the Times Used column for those records.

## Usage Examples

```
/founder-os:prompt:list
/founder-os:prompt:list sales
/founder-os:prompt:list --search=email
/founder-os:prompt:list --search=onboarding --limit=5
/founder-os:prompt:list support --limit=10
/founder-os:prompt:list writing --search=newsletter
```
