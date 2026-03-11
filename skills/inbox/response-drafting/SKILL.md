---
name: Response Drafting
description: "Generates contextual email reply drafts that mirror the sender's tone and style. Activates when the user wants to draft replies, compose responses, write back to someone, or handle emails that need a response — even 'help me answer these emails' or 'what should I say back?' Includes confidence scoring and commitment safety boundaries."
globs:
  - "teams/agents/response-agent.md"
---

## Overview

Generate contextual, well-structured email drafts for every email flagged as `needs_response: true` during the triage phase. Save all drafts to the **"[FOS] Content"** Notion database with `Type = "Email Draft"` for user review. Never send a response automatically. Treat every draft as a suggestion that requires human approval before delivery. Ensure each draft reflects the original email's context, tone, and urgency while staying within safe commitment boundaries.

## Notion Database Discovery

Do NOT create databases. Discover existing ones using this fallback chain:

1. Search Notion for **"[FOS] Content"**.
2. If not found, try **"Founder OS HQ - Content"**.
3. If not found, fall back to **"Inbox Zero - Drafts"** (legacy name).
4. If none exists, warn that drafts will not be persisted to Notion and continue pipeline.
4. Cache the resolved database ID for the remainder of the pipeline run.

Every draft page MUST set:
- `Type` = `"Email Draft"` (select)

## Email Structure

Follow this four-part structure for every drafted response.

### 1. Greeting

Mirror the sender's greeting style (refer to the tone-matching skill for detailed guidance). Use "Hi [First Name]," when no greeting appears in the original email. Switch to "Dear [Name]," in formal contexts such as first-time client communication, legal correspondence, or executive-level exchanges. Omit the greeting entirely only when replying within a rapid back-and-forth thread where greetings have already been dropped by both parties.

### 2. Acknowledgment

Open with a brief acknowledgment of what was received. Write one sentence that confirms receipt and shows the email was read. Use phrasing like "Thanks for sending the Q4 report" or "Got your message about the timeline change." Skip the acknowledgment line when the email is part of a quick back-and-forth thread where context is already established and an acknowledgment would feel redundant.

### 3. Core Response

Address ALL points and questions raised in the original email. Do not skip or defer any topic the sender explicitly raised. Reference any action items that were created during the action-extraction phase, connecting the response to concrete next steps. Keep the response concise and match the original email's length where possible. Use bullet points or numbered lists when addressing three or more distinct items. Organize the response in the same order the sender raised each topic, making it easy for them to scan and confirm each point was covered.

### 4. Closing

Include a clear next step when one applies, such as "I'll send the updated version by Friday" or "Let me know if you'd like to schedule a call." Mirror the sender's closing style when one is present. Default to "Best," or "Thanks," when the sender's style is unknown or inconsistent. Add the user's name on the line below the closing.

## Length Matching Guidelines

Match the response length to the original email's length. Follow these rules strictly.

- **Short email (1-3 sentences)**: Reply with 1-3 sentences. Do not pad with unnecessary pleasantries.
- **Medium email (1-2 paragraphs)**: Reply with 1-2 paragraphs. Maintain a similar density of information.
- **Long email (3+ paragraphs)**: Summarize and respond concisely in 2-3 paragraphs maximum. Prioritize the most important points and group secondary items into a single bullet list.
- Never write a longer response than the original unless genuinely necessary to address all raised points. Err on the side of brevity.

## Confidence Scoring

Assign a confidence score between 0.0 and 1.0 to every draft. Base the score on how certain the system is that the draft is accurate, appropriate, and ready to send with minimal editing.

### High Confidence (0.8-1.0)

Reserve high confidence for routine responses: meeting confirmations, simple acknowledgments, straightforward approvals, and scheduling replies. Assign this range when the context is clear, the intent is unambiguous, and similar emails have been handled before through pattern recognition. Example: "Yes, I can attend the meeting on Thursday at 2pm" receives a score of 0.95.

### Medium Confidence (0.5-0.79)

Assign medium confidence to nuanced responses that require some judgment. Include emails with multiple topics to address, some ambiguity in the request, or situations where the appropriate level of detail is unclear. Example: a response to a proposal with several discussion points receives a score of 0.65.

### Low Confidence (below 0.5)

Assign low confidence to drafts involving highly ambiguous requests, sensitive topics (complaints, negotiations, legal matters), missing context needed for an informed response, or complex multi-party situations. Example: a client complaint about project delays receives a score of 0.35. Flag every low-confidence draft with `needs_review: true` in the output to ensure the user sees it before any other drafts.

## Commitment Boundaries

Follow this critical rule: NEVER make new commitments beyond what was captured as action items during the action-extraction phase.

- Only reference commitments already present in the `action_items` array for the given email.
- Draft safe, generic language when the email expects a commitment that was not extracted. Use phrasing like "I'll review this and get back to you" or "Let me look into this and follow up."
- Never promise specific deadlines that were not already extracted as action items.
- Never agree to new scope, additional deliverables, or expanded timelines.
- Never confirm pricing, budgets, or financial terms without explicit prior extraction.
- Flag the draft as `needs_review: true` whenever a commitment seems expected but none was extracted during action extraction. Add a note in the draft metadata explaining: "Sender may expect a commitment — none was extracted. User should review."

## Cross-Referencing Action Items

Draft responses that connect directly to extracted action items when they exist for the email being answered.

- Acknowledge the commitment explicitly: "I'll have the [action item title] ready by [deadline]."
- Reference tracking when appropriate: "I've added this to my task list" or "This is on my radar for [timeframe]."
- Only reference action items extracted from THIS specific email. Never pull in action items from other emails in the same batch.
- When multiple action items exist for one email, list them briefly so the sender knows each item was noted.

## Context Awareness

### Reply vs Reply-All

Default to Reply (single recipient) for every draft. Only suggest Reply-All when the original email was sent to multiple people AND all recipients need to see the response. When unsure, default to Reply and add a metadata note: "Consider Reply-All if all original recipients need visibility."

### Thread Context

Read the full email thread before drafting any response. Reference earlier messages when relevant, using phrasing like "As discussed last Tuesday..." or "Building on your earlier point about the timeline..." Avoid repeating information already shared in the thread. When the thread is long (5+ messages), summarize the current state briefly before responding to the latest message.

### Sender Relationship

Adjust formality and directness based on the sender's relationship to the user. Refer to the tone-matching skill for detailed guidance. Apply these general rules:

- **Known client**: Use more formal language, acknowledge the relationship, reference shared history when relevant.
- **Internal team member**: Use casual, direct language. Skip unnecessary pleasantries.
- **Unknown sender or first contact**: Default to professional and neutral. Do not assume familiarity.
- **Executive or senior stakeholder**: Maintain formality, be concise, lead with the most important information.

## Edge Cases

Handle the following situations with specific behavior.

- **Out-of-office detection**: If the original email mentions the sender will be out or unavailable, skip drafting a response. Add a note to the output: "Sender is OOO — no response drafted."
- **Multiple questions in one email**: Address each question in the order it was asked. Use numbered responses when the email contains three or more distinct questions to make the reply scannable.
- **Email in a language other than English**: Draft the response in the same language as the original email when possible. If the language is not supported or the system cannot produce a reliable draft, flag the email with `needs_review: true` and note: "Non-English email — user should draft manually."
- **Forwarded email with "thoughts?" or similar**: Provide a brief assessment of the forwarded content rather than drafting a full reply. Keep the assessment to 2-4 sentences covering the key takeaway and a recommended action.
- **Angry or frustrated tone**: De-escalate immediately. Acknowledge the sender's frustration with empathy ("I understand this has been frustrating"). Be concise and solution-oriented. Avoid defensive language. Flag the draft as `needs_review: true` with a note: "Sender tone is frustrated — review before sending."
- **Auto-generated emails (newsletters, notifications, receipts)**: Do not draft a response. Mark as `needs_response: false` if incorrectly flagged during triage.
- **Duplicate or near-duplicate emails**: Draft a single response and note the duplication. Do not draft separate responses for the same content sent multiple times.

## Draft Output Format

Structure every draft output with the following fields.

- `source_email_id`: The unique identifier linking back to the original email.
- `to`: The recipient email address for the draft.
- `cc`: Include only if the original email context requires it. Default to empty.
- `subject`: Use "Re: [original subject]" exactly. Do not modify the subject line.
- `body`: The full drafted response text, formatted as plain text with line breaks.
- `tone`: The detected and applied tone level (e.g., "formal", "casual", "neutral"). Refer to the tone-matching skill output.
- `confidence`: The confidence score as a float between 0.0 and 1.0.
- `needs_review`: Boolean value. Set to `true` when confidence falls below 0.5, sensitive content is detected, commitment boundaries may be crossed, or any edge case triggers manual review. Set to `false` for routine, high-confidence drafts.
- `review_notes`: Optional string. Include only when `needs_review` is `true`. Explain why the draft requires attention.

Validate every draft against the commitment boundaries before finalizing. Verify that the confidence score accurately reflects the draft's reliability. Ensure the tone matches the tone-matching skill's output for the corresponding email. Save the completed draft to the resolved Notion Content database (HQ Content or legacy Drafts) with `Type = "Email Draft"` and status "To Review". Drafts move to Gmail only after user approval via `/founder-os:inbox:drafts_approved`.
