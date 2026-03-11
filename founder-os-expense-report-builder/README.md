# founder-os-expense-report-builder

> **Plugin #16** -- Generates comprehensive expense reports from processed invoices and local receipt files

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | Code Without Coding |
| **Platform** | Claude Code |
| **Type** | Chained |
| **Difficulty** | Beginner |
| **Week** | 17 |

## What It Does

Aggregates expense data from P11 Invoice Processor's Notion DB and local receipt/invoice files, then produces structured 7-section Markdown reports. Reports include category breakdowns across the 14-category expense taxonomy, vendor summaries with top-N ranking, tax deductibility analysis with deductible vs. non-deductible totals, budget code allocation mapped to department codes, and period-over-period trend comparisons that flag significant spending changes. A lightweight summary command provides quick ephemeral overviews directly in chat without file output or Notion logging.

## Requirements

### MCP Servers

- **Filesystem** (required) -- Read receipt/invoice files, write generated reports
- **Notion** (optional) -- Query Founder OS HQ Finance DB (or legacy P11 DB), track reports in HQ Reports DB
- **gws CLI** (optional) -- Access receipts from Google Drive via gws CLI

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md).

## Installation

See [INSTALL.md](INSTALL.md).

## Commands

| Command | Description |
|---------|-------------|
| `/expense:report [date-range]` | Generate full 7-section expense report with file output and Notion logging |
| `/expense:summary [date-range]` | Quick ephemeral expense summary to chat (no file, no Notion) |

## Skills

- **expense-categorization**: 14-category expense taxonomy with classification signals, tax deductibility rules, budget code mapping, and confidence scoring
- **expense-reporting**: 7-section report structure, date range parsing, data aggregation pipeline, trend analysis methodology, and report quality rules

## Agent Teams

This plugin does not use Agent Teams.

## Dependencies

- **#11 Invoice Processor**: Chains with P11 -- reads processed invoice data from "Founder OS HQ - Finance" (Type="Invoice") with fallback to legacy "Invoice Processor - Invoices" DB

## Blog Post

**Week 17**: "Expense Reports in 5 Minutes: From Chaos to Clarity"

## License

MIT
