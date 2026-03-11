# founder-os-client-health-dashboard

> **Plugin #10** -- Scans Notion CRM clients, computes 5 health metrics (Last Contact, Response Time, Open Tasks, Payment Status, Sentiment), and outputs a color-coded RAG dashboard with risk flags and recommended actions.

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | Code Without Coding |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Advanced |
| **Week** | 13 |

## What It Does

Monitors the health of all client relationships in your Notion CRM. Computes a composite health score (0-100) for each client by analyzing five weighted metrics: contact recency, email response times, open task completion, invoice payment history, and communication sentiment. Classifies clients into Green (healthy), Yellow (needs attention), and Red (at risk) tiers. Detects risk flags like escalation language, payment issues, and meeting cancellations. Caches results for 24 hours with on-demand refresh.

### Founder OS HQ Integration

When the **Founder OS HQ** consolidated workspace is available, health scores are written directly onto Company pages in the "Founder OS HQ - Companies" database -- no separate Health Scores database is created. This keeps all client data in one place. For users without the HQ template, the plugin falls back to a standalone "Client Health Dashboard - Health Scores" database (created automatically on first use).

## Requirements

### MCP Servers

- **Notion** (required) -- CRM client data (writes health scores to Company pages), task tracking
- **Gmail** (required) -- Email thread analysis for contact recency, response time, and sentiment
- **Google Calendar** (optional) -- Meeting pattern analysis for sentiment and contact supplementation

### Cross-Plugin Integration

- **#20 Client Context Loader** (optional) -- Reads cached client dossiers when fresh (< 24h) to supplement scoring
- **#11 Invoice Processor** (optional) -- Reads invoice payment data for the Payment Status metric

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/client:health-scan` | Scan all CRM clients and compute health scores with RAG dashboard |
| `/client:health-report` | Generate a detailed health report for a single client |

## Skills

- **Client Health Scoring**: 5-metric composite scoring algorithm (Last Contact 0.25, Response Time 0.20, Open Tasks 0.20, Payment 0.20, Sentiment 0.15), RAG classification, data source integration, caching strategy, and risk flag taxonomy.
- **Sentiment Analysis**: Email sentiment extraction from Gmail threads, meeting pattern analysis from Google Calendar, signal detection dictionaries, and composite sentiment scoring (0-100).

## Agent Teams

This plugin does not use Agent Teams.

## Dependencies

- **Notion CRM** (required): Companies database with contacts, status, and communications relations. Prefers "Founder OS HQ - Companies" (consolidated), falls back to standalone CRM or lazy-created Health Scores DB.
- **#20 Client Context Loader** (optional): Provides cached dossier data. Plugin operates independently when not available.
- **#11 Invoice Processor** (optional): Provides invoice payment history. Uses neutral defaults when not available.

## License

MIT
