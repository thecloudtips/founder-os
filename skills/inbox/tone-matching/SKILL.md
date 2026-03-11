---
name: Tone Matching
description: "Detects email formality level and mirrors the sender's communication style in drafted replies. Activates for tone analysis, formality matching, style mirroring, or when the user wants responses that 'sound right' for a given relationship — covers formal, professional, casual, and internal registers with cultural sensitivity."
globs:
  - "teams/agents/response-agent.md"
---

## Overview

Analyze incoming email tone and formality to produce responses that mirror the sender's communication style. Use this skill to ensure AI-drafted replies feel natural, relationship-appropriate, and consistent with the sender's expectations. Treat tone matching as a core requirement of every drafted response in the Inbox Zero Commander pipeline. Recognize that mismatched tone erodes trust, while accurate mirroring strengthens professional relationships and increases reply rates.

## Formality Levels

Detect and classify every incoming email into one of four formality levels before drafting any response.

### Formal

- **Indicators**: Identify full salutations ("Dear Mr./Ms."), complete sentences without contractions, professional vocabulary, and signature blocks that include title and company.
- **Response style**: Open with "Dear [Name],". Write in full sentences. Avoid all contractions. Close with "Sincerely," or "Best regards,". Include a complete signature block.
- **Typical contexts**: Apply to first contact, legal correspondence, executive communication, and external stakeholder outreach.
- **Example greeting**: "Dear Ms. Johnson,"
- **Example closing**: "Kind regards,"

### Professional

- **Indicators**: Look for "Hi [Name]," greetings, proper grammar with occasional contractions, clear and structured paragraphs, and a tone that is professional but warm.
- **Response style**: Open with "Hi [Name],". Write clear paragraphs. Allow contractions where they sound natural. Close with "Best," or "Thanks,".
- **Typical contexts**: Apply to regular business communication, known contacts, and established client relationships.
- **Example greeting**: "Hi Sarah,"
- **Example closing**: "Best,"

### Casual

- **Indicators**: Look for first-name-only greetings, informal openers ("Hey", "Hi!"), short sentences, emoji usage, and abbreviations.
- **Response style**: Open with "Hey [Name],". Write conversationally. Prefer contractions. Keep responses brief and direct.
- **Typical contexts**: Apply to close colleagues, startup environments, and friendly long-term clients.
- **Example greeting**: "Hey Mike,"
- **Example closing**: "Cheers," or "Thanks!"

### Internal

- **Indicators**: Look for the absence of any greeting, direct-to-the-point content, very brief messages, thread-style replies, and responses that are sometimes just a few words.
- **Response style**: Skip the greeting. Respond directly to the content. Use minimal formatting. Keep it to one or two sentences when possible.
- **Typical contexts**: Apply to ongoing internal threads, Slack-like email exchanges, and quick confirmations.
- **Example**: "Looks good, go ahead."

## Detection Heuristics

Analyze the following signals in order to determine the formality level of an incoming email. Weigh each signal and use the aggregate to reach a classification.

### Greeting Analysis

Scan the first line of the email body for greeting patterns.

- Map "Dear [Title] [Last Name]" to Formal.
- Map "Dear [First Name]" to the Formal/Professional boundary. Default to Professional unless other signals push toward Formal.
- Map "Hi [First Name]," to Professional.
- Map "Hey [Name]" or "Hi!" to Casual.
- Map the absence of any greeting to Internal.

### Sentence Structure

Evaluate the average sentence length and complexity across the email body.

- Classify long, complex sentences with subordinate clauses as Formal.
- Classify clear, medium-length sentences with straightforward structure as Professional.
- Classify short, punchy sentences as Casual.
- Classify fragments and one-liners as Internal.

### Vocabulary

Examine word choice and register throughout the message.

- Classify industry jargon paired with formal language constructions as Formal.
- Classify clear business language without excessive formality as Professional.
- Classify colloquialisms, slang, and informal expressions as Casual.
- Classify heavy use of abbreviations (FYI, ASAP, thx, lmk) as Casual or Internal.

### Punctuation and Formatting

Inspect punctuation patterns, emoji usage, and overall formatting.

- Classify proper punctuation with no emojis as Formal or Professional.
- Classify frequent exclamation marks or any emoji usage as Casual.
- Classify minimal punctuation and lack of formatting as Internal.

### Signature

Check the email signature block at the bottom of the message.

- Classify a full signature block (name, title, company, phone number) as Formal.
- Classify name plus title as Professional.
- Classify first name only or no signature at all as Casual or Internal.

## Mirroring Patterns

Apply these mirroring rules to every drafted response. Mirror the sender's style rather than imposing a default template.

### Greeting Mirroring

Mirror the exact greeting type used by the sender. If they write "Hi Sarah,", respond with "Hi [Their Name],". If they use "Dear,", respond with "Dear,". Do not downgrade from Formal to Casual on the first reply in any thread. Preserve the relationship boundary the sender has established.

### Length Mirroring

Match the approximate paragraph count and sentence length of the incoming email. Reply to a short email with a short response. Reply to a detailed email with a structured, organized response, but still keep it concise. Never pad a response with filler to match length artificially. Prioritize substance, then calibrate length.

### Punctuation Mirroring

Mirror the sender's punctuation style. If the sender uses exclamation marks, include one or two in the response but never more than the sender used. If the sender is reserved with punctuation, match that restraint. Never exceed the sender's emoji count. If they use zero emojis, use zero. If they use one, use at most one.

### Vocabulary Matching

Use a similar complexity level to the sender's. If they employ technical terms, use those terms back appropriately to demonstrate understanding. If they keep language simple, avoid jargon entirely. Mirror their register: if they write "per our conversation," respond in kind; if they write "like we talked about," match that informality.

## Cultural Sensitivity Guidelines

Apply these guidelines to prevent tone missteps across cultural boundaries and unfamiliar contacts.

### Cross-Cultural Awareness

Default to Professional level when the sender's cultural context is uncertain. Recognize that many cultures expect higher formality in business correspondence and err on the side of formality when ambiguity exists. Watch for non-English greeting conventions (e.g., "Sehr geehrte/r," "Estimado/a") and mirror them when possible. Do not attempt to replicate greetings in languages the system cannot verify for correctness.

### Escalation Rule

When detection signals conflict or the formality level is ambiguous, go one level more formal than the detected level. It is always safer to be slightly too formal than too casual. For any first interaction with a new contact, enforce Professional as the minimum floor regardless of signals. Never open a new relationship at Casual or Internal level.

### Relationship Progression

Recognize that formality naturally decreases over the course of multiple email exchanges. Track tone shifts within a thread: if the sender shifted from Formal to Professional in their latest reply, match the shift. Never be the first to shift down in formality. Always let the sender lead the progression toward informality. If the sender shifts back up to a more formal tone, match that escalation immediately.

## Edge Cases

Handle the following edge cases with explicit rules to prevent tone mismatches.

- **Mixed signals**: When an email starts formal but ends casual, use the closing tone as the classification. The most recent tone reflects the sender's current comfort level.
- **Group emails**: Match the most formal participant's tone when multiple recipients are on the thread. Formality protects against offending the most conservative reader.
- **Angry or upset tone**: Do not mirror negative tone under any circumstances. De-escalate to Professional level and incorporate empathetic language. Acknowledge the sender's concern without matching hostility or frustration.
- **Humor in email**: Acknowledge humor lightly if appropriate but do not attempt to replicate it in drafted responses. Humor carries high risk of misinterpretation in written form, especially across cultural boundaries.
- **Auto-generated emails**: Default to Professional for any email sent by an automated system, notification service, or bot. The "sender" is a system and provides no meaningful tone signal.
- **Very short emails**: When the email body is fewer than ten words, rely primarily on greeting and signature signals. Do not attempt sentence-structure or vocabulary analysis on minimal content.
- **Forwarded emails**: Analyze the sender's added commentary for tone, not the forwarded content. The sender's words set the relationship context.

## Quick Reference Table

Consult this table for rapid classification when drafting responses.

| Signal | Formal | Professional | Casual | Internal |
|--------|--------|-------------|--------|----------|
| Greeting | Dear Mr./Ms. | Hi [Name], | Hey! | None |
| Contractions | No | Sometimes | Yes | Yes |
| Sentence length | Long | Medium | Short | Fragment |
| Emojis | Never | Rarely | Sometimes | Sometimes |
| Closing | Sincerely | Best | Cheers | None |
| Signature | Full block | Name + title | First name | None |
| Response time expectation | Measured | Reasonable | Quick | Immediate |
