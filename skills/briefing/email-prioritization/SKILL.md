---
name: Email Prioritization
description: "Scans unread emails and produces prioritized highlights using the Eisenhower urgent/important matrix. Activates for inbox highlights, email summaries, morning email scans, or any request to understand what's important in the inbox right now. Scores by sender importance, keywords, action flags, and recency — surfaces up to 10 highlights grouped by quadrant."
globs:
  - "teams/agents/gmail-agent.md"
---

## Overview

Scan all unread emails and produce a prioritized highlight list for inclusion in the daily briefing. Apply the Eisenhower urgent/important matrix to classify each unread message, score it using sender importance, subject keyword signals, action-required flags, recency weighting, and thread activity. Extract a structured highlight for each high-priority email and return up to 10 highlights grouped by quadrant. Feed the resulting highlight list to the briefing assembly step -- this skill handles classification and extraction only, not final briefing formatting.

## The Urgent/Important Matrix

Classify every unread email into exactly one quadrant. Use the quadrant assignment to determine whether the email surfaces in the briefing highlights and in what order.

### Q1: Urgent AND Important (Surface First)

Reserve Q1 for emails that demand same-day action AND carry significant consequences if ignored. Look for:
- Client escalations, complaints, or service disruptions.
- Items due today or already overdue (deadlines within 24 hours).
- Revenue-impacting messages: signed proposals, payment issues, deal-closing communications.
- Emails from the boss, leadership, or board members requiring a direct response.
- Legal, compliance, or security alerts.

Always surface Q1 emails in the briefing. Mark every Q1 item with "Action needed: yes" and specify the action.

### Q2: Important, Not Urgent (Surface Second)

Assign Q2 to emails with strategic weight but no same-day deadline pressure. Look for:
- Strategic discussions about quarterly goals, product direction, or team planning.
- Project milestone updates, status reports, and review requests.
- Partnership or business development inquiries from credible senders.
- Hiring or organizational changes affecting the user's team.
- Proposals or contracts in negotiation that do not expire today.

Surface Q2 emails after all Q1 items. Mark action needed only when an explicit request is present.

### Q3: Urgent, Not Important (Surface Only When Few Highlights)

Assign Q3 to time-sensitive emails that carry low strategic weight. Look for:
- Meeting confirmations and calendar RSVPs needing response.
- Routine approval requests (expense reports, PTO, access grants).
- CC'd threads with active replies but no direct request to the user.
- Administrative reminders with near-term deadlines (surveys, form submissions).

Do not surface Q3 emails in the briefing unless the total Q1 + Q2 count is fewer than 5. When included, place them after all Q2 items.

### Q4: Not Urgent, Not Important (Exclude from Briefing)

Assign Q4 to emails with no impact on current priorities. Look for:
- Marketing emails, promotional offers, and sales outreach.
- Newsletter digests and automated platform notifications.
- Social media alerts (LinkedIn, Twitter, GitHub stars).
- Internal announcements with no action required (office closures, parking updates).
- Automated build/deploy notifications with success status.

Never surface Q4 emails in the briefing highlights. Include them only in the aggregate unread count.

## Priority Scoring Signals

Apply these signals to determine the quadrant assignment. Evaluate each signal independently, then use the combined signal profile to select the best-fit quadrant.

### Sender Importance

Classify the sender into tiers. Use any available context from CRM data, prior interactions, or the user's contact list.

| Tier | Examples | Weight |
|------|----------|--------|
| Tier 1: Key clients | Known client contacts, accounts with active deals or projects | High |
| Tier 2: Leadership | Direct manager, C-suite, board members | High |
| Tier 3: Direct reports | Team members who report to the user | Medium |
| Tier 4: External VIPs | Investors, advisors, key partners, high-value prospects | Medium |
| Tier 5: Known internal | Colleagues, cross-functional peers | Low |
| Tier 6: Unknown external | First-time senders, cold outreach | Low |

Tier 1 and Tier 2 senders push the email toward Q1 or Q2 unless the content is clearly low-value (e.g., a VIP forwarding a newsletter with no commentary).

### Subject Keyword Signals

Scan the subject line and first 200 characters of the body for these keyword categories. Perform case-insensitive whole-word matching.

**Urgency keywords** (push toward Q1 or Q3):
- "urgent", "ASAP", "deadline", "overdue", "time-sensitive", "immediate", "EOD", "end of day", "expires today", "final notice"

**Importance keywords** (push toward Q1 or Q2):
- "action required", "approval needed", "please review", "signature required", "invoice", "proposal", "contract", "escalation", "blocking", "critical"

**Low-priority keywords** (push toward Q3 or Q4):
- "FYI", "no action needed", "for your records", "newsletter", "digest", "unsubscribe", "weekly update", "automated notification"

Apply keyword signals as modifiers, not overrides. A "newsletter" subject from a Tier 1 client still warrants review -- classify it as Q2 rather than Q4.

### Action-Required Flags

Detect explicit requests directed at the user:
- Direct questions: sentences ending in "?" where the user is addressed by name or as the sole recipient.
- Explicit asks: "please", "can you", "need you to", "would you", "could you" followed by a verb.
- Calendar invites requiring RSVP (pending invites with no response recorded).
- Approval workflows: emails containing "approve", "reject", "sign off", "authorize."

Mark any email with a detected action-required flag as "Action needed: yes" and extract a one-phrase description of the required action.

### Recency Weighting

Apply a recency multiplier to break ties within the same quadrant:
- **Last 4 hours**: Weight 1.0 (full recency).
- **4-12 hours ago**: Weight 0.8.
- **12-24 hours ago**: Weight 0.6.
- **Older than 24 hours**: Weight 0.4.

Use recency only for ordering within a quadrant, never to promote an email to a higher quadrant. A 3-day-old Q1 email still ranks above a 1-hour-old Q2 email.

### Thread Depth

Evaluate thread activity as an engagement signal:
- **3+ unread messages in the same thread**: Active discussion requiring attention. Treat as a single highlight entry using the latest message.
- **Long thread (10+ messages) with a recent reply**: Ongoing conversation -- check whether the latest reply contains a direct request.
- **Single-message thread**: Evaluate on content alone without thread boost.

Threads with high activity from Tier 1-2 senders push toward Q1 or Q2. Threads with high activity from Tier 5-6 senders push toward Q3 at most.

## Highlight Extraction Rules

For each email that qualifies for the briefing, extract a structured highlight record.

### Fields to Extract

| Field | Description | Format |
|-------|-------------|--------|
| Sender | Display name and email address | "Jane Smith (jane@acme.com)" |
| Subject | Full subject line, truncated at 80 characters | Plain text |
| Summary | One-line summary of the email's core content | Max 100 characters, plain text |
| Quadrant | Assigned matrix quadrant | Q1, Q2, or Q3 |
| Action Needed | Whether the user must take action | "Yes: [action phrase]" or "No" |
| Recency | When the email arrived | Relative timestamp ("2h ago", "yesterday") |
| Thread Count | Number of unread messages in the thread | Integer (1 if standalone) |

### Summary Generation Rules

Generate the one-line summary by:
1. Extracting the first substantive sentence from the email body (skip greetings, pleasantries, and quoted text).
2. If the first sentence exceeds 100 characters, truncate at the nearest word boundary and append "...".
3. If the email body is empty or contains only an attachment, use "Attachment: [filename]" or "Empty body -- subject only."
4. For calendar invites, use "Meeting invite: [event title] on [date/time]."
5. For forwarded emails, summarize the forwarding sender's intent, not the forwarded content.

### Highlight Limits

- Extract a maximum of **10 highlights** for the briefing.
- Fill from Q1 first (all Q1 emails, up to 10).
- Then fill remaining slots with Q2 emails, ordered by sender tier then recency.
- Include Q3 emails only if Q1 + Q2 total fewer than 5. Fill remaining slots (up to 10 total) with Q3, ordered by recency.
- Never include Q4 emails in the highlights.
- When more than 10 emails qualify for Q1 alone, include the top 10 by sender tier then recency, and append a note: "N additional urgent emails not shown."

### Thread Deduplication

When multiple unread messages belong to the same thread:
- Count them as a single highlight entry.
- Use the latest message in the thread for summary extraction.
- Set Thread Count to the number of unread messages in the thread.
- Use the arrival time of the latest message for recency weighting.

## Output Format

Return the highlight list as a structured block for the briefing assembly agent. Use this format:

```
## Email Highlights

**Unread total**: [N] emails ([M] threads)
**Highlights**: [count] shown of [total qualifying]

### Q1: Urgent & Important
1. **[Subject]** -- [Sender]
   [Summary] | Action: [Yes: action phrase / No] | [Recency] | Thread: [count]

2. ...

### Q2: Important
3. **[Subject]** -- [Sender]
   [Summary] | Action: [Yes: action phrase / No] | [Recency] | Thread: [count]

4. ...

### Q3: Time-Sensitive (included because fewer than 5 Q1+Q2 items)
5. ...
```

Omit the Q3 section header entirely when no Q3 items are included. Omit the Q2 section header when no Q2 items are included.

After the highlights, include a **Quick Stats** footer:

```
**Quick Stats**: Q1: [n] | Q2: [n] | Q3: [n] | Q4: [n] | Total unread: [N]
```

## Graceful Degradation

Handle reduced data availability without failing:

- **Fewer than 10 unread emails**: Report all qualifying emails as highlights. Do not pad the list or invent content. Adjust the "shown of total" count accordingly.
- **Zero unread emails**: Skip the entire email highlights section. Return a single line: "Inbox zero -- no unread emails to report." Allow the briefing assembly agent to omit or note this section.
- **All unread emails are Q4**: Return no highlights. Report: "No actionable emails found. [N] unread newsletters/notifications in inbox." Provide the Quick Stats footer showing all items in Q4.
- **gws CLI unavailable**: Return: "Email highlights unavailable -- gws CLI not installed or not authenticated." Mark the email section status as "unavailable" in the briefing metadata. Do not block the rest of the briefing pipeline.
- **Partial Gmail results** (API timeout or rate limit): Process whatever emails were retrieved. Append a note: "Partial results -- [N] emails scanned of estimated [M] unread." Flag the briefing metadata accordingly.

## Edge Cases

### Threads with Multiple Unread Messages
Collapse the thread into a single highlight. Use the latest message for all extracted fields except Thread Count, which reflects the total unread count in the thread. Apply the highest applicable quadrant from any message in the thread -- if one message is Q2 but the latest reply is Q1, classify the thread highlight as Q1.

### Calendar Invites in Email
Treat pending calendar invites (those awaiting RSVP) as Q3 minimum. Promote to Q2 if the invite sender is Tier 1-2 or the event is within 24 hours. Extract the event title, date, and time into the summary field instead of the email body text.

### Automated Notifications with Failure Alerts
Distinguish between success notifications (Q4) and failure/error alerts (Q2 or Q1). A CI/CD failure notification for a production deployment is Q1. A successful nightly backup notification is Q4. Look for keywords: "failed", "error", "down", "alert", "warning", "outage" to detect failures.

### Emails in Foreign Languages
Extract highlights using the original language for sender and subject. Generate the summary in English regardless of the source language. Note the detected language in parentheses after the summary if it is not English.

### Emails with Only Attachments
When the body is empty or contains only "See attached" / "Please find attached":
- Use the attachment filename as the summary: "Attachment: quarterly-report-Q4.pdf"
- Check the sender tier and attachment type to determine the quadrant. A Tier 1 client sending a PDF contract is Q2 at minimum.

### Reply-All Storms
When a thread accumulates 5+ messages within 1 hour from 3+ distinct senders and the content is repetitive (acknowledgments, "+1", "thanks"), collapse to a single Q4 highlight and exclude from the briefing. Note in Quick Stats: "1 reply-all storm excluded ([N] messages)."
