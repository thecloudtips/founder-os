# founder-os-time-savings-calculator

> **Plugin #25** -- Know Exactly How Much Time (and Money) Your AI Plugins Save

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | Meta & Growth |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Intermediate |
| **Week** | 25 |

## What It Does

Scans all active Founder OS plugin Notion databases (consolidated "Founder OS HQ" databases first, falling back to legacy per-plugin database names), counts completed tasks across 24 task categories using Type filters where applicable, and converts them into time saved, dollar value, and ROI multiplier reports. Generates Mermaid pie charts (weekly) and bar charts (monthly) to visualize savings over time. Supports configurable hourly rates and custom time estimates per task type.

## Requirements

### MCP Servers

- **Notion** (`@modelcontextprotocol/server-notion`) -- Scan plugin databases and store report tracking data (required)
- **Filesystem** (`@modelcontextprotocol/server-filesystem`) -- Write report files to local disk (required)

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/savings:quick` | Quick chat-only summary of recent savings (no file/Notion output) |
| `/savings:weekly` | Full weekly savings report with Mermaid chart, saved to file and Notion |
| `/savings:monthly-roi` | Multi-month ROI report with trends, bar charts, and annualized projections |
| `/savings:configure` | Set hourly rate and customize time estimates |

## Skills

- **cross-plugin-discovery**: Scans all Founder OS plugin Notion databases and counts completed tasks across 24 task categories
- **roi-calculation**: Converts task counts to time and dollar savings, generates Mermaid charts, and produces formatted reports

## Agent Teams

This plugin does not use Agent Teams.

## Dependencies

This plugin has no dependencies on other Founder OS plugins. It reads from all active plugin Notion databases (consolidated Founder OS HQ databases or legacy per-plugin databases) to aggregate savings data. Reports are logged to "[FOS] Reports" with Type="ROI Report" (falls back to "Founder OS HQ - Reports", then legacy "Time Savings Calculator - Reports").

## Blog Post

**Week 25**: "Know Exactly How Much Time (and Money) Your AI Plugins Save"

Show founders how to measure real ROI from their AI automation stack with auto-generated weekly and monthly reports.

## License

MIT
