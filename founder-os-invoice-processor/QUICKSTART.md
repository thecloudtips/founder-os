# Quick Start: Invoice Processor

Get up and running in 5 minutes.

## Your First Invoice (Default Mode)

No Notion setup required. Just point at any invoice file:

```
/invoice:process /path/to/invoice.pdf
```

**Expected output:**

```
## Invoice: Adobe Inc.
**Invoice #**: INV-2024-12345
**Date**: December 1, 2024 | **Due**: January 1, 2025
**Total**: $659.88 USD

### Line Items
| Description | Qty | Unit Price | Total | Category |
|-------------|-----|-----------|-------|----------|
| Creative Cloud All Apps - Annual | 1 | $659.88 | $659.88 | subscriptions |

**Subtotal**: $659.88 | **Tax**: $0.00 | **Total**: $659.88
**Primary Category**: subscriptions | **Tax Deductible**: Yes
```

## Process a Folder (Default Mode)

```
/invoice:batch /invoices/2024/
```

You'll get a table showing all invoices, categories, and totals.

## Year-End Batch Processing (Team Mode)

Set up Notion first (see [INSTALL.md](INSTALL.md)), then:

```
/invoice:batch /invoices/2024/ --team --output=/reports/2024-annual.md
```

This runs the full 5-agent pipeline on every invoice:
1. Extracts all data
2. Validates math and dates
3. Assigns expense categories
4. Flags anything unusual for your review
5. Records everything in your Notion **"Founder OS HQ - Finance"** database (Type: Invoice)

## Common Scenarios

### Process Q4 invoices only

```
/invoice:batch /invoices/ --since=2024-10-01 --team
```

### Process a single contractor invoice with full pipeline

```
/invoice:process ~/Downloads/contractor-nov.pdf --team
```

### Save the batch summary to a file

```
/invoice:batch /invoices/2024/ --output=/reports/2024-summary.md
```

### Process invoices with slower system (reduce concurrency)

```
/invoice:batch /invoices/ --team --concurrency=2
```

## What Gets Flagged for Review

The approval agent automatically flags unusual items in your Notion **"Founder OS HQ - Finance"** database (Type: Approval):

| Flag | Why |
|------|-----|
| Amount > $5,000 | Requires manager approval |
| First-time vendor | New vendor, verify before paying |
| Invoice > 90 days old | Late payment risk |
| Duplicate invoice # | Potential double-payment |
| Low categorization confidence | AI uncertain, human check needed |

## Supported File Types

- **PDF** (native text or scanned)
- **JPG / JPEG**
- **PNG**
- **TIFF**

Other file types (DOCX, XLSX, etc.) are silently skipped in batch mode.

## Tips

- **Default mode is fast**: Use it for quick checks or when you don't need Notion integration
- **Team mode is thorough**: Use it for year-end accounting or when you need a full audit trail
- **Batch concurrency**: Default 5 parallel pipelines works well; reduce to 2-3 on slower systems
- **Check Approvals first**: After batch processing, filter "Founder OS HQ - Finance" by Type="Approval" in Notion before paying any flagged invoices
