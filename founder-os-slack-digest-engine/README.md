# founder-os-slack-digest-engine

> **Plugin #19** -- Scan Slack channels to create structured digests with decisions, action items, key threads, and @mentions

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | MCP & Integrations |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Intermediate |
| **Week** | 20 |

## What It Does

Cuts through Slack noise to surface what actually matters. The Slack Digest Engine scans channels and DMs, classifies messages into 9 types, scores relevance using a 4-factor algorithm, and produces structured digests with decisions, action items, @mentions, and key threads. Digests are stored in the consolidated "[FOS] Briefings" database (Type = "Slack Digest"). Two commands serve different needs: a comprehensive team digest and a lightweight personal catch-up.

## Requirements

### MCP Servers

- **Slack** -- Read channels, DMs, and search messages (Required)
- **Notion** -- Store digest history (Optional)

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/slack:digest [channels] [--all] [--since] [--include-dms] [--output]` | Comprehensive channel digest with decisions, action items, threads, and mentions |
| `/slack:catch-up [--since]` | Quick personal summary — only your @mentions and action items |

## Skills

- **Slack Analysis**: Channel scanning, message extraction, thread context resolution, message type classification (9 types), and decision detection via Slack MCP
- **Message Prioritization**: Noise filtering, 4-factor signal scoring (0-100), priority tier assignment (P1-P5), @mention detection, action item extraction, and thread deduplication

## Agent Teams

This plugin does not use Agent Teams.

## Dependencies

This plugin has no dependencies on other Founder OS plugins.

**Enhances**: #22 Multi-Tool Morning Sync (provides Slack digest data)

## Blog Post

**Week 20**: "Never Miss What Matters: AI-Powered Slack Catch-Up"

## License

MIT
