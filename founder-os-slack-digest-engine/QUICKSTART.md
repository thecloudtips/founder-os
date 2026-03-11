# Quick Start: Slack Digest Engine

> Scan Slack channels to create structured digests with decisions, action items, and @mentions

## Overview

**Plugin #19** | **Pillar**: MCP & Integrations | **Platform**: Claude Code

The Slack Digest Engine cuts through Slack noise to surface decisions, action items, key threads, and your @mentions. Two commands serve different needs.

### What This Plugin Does

- Scans Slack channels and classifies messages into 9 types (decisions, announcements, action items, etc.)
- Scores message importance using a 4-factor algorithm (type, engagement, recency, channel importance)
- Filters 30-60% noise (bot messages, social content, duplicates)
- Extracts explicit action items with assignees and due dates
- Detects your @mentions across all scanned channels

### Time Savings

Estimated **20-30 minutes** per day compared to manually reading all Slack channels.

## Available Commands

| Command | Description |
|---------|-------------|
| `/slack:digest` | Comprehensive team digest — decisions, action items, threads, mentions |
| `/slack:catch-up` | Personal quick summary — only your mentions and action items |

## Usage Examples

### Example 1: Morning Team Digest

```
/slack:digest --all --since=12h
```

**What happens:** Scans all bot-accessible channels for the last 12 hours. Produces a full digest with decisions, action items, @mentions, key threads, and channel summaries. Saves to Notion if available.

### Example 2: Quick Personal Catch-Up

```
/slack:catch-up
```

**What happens:** Scans all channels for the last 8 hours (default). Shows only your @mentions and action items assigned to you. Fast — uses ~80% fewer API calls than the full digest.

### Example 3: Specific Channel Deep Dive

```
/slack:digest #engineering #product --since=2d
```

**What happens:** Scans only #engineering and #product for the last 2 days. Useful for catching up on specific team discussions.

### Example 4: Include DMs

```
/slack:digest --all --since=24h --include-dms
```

**What happens:** Full workspace scan including direct messages. Requires the im:history bot scope.

### Example 5: Chat-Only Output

```
/slack:digest #general --output=chat
```

**What happens:** Displays digest in chat without saving to Notion. Useful for quick checks.

### Example 6: Extended Catch-Up After Vacation

```
/slack:catch-up --since=3d
```

**What happens:** Personal catch-up covering the last 3 days. Shows all your mentions and action items from while you were away.

## Tips

- Start with `/slack:catch-up` for your daily morning routine — it's fast and focused
- Use `/slack:digest --all` weekly for a broader team awareness scan
- The bot must be invited to channels to scan them — run `/invite @bot-name` in Slack
- Noise filtering removes 30-60% of messages automatically (bot messages, social content, etc.)
- Action items are only extracted when explicitly assigned (no inferred commitments)

## Related Plugins

This plugin enhances:
- **#22 Multi-Tool Morning Sync**: Provides Slack digest data for the unified morning briefing

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Slack MCP server is not connected" | Set SLACK_BOT_TOKEN environment variable |
| No messages found | Invite the bot to channels via `/invite @bot-name` |
| Rate limit errors | Wait 60 seconds, retry with fewer channels or narrower time window |
| Notion unavailable | Not an error — digest displays in chat. Configure Notion per INSTALL.md |

## Next Steps

1. Try `/slack:catch-up` for a quick personal scan
2. Run `/slack:digest --all --since=8h` for a full team digest
3. Check `INSTALL.md` for Notion configuration to enable digest history
