---
name: Action Extraction
description: "Turns emails into structured action items with owners, deadlines, and priorities. Activates when the user wants to extract tasks from email, find action items, pull to-dos from their inbox, or convert email requests into trackable work — including implicit asks like 'what do I need to do from these emails?' Handles verb detection, owner inference, and deadline parsing."
globs:
  - "teams/agents/action-agent.md"
---

## Overview

Analyze email content to extract structured action items. Convert every detected action into a task in the **"[FOS] Tasks"** Notion database with `Type = "Email Task"` and `Source Plugin = "Inbox Zero"`. Each task contains a title, description, owner, deadline, and priority. Treat each email as a potential source of one or more independent action items. Process the email body systematically: scan for actionable verb patterns, infer ownership, parse deadlines, and assign priority inherited from the triage stage. Never skip an email classified as `action_required` without producing at least one action item.

## Notion Database Discovery

Do NOT create databases. Discover existing ones using this fallback chain:

1. Search Notion for **"[FOS] Tasks"**.
2. If not found, try **"Founder OS HQ - Tasks"**.
3. If not found, fall back to **"Inbox Zero - Action Items"** (legacy name).
4. If none exists, warn that tasks will not be persisted to Notion and continue pipeline.
4. Cache the resolved database ID for the remainder of the pipeline run.

Every task page MUST set:
- `Type` = `"Email Task"` (select)
- `Source Plugin` = `"Inbox Zero"` (select)

## Company/Contact Relation Population

When writing a task to Notion, attempt to link it to the CRM:

1. Extract the sender's full email address and email domain (e.g., `acmecorp.com` from `sarah.chen@acmecorp.com`).
2. **Contact lookup**: Search **"[FOS] Contacts"** (fall back to "Founder OS HQ - Contacts") for a contact whose **Email** property matches the sender's full email address.
3. If a Contact match is found, follow its **Company** relation to get the Company page ID. Set both the `Company` and `Contact` relations on the task page.
4. **Domain fallback**: If no Contact match, search **"[FOS] Companies"** (fall back to "Founder OS HQ - Companies") for a company whose **Domain** property contains the sender's email domain.
5. If a Company is found via domain match, set the `Company` relation on the task page. Leave `Contact` empty.
6. If no CRM match is found by either method, leave Company and Contact empty. Never create new CRM records from this plugin.

## Actionable Verb Patterns

Detect action items by identifying verb patterns in email text. Scan the email body in three passes -- one per pattern category below -- and collect all matches before deduplicating.

### Direct Requests (Highest Signal)

Treat these patterns as strong indicators of an action item. Extract the action immediately upon detection:

- "Review [something]", "Approve [something]", "Sign [document]"
- "Send [item] to [person]", "Forward [something] to [recipient]"
- "Schedule [meeting/call]", "Set up [something]", "Book [time/room]"
- "Complete [task]", "Finish [item]", "Submit [deliverable]"
- "Update [document/status]", "Revise [item]", "Edit [document]"
- "Pay [invoice/bill]", "Process [payment/expense]"
- "Create [document/report/plan]", "Draft [response/proposal]"
- "Confirm [attendance/details]", "Verify [information]"
- "Share [document/access] with [person]", "Grant [permission]"
- "Cancel [meeting/subscription]", "Remove [item/access]"

Flag any sentence containing one of these verb patterns as a candidate action item. Proceed to owner inference and deadline parsing for each candidate.

### Implicit Actions (Medium Signal)

Recognize polite or indirect phrasing that conceals a genuine request. Convert the implicit language into an explicit action verb before creating the action item:

- "Can you...?", "Could you...?", "Would you mind...?" -- extract the verb following the modal.
- "Please [verb]...", "Kindly [verb]..." -- extract the verb directly.
- "I need you to...", "We need...", "It would be great if..." -- extract the clause following the setup phrase.
- "Let me know about...", "Get back to me on..." -- convert to "Respond about [topic]" or "Provide update on [topic]".
- "Any thoughts on...?", "What do you think about...?" -- convert to "Review and provide feedback on [topic]".
- "It would be helpful to have..." -- convert to "Prepare [item]" or "Create [item]".

When an implicit action lacks a clear verb, default to "Follow up on [topic extracted from sentence context]".

### Commitment Language (Actions the User Promised)

Capture promises the user made in prior thread messages. These represent obligations the user must fulfill:

- "I will...", "I'll...", "I can...", "I'm going to..."
- "Let me...", "Allow me to..."
- "I'll follow up on...", "I'll get back to you about..."
- "I'll have that to you by...", "Expect it by..."
- "Consider it done", "I'm on it" -- extract the referenced task from surrounding context.

Mark every commitment-language action with `owner: "user"` regardless of other signals.

## Action Item Structure

Produce one structured object per detected action. Include all of the following fields:

- **title**: Write a concise, verb-first description. Cap at 80 characters. Start with an actionable verb in imperative form. Good: "Review Q4 budget proposal". Bad: "Budget proposal". Good: "Send updated contract to legal team". Bad: "Contract update". Strip filler words. Omit articles when possible without losing clarity.
- **description**: Include full context. State who made the request, what is needed, why it matters (if stated), and any relevant constraints or conditions mentioned in the email. Quote key phrases from the original email when they add specificity.
- **owner**: Assign using the Owner Inference Rules below. Use the string `"user"` for the current user. Use the person's name or email address for other individuals.
- **deadline**: Use an ISO date string (YYYY-MM-DD) or `null`. Apply the Deadline Parsing rules below.
- **priority**: Inherit the priority score from the email's triage stage. Do not recalculate priority -- pass through the value assigned by the priority-scoring skill.
- **source_email_id**: Store the unique identifier of the originating email. Use the Gmail message ID.
- **context**: Build a brief reference string in the format `"From: [sender name/email] | Subject: [email subject line]"`. Keep this under 120 characters.

## Owner Inference Rules

Determine who owns each action by evaluating these rules in order. Stop at the first rule that matches:

1. **Explicit assignment to user**: The email is addressed TO the user and contains a direct request or question. Assign `owner: "user"`.
2. **Named delegation**: The email says "Ask [person] to...", "Have [person] handle...", "[Person] will take care of...". Assign `owner` to the named person. Extract the person's name or email.
3. **Explicit assignment to third party**: The email assigns the task to a specific person other than the user ("This is for [person]", "[Person], please..."). Assign `owner` to that person.
4. **Team references**: "The team should...", "We need someone to...", "Engineering needs to...". Assign `owner: "user"` because the user must delegate. Add a note in the description: "Requires delegation -- assign to appropriate team member."
5. **Self-commitments**: The user wrote "I will..." or equivalent commitment language in the email thread. Assign `owner: "user"`.
6. **Ambiguous ownership**: When no rule above matches clearly, default to `owner: "user"`. Add to the description: "Owner unclear from email context -- verify assignment."

Never leave the owner field empty or null. Every action item must have an assigned owner.

## Deadline Parsing

### Explicit Dates

Parse any recognizable date format found in the email body:

- Full dates: "January 15, 2025", "Jan 15", "1/15/2025", "01-15-2025", "2025-01-15"
- Relative day names: "next Monday", "this Thursday", "on Wednesday"
- Partial dates: "the 15th", "by the 20th"

Convert all parsed dates to ISO format (YYYY-MM-DD). When only a day is mentioned without a month, assume the next future occurrence of that day. When only a month and day are mentioned without a year, assume the current year unless that date has already passed, in which case assume next year.

### Urgency Language to Date Mapping

Convert urgency phrases to concrete dates relative to the current date at processing time:

- "ASAP", "immediately", "right away", "urgent" -- set deadline to today's date.
- "today", "by end of day", "EOD", "by close of business", "COB" -- set deadline to today's date.
- "tomorrow", "by tomorrow", "first thing tomorrow" -- set deadline to tomorrow's date.
- "this week", "by end of week", "EOW", "before the weekend" -- set deadline to the coming Friday. If today is Saturday or Sunday, set to the following Friday.
- "next week", "early next week" -- set deadline to next Monday.
- "end of month", "EOM", "by month's end" -- set deadline to the last calendar day of the current month.
- "end of quarter", "EOQ" -- set deadline to the last day of the current fiscal quarter (Mar 31, Jun 30, Sep 30, or Dec 31).
- "end of year", "EOY" -- set deadline to December 31 of the current year.
- "in [N] days" -- add N calendar days to today's date.
- "in [N] weeks" -- add N * 7 calendar days to today's date.

### No Deadline Detected

When no temporal language or date reference appears in the email for a given action item:

- Set `deadline: null`.
- Append to the action item description: "No deadline specified in email -- set manually based on priority."

Never fabricate a deadline. Only assign a date when the email text provides explicit or implicit temporal information.

## Multiple Actions Per Email

Handle emails containing more than one action item:

- Extract every distinct action from the email body. Do not merge related but separate tasks into a single item.
- Assign each action item its own unique title. Differentiate by verb and object ("Review budget proposal" and "Send budget to finance" are two separate items from the same email).
- Share the same `source_email_id` and `context` across all action items from one email.
- Evaluate priority independently for each action. One email may contain an urgent approval request alongside a low-priority FYI task.
- Preserve extraction order. List action items in the order they appear in the email body.
- When an email contains a numbered or bulleted list of tasks, treat each list item as a separate action item.

## Duplicate Detection

Before creating a Notion task, check for existing duplicates:

- Query the resolved Notion database (HQ Tasks or legacy) for tasks with similar titles created within the past 14 days. When querying HQ Tasks, filter by `Type = "Email Task"` AND `Source Plugin = "Inbox Zero"` to scope the duplicate check to this plugin's records only.
- Define similarity as: same primary actionable verb AND same core noun phrase. Example: "Review Q4 budget" and "Review the Q4 budget proposal" are duplicates. "Review Q4 budget" and "Approve Q4 budget" are not duplicates.
- When a duplicate is found: skip task creation. Include the existing Notion task ID in the output and add a note: "Duplicate detected -- existing task [task_id]."
- When near-duplicate is found (same noun, different verb): create the new task but add a cross-reference in the description: "Related task: [existing_task_id]."
- Never delete or modify existing tasks during duplicate detection. This check is read-only.

## Edge Cases

Handle the following scenarios with these specific rules:

- **Email chain with multiple requests across messages**: Extract action items from the latest (most recent) message only. Earlier requests in the thread may already be resolved. If the latest message explicitly references an earlier unresolved request ("Still waiting on the budget review I mentioned Tuesday"), extract that referenced action as well.
- **Forwarded email with "FYI" but embedded action**: Extract the action item from the forwarded content. Set the context to indicate the email was forwarded. Add to description: "Forwarded by [forwarder] -- action embedded in original message."
- **Meeting invite with agenda items**: Do not extract the meeting itself as an action item. Instead, extract "Prepare for [meeting topic]" as a single action item. If the agenda lists specific preparation tasks ("Bring Q4 numbers", "Review attached deck"), extract each preparation task as a separate action item with the meeting date as the deadline.
- **Auto-generated emails** (Jira, GitHub, Asana, Trello notifications): Extract an action item only when the notification indicates a task assigned to or requiring action from the user. Ignore status-update-only notifications. Use the linked ticket/issue title as the action item title when available.
- **Vague requests** ("Let's circle back", "We should catch up", "Let's revisit this"): Create an action item with the title "Follow up on [topic]". Set `deadline: null`. Add to description: "Vague request -- clarify scope and timeline with [sender]."
- **Conditional actions** ("If the client approves, then send the contract"): Create the action item with the condition noted in the description: "Conditional -- blocked on [condition]. Do not execute until condition is met." Set priority one level lower than the email's triage score (minimum 1).
- **Recurring or standing requests** ("Send me the weekly report every Friday"): Create a single action item for the next occurrence only. Add to description: "Recurring task -- consider setting up automation."

## Quality Checks

Validate every batch of extracted action items before output:

- Confirm that every email classified as `action_required` produces at least one action item. If the extraction pipeline yields zero items for an `action_required` email, re-scan the email body with relaxed pattern matching (include implicit actions and vague requests).
- Verify that every title starts with an actionable verb in imperative form. Reject titles that begin with nouns, articles, or adjectives. Rewrite non-compliant titles before output.
- Validate all deadline values. Accept only valid ISO date strings (YYYY-MM-DD) or `null`. Reject malformed dates. When a parsed date is in the past, flag it in the description: "Parsed deadline [date] is in the past -- verify with sender."
- Confirm that every action item includes a populated `source_email_id` and `context` field. Never output an action item without traceability back to the source email.
- Confirm that no two action items from the same email have identical titles. Disambiguate by adding specificity from the email body.
