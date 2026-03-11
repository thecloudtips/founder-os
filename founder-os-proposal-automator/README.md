# founder-os-proposal-automator

> **Plugin #12** -- Generates professional client proposals with 7 sections and 3 pricing packages

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | Code Without Coding |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Intermediate |
| **Week** | 14 |

## What It Does

The Proposal Automator creates polished client proposals from a brief, scope notes, and optional CRM context. It outputs Markdown proposals with 7 structured sections and 3 pricing packages (good-better-best), plus a SOW-compatible brief file for seamless handoff to the #14 SOW Generator via `/sow:from-brief`.

## Requirements

### MCP Servers

- **Filesystem** (required) -- Read brief files and write generated proposals
- **Notion** (optional) -- Search CRM Pro for client context, track proposals in the consolidated "Founder OS HQ - Deliverables" database (Type="Proposal"), with fallback to legacy "Proposal Automator - Proposals" database
- **gws CLI** (optional) -- Store generated proposals in Google Drive for client sharing

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/proposal:create [client]` | Generate a complete proposal with 7 sections and 3 pricing packages |
| `/proposal:from-brief [file-or-url]` | Generate a proposal from an existing brief file or Notion page |

## Skills

- **Proposal Writing**: 7-section proposal structure, formatting rules, writing style, quality checklist, SOW-compatible brief generation
- **Pricing Strategy**: 3-tier good-better-best pricing, package naming, effort/value/competitive calculation frameworks, comparison table layout, payment terms

## Agent Teams

This plugin does not use Agent Teams.

## Dependencies

- **#14 SOW Generator**: Produces SOW-compatible brief files consumable by `/sow:from-brief`
- **#20 Client Context Loader**: Reads same CRM Pro databases for client context
- **#21 CRM Sync Hub**: Uses same CRM Pro Companies/Contacts/Deals databases

## License

MIT
