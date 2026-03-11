---
description: Generate a comprehensive expense report aggregating P11 Invoice Processor data and local receipts for any date range
argument-hint: "[date-range] --output=PATH --sources=notion|local|all"
allowed-tools: ["Read", "Write"]
---

# Generate Expense Report

Produce a 7-section Markdown expense report covering the requested date range. Aggregate data from the consolidated Notion "Founder OS HQ - Finance" database (filtered by Type="Invoice") and local receipt/invoice files, deduplicate, categorize uncategorized items, calculate tax deductibility, compare against the prior period, and save the report to disk and optionally to Notion.

## Load Skills

Read the expense-reporting skill at `${CLAUDE_PLUGIN_ROOT}/skills/expense-reporting/SKILL.md` for the 7-section report structure, date range parsing rules, data aggregation pipeline, trend analysis methodology, flagging thresholds, and report quality rules.

Read the expense-categorization skill at `${CLAUDE_PLUGIN_ROOT}/skills/expense-categorization/SKILL.md` for the 14-category taxonomy, vendor and description classification signals, confidence scoring, tax-deductibility rules, and budget code mapping.

Read the report template at `${CLAUDE_PLUGIN_ROOT}/templates/expense-report-template.md` as the structural scaffold for the final output.

## Parse Arguments

Extract from `$ARGUMENTS`:

- `[date-range]` (optional) -- Flexible period specification. Supported formats:
  - Explicit: `YYYY-MM` (single month), `Q1 YYYY` through `Q4 YYYY` (quarter), `YYYY-MM to YYYY-MM` (range)
  - Relative: `this month`, `last month`, `this quarter`, `last quarter`
  - Default when omitted: current calendar month
- `--output=PATH` (optional) -- File path or directory for the generated report. Default: `expense-reports/[period-slug]-[YYYY-MM-DD].md`
- `--sources=notion|local|all` (optional, default: `all`) -- Which data sources to query. `notion` = Founder OS HQ Finance database only, `local` = local files only, `all` = both sources merged.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Workflow

### Step 1: Parse Date Range

Resolve the date range argument into concrete `start_date` and `end_date` values (ISO 8601 YYYY-MM-DD) using the expense-reporting skill's date range parsing rules.

1. Apply the parsing rules in priority order: explicit formats first, then relative formats, then default to current month.
2. Validate the resolved range:
   - If the end date is in the future, clamp it to today and flag the report as a "partial period."
   - If the end date precedes the start date, ask the user: "The end date is before the start date. Please provide a valid date range."
3. Derive the period slug for file naming:
   - Monthly: `YYYY-MM` (e.g., `2024-03`)
   - Quarterly: `Q1-YYYY` (e.g., `Q1-2024`)
   - Multi-month: `YYYY-MM-to-YYYY-MM` (e.g., `2024-01-to-2024-03`)
4. Store `start_date`, `end_date`, `period_slug`, and `period_display` (human-readable form like "March 2024" or "Q1 2024") for downstream use.

### Step 2: Query Invoice Data from Notion

Skip this step if `--sources=local`.

If Notion MCP is available:

1. Search Notion for a database titled "[FOS] Finance".
2. If not found, fall back to "Founder OS HQ - Finance".
3. If not found, fall back to searching for the legacy name "Invoice Processor - Invoices".
3. If found, query with filters:
   - `Type` equals "Invoice" (HQ database only -- skip this filter for legacy DB)
   - `Invoice Date` is on or after `start_date` AND on or before `end_date`
   - `Approval Status` equals "approved"
4. Extract from each matching record: Invoice #, Vendor, Amount, Currency, Invoice Date, Due Date, Category, Tax Deductible, Budget Code, Line Items.
5. Record the count of approved invoices returned.
6. Also query for pending and rejected invoices in the same date range (count only) to report as excluded in the Executive Summary.

If Notion MCP is unavailable:
- Log "Notion unavailable -- skipping invoice data" and continue with local files only.
- Do not error or abort.

### Step 3: Scan Local Files for Receipts and Invoices

Skip this step if `--sources=notion`.

Scan the working directory and common receipt subdirectories for expense files:

1. Search for files matching `*.pdf`, `*.jpg`, `*.jpeg`, `*.png`, `*.tiff`, `*.csv` in:
   - The current working directory
   - `receipts/` subdirectory (if it exists)
   - `invoices/` subdirectory (if it exists)
2. For CSV files, parse rows as expense entries. Expect columns: date, vendor, amount, category, description. Handle missing columns gracefully.
3. For image and PDF files, read the file to extract any visible text content. If the file cannot be parsed or contains no recognizable expense data, record its path and flag as "unprocessed -- run `/invoice:process` first."
4. Record the total count of local files found and how many were parseable.

### Step 4: Categorize Uncategorized Local Items

For each local file entry that does not already carry a P11 category assignment, apply the expense-categorization skill:

1. Run through classification signals in priority order: vendor name signals, then description and line item signals, then amount-based signals as tiebreaker.
2. Assign: category, budget code, tax-deductible flag, and confidence score (0.0 to 1.0).
3. Flag any expense with confidence below 0.7 as "needs review."
4. For receipts spanning multiple categories, split into separate entries per category when line-item detail is available. When unavailable, assign the full amount to the dominant category and note "mixed-category receipt."

### Step 5: Merge and Deduplicate

Combine P11 Notion records and local file entries into a single unified expense dataset:

1. **Invoice # match**: If a local file's name or parsed content contains an Invoice # matching a Notion record, treat them as the same entry. Keep the Notion record (richer metadata).
2. **Vendor + Amount + Date match**: If vendor name matches (case-insensitive), amount is identical, and dates are within 3 calendar days, treat as duplicate. Keep the Notion record.
3. **Remaining local entries**: Include as separate line items. Tag each as "local-only -- not in Invoice Processor."
4. Record merge statistics: final merged count, Notion-sourced count, local-only count, and duplicates removed.

### Step 6: Aggregate by Category, Vendor, and Budget Code

From the merged dataset, compute the following aggregations:

1. **Category aggregation**: Sum amounts per category (all 14 categories), calculate percentage of total, count items per category.
2. **Vendor aggregation**: Sum amounts per vendor, count invoices per vendor, identify top category per vendor. Sort by total descending.
3. **Budget code aggregation**: Sum amounts per budget code, map to department names (OPS=Operations, TECH=Technology, SVC=Services, TRV=Travel, FAC=Facilities, ADM=Administration, MKT=Marketing, HR=Human Resources, GEN=General).

### Step 7: Calculate Tax Deductibility Totals

Compute the three-tier tax deductibility summary:

1. **Fully Deductible**: Sum all categories marked "Yes" at 100% of their amounts.
2. **Partially Deductible (50%)**: Sum `meals` at 50% of their amounts. For `travel`, split lodging/transport (100%) from travel meals (50%) when line-item detail is available. When detail is unavailable, estimate travel at 85% deductible.
3. **Non-Deductible / Pending Review**: Sum `other` category amounts. List these separately as "Pending Review" since deductibility cannot be determined automatically.
4. Calculate total deductible amount and percentage of overall spend.

### Step 8: Fetch Previous Period Data for Trend Analysis

Determine the previous period of identical length (e.g., if current is March 2024, previous is February 2024; if current is Q1 2024, previous is Q4 2023).

1. Query the same data sources used in Steps 2 and 3, but with the previous period's date range.
2. If previous period data exists, compute:
   - Total spend change (amount and percentage)
   - Invoice count change
   - Average invoice size change
   - Per-category percentage changes with flagging labels (Significant spike > +50%, Notable increase > +20%, Stable, Notable decrease < -20%, Significant drop < -50%, New spending, Eliminated)
   - Spending velocity: daily rate comparison (`total / days_in_period`)
3. If no previous period data exists, note "No prior period data available for comparison" and skip trend calculations.

### Step 9: Generate 7-Section Markdown Report

Build the complete report using the template scaffold. Generate all 7 sections in order -- never omit a section. Use "No data available for this section" when a section has insufficient data.

1. **Cover Page**: Report title ("Expense Report: [period_display]"), date range, generation date, data sources used, partial-period flag if applicable, re-run update note if overwriting.
2. **Executive Summary**: Total expenses (formatted with currency and thousands separators), invoice count, top category (name + amount + % of total), tax deductible percentage, period-over-period change (arrow + percentage). Note excluded pending/rejected invoice counts. Note if report uses partial data sources.
3. **Category Breakdown**: Table with all 14 categories. Columns: Category, Amount, % of Total, Items, Budget Code. Sort by Amount descending. Zero-spend categories show $0.00 and 0.0%. Include totals row.
4. **Vendor Summary**: Table of unique vendors sorted by Total descending. Columns: Vendor, Total, Invoices, Top Category. Limit to top 20; add "Other Vendors (N)" summary row if more than 20 exist.
5. **Tax Deductibility Summary**: Three-row table (Fully Deductible, Partially Deductible 50%, Non-Deductible/Pending Review). Columns: Classification, Amount, % of Total, Invoice Count. Include totals row. Add note listing partially deductible categories.
6. **Budget Code Allocation**: Table grouped by Budget Code. Columns: Budget Code, Department, Amount, % of Total. Sort by Amount descending.
7. **Trend Analysis**: Period-over-period comparison table, category shift analysis with flagging labels, spending velocity comparison. If no prior data, display "No prior period data available for comparison."

Apply report quality rules:
- Currency consistency: single currency throughout; flag mixed currencies for manual review.
- Rounding: amounts to 2 decimal places, percentages to 1 decimal place, ensure percentage columns sum to 100.0%.
- Right-align Amount and percentage columns. Left-align text columns.

### Step 10: Save Report and Update Notion

1. **Determine output path**: Use `--output` if provided. If `--output` is a directory, append the default filename. Default: `expense-reports/[period-slug]-[YYYY-MM-DD].md`.
2. **Create output directory** if it does not exist.
3. **Write the report file** using the Write tool.
4. **Upsert to Notion** (if Notion MCP is available):
   - Search for database named "[FOS] Reports".
   - If not found, fall back to "Founder OS HQ - Reports".
   - If not found, fall back to searching for the legacy name "Expense Report Builder - Reports".
   - If neither is found, skip Notion logging and note "Reports database not found -- report not saved to Notion" in the output. Do not create the database.
   - If found, check for existing record with matching Report Title + Date Range (idempotent upsert).
   - Create or update the record with current report data, setting Type="Expense Report" (HQ database only).
   - **Company relation**: If the expense data is predominantly from a single vendor/company (i.e., a majority of invoices in the report share the same vendor), look up that company in the Companies DB (search "[FOS] Companies" first, then "Founder OS HQ - Companies"). If a match is found, set the Company relation property. If expenses are spread across multiple vendors with no clear majority, leave the Company relation empty.
5. If Notion is unavailable, skip upsert and note "Report not saved to Notion -- Notion unavailable" in the output.
6. If the output directory is not writable, output the full report content to chat with a warning.

### Present Summary

Display the completion summary:

```
## Expense Report Generated

**Period**: [period_display] ([start_date] to [end_date])
**Output**: [file path]
**Saved to Notion**: [Yes/No]
**Sources Used**: [Notion + Local / Notion only / Local only]

### Key Metrics
| Metric | Value |
|--------|-------|
| Total Expenses | $XX,XXX.XX |
| Invoice Count | N |
| Top Category | [category] ($X,XXX.XX, XX.X%) |
| Tax Deductible | XX.X% |
| vs. Prior Period | [arrow] XX.X% |

### Flagged Items
- N items need category review (confidence < 0.7)
- N unprocessed files (run /invoice:process first)
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Graceful Degradation

- **Notion MCP unavailable**: Use local files only. Skip Notion logging. Note "Report generated from local files only -- Notion data unavailable" in the Executive Summary. Omit fields that depend on P11 metadata (Budget Code, Tax Deductible) unless local CSV contains those columns.
- **No local files found**: Use Notion data exclusively. This is normal when all invoices flow through P11.
- **No data from any source**: Generate the full 7-section report with all sections present but populated with zeros and "No expenses recorded in this period" notes. Do not abort.
- **Output directory not writable**: Output the complete report content directly to chat with a warning: "Could not write to [path]. Report displayed below."
- **Mixed currencies in source data**: Report all amounts in the majority currency. Do not perform exchange rate conversion. Flag mixed-currency entries for manual review in a note after the Executive Summary.
- **Finance database not found in Notion**: Search for "[FOS] Finance" first, then fall back to "Founder OS HQ - Finance", then fall back to legacy "Invoice Processor - Invoices". If neither is found, treat as "no Notion data" scenario. Note that the Finance database was not found and suggest running `/invoice:process` first.

## Usage Examples

```
/expense:report
/expense:report 2024-03
/expense:report Q1 2024
/expense:report "last month"
/expense:report "this quarter" --output=./reports/q1-expenses.md
/expense:report 2024-01 to 2024-03 --sources=notion
/expense:report "last month" --sources=local --output=./reports/
```
