# Quick Start: founder-os-follow-up-tracker

> Scans Gmail sent folder for emails awaiting response, detects promises, drafts nudge emails, and creates calendar reminders.

## Overview

**Plugin #06** | **Pillar**: Daily Work | **Platform**: Claude Code

Track emails that need follow-up attention. Never let an important email slip through the cracks.

### What This Plugin Does

- Scans your sent folder to find emails awaiting a reply
- Detects promises you made to others and promises others made to you
- Scores urgency based on age, relationship importance, and promise type
- Drafts professionally escalating follow-up nudge emails
- Creates calendar reminders for pending follow-ups

### Time Savings

Estimated **20-30 minutes** per day compared to manually checking sent mail and tracking follow-ups.

## Available Commands

| Command | Description |
|---------|-------------|
| `/followup:check` | Scan sent folder for emails awaiting response |
| `/followup:nudge` | Draft a follow-up nudge email |
| `/followup:remind` | Create calendar reminders for pending follow-ups |

## Usage Examples

### Example 1: Check for Pending Follow-Ups

```
/followup:check
```

**What happens:** Scans the last 30 days of your sent folder, identifies emails without replies, detects promises, and displays a prioritized table. Results are saved to Notion if available.

### Example 2: Check Only High Priority

```
/followup:check --priority=high --days=14
```

**What happens:** Shows only priority 3-5 follow-ups from the last 14 days. Useful for a quick morning review.

### Example 3: Draft a Nudge Email

```
/followup:nudge "project proposal"
```

**What happens:** Finds the most recent sent email matching "project proposal", analyzes the thread context, auto-selects the escalation level (gentle/firm/urgent) based on how long you've been waiting, and creates a Gmail draft for your review.

### Example 4: Override Nudge Tone

```
/followup:nudge 18e3a4b2c1d0e5f6 --tone=urgent
```

**What happens:** Drafts an urgent-level nudge for a specific thread ID, regardless of the auto-calculated escalation level.

### Example 5: Set a Reminder for One Follow-Up

```
/followup:remind "quarterly review" --in=2d
```

**What happens:** Creates a Google Calendar event "Follow up: quarterly review" for 2 days from now at 9:00 AM with a 30-minute notification.

### Example 6: Set Reminders for All Pending Follow-Ups

```
/followup:remind --all
```

**What happens:** Creates calendar reminders for all pending follow-ups with priority >= 2. Reminder dates are auto-calculated based on priority (urgent = tomorrow, gentle = 5 days).

## Tips

- Run `/followup:check` as part of your morning routine to catch stale threads
- Use `/followup:nudge` after checking -- it references the original email context automatically
- The plugin auto-detects relationship type (client/colleague/vendor) and adjusts nudge tone accordingly
- Nudge emails are created as Gmail drafts, never sent automatically -- always review before sending

## Related Plugins

This plugin connects with:
- **#01 Inbox Zero Commander**: Follow-Up Tracker can use Inbox Zero's VIP list and waiting_on data for better priority scoring. Works independently when Inbox Zero is not installed.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| gws CLI (Gmail) not responding | Check credentials paths and OAuth token. Run `/mcp` to verify server status. |
| No follow-ups found | Try expanding the lookback window: `/followup:check --days=30` |
| Notion database not created | Ensure Notion integration has workspace access and "Insert content" capability |
| Calendar reminders not working | gws CLI (Calendar) is optional. If unavailable, reminder details are shown in chat. |
| Nudge tone feels wrong | Override with `--tone=gentle\|firm\|urgent` to force a specific escalation level |

## Next Steps

1. Run `/followup:check` to see your current follow-up status
2. Try `/followup:nudge` on a stale email to draft a follow-up
3. Set up `/followup:remind --all` as a weekly habit
4. Check `INSTALL.md` for advanced configuration options
