---
name: Expense Reporting
description: "Generates comprehensive Markdown expense reports from invoice data and local receipt files. Activates when the user wants an expense report, spending breakdown, category summary, or asks 'show me my expenses for [period].' Aggregates from Notion Finance DB and local files with 7-section structure, trend analysis, and period-over-period comparisons."
---

# Expense Reporting

Generate structured Markdown expense reports by aggregating processed invoice data from the consolidated Notion "[FOS] Finance" database (filtered by Type="Invoice") and local receipt/invoice files. Produce a 7-section report covering the requested date range, save to `expense-reports/[period]-[YYYY-MM-DD].md`, and optionally log to the Notion "Founder OS HQ - Reports" database with Type="Expense Report".

## Date Range Parsing

Parse the user-supplied period argument into a concrete start and end date. Apply these rules in priority order:

### Explicit Formats

| Input | Interpretation |
|-------|---------------|
| `YYYY-MM` (e.g., `2024-03`) | First day to last day of that month |
| `Q1 YYYY` through `Q4 YYYY` | Q1 = Jan-Mar, Q2 = Apr-Jun, Q3 = Jul-Sep, Q4 = Oct-Dec |
| `YYYY-MM to YYYY-MM` | First day of start month through last day of end month |

### Relative Formats

Resolve relative to today's date at invocation time.

| Input | Interpretation |
|-------|---------------|
| `this month` or `current month` | First day to last day of the current calendar month |
| `last month` | First day to last day of the previous calendar month |
| `this quarter` | First day to last day of the current calendar quarter |
| `last quarter` | First day to last day of the previous calendar quarter |

### Default Behavior

When no period is specified, default to the current calendar month.

### Validation Rules

- Reject future end dates beyond today. Clamp end date to today and note "partial period" in the report cover page.
- Reject end dates that precede start dates. Prompt the user to correct.
- Accept date ranges spanning multiple months or quarters without restriction.
- Store resolved `start_date` and `end_date` as ISO 8601 (YYYY-MM-DD) for all downstream operations.

## Data Aggregation Pipeline

Gather expense data from two sources, merge, and deduplicate. Execute the pipeline in this order.

### Step 1: Notion Query (Primary Source)

When Notion MCP is available, query the consolidated Finance database:

1. Search Notion for a database titled "[FOS] Finance".
2. If not found, fall back to "Founder OS HQ - Finance".
3. If not found, fall back to searching for the legacy name "Invoice Processor - Invoices".
3. Filter by `Type` equal to "Invoice" to retrieve only invoice records.
4. Filter by `Invoice Date` within the resolved date range (`start_date` to `end_date`).
5. Filter by `Approval Status` equal to "approved" -- exclude rejected, pending, and flagged invoices.
6. Extract these properties per record: Invoice #, Vendor, Amount, Currency, Invoice Date, Due Date, Category, Tax Deductible, Budget Code, Line Items.

When Notion is unavailable, skip this step and proceed with local files only. Never error on missing Notion.

### Step 2: Local File Scan (Secondary Source)

Scan the working directory and common receipt locations for unprocessed expense files:

1. Search for files matching: `*.pdf`, `*.jpg`, `*.jpeg`, `*.png`, `*.tiff`, `*.csv` in the working directory and any `receipts/` or `invoices/` subdirectory.
2. For CSV files, parse rows as expense entries (expect columns: date, vendor, amount, category, description).
3. For image and PDF files, note the file path and flag as "unprocessed -- run /founder-os:invoice:process first" unless a matching record exists in the Notion data from Step 1.

### Step 3: Merge and Deduplicate

Combine Notion records and local file entries into a single expense dataset:

1. **Invoice # match**: If a local file's name or content contains an Invoice # matching a Notion record, treat them as the same entry. Keep the Notion record (richer metadata).
2. **Vendor + Amount + Date match**: If vendor name matches (case-insensitive), amount is identical, and dates are within 3 calendar days, treat as duplicate. Keep the Notion record.
3. **Remaining local entries**: Include as separate line items. Flag as "local-only -- not in Invoice Processor" in the report notes.
4. Record the final merged count, Notion count, local-only count, and duplicate count for the Executive Summary.

## 7-Section Report Structure

Generate each section in order. Omit no section -- use "No data available for this section" when a section has insufficient data rather than removing it.

### Section 1: Cover Page

Report title, date range, generation date, and company placeholder. Format as a centered Markdown header block.

### Section 2: Executive Summary

Five key metrics in a scannable block:
- **Total Expenses**: Sum of all amounts in the period (formatted with currency symbol and thousands separators).
- **Invoice Count**: Number of unique expense entries.
- **Top Category**: Category with the highest total spend, with its amount and percentage of total.
- **Tax Deductible**: Percentage of total spend that is fully or partially tax-deductible.
- **Period-over-Period Change**: Percentage change in total spend compared to the previous period of the same length. Show direction arrow and percentage.

### Section 3: Category Breakdown

Table with one row per category from the P11 14-category taxonomy. Include all 14 categories; categories with zero spend appear with $0.00 and 0.0%. Sort by Amount descending. Columns: Category, Amount, % of Total, Items, Budget Code. Include a totals row at the bottom.

### Section 4: Vendor Summary

Table listing each unique vendor. Sort by Total descending. Columns: Vendor, Total, Invoices, Top Category. Include only vendors that appear in the current period. Limit to top 20 vendors; if more than 20 exist, add a "Other Vendors (N)" summary row.

### Section 5: Tax Deductibility Summary

Three-row summary table: Fully Deductible, Partially Deductible (50%), Non-Deductible. Columns: Classification, Amount, % of Total, Invoice Count. Include a totals row. After the table, add a note listing the categories that fall under partial deductibility (meals at 50%, travel partial per P11 rules).

### Section 6: Budget Code Allocation

Table grouping expenses by Budget Code. Columns: Budget Code, Department, Amount, % of Total. Derive Department from the budget code prefix mapping (OPS = Operations, TECH = Technology, SVC = Services, TRV = Travel, FAC = Facilities, ADM = Administration, MKT = Marketing, HR = Human Resources, GEN = General). Sort by Amount descending.

### Section 7: Trend Analysis

Compare the current period to the previous period of the same length (e.g., March 2024 vs February 2024; Q1 2024 vs Q4 2023). Present the comparison as described below in the Trend Analysis Methodology section.

Consult `${CLAUDE_PLUGIN_ROOT}/skills/expense/expense-reporting/references/report-sections.md` for detailed section templates, example output, table formats, and column calculation formulas.

## Trend Analysis Methodology

Compare the current period against the previous period of identical length. When the previous period has no data, note "No prior period data available for comparison" and skip trend calculations.

### Period-over-Period Comparison

Calculate percentage change as: `((current - previous) / |previous|) * 100`. When the previous period total is zero, report "N/A -- no prior spending" instead of infinity.

Present:
- Total spend change (amount and percentage).
- Invoice count change.
- Average invoice size change.

### Category Shift Analysis

For each of the 14 categories, compute:
- Current period amount and percentage of total.
- Previous period amount and percentage of total.
- Absolute change and percentage change.
- Share shift (change in percentage of total, in percentage points).

### Flagging Rules

Apply these labels based on percentage change per category:

| Change | Label |
|--------|-------|
| > +50% | **Significant spike** |
| > +20% | **Notable increase** |
| -20% to +20% | Stable |
| < -20% | **Notable decrease** |
| < -50% | **Significant drop** |
| New category (zero in prior period) | **New spending** |
| Disappeared category (zero in current period) | **Eliminated** |

### Spending Velocity

Calculate daily spending rate for each period: `total / days_in_period`. Compare rates to detect acceleration or deceleration independent of period length differences. Report as "[current_rate]/day vs [previous_rate]/day ([change]%)".

## Report Quality Rules

Apply these rules before finalizing the report:

1. **Currency consistency**: All amounts in a single currency. When mixed currencies appear in source data, note the currencies present and report all amounts in the majority currency. Do not perform exchange rate conversion -- flag mixed-currency entries for manual review.
2. **Rounding**: Display amounts to two decimal places. Percentages to one decimal place. Ensure percentage columns sum to 100.0% (adjust the largest category by rounding residual).
3. **Zero handling**: Include zero-spend categories in the Category Breakdown table. Omit zero-spend vendors from the Vendor Summary.
4. **Empty period**: When the date range yields zero expenses, generate the report with all sections present but populated with zeros and "No expenses recorded in this period" notes.
5. **Partial data**: When only local files are available (no Notion), note "Report generated from local files only -- Notion data unavailable" in the Executive Summary and omit fields that depend on P11 metadata (Budget Code, Tax Deductible) unless the local CSV contains those columns.
6. **Table alignment**: Use consistent Markdown table alignment. Right-align Amount and percentage columns. Left-align text columns.

## Report Output

### File Naming

Save the generated report to: `expense-reports/[period]-[YYYY-MM-DD].md`

Period slug format:
- Monthly: `2024-03`
- Quarterly: `Q1-2024`
- Multi-month: `2024-01-to-2024-03`

Example: `expense-reports/2024-03-2024-03-15.md`

Create the `expense-reports/` directory if it does not exist.

### Notion Logging

When Notion is available, log the report to the Reports database with Type="Expense Report". Search for a database named "[FOS] Reports"; if not found, fall back to "Founder OS HQ - Reports"; if not found, fall back to the legacy name "Expense Report Builder - Reports". Do not create the database -- it is expected to exist as part of the Founder OS HQ template. Use Report Title + Date Range as the composite key for idempotent upsert -- update the existing record on re-runs rather than creating duplicates.

Properties to log: Report Title, Type (always "Expense Report"), Date Range, Total Amount, Invoice Count, Top Category, Tax Deductible %, Report File Path, Generated At.

## P11 Category Taxonomy Reference

Use the 14-category taxonomy defined by P11 Invoice Processor. Do not invent new categories. Map each category to its Budget Code using the P11 mapping:

| Category | Budget Code | Tax Deductible |
|----------|------------|----------------|
| office_supplies | OPS-001 | Yes |
| software | TECH-001 | Yes |
| hardware | TECH-002 | Yes |
| professional_services | SVC-001 | Yes |
| travel | TRV-001 | Partial |
| meals | TRV-002 | 50% |
| shipping | OPS-002 | Yes |
| utilities | FAC-001 | Yes |
| rent | FAC-002 | Yes |
| insurance | ADM-001 | Yes |
| marketing | MKT-001 | Yes |
| training | HR-001 | Yes |
| subscriptions | TECH-003 | Yes |
| other | GEN-001 | Varies |

## Edge Cases

### Single Invoice in Period

Generate the full 7-section report. Category Breakdown will have one non-zero row. Trend Analysis still compares to the prior period. Vendor Summary will have one row.

### Very Large Datasets (>500 Invoices)

Process in batches of 100 for aggregation. Report all data -- do not sample or truncate. The Vendor Summary top-20 limit applies regardless of dataset size.

### Overlapping Date Ranges on Re-Run

When a report for the same period already exists in Notion, update the existing record. When the local file exists, overwrite it. Note "Updated report -- replaces prior version" in the cover page.

### Mixed Approval Statuses

Only include "approved" invoices from Notion in calculations. Note the count of pending and rejected invoices in the Executive Summary as informational: "N pending and M rejected invoices excluded from this report."
