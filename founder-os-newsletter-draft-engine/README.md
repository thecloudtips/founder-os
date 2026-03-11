# founder-os-newsletter-draft-engine

> **Plugin #08** -- Researches topics across web, GitHub, Reddit, and Quora, then generates structured newsletter drafts in founder voice with Substack-compatible markdown output.

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | Daily Work |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Intermediate |
| **Week** | 12 |

## What It Does

Automates the full newsletter creation pipeline from topic to publish-ready draft. Performs deep multi-source research across the web, GitHub, Reddit, and Quora to gather relevant findings, builds a structured outline with configurable sections, and writes a complete newsletter draft in a professional-but-conversational founder voice. Output is saved as Substack-compatible markdown, ready for copy-paste publishing.

## Requirements

### MCP Servers

- **Web Search** (required) -- Uses the built-in WebSearch tool for multi-source research. No MCP configuration needed.
- **Filesystem** (required) -- Reads research docs and writes newsletter output files via `@modelcontextprotocol/server-filesystem`
- **Notion** (optional) -- Tracks research sessions in "[FOS] Research" (Type="Newsletter Research") and newsletter drafts in "[FOS] Content" (Type="Newsletter"). Falls back to "Founder OS HQ - " prefixed names, then legacy "Newsletter Engine - Research" if not found.
- **gws CLI** (optional) -- Accesses existing research documents and reference material from Google Drive

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/newsletter [topic]` | Full pipeline: research, outline, and draft in one run |
| `/newsletter:research [topic]` | Deep multi-source research on a topic |
| `/newsletter:outline` | Create newsletter structure from gathered research |
| `/newsletter:draft` | Write full newsletter from outline |

## Skills

- **Topic Research**: Multi-source query formulation across web, GitHub, Reddit, and Quora. Finding extraction with recency scoring and deduplication across sources.
- **Newsletter Writing**: Newsletter structure following the Hook, Main, Takeaways, CTA framework. Substack formatting, configurable section count, and section templates.
- **Founder Voice**: Professional-but-conversational tone calibration, opinion injection from practical experience, practical framing for founder audiences, and anti-pattern avoidance.

## Agent Teams

This plugin does not use Agent Teams.

## Dependencies

This plugin has no dependencies on other Founder OS plugins.

## License

MIT
