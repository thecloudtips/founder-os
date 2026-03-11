---
description: Share a prompt with your team
argument-hint: "[name]"
allowed-tools: ["Read"]
---

# /prompt:share

Share a prompt with your team by updating its Visibility from Personal to Shared in the Notion prompt library.

## Load Skills

Load the prompt-management skill from `${CLAUDE_PLUGIN_ROOT}/skills/prompt-management/SKILL.md` for Notion DB discovery and prompt lookup logic.

## Parse Arguments

Extract the prompt name from the argument. If no argument is provided, ask the user: "Which prompt would you like to share? Please provide the prompt name."

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Steps

1. **Discover the Notion DB** — Use the prompt-management skill to locate the prompts database. Search for "[FOS] Prompts" first. If not found, try "Founder OS HQ - Prompts". If not found, fall back to "Team Prompt Library - Prompts". If none is found, inform the user that the prompt library has not been set up yet and suggest running `/prompt:add` first.

2. **Find the prompt** — Search the database for a page where the Name property matches the provided name (case-insensitive). If no exact match is found:
   - Search for pages where the Name contains any word from the provided name
   - Present up to 3 similar matches to the user: "Could not find '[name]'. Did you mean one of these? [list]"
   - If no similar matches exist, inform the user: "No prompt named '[name]' was found in the library."

3. **Check current Visibility** — Read the Visibility property of the matched prompt page.
   - If Visibility is already "Shared", inform the user: "The prompt '[name]' is already shared with your team. No changes made."
   - Stop here.

4. **Update Visibility** — Update the Visibility property from "Personal" to "Shared" on the matched prompt page.

5. **Confirm change** — Report success to the user:
   ```
   Prompt shared successfully.

   Name: [prompt name]
   Visibility: Personal → Shared

   Your team can now find this prompt using /prompt:list or /prompt:get.
   ```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Graceful Degradation

- **Notion unavailable**: Inform the user that Notion MCP is required for this command and cannot proceed without it.
- **Multiple exact matches**: Present all matches with their tags and creation dates so the user can clarify which one to share.
- **Update fails**: Report the error and suggest the user check their Notion permissions.

## Usage Examples

```
/prompt:share "Weekly Status Update"
/prompt:share cold-email-opener
/prompt:share "Client Onboarding Welcome"
```
