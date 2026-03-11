# founder-os-daily-briefing-generator

> **Plugin #02** -- Parallel-gathering plugin that pulls today's calendar events, priority emails, due tasks, and optional Slack mentions -- assembling a structured daily briefing in Notion

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | Daily Work |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Beginner |
| **Week** | 6 |

## What It Does

Daily Briefing Generator acts as your personal chief of staff, compiling everything you need to know before your workday begins into a single Notion page. It dispatches multiple agents in parallel to scan your Google Calendar for today's meetings, surface priority emails from Gmail that need your attention, pull due and overdue tasks from Notion, and optionally sweep overnight Slack mentions and DMs. The result is a structured briefing page that gives you full situational awareness in under 30 seconds -- no tab-hopping, no mental load, no missed commitments.

The plugin operates in two modes. In **default mode**, a single agent performs a fast sweep across your connected sources and produces a lightweight briefing covering meetings, email highlights, and top tasks. In **team mode** (`--team`), the full 5-agent parallel pipeline activates: four dedicated gatherer agents fetch data from Calendar, Gmail, Notion, and Slack simultaneously, then a Briefing Lead agent synthesizes everything into a richly formatted Notion page with meeting prep notes, an email priority matrix, a task list grouped by project, and a time-block suggestion for the day ahead.

Because founders rarely have all tools connected on day one, the plugin degrades gracefully. Slack is entirely optional, and if any required source is temporarily unavailable the briefing still generates with the data it has, clearly marking which sections are incomplete. Each briefing is saved as a dated Notion page in the consolidated "[FOS] Briefings" database (with Type = "Daily Briefing"), giving you a searchable archive of how every workday started -- useful for weekly reviews, pattern spotting, and making sure nothing slipped through the cracks.

## Requirements

### MCP Servers

- **Google Calendar** (required) -- Fetch today's meetings and schedule
- **Gmail** (required) -- Scan unread emails for priority highlights
- **Notion** (required) -- Pull tasks, create briefing pages, record stats
- **Slack** (optional) -- Gather overnight mentions and DMs

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/daily:briefing` | Generate structured daily briefing (default: single-agent, `--team` for full pipeline) |
| `/daily:review` | Update existing briefing with changes since generation |

## Skills

- **meeting-prep**: Calendar event analysis, attendee context lookup, prep note generation
- **email-prioritization**: Unread email scanning, urgent/important matrix scoring, highlight extraction
- **task-curation**: Notion task filtering by due date, priority ordering, project grouping
- **briefing-assembly**: Multi-source synthesis, Notion page formatting, partial-data handling

## Agent Teams

This plugin uses a **parallel-gathering** Agent Team pattern with 5 agents:
- **calendar-agent** -- Fetches today's events and generates meeting prep notes
- **gmail-agent** -- Scans unread emails and applies priority scoring
- **notion-agent** -- Pulls tasks due today and overdue items
- **slack-agent** (optional) -- Gathers overnight Slack mentions and DMs
- **briefing-lead** -- Synthesizes all gathered data into a structured Notion page

See `teams/` for agent definitions and configuration.

## Dependencies

This plugin has no dependencies on other Founder OS plugins.

## Blog Post

**Week 6**: "Start Every Day with AI: Your Personal Chief of Staff"

## License

MIT
