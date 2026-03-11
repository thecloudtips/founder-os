# Activity Summary Template

<!-- INSTRUCTIONS: This template guides consistent AI-generated activity summaries when logging activities to the CRM Pro Communications database. It is used by the activity-logging skill to produce the Title, Summary, Sentiment, and Participants fields for each Communications record. Follow all rules exactly as written. -->

Guide for generating consistent AI summaries when logging activities to CRM Pro Communications database.

---

## Email Activity Summary

### Title Generation

Strip email subject line prefixes iteratively until none remain, then format the result as the Title property.

**Prefix stripping order** (apply repeatedly until stable):
1. `Re:` / `RE:` (with or without trailing space)
2. `Fwd:` / `FWD:` / `FW:` (with or without trailing space)
3. `[EXTERNAL]` / `[EXT]` (gateway tags)
4. `Automatic reply:` / `Auto:` (out-of-office prefixes)

<!-- Example: "Re: Re: Fwd: [EXTERNAL] Q2 Budget Review" → "Q2 Budget Review" -->

**Formatting rules:**
- Trim leading and trailing whitespace after stripping.
- Capitalize the first letter if it is lowercase.
- Do not otherwise modify casing -- preserve the original.
- Truncate at 77 characters and append `...` if the result exceeds 80 characters.
- If the result is empty after stripping (subject was only prefixes), set Title to `Untitled Email`.
- Preserve special characters: `#`, `&`, `@`, `/`, parentheses. These carry meaning (e.g., "Invoice #2847").

### Summary Structure (2-3 sentences)

<!-- Target: A founder should understand the gist of the interaction in under 5 seconds. Write in plain English. Avoid jargon. -->

**Sentence 1 -- Topic**: What the email was about.
- Pattern: `[Sender/Recipient] [discussed/requested/responded to/shared/confirmed] [topic].`
- Example: "Discussed Q2 marketing budget allocation and timeline adjustments."

**Sentence 2 -- Key Outcomes**: Decisions, commitments, or action items.
- Pattern: `[Key decision or commitment]. [Action item if any].`
- Example: "Agreed to increase social media spend by 15%. Jane to send revised budget by Friday."

**Sentence 3 -- Next Steps** (include only when significant):
- Pattern: `Next step: [action] by [date/person].`
- Example: "Next step: Review meeting scheduled for March 15."

### Email-Specific Rules

- For short emails (< 3 sentences): summary may be 1 sentence.
- For multi-message threads: summarize the LATEST exchange, note thread length ("Thread of 8 messages").
- For forwarded emails: focus on the forwarded content and any added context.
- Never include email signatures, disclaimers, or boilerplate in summaries.

### Email Summary Example

**Source data:**
- Subject: `Re: Fwd: Q3 Website Redesign Proposal`
- Body: Confirms $15,000 budget, requests kickoff meeting next week.
- Recipient: Sarah Chen at Brightwave Digital

**Generated output:**
```
Title:       Q3 Website Redesign Proposal
Summary:     Confirmed the $15,000 budget for the Q3 website redesign project
             with Brightwave Digital. Requested a kickoff meeting next week to
             align on deliverables and timeline.
Sentiment:   Positive
```

---

## Meeting Activity Summary

### Title Generation

- Use the calendar event title directly -- no prefix stripping (meetings do not have Re:/Fwd: conventions).
- Truncate at 77 characters and append `...` if the result exceeds 80 characters.
- Do NOT add prefixes like "Meeting:" -- the Type field already indicates it is a meeting.

### Summary Structure (2-3 sentences)

**Sentence 1 -- Purpose and Participants**: What the meeting was for.
- Pattern: `[Meeting type] with [key participants] regarding [topic].`
- Example: "Project kickoff with Acme Corp team regarding Q2 website redesign."

**Sentence 2 -- Key Topics/Decisions**: What was discussed or decided.
- Pattern: `[Topics covered or decisions made].`
- Example: "Reviewed project scope, agreed on 8-week timeline, and identified three key deliverables."

**Sentence 3 -- Follow-ups** (include only when present):
- Pattern: `Follow-up: [action items or next meeting].`
- Example: "Follow-up: SOW to be drafted by end of week; next check-in March 20."

### Meeting-Specific Rules

- For meetings with descriptions: extract key points from the description.
- For meetings without descriptions: summarize based on title, attendees, and duration.
- For recurring meetings: note it is a recurring sync ("Weekly client sync").
- For short meetings (< 15 min): likely a quick call, keep summary to 1 sentence.

### Meeting Summary Example

**Source data:**
- Event title: `Monthly Retainer Review - Island Breeze Co`
- Description: "Review October deliverables, discuss November priorities"
- Attendees: Lani Kahale, David Park, user
- Duration: 45 minutes (past event)

**Generated output:**
```
Title:       Monthly Retainer Review - Island Breeze Co
Summary:     Monthly retainer review with Lani Kahale and David Park from
             Island Breeze Co. Covered October deliverables and discussed
             priorities for November.
Sentiment:   Neutral
```

---

## Sentiment Classification

<!-- Default to Neutral when signals are mixed or ambiguous. A single strong negative signal overrides multiple mild positive signals. -->

### Positive Signals

Classify as **Positive** when clear positive signals dominate the communication.

| Category | Signal Words |
|----------|-------------|
| Gratitude | "thank you", "appreciate", "grateful", "thanks so much", "many thanks" |
| Enthusiasm | "excited", "looking forward", "great news", "thrilled", "fantastic", "amazing", "love it", "perfect" |
| Agreement | "sounds good", "approved", "let's proceed", "go ahead", "green light", "on board", "confirmed" |
| Forward momentum | "next steps", "moving forward", "on track", "ready to move forward", "eager to begin", "phase 2", "scale up" |
| Praise | "great work", "outstanding", "exceeded expectations", "impressed", "above and beyond" |

### Neutral Signals

Classify as **Neutral** when the communication is factual, routine, or administrative with no strong emotional signals.

| Category | Signal Words |
|----------|-------------|
| Administrative | "please find attached", "as discussed", "for your records", "FYI", "scheduling", "confirming" |
| Status updates | "update on", "progress report", "status:", "completed", "in progress", "on track", "milestone reached" |
| Routine | "weekly sync", "monthly review", "check-in", "agenda for", "recap", "minutes from", "as planned" |

### Negative Signals

Classify as **Negative** when clear negative signals dominate the communication.

| Category | Signal Words |
|----------|-------------|
| Frustration | "disappointed", "concerned", "issue", "not satisfied", "still waiting", "falling behind", "per my last email" |
| Escalation | "urgent", "escalate", "unacceptable", "formal complaint", "legal", "breach", "termination", "SLA violation" |
| Delays | "delayed", "postponed", "pushed back", "on hold", "blocked", "cannot proceed", "unfortunately" |
| Cancellation | "cancelled", "no longer", "discontinued", "pausing the project", "stepping back", "exploring other options" |

### Classification Rules

1. Default to **Neutral** when signals are mixed or unclear.
2. Classify as **Positive** only when clear positive signals dominate.
3. Classify as **Negative** only when clear negative signals dominate.
4. When both positive and negative signals are present equally: **Neutral**.
5. Negative signals carry more weight -- a single strong negative indicator overrides multiple mild positive signals.
6. Evaluate signals in context. A signal word used sarcastically or ironically inverts its meaning.

---

## Participants Format

<!-- Participants are listed in the Participants property (rich_text) for Communications records that support the optional field. -->

Format participants as a comma-separated list: `Name (Role)` where Role comes from the CRM Contacts database.

**Formatting rules:**
- If role is known: `Name (Role)` -- e.g., `Jane Smith (VP Marketing)`
- If role is unknown: just `Name` -- e.g., `Bob Lee`
- If name is unknown: just the email address -- e.g., `unknown@example.com`
- Put the user first, then external participants.
- Separate entries with commas and a space.

**Example:**
```
You, Jane Smith (VP Marketing), Bob Lee, kai@pacificedge.com
```

---

<!-- GENERATION NOTES:
  - Voice: Plain English. No jargon. Write for a busy founder who needs the gist in 5 seconds.
  - Summary length: 2-3 sentences for standard activities. 1 sentence for short emails (< 3 sentences) and brief meetings (< 15 min).
  - Title length: Max 80 characters. Truncate at 77 and append "..." if exceeded.
  - Sentiment: Default to Neutral when ambiguous. Negative signals outweigh positive.
  - Threads: Summarize only the latest exchange for threads with 10+ messages. Note total thread length.
  - Empty content: Use "Untitled Email" or "Untitled Meeting" when source data lacks a subject or title.
  - This template is consumed by the activity-logging skill. See SKILL.md for the full write logic, deduplication strategy, and batch processing rules.
-->
