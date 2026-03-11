# founder-os-contract-analyzer

> **Plugin #13** -- Analyzes legal contracts to extract key terms, flag risky clauses using RAG classification, and compare contract terms against standard templates for freelancers and agencies.

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | Code Without Coding |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Advanced |
| **Week** | 15 |

## What It Does

Contract Analyzer reads legal documents (PDF, DOCX, MD, TXT), extracts structured data across 7 key term categories, evaluates each clause for legal risk using a Red-Amber-Green classification system, and optionally compares terms against standard freelancer/agency benchmarks. Results are displayed as structured reports and optionally saved to Notion for tracking.

Designed for freelancers and small agency founders who need to quickly understand contract terms without legal expertise. Not a substitute for legal advice.

## Requirements

### MCP Servers

- **Filesystem** (required) -- Read contract files from the local filesystem
- **Notion** (optional) -- Store analysis results in a tracking database

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/contract:analyze [file-path]` | Analyze a contract to extract key terms, detect risks, and produce a structured report |
| `/contract:compare [file-path]` | Analyze a contract and compare its terms against standard freelancer/agency benchmarks |

## Skills

- **contract-analysis**: Contract structure recognition, file format handling, contract type detection, key term extraction across 7 categories (Payment, Duration/Renewal, IP, Confidentiality, Liability, Termination, Warranty), output formatting, and Notion integration.
- **legal-risk-detection**: 3-tier RAG classification system (Red/Yellow/Green), 7 risk categories for freelancers and agencies, risk flag taxonomy with 35 patterns, comparison logic against standard terms, and structured risk reporting.

## Agent Teams

This plugin does not use Agent Teams.

## Notion Storage

This plugin writes to the consolidated **"Founder OS HQ - Deliverables"** database with `Type = "Contract"`. If the HQ database is not found, it falls back to the legacy "Contract Analyzer - Analyses" database. The plugin does not lazy-create either database. See `_infrastructure/notion-db-templates/hq-deliverables.json` for the HQ schema.

When a contract party matches a record in the CRM Pro "Companies" database, the Company relation is automatically set.

## Dependencies

This plugin has no dependencies on other Founder OS plugins.

## Templates

- **contract-checklist.md** -- 10-section review checklist with 52 verification items
- **standard-terms.md** -- Baseline acceptable terms for freelancer/agency contracts across 7 categories with Standard/Acceptable/Red Flag thresholds

## License

MIT
