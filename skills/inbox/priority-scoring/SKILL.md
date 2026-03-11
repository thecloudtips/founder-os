---
name: Priority Scoring
description: "Assigns priority scores (1-5) to emails using an Eisenhower matrix framework. Activates when the user wants to rank, score, or prioritize emails, figure out what's urgent, or understand why an email got a certain priority — including VIP boost logic, keyword detection, and spam overrides."
globs:
  - "teams/agents/triage-agent.md"
---

## Overview

Assign a priority score from 1 to 5 to each email using the Eisenhower matrix framework. Treat higher scores as more important and more urgent. Use this rubric to ensure every email in the triage pipeline receives a consistent, explainable priority level. Feed the resulting score into downstream actions: routing, summarization, and response drafting. Apply the score after category assignment so that category context informs the priority determination.

## The Eisenhower Matrix Applied to Email

### Priority 5: Urgent AND Important (Do First)

Reserve this level for emails that demand immediate action AND carry significant consequences if ignored. Look for explicit deadlines within 24 hours, client-facing commitments at risk, legal or financial exposure, and escalation language such as "escalating to leadership" or "final notice." Assign priority 5 when delay would cause measurable harm.

Examples:
- "Contract expires today -- signature required before 5 PM"
- "Client meeting in 2 hours needs updated deck"
- "Payment of $12,000 due by EOD or late fees apply"

Typical category: `action_required`.

### Priority 4: Important, Not Urgent (Schedule)

Assign this level to emails with significant strategic impact but no immediate deadline pressure. Identify requests tied to project milestones, quarterly planning, relationship-building outreach from key contacts, and proposals requiring thoughtful response. Schedule these for focused work blocks rather than reactive handling.

Examples:
- "Quarterly review materials needed by next Friday"
- "Strategy proposal for Q2 -- would love your input this week"
- "Partnership opportunity worth exploring when you have bandwidth"

Typical categories: `action_required`, `waiting_on`.

### Priority 3: Urgent, Not Important (Delegate/Quick Handle)

Assign this level to time-sensitive emails that carry low strategic weight. Recognize routine approvals, quick confirmations, scheduling requests, and administrative tasks that someone else could handle or that require less than two minutes to complete. Process these in batches to avoid context-switching.

Examples:
- "Please confirm your attendance at tomorrow's standup"
- "Approve this purchase order for office supplies"
- "Sign the NDA so we can proceed with the vendor call"

Typical categories: `action_required`, `fyi`.

### Priority 2: Neither Urgent Nor Important (Consider Archiving)

Assign this level to emails with low impact and no time pressure. Identify general team updates, low-priority FYI notifications, meeting notes from sessions you did not attend, and informational broadcasts. Flag these for batch review at the end of the day or archive directly if they add no value.

Examples:
- "Team outing planned for next month -- save the date"
- "Updated office policy on parking"
- "Meeting notes from last week's design review"

Typical categories: `fyi`, `newsletter`.

### Priority 1: Noise (Auto-Archive Candidate)

Assign this level to emails with no relevance to current work. Identify mass marketing blasts, irrelevant promotional offers, old thread notifications with no new substance, social media alerts, and spam-adjacent content. Recommend auto-archiving these without surfacing them in the daily summary.

Examples:
- "50% off sale -- today only!"
- "Your weekly digest from a platform you never use"
- "Someone liked your post on LinkedIn"

Typical categories: `promotions`, `newsletter`.

## VIP Boost Rule

Apply the VIP boost AFTER calculating the base Eisenhower score. Check the sender address and display name against the `user_preferences.vip_senders` list. If the sender matches any VIP entry, add +1 to the current priority score. Cap the result at 5 so that no email exceeds the maximum priority level.

Follow these rules strictly:
- Match against both email address and display name in the VIP list.
- Apply the boost exactly once per email regardless of how many VIP list entries the sender matches.
- Do not apply the VIP boost to emails already scored at priority 5 -- record the boost attempt but keep the score at 5.
- Log the boost for transparency: note "VIP boost applied: base X -> final Y" in the scoring rationale.

Examples:
- VIP sends a general FYI (base priority 2) -> boosted to priority 3.
- VIP sends an urgent deadline request (base priority 5) -> stays at priority 5 (capped).
- VIP sends a newsletter forward (base priority 2) -> boosted to priority 3.

## Priority Keywords

Check for priority keywords from `user_preferences.priority_keywords` in both the subject line and the email body. Apply a +1 boost if any keyword is found. Apply this boost BEFORE the VIP boost so that both boosts can stack, but enforce the cap of 5 on the final result.

Common default keywords to recognize:
- "urgent"
- "deadline"
- "invoice"
- "overdue"
- "ASAP"
- "critical"
- "blocking"
- "time-sensitive"
- "immediate"
- "action required"

Follow these rules for keyword detection:
- Perform case-insensitive matching.
- Match whole words only to avoid false positives (e.g., "urge" should not trigger "urgent").
- Apply the keyword boost only once per email regardless of how many keywords appear.
- Ignore keywords that appear only in quoted reply text or email signatures.
- Override the keyword boost for obvious spam: if the email is clearly promotional or spam despite containing a priority keyword, do not apply the boost.

## Scoring Process

Execute the following steps in order for each email:

1. Read the email subject, sender, body preview, and any available metadata (timestamp, thread length, attachments).
2. Determine the base priority (1-5) by mapping the email to the appropriate Eisenhower quadrant. Consider the assigned category as a strong signal but not an override.
3. Check the subject and body for priority keywords from `user_preferences.priority_keywords`. If at least one keyword is found and the email is not obvious spam, add +1 to the score.
4. Check the sender against `user_preferences.vip_senders`. If the sender matches, add +1 to the score.
5. Cap the final score at 5. No email may exceed priority 5 regardless of how many boosts apply.
6. Record the scoring breakdown for transparency: note the base score, whether a keyword boost was applied (and which keyword triggered it), and whether a VIP boost was applied.
7. Attach the final priority score to the email's triage metadata alongside the category and summary.

## Consistency Rules

Maintain predictable, repeatable scoring across the entire inbox:

- Assign the same base priority to emails of the same type from the same sender class. All newsletter digests from the same source receive the same base score. All scheduling confirmations from calendar tools receive the same base score.
- Respect the strong correlation between category and priority range:
  - `action_required`: typically priority 3-5.
  - `waiting_on`: typically priority 3-4.
  - `fyi`: typically priority 1-3.
  - `newsletter`: typically priority 1-2.
  - `promotions`: typically priority 1.
- Re-examine the category assignment if the priority score conflicts with these ranges. A newsletter scoring at priority 4 without any boosts suggests the category may be wrong.
- Do not let recency bias inflate scores. An email is not more urgent simply because it arrived most recently.
- Treat batch-processed emails identically to individually processed emails. The scoring rubric does not change based on processing mode.

## Edge Cases

Handle the following scenarios with explicit rules:

- **Spam with urgent language**: If an email contains "urgent" in the subject but is clearly spam or promotional, assign priority 1. Content analysis overrides keyword detection for obvious spam.
- **VIP sends a newsletter**: Assign the newsletter base score (typically 2), then apply the VIP boost. Result: priority 3. VIP status always earns a boost even on low-value content.
- **Multiple priority keywords**: Apply the keyword boost only once. Do not stack multiple keyword matches. Avoid artificially inflating scores through keyword stuffing.
- **Reply in old thread with new urgent content**: Score based on the latest message content, not the thread age or original subject. Parse the most recent reply body for priority signals.
- **Calendar invite from VIP**: Assign a minimum base priority of 4 for calendar invites from VIP senders. Scheduling requests from important contacts always warrant prompt attention.
- **Forwarded email**: Score based on the forwarding sender's intent and the forwarded content. If a VIP forwards a low-priority newsletter with a note saying "thoughts?", treat it as priority 4 (important, not urgent).
- **Auto-replies and out-of-office**: Assign priority 1 unless the auto-reply contains actionable information such as an alternate contact for an urgent matter.
- **Emails with attachments**: Do not boost priority solely because an attachment is present. Assess the email text on its own merits. Note the attachment in metadata for downstream agents.

## Scoring Examples Table

Use this reference table to calibrate scoring decisions:

| Scenario | Base | Keywords | VIP | Final |
|---|---|---|---|---|
| Client deadline email, no keywords, non-VIP | 5 | +0 | +0 | 5 |
| VIP sends general FYI | 2 | +0 | +1 | 3 |
| Newsletter containing "urgent" keyword | 2 | +1 | +0 | 3 |
| Promotional email, no keywords, non-VIP | 1 | +0 | +0 | 1 |
| Quick approval request, non-VIP | 3 | +0 | +0 | 3 |
| VIP deadline email with "critical" keyword | 5 | +0 | +0 | 5 (capped) |
| Non-VIP strategic proposal, no keywords | 4 | +0 | +0 | 4 |
| VIP scheduling request | 4 | +0 | +1 | 5 |
| Spam with "ASAP" in subject | 1 | +0 | +0 | 1 (spam override) |
| Auto-reply from VIP | 1 | +0 | +1 | 2 |
| Non-VIP invoice email with "overdue" keyword | 4 | +1 | +0 | 5 |
| Old thread, new urgent reply from non-VIP | 5 | +0 | +0 | 5 |

Apply this rubric consistently across all emails entering the Inbox Zero Commander pipeline. Surface the scoring breakdown in triage output so the user can audit and adjust thresholds over time.
