---
name: Follow-Up Detection
description: "Identifies sent emails awaiting replies and detects promises in email threads. Activates when the user wants to check follow-ups, find unanswered emails, track pending responses, or asks 'who hasn't gotten back to me?' Scans sent mail, detects bidirectional promises, scores urgency by age and relationship importance, and filters noise via smart exclusion rules."
globs:
  - "commands/followup-check.md"
  - "commands/followup-nudge.md"
  - "commands/followup-remind.md"
---

## Overview

Scan the user's Gmail sent folder to identify emails that require follow-up attention. Detect three categories of follow-up candidates: sent emails awaiting a reply, outbound promises the user made, and inbound promises others made to the user. For each candidate, determine thread reply status, calculate age in days, apply exclusion rules to filter noise, and assign a priority score from 1 to 5. Produce a structured follow-up list ordered by priority descending, then by age descending. This skill operates as the detection and scoring layer only -- it does not draft nudge emails or create calendar reminders (those responsibilities belong to the nudge-writing skill and the respective commands).

## Sent Email Scanning

Identify emails where the user sent the last message in a thread and no reply has arrived. This is the primary detection method and produces the highest volume of follow-up candidates.

### Query Strategy

1. Search Gmail for messages in the user's sent folder. Default lookback window: 30 days. Respect the `--days` or `--since` flag when provided by the command layer.
2. For each sent message, retrieve the full thread to determine whether a reply exists after the user's message.
3. Group messages by thread ID. Within each thread, sort messages by date ascending.
4. Identify the most recent message in each thread. If the most recent message was sent by the user (sender matches the user's email address), flag the thread as "awaiting reply."
5. Exclude threads where the most recent message is from someone other than the user -- those threads have received a reply and need no follow-up.

### Sent Message Fields to Extract

For each flagged thread, extract:

- **thread_id**: Gmail thread ID (unique key for deduplication).
- **subject**: Email subject line, stripped of "Re:" and "Fwd:" prefixes.
- **recipient**: Primary To-address of the user's sent message. When multiple recipients exist, use the first address in the To field.
- **sent_date**: ISO date (YYYY-MM-DD) of the user's most recent message in the thread.
- **days_waiting**: Integer count of calendar days between sent_date and today.
- **snippet**: First 120 characters of the user's sent message body (for context display).
- **has_question**: Boolean indicating whether the sent message contains a direct question (ends with "?" or contains question patterns like "Can you", "Could you", "Would you", "Do you", "Are you", "Will you", "Have you").

Threads where `has_question` is true receive a +1 priority boost because the user explicitly requested information.

## Thread Reply Detection

Determine whether a reply has been received for a tracked thread. This check runs both during initial scanning and during re-runs to resolve previously flagged follow-ups.

### Detection Logic

1. Fetch the full thread by thread_id from Gmail.
2. Sort all messages in the thread by internal date ascending.
3. Locate the user's most recent sent message by matching the sender address against the user's configured email.
4. Check whether any message exists in the thread with an internal date after the user's sent message AND a sender address that does not match the user's email.
5. If such a message exists, the thread has received a reply. Mark the follow-up as resolved. Set `status: "Done"` in Notion if a tracker record exists.
6. If no such message exists, the thread remains in "Waiting" status.

### Re-Run Idempotency

On subsequent runs, query existing Notion records in the "[FOS] Tasks" database filtered by `Type = "Follow-Up"` and matching Thread ID. For threads already tracked:
- If a reply has since arrived, update Status to "Done" and recalculate Days Waiting.
- If still awaiting reply, update Days Waiting and recalculate Priority.
- Never create duplicate records for the same thread_id. Use thread_id as the unique key.

## Bidirectional Promise Detection

Scan email thread content for explicit commitments -- both promises the user made to others (outbound) and promises others made to the user (inbound). Promise detection supplements the sent-email scanning by catching obligations that standard "awaiting reply" logic misses.

### Pattern Matching

Scan sent messages for commitment language across four categories: delivery commitments, response commitments, action commitments, and temporal commitments. Scan received messages for the same categories plus deferral language (high follow-up signal). For the complete pattern library with specific phrases for each category, see `${CLAUDE_PLUGIN_ROOT}/skills/followup/follow-up-detection/references/promise-patterns.md`.

When a temporal commitment accompanies a promise, extract the implied deadline and factor it into the priority score. A missed deadline elevates priority by +1 (cap at 5).

### Promise Classification

Label each detected promise with a Promise Type:

- **"Promise Made"**: Outbound promise detected in the user's sent message. The user owes an action.
- **"Promise Received"**: Inbound promise detected in a received message. Someone else owes an action.
- **"Awaiting Response"**: No explicit promise language, but the user sent the last message and expects a reply. This is the default type for standard sent-email scanning results.

A single thread may contain both outbound and inbound promises. Create separate follow-up entries for each distinct promise when they represent different obligations.

## Age-Based Priority Tiers

Assign a base priority tier based on the number of days the email has been awaiting a reply or the promise has been outstanding:

| Days Waiting | Tier | Label | Base Priority |
|-------------|------|-------|---------------|
| 1-2 days | Fresh | No action needed yet | 1 |
| 3-6 days | Gentle | Polite follow-up appropriate | 2 |
| 7-13 days | Firm | Direct follow-up recommended | 3 |
| 14-20 days | Urgent | Escalation may be needed | 4 |
| 21+ days | Critical | At risk of being lost entirely | 5 |

The base priority from the age tier serves as the starting point. Apply the modifiers from the Priority Scoring section below to arrive at the final score.

## Exclusion Rules

Filter out threads that should never appear in the follow-up list. Apply exclusion rules before promise detection and priority scoring to avoid wasted processing.

### Address-Based Exclusions

Exclude threads where the recipient matches any of these patterns:

- **No-reply addresses**: Any address containing "noreply", "no-reply", "no_reply", "donotreply", or "do-not-reply" (case-insensitive).
- **Automated senders**: Addresses from known automation domains: `notifications@`, `alerts@`, `system@`, `mailer-daemon@`, `postmaster@`, `support@` (when part of a ticketing system auto-reply).
- **Service addresses**: Generic service addresses like `billing@`, `receipts@`, `orders@`, `shipping@`, `tracking@` from commercial domains.

### Content-Based Exclusions

Exclude threads matching these content patterns:

- **Newsletter unsubscribes**: Threads where the user's sent message consists solely of an unsubscribe request or reply to a newsletter.
- **Auto-replies**: Threads where the user's sent message is an out-of-office auto-reply (detected by `X-Auto-Reply` header or body containing "out of office", "automatic reply", "auto-response").
- **Transactional confirmations**: Threads where the user's sent message is a brief confirmation ("Thanks", "Got it", "Received", "Acknowledged") with no question or promise. Detect single-sentence replies under 20 words containing only acknowledgment language.
- **Mailing list messages**: Threads with `List-Unsubscribe`, `List-Id`, or `Precedence: bulk` headers.
- **Calendar invitations**: Threads that are calendar event responses (accept/decline/tentative) identified by MIME type `text/calendar` or content containing "calendar notification".

### Override Mechanism

When the user explicitly includes a thread via `--include [thread_id]`, bypass all exclusion rules for that thread. The user's explicit intent overrides automatic filtering.

## Priority Scoring

Calculate a final priority score from 1 (low) to 5 (critical) for each follow-up candidate. Start with the age-based base priority and apply modifiers.

### Scoring Factors

Four factors influence the final score. Each factor adds or subtracts from the base priority:

**1. Age Factor (Base Priority)**
Determined by the age-based priority tiers table above. This is the starting value.

**2. Relationship Importance (+0 to +2)**
Assess the importance of the recipient or sender based on available signals:
- +2 if the contact appears in the user's VIP list (when Inbox Zero VIP data is available via the `#01 Inbox Zero → #06 Follow-Up Tracker` chain).
- +1 if the contact is associated with an active deal or client in Notion CRM (when Notion is available).
- +1 if the contact has appeared in 5 or more email threads with the user in the past 90 days (high-frequency correspondent).
- +0 for contacts with no special relationship signals.
- Apply the highest single relationship modifier, not cumulative. Maximum relationship boost: +2.

**3. Promise Urgency (+0 to +1)**
- +1 if the thread contains an explicit promise (either direction) with a temporal commitment whose deadline has passed.
- +1 if the thread contains a question (has_question is true) that remains unanswered.
- +0 if no promise deadline exists or the deadline is still in the future.
- Apply the highest single promise modifier. Maximum promise boost: +1.

**4. Thread Activity (-1 to +0)**
- -1 if the thread has had recent activity (a non-reply message from the user, such as a forwarded FYI) within the last 2 days, suggesting the relationship is active and a nudge may be premature.
- +0 if no recent thread activity exists.

### Final Score Calculation

```
final_priority = clamp(base_priority + relationship_modifier + promise_modifier + activity_modifier, 1, 5)
```

Always clamp the result to the 1-5 range. Never produce a score below 1 or above 5.

### Priority Output Labels

Attach a human-readable label to each score:

| Score | Label |
|-------|-------|
| 5 | Critical -- follow up immediately |
| 4 | Urgent -- follow up today |
| 3 | Firm -- follow up this week |
| 2 | Gentle -- follow up when convenient |
| 1 | Low -- monitor only |

## Follow-Up Item Structure

Produce one structured object per detected follow-up candidate:

- **thread_id**: Gmail thread ID (unique key).
- **subject**: Email subject line, cleaned of "Re:"/"Fwd:" prefixes.
- **recipient**: Primary recipient email address (for sent-email items) or sender address (for inbound promise items).
- **sent_date**: ISO date (YYYY-MM-DD) of the relevant message.
- **days_waiting**: Integer days since the relevant message was sent.
- **priority**: Final score 1-5 after all modifiers.
- **priority_label**: Human-readable label matching the score.
- **promise_type**: One of "Awaiting Response", "Promise Made", "Promise Received".
- **promise_text**: The extracted promise phrase from the email body, or null if promise_type is "Awaiting Response".
- **has_question**: Boolean indicating whether the user's message contained a direct question.
- **snippet**: First 120 characters of the relevant message body.
- **status**: One of "Waiting", "Done". Internal plugin states map as follows: Awaiting Reply → Waiting, Nudge Sent → Waiting, Resolved → Done, Expired → Done.
- **nudge_count**: Number of nudges previously sent (0 for new items).
- **source**: One of "Sent Mail" or "Promise Detected".

## Inbox Zero Integration

When the `#01 Inbox Zero Commander` plugin is available, leverage its triage data to enrich follow-up detection:

- Query the "[FOS] Tasks" database (or legacy "Inbox Zero - Action Items") filtered by `Type = "Email Task"` for items with category `waiting_on`. These represent threads Inbox Zero already identified as awaiting a response. Cross-reference by thread subject or email address to avoid duplicating entries.
- Import VIP sender list from Inbox Zero's configuration for relationship importance scoring.
- When a thread exists in both Inbox Zero's `waiting_on` list and the Follow-Up Tracker's scan results, prefer the Follow-Up Tracker's richer metadata (promise detection, age scoring) but note the cross-reference.

When Inbox Zero is not available, operate independently using Gmail data only. Never fail because the upstream plugin is missing.

## Notion Task Creation

### Database Discovery

1. Search Notion for a database named **"[FOS] Tasks"** (the consolidated tasks database).
2. If not found, try **"Founder OS HQ - Tasks"**.
3. If not found, fall back to the legacy database named "Follow-Up Tracker - Follow-Ups".
4. If none is found, degrade gracefully (see Graceful Degradation below). Do **not** lazy-create the database — the HQ database is provisioned centrally.

### Writing Records

1. For every follow-up record, set these HQ-specific fields:
   - **Type** (select): `"Follow-Up"`
   - **Source Plugin** (select): `"Follow-Up Tracker"`
2. Map plugin fields to HQ columns:
   - Subject → **Title** (title property)
   - Thread ID → **Thread ID** (rich_text — unique key for deduplication)
   - Recipient → **Contact** (relation to CRM Pro Contacts database). Match recipient email against CRM Pro Contacts by email property. If no match is found, fall back to storing the email address in a **Recipient** rich_text property.
   - **Company** (relation to CRM Pro Companies database): When the recipient's email domain matches a Company domain in CRM Pro, set this relation. Skip silently when no match is found.
   - Sent Date → **Sent Date** (date)
   - Days Waiting → **Days Waiting** (number)
   - Priority → **Priority** (number)
   - Promise Type → **Promise Type** (select: Awaiting Response / Promise Made / Promise Received)
   - Nudge Count → **Nudge Count** (number)
   - Last Nudge Date → **Last Nudge Date** (date)
   - Source → **Source** (select: Sent Mail / Promise Detected)
3. **Status mapping** — translate plugin statuses to HQ statuses:
   - Awaiting Reply → **Waiting**
   - Nudge Sent → **Waiting** (with Nudge Count incremented)
   - Resolved → **Done**
   - Expired → **Done** (with a note "[Expired — no reply after 30 days]")
4. Set default Status to "Waiting" and Nudge Count to 0 for new records.
5. Use Thread ID as the unique key. On re-runs, update existing records rather than creating duplicates.
6. Mark items as "Done" with note "[Expired — no reply after 30 days]" when days_waiting exceeds 30 and no nudge has been sent. Expired items remain in the database for audit purposes but are excluded from the active follow-up list displayed to the user.
7. After creating or updating records, display results with Notion page links.

### Reading Records

When querying the database for existing follow-ups (re-run deduplication, nudge history, etc.), **always** apply a compound filter:
- `Type = "Follow-Up"` **AND** the relevant query conditions (e.g., Thread ID match, Status = "Waiting")

This ensures the plugin only reads its own records and never collides with tasks from other plugins sharing the HQ database.

## Graceful Degradation

If Notion MCP is unavailable, or none of "[FOS] Tasks", "Founder OS HQ - Tasks", or the legacy "Follow-Up Tracker - Follow-Ups" database is found, output the follow-up list as structured text in chat. Include all fields. Warn: "Notion unavailable -- displaying results in chat. Follow-ups were not saved to the tracker database."

If Google gws CLI is unavailable for Calendar, skip reminder creation silently. Calendar reminders are an optional enhancement, not a core requirement.

If Gmail returns an error or rate limit, report the error clearly and suggest retrying with a narrower date range: "Gmail API error -- try narrowing the search window with --days=7."

## Edge Cases

### Empty Sent Folder
When no sent messages exist in the lookback window, report: "No sent emails found in the last [N] days. Nothing to track." Do not fabricate results.

### High-Volume Senders
When the user has more than 200 sent threads in the lookback window, process in batches of 50. Display a progress indicator ("Scanning batch 1 of 4..."). Apply exclusion rules early to reduce the working set before promise detection.

### Self-Sent Emails
Exclude threads where the only recipient is the user's own email address (notes-to-self). These never require follow-up.

### Shared Mailbox / Alias Detection
When the user sends from multiple addresses or aliases, treat all configured addresses as "the user." Match sender against all known aliases when determining whether the user sent the last message. If aliases are not configured, match against the primary Gmail address only.

### Thread with Multiple Recipients
When a sent email has multiple To/CC recipients, track the thread once with the primary To recipient. Do not create separate follow-up entries per recipient unless the user explicitly requests per-recipient tracking via `--per-recipient`.

### Already-Resolved Threads
When a thread receives a reply between scan runs, detect the reply during the next run and update the status to "Done." Do not generate a nudge recommendation for resolved threads even if they previously had high priority.

### Promise Without Context
When promise language is detected but the surrounding context is ambiguous (e.g., "I'll look into it" in a thread about multiple topics), extract the promise text verbatim and set promise_type accordingly, but append to the snippet: "[Promise context unclear -- verify before nudging]".
