---
description: Improve an existing prompt using AI optimization
argument-hint: "[name]"
allowed-tools: ["Read"]
---

# /founder-os:prompt:optimize

Retrieve a saved prompt from the Team Prompt Library, score it on five quality dimensions, apply targeted rewrite strategies to produce an improved version, and — with user confirmation — save the improved prompt back to Notion. All `{{variable}}` placeholders are preserved exactly as-is throughout the process.

## Load Skills

Read the prompt-management skill at `${CLAUDE_PLUGIN_ROOT}/skills/prompt/prompt-management/SKILL.md` for Notion DB discovery, prompt lookup logic, idempotent upsert rules, and variable detection conventions.

Read the prompt-optimization skill at `${CLAUDE_PLUGIN_ROOT}/skills/prompt/prompt-optimization/SKILL.md` for the five-dimension quality scoring system, anti-pattern detection rules, rewrite strategies, and the improvement suggestions output format.

## Parse Arguments

Extract from `$ARGUMENTS`:
- **[name]** (required positional) — The name of the prompt to optimize. If not provided, ask the user: "Which prompt would you like to optimize? Please provide the prompt name."

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Step 1: Verify Notion Availability

Check that the Notion MCP server is connected. If Notion is unavailable, display:

```
Error: Notion MCP is required for /founder-os:prompt:optimize.
See ${CLAUDE_PLUGIN_ROOT}/INSTALL.md for setup instructions.
```

Then stop.

## Step 2: Locate the Team Prompt Library Database

Search the user's Notion workspace for a database named "[FOS] Prompts". If not found, try "Founder OS HQ - Prompts". If not found, fall back to "Team Prompt Library - Prompts", using the discovery logic from the prompt-management skill.

If neither database exists, display:

```
Your Team Prompt Library is empty — no prompts have been saved yet.

Get started with:
  /founder-os:prompt:add [prompt-text] --name="My First Prompt" --category=general
```

Then stop.

## Step 3: Retrieve the Prompt

Search the discovered prompts database for a page whose `Name` property matches the provided name (case-insensitive exact match first).

If no exact match is found:
- Search for pages where the `Name` contains any word from the provided name
- Present up to 3 similar matches: "Could not find '[name]'. Did you mean one of these? [numbered list with category and Created At]"
- If no similar matches exist, inform the user: "No prompt named '[name]' was found in the library." Then stop.

Once the prompt is located, read the following properties:
- **Name**: prompt title
- **Content**: full prompt text (preserve all `{{variable}}` placeholders verbatim)
- **Category**: prompt category
- **Variables**: existing detected variables list
- **Visibility**: Personal or Shared

Do not increment `Times Used` — this is an optimization operation, not a retrieval for use.

## Step 4: Score the Current Prompt

Apply the quality scoring system from the prompt-optimization skill. Score the retrieved `Content` across all five dimensions:

1. **Task Clarity** (1–5)
2. **Context Provided** (1–5)
3. **Output Format Specified** (1–5)
4. **Constraints Defined** (1–5)
5. **Example Included** (1–5)

Compute the total score (max 25) and classify it into a quality tier (Excellent / Good / Fair / Poor / Unusable).

Run anti-pattern detection against the full prompt text. Flag every anti-pattern found.

If the prompt scores 21–25 (Excellent), present the score and inform the user:

```
Quality Score: [total]/25 — Excellent

This prompt is already high quality. Optimization may offer only minor improvements.

Would you like to proceed with a rewrite anyway? (Yes / No)
```

If the user declines, stop here.

## Step 5: Produce the Rewritten Prompt

Using the prompt-optimization skill, select up to 3 rewrite strategies that address the lowest-scoring dimensions and any detected anti-patterns. Apply them to produce a complete rewritten version of the prompt.

Rewrite rules:
- Preserve the original intent exactly. Do not change the meaning or purpose of the prompt.
- Preserve every `{{variable}}` placeholder verbatim — do not rename, remove, or add variables that the user did not intend.
- If the original prompt contains a factual error or suspicious instruction (e.g., "write a 10,000-word summary"), flag it as a note rather than silently correcting it.
- Produce rewrites in the same language as the original prompt.

## Step 6: Present Side-by-Side Comparison

Display the original and improved prompts side by side with the full improvement report:

```
## Prompt Optimization: [Prompt Name]

### Original Prompt
─────────────────────────────────────────────
[full original prompt text]
─────────────────────────────────────────────

### Quality Score: [total]/25 — [Quality Tier]

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

### Improved Prompt
─────────────────────────────────────────────
[full rewritten prompt text]
─────────────────────────────────────────────

CHANGES MADE:
- [Change 1]: [Why this improves the prompt]
- [Change 2]: [Why this improves the prompt]
- [Change 3, if applicable]: [Why this improves the prompt]

VARIABLES PRESERVED: {{var1}}, {{var2}}  (or "None detected" if no variables)
```

## Step 7: Confirm Action

Use AskUserQuestion to present the user with three options:

"How would you like to proceed?

1. Keep Original — discard the improved version, no changes saved
2. Use Improved — save the improved prompt to the library, replacing the current content
3. Edit Further — paste your edited version and I will save that instead"

Handle each response:

- **Keep Original**: Inform the user: "No changes made. The original prompt '[name]' is unchanged in the library." Then stop.

- **Use Improved**: Proceed to Step 8 with the rewritten prompt as the content to save.

- **Edit Further**: Ask the user to paste their edited prompt text. Accept the pasted text as the final content to save. Re-run variable detection on the pasted text before saving. Then proceed to Step 8.

## Step 8: Update Notion

Save the accepted content back to the discovered prompts database using the idempotent upsert rule from the prompt-management skill:

1. Locate the existing page by `Name` (case-insensitive match — the same page retrieved in Step 3).
2. Update the following properties only:
   - **Content**: the accepted prompt text (improved or user-edited)
   - **Variables**: re-run variable detection regex on the new content; overwrite the existing Variables value with the updated comma-separated list
3. Do not modify `Name`, `Category`, `Visibility`, `Times Used`, `Author`, `Tags`, `Created At`, or `Last Used`.

Display a confirmation:

```
Prompt updated successfully.

Name: [Prompt Name]
Category: [Category]
Variables: [updated variable list, or "None"]
Saved to: [FOS] Prompts (Notion)
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Graceful Degradation

- **Notion unavailable**: Show error with INSTALL.md reference at Step 1. Do not proceed.
- **Database missing**: Show onboarding hint at Step 2. Do not proceed.
- **Prompt not found**: Show fuzzy match suggestions at Step 3. Do not fabricate prompt content.
- **Prompt scores Excellent (21–25)**: Notify the user and ask whether to proceed before running the rewrite (Step 4).
- **No anti-patterns detected**: Omit the ANTI-PATTERNS DETECTED section from the report entirely. Do not display an empty section.
- **User selects Edit Further but pastes empty text**: Ask again: "The text appears to be empty. Please paste your edited prompt, or type 'cancel' to discard changes."
- **Notion update fails at Step 8**: Report the error and display the accepted prompt text in chat so the user can copy it manually.

## Usage Examples

```
/founder-os:prompt:optimize "Cold Outreach Opener"
/founder-os:prompt:optimize "Weekly Status Update"
/founder-os:prompt:optimize client-intro-email
/founder-os:prompt:optimize "Competitor Analysis Brief"
```
