# Quick Start: founder-os-inbox-zero

> AI-powered email triage that categorizes, prioritizes, extracts actions, drafts responses, and archives — achieving Inbox Zero with a 4-agent pipeline.

## Overview

**Plugin #01** | **Pillar**: Daily Work | **Platform**: Claude Code

Inbox Zero Commander turns your overflowing inbox into a structured, prioritized workflow. Run a quick summary to see what needs attention, or activate the full pipeline to extract tasks, draft replies, and clean up automatically.

### What This Plugin Does

- Categorizes emails into 5 types: Action Required, Waiting On, FYI, Newsletter, Promotions
- Scores priority 1-5 using an Eisenhower matrix with VIP and keyword boosts
- Extracts action items and creates Notion tasks
- Drafts contextual replies matching sender tone
- Recommends emails for archiving (never auto-archives)

### Time Savings

Estimated **2-3 hours per week** compared to manually triaging, task-extracting, and drafting responses.

## Available Commands

| Command | Description |
|---------|-------------|
| `/inbox:triage` | Quick inbox summary with categories and priorities |
| `/inbox:triage --team` | Full 4-agent pipeline: triage, actions, drafts, archive |
| `/inbox:drafts_approved` | Push approved Notion drafts to Gmail |

## Usage Examples

### Example 1: Quick Inbox Summary (Default Mode)

```
/inbox:triage
```

**What happens:**
- Fetches unread emails from the last 24 hours (up to 100)
- Categorizes each email and assigns a priority score
- Shows category counts, top 5 urgent items, and archive candidates
- Takes about 30 seconds for a typical inbox

### Example 2: Full Pipeline with Custom Timeframe

```
/inbox:triage --team --hours=48
```

**What happens:**
- Processes 48 hours of email through the complete 4-agent pipeline
- **Triage Agent** categorizes and prioritizes all emails
- **Action Agent** extracts tasks and creates them in your Notion "[FOS] Tasks" database (Type="Email Task", Source Plugin="Inbox Zero")
- **Response Agent** drafts replies and saves them to your Notion "[FOS] Content" database (Type="Email Draft") for review
- **Archive Agent** recommends which emails to archive (you decide)
- Final report shows everything: categories, tasks created, drafts ready, archive candidates

### Example 3: Approve and Send Drafted Responses

```
/inbox:drafts_approved
```

**What happens:**
- Checks Notion "[FOS] Content" (or fallback "Founder OS HQ - Content" / legacy "Inbox Zero - Drafts") for Email Draft entries you marked as "Approved"
- Creates Gmail drafts for each approved response (threaded as replies)
- Updates Notion status to "Sent to Gmail"
- Reminder: drafts land in your Gmail Drafts folder for final review before sending

## Flags Reference

| Flag | Default | Description |
|------|---------|-------------|
| `--team` | off | Activate full 4-agent pipeline |
| `--hours=N` | 24 | Hours to look back for unread emails |
| `--max=N` | 100 | Maximum emails to process |

## Tips

- Start with `/inbox:triage` (default mode) to get a feel for how categorization works before running the full pipeline
- VIP senders are never recommended for archiving and always get a priority boost
- Drafts go to Notion first, not Gmail — review them at your pace before approving
- Run the pipeline daily for best results: `/inbox:triage --team`

## Related Plugins

This plugin connects with:
- **#06 Follow-Up Tracker**: Emails marked `waiting_on` can feed into follow-up tracking when both plugins are installed

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "gws CLI not found" | Install gws and run `gws auth login` to authenticate |
| "Notion MCP not configured" | Set `NOTION_API_KEY` or run without Notion (text output only) |
| No emails found | Try `--hours=48` to expand the lookback window |
| No approved drafts | Run `/inbox:triage --team` first, then approve drafts in Notion |
| Plugin not loading | Ensure folder is in `~/.claude/plugins/` and restart Claude Code |

## Next Steps

1. Try `/inbox:triage` to see your inbox summary
2. Run `/inbox:triage --team` for the full pipeline experience
3. Review drafts in Notion and approve the ones you like
4. Run `/inbox:drafts_approved` to push them to Gmail
5. Check `INSTALL.md` for advanced configuration options
