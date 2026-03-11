---
description: Extract action items from pasted text and create Notion tasks
argument-hint: "[paste text or meeting notes]"
allowed-tools: ["Read"]
---

# Extract Action Items from Text

Extract structured action items from pasted text (meeting transcripts, email threads, or documents) and create Notion tasks automatically.

## Load Skill

Read the action-extraction skill at `${CLAUDE_PLUGIN_ROOT}/skills/actions/action-extraction/SKILL.md` for verb patterns, owner inference rules, deadline parsing, priority scoring, duplicate detection, and Notion task creation procedures.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Parse Input

The user's input is provided in `$ARGUMENTS`. This is the raw text to extract action items from.

If `$ARGUMENTS` is empty or missing:
- Halt with: "No text provided. Paste the content you want to extract action items from, or use `/founder-os:actions:extract-file [path]` to process a file."

## Extraction Process

1. **Detect source type**: Analyze the text to determine if it is a meeting transcript, email thread, document, or other format. Use the source type detection rules from the skill.

2. **Extract source title**: Identify the title or subject of the source content:
   - Meeting transcript: Look for a title line, "Meeting:" header, or subject in metadata
   - Email: Extract the `Subject:` header
   - Document: Use the first heading or first meaningful line
   - If no title found, use "Untitled [Source Type]"

3. **Scan for action items**: Apply the three-pass verb pattern scan from the skill (direct requests, implicit actions, commitment language). For meeting transcripts, also apply transcript-specific patterns.

4. **Build action items**: For each detected action, construct the full action item structure per the skill: title (verb-first, max 80 chars), description, owner (using inference rules), deadline (using parsing rules), priority (1-5), source_type, source_title, context.

5. **Deduplicate within batch**: Ensure no two action items from the same source have identical titles. Disambiguate by adding specificity from the text.

## Notion Integration

1. **Database discovery**: Search Notion for a database named "[FOS] Tasks". If not found, try "Founder OS HQ - Tasks". If not found, fall back to "Action Item Extractor - Tasks". If none exists, use graceful degradation (below). Do NOT create the database.
2. **Duplicate detection**: For each action item, query the database for tasks with similar titles created within the past 14 days, **filtered by `Type = "Action Item"`**. Apply the duplicate detection rules from the skill (verb+noun matching). Skip duplicates, cross-reference near-duplicates.
3. **Create tasks**: Create a Notion page for each new action item with all properties populated:
   - `Type` = "Action Item"
   - `Source Plugin` = "Action Extractor"
   - Title, Description, Owner, Deadline, Priority, Status ("To Do"), Source Type, Source Title, Extracted At (now)
   - `Company` / `Contact` relations when owner matches a CRM contact (see skill for matching rules)

## Graceful Degradation

If Notion MCP is unavailable or any Notion operation fails:
- Output all extracted action items as structured text in chat
- Format each item clearly with all fields (title, description, owner, deadline, priority, source type, source title)
- Warn: "Notion unavailable — displaying results in chat. Tasks were not saved to Notion. Configure Notion MCP per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`."

## Output Format

After processing, display results:

```
## Action Items Extracted

**Source**: [source_title] ([source_type])
**Items found**: [count]
**Created in Notion**: [count] new | [count] duplicates skipped

---

| # | Action Item | Owner | Deadline | Priority | Status |
|---|-------------|-------|----------|----------|--------|
| 1 | [title] | [owner] | [deadline or "—"] | [priority]/5 | [Created ✓ / Duplicate ⚠️] |
| 2 | ... | ... | ... | ... | ... |

[For each created task, include the Notion page link]
```

If no action items were found:
- Display: "No action items detected in the provided text. The text may not contain actionable requests, tasks, or commitments."

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/founder-os:actions:extract Meeting notes from standup: John will review the API spec by Friday. Sarah to update the deployment docs. AI: Schedule follow-up meeting for next week.

/founder-os:actions:extract From: alice@example.com Subject: Q4 Planning Hi team, please review the attached budget by EOD Thursday. Bob, can you prepare the slide deck for Monday's presentation?

/founder-os:actions:extract Next steps from project kickoff: 1. Draft project charter - Mike, by Jan 15 2. Set up development environment - Dev team, this week 3. Schedule stakeholder interviews - PM, ASAP
```
