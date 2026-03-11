# Quick Start: Daily Briefing Generator

> Your AI chief of staff that assembles a structured daily briefing from Calendar, Gmail, Notion, and Slack -- every morning, in under 30 seconds.

## Overview

**Plugin #02** | **Pillar**: Daily Work | **Platform**: Claude Code

Daily Briefing Generator pulls together the scattered signals from your morning -- calendar events, priority emails, due tasks, and Slack mentions -- into a single, structured Notion page. Instead of jumping between four apps before your first meeting, run one command and get a complete picture of your day.

### What This Plugin Does

- Gathers data from Google Calendar, Gmail, Notion tasks, and optionally Slack to build a unified daily briefing
- Creates a structured Notion page with schedule overview, priority emails, tasks grouped by project, and Slack activity
- Tracks all generated briefings in the "[FOS] Briefings" database (Type = "Daily Briefing") with meeting counts, email counts, task counts, and overdue metrics
- Supports midday review updates that append new information to your morning briefing without duplicating it

### Time Savings

Estimated **15-20 minutes per day** compared to manually checking Calendar, Gmail, Notion tasks, and Slack each morning.

## Available Commands

| Command | Description |
|---------|-------------|
| `/daily:briefing` | Generate a structured daily briefing for today (or a specified date) |
| `/daily:review` | Check for updates since your morning briefing and append changes |

## Usage Examples

### Example 1: Quick Morning Briefing

```
/daily:briefing
```

**What happens:**
A single agent gathers data from all configured sources sequentially -- Calendar events first, then Gmail highlights, Notion tasks, and Slack mentions. It assembles everything into a structured Notion page titled "Daily Briefing -- [today's date]" with sections for your schedule (with prep notes for key meetings), top 10 priority emails, tasks grouped by project, and a quick stats summary. The briefing database row is created automatically on first run. Takes about 15-20 seconds for a typical day.

### Example 2: Full Team Pipeline

```
/daily:briefing --team
```

**What happens:**
Launches 5 agents in a parallel-gathering pipeline. Four gatherer agents run simultaneously -- Calendar Agent fetches and classifies events with prep notes, Gmail Agent scores and extracts email highlights, Notion Agent pulls due and overdue tasks, and Slack Agent gathers mentions and DMs. Once all gatherers complete (or timeout after 30 seconds), the Briefing Lead agent synthesizes everything into the Notion page, calculates a "day complexity" score (Low/Medium/High/Critical), and logs pipeline execution stats. The pipeline continues as long as at least 2 agents return data.

### Example 3: Custom Email Lookback

```
/daily:briefing --hours=24
```

**What happens:**
Runs the same briefing process but expands the email lookback window from the default 12 hours to 24 hours. Useful on Monday mornings when you want to catch weekend emails, or after time off. Combine with `--team` for the full pipeline: `/daily:briefing --team --hours=24`.

### Example 4: Midday Review

```
/daily:review
```

**What happens:**
Finds your existing briefing for today and checks all sources for changes since it was generated. New meetings added or cancelled, high-priority emails that arrived after the morning briefing, newly completed tasks, and items that became overdue are surfaced. If changes exist, an "Updates Since Morning" section is appended to the bottom of your Notion briefing page (the original content is never modified). If nothing changed, you get a simple confirmation that everything is on track.

## Flags Reference

| Flag | Default | Applies To | Description |
|------|---------|------------|-------------|
| `--team` | off | `/daily:briefing` | Activate full 5-agent parallel-gathering pipeline |
| `--hours=N` | 12 | `/daily:briefing` | Hours to look back for unread emails |
| `--date=YYYY-MM-DD` | today | both commands | Target date for the briefing |

## Tips

- Run `/daily:briefing` first thing in the morning for best results -- it sets the baseline for your entire day
- Use `--team` mode for more thorough meeting prep notes, since each gatherer agent has dedicated time to process its source in depth
- Slack is optional -- the briefing works great without it, and the plugin skips Slack silently if the MCP server is not configured
- Run `/daily:review` mid-afternoon to catch schedule changes, new priority emails, and task completions since your morning briefing
- If you run `/daily:briefing` again for the same date, it updates the existing Notion page rather than creating a duplicate

## Related Plugins

This plugin connects with:
- **#22 Multi-Tool Morning Sync**: A more comprehensive morning workflow that goes beyond briefing into cross-tool synchronization. Daily Briefing Generator is the lighter, focused alternative

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Notion MCP is required" | Notion is mandatory for this plugin. Set `NOTION_API_KEY` in your environment. See `INSTALL.md` for setup. |
| "Need at least 2 data sources" | The plugin requires at least 2 working data sources. Verify gws CLI is installed (`which gws`) and authenticated (`gws auth login`). |
| Gmail unavailable warning | The briefing will still generate with Calendar and Notion data. Install and authenticate the gws CLI to add email highlights. |
| Calendar unavailable warning | The briefing will still generate without a schedule section. Install and authenticate the gws CLI for full output. |
| Duplicate briefing created | This should not happen -- the plugin checks for existing briefings by Date + Type = "Daily Briefing". If it does, verify that the "[FOS] Briefings" database has Date and Type properties with the correct format. |
| `/daily:review` says no briefing found | Run `/daily:briefing` first to generate the initial briefing for today before running review. |
| Slack data missing | This is expected if Slack gws CLI is unavailable or authentication not configured. Slack is optional and the plugin skips it silently. |
| Briefing takes too long in `--team` mode | Individual agents timeout after 30 seconds. If the pipeline is slow, check MCP server connectivity. The pipeline will continue with partial results. |

## Next Steps

1. Run `/daily:briefing` to generate your first morning briefing
2. Review the Notion page and get familiar with the section layout
3. Try `/daily:briefing --team` to see the full parallel pipeline in action
4. Run `/daily:review` in the afternoon to test the update flow
5. Check `INSTALL.md` for MCP server configuration and optional Slack setup
