# founder-os-multi-tool-morning-sync

> **Plugin #22** -- Never Miss a Beat: Your AI Morning Briefing Across Every Tool

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | MCP & Integrations |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Intermediate |
| **Week** | 22 |

## What It Does

Consolidates overnight updates from Gmail, Google Calendar, Notion, Slack, and Google Drive into a single prioritized morning briefing. Cross-source priority synthesis surfaces the most important items first, with detailed sections per source. Saves full briefings to the consolidated "[FOS] Briefings" database (Type = "Morning Sync") and provides quick ephemeral summaries.

## Requirements

### MCP Servers

- **Gmail** (`gws` CLI (Gmail)) -- Scan overnight emails (required)
- **Google Calendar** (`gws` CLI (Calendar)) -- Today's schedule (required)
- **Notion** (`@modelcontextprotocol/server-notion`) -- Task tracking and briefing storage (required)
- **Slack** (`@anthropic/mcp-server-slack`) -- Channel highlights and @mentions (optional)
- **Google Drive** (`gws` CLI (Drive)) -- Document updates (optional)

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/morning:sync` | Full pipeline: gather all sources, synthesize priorities, save to Notion, chat summary |
| `/morning:quick` | Quick ephemeral check-in: top 5 priorities, schedule, counts (no Notion storage) |

## Skills

- **morning-briefing**: Multi-source overnight data gathering (Gmail, Calendar, Notion, Slack, Drive) with graceful degradation
- **priority-synthesis**: Cross-source priority ranking (0-100 scoring), urgency windowing, and section assembly

## Agent Teams

This plugin does not use Agent Teams. It uses an orchestrator pattern that directly coordinates MCP tools.

## Dependencies

This plugin has no dependencies on other Founder OS plugins. It reuses domain knowledge patterns from P02 (Daily Briefing), P19 (Slack Digest), and P18 (Google Drive Brain).

## Blog Post

**Week 22**: "Never Miss a Beat: Your AI Morning Briefing Across Every Tool"

Start every day knowing exactly what needs attention, with priorities ranked across all your tools.

## License

MIT
