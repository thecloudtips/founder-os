---
description: Process a single invoice file, extracting vendor, amount, date, and line items. Supports two modes: fast single-agent extraction (default) or full 5-agent pipeline with Notion recording (--team flag).
argument-hint: "[file-path] [--team] [--output=PATH]"
allowed-tools: [mcp__filesystem__read_file, mcp__notion__create_page, mcp__notion__search]
---

# /founder-os:invoice:process

Process a single invoice file and extract structured data.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Modes

### Default Mode (Fast, No Notion Required)

When invoked without `--team`, read the invoice file directly and output a formatted summary to the user.

1. Read the invoice file from the provided path.
2. Apply the invoice-extraction skill: extract vendor, amount, date, line items, totals.
3. Apply the expense-categorization skill: assign categories to line items.
4. Output a formatted markdown summary to the user.
5. Do NOT write to Notion in default mode.

**Output format:**

```
## Invoice: [VENDOR NAME]
**Invoice #**: INV-2024-0042
**Date**: January 15, 2024 | **Due**: February 14, 2024
**Total**: $513.00 USD

### Line Items
| Description | Qty | Unit Price | Total | Category |
|-------------|-----|-----------|-------|----------|
| Office Supplies - Q1 Bundle | 1 | $450.00 | $450.00 | office_supplies |
| Shipping and Handling | 1 | $25.00 | $25.00 | shipping |

**Subtotal**: $475.00 | **Tax**: $38.00 | **Total**: $513.00
**Primary Category**: office_supplies | **Tax Deductible**: Yes
```

If `--output=PATH` is specified, also write the summary as a markdown file to that path.

### Team Mode (Full Pipeline + Notion)

When invoked with `--team`, run the complete 5-agent pipeline:

1. **extraction-agent**: Read and extract structured data from the file.
2. **validation-agent**: Verify mathematical correctness and completeness.
3. **categorization-agent**: Assign expense categories to line items.
4. **approval-agent**: Detect anomalies; create Notion approval request if needed.
5. **integration-agent**: Record the invoice in the Notion Finance database with `Type = "Invoice"`. DB discovery order: **"[FOS] Finance"** first, then "Founder OS HQ - Finance", then "Invoice Processor - Invoices" as legacy fallback. Links vendor to the Companies DB via Company relation when a match exists.

Show progress as each agent completes. Display the final Notion record URL.

## Supported File Formats

PDF, JPG, JPEG, PNG, TIFF. Return an error for unsupported formats.

## Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `[file-path]` | Yes | Path to the invoice file |
| `--team` | No | Run full 5-agent pipeline with Notion integration |
| `--output=PATH` | No | Save formatted summary to a local file |

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Examples

```
/founder-os:invoice:process /invoices/2024/adobe-dec.pdf
/founder-os:invoice:process ~/Downloads/contractor-invoice.jpg --team
/founder-os:invoice:process /invoices/acme-jan.pdf --output=/reports/acme-summary.md
```

## Error Handling

- **File not found**: Tell the user the file path doesn't exist. Suggest checking the path.
- **Unsupported format**: Tell the user which formats are supported (PDF, JPG, JPEG, PNG, TIFF).
- **Notion unavailable** (in `--team` mode): Inform the user that Notion integration failed but show the extracted and categorized data.
