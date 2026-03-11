# Quick Start: founder-os-multi-tool-morning-sync

> Never Miss a Beat: Your AI Morning Briefing Across Every Tool

## Overview

**Plugin #22** | **Pillar**: MCP & Integrations | **Platform**: Claude Code

Consolidates overnight updates from Gmail, Google Calendar, Notion, Slack, and Google Drive into a single prioritized morning briefing with cross-source priority synthesis.

### What This Plugin Does

- Gathers overnight updates from up to 5 data sources
- Ranks priorities across all sources using unified scoring (0-100)
- Saves full briefings to Notion with source metrics
- Provides quick ephemeral summaries for fast check-ins

### Time Savings

Estimated **15-30 minutes** per morning compared to manually checking each tool.

## Available Commands

| Command | Description |
|---------|-------------|
| `/morning:sync` | Full pipeline: gather, prioritize, Notion page, chat summary |
| `/morning:quick` | Quick chat-only check-in (no Notion storage) |

## Usage Examples

### Example 1: Quick Morning Check-In

```
/morning:quick
```

**What happens:** Scans all sources for the last 12 hours, shows top 5 priorities, today's schedule at a glance, and urgent/unread counts per source. No Notion page created.

### Example 2: Full Morning Sync (Default)

```
/morning:sync
```

**What happens:** Full pipeline with 12-hour overnight window. Gathers data from all configured sources, synthesizes priorities, creates/updates a Notion page in the "[FOS] Briefings" database (Type = "Morning Sync"), and presents a chat summary.

### Example 3: Custom Overnight Window

```
/morning:sync --since=8h
```

**What happens:** Same as full sync but only scans the last 8 hours instead of 12.

### Example 4: Chat-Only Full Sync

```
/morning:sync --output=chat
```

**What happens:** Full gathering and synthesis, but skips Notion page creation. Useful when Notion is not configured or you just want the detailed briefing in chat.

### Example 5: Notion-Only Sync

```
/morning:sync --output=notion
```

**What happens:** Creates/updates the Notion briefing page but skips the chat summary. Good for automated/scheduled runs.

### Example 6: Specific Date

```
/morning:sync --date=2026-03-04
```

**What happens:** Generates a briefing for March 4th instead of today. The overnight window adjusts to end at midnight of the specified date.

## Tips

- Start with `/morning:quick` to verify all sources are connected
- Use `/morning:sync` once daily for a comprehensive briefing saved to Notion
- The plugin works with just Gmail + Calendar + Notion; Slack and Drive add more context when available
- Briefings are idempotent: running `/morning:sync` twice on the same day updates the existing briefing

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "0 required sources" error | Configure Gmail, Calendar, and Notion MCP servers (see INSTALL.md) |
| Slack/Drive section missing | These are optional; set `"disabled": false` in `.mcp.json` |
| Stale data | Try `--since=24h` for a wider window |
| Duplicate briefing | Already handled: the plugin updates existing entries by date |
| Command not found | Verify plugin is installed in the correct directory |

## Next Steps

1. Try `/morning:quick` to verify your setup
2. Run `/morning:sync` for your first full briefing
3. Check your Notion workspace for the "[FOS] Briefings" database (entries with Type = "Morning Sync")
4. Enable Slack and Drive in `.mcp.json` for richer briefings
5. Check `INSTALL.md` for detailed MCP server configuration
