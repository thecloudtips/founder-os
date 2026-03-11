---
description: Create Google Calendar reminders for pending follow-ups
argument-hint: "[email_id] [--all] [--in=Nd]"
allowed-tools: ["Read"]
---

# Create Follow-Up Reminders

Create Google Calendar events as reminders to follow up on pending emails. Supports single-thread reminders and batch creation for all pending follow-ups.

## Load Skill

Read the follow-up-detection skill at `${CLAUDE_PLUGIN_ROOT}/skills/followup/follow-up-detection/SKILL.md` for thread context analysis and priority-based scheduling logic.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `$1` (optional) — email thread ID or subject keyword for a specific follow-up. If a keyword, search Gmail sent folder for the most recent matching thread.
- `--all` (optional) — create reminders for all pending follow-ups from the last `/founder-os:followup:check` run. Mutually exclusive with `$1`.
- `--in=Nd` (optional) — set explicit reminder delay in days. Example: `--in=3d` creates a reminder 3 days from today. Default: auto-calculate based on priority.

If neither `$1` nor `--all` is provided:
1. Check if `/founder-os:followup:check` was run recently in this conversation. If follow-up results are available, present them as a numbered list and ask the user to pick one or confirm `--all`.
2. Otherwise, prompt: "No email specified. Run `/founder-os:followup:check` first, or provide a thread ID, subject keyword, or `--all` flag."

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Reminder Date Calculation

When `--in=Nd` is not specified, auto-calculate the reminder date based on priority:

| Priority | Reminder Delay | Rationale |
|----------|---------------|-----------|
| 5 (Critical) | Tomorrow | Needs immediate attention |
| 4 (Urgent) | +1 day | Follow up today or tomorrow |
| 3 (Firm) | +3 days | Follow up this week |
| 2 (Gentle) | +5 days | Follow up when convenient |
| 1 (Low) | +7 days | Check again next week |

When `--in=Nd` is provided, use that explicit delay regardless of priority.

## Single Reminder Creation

For a specific thread (`$1` provided without `--all`):

1. **Fetch thread context**: Retrieve the email thread from Gmail. Extract subject, recipient, sent date, days waiting, and any promise context.

2. **Calculate reminder date**: Apply the priority-based delay or use `--in` override.

3. **Create Calendar event**:
   - **Title**: "Follow up: [subject]" (truncate subject to keep title under 80 chars)
   - **Date**: Calculated reminder date
   - **Time**: 9:00 AM in the user's local timezone
   - **Duration**: 15 minutes (placeholder)
   - **Reminder**: 30-minute notification before the event
   - **Description**: Include thread context:
     ```
     Original email to: [recipient]
     Sent: [sent_date]
     Days waiting: [days_waiting]
     Priority: [score]/5

     Context: [first 200 chars of the user's sent message]

     Thread ID: [thread_id]
     Tip: Run /founder-os:followup:nudge [thread_id] to draft a follow-up email.
     ```

4. **Update Notion** (if available): Find the follow-up record in "[FOS] Tasks" (filtered by `Type = "Follow-Up"` and matching Thread ID; fall back to "Founder OS HQ - Tasks", then legacy "Follow-Up Tracker - Follow-Ups"). Add a note indicating a reminder was set for the calculated date.

## Batch Reminder Creation (`--all` flag)

When `--all` is specified:

1. **Gather pending follow-ups**: Use results from the most recent `/founder-os:followup:check` in this conversation, or run a fresh scan if no recent results exist. Include only items with Status "Awaiting Reply" and priority >= 2 (skip priority 1 "monitor only" items).

2. **Create reminders for each**: Apply the single reminder creation process to each pending follow-up. Stagger reminder times by 15-minute intervals to avoid notification overload (9:00 AM, 9:15 AM, 9:30 AM, etc.).

3. **Display batch summary** after all reminders are created.

## Graceful Degradation

If Google gws CLI is unavailable for Calendar:
- Output reminder details as structured text in chat
- For each planned reminder, show the date, time, title, and description
- Suggest: "gws CLI (Calendar) unavailable. Add these reminders manually, or configure Google Calendar per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`."

## Output Format

### Single Reminder

```
## Follow-Up Reminder Created

**Event**: Follow up: [subject]
**Date**: [reminder_date] at 9:00 AM
**Priority**: [score]/5 — [label]
**Recipient**: [recipient]
**Days waiting**: [days_waiting]

Calendar event created with 30-minute notification.
[Notion link if tracked]

Tip: When the reminder fires, run `/founder-os:followup:nudge [thread_id]` to draft a follow-up email.
```

### Batch Reminders

```
## Follow-Up Reminders Created

**Reminders set**: [count]
**Skipped** (priority 1): [count]

| # | Subject | Recipient | Reminder Date | Priority |
|---|---------|-----------|---------------|----------|
| 1 | [subject] | [recipient] | [date] | [score]/5 |
| 2 | ... | ... | ... | ... |

All events created with 30-minute notifications.
```

If no eligible follow-ups exist for batch mode:
- Display: "No pending follow-ups with priority >= 2. Run `/founder-os:followup:check` to scan for new follow-ups."

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/founder-os:followup:remind 18e3a4b2c1d0e5f6
/founder-os:followup:remind "project proposal"
/founder-os:followup:remind 18e3a4b2c1d0e5f6 --in=2d
/founder-os:followup:remind --all
/founder-os:followup:remind --all --in=1d
```
