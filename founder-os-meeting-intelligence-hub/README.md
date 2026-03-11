# founder-os-meeting-intelligence-hub

> **Plugin #07** -- Multi-source transcript aggregator with intelligence extraction

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | Daily Work |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Medium |
| **Week** | 11 |

## What It Does

Gathers meeting transcripts from multiple sources -- Fireflies.ai, Notion meeting notes, Otter.ai, Gemini (Google Drive), and local files -- then extracts intelligence: summaries, key decisions, follow-up commitments, and topic tags. Results are saved to a Notion database and/or displayed in chat.

Key capabilities:
- **5 source adapters** with auto-detection from content patterns
- **4 extraction pipelines** running independently (summary, decisions, follow-ups, topics)
- **Unified NormalizedTranscript** format across all sources
- **Cross-plugin integration** with #04 Action Item Extractor and #06 Follow-Up Tracker

## Requirements

### MCP Servers

- **Notion** (required) -- Meeting notes source + intelligence output database
- **Filesystem** (required) -- Read local transcript files
- **Google Drive** (optional) -- Access Gemini-generated meeting transcripts
- **Gmail** (optional) -- Email context enrichment for meetings

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/meeting:intel [source-or-file]` | Full pipeline: gather transcript, analyze, save to Notion |
| `/meeting:analyze [text-or-file]` | Analysis only: extract intelligence from provided transcript |

## Skills

- **source-gathering**: Multi-source transcript gathering with auto-detection, 5 source adapters, and NormalizedTranscript normalization
- **meeting-analysis**: 4-pipeline intelligence extraction (summaries, decisions, follow-ups, topics) with Notion integration

## Notion Database

Writes to the shared **"[FOS] Meetings"** database (falls back to "Founder OS HQ - Meetings", then legacy "Meeting Intelligence Hub - Analyses"). Shares the Event ID as an idempotent key with P03 Meeting Prep Autopilot -- when one plugin creates a record, the other updates it rather than creating a duplicate.

**P07-owned fields**: Source Type, Transcript File, Summary, Decisions, Follow-Ups, Topics, Duration, Company (relation)

## Agent Teams

This plugin does not use Agent Teams.

## Dependencies

- **#03 Meeting Prep Autopilot**: Shares "[FOS] Meetings" database via Event ID idempotent key
- **#04 Action Item Extractor**: Suggests `/actions:extract-file` on transcripts for deeper action extraction
- **#06 Follow-Up Tracker**: Follow-up commitments use compatible promise pattern format

## License

MIT
