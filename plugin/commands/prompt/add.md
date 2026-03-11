---
description: Add a new prompt to the library with quality checks
argument-hint: "[name] [content] [--category=CAT] [--variables=a,b]"
allowed-tools: ["Read"]
---

# /founder-os:prompt:add

Add a new prompt to the Team Prompt Library with automatic variable detection and a quality check before saving. If the prompt scores below the quality threshold, surface improvement suggestions and ask the user whether to proceed.

## Load Skills

Read both skills before starting any step:

1. `${CLAUDE_PLUGIN_ROOT}/skills/prompt/prompt-management/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/skills/prompt/prompt-optimization/SKILL.md`

Apply prompt-management for database operations, naming conventions, variable detection, and idempotent upsert logic. Apply prompt-optimization for quality scoring and improvement suggestions.

## Parse Arguments

Extract from `$ARGUMENTS`:

- **name** (optional positional) — the prompt's display name. Everything before the first `--` flag that is not the prompt content. If the user provides both a name and content inline, the name is the first quoted string or the first segment before a separator. If no name is provided, infer one from the content and confirm with the user before saving.
- **content** (optional positional) — the full prompt text. May contain `{{variable}}` placeholders. If content is not provided inline, ask the user: "Paste or type the prompt content you want to add." Then wait for input.
- `--category=CAT` (optional) — one of the 6 predefined categories or a custom value. If not provided, detect from content and ask the user to confirm (see Step 3).
- `--variables=a,b` (optional) — explicit variable list override. If provided, use this list instead of auto-detecting from content. Still validate that listed variables appear in the content.

If neither name nor content can be parsed from `$ARGUMENTS`, prompt: "What prompt would you like to add? Provide a name and the prompt text." Then wait for input before continuing.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Step 1: Verify Notion Availability

Check that the Notion MCP server is connected. If Notion is unavailable, display:

```
Error: Notion MCP is required for /founder-os:prompt:add.
See ${CLAUDE_PLUGIN_ROOT}/INSTALL.md for setup instructions.
```

Then stop.

## Step 2: Validate Content

Apply the minimum content guardrail from the prompt-management skill:

- If the content is fewer than 10 characters, display: "Prompt content is too short (fewer than 10 characters). Please provide the full prompt text." Then wait for the user to provide the corrected content before continuing.
- If content is not present after parsing `$ARGUMENTS`, ask: "Paste or type the prompt content you want to add." Then wait.

## Step 3: Resolve Category

If `--category` was provided, use it directly. Notify the user if a custom (non-predefined) category will be created.

If `--category` was not provided:

1. Infer the most likely category from the prompt content using the category inference rules in the prompt-management skill.
2. Ask the user via AskUserQuestion: "What category should this prompt be filed under? I'd suggest **[inferred category]** based on the content. Options: Email Templates, Meeting Prompts, Analysis Prompts, Content Creation, Code Assistance, Research Prompts — or type a custom category." Wait for their response.
3. Use the user's answer. If the user confirms the inferred category, proceed with it.

## Step 4: Auto-Detect Variables

Apply the variable detection regex from the prompt-management skill to the content:

```
\{\{([a-zA-Z_][a-zA-Z0-9_]*)\}\}
```

1. Extract all unique variable names (case-insensitive deduplication).
2. If `--variables=a,b` was provided, use the explicit list instead, but verify each listed variable appears in the content. Warn about any listed variable not found in the content.
3. Store the final variable list as a comma-separated string for the `Variables` property. If no variables are found, store an empty string.

Display the detected variables to the user as part of the quality check output in Step 5 (not as a separate message).

## Step 5: Quality Check

Run the full quality scoring pipeline from the prompt-optimization skill on the prompt content:

1. Score all five dimensions (Task Clarity, Context Provided, Output Format, Constraints, Example Included) on a 1–5 scale.
2. Compute the total score (max 25) and classify into a quality tier.
3. Run anti-pattern detection against the content.

**Scoring thresholds determine the next action:**

### Score 16–25 (Good or Excellent)

Display a brief quality summary:

```
Quality Check: [total]/25 — [Quality Tier]
  Task Clarity: [n]/5  |  Context: [n]/5  |  Format: [n]/5  |  Constraints: [n]/5  |  Example: [n]/5
```

If any top issue exists (score 16–20), append: "Optional improvement: [top issue and one-sentence fix]."

Proceed directly to Step 6 without asking the user for confirmation.

### Score 11–15 (Fair)

Display the full quality report:

```
Quality Check: [total]/25 — Fair

DIMENSION SCORES:
- Task Clarity:       [score]/5
- Context Provided:   [score]/5
- Output Format:      [score]/5
- Constraints:        [score]/5
- Example Included:   [score]/5

ANTI-PATTERNS DETECTED:
- [Anti-pattern name]: [one-line explanation]

TOP ISSUES:
1. [Highest-impact issue]: [Concrete fix in one sentence]
2. [Second issue]: [Concrete fix]
3. [Third issue, if applicable]: [Concrete fix]
```

Then ask via AskUserQuestion: "This prompt scored [total]/25 (Fair). Would you like to (1) save it as-is, (2) edit the content now, or (3) cancel?" Wait for the user's response.

- If the user chooses to save as-is, proceed to Step 6.
- If the user chooses to edit, display the current content and ask: "Paste the updated prompt content." Wait for new content, then re-run Steps 4 and 5 on the updated content before proceeding.
- If the user cancels, display: "Add cancelled. Run /founder-os:prompt:add again when ready." Then stop.

### Score 6–10 (Poor)

Display the full quality report (same format as Fair above) and strongly recommend a rewrite:

```
This prompt scored [total]/25 (Poor). Saving it as-is is likely to produce inconsistent results.

Suggested next step: Run /founder-os:prompt:optimize "[name]" to get an improved version, then re-add.
```

Then ask via AskUserQuestion: "Would you like to (1) save it as-is anyway, (2) edit the content now, or (3) cancel and optimize first?" Wait for the user's response and act accordingly (same branching as Fair tier above).

### Score 5 (Unusable — all dimensions scored 1)

Display:

```
Quality Check: 5/25 — Unusable

This prompt could not be meaningfully scored. The content may be too vague, too short, or missing a task statement entirely.

Please revise the content before saving.
```

Ask via AskUserQuestion: "Paste the revised prompt content, or type 'cancel' to stop." Wait for response. If the user provides new content, re-run from Step 4. If the user types "cancel", stop.

## Step 6: Resolve Name

If a name was parsed from `$ARGUMENTS`, use it.

If no name was provided:

1. Infer a name from the first sentence or purpose of the prompt content using the naming conventions in the prompt-management skill.
2. Ask via AskUserQuestion: "I'll save this prompt as **[inferred name]**. Is that right, or would you like a different name?" Wait for the user's response.
3. Use the confirmed or user-provided name.

Check for duplicate names using the idempotent upsert rule from the prompt-management skill (case-insensitive match against existing database records). If a duplicate is found, present the existing prompt and ask via AskUserQuestion: "A prompt named '[name]' already exists. Would you like to (1) overwrite it with this new content, (2) save under a different name, or (3) cancel?" Wait and act on the response.

## Step 7: Save to Notion

### Locate the Database

Search the Notion workspace for a database named "[FOS] Prompts". If not found, try "Founder OS HQ - Prompts". If not found, fall back to "Team Prompt Library - Prompts".

If none is found, report: "Prompts database not found. Ensure the Founder OS HQ workspace template is installed in your Notion workspace." Then stop.

The database should have the following schema:

| Property | Type |
|----------|------|
| Name | title |
| Content | rich_text |
| Category | select |
| Variables | rich_text |
| Visibility | select |
| Times Used | number |
| Author | rich_text |
| Tags | multi_select |
| Created At | date |
| Last Used | date |

### Create the Page

Create a new Notion page in the database with these property values:

- **Name**: the resolved prompt name
- **Content**: the full prompt text (with `{{variables}}` intact)
- **Category**: the resolved category
- **Variables**: comma-separated detected variable names (or empty string)
- **Visibility**: `Personal` (default — never set to Shared on add unless the user explicitly requested it)
- **Times Used**: `0`
- **Author**: leave blank (the user may fill this in manually)
- **Tags**: empty (the user may add tags later via the Notion page)
- **Created At**: current date and time in ISO 8601 format
- **Last Used**: empty

If the content exceeds 2000 characters, split across multiple rich_text blocks or warn the user that the prompt may be truncated and suggest shortening it.

## Step 8: Confirm Save

Display the confirmation block:

```
Prompt added to your Team Prompt Library.

  Name:       [prompt name]
  Category:   [category]
  Variables:  [list of {{variables}}, or "none detected"]
  Visibility: Personal
  Quality:    [total]/25 — [Quality Tier]

To retrieve this prompt: /founder-os:prompt:get "[name]"
To share with your team: /founder-os:prompt:share "[name]"
To optimize it:          /founder-os:prompt:optimize "[name]"
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Graceful Degradation

- **Notion unavailable**: Show error at Step 1 with INSTALL.md reference. Do not attempt to cache or save locally.
- **Content too short**: Reject with clear message at Step 2. Ask for the full prompt text.
- **Category ambiguous**: Always ask the user rather than defaulting silently (see Step 3).
- **Duplicate name**: Always surface the conflict and ask — never silently overwrite (see Step 6).
- **Content over 2000 characters**: Warn the user and offer to proceed with truncation or suggest shortening before saving.
- **Quality check failure (score 5)**: Block save and require revised content. Do not allow a score-5 prompt to be saved without user explicitly overriding after editing.

## Usage Examples

```
/founder-os:prompt:add "Client Intro Email" "Write a warm introduction email to {{client_name}} at {{company_name}}. Introduce our agency, mention our work in {{industry}}, and propose a 30-minute call. Keep it under 150 words and end with a soft CTA." --category="Email Templates"
/founder-os:prompt:add --category="Analysis Prompts"
/founder-os:prompt:add "Weekly Status Update" "Summarize this week's progress on {{project_name}} for {{audience}}. Include: what was completed, what is in progress, and any blockers. Format as 3 short sections with bullet points. Keep the total under 200 words."
/founder-os:prompt:add "Competitor Analysis Brief" "{{competitor_name}} analysis: list their top 3 strengths, top 3 weaknesses, and one strategic threat to us. Use bullet points. Base your response only on publicly available information." --category="Research Prompts" --variables=competitor_name
```
