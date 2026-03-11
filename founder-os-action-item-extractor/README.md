# founder-os-action-item-extractor

> **Plugin #04** -- Extracts structured action items from meeting transcripts, email threads, or documents and auto-creates Notion tasks with owners, deadlines, and priorities.

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | Daily Work |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Beginner |
| **Week** | 8 |

## What It Does

Paste any text — meeting transcript, email thread, or document — and this plugin automatically identifies action items, assigns owners, parses deadlines, scores priority, and creates structured tasks in your Notion workspace. It handles duplicate detection (14-day window) and gracefully falls back to chat output when Notion is unavailable.

## Requirements

### MCP Servers

- **Notion** (required) -- Task storage in "[FOS] Tasks" (Type="Action Item"), duplicate detection, CRM contact/company linking

### CLI Tools

- **gws CLI** (optional) -- Read source documents directly from Google Drive

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/actions:extract` | Extract action items from pasted text and create Notion tasks |
| `/actions:extract-file` | Extract action items from a file and create Notion tasks |

## Skills

- **Action Extraction**: Verb detection patterns, owner inference rules, deadline parsing, priority scoring, and duplicate detection for converting text into structured tasks.

## Agent Teams

This plugin does not use Agent Teams.

## Dependencies

This plugin has no hard dependencies on other Founder OS plugins. However:

- **#07 Voice Note Processor** enhances this plugin by providing transcribed audio as input.

## License

MIT
