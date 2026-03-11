---
description: Quick expense summary for a date range — totals, category breakdown, top vendors, tax deductible amount
argument-hint: "[date-range] [--top=10]"
allowed-tools: ["Read"]
---

# Expense Summary

Ephemeral spending overview for a given period. Output directly to chat — no file saving, no Notion DB write. This is the lightweight counterpart to `/founder-os:expense:report`, optimized for a quick "how much did I spend?" answer.

## Load Skills

Read the expense-reporting skill at `${CLAUDE_PLUGIN_ROOT}/skills/expense/expense-reporting/SKILL.md` for date range parsing rules, the data aggregation pipeline, and the P11 category taxonomy.

Read the expense-categorization skill at `${CLAUDE_PLUGIN_ROOT}/skills/expense/expense-categorization/SKILL.md` for the 14-category taxonomy, classification signals, and confidence scoring — needed when local files lack pre-assigned categories.

## Parse Arguments

Extract from `$ARGUMENTS`:

- `[date-range]` (optional) — the period to summarize. Accepts all formats defined in the expense-reporting skill's Date Range Parsing section:
  - Explicit: `YYYY-MM`, `Q1 YYYY` through `Q4 YYYY`, `YYYY-MM to YYYY-MM`
  - Relative: `this month`, `last month`, `this quarter`, `last quarter`
  - Default when omitted: current calendar month
- `--top=N` (optional) — maximum number of vendors to display in the Top Vendors table. Default: `10`. Minimum: `1`.

Resolve the date range into concrete `start_date` and `end_date` using the skill's parsing rules. Apply the same validation: reject future end dates beyond today (clamp and note "partial period"), reject end-before-start.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Data Gathering

Follow the expense-reporting skill's Data Aggregation Pipeline (Steps 1-3) to collect expense data for the resolved date range.

### Step 1: Notion Query (Primary)

When Notion MCP is available, search for the "[FOS] Finance" database. If not found, fall back to "Founder OS HQ - Finance". If not found, fall back to searching for the legacy name "Invoice Processor - Invoices". Filter by `Type` equal to "Invoice" (HQ database only -- skip this filter for legacy DB), `Invoice Date` within the resolved range, and `Approval Status` equal to "approved". Extract: Vendor, Amount, Currency, Category, Tax Deductible, Invoice Date.

When Notion is unavailable, skip silently and proceed to Step 2.

### Step 2: Local File Scan (Secondary)

Scan the working directory and `receipts/` or `invoices/` subdirectories for `*.csv` files containing expense data. Parse rows for date, vendor, amount, and category columns. Skip image and PDF files — this is a summary command, not a processing command.

### Step 3: Merge and Deduplicate

Apply the same deduplication rules from the skill: Invoice # match first, then Vendor + Amount + Date (within 3 days). Keep Notion records over local duplicates.

After merging, filter the dataset to only entries where `Invoice Date` falls within the resolved `start_date` to `end_date`.

## Aggregation

From the merged dataset, compute:

1. **Total spending**: Sum of all amounts.
2. **Invoice count**: Number of unique expense entries.
3. **Category aggregation**: For each of the 14 P11 categories that has non-zero spend — sum the amount and compute percentage of total. Sort by amount descending.
4. **Vendor aggregation**: For each unique vendor — sum the total amount and count the number of invoices. Sort by total descending. Keep only the top N vendors (from `--top` argument).
5. **Tax deductible total**: Apply the tax deductibility rules from the expense-reporting skill:
   - Fully deductible categories: 100% of amount.
   - Meals: 50% of amount.
   - Travel: 85% of amount (conservative default when line-item split unavailable).
   - Other: excluded from deductible total.
   - Sum = fully deductible amount + partial deductible amount.

## Output Format

Display the summary directly in chat. Use this exact structure.

### Data Found

```
## Expense Summary -- [Period Label]

**Total:** $[amount] across [count] invoices

### By Category
| Category | Amount | % |
|:---------|-------:|--:|
| [category] | $[amount] | [pct]% |
| ... | ... | ... |

### Top [N] Vendors
| Vendor | Total | Invoices |
|:-------|------:|---------:|
| [vendor] | $[amount] | [count] |
| ... | ... | ... |

**Tax Deductible:** $[deductible_amount] ([pct]% of total)
```

Formatting rules:
- Period Label uses human-readable format: "March 2024", "Q1 2024", "January -- March 2024".
- All amounts formatted with dollar sign, commas for thousands, two decimal places (e.g., `$12,847.50`).
- Percentages to one decimal place (e.g., `33.3%`).
- Right-align Amount and percentage columns in tables.
- Omit categories with zero spend from the By Category table (unlike the full report which shows all 14).
- If more vendors exist beyond the top N, add a note after the table: "_[M] additional vendors not shown_".
- Tax Deductible line shows the combined fully + partial deductible amount and its percentage of total spending.

### Partial Period

When the end date was clamped to today, append after the header line:

```
_Partial period -- data through [today's date]_
```

### No Data Found

```
## Expense Summary -- [Period Label]

No expenses found for [Period Label]. Run `/founder-os:invoice:process` to import invoices, or check that the date range is correct.
```

### Notion Unavailable

When Notion was skipped, append a note at the bottom of the output:

```
_Summary from local files only -- Notion data unavailable_
```

## No Persistence

This command does NOT save output to a file or write to a Notion database. It is ephemeral by design. For a full 7-section report with file output and Notion logging, use `/founder-os:expense:report`.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Graceful Degradation

**Notion MCP unavailable**: Continue with local files only. Add the "local files only" note to the output footer.

**No data in period**: Display the "No expenses found" message. Do not error.

**Mixed currencies**: Report amounts in the majority currency. Add a note: "_[N] entries in other currencies excluded -- run `/founder-os:expense:report` for full multi-currency handling_".

## Usage Examples

```
/founder-os:expense:summary
/founder-os:expense:summary 2024-03
/founder-os:expense:summary Q1 2024
/founder-os:expense:summary "last month"
/founder-os:expense:summary "this quarter" --top=5
/founder-os:expense:summary "last quarter" --top=20
```
