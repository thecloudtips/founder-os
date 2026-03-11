# Quick Start: founder-os-expense-report-builder

> Generates comprehensive expense reports from processed invoices and local receipt files

## Overview

**Plugin #16** | **Pillar**: Code Without Coding | **Platform**: Claude Code

Aggregates expense data from P11 Invoice Processor and local receipt files into structured 7-section Markdown reports with category breakdowns, vendor summaries, tax analysis, and trend comparisons.

### What This Plugin Does

- Generates full expense reports with 7 sections (Cover Page, Executive Summary, Category Breakdown, Vendor Summary, Tax Deductibility, Budget Codes, Trend Analysis)
- Provides quick ephemeral expense summaries directly in chat
- Chains with P11 Invoice Processor for pre-processed invoice data
- Categorizes local receipts using the 14-category expense taxonomy
- Compares spending against previous periods with trend flagging

## Available Commands

| Command | Description |
|---------|-------------|
| `/expense:report [date-range]` | Generate full 7-section report saved to file |
| `/expense:summary [date-range]` | Quick spending overview in chat |

## Usage Examples

### Example 1: Full Report for Current Month

```
/expense:report
```

**What happens:** Generates a complete expense report for the current month, querying P11's Notion DB and local files. Saves to `expense-reports/[period]-[date].md` and logs to Notion.

### Example 2: Quick Summary for Last Quarter

```
/expense:summary "last quarter" --top=5
```

**What happens:** Shows a compact spending breakdown for last quarter with the top 5 vendors. Output goes directly to chat -- no files saved.

### Example 3: Report for a Specific Month

```
/expense:report 2024-03 --output=./reports/
```

**What happens:** Generates a March 2024 expense report saved to the specified output directory.

### Example 4: Quarterly Report from Notion Only

```
/expense:report Q1 2024 --sources=notion
```

**What happens:** Generates a Q1 2024 report using only data from P11's Notion database (no local file scan).

## Tips

- Run `/expense:summary` first to get a quick overview before generating a full report
- Use `--sources=local` when Notion is unavailable or for offline receipts only
- The plugin auto-detects date formats: `2024-03`, `Q1 2024`, `last month`, `this quarter` all work
- Reports include trend analysis comparing current period to the previous period of equal length
- Items with category confidence below 0.7 are flagged for manual review

## Related Plugins

This plugin connects with:
- **#11 Invoice Processor**: Reads processed invoice data from the "Invoice Processor - Invoices" Notion database. Run `/invoice:process` or `/invoice:batch` first to populate Notion with categorized invoices.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "No expenses found" | Ensure invoices exist in P11 Notion DB or local directory |
| Notion unavailable | Plugin gracefully degrades to local files only |
| Missing categories | Run `/invoice:process` on raw receipts first for best results |
| Duplicate entries | Deduplication runs automatically by Invoice # or vendor+amount+date |

## Next Steps

1. Try `/expense:summary` for a quick overview
2. Generate a full report with `/expense:report`
3. Explore `skills/` folder for the expense categorization taxonomy and report structure
4. Check `INSTALL.md` for MCP server configuration
