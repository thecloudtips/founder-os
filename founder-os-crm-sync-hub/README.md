# founder-os-crm-sync-hub

> **Plugin #21** — Sync email and calendar activities to Notion CRM Pro with intelligent client matching, AI-generated summaries, and deduplication.

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | MCP & Integrations |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Advanced |
| **Week** | 21 |

## What It Does

CRM Sync Hub bridges the gap between your communication tools (Gmail, Google Calendar) and your Notion CRM. Run a command to log email conversations and meeting activities as structured CRM records — with AI-generated summaries, automatic client matching, and smart deduplication.

**Key capabilities:**
- Sync individual email threads or batch-process recent sent emails
- Sync individual meetings or batch-process recent calendar events
- Intelligent 5-step client matching (email domain → contact lookup → fuzzy name)
- AI-generated 2-3 sentence summaries per activity
- Sentiment classification (Positive/Neutral/Negative)
- Deduplication prevents duplicate CRM records on re-sync
- Fast CRM-only context view for any client
- Dry run mode for previewing without writing
- Notion integration for CRM Pro Communications database

## Requirements

### MCP Servers

| Server | Purpose | Required |
|--------|---------|----------|
| **Notion** | CRM database reads and writes | ✅ Required |
| **Gmail** | Email thread retrieval | ✅ Required |
| **Google Calendar** | Meeting event retrieval | ✅ Required |

### Platform

- **Claude Code** with Notion, Gmail, and gws CLI (`gws calendar`)s configured

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/crm:sync-email [thread_id]` | Sync email threads to CRM — single thread or batch mode |
| `/crm:sync-meeting [event_id]` | Sync calendar meetings to CRM — single event or batch mode |
| `/crm:context [client]` | Load CRM context for a client (read-only) |

### Common Flags

| Flag | Commands | Description |
|------|----------|-------------|
| `--since=Nd` | sync-email, sync-meeting | Batch lookback window (default: 7d) |
| `--client=NAME` | sync-email, sync-meeting | Skip matching, assign to named client |
| `--dry-run` | sync-email, sync-meeting | Preview without writing to CRM |
| `--upcoming` | sync-meeting | Include future meetings |
| `--days=N` | context | Activity lookback (default: 30) |
| `--full` | context | Show full activity summaries |

## Skills

- **crm-sync**: Central orchestration — sync pipeline workflow, batch processing, dry run mode, status reporting
- **activity-logging**: CRM write layer — Communications DB schema, AI summaries, deduplication, idempotent updates
- **client-matching**: Contact resolution — 5-step progressive matching, confidence scoring, domain-based lookup

## Dependencies

- **#20 Client Context Loader** — reads Communications DB data written by this plugin
- **#10 Client Health Dashboard** — uses Communications DB for "Last Contact" metric

## Blog Post

**Week 21**: "Notion as Your CRM: Automatic Email and Meeting Logging"

Use AI to automatically log client communications — summaries, sentiment, and contact matching, all flowing into your Notion CRM.

## License

MIT
