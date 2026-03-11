# founder-os-client-context-loader

> **Plugin #20** -- Parallel-gathering plugin that pulls client data from Notion CRM, Gmail, Google Drive, and Google Calendar — assembling a complete client dossier in under 30 seconds.

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | MCP & Integrations |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Intermediate |
| **Week** | 2 |

## What It Does

Client Context Loader gathers data from five sources simultaneously and merges it into a unified client dossier. It operates in two modes:

- **Default mode**: Quick single-agent lookup that searches CRM and email to present a structured dossier with profile, activity, open items, and sentiment.
- **Team mode** (`--team`): Full 6-agent parallel pipeline that dispatches 5 gatherer agents simultaneously (CRM, Email, Docs, Calendar, Notes), then synthesizes results through a Context Lead agent — caching dossiers in Notion and writing enrichments back to CRM.

### Architecture

Uses the **Parallel Gathering** agent pattern:

```
/client:load "Acme Corp" --team
        │
        ├── CRM Agent ──────────┐
        ├── Email Agent ────────┤
        ├── Docs Agent ─────────┤── Context Lead ── Dossier
        ├── Calendar Agent ─────┤
        └── Notes Agent ────────┘
```

- **5 gatherer agents** run simultaneously, each pulling from a different data source
- **1 context lead** merges all outputs, calculates health metrics, caches results, and writes enrichments
- **Graceful degradation**: Pipeline succeeds with just 1 source (minimum_gatherers_required=1)

## Requirements

### MCP Servers

| Server | Required | Purpose |
|--------|----------|---------|
| **Notion** | Yes | CRM Pro databases (Companies, Contacts, Deals, Communications) — dossiers cached on Companies pages |
| **Gmail** | Yes | Email communication history and sentiment analysis |
| **Google Drive** | Optional | Client-related documents (proposals, contracts, reports) |
| **Google Calendar** | Optional | Meeting history and upcoming engagements |

### Founder OS HQ / CRM Pro Template

This plugin integrates with the **Founder OS HQ** consolidated workspace or a standalone **CRM Pro** Notion template. The plugin auto-discovers databases in this order: "[FOS] Companies" → "Founder OS HQ - Companies" → "Companies" / "CRM - Companies" → fallback "Client Dossiers".

Dossiers are stored as properties directly on the Companies page (Dossier, Dossier Completeness, Dossier Generated At, Dossier Stale) rather than in a separate database.

> **Credit**: CRM Pro template by [Mindful Yesmads](https://www.notion.so/templates/crm-plus). Duplicate the template to your Notion workspace and share with your Notion integration.

### Platform

- **Claude Code** with Node.js 18+ and npx

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/client:load [name]` | Load complete client context from all sources into a unified dossier |
| `/client:load [name] --team` | Run the full 6-agent parallel pipeline |
| `/client:brief [name]` | Generate a concise 1-page client brief for meeting preparation |

## Skills

- **Client Context** (`skills/client-context/`): Data source hierarchy, CRM Pro schema mapping, fuzzy matching, extraction rules, deduplication, completeness scoring, and dossier structure.
- **Relationship Summary** (`skills/relationship-summary/`): Sentiment scoring rubric, engagement metrics, risk flag criteria, health score formula, executive brief template, and CRM enrichment writeback rules.

## Agent Teams

This plugin uses a **Parallel Gathering** Agent Team pattern with 6 agents.

| Agent | Role | Source | Required |
|-------|------|--------|----------|
| **CRM Agent** | Pull company, contacts, deals, communications | Notion | Yes |
| **Email Agent** | Gather email history and sentiment | Gmail | Yes |
| **Docs Agent** | Find proposals, contracts, reports | Google Drive | No |
| **Calendar Agent** | Meeting history and upcoming events | Google Calendar | No |
| **Notes Agent** | Decisions, action items, open items | Notion | Yes |
| **Context Lead** | Synthesize, cache on Companies page, enrich CRM | Notion | -- |

See `teams/` for agent definitions and configuration.

## CRM Pro Enrichments

The plugin optionally writes calculated values back to your CRM:

| Database | Property | Type | What It Does |
|----------|----------|------|-------------|
| Companies | Client Health Score | Number (0-100) | Composite relationship health metric |
| Deals | Risk Level | Select | High/Medium/Low based on deal stall + engagement |
| Communications | Sentiment | Select | Auto-detected Positive/Neutral/Negative |

Enrichments are optional — the plugin works with the base CRM Pro template but provides richer insights when these properties are added.

## Dependencies

- **Enhances**: #03 Meeting Prep Autopilot (provides client context for meeting prep)
- **Related**: #21 CRM Sync Hub (bidirectional CRM updates)

## Blog Angle

**Week 2**: "Know Everything About Your Client in 30 Seconds"

## License

MIT
