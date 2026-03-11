# founder-os-weekly-review-compiler

> **Plugin #05** -- Generate a structured weekly review Notion page from auto-discovered task databases, Google Calendar events, and Gmail threads

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | Daily Work |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Intermediate |
| **Week** | 9 |

## What It Does

Automates end-of-week reflection by pulling data from three sources -- Notion task databases (auto-discovered), Google Calendar events, and Gmail threads -- then assembling a structured 6-section review page in the consolidated "[FOS] Briefings" database (Type = "Weekly Review"). Covers wins by project, meetings and outcomes, blockers and risks, carryover items, and next-week priorities with an AI-ranked top-5 list and calendar preview.

## Requirements

### MCP Servers

- **Notion** -- Auto-discover task databases, store review pages (Required)
- **Google Calendar** -- Meeting data, time allocation, calendar preview (Required)
- **Gmail** -- Email thread activity and communication summary (Optional)

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/weekly:review [--date=YYYY-MM-DD] [--output=notion\|chat\|both]` | Generate a structured weekly review from tasks, meetings, and emails |

## Skills

- **Weekly Reflection**: Week boundary rules, database auto-discovery algorithm, 3-source data gathering, blocker detection signals, next-week priority ranking algorithm, and Notion output formatting

## Agent Teams

This plugin does not use Agent Teams.

## Dependencies

This plugin has no dependencies on other Founder OS plugins.

## Blog Post

**Week 9**: "Your AI-Powered Weekly Review: Never Forget What You Accomplished"

## License

MIT
