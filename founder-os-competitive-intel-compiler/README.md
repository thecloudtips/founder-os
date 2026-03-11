# founder-os-competitive-intel-compiler

> **Plugin #15** — Research competitors via web search and compile structured competitive intelligence reports with pricing, features, positioning, reviews, and strategic recommendations.

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | Code Without Coding |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Intermediate |
| **Week** | 16 |

## What It Does

Competitive Intel Compiler gathers intelligence on any competitor in minutes. Run a single command and get a structured report covering pricing, features, customer reviews, positioning, and recent news — all from live web searches. Build side-by-side comparison matrices for 2+ competitors. Optionally compare against your own product to identify gaps and positioning opportunities.

**Key capabilities:**
- 4-6 targeted web searches per competitor across 5 research dimensions
- Pricing normalization (per user/month, annual vs monthly, free tiers)
- Review aggregation from G2, Capterra, and ProductHunt
- Positioning archetype classification (Enterprise Leader, SMB Friendly, Developer-First, etc.)
- 'vs You' self-comparison analysis with differentiation recommendations
- Multi-competitor comparison matrices
- Notion integration via consolidated "Founder OS HQ - Research" database (optional, falls back to legacy DB name)

## Requirements

### MCP Servers

| Server | Purpose | Required |
|--------|---------|----------|
| **WebSearch** | Research competitors via live web search | Built-in (no setup needed) |
| **Filesystem** | Save reports to local files | ✅ Required |
| **Notion** | Store research in "Founder OS HQ - Research" (consolidated) | Optional |

### Platform

- **Claude Code** with internet access (WebSearch tool must be available)

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/compete:research [company]` | Research a single competitor and produce a structured intelligence report |
| `/compete:matrix [company1] [company2] ...` | Build a comparison matrix for 2+ competitors |

### Flags (both commands)

| Flag | Description |
|------|-------------|
| `--your-product="description"` | Add self-comparison analysis showing where you win/lose |
| `--output=PATH` | Custom output file path |

## Skills

- **competitive-research**: Surface scan web research strategy — query formulation, data extraction, pricing normalization, review scoring, source credibility, and finding deduplication
- **market-analysis**: Strategic synthesis — SWOT analysis, competitive positioning archetypes, 'vs You' feature gap analysis, and strategic recommendation generation

## Dependencies

This plugin has no dependencies on other Founder OS plugins.

## Blog Post

**Week 16**: "Know Your Competition Better Than They Know Themselves"

Use AI to research competitors in minutes instead of hours — pricing, features, reviews, and positioning, all from live web data.

## License

MIT
