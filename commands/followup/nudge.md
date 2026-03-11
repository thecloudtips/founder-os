---
description: Draft a follow-up nudge email and create a Gmail draft
argument-hint: "[email_id] [--tone=gentle|firm|urgent]"
allowed-tools: ["Read"]
---

# Draft Follow-Up Nudge

Draft a professional follow-up nudge email for a sent message that has not received a response, then create a Gmail draft for user review.

## Load Skills

Read the nudge-writing skill at `${CLAUDE_PLUGIN_ROOT}/skills/followup/nudge-writing/SKILL.md` for escalation levels, tone matching by relationship, subject line handling, context referencing, call-to-action patterns, and anti-patterns.

Read the follow-up-detection skill at `${CLAUDE_PLUGIN_ROOT}/skills/followup/follow-up-detection/SKILL.md` for thread context analysis and priority scoring.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `$1` (required) — email thread ID or subject keyword to identify the email to nudge. If a keyword, search Gmail sent folder for the most recent matching thread.
- `--tone=gentle|firm|urgent` (optional) — override the auto-selected escalation level. Default: auto-detect based on days_waiting and nudge count.

If no argument is provided:
1. Check if `/founder-os:followup:check` was run recently in this conversation. If follow-up results are available in context, present them as a numbered list and ask the user to pick one.
2. Otherwise, prompt: "No email specified. Run `/founder-os:followup:check` first to see pending follow-ups, or provide a thread ID or subject keyword."

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Context Analysis

1. **Fetch thread**: Retrieve the full email thread from Gmail using the thread ID. Identify the user's most recent sent message and any prior messages in the thread.

2. **Determine relationship type**: Infer the relationship from context signals:
   - **Client**: Recipient domain differs from user's domain, thread contains business language (proposal, invoice, project, deliverable), or contact appears in CRM.
   - **Colleague**: Recipient shares the user's email domain, or uses first-name-only sign-offs.
   - **Vendor**: User is the buyer — thread references quotes, invoices to pay, service delivery, support tickets.
   - Default to "client" when unclear.

3. **Calculate escalation level**: Determine automatically from days_waiting and nudge history:
   - **Level 1 (Gentle)**: 3-7 days waiting, 0 prior nudges.
   - **Level 2 (Firm)**: 7-14 days waiting, OR 1 prior nudge (regardless of age).
   - **Level 3 (Urgent)**: 14+ days waiting, OR 2+ prior nudges.
   - Apply `--tone` override if provided.

4. **Identify original ask**: Extract the core request, question, or commitment from the user's sent message. This provides the context reference for the nudge.

## Draft Nudge Email

Apply the nudge-writing skill to compose the follow-up:

1. **Subject line**: Preserve the original `Re:` prefix for threading. On Level 2+, prepend `[Follow-up]` tag. Keep under 80 characters.

2. **Body**: Follow the skill's escalation-level structure:
   - Level 1: Brief, warm, reference the specific ask, ask one clear question. 2-3 sentences max.
   - Level 2: Reference the specific date and original ask, propose a concrete next step, set a soft deadline. 3-4 sentences.
   - Level 3: State urgency directly, reference timeline and previous attempts, offer alternatives (different contact, revised timeline, cancel request). 4-5 sentences.

3. **Tone**: Match the relationship type per the skill's tone-matching rules (client = professional/warm, colleague = casual/direct, vendor = assertive/clear).

4. **Call-to-action**: Include one specific CTA matching the escalation level (question for Level 1, next step for Level 2, soft deadline for Level 3).

5. **Anti-pattern check**: Verify the draft does not contain any phrases from the anti-patterns list (no "just checking in" without context, no "per my last email", no ultimatums on first nudge).

## Create Gmail Draft

1. Create a Gmail draft with:
   - **To**: Original recipient(s)
   - **Subject**: Constructed per subject line rules above
   - **Body**: The drafted nudge email
   - **In-Reply-To / References**: Set to maintain threading with the original conversation
2. This is a recommend-only action — the draft is created for user review, never sent automatically.

## Notion Update

If Notion MCP is available and the **"[FOS] Tasks"** database exists (fall back to "Founder OS HQ - Tasks", then legacy "Follow-Up Tracker - Follow-Ups" if not found):
1. Find the record matching the thread ID, filtered by `Type = "Follow-Up"`.
2. Update: increment Nudge Count by 1, set Last Nudge Date to today. Status remains "Waiting" (nudge sent does not change HQ status).
3. If no record exists, create one with all fields populated, including `Type = "Follow-Up"`, `Source Plugin = "Follow-Up Tracker"`, and Contact/Company relations where matches are found.

If Notion is unavailable, skip silently — Notion tracking is optional.

## Output Format

After creating the draft, display:

```
## Nudge Draft Created

**To**: [recipient]
**Subject**: [subject line]
**Escalation**: Level [1|2|3] ([gentle|firm|urgent])
**Relationship**: [client|colleague|vendor]

---

[Full email body preview]

---

Gmail draft created. Review and send from Gmail when ready.
[Notion link if tracked]
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/founder-os:followup:nudge 18e3a4b2c1d0e5f6
/founder-os:followup:nudge "project proposal"
/founder-os:followup:nudge 18e3a4b2c1d0e5f6 --tone=urgent
/founder-os:followup:nudge "quarterly review" --tone=gentle
```
