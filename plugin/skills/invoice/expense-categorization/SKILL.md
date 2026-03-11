---
name: Expense Categorization
description: "Assigns accounting categories to invoice line items using a standard 14-category taxonomy. Activates when the user wants to categorize expenses, classify line items, assign budget codes, or asks 'what type of expense is this?' Covers tax-deductibility rules, budget code mapping, and confidence scoring."
version: 1.0.0
---

# Expense Categorization

Assign standard expense categories to invoice line items and the overall invoice. Used by the categorization-agent as step 3 of the 5-agent pipeline. Category and budget code values are written to the **"Founder OS HQ - Finance"** database (Type="Invoice") or the legacy "Invoice Processor - Invoices" fallback.

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

Apply signals in priority order:

### 1. Vendor Name Signals (highest weight)
| Vendor pattern | Category |
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
| Insurance companies (Hiscox, etc.) | insurance |

### 2. Line Item Description Signals (medium weight)
- Keywords: "software license", "subscription", "SaaS" → `software` or `subscriptions`
- Keywords: "laptop", "monitor", "keyboard", "hardware" → `hardware`
- Keywords: "flight", "hotel", "accommodation", "car rental" → `travel`
- Keywords: "lunch", "dinner", "catering", "meal" → `meals`
- Keywords: "consulting", "advisory", "legal fees" → `professional_services`
- Keywords: "postage", "courier", "freight" → `shipping`
- Keywords: "electric", "gas", "internet", "phone bill" → `utilities`
- Keywords: "office supplies", "paper", "pens", "toner" → `office_supplies`

### 3. Amount-Based Signals (lower weight, use as tiebreaker)
- Very large amounts (> $10,000): likely `rent`, `professional_services`, or `hardware`
- Small recurring amounts ($10–$200): likely `subscriptions` or `software`
- Per-diem amounts ($50–$75): likely `meals`

## Confidence Scoring

Assign `category_confidence` per line item:

| Score | Meaning |
|-------|---------|
| 0.9–1.0 | Clear vendor name + matching description |
| 0.7–0.89 | Good signal from vendor or description alone |
| 0.5–0.69 | Mixed signals or generic description |
| 0.3–0.49 | Ambiguous — multiple valid categories |
| < 0.3 | Unknown vendor, unclear description |

Flag items with `category_confidence < 0.7` for human review. These are "ambiguous" items.

## Output Schema

Add to each line item:
```json
{
  "category": "office_supplies",
  "category_confidence": 0.95
}
```

Add a top-level `categorization` object to the invoice:
```json
{
  "categorization": {
    "primary_category": "office_supplies",
    "category_breakdown": {
      "office_supplies": 450.00,
      "shipping": 25.00
    },
    "tax_deductible": true,
    "budget_code": "OPS-001",
    "ambiguous_items": []
  }
}
```

## Primary Category Determination

The primary category is the category with the **highest total amount** across all line items.

If two categories tie:
1. Prefer the more specific category (e.g., `software` over `other`)
2. If still tied, prefer alphabetically first

## Tax Deductibility Rules

- `travel`: Mark as `Partial` — transportation and lodging are fully deductible; meals during travel are 50%
- `meals`: Always 50% deductible (not fully deductible)
- `other`: Cannot determine — flag as `Varies`
- All other categories: fully deductible

Set `tax_deductible: true` if primary category is fully deductible, `false` if `other`, `"partial"` if `travel` or `meals`.

## Edge Cases

### Unknown Vendor + Generic Description
Categorize as `other` with `category_confidence: 0.3`. Never guess at a specific category with low confidence — `other` is honest and searchable.

### Multiple Possible Categories
Choose the most specific applicable category. Example: "Microsoft 365 Annual Subscription" → `subscriptions` (more specific than `software`).

### Single-Total Invoice (No Line Items)
If the invoice has no line items, create a synthetic single line item with the invoice total and the vendor-level category. Set `category_confidence` based on vendor name signal quality.

### Mixed-Category Invoice
An invoice from Amazon may have both `office_supplies` and `hardware`. Assign the correct category per line item. The `primary_category` is simply the category with the largest total.

### Shipping Handling Charges
Shipping and handling line items on an otherwise single-category invoice should be categorized as `shipping`. They do not change the primary category.
