---
name: Nudge Writing
description: "Drafts professional follow-up nudge emails calibrated by elapsed time and relationship type. Activates when the user wants to follow up on an unanswered email, write a reminder, nudge someone, or asks 'how should I follow up on this?' Handles 3 escalation levels (gentle/firm/urgent) with tone matching for clients, colleagues, and vendors — avoids passive-aggression and common anti-patterns."
globs:
  - "commands/followup-nudge.md"
---

## Overview

Draft professional follow-up nudge emails for sent messages that have not received a response. Select the appropriate escalation level based on elapsed time since the original email, match tone to the relationship type, construct a subject line that preserves threading, reference the original ask without passive-aggression, and close with a clear call to action. Every nudge must feel purposeful and respectful -- the goal is to prompt a response, not to shame the recipient for silence.

## Escalation Levels

Determine the escalation level from the number of days since the original email was sent (or since the last nudge, whichever is more recent) and the number of prior nudges already sent.

| Level | Label | Trigger | Days Elapsed | Prior Nudges | Tone Shift |
|-------|-------|---------|--------------|--------------|------------|
| 1 | Gentle | First follow-up | 3-7 days | 0 | Light, assumes busy schedule |
| 2 | Firm | Second follow-up | 7-14 days | 1 | Direct, restates importance |
| 3 | Urgent | Third or later | 14+ days | 2+ | Clear deadline, escalation signal |

### Level 1: Gentle Nudge (3-7 days, first follow-up)

Assume the recipient is busy and the original email was simply buried. Keep the message short (3-5 sentences). Lead with a brief, genuine context reference ("Following up on the proposal I sent last Tuesday"). Offer a lightweight reason for the follow-up ("Wanted to make sure this didn't get lost in the shuffle"). Close with a single, low-pressure call to action ("Would love to hear your thoughts when you get a chance").

Structure:
1. One-sentence context anchor referencing the original email
2. One sentence acknowledging the recipient may be busy (without over-apologizing)
3. One-sentence call to action with an open-ended or soft-deadline phrasing

Avoid: urgency language, deadline pressure, any implication that silence is a problem.

### Level 2: Firm Nudge (7-14 days, second follow-up)

Shift from "just making sure you saw it" to "this needs your attention." Be direct about what is needed and why it matters. Reference the specific ask from the original email. Introduce a soft deadline or consequence without ultimatums. Length: 4-6 sentences.

Structure:
1. Brief reference to the original email and the first follow-up
2. Restate the specific request or decision needed
3. Explain why a response matters now (dependency, timeline, other stakeholders)
4. Propose a concrete next step or soft deadline
5. Offer an alternative if the original ask is no longer feasible ("If priorities have shifted, a quick heads-up would help me plan accordingly")

Avoid: accusatory framing, repeating the full original email body, emotional language.

### Level 3: Urgent Nudge (14+ days, third or later follow-up)

Signal that this is the final attempt through standard channels. Be concise and clear about the impact of continued non-response. State a firm deadline. Mention escalation only when appropriate (e.g., looping in a manager, finding an alternative contact). Length: 3-5 sentences.

Structure:
1. State this is a third (or Nth) follow-up on the original topic
2. Summarize the outstanding ask in one sentence
3. State a specific deadline ("I need to hear back by Friday, March 7")
4. Describe what happens if no response is received (proceed without input, escalate, close the thread)
5. Keep the door open ("Happy to jump on a quick call if that's easier")

Avoid: threats, ultimatums phrased as demands ("You must respond by..."), burning bridges.

## Tone Matching by Relationship Type

Adjust vocabulary, formality, and directness based on the relationship between the sender and recipient.

### Client (Professional / Warm)

- Use the client's first name
- Maintain a service-oriented posture -- the nudge is about helping them, not pressuring them
- Frame deadlines in terms of the client's benefit ("To keep your project on track for the April launch...")
- Never imply the client is at fault for the delay
- Use collaborative language: "we", "together", "our timeline"
- Sign off warmly: "Looking forward to hearing from you", "Happy to discuss anytime"

Example phrases by level:
- Gentle: "I wanted to circle back on the proposal I shared last week -- happy to walk through any questions."
- Firm: "I want to make sure we stay on track for your launch date. Could you let me know your decision on the scope by Friday?"
- Urgent: "I want to be respectful of your timeline. To keep the project moving, I'll need confirmation by March 7 -- otherwise we may need to adjust the delivery schedule."

### Colleague (Casual / Direct)

- Use first name, skip formalities
- Be straightforward about the need without excessive politeness
- Reference shared context and team goals
- Acceptable to use slightly informal language ("Hey", "Quick ping", "Bumping this up")
- Frame as mutual accountability, not hierarchy

Example phrases by level:
- Gentle: "Hey -- just bumping this up. Let me know when you get a chance to look at the budget numbers."
- Firm: "I need the budget numbers to finish the quarterly report by Thursday. Can you send them over today or tomorrow?"
- Urgent: "Third time reaching out on this -- I need to submit the quarterly report Friday with or without the updated numbers. Can you get them to me by EOD Thursday?"

### Vendor (Assertive / Clear)

- Use formal address unless an informal relationship is established
- State expectations clearly and reference any contractual or agreed-upon obligations
- Frame in terms of deliverables and timelines, not feelings
- Acceptable to reference SLAs, contract terms, or prior commitments
- Escalation language is appropriate at Level 3 ("I may need to loop in your account manager")

Example phrases by level:
- Gentle: "Following up on the invoice correction I requested on February 15. Could you provide an update on the revised amount?"
- Firm: "Per our agreement, the corrected invoice was due within 5 business days. I'd appreciate an update by end of week so we can process payment promptly."
- Urgent: "This is my third follow-up regarding the outstanding invoice correction (originally requested February 15). I need the revised invoice by March 7 to avoid a hold on future purchase orders. Please confirm receipt of this request."

## Subject Line Handling

### Threading Preservation

Always preserve the `Re:` prefix to maintain email thread continuity. Never strip it or replace it. When the original subject already contains `Re:`, do not add another.

### Follow-Up Tagging

Add a `[Follow-up]` tag on the second nudge and beyond (Level 2+). Place the tag after `Re:` and before the original subject text.

| Nudge Level | Subject Line Format |
|-------------|-------------------|
| Level 1 (first nudge) | `Re: [Original Subject]` |
| Level 2 (second nudge) | `Re: [Follow-up] [Original Subject]` |
| Level 3 (third+ nudge) | `Re: [Follow-up] [Original Subject]` |

Do not add numeric counters like `[Follow-up #3]` -- it feels aggressive. One `[Follow-up]` tag is sufficient to signal persistence without being confrontational.

### Subject Line Rules

- Never rewrite the original subject line. Preserve the recipient's ability to find the thread.
- Never add urgency markers like `[URGENT]` or `[ACTION REQUIRED]` to subject lines for Level 1 nudges.
- At Level 3, adding `[Action Required]` before the original subject is acceptable for vendor relationships only.
- Maximum subject line length: 78 characters (email standard). Truncate the original subject with `...` if needed to fit the tag.

## Context Referencing

Reference the original email's content to remind the recipient what is being followed up on. The goal is clarity, not guilt.

### Principles

1. **Be specific about the ask.** Name the exact item, decision, or deliverable. Good: "the revised project timeline I sent on February 20." Bad: "my previous email."
2. **Anchor with dates, not duration.** Prefer "I sent the proposal on February 15" over "I sent the proposal two weeks ago." Dates are factual; durations carry implicit judgment.
3. **Reference the action needed, not the silence.** Good: "I'd love your feedback on the three scope options." Bad: "I haven't heard back from you."
4. **Provide a reason for timing.** Explain why the follow-up is happening now: a deadline is approaching, a dependency exists, or a decision window is closing. This reframes the nudge as helpful, not nagging.
5. **Summarize, do not repeat.** Never paste or paraphrase the entire original email. A one-sentence summary is sufficient. If the recipient needs the full context, they can scroll down in the thread.

### Context Reference Templates

Use these as starting patterns and adapt to the specific situation:

- **Proposal/deliverable**: "Following up on the [deliverable name] I shared on [date] -- specifically looking for your input on [specific aspect]."
- **Decision needed**: "Circling back on the [topic] -- you mentioned you'd have a decision by [date they mentioned], and I wanted to check in."
- **Information request**: "Still looking for [specific information] to [reason it's needed]. I originally reached out on [date]."
- **Approval/sign-off**: "The [document/item] is ready for your review. I sent it over on [date] and wanted to make sure it's on your radar."
- **Meeting/call request**: "I'd still love to find time to discuss [topic]. Are any of the times I suggested on [date] working for you, or should I send fresh options?"

## Call-to-Action Patterns

Every nudge must end with a clear, actionable request. Choose one pattern per nudge -- do not stack multiple CTAs.

### Pattern 1: Ask a Specific Question

Reduce the cognitive load of responding by asking a narrow, answerable question rather than an open-ended one.

- Good: "Would Option A or Option B work better for your team?"
- Good: "Can you confirm the budget is still $50K, or has that changed?"
- Bad: "What are your thoughts?" (too vague, easy to defer)
- Bad: "Let me know!" (no specific action)

Use when: the original email contained multiple options or a complex ask that may feel overwhelming.

### Pattern 2: Propose a Next Step

Remove ambiguity by suggesting a concrete action the recipient can simply approve or reject.

- Good: "I'll plan to move forward with the March 15 timeline unless I hear otherwise by Friday."
- Good: "Happy to set up a 15-minute call this week to walk through the details -- would Wednesday or Thursday work?"
- Bad: "Let me know how you'd like to proceed." (shifts all decision-making back to recipient)

Use when: the follow-up has stalled because the recipient may not know what to do next.

### Pattern 3: Set a Soft Deadline

Introduce a time boundary that creates gentle urgency without an ultimatum.

- Good: "If I can get your feedback by Friday, I can still hit the March 1 launch date."
- Good: "I'll need to finalize the vendor list by end of next week -- your recommendation would be really valuable before then."
- Bad: "I need this by Friday." (no reason given, feels like a demand)
- Bad: "Please respond at your earliest convenience." (no actual deadline, easily ignored)

Use when: a real dependency or timeline exists that makes the deadline genuine, not manufactured.

### Matching CTAs to Escalation Levels

| Level | Preferred CTA Pattern | Rationale |
|-------|----------------------|-----------|
| 1 (Gentle) | Ask a Specific Question | Low pressure, easy to respond to |
| 2 (Firm) | Propose a Next Step | Moves the conversation forward without waiting |
| 3 (Urgent) | Set a Soft Deadline | Creates accountability with a clear timeline |

## Anti-Patterns

Avoid these common mistakes that undermine the effectiveness of follow-up emails or damage relationships.

### Never: "Just checking in" without context

The phrase "just checking in" is acceptable only when followed immediately by a specific reference. On its own, it communicates nothing and is easy to ignore.

- Bad: "Just checking in! Let me know."
- Good: "Checking in on the contract revisions -- were you able to review the updated terms in Section 3?"

### Never: "Per my last email"

This phrase is universally interpreted as passive-aggressive. It implies the recipient should have already responded and did not. Replace with a neutral restatement.

- Bad: "Per my last email, the deadline is Friday."
- Good: "The deadline for the deliverable is this Friday, March 7."

### Never: "As I mentioned" / "As previously stated"

Same problem as "per my last email." These phrases center the sender's prior communication rather than the recipient's needs.

- Bad: "As I mentioned, we need the signed contract before we can begin."
- Good: "We'll be ready to kick off as soon as we have the signed contract."

### Never: Ultimatums on first nudge

Escalation language is earned through prior attempts. A first follow-up should never include consequences, deadlines framed as threats, or escalation mentions.

- Bad (Level 1): "If I don't hear back by Friday, I'll need to escalate this."
- Good (Level 1): "Would love to get your thoughts when you have a moment."

### Never: Apologize for following up

Opening with "Sorry to bother you" or "I hate to be a pest" undermines the legitimacy of the follow-up. The sender has a valid reason to follow up -- frame it that way.

- Bad: "Sorry to bother you again, but..."
- Good: "Following up on the timeline discussion -- I want to make sure we're aligned before the team meeting Thursday."

### Never: Guilt-trip or track silence duration

Avoid language that emphasizes how long the recipient has been silent or how many times the sender has reached out (except at Level 3 where stating the number of attempts is factual, not guilt-inducing).

- Bad: "I've now emailed you three times over the past two weeks with no response."
- Good (Level 3): "This is my third follow-up on the scope approval. I'd like to resolve this by Friday so we can keep the project on schedule."

### Never: CC escalation without warning

Do not CC a recipient's manager or senior stakeholder without first warning the recipient directly. At Level 3, state the intent: "If I don't hear back by [date], I'll reach out to [person] to help move this forward."

## Email Structure Template

Apply this structure for all nudge emails, adjusting length and tone per escalation level and relationship type:

```
Subject: [Formatted per Subject Line Handling rules]

[Greeting -- first name, appropriate formality]

[Context anchor -- 1 sentence referencing original email with date and specific ask]

[Escalation-appropriate body -- see Escalation Levels section for sentence count and tone]

[Call to action -- single CTA matching the escalation level]

[Warm close -- relationship-appropriate sign-off]

[Signature]
```

## Edge Cases

- **Original email had no clear ask**: When the original email was informational and a response was only implicitly expected, frame the nudge around confirming receipt or alignment: "Wanted to confirm you saw the updated timeline -- any concerns before we proceed?"
- **Recipient replied but did not answer the question**: Do not treat this as a non-response. Reference the reply and restate only the unanswered portion: "Thanks for the update on the budget. I still need your sign-off on the vendor selection -- could you take a look at the three options I outlined?"
- **Multiple recipients on the original email**: Address the nudge to the primary decision-maker only. Do not Reply All unless necessary. Name the specific person whose input is needed.
- **The sender's own deadline has passed**: When the sender promised a follow-up by a certain date and is now late, acknowledge it briefly: "Apologies for the delayed follow-up -- here's the analysis I mentioned." Then proceed with the ask.
- **Recipient is known to be out of office**: Do not send a nudge during a known OOO period. Queue the nudge for the recipient's return date + 1 business day. Note in the follow-up: "I held off while you were out -- now that you're back, I wanted to resurface this."
- **Thread has become stale (30+ days)**: Start a fresh email thread rather than replying to the old one. Reference the original conversation by date and topic but do not use `Re:` on a month-old thread. Subject: "[Follow-up] [Original Topic] from [Month]".
- **Cross-timezone recipients**: When composing nudges for recipients in significantly different time zones, note the timezone context in deadline language: "by end of day Friday your time" rather than an ambiguous "by Friday."
- **No relationship type detected**: Default to the Client tone (professional/warm). It is safer to be slightly too formal than too casual.
