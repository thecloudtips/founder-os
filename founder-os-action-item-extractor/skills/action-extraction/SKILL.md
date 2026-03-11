---
name: Action Extraction
description: "Converts meeting transcripts, email threads, and documents into structured Notion tasks. Activates when the user pastes text and wants action items extracted, asks 'what tasks are in this?', or needs to parse any content for to-dos, assignments, and commitments. Handles verb detection, owner inference, deadline parsing, and duplicate checking against HQ Tasks."
globs:
  - "commands/actions-extract.md"
  - "commands/actions-extract-file.md"
---

## Overview

Analyze text content from meeting transcripts, email threads, or documents to extract structured action items. Convert every detected action into a task containing a title, description, owner, deadline, priority, source type, and source title. Process the text systematically: detect the source type, scan for actionable verb patterns, infer ownership, parse deadlines, assign priority, and check for duplicates before creating Notion tasks.

## Source Type Detection

Identify the source type from content patterns before extraction begins:

**Meeting Transcript** — Contains speaker labels (`Speaker 1:`, `John:`), timestamps (`[00:15:30]`), turn-taking patterns, or keywords like "meeting notes", "transcript", "minutes". Look for action-assignment patterns: "AI:", "Action Item:", "Next steps:", "[Name] to...", "[Name] will...".

**Email** — Contains header patterns (`From:`, `To:`, `Subject:`, `Date:`), forwarding markers (`---------- Forwarded message ----------`), reply chains (`On [date], [person] wrote:`), or signature blocks. Process the most recent message first; earlier messages may contain resolved items.

**Document** — General text without transcript or email markers. May contain structured lists, headings, bullet points, or task-oriented sections. Treat any actionable language as a candidate.

**Other** — When no clear pattern matches, default to "Other" and apply general extraction rules.

## Actionable Verb Patterns

Scan text in three passes — one per category — and collect all matches before deduplicating.

### Direct Requests (Highest Signal)

Strong indicators of an action item. Extract immediately upon detection:

- "Review [X]", "Approve [X]", "Sign [document]"
- "Send [item] to [person]", "Forward [X] to [recipient]"
- "Schedule [meeting/call]", "Set up [X]", "Book [time/room]"
- "Complete [task]", "Finish [item]", "Submit [deliverable]"
- "Update [document/status]", "Revise [item]", "Edit [document]"
- "Pay [invoice/bill]", "Process [payment/expense]"
- "Create [document/report/plan]", "Draft [response/proposal]"
- "Confirm [attendance/details]", "Verify [information]"
- "Share [document/access] with [person]", "Grant [permission]"
- "Cancel [meeting/subscription]", "Remove [item/access]"

### Implicit Actions (Medium Signal)

Polite or indirect phrasing concealing genuine requests. Convert to an explicit action verb:

- "Can you...?", "Could you...?", "Would you mind...?" — extract the verb following the modal.
- "Please [verb]...", "Kindly [verb]..." — extract the verb directly.
- "I need you to...", "We need...", "It would be great if..." — extract the clause following the setup phrase.
- "Let me know about...", "Get back to me on..." — convert to "Respond about [topic]" or "Provide update on [topic]".
- "Any thoughts on...?" — convert to "Review and provide feedback on [topic]".

When an implicit action lacks a clear verb, default to "Follow up on [topic]".

### Commitment Language (Self-Assigned Actions)

Promises or commitments that represent obligations:

- "I will...", "I'll...", "I can...", "I'm going to..."
- "Let me...", "Allow me to..."
- "I'll follow up on...", "I'll get back to you about..."
- "Consider it done", "I'm on it" — extract the referenced task from surrounding context.

### Transcript-Specific Patterns

For meeting transcripts, also detect:

- "AI:" or "Action Item:" prefixes followed by task descriptions
- "[Name] to [verb]..." or "[Name] will [verb]..." delegation patterns
- "Next steps:" sections — treat each bullet/item as a separate action
- "Takeaway:" or "Follow-up:" markers
- "[Name], can you take [task]?" — explicit delegation during discussion

## Action Item Structure

Produce one structured object per detected action:

- **title**: Verb-first, imperative form, max 80 characters. Good: "Review Q4 budget proposal". Bad: "Budget proposal".
- **description**: Full context including who made the request, what is needed, why it matters, and any constraints. Quote key phrases from the source when they add specificity.
- **owner**: Assign using the Owner Inference Rules below. Use `"user"` for the current user. Use the person's name for others.
- **deadline**: ISO date string (YYYY-MM-DD) or `null`. Apply Deadline Parsing rules.
- **priority**: Score 1-5. Infer from urgency language, deadline proximity, and context (5 = critical, 1 = low).
- **source_type**: One of "Meeting Transcript", "Email", "Document", or "Other".
- **source_title**: Title of the source — meeting subject, email subject line, or document title. Extract from content headers or use first meaningful line.
- **context**: Brief reference string under 120 characters. Format varies by source type: "Meeting: [title] | [date]" or "From: [sender] | Subject: [line]" or "Document: [title]".

## Owner Inference Rules

Evaluate in order. Stop at the first match:

1. **Explicit @mention**: Text contains "@[name]" or "[name]:" followed by a task assignment. Assign owner to that person.
2. **Named delegation**: "[Name] to [verb]...", "Have [name] handle...", "[Name] will take care of...". Assign owner to the named person.
3. **Direct request to user**: In emails addressed TO the user containing a request. Assign `owner: "user"`.
4. **Team references**: "The team should...", "Engineering needs to...". Assign `owner: "user"` and add note: "Requires delegation — assign to appropriate team member."
5. **Self-commitments**: "I will...", "I'll..." or equivalent. Assign `owner: "user"`.
6. **Ambiguous ownership**: Default to `owner: "user"`. Add to description: "Owner unclear from context — verify assignment."

Never leave the owner field empty. Every action item must have an assigned owner.

## Deadline Parsing

### Explicit Dates

Parse any recognizable date format: "January 15, 2025", "Jan 15", "1/15/2025", "2025-01-15", "next Monday", "this Thursday", "the 15th", "by the 20th". Convert all to ISO format (YYYY-MM-DD). When only a day is mentioned without a month, assume the next future occurrence.

### Urgency Language

Convert urgency phrases to concrete dates relative to the current date:

| Phrase | Deadline |
|--------|----------|
| "ASAP", "immediately", "urgent" | Today |
| "today", "EOD", "COB" | Today |
| "tomorrow", "first thing tomorrow" | Tomorrow |
| "this week", "EOW", "before the weekend" | Coming Friday |
| "next week", "early next week" | Next Monday |
| "end of month", "EOM" | Last day of current month |
| "in [N] days" | Today + N days |
| "in [N] weeks" | Today + N*7 days |

### No Deadline

When no temporal language appears: set `deadline: null`. Append to description: "No deadline specified — set manually based on priority."

Never fabricate a deadline. Only assign a date when text provides explicit or implicit temporal information.

## Priority Scoring

Assign priority 1-5 based on these signals:

- **5 (Critical)**: Explicit urgency ("ASAP", "urgent", "critical"), same-day deadline, escalation language
- **4 (High)**: Deadline within 2 days, senior stakeholder requests, blocking other work
- **3 (Medium)**: Deadline within 1 week, standard requests, routine tasks with clear owners
- **2 (Low)**: Deadline beyond 1 week, nice-to-have items, informational follow-ups
- **1 (Backlog)**: No deadline, vague requests ("let's circle back"), optional items

When multiple signals conflict, use the highest priority indicator.

## Duplicate Detection

Before creating a Notion task, check for existing duplicates:

- Query the "[FOS] Tasks" database for tasks with similar titles created within the past 14 days. **Filter by `Type = "Action Item"`** to avoid false positives against Follow-Ups or Email Tasks from other plugins.
- **Duplicate**: Same primary verb AND same core noun phrase. Example: "Review Q4 budget" and "Review the Q4 budget proposal" are duplicates. Skip creation and note: "Duplicate detected — existing task [task_id]."
- **Near-duplicate**: Same noun, different verb. Example: "Review Q4 budget" vs "Approve Q4 budget". Create the new task but add cross-reference: "Related task: [task_id]."
- Never delete or modify existing tasks during duplicate detection. This check is read-only.

## Multiple Actions Per Source

- Extract every distinct action. Do not merge related but separate tasks.
- Assign each action its own unique title differentiated by verb and object.
- Share the same `source_type`, `source_title`, and `context` across items from one source.
- When the source contains a numbered or bulleted list of tasks, treat each item as a separate action.
- Preserve extraction order — list items in the order they appear.

## Edge Cases

- **Vague requests** ("Let's circle back", "We should catch up"): Create "Follow up on [topic]" with `deadline: null` and priority 1. Add: "Vague request — clarify scope and timeline."
- **Conditional actions** ("If the client approves, then send the contract"): Note the condition in description. Reduce priority by 1 (minimum 1).
- **Recurring tasks** ("Send weekly report every Friday"): Create one action for the next occurrence. Add: "Recurring task — consider automation."
- **No actions found**: Report clearly: "No action items detected in the provided text." Do not fabricate items.
- **Empty input**: Halt with: "No text provided. Paste content or provide a file path."

## Notion Task Creation

1. **Database discovery**: Search Notion for a database named "[FOS] Tasks". If not found, try "Founder OS HQ - Tasks". If not found, fall back to the legacy name "Action Item Extractor - Tasks". If none is found, skip Notion storage and use graceful degradation (see below). Do NOT create the database — the HQ database is provisioned by the Notion HQ setup process.
2. **Set required columns**: For every task created, set:
   - `Type` = "Action Item"
   - `Source Plugin` = "Action Extractor"
   - All other properties: Title, Description, Owner, Deadline, Priority, Status ("To Do"), Source Type, Source Title, Extracted At (current timestamp).
3. **Company/Contact relation**: When the owner can be matched to a CRM contact, populate the `Contact` relation. If a matching company is found via the contact's company or email domain, populate the `Company` relation. To match, search the "[FOS] Contacts" database by owner name (case-insensitive). If no match is found, leave both relations empty — never error on a failed CRM lookup.
4. After creating tasks, display results with Notion page links.

## Graceful Degradation

If Notion MCP is unavailable, output extracted action items as structured text in chat. Include all fields. Warn: "Notion unavailable — displaying results in chat. Tasks were not saved to Notion."
