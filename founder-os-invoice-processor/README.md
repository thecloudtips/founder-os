# Founder OS: Invoice Processor

**Plugin #11** | Pillar: Code Without Coding | Platform: Claude Code | Week 4

> Process a year of invoices in minutes with a 5-agent AI pipeline that extracts, validates, categorizes, approves, and records every invoice.

## What It Does

The Invoice Processor reads invoice files (PDF, JPG, PNG, TIFF) and extracts structured data — vendor, amounts, dates, line items — then validates the math, assigns expense categories, flags anomalies for approval, and records everything in your Notion accounting database.

Two modes for every command:
- **Default**: Fast single-agent extraction with no external dependencies
- **`--team`**: Full 5-agent pipeline with Notion integration for year-end accounting

## Commands

| Command | Description |
|---------|-------------|
| `/invoice:process [file]` | Process a single invoice file |
| `/invoice:batch [folder]` | Process all invoices in a folder |

### Key Options

| Flag | Description |
|------|-------------|
| `--team` | Run the full 5-agent pipeline with Notion recording |
| `--since=DATE` | Filter folder processing by file date (e.g., `2024-01-01`) |
| `--concurrency=N` | Parallel pipelines in team mode (default: 5) |
| `--output=PATH` | Save results to a local file |

## Examples

```bash
# Quick extraction of a single invoice
/invoice:process /invoices/adobe-dec.pdf

# Full pipeline with Notion recording
/invoice:process ~/Downloads/contractor-invoice.jpg --team

# Process all 2024 Q4 invoices through the full pipeline
/invoice:batch /invoices/2024/q4/ --team --since=2024-10-01

# Year-end batch processing
/invoice:batch /invoices/2024/ --team --output=/reports/2024-annual.md
```

## The 5-Agent Pipeline

When using `--team`, each invoice goes through:

```
invoice.pdf
    ↓
[1] Extraction Agent    → OCR + structured field extraction
    ↓
[2] Validation Agent    → Math checks, date validation, auto-corrections
    ↓
[3] Categorization Agent → Expense categories (14 standard types)
    ↓
[4] Approval Agent      → Anomaly detection, Notion approval requests
    ↓
[5] Integration Agent   → Records in Founder OS HQ - Finance (Type: Invoice)
```

Up to 5 invoices processed in parallel (configurable with `--concurrency`).

## Skills

| Skill | Purpose |
|-------|---------|
| `invoice-extraction` | OCR processing, field extraction, confidence scoring |
| `expense-categorization` | 14-category taxonomy, tax deductibility, budget codes |

## Requirements

| Dependency | Required | Purpose |
|------------|----------|---------|
| Filesystem MCP | Yes | Read invoice files |
| Notion MCP | Yes | Record invoices, create approval requests |
| gws CLI | Optional | Fetch invoice attachments from Gmail, access invoices in Google Drive |

## Expense Categories

14 standard categories with tax-deductibility rules:

`office_supplies` · `software` · `hardware` · `professional_services` · `travel` · `meals` · `shipping` · `utilities` · `rent` · `insurance` · `marketing` · `training` · `subscriptions` · `other`

## Notion Databases

This plugin writes to the consolidated **Founder OS HQ - Finance** database. Each record is tagged with a `Type` property.

| Type | Purpose |
|------|---------|
| Invoice | All processed invoices with categories and approval status |
| Approval | Invoices flagged for human review |

Vendor names are linked to the **Companies** database via a Company relation when a match is found.

> **Fallback**: If "Founder OS HQ - Finance" is not found, the plugin falls back to the legacy "Invoice Processor - Invoices" / "Invoice Processor - Approvals" databases. Deploy the HQ template from `_infrastructure/notion-db-templates/founder-os-hq-finance.json` for the consolidated experience.

## Anomaly Detection

The approval agent automatically flags:
- Invoices over $5,000 (requires approval)
- First-time vendors (needs review)
- Invoices older than 90 days (needs review)
- Duplicate invoice numbers (rejected)
- Low categorization confidence items (needs review)

## Installation

See [INSTALL.md](INSTALL.md) for setup instructions.

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for your first invoice processing run.
