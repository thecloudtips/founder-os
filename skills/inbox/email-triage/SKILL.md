---
name: Email Triage
description: "Email classification and routing for inbox management. Use this whenever the user mentions email triage, sorting inbox, prioritizing messages, categorizing emails, or dealing with email overload — even if they don't say 'triage' explicitly. Also activates for questions about email categories, VIP handling, or archive rules. Powers the 5-category classification system with needs_response and archivable flags."
globs:
  - "teams/agents/triage-agent.md"
  - "teams/agents/archive-agent.md"
---

## Overview

Classify every incoming email into exactly one of 5 mutually exclusive categories. Assign two boolean flags to each email: `needs_response` and `archivable`. Never assign more than one category per email. Use the detection heuristics below in order of specificity -- when multiple categories could apply, prefer the category with the strongest signal. Treat category assignment, flag setting, and VIP handling as a single atomic operation; never output a partial classification.

## Categories

### action_required

Reserve this category for emails that require the user to perform a concrete action: reply, review, approve, sign, schedule, or complete a task.

Detect by scanning for:
- Direct questions addressed to the user ("Can you...?", "Will you...?", "Could you review...?")
- Explicit requests with imperative verbs ("Please approve", "Sign and return", "Complete the form")
- Deadlines or time-bound language ("by Friday", "before EOD", "due next week")
- Approval or sign-off requests ("Your approval is needed", "Awaiting your sign-off")
- Task assignments ("Assigned to you", "You've been added as reviewer")

Examples:
- "Can you review this by Friday?"
- "Please approve the attached invoice"
- "Your signature is needed on the contract"
- "I need your feedback on the Q3 budget before Monday"

### waiting_on

Assign this category when the user has already taken action and is waiting for someone else to respond or complete their part.

Detect by scanning for:
- Threads where the user sent the most recent message and no reply has arrived
- Language indicating pending action from others ("I'll get back to you", "Let me check and follow up", "Working on it")
- Pending approvals or requests the user submitted upstream
- Acknowledgment-only replies that imply forthcoming follow-up ("Got it, will review soon")

Examples:
- A proposal the user sent three days ago with no response
- A request the user submitted to finance awaiting approval
- A thread where the user asked a question and the recipient replied "Let me look into it"

### fyi

Assign this category to informational emails that require no action and no reply from the user.

Detect by scanning for:
- CC'd emails where the user is not in the To field
- Status updates and progress reports not requesting input
- Team-wide announcements and organizational notices
- Automated system notifications (build results, monitoring alerts, deployment confirmations)
- Shared documents or links provided "for your awareness"

Examples:
- "FYI -- project status update attached"
- Team-wide announcement about office hours changing
- Automated CI/CD build success notification
- Meeting notes shared for reference

### newsletter

Assign this category to subscription-based content, digests, and recurring informational mailings.

Detect by scanning for:
- Presence of an "Unsubscribe" link or footer
- Known newsletter sender addresses or domains (Substack, Mailchimp, ConvertKit, etc.)
- Recurring digest patterns (daily, weekly, monthly cadence from the same sender)
- Mailing list headers (`List-Unsubscribe`, `List-Id`, `Precedence: bulk`)
- Subject line patterns indicating digest content ("Weekly Roundup", "Your Daily Brief", "Issue #47")

Examples:
- Industry newsletter from a Substack publication
- Weekly company digest email
- Community forum summary email
- "Your weekly analytics report" from a SaaS tool

### promotions

Assign this category to marketing, sales, and commercial emails designed to sell, upsell, or drive a commercial action.

Detect by scanning for:
- Promotional subject lines containing discount language ("% off", "sale", "limited time", "exclusive offer", "free trial")
- Marketing sender domains or subdomains (marketing@, promo@, offers@)
- Commercial calls-to-action ("Shop now", "Claim your offer", "Upgrade today", "Buy now")
- Product launch announcements framed as sales opportunities
- Coupon codes, referral links, or affiliate tracking parameters in URLs

Examples:
- "50% off all plans -- this weekend only"
- "Introducing our new Pro tier -- upgrade now"
- Product promotion from a vendor the user purchased from
- Re-engagement email ("We miss you -- here's 20% off")

## VIP Handling

Apply VIP rules after initial category and flag assignment. Pull the VIP sender list from `user_preferences.vip_senders`.

- Never mark a VIP email as `archivable: true`, regardless of category or priority.
- Boost the priority score of every VIP email by +1 (cap at 5). Defer the actual scoring math to the priority-scoring skill, but ensure the boost signal is passed along.
- Classify VIP emails into their natural category based on content. Do not force VIP emails into `action_required` simply because the sender is a VIP.
- When a VIP email falls into `fyi`, `newsletter`, or `promotions`, set `needs_response: false` but always set `archivable: false`.
- Match VIP status against both the `from` email address and the sender display name. A match on either qualifies the email as VIP.

## The needs_response Flag

Set `needs_response: true` when any of the following conditions hold:
- The email contains a direct question addressed to the user.
- The email requests an action that requires the user to communicate back (reply, forward with comments, send a document).
- The category is `action_required` AND the required action involves sending a reply or written response.

Set `needs_response: false` when:
- The category is `newsletter` or `promotions`.
- The category is `fyi` and no question is directed at the user.
- The category is `waiting_on` (user has already responded; no new reply needed).
- The required action is non-communicative (e.g., "review internally" with no reply expected).

## The archivable Flag

Set `archivable: true` when all of the following hold:
- The category is `newsletter` or `promotions` (these are always archivable by default).
- OR the category is `fyi` AND priority is less than or equal to 2.
- AND the sender is not a VIP.
- AND the email has no associated action items.

Set `archivable: false` when any of the following hold:
- The category is `action_required` or `waiting_on`.
- The sender is a VIP, regardless of category.
- The priority score is 4 or higher.
- The category is `fyi` AND the priority score is 3 or higher.

## Edge Cases

### Mixed Signals

Handle ambiguous emails using these precedence rules:

- Email from a VIP with promotional content: assign category `fyi`, set `archivable: false`. VIP protection overrides the `promotions` classification when the content is not purely commercial.
- Newsletter containing a direct question to the user: assign category `action_required`. Action signals always take precedence over format-based categorization.
- FYI CC'd email with a question embedded in the body: assign category `action_required` only if the question is specifically directed at the user (mentions by name, uses "you", or the user is the only CC recipient). Otherwise, keep as `fyi`.
- Auto-forwarded email requiring action: assign category based on the content of the forwarded message, not the forwarding metadata. If the forwarded content contains action items, classify as `action_required`.
- Email from a known newsletter sender that breaks the usual pattern (e.g., a personal note from the newsletter author): evaluate content over sender reputation. If the message contains a personal request, classify as `action_required`.

### Thread Handling

- Categorize based on the most recent message in the thread, not the thread as a whole.
- Re-categorize when the latest message changes the thread's context. For example, if a new reply adds a question to what was previously an FYI thread, re-classify as `action_required`.
- Ignore quoted/replied text when determining category -- focus on the new content added by the latest sender.
- When a thread has multiple unread messages, evaluate each unread message independently but use the latest one for the final category assignment.

### Auto-Archive Labels

- Mark emails matching any label in the user's `auto_archive_labels` preference list as `archivable: true`, bypassing normal archivable logic.
- Exception: VIP senders override auto-archive labels. Never auto-archive a VIP email even if it matches an auto-archive label.
- Apply auto-archive evaluation after all other flag assignments so it acts as a final override (except for VIP).

## Output Format

Produce exactly one classification object per email. Include the following fields:

- `category`: Exactly one of `action_required`, `waiting_on`, `fyi`, `newsletter`, `promotions`.
- `needs_response`: Boolean. Indicates whether the user needs to send a reply or written communication.
- `archivable`: Boolean. Indicates whether the email can be safely archived without user review.
- `labels`: Array of strings. Any content-based labels applied during analysis (e.g., `["finance", "urgent"]`).

Do not include confidence scores or secondary category suggestions. Commit to a single classification. When uncertain between two categories, apply the precedence: `action_required` > `waiting_on` > `fyi` > `newsletter` > `promotions`.
