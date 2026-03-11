---
name: Expense Categorization
description: "Classifies receipts and invoice files into the standard 14-category expense taxonomy during report assembly. Activates when the user wants to categorize expenses, classify receipts, determine expense types, or asks 'what category is this?' Covers vendor-based classification, tax-deductibility flags, budget code mapping, and confidence scoring."
---

# Expense Categorization

Assign standard expense categories to individual receipts and invoice files when building an expense report. Each file processed by `/founder-os:expense:report` receives a category, budget code, tax-deductibility flag, and confidence score before aggregation into the final report.

## When This Skill Applies

Use this skill to classify any local file (receipt image, PDF invoice, scanned document, or plain-text record) that has not already been categorized by Plugin #11 Invoice Processor. If a file carries P11 categorization data, accept it as-is and skip re-classification.

## Standard Category Taxonomy

Use exactly these 14 categories. Never invent new categories.

| Category | Code | Tax Deductible | Budget Code |
|----------|------|---------------|-------------|
| office_supplies | OFC | Yes | OPS-001 |
| software | SFW | Yes | TECH-001 |
| hardware | HW | Yes | TECH-002 |
| professional_services | PRO | Yes | SVC-001 |
| travel | TRV | Partial | TRV-001 |
| meals | MEA | 50% | TRV-002 |
| shipping | SHP | Yes | OPS-002 |
| utilities | UTL | Yes | FAC-001 |
| rent | RNT | Yes | FAC-002 |
| insurance | INS | Yes | ADM-001 |
| marketing | MKT | Yes | MKT-001 |
| training | TRN | Yes | HR-001 |
| subscriptions | SUB | Yes | TECH-003 |
| other | OTH | Varies | GEN-001 |

## Classification Signals

Apply signals in priority order. When multiple signals conflict, the higher-priority signal wins.

### 1. Vendor Name Signals (highest weight)

Match the vendor or merchant name on the receipt against known patterns.

| Vendor Pattern | Category |
|----------------|----------|
| Microsoft, Adobe, Salesforce, Notion, Slack, GitHub | software or subscriptions |
| Amazon (non-AWS), Staples, Office Depot | office_supplies |
| Amazon Web Services, Google Cloud, Azure | software |
| Airlines, Hotels, Airbnb, Uber, Lyft | travel |
| Restaurants, DoorDash, Grubhub, Seamless | meals |
| FedEx, UPS, DHL, USPS | shipping |
| AT&T, Verizon, Comcast, electric/water utilities | utilities |
| WeWork, Regus, commercial real estate | rent |
| Law firms, accounting firms, consultants | professional_services |
| Facebook Ads, Google Ads, PR agencies | marketing |
| Udemy, Coursera, LinkedIn Learning | training |
| Insurance companies (Hiscox, State Farm, etc.) | insurance |

For vendor names not in this table, fall through to description and amount signals.

### 2. Description and Line Item Signals (medium weight)

Scan receipt text, item descriptions, and any readable line items for keyword matches.

- "software license", "subscription", "SaaS", "annual plan" --> `software` or `subscriptions`
- "laptop", "monitor", "keyboard", "mouse", "hardware" --> `hardware`
- "flight", "hotel", "accommodation", "car rental", "parking" --> `travel`
- "lunch", "dinner", "catering", "meal", "coffee" (business context) --> `meals`
- "consulting", "advisory", "legal fees", "retainer" --> `professional_services`
- "postage", "courier", "freight", "delivery fee" --> `shipping`
- "electric", "gas", "internet", "phone bill", "water" --> `utilities`
- "office supplies", "paper", "pens", "toner", "ink" --> `office_supplies`
- "ad spend", "campaign", "sponsored", "promotion" --> `marketing`
- "course", "workshop", "certification", "conference" --> `training`
- "premium", "policy", "coverage" --> `insurance`

### 3. Amount-Based Signals (tiebreaker weight)

Use amount ranges only to break ties when vendor and description signals are inconclusive.

- Very large amounts (> $10,000): likely `rent`, `professional_services`, or `hardware`
- Small recurring amounts ($10-$200): likely `subscriptions` or `software`
- Per-diem amounts ($50-$75): likely `meals`
- Round-dollar amounts matching known utility billing patterns: likely `utilities`

## Confidence Scoring

Assign a confidence score between 0.0 and 1.0 to each categorized expense.

| Score Range | Meaning |
|-------------|---------|
| 0.9-1.0 | Clear vendor name match plus corroborating description |
| 0.7-0.89 | Strong signal from vendor or description alone |
| 0.5-0.69 | Mixed or partially matching signals |
| 0.3-0.49 | Ambiguous -- multiple valid categories possible |
| < 0.3 | Unknown vendor, unclear description |

Flag any expense with confidence below 0.7 as "needs review" in the expense report. These items appear in the Flagged Items section of the report so the user can confirm or override the category before submission.

## Tax Deductibility Rules

Apply these rules based on the assigned category:

- **travel**: Mark as `Partial`. Transportation and lodging are fully deductible; meals incurred during travel fall under the 50% meals rule.
- **meals**: Always 50% deductible. This applies regardless of business purpose.
- **other**: Cannot determine deductibility. Mark as `Varies` and flag for user review.
- **All remaining categories**: Fully deductible as ordinary business expenses.

When calculating report-level tax deductibility totals:
1. Sum fully deductible categories at 100% of their amounts.
2. Sum `meals` at 50% of their amounts.
3. Sum `travel` by splitting lodging/transport (100%) from travel meals (50%) when line-item detail is available. When detail is unavailable, estimate travel at 85% deductible as a conservative default.
4. Exclude `other` from deductibility totals entirely -- list it separately as "Pending Review."

## Budget Code Mapping

Each category maps to a single budget code. The budget code groups related categories into departments for the report's Budget Summary section.

| Budget Group | Prefix | Categories Included |
|-------------|--------|---------------------|
| Operations | OPS | office_supplies (OPS-001), shipping (OPS-002) |
| Technology | TECH | software (TECH-001), hardware (TECH-002), subscriptions (TECH-003) |
| Services | SVC | professional_services (SVC-001) |
| Travel | TRV | travel (TRV-001), meals (TRV-002) |
| Facilities | FAC | utilities (FAC-001), rent (FAC-002) |
| Admin | ADM | insurance (ADM-001) |
| Marketing | MKT | marketing (MKT-001) |
| Human Resources | HR | training (HR-001) |
| General | GEN | other (GEN-001) |

Roll up individual expense amounts by budget group prefix to produce the Budget Summary section of the expense report.

## Feeding Into the Expense Report

Each categorized expense contributes to the 7-section expense report structure:

1. **Report Header** -- report period, preparer, total amount, total deductible amount.
2. **Expense Summary by Category** -- table of each category with line count, subtotal, and percentage of total spend. Use the 14-category codes as row keys.
3. **Budget Summary** -- roll-up by budget group prefix (OPS, TECH, SVC, TRV, FAC, ADM, MKT, HR, GEN) with subtotals.
4. **Detailed Line Items** -- every individual expense sorted by date, showing vendor, amount, category, budget code, and confidence score.
5. **Tax Deductibility Summary** -- total fully deductible, partial (50%), and pending-review amounts following the rules above.
6. **Flagged Items** -- expenses with confidence below 0.7 or assigned to `other`, listed for user review with the reason for flagging.
7. **P11 Cross-Reference** -- expenses that match P11-processed invoices, shown with their P11 invoice number for reconciliation. Unmatched expenses are listed separately.

## Integration with P11 Invoice Processor

When P11 Invoice Processor data is available in the consolidated Notion Finance database:

1. Search Notion for a database titled "[FOS] Finance".
2. If not found, fall back to "Founder OS HQ - Finance".
3. If not found, fall back to searching for the legacy name "Invoice Processor - Invoices".
3. Filter by `Type` equal to "Invoice" to retrieve only invoice records.
4. Query for invoices matching the expense report date range.
5. Accept P11 category assignments without re-classification (P11 confidence is already validated through its pipeline).
6. Merge P11 invoices into the report alongside locally categorized receipts.
7. Mark P11-sourced entries in the Detailed Line Items section with their P11 invoice number.
8. Any receipt that matches a P11 invoice by vendor + amount + date (within 1-day tolerance) should be deduplicated -- keep the P11 version as authoritative.

When P11 data is unavailable (Notion not connected, no matching database, or no matching invoices), classify all files locally using the signals above and omit the P11 Cross-Reference section.

## Edge Cases

### Unknown Vendor with Generic Description
Categorize as `other` with confidence 0.3. Do not guess at a specific category with low confidence. The `other` category is honest, searchable, and will surface in the Flagged Items section for user correction.

### Multiple Categories on a Single Receipt
When a single receipt contains items spanning multiple categories (e.g., an Amazon order with both office supplies and hardware), split the receipt into separate expense entries per category. Each entry carries its own amount, category, budget code, and confidence score. If line-item amounts are unavailable, assign the full receipt amount to the dominant category and note "mixed-category receipt -- line-item split unavailable" in the flags.

### Recurring vs. One-Time Distinction
Differentiate `subscriptions` from `software` by recurrence signals. Monthly or annual billing indicators ("monthly plan", "annual renewal", "recurring charge") point to `subscriptions`. One-time license purchases ("perpetual license", "one-time fee") point to `software`. When ambiguous, prefer `subscriptions` for SaaS vendors and `software` for traditional vendors.

### Partial Receipts and Missing Information
When a receipt is partially illegible or missing vendor/amount fields, extract whatever is available. Assign the best-fit category based on readable signals and set confidence proportionally lower (typically 0.3-0.5). Flag the expense as "incomplete receipt" in the Flagged Items section.

### Shipping and Handling on Otherwise Single-Category Receipts
Shipping line items on an otherwise uniform receipt should be categorized as `shipping` with their own budget code (OPS-002). They do not change the primary category of the receipt's other items.

### Foreign Currency Receipts
When a receipt amount is in a non-USD currency, preserve the original currency and amount in the line item. Conversion to the report currency is handled by the expense-reporting skill, not by categorization. Assign category and confidence normally based on vendor and description signals regardless of currency.
