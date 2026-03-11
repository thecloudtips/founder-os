<!-- Expense Report Template: Structural scaffold for the /expense:report command when generating
     expense reports. Replace all {{PLACEHOLDER}} variables with actual computed values during generation.
     This template consumes data from P11 Invoice Processor's Notion DB and the expense-categorization
     skill's 14-category taxonomy. -->

# Expense Report

**Period:** {{PERIOD_LABEL}}
<!-- PERIOD_LABEL: Human-readable period name, e.g., "March 2026", "Q1 2026", "Week of Mar 2-8, 2026" -->
**Date Range:** {{START_DATE}} to {{END_DATE}}
<!-- START_DATE / END_DATE: YYYY-MM-DD format -->
**Generated:** {{GENERATED_DATE}}
<!-- GENERATED_DATE: YYYY-MM-DD of report generation -->
**Prepared for:** {{COMPANY_NAME}}
<!-- COMPANY_NAME: Company or individual name from user context or CRM -->

---

## Executive Summary

| Metric                | Value |
|-----------------------|------:|
| **Total Expenses**    | {{TOTAL_EXPENSES}} |
| **Invoice Count**     | {{INVOICE_COUNT}} invoices |
| **Top Category**      | {{TOP_CATEGORY}} ({{TOP_CATEGORY_AMOUNT}} — {{TOP_CATEGORY_PCT}}% of total) |
| **Tax Deductible**    | {{TAX_DEDUCTIBLE_PCT}}% of total spend |
| **Period-over-Period** | {{PERIOD_CHANGE}}% vs. previous period ({{CURRENT_TOTAL}} vs. {{PREVIOUS_TOTAL}}) |

<!-- TOTAL_EXPENSES: Currency-formatted grand total, e.g., "$12,450.00" -->
<!-- INVOICE_COUNT: Integer count of invoices in this period -->
<!-- TOP_CATEGORY: Display name of the highest-spend category from the 14-category taxonomy -->
<!-- TOP_CATEGORY_AMOUNT: Currency-formatted amount for the top category -->
<!-- TOP_CATEGORY_PCT: Percentage of total spend (1 decimal place) -->
<!-- TAX_DEDUCTIBLE_PCT: Percentage of total spend that is fully or partially deductible (1 decimal place) -->
<!-- PERIOD_CHANGE: Signed percentage change vs. prior period, e.g., "+12.3" or "-5.7" -->
<!-- CURRENT_TOTAL: Currency-formatted total for this period -->
<!-- PREVIOUS_TOTAL: Currency-formatted total for the prior period -->

**Data Sources:** {{DATA_SOURCES}}
<!-- DATA_SOURCES: Comma-separated list of sources used, e.g., "Invoice Processor DB, Gmail, Filesystem" -->

{{#EXCLUSION_NOTES}}
> **Note:** {{EXCLUSION_NOTES}}
{{/EXCLUSION_NOTES}}
<!-- EXCLUSION_NOTES: Optional. Explains any invoices excluded from the report (e.g., rejected, pending approval).
     Omit this block entirely if no exclusions apply. -->

---

## Category Breakdown

| Category | Amount | % of Total | Items | Budget Code |
|----------|-------:|:----------:|------:|-------------|
| Office Supplies | {{CAT_OFFICE_SUPPLIES_AMOUNT}} | {{CAT_OFFICE_SUPPLIES_PCT}}% | {{CAT_OFFICE_SUPPLIES_COUNT}} | OPS-001 |
| Software | {{CAT_SOFTWARE_AMOUNT}} | {{CAT_SOFTWARE_PCT}}% | {{CAT_SOFTWARE_COUNT}} | TECH-001 |
| Hardware | {{CAT_HARDWARE_AMOUNT}} | {{CAT_HARDWARE_PCT}}% | {{CAT_HARDWARE_COUNT}} | TECH-002 |
| Professional Services | {{CAT_PROFESSIONAL_SERVICES_AMOUNT}} | {{CAT_PROFESSIONAL_SERVICES_PCT}}% | {{CAT_PROFESSIONAL_SERVICES_COUNT}} | SVC-001 |
| Travel | {{CAT_TRAVEL_AMOUNT}} | {{CAT_TRAVEL_PCT}}% | {{CAT_TRAVEL_COUNT}} | TRV-001 |
| Meals | {{CAT_MEALS_AMOUNT}} | {{CAT_MEALS_PCT}}% | {{CAT_MEALS_COUNT}} | TRV-002 |
| Shipping | {{CAT_SHIPPING_AMOUNT}} | {{CAT_SHIPPING_PCT}}% | {{CAT_SHIPPING_COUNT}} | OPS-002 |
| Utilities | {{CAT_UTILITIES_AMOUNT}} | {{CAT_UTILITIES_PCT}}% | {{CAT_UTILITIES_COUNT}} | FAC-001 |
| Rent | {{CAT_RENT_AMOUNT}} | {{CAT_RENT_PCT}}% | {{CAT_RENT_COUNT}} | FAC-002 |
| Insurance | {{CAT_INSURANCE_AMOUNT}} | {{CAT_INSURANCE_PCT}}% | {{CAT_INSURANCE_COUNT}} | ADM-001 |
| Marketing | {{CAT_MARKETING_AMOUNT}} | {{CAT_MARKETING_PCT}}% | {{CAT_MARKETING_COUNT}} | MKT-001 |
| Training | {{CAT_TRAINING_AMOUNT}} | {{CAT_TRAINING_PCT}}% | {{CAT_TRAINING_COUNT}} | HR-001 |
| Subscriptions | {{CAT_SUBSCRIPTIONS_AMOUNT}} | {{CAT_SUBSCRIPTIONS_PCT}}% | {{CAT_SUBSCRIPTIONS_COUNT}} | TECH-003 |
| Other | {{CAT_OTHER_AMOUNT}} | {{CAT_OTHER_PCT}}% | {{CAT_OTHER_COUNT}} | GEN-001 |
| **Total** | **{{TOTAL_EXPENSES}}** | **100.0%** | **{{INVOICE_COUNT}}** | |

<!-- CAT_[NAME]_AMOUNT: Currency-formatted total for that category. Use "$0.00" if no invoices in category. -->
<!-- CAT_[NAME]_PCT: Percentage of total spend (1 decimal place). Use "0.0" if no invoices in category. -->
<!-- CAT_[NAME]_COUNT: Integer count of invoices in that category. Use "0" if none. -->
<!-- All 14 rows MUST appear even if amount is $0.00 — this ensures consistent report structure. -->

---

## Vendor Summary

| Vendor | Total | Invoices | Top Category |
|--------|------:|---------:|--------------|
{{#VENDOR_ROWS}}
| {{VENDOR_NAME}} | {{VENDOR_TOTAL}} | {{VENDOR_INVOICE_COUNT}} | {{VENDOR_TOP_CATEGORY}} |
{{/VENDOR_ROWS}}
{{#OTHER_VENDORS}}
| *Other Vendors ({{OTHER_VENDOR_COUNT}})* | {{OTHER_VENDORS_TOTAL}} | {{OTHER_VENDORS_INVOICE_COUNT}} | Various |
{{/OTHER_VENDORS}}
| **Total** | **{{TOTAL_EXPENSES}}** | **{{INVOICE_COUNT}}** | |

<!-- VENDOR_ROWS: Repeat block for each of the top 20 vendors by total spend, sorted descending. -->
<!-- VENDOR_NAME: Vendor display name -->
<!-- VENDOR_TOTAL: Currency-formatted total for that vendor -->
<!-- VENDOR_INVOICE_COUNT: Integer count of invoices from that vendor -->
<!-- VENDOR_TOP_CATEGORY: The category with the highest spend for this vendor -->
<!-- OTHER_VENDORS: Optional aggregation row. Include only if more than 20 vendors exist. -->
<!-- OTHER_VENDOR_COUNT: Number of vendors rolled into the "Other" row -->
<!-- OTHER_VENDORS_TOTAL: Currency-formatted combined total for remaining vendors -->
<!-- OTHER_VENDORS_INVOICE_COUNT: Combined invoice count for remaining vendors -->

---

## Tax Deductibility Summary

| Classification | Amount | % of Total | Categories |
|----------------|-------:|:----------:|------------|
| Fully Deductible | {{FULLY_DEDUCTIBLE_AMOUNT}} | {{FULLY_DEDUCTIBLE_PCT}}% | {{FULLY_DEDUCTIBLE_CATEGORIES}} |
| Partially Deductible (50%) | {{PARTIAL_DEDUCTIBLE_AMOUNT}} | {{PARTIAL_DEDUCTIBLE_PCT}}% | {{PARTIAL_DEDUCTIBLE_CATEGORIES}} |
| Non-Deductible | {{NON_DEDUCTIBLE_AMOUNT}} | {{NON_DEDUCTIBLE_PCT}}% | {{NON_DEDUCTIBLE_CATEGORIES}} |
| **Total** | **{{TOTAL_EXPENSES}}** | **100.0%** | |

<!-- FULLY_DEDUCTIBLE_AMOUNT: Sum of office_supplies, software, hardware, professional_services, shipping, utilities, rent, insurance, marketing, training, subscriptions -->
<!-- FULLY_DEDUCTIBLE_PCT: Percentage of total (1 decimal place) -->
<!-- FULLY_DEDUCTIBLE_CATEGORIES: Comma-separated list of fully deductible categories with non-zero spend -->
<!-- PARTIAL_DEDUCTIBLE_AMOUNT: Sum of meals (50% deductible) + travel transportation/lodging portion -->
<!-- PARTIAL_DEDUCTIBLE_PCT: Percentage of total (1 decimal place) -->
<!-- PARTIAL_DEDUCTIBLE_CATEGORIES: "Meals, Travel" or whichever partial categories have non-zero spend -->
<!-- NON_DEDUCTIBLE_AMOUNT: "Other" category spend where deductibility cannot be determined -->
<!-- NON_DEDUCTIBLE_PCT: Percentage of total (1 decimal place) -->
<!-- NON_DEDUCTIBLE_CATEGORIES: "Other" or empty if no non-deductible spend -->

**Notes:**
- Meals are 50% deductible per IRS guidelines. The actual deductible amount is {{MEALS_DEDUCTIBLE_AMOUNT}}.
<!-- MEALS_DEDUCTIBLE_AMOUNT: 50% of total meals spend, currency-formatted -->
- Travel expenses include both fully deductible components (transportation, lodging) and 50% deductible components (meals during travel). Travel meals are included in the Meals category.
- Items categorized as "Other" require manual review to determine deductibility. Consult your tax professional.

---

## Budget Code Allocation

| Budget Code | Department | Amount | % of Total |
|-------------|------------|-------:|:----------:|
| OPS-001 | Operations | {{BUDGET_OPS001_AMOUNT}} | {{BUDGET_OPS001_PCT}}% |
| OPS-002 | Operations | {{BUDGET_OPS002_AMOUNT}} | {{BUDGET_OPS002_PCT}}% |
| TECH-001 | Technology | {{BUDGET_TECH001_AMOUNT}} | {{BUDGET_TECH001_PCT}}% |
| TECH-002 | Technology | {{BUDGET_TECH002_AMOUNT}} | {{BUDGET_TECH002_PCT}}% |
| TECH-003 | Technology | {{BUDGET_TECH003_AMOUNT}} | {{BUDGET_TECH003_PCT}}% |
| SVC-001 | Services | {{BUDGET_SVC001_AMOUNT}} | {{BUDGET_SVC001_PCT}}% |
| TRV-001 | Travel | {{BUDGET_TRV001_AMOUNT}} | {{BUDGET_TRV001_PCT}}% |
| TRV-002 | Travel | {{BUDGET_TRV002_AMOUNT}} | {{BUDGET_TRV002_PCT}}% |
| FAC-001 | Facilities | {{BUDGET_FAC001_AMOUNT}} | {{BUDGET_FAC001_PCT}}% |
| FAC-002 | Facilities | {{BUDGET_FAC002_AMOUNT}} | {{BUDGET_FAC002_PCT}}% |
| ADM-001 | Administration | {{BUDGET_ADM001_AMOUNT}} | {{BUDGET_ADM001_PCT}}% |
| MKT-001 | Marketing | {{BUDGET_MKT001_AMOUNT}} | {{BUDGET_MKT001_PCT}}% |
| HR-001 | Human Resources | {{BUDGET_HR001_AMOUNT}} | {{BUDGET_HR001_PCT}}% |
| GEN-001 | General | {{BUDGET_GEN001_AMOUNT}} | {{BUDGET_GEN001_PCT}}% |
| **Total** | | **{{TOTAL_EXPENSES}}** | **100.0%** |

<!-- BUDGET_[CODE]_AMOUNT: Currency-formatted total for that budget code. Maps 1:1 with categories. -->
<!-- BUDGET_[CODE]_PCT: Percentage of total (1 decimal place) -->

### By Department

| Department | Amount | % of Total |
|------------|-------:|:----------:|
| Operations | {{DEPT_OPERATIONS_AMOUNT}} | {{DEPT_OPERATIONS_PCT}}% |
| Technology | {{DEPT_TECHNOLOGY_AMOUNT}} | {{DEPT_TECHNOLOGY_PCT}}% |
| Services | {{DEPT_SERVICES_AMOUNT}} | {{DEPT_SERVICES_PCT}}% |
| Travel | {{DEPT_TRAVEL_AMOUNT}} | {{DEPT_TRAVEL_PCT}}% |
| Facilities | {{DEPT_FACILITIES_AMOUNT}} | {{DEPT_FACILITIES_PCT}}% |
| Administration | {{DEPT_ADMINISTRATION_AMOUNT}} | {{DEPT_ADMINISTRATION_PCT}}% |
| Marketing | {{DEPT_MARKETING_AMOUNT}} | {{DEPT_MARKETING_PCT}}% |
| Human Resources | {{DEPT_HR_AMOUNT}} | {{DEPT_HR_PCT}}% |
| General | {{DEPT_GENERAL_AMOUNT}} | {{DEPT_GENERAL_PCT}}% |
| **Total** | **{{TOTAL_EXPENSES}}** | **100.0%** |

<!-- DEPT_[NAME]_AMOUNT: Aggregated total across all budget codes in that department -->
<!-- DEPT_[NAME]_PCT: Percentage of total (1 decimal place) -->
<!-- Department mapping: Operations = OPS-001 + OPS-002, Technology = TECH-001 + TECH-002 + TECH-003,
     Services = SVC-001, Travel = TRV-001 + TRV-002, Facilities = FAC-001 + FAC-002,
     Administration = ADM-001, Marketing = MKT-001, Human Resources = HR-001, General = GEN-001 -->

---

## Trend Analysis

**Comparing:** {{CURRENT_PERIOD}} vs. {{PREVIOUS_PERIOD}}
<!-- CURRENT_PERIOD: Human-readable label for this report's period, e.g., "March 2026" -->
<!-- PREVIOUS_PERIOD: Human-readable label for the prior period, e.g., "February 2026" -->

### Overall Metrics

| Metric | {{CURRENT_PERIOD}} | {{PREVIOUS_PERIOD}} | Change |
|--------|-------------------:|--------------------:|-------:|
| Total Spend | {{CURRENT_TOTAL}} | {{PREVIOUS_TOTAL}} | {{PERIOD_CHANGE}}% |
| Invoice Count | {{CURRENT_INVOICE_COUNT}} | {{PREVIOUS_INVOICE_COUNT}} | {{INVOICE_COUNT_CHANGE}}% |
| Avg Invoice Size | {{CURRENT_AVG_INVOICE}} | {{PREVIOUS_AVG_INVOICE}} | {{AVG_INVOICE_CHANGE}}% |
| Daily Spend Rate | {{CURRENT_DAILY_RATE}} | {{PREVIOUS_DAILY_RATE}} | {{DAILY_RATE_CHANGE}}% |

<!-- CURRENT_INVOICE_COUNT / PREVIOUS_INVOICE_COUNT: Integer invoice counts per period -->
<!-- INVOICE_COUNT_CHANGE: Signed percentage change -->
<!-- CURRENT_AVG_INVOICE / PREVIOUS_AVG_INVOICE: Currency-formatted average (total / count) -->
<!-- AVG_INVOICE_CHANGE: Signed percentage change -->
<!-- CURRENT_DAILY_RATE / PREVIOUS_DAILY_RATE: Currency-formatted daily average (total / days in period) -->
<!-- DAILY_RATE_CHANGE: Signed percentage change -->

### Category Shifts

| Category | {{CURRENT_PERIOD}} | {{PREVIOUS_PERIOD}} | Change | Flag |
|----------|-------------------:|--------------------:|-------:|:----:|
{{#CATEGORY_SHIFT_ROWS}}
| {{SHIFT_CATEGORY}} | {{SHIFT_CURRENT}} | {{SHIFT_PREVIOUS}} | {{SHIFT_CHANGE}}% | {{SHIFT_FLAG}} |
{{/CATEGORY_SHIFT_ROWS}}

<!-- CATEGORY_SHIFT_ROWS: One row per category that had non-zero spend in either period. -->
<!-- SHIFT_CATEGORY: Category display name -->
<!-- SHIFT_CURRENT / SHIFT_PREVIOUS: Currency-formatted amounts -->
<!-- SHIFT_CHANGE: Signed percentage change. Use "NEW" if no prior period data for this category. -->
<!-- SHIFT_FLAG: Visual indicator for significant changes:
       - empty string if change is within +/- 20%
       - "Up" if increase > 20%
       - "DOWN" if decrease > 20%
       - "NEW" if category had $0 in prior period
       - "GONE" if category has $0 in current period -->

### Notable Changes

{{#NOTABLE_CHANGES}}
- {{NOTABLE_CHANGE_TEXT}}
{{/NOTABLE_CHANGES}}

<!-- NOTABLE_CHANGES: Repeat block for 3-5 bullet points highlighting the most significant changes. -->
<!-- NOTABLE_CHANGE_TEXT: Human-readable insight, e.g.,
     "Software spend increased 45% ($2,100 to $3,045), driven by 3 new SaaS subscriptions."
     "Travel expenses dropped 62% — no conference travel this period."
     "New vendor: Acme Corp ($4,200) — first invoice from this vendor."
     Include specific dollar amounts and counts. Be factual, not speculative. -->

{{#NO_PRIOR_PERIOD}}
> **Note:** No prior period data available for comparison. Trend analysis will be included in the next report once a baseline period is established. All "Change" columns show "N/A" and category shift flags are omitted.
{{/NO_PRIOR_PERIOD}}
<!-- NO_PRIOR_PERIOD: Include this block instead of the Overall Metrics, Category Shifts, and Notable Changes
     subsections when no prior period data exists. When this block is active, replace all change percentages
     in the Executive Summary Period-over-Period row with "N/A — first report". -->

---

*This expense report was generated by [Founder OS Expense Report Builder](https://founderos.dev). Data sourced from P11 Invoice Processor. Verify all figures before filing.*
