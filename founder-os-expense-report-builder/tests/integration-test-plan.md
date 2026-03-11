# Integration Test Plan: Expense Report Builder

## Overview

This test plan validates the P16 Expense Report Builder plugin against all acceptance criteria. Tests cover both commands (`/expense:report`, `/expense:summary`), both skills (expense-reporting, expense-categorization), data source scenarios, date range parsing, calculation accuracy, resilience behaviors, and cross-plugin compatibility with P11 Invoice Processor.

## Prerequisites

- Plugin installed in Claude Code
- Filesystem MCP configured with access to test directories
- Notion MCP configured (for Notion integration tests)
- Consolidated "Founder OS HQ - Finance" Notion database populated with test invoice data (Type="Invoice"), or legacy "Invoice Processor - Invoices" database as fallback
- Sample local files prepared in `receipts/` and `invoices/` subdirectories
- Test CSV files with columns: date, vendor, amount, category, description

---

## Data Source Tests

### Test 1: Notion-Only Data Source

**Command**: `/expense:report 2024-03 --sources=notion`
**Preconditions**:
- Notion MCP connected and accessible
- "Founder OS HQ - Finance" database contains 10+ approved invoices (Type="Invoice") dated March 2024 (or legacy "Invoice Processor - Invoices" as fallback)
- At least 2 pending and 1 rejected invoice exist in the same date range
**Steps**:
1. Run the command with `--sources=notion`
2. Verify the plugin queries "Founder OS HQ - Finance" with Type="Invoice" filter (or falls back to legacy "Invoice Processor - Invoices")
3. Verify only approved invoices are included in calculations
4. Review all 7 report sections for completeness
**Expected Results**:
- Report contains only Notion-sourced data; no local file scan is performed
- Data Sources line reads "Notion (N invoices)"
- Executive Summary notes excluded pending and rejected invoice counts
- All P11 fields used directly (Category, Budget Code, Tax Deductible) without re-classification
- Report file saved to `expense-reports/2024-03-[YYYY-MM-DD].md`
**Pass Criteria**: Report generated exclusively from P11 Notion data; local file scan step skipped entirely

---

### Test 2: Local Files Only

**Command**: `/expense:report 2024-03 --sources=local`
**Preconditions**:
- `receipts/` subdirectory contains 3 CSV files and 2 PDF invoices dated March 2024
- At least one CSV includes the columns: date, vendor, amount, category, description
- At least one CSV omits the category column
**Steps**:
1. Run the command with `--sources=local`
2. Verify no Notion query is attempted
3. Verify CSV files are parsed and image/PDF files are flagged as unprocessed
4. Verify uncategorized CSV entries are classified using the expense-categorization skill
**Expected Results**:
- Report generated without any Notion interaction
- CSV entries with pre-assigned categories retain those categories
- CSV entries missing category are classified by vendor/description signals with confidence scores
- PDF and image files flagged as "unprocessed -- run `/invoice:process` first"
- Flagged Items section lists low-confidence categorizations (< 0.7) and unprocessed files
- Executive Summary notes "Report generated from local files only -- Notion data unavailable"
**Pass Criteria**: Full 7-section report generated from local files; no Notion dependency

---

### Test 3: Mixed Sources with Deduplication

**Command**: `/expense:report 2024-03 --sources=all`
**Preconditions**:
- "Founder OS HQ - Finance" database contains 8 approved invoices (Type="Invoice") for March 2024 (or legacy "Invoice Processor - Invoices" as fallback)
- Local `invoices/` directory contains 5 files, of which:
  - 2 match Notion records by Invoice # (filename contains invoice number)
  - 1 matches a Notion record by vendor + amount + date (within 3 days)
  - 2 are unique local-only entries
**Steps**:
1. Run the command with `--sources=all` (or no `--sources` flag, since `all` is the default)
2. Verify both Notion query and local file scan execute
3. Verify deduplication removes the 3 duplicate entries
4. Verify Notion records are kept over local duplicates
**Expected Results**:
- Final merged dataset contains 10 entries (8 Notion + 2 local-only)
- 3 duplicates removed: 2 by Invoice # match, 1 by vendor+amount+date match
- Notion records preserved for all duplicates (richer metadata)
- Local-only entries tagged as "local-only -- not in Invoice Processor"
- Executive Summary Data Sources reads "Both (8 Notion + 2 local)"
- Merge statistics reported: final merged 10, Notion-sourced 8, local-only 2, duplicates removed 3
**Pass Criteria**: Deduplication correctly identifies and removes duplicates by both matching strategies; counts are accurate

---

## Date Range Tests

### Test 4: Explicit Month

**Command**: `/expense:report 2024-03`
**Preconditions**:
- Expense data exists for March 2024 in at least one data source
**Steps**:
1. Run the command with explicit month argument `2024-03`
2. Verify the resolved date range
3. Verify the period slug and display label
**Expected Results**:
- `start_date` resolved to `2024-03-01`
- `end_date` resolved to `2024-03-31`
- Period slug is `2024-03`
- Period display label is "March 2024"
- Report cover page shows "Period: March 2024" and "Date Range: 2024-03-01 to 2024-03-31"
- Only invoices dated within March 2024 are included
- Output file named `expense-reports/2024-03-[YYYY-MM-DD].md`
**Pass Criteria**: Date boundaries are exact calendar month boundaries; no off-by-one errors

---

### Test 5: Quarterly Date Range

**Command**: `/expense:report Q1 2024`
**Preconditions**:
- Expense data exists across January, February, and March 2024
**Steps**:
1. Run the command with quarterly argument `Q1 2024`
2. Verify the 3-month date range
3. Verify trend analysis compares against Q4 2023
**Expected Results**:
- `start_date` resolved to `2024-01-01`
- `end_date` resolved to `2024-03-31`
- Period slug is `Q1-2024`
- Period display label is "Q1 2024"
- All invoices from January 1 through March 31, 2024 are included
- Trend Analysis compares Q1 2024 vs Q4 2023 (previous period of identical length)
- Daily spend rate uses 91 calendar days (2024 is a leap year: 31+29+31)
**Pass Criteria**: Quarter spans exactly 3 months; previous period correctly resolves to Q4 2023

---

### Test 6: Relative Date Ranges

**Command**: `/expense:report "last month"` and `/expense:report "this quarter"`
**Preconditions**:
- Expense data exists for the relevant relative periods
- Current date is known at invocation time
**Steps**:
1. Run `/expense:report "last month"` and note the resolved date range
2. Run `/expense:report "this quarter"` and note the resolved date range
3. For "this quarter," verify end date is clamped to today if the quarter is not yet complete
**Expected Results**:
- "last month": resolves to the first and last day of the previous calendar month (e.g., if today is 2026-03-05, resolves to 2026-02-01 through 2026-02-28)
- "this quarter": resolves to the first day of the current quarter through today (e.g., 2026-01-01 through 2026-03-05), clamped if quarter is incomplete
- When end date is clamped, cover page shows "(partial -- through [YYYY-MM-DD])"
- Period display labels are human-readable (e.g., "February 2026", "Q1 2026")
**Pass Criteria**: Relative dates resolve correctly against the current calendar date; partial period flagged when applicable

---

## Calculation Accuracy Tests

### Test 7: 14-Category Breakdown

**Command**: `/expense:report 2024-03`
**Preconditions**:
- Merged dataset contains invoices spanning at least 8 of the 14 categories
- At least 6 categories have zero spend in the period
**Steps**:
1. Generate the report
2. Inspect Section 3 (Category Breakdown) table
3. Verify all 14 categories appear as rows
4. Sum the Amount column and compare to the Executive Summary total
**Expected Results**:
- All 14 categories listed in the table: office_supplies, software, hardware, professional_services, travel, meals, shipping, utilities, rent, insurance, marketing, training, subscriptions, other
- Categories with zero spend show $0.00 and 0.0%
- Non-zero categories sorted by Amount descending; zero categories appear at the bottom in alphabetical order
- Amount column sums to the Executive Summary Total Expenses value exactly
- Percentage column sums to exactly 100.0% (rounding residual absorbed by the largest category)
- Each category row shows the correct Budget Code from the P11 mapping
- Items column sums to the total Invoice Count
**Pass Criteria**: All 14 categories present; amounts sum correctly; percentages sum to 100.0%

---

### Test 8: Tax Deductibility Classification

**Command**: `/expense:report 2024-03`
**Preconditions**:
- Dataset includes invoices in these categories:
  - Fully deductible: software ($4,000), rent ($2,500), professional_services ($1,500)
  - Partially deductible: meals ($400), travel ($600)
  - Non-deductible: other ($300)
**Steps**:
1. Generate the report
2. Inspect Section 5 (Tax Deductibility Summary)
3. Verify the three-tier classification amounts
4. Verify the notes section
**Expected Results**:
- Fully Deductible row: $8,000.00 (software + rent + professional_services + all other "Yes" categories)
- Partially Deductible (50%) row: $1,000.00 (meals $400 + travel $600, displayed at full invoice amounts)
- Non-Deductible row: $300.00 (other category)
- Total row: $9,300.00 matching grand total
- Percentages sum to 100.0%
- Notes mention meals at 50% deductible and travel partial deductibility rules
- Notes mention "other" category requires manual review
**Pass Criteria**: Three-tier amounts are correct; meals at 50%, travel partial rules applied; "other" classified as non-deductible

---

### Test 9: Budget Code Allocation

**Command**: `/expense:report 2024-03`
**Preconditions**:
- Dataset includes invoices spanning at least 5 different budget codes across 3+ departments
**Steps**:
1. Generate the report
2. Inspect Section 6 (Budget Code Allocation)
3. Verify budget code mapping and department roll-up
**Expected Results**:
- Each budget code row maps to the correct department:
  - OPS-001, OPS-002 -> Operations
  - TECH-001, TECH-002, TECH-003 -> Technology
  - SVC-001 -> Services
  - TRV-001, TRV-002 -> Travel
  - FAC-001, FAC-002 -> Facilities
  - ADM-001 -> Administration
  - MKT-001 -> Marketing
  - HR-001 -> Human Resources
  - GEN-001 -> General
- Budget code amounts match corresponding category amounts (1:1 mapping)
- Zero-spend budget codes are omitted from the table (unlike Category Breakdown)
- Department roll-up subsection appears (3+ budget codes present)
- Department totals correctly sum constituent budget codes (e.g., Technology = TECH-001 + TECH-002 + TECH-003)
- Percentage column sums to 100.0%
**Pass Criteria**: Budget codes map correctly to categories and departments; department roll-up sums are accurate

---

### Test 10: Trend Analysis with Flagging

**Command**: `/expense:report 2024-03`
**Preconditions**:
- March 2024 data exists (current period)
- February 2024 data exists (previous period)
- At least one category shows >50% increase (significant spike)
- At least one category shows >20% increase (notable increase)
- At least one category is new (zero in February, non-zero in March)
- At least one category is eliminated (non-zero in February, zero in March)
**Steps**:
1. Generate the report
2. Inspect Section 7 (Trend Analysis)
3. Verify overall metrics comparison
4. Verify category shift flags
5. Verify Notable Changes bullet points
**Expected Results**:
- Overall metrics table shows: Total Spend, Invoice Count, Avg Invoice Size, Daily Spend Rate for both periods with correct percentage changes
- Category Shifts table shows all categories with non-zero spend in either period
- Flag column correctly assigns:
  - "Significant spike" for categories with >+50% change
  - "Notable increase" for categories with >+20% and <=+50% change
  - "Stable" for categories within +/-20%
  - "Notable decrease" for categories with <-20% and >=-50% change
  - "Significant drop" for categories with <-50% change
  - "New spending" for categories with $0 in previous period and >$0 in current
  - "Eliminated" for categories with >$0 in previous period and $0 in current
- Notable Changes section contains 3-6 bullet points prioritized by impact severity
- Each bullet includes specific dollar amounts and a brief hypothesis or recommendation
- Spending velocity (daily rate) comparison is accurate using actual calendar days per period
**Pass Criteria**: All flag labels correctly assigned based on thresholds; Notable Changes section highlights the most impactful shifts

---

## Resilience Tests

### Test 11: Graceful Degradation Without Notion

**Command**: `/expense:report 2024-03`
**Preconditions**:
- Notion MCP is disconnected or unavailable
- Local `receipts/` directory contains CSV files with expense data for March 2024
**Steps**:
1. Disconnect or disable Notion MCP
2. Run the command (default `--sources=all`)
3. Verify the plugin does not error or abort
4. Verify the report is generated from local files
**Expected Results**:
- No error or crash from missing Notion
- Executive Summary notes "Report generated from local files only -- Notion data unavailable"
- Data Sources line reads "Local files (N files)"
- All 7 report sections are present and populated (or show "No data available" notes)
- Uncategorized local entries are classified using the expense-categorization skill
- Budget Code and Tax Deductible fields are populated when local CSV includes those columns
- Budget Code and Tax Deductible fields are omitted when local CSV lacks those columns
- Report file saved to disk normally
- Notion logging step skipped with note "Report not saved to Notion -- Notion unavailable"
**Pass Criteria**: Full report generated without Notion; no errors; degradation is clearly communicated

---

### Test 12: HQ Reports Database Discovery with Fallback

**Command**: `/expense:report 2024-03`
**Preconditions**:
- Notion MCP connected
- "Founder OS HQ - Reports" database exists in Notion (from HQ template)
- "Founder OS HQ - Finance" database exists with invoice data
**Steps**:
1. Run the command
2. Verify the plugin discovers the "Founder OS HQ - Reports" database
3. Verify the report record is saved with Type="Expense Report"
**Expected Results**:
- Plugin searches Notion for "Founder OS HQ - Reports" database
- If not found, falls back to searching for legacy "Expense Report Builder - Reports"
- If neither found, skips Notion logging with note "Reports database not found"
- Plugin does NOT create the database -- it expects the HQ template to provide it
- When found, report record created/updated with Type="Expense Report" property
- Completion summary shows "Saved to Notion: Yes"
**Pass Criteria**: Database discovered by HQ name (or fallback); no lazy creation; Type property set correctly

---

### Test 13: Idempotent Upsert on Re-Run

**Command**: `/expense:report 2024-03` (run twice)
**Preconditions**:
- Notion MCP connected
- "Founder OS HQ - Reports" database exists (from HQ template or prior run)
- First run already created a record for March 2024
**Steps**:
1. Run `/expense:report 2024-03` to generate the initial report and Notion record
2. Note the Notion record ID or page URL
3. Run `/expense:report 2024-03` again
4. Check the Notion database for duplicate records
**Expected Results**:
- Second run finds the existing record by matching Report Title + Date Range
- Existing record is updated with current data (not duplicated)
- Only one record exists for March 2024 after both runs
- Cover page includes "Updated report -- replaces prior version" note
- Local file is overwritten with the updated report
**Pass Criteria**: No duplicate Notion records; existing record updated; local file overwritten

---

### Test 14: Empty Period with Zero Expenses

**Command**: `/expense:report 2024-12`
**Preconditions**:
- No invoices exist in any data source for December 2024
- No local files in `receipts/` or `invoices/` for that period
**Steps**:
1. Run the command for a period with no data
2. Verify the report structure is complete with all 7 sections
**Expected Results**:
- Report generated with all 7 sections present (no section omitted)
- Executive Summary shows:
  - Total Expenses: $0.00
  - Invoice Count: 0 invoices
  - Top Category: "N/A"
  - Tax Deductible: 0.0%
  - Period-over-Period: computed against November 2024 data (or "N/A" if also empty)
- Category Breakdown table shows all 14 categories with $0.00 and 0.0%
- Vendor Summary shows "No vendors in this period"
- Tax Deductibility Summary shows $0.00 across all classifications
- Budget Code Allocation shows no rows (zero-spend codes omitted)
- Trend Analysis compares against November 2024 or shows "No prior period data"
- Each empty section includes "No expenses recorded in this period" note
- Report file is still saved to disk
**Pass Criteria**: Complete 7-section report generated with zero values; no errors or aborted sections

---

## Command Tests

### Test 15: Ephemeral Summary Command

**Command**: `/expense:summary 2024-03 --top=5`
**Preconditions**:
- Expense data exists for March 2024 in Notion and/or local files
- More than 5 unique vendors in the dataset
**Steps**:
1. Run `/expense:summary 2024-03 --top=5`
2. Verify output appears in chat only
3. Verify no file is written to disk
4. Verify no Notion database write occurs
**Expected Results**:
- Output displayed directly in chat with the correct structure:
  - Header: "Expense Summary -- March 2024"
  - Total line: "$X,XXX.XX across N invoices"
  - By Category table: only categories with non-zero spend (unlike full report which shows all 14)
  - Top 5 Vendors table: exactly 5 vendor rows, sorted by total descending
  - Note below vendor table: "N additional vendors not shown" (where N = total vendors - 5)
  - Tax Deductible line: combined fully + partial deductible amount and percentage
- No file created in `expense-reports/` or any other directory
- No Notion database query for "Founder OS HQ - Reports" or "Expense Report Builder - Reports" (the tracking DB)
- No Notion record creation or update
- Currency formatting: dollar signs, comma separators, 2 decimal places
- Percentage formatting: 1 decimal place
**Pass Criteria**: Output is ephemeral (chat only); no file writes; no Notion writes; `--top=5` limits vendor list

---

### Test 16: Cross-Plugin P11 Compatibility

**Command**: `/expense:report 2024-03 --sources=notion`
**Preconditions**:
- P11 Invoice Processor has processed invoices into the Notion "Founder OS HQ - Finance" database (Type="Invoice") or legacy "Invoice Processor - Invoices" database
- Invoices include various categories from the 14-category taxonomy
- At least one invoice has each approval status: approved, pending, rejected
**Steps**:
1. Run the command sourcing exclusively from Notion
2. Verify P11 category codes are recognized and mapped correctly
3. Verify P11 budget codes match the expense-categorization skill's mapping
4. Verify approval status filtering
**Expected Results**:
- "Founder OS HQ - Finance" database is discovered by name search (or legacy "Invoice Processor - Invoices" as fallback)
- Only invoices with `Approval Status = "approved"` are included in calculations
- Pending and rejected invoices are counted and noted in the Executive Summary as excluded
- P11 category assignments are accepted without re-classification (P11 confidence already validated)
- P11 categories map 1:1 to the expense-categorization skill's 14-category taxonomy:
  - office_supplies, software, hardware, professional_services, travel, meals, shipping, utilities, rent, insurance, marketing, training, subscriptions, other
- P11 budget codes match: OPS-001, OPS-002, TECH-001, TECH-002, TECH-003, SVC-001, TRV-001, TRV-002, FAC-001, FAC-002, ADM-001, MKT-001, HR-001, GEN-001
- Tax deductibility flags from P11 (Yes, 50%, Partial, Varies) map correctly to the three-tier summary
- P11 line item data used for travel tax deductibility splitting when available
**Pass Criteria**: P11 data consumed without re-classification; categories, budget codes, and tax flags align between P11 and P16

---

## Coverage Matrix

| Feature | Test Scenario(s) |
|---------|-----------------|
| `/expense:report` command | Tests 1-14, 16 |
| `/expense:summary` command | Test 15 |
| `--sources=notion` flag | Tests 1, 16 |
| `--sources=local` flag | Test 2 |
| `--sources=all` (default) | Tests 3, 4, 5, 6, 7-14 |
| `--output=PATH` flag | Test 2 (implicit via default path) |
| `--top=N` flag | Test 15 |
| Explicit month date parsing | Tests 1, 4, 7-14, 16 |
| Quarterly date parsing | Test 5 |
| Relative date parsing | Test 6 |
| HQ Finance DB query (with legacy fallback) | Tests 1, 3, 5, 12, 13, 16 |
| Local file scanning | Tests 2, 3, 11 |
| CSV parsing | Tests 2, 11 |
| Expense categorization skill | Tests 2, 11 |
| Merge and deduplication | Test 3 |
| Invoice # dedup match | Test 3 |
| Vendor+Amount+Date dedup match | Test 3 |
| 14-category taxonomy | Tests 7, 16 |
| Tax deductibility (3-tier) | Tests 8, 16 |
| Budget code allocation | Tests 9, 16 |
| Department roll-up | Test 9 |
| Trend analysis | Tests 5, 10 |
| Flag labels (spike/increase/stable/decrease/drop/new/eliminated) | Test 10 |
| Spending velocity comparison | Test 10 |
| Graceful degradation (no Notion) | Test 11 |
| HQ Reports DB discovery with fallback | Test 12 |
| Idempotent upsert | Test 13 |
| Empty period handling | Test 14 |
| Ephemeral output (no persistence) | Test 15 |
| P11 cross-plugin compatibility | Tests 1, 3, 16 |
| Approval status filtering | Tests 1, 16 |
| Report quality (currency formatting) | Tests 7, 8, 9, 15 |
| Report quality (percentage rounding to 100.0%) | Tests 7, 8, 9 |
| Report quality (zero-spend categories) | Tests 7, 14 |
| 7-section report structure | Tests 1, 2, 4, 7, 14 |
| Partial period flagging | Test 6 |
| HQ Reports DB record with Type="Expense Report" | Test 12 |

## Acceptance Criteria Mapping

| Criterion | Test Scenario(s) |
|-----------|-----------------|
| `/expense:report` generates a 7-section Markdown report | Tests 1, 2, 4, 7, 14 |
| Aggregates invoice data from HQ Finance DB (or legacy P11 DB) | Tests 1, 3, 16 |
| Scans local receipts and invoices | Tests 2, 3, 11 |
| Deduplicates across Notion and local sources | Test 3 |
| Parses explicit, relative, and default date ranges | Tests 4, 5, 6 |
| Categorizes uncategorized local items using 14-category taxonomy | Tests 2, 11 |
| Calculates tax deductibility (fully/partial/non-deductible) | Tests 8, 16 |
| Maps expenses to budget codes and departments | Tests 9, 16 |
| Performs trend analysis with flagging labels | Tests 5, 10 |
| Saves report to disk and upserts to HQ Reports DB | Tests 1, 12, 13 |
| `/expense:summary` outputs ephemeral chat-only summary | Test 15 |
| Graceful degradation when Notion unavailable | Test 11 |
| HQ Reports DB discovery with fallback (no lazy creation) | Test 12 |
| Idempotent re-runs (no duplicate records) | Test 13 |
| Handles empty periods with zero-value report | Test 14 |
| Cross-plugin compatibility with P11 categories and budget codes | Test 16 |
