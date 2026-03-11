# Report Section Templates

Detailed templates and example output for each of the 7 sections in the Expense Report Builder report. Use these formats exactly when generating reports -- maintain column order, alignment, and calculation formulas.

## Section 1: Cover Page

### Template

```markdown
# Expense Report

**Period:** [Month YYYY | QN YYYY | Month YYYY - Month YYYY]
**Date Range:** [YYYY-MM-DD] to [YYYY-MM-DD]
**Generated:** [YYYY-MM-DD]
**Prepared for:** [Company Name]

---
```

### Example Output

```markdown
# Expense Report

**Period:** March 2024
**Date Range:** 2024-03-01 to 2024-03-31
**Generated:** 2024-03-31
**Prepared for:** [Your Company]

---
```

### Rules

- Use "[Your Company]" as the company placeholder unless the user provides a company name.
- For partial periods (end date clamped to today), append: `(partial -- through [YYYY-MM-DD])` after the Period value.
- For updated reports, append: `(Updated report -- replaces prior version)` below the Generated line.

## Section 2: Executive Summary

### Template

```markdown
## Executive Summary

| Metric | Value |
|:-------|------:|
| **Total Expenses** | $[XX,XXX.XX] |
| **Invoice Count** | [N] invoices |
| **Top Category** | [Category] ($[X,XXX.XX] -- [XX.X]% of total) |
| **Tax Deductible** | [XX.X]% of total spend |
| **Period-over-Period** | [arrow] [XX.X]% vs. previous period ($[XX,XXX.XX] vs. $[XX,XXX.XX]) |

**Data Sources:** [Notion (N invoices) | Local files (N files) | Both (N Notion + N local)]
[Optional: N pending and M rejected invoices excluded from this report.]
[Optional: Report generated from local files only -- Notion data unavailable.]
```

### Example Output

```markdown
## Executive Summary

| Metric | Value |
|:-------|------:|
| **Total Expenses** | $12,847.50 |
| **Invoice Count** | 34 invoices |
| **Top Category** | software ($4,280.00 -- 33.3% of total) |
| **Tax Deductible** | 87.2% of total spend |
| **Period-over-Period** | +14.3% vs. previous period ($12,847.50 vs. $11,240.00) |

**Data Sources:** Both (31 Notion + 3 local)
2 pending and 1 rejected invoices excluded from this report.
```

### Calculations

- **Total Expenses**: `SUM(all approved invoice amounts in period)`. Format with currency symbol, thousands separator, two decimals.
- **Invoice Count**: `COUNT(unique expense entries after deduplication)`.
- **Top Category**: Category with `MAX(SUM(amount) GROUP BY category)`. Display the category name, its total, and its share of grand total.
- **Tax Deductible**: `(SUM(fully_deductible) + SUM(partially_deductible * 0.5)) / total * 100`. The 50% factor applies to meals; travel amounts use the full amount for this high-level percentage (detailed breakdown in Section 5).
- **Period-over-Period**: `((current_total - previous_total) / |previous_total|) * 100`. Use upward arrow for positive change, downward arrow for negative. When no prior period data exists, display "N/A -- no prior period data".

### Arrow Symbols

- Increase: use the word "Up" followed by percentage (e.g., "Up 14.3%")
- Decrease: use the word "Down" followed by percentage (e.g., "Down 8.7%")
- No change: "Flat (0.0%)"

## Section 3: Category Breakdown

### Template

```markdown
## Category Breakdown

| Category | Amount | % of Total | Items | Budget Code |
|:---------|-------:|-----------:|------:|:------------|
| [category_name] | $[X,XXX.XX] | [XX.X]% | [N] | [CODE] |
| ... | ... | ... | ... | ... |
| **Total** | **$[XX,XXX.XX]** | **100.0%** | **[N]** | |
```

### Example Output

```markdown
## Category Breakdown

| Category | Amount | % of Total | Items | Budget Code |
|:---------|-------:|-----------:|------:|:------------|
| software | $4,280.00 | 33.3% | 8 | TECH-001 |
| professional_services | $3,200.00 | 24.9% | 3 | SVC-001 |
| rent | $2,500.00 | 19.5% | 1 | FAC-002 |
| hardware | $1,249.99 | 9.7% | 2 | TECH-002 |
| subscriptions | $620.00 | 4.8% | 6 | TECH-003 |
| meals | $387.50 | 3.0% | 5 | TRV-002 |
| office_supplies | $245.01 | 1.9% | 4 | OPS-001 |
| travel | $200.00 | 1.6% | 1 | TRV-001 |
| shipping | $95.00 | 0.7% | 2 | OPS-002 |
| marketing | $50.00 | 0.4% | 1 | MKT-001 |
| utilities | $20.00 | 0.2% | 1 | FAC-001 |
| training | $0.00 | 0.0% | 0 | HR-001 |
| insurance | $0.00 | 0.0% | 0 | ADM-001 |
| other | $0.00 | 0.0% | 0 | GEN-001 |
| **Total** | **$12,847.50** | **100.0%** | **34** | |
```

### Calculations

- **Amount**: `SUM(amount) WHERE category = [this category] AND invoice_date IN [date_range]`.
- **% of Total**: `(category_amount / grand_total) * 100`. Round to one decimal. Adjust the largest category's percentage to ensure the column sums to exactly 100.0% (absorb rounding residual).
- **Items**: `COUNT(invoices) WHERE category = [this category]`.
- **Budget Code**: Direct lookup from the P11 category-to-budget-code mapping table.

### Formatting Rules

- Always include all 14 categories, even with $0.00 amounts.
- Sort by Amount descending (highest spend first), with zero-amount categories at the bottom in alphabetical order.
- Right-align Amount, % of Total, and Items columns.
- Left-align Category and Budget Code columns.

## Section 4: Vendor Summary

### Template

```markdown
## Vendor Summary

| Vendor | Total | Invoices | Top Category |
|:-------|------:|---------:|:-------------|
| [vendor_name] | $[X,XXX.XX] | [N] | [category] |
| ... | ... | ... | ... |
| Other Vendors ([N]) | $[X,XXX.XX] | [N] | various |
```

### Example Output

```markdown
## Vendor Summary

| Vendor | Total | Invoices | Top Category |
|:-------|------:|---------:|:-------------|
| WeWork | $2,500.00 | 1 | rent |
| Anthropic | $2,400.00 | 2 | software |
| Smith & Associates LLP | $1,800.00 | 1 | professional_services |
| Adobe | $1,500.00 | 3 | software |
| Acme Consulting | $1,400.00 | 2 | professional_services |
| Apple | $1,249.99 | 2 | hardware |
| GitHub | $380.00 | 2 | subscriptions |
| Notion | $240.00 | 4 | subscriptions |
| DoorDash | $207.50 | 3 | meals |
| FedEx | $95.00 | 2 | shipping |
| Staples | $145.01 | 2 | office_supplies |
| Amazon | $100.00 | 2 | office_supplies |
| Uber | $200.00 | 1 | travel |
| DoorDash (catering) | $180.00 | 2 | meals |
| Google Ads | $50.00 | 1 | marketing |
| Comcast | $20.00 | 1 | utilities |
| Other Vendors (2) | $380.00 | 3 | various |
```

### Calculations

- **Total**: `SUM(amount) WHERE vendor = [this vendor] AND invoice_date IN [date_range]`.
- **Invoices**: `COUNT(invoices) WHERE vendor = [this vendor]`.
- **Top Category**: The category with the highest total amount for this vendor. When tied, select alphabetically first.

### Formatting Rules

- Sort by Total descending.
- Show the top 20 vendors individually.
- When more than 20 vendors exist, combine the remainder into a single "Other Vendors (N)" row at the bottom, where N is the count of collapsed vendors.
- Omit vendors with $0.00 in the current period -- they should not appear.
- Normalize vendor names: trim whitespace, collapse case variations of the same vendor into one row (e.g., "ADOBE" and "Adobe" merge into "Adobe").

## Section 5: Tax Deductibility Summary

### Template

```markdown
## Tax Deductibility Summary

| Classification | Amount | % of Total | Invoices |
|:---------------|-------:|-----------:|---------:|
| Fully Deductible | $[X,XXX.XX] | [XX.X]% | [N] |
| Partially Deductible (50%) | $[X,XXX.XX] | [XX.X]% | [N] |
| Non-Deductible | $[X,XXX.XX] | [XX.X]% | [N] |
| **Total** | **$[XX,XXX.XX]** | **100.0%** | **[N]** |

**Notes:**
- Partially deductible categories: meals (50% deductible), travel (transportation and lodging fully deductible; meals during travel at 50%).
- "other" category invoices classified as Non-Deductible by default. Review individually for potential deductions.
- [If applicable: N invoices missing tax deductibility data -- classified as Non-Deductible pending review.]
```

### Example Output

```markdown
## Tax Deductibility Summary

| Classification | Amount | % of Total | Invoices |
|:---------------|-------:|-----------:|---------:|
| Fully Deductible | $10,860.00 | 84.5% | 25 |
| Partially Deductible (50%) | $587.50 | 4.6% | 6 |
| Non-Deductible | $1,400.00 | 10.9% | 3 |
| **Total** | **$12,847.50** | **100.0%** | **34** |

**Notes:**
- Partially deductible categories: meals (50% deductible), travel (transportation and lodging fully deductible; meals during travel at 50%).
- "other" category invoices classified as Non-Deductible by default. Review individually for potential deductions.
```

### Classification Rules

Map each invoice to a classification based on its category's tax deductibility from the P11 taxonomy:

| Tax Deductible Value | Classification |
|---------------------|----------------|
| Yes | Fully Deductible |
| 50% | Partially Deductible (50%) |
| Partial | Partially Deductible (50%) |
| Varies | Non-Deductible |
| No / unknown / missing | Non-Deductible |

### Calculations

- **Fully Deductible Amount**: `SUM(amount) WHERE tax_deductible = 'Yes'`.
- **Partially Deductible Amount**: `SUM(amount) WHERE tax_deductible IN ('50%', 'Partial')`. Display the full invoice amount in this row (the 50% reduction is a tax calculation, not a reporting adjustment).
- **Non-Deductible Amount**: `SUM(amount) WHERE tax_deductible IN ('Varies', 'No', NULL)`.
- **Invoices**: Count of invoices per classification.

## Section 6: Budget Code Allocation

### Template

```markdown
## Budget Code Allocation

| Budget Code | Department | Amount | % of Total |
|:------------|:-----------|-------:|-----------:|
| [CODE] | [department] | $[X,XXX.XX] | [XX.X]% |
| ... | ... | ... | ... |
| **Total** | | **$[XX,XXX.XX]** | **100.0%** |
```

### Example Output

```markdown
## Budget Code Allocation

| Budget Code | Department | Amount | % of Total |
|:------------|:-----------|-------:|-----------:|
| TECH-001 | Technology | $4,280.00 | 33.3% |
| SVC-001 | Services | $3,200.00 | 24.9% |
| FAC-002 | Facilities | $2,500.00 | 19.5% |
| TECH-002 | Technology | $1,249.99 | 9.7% |
| TECH-003 | Technology | $620.00 | 4.8% |
| TRV-002 | Travel | $387.50 | 3.0% |
| OPS-001 | Operations | $245.01 | 1.9% |
| TRV-001 | Travel | $200.00 | 1.6% |
| OPS-002 | Operations | $95.00 | 0.7% |
| MKT-001 | Marketing | $50.00 | 0.4% |
| FAC-001 | Facilities | $20.00 | 0.2% |
| **Total** | | **$12,847.50** | **100.0%** |
```

### Budget Code to Department Mapping

| Prefix | Department |
|--------|-----------|
| OPS | Operations |
| TECH | Technology |
| SVC | Services |
| TRV | Travel |
| FAC | Facilities |
| ADM | Administration |
| MKT | Marketing |
| HR | Human Resources |
| GEN | General |

### Calculations

- **Amount**: `SUM(amount) WHERE budget_code = [this code]`.
- **% of Total**: `(code_amount / grand_total) * 100`.

### Formatting Rules

- Sort by Amount descending.
- Omit budget codes with $0.00 (unlike the Category Breakdown, zero-spend codes are excluded here for readability since budget codes are derived from categories).
- When multiple categories share the same department prefix (e.g., TECH-001, TECH-002, TECH-003), list each budget code as a separate row -- do not roll up to the department level. The department column provides the grouping context visually.

### Department Summary (Optional Subsection)

When 3 or more budget codes exist, add a department roll-up after the budget code table:

```markdown
### By Department

| Department | Amount | % of Total |
|:-----------|-------:|-----------:|
| Technology | $6,149.99 | 47.9% |
| Services | $3,200.00 | 24.9% |
| Facilities | $2,520.00 | 19.6% |
| Travel | $587.50 | 4.6% |
| Operations | $340.01 | 2.6% |
| Marketing | $50.00 | 0.4% |
| **Total** | **$12,847.50** | **100.0%** |
```

Calculate department totals by summing all budget codes sharing the same prefix.

## Section 7: Trend Analysis

### Template

```markdown
## Trend Analysis

**Comparing:** [Current Period] vs. [Previous Period]

### Overall

| Metric | Current | Previous | Change |
|:-------|--------:|---------:|-------:|
| Total Spend | $[XX,XXX.XX] | $[XX,XXX.XX] | [+/-XX.X]% |
| Invoice Count | [N] | [N] | [+/-XX.X]% |
| Avg Invoice Size | $[XXX.XX] | $[XXX.XX] | [+/-XX.X]% |
| Daily Spend Rate | $[XXX.XX]/day | $[XXX.XX]/day | [+/-XX.X]% |

### Category Shifts

| Category | Current | Previous | Change | Flag |
|:---------|--------:|---------:|-------:|:-----|
| [category] | $[X,XXX.XX] ([XX.X]%) | $[X,XXX.XX] ([XX.X]%) | [+/-XX.X]% | [flag] |
| ... | ... | ... | ... | ... |

### Notable Changes

- [Bullet point observations about significant shifts, new categories, eliminated categories]
```

### Example Output

```markdown
## Trend Analysis

**Comparing:** March 2024 vs. February 2024

### Overall

| Metric | Current | Previous | Change |
|:-------|--------:|---------:|-------:|
| Total Spend | $12,847.50 | $11,240.00 | +14.3% |
| Invoice Count | 34 | 29 | +17.2% |
| Avg Invoice Size | $377.87 | $387.59 | -2.5% |
| Daily Spend Rate | $414.44/day | $388.97/day | +6.6% |

### Category Shifts

| Category | Current | Previous | Change | Flag |
|:---------|--------:|---------:|-------:|:-----|
| software | $4,280.00 (33.3%) | $3,100.00 (27.6%) | +38.1% | **Notable increase** |
| professional_services | $3,200.00 (24.9%) | $3,400.00 (30.2%) | -5.9% | Stable |
| rent | $2,500.00 (19.5%) | $2,500.00 (22.2%) | 0.0% | Stable |
| hardware | $1,249.99 (9.7%) | $450.00 (4.0%) | +177.8% | **Significant spike** |
| subscriptions | $620.00 (4.8%) | $590.00 (5.3%) | +5.1% | Stable |
| meals | $387.50 (3.0%) | $600.00 (5.3%) | -35.4% | **Notable decrease** |
| office_supplies | $245.01 (1.9%) | $200.00 (1.8%) | +22.5% | **Notable increase** |
| travel | $200.00 (1.6%) | $0.00 (0.0%) | N/A | **New spending** |
| shipping | $95.00 (0.7%) | $150.00 (1.3%) | -36.7% | **Notable decrease** |
| marketing | $50.00 (0.4%) | $0.00 (0.0%) | N/A | **New spending** |
| utilities | $20.00 (0.2%) | $250.00 (2.2%) | -92.0% | **Significant drop** |
| training | $0.00 (0.0%) | $0.00 (0.0%) | 0.0% | Stable |
| insurance | $0.00 (0.0%) | $0.00 (0.0%) | 0.0% | Stable |
| other | $0.00 (0.0%) | $0.00 (0.0%) | 0.0% | Stable |

### Notable Changes

- **Hardware spending spiked 177.8%** ($1,249.99 vs. $450.00) -- likely due to new equipment purchases. Review for one-time vs. recurring.
- **Software increased 38.1%** and now represents the largest expense category at 33.3% of total spend.
- **Travel and marketing are new categories** this period -- no prior spending recorded.
- **Utilities dropped 92.0%** ($20.00 vs. $250.00) -- verify whether prior period included a quarterly billing cycle.
- **Meals decreased 35.4%** -- may reflect seasonal variation or reduced client entertainment.
- **Daily spending rate increased 6.6%** ($414.44/day vs. $388.97/day) indicating moderate acceleration in overall spending velocity.
```

### Calculations

- **Previous Period**: Automatically determined as the period of identical length immediately preceding the current period. For March 2024, the previous period is February 2024. For Q1 2024, the previous period is Q4 2023. For a custom range of 3 months, the previous period is the 3 months before that.
- **Change %**: `((current - previous) / |previous|) * 100`. When previous is zero, display "N/A" in the Change column.
- **Daily Spend Rate**: `total_spend / calendar_days_in_period`. Use actual calendar days (28, 29, 30, or 31 for months; 90-92 for quarters).
- **Avg Invoice Size**: `total_spend / invoice_count`.

### Flag Assignment Rules

Apply one flag per category based on percentage change:

| Condition | Flag Value |
|-----------|-----------|
| Change > +50% | **Significant spike** |
| Change > +20% and <= +50% | **Notable increase** |
| Change >= -20% and <= +20% | Stable |
| Change < -20% and >= -50% | **Notable decrease** |
| Change < -50% | **Significant drop** |
| Previous = $0, Current > $0 | **New spending** |
| Previous > $0, Current = $0 | **Eliminated** |
| Both $0 | Stable |

### Notable Changes Section Rules

Generate 3-6 bullet points highlighting the most significant findings. Include:

1. Any category flagged as **Significant spike** or **Significant drop** -- always include these.
2. Any category flagged as **New spending** or **Eliminated**.
3. The largest absolute dollar change (even if percentage change is moderate).
4. The daily spending rate change if it exceeds 10% in either direction.
5. For each bullet point, provide a brief hypothesis or recommended action (e.g., "Review for one-time vs. recurring", "Verify billing cycle alignment").

Sort bullets by impact severity: Significant spike/drop first, then New/Eliminated, then Notable changes, then velocity observations.

### No Prior Period Fallback

When no data exists for the previous period:

```markdown
## Trend Analysis

**Note:** No prior period data available for comparison. Trend analysis requires at least two consecutive periods.

This is the first report for [Period]. Future reports will include period-over-period comparisons automatically.

### Current Period Summary

| Metric | Value |
|:-------|------:|
| Total Spend | $[XX,XXX.XX] |
| Invoice Count | [N] |
| Avg Invoice Size | $[XXX.XX] |
| Daily Spend Rate | $[XXX.XX]/day |
```

## General Formatting Rules

These rules apply across all sections:

### Number Formatting

- **Currency**: `$X,XXX.XX` -- dollar sign, comma thousands separator, two decimal places. No space between symbol and digits.
- **Percentages**: `XX.X%` -- one decimal place, percent sign immediately after digits. No space.
- **Counts**: Plain integers with comma thousands separator for values >= 1,000. No decimal places.
- **Dates**: `YYYY-MM-DD` in tables and metadata. `Month YYYY` (e.g., "March 2024") in prose and headers.

### Table Formatting

- Use pipe-delimited Markdown tables.
- Left-align text columns (`:------`).
- Right-align numeric columns (`------:`).
- Bold the totals row: `| **Total** | **$XX,XXX.XX** | **100.0%** | **N** |`.
- No trailing whitespace in cells.
- Column headers use Title Case.

### Section Ordering

Always produce sections in this fixed order (1 through 7). Never reorder, merge, or split sections. When a section has no data, include the section header with a note: "No data available for this section."
