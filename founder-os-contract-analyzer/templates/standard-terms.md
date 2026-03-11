# Standard Contract Terms Reference

These are standard, balanced terms commonly found in freelancer and agency contracts. Use these as the baseline for comparison when running `/contract:compare`. Deviations from these standards are flagged with RAG severity levels.

> **Customization**: Copy this file and modify values to match your specific risk tolerance and business requirements.

---

## Payment

| Term | Standard Range | Acceptable | Red Flag |
|------|---------------|------------|----------|
| Payment timing | Net 15 - Net 30 | Net 45 | Net 60+ or "upon client payment" |
| Late payment penalty | 1-1.5% per month | 0.5-2% per month | None specified |
| Deposit / advance | 25-50% upfront | 10-100% upfront | No deposit on large projects (>$10k) |
| Kill fee | 25-50% of remaining | Any percentage | No kill fee for early termination |
| Expense markup | 10-15% | 0-20% | Client refuses all expense reimbursement |
| Invoicing | Monthly or milestone | Any reasonable schedule | Invoicing only at project end for long projects |

## Duration & Renewal

| Term | Standard Range | Acceptable | Red Flag |
|------|---------------|------------|----------|
| Initial term | 3-12 months | 1-24 months | Perpetual with no exit clause |
| Auto-renewal notice | 30 days | 15-60 days | No notice period or >90 days |
| Renewal term | Same as initial or shorter | Any defined period | Longer than initial with no opt-out |
| Early termination notice | 30 days | 15-60 days | No early termination right |

## Intellectual Property

| Term | Standard | Acceptable | Red Flag |
|------|----------|------------|----------|
| Deliverable IP | Client owns upon full payment | Various ownership models | Client owns before payment or perpetually regardless |
| Pre-existing IP | Contractor retains, licenses to client | Shared license | Client claims all pre-existing IP |
| IP transfer timing | Upon final payment | Upon milestone payments | Upon contract signing (before work done) |
| License scope | Non-exclusive for deliverables | Exclusive for deliverables | Exclusive for all contractor's work |
| Portfolio rights | Contractor can show in portfolio | With client approval | Complete prohibition |

## Confidentiality

| Term | Standard | Acceptable | Red Flag |
|------|----------|------------|----------|
| Survival period | 2-3 years | 1-5 years | Perpetual |
| Scope | Project-specific information | Reasonably defined business info | "All information shared in any form" |
| Exclusions | Public info, prior knowledge, legal requirement | Standard 4 exclusions | No exclusions |
| Mutual obligation | Both parties bound | Both parties bound | Only contractor bound |
| Return/destroy | Within 30 days of termination | Within 60 days | Immediate or no provision |

## Liability & Indemnification

| Term | Standard | Acceptable | Red Flag |
|------|----------|------------|----------|
| Liability cap | Total contract value (1x) | 1-3x contract value | No cap / unlimited |
| Indemnification | Mutual | Mutual with reasonable scope | One-sided (contractor only) |
| Consequential damages | Excluded by both parties | Excluded by both | Only excluded for client |
| Insurance | Professional liability, $1M | $500K - $2M | >$5M or unusual coverage types |
| Force majeure | Included, balanced | Included | Absent or one-sided |

## Termination

| Term | Standard | Acceptable | Red Flag |
|------|----------|------------|----------|
| For cause notice | 30 days with cure period | 15-45 days | Immediate, no cure |
| For convenience notice | 30 days | 15-60 days | No convenience termination right for contractor |
| Cure period | 15-30 days | 10-45 days | No cure period |
| Payment on termination | Paid for completed work | Pro-rated payment | No payment for work done |
| Wind-down period | 2-4 weeks | 1-8 weeks | None, immediate cessation |

## Non-Compete & Non-Solicitation

| Term | Standard | Acceptable | Red Flag |
|------|----------|------------|----------|
| Non-compete duration | 6 months | 3-12 months | >2 years |
| Non-compete scope | Direct competitors only | Narrow industry definition | Broad industry or "any similar business" |
| Geographic scope | Local market or N/A | Regional | National/global |
| Non-solicitation | 12 months, direct clients only | 6-18 months | >2 years or "anyone known to client" |
| Compensation during | Paid during restriction | Partial payment | No compensation during restriction |

## Warranty & Representations

| Term | Standard | Acceptable | Red Flag |
|------|----------|------------|----------|
| Warranty period | 30-90 days after delivery | 15-180 days | >1 year or "perpetual" |
| Scope | Work performed in professional manner | Workmanlike quality | Fitness for particular purpose guarantee |
| Remedy | Re-performance or refund | Various proportional | Unlimited re-work obligation |
| Disclaimers | Standard "AS IS" for 3rd party | Reasonable scope | No warranty disclaimers at all |

---

## How Comparison Works

When `/contract:compare` is invoked:
1. Extract terms from the contract using the contract-analysis skill
2. For each extracted term, find the matching category and row in this reference
3. Compare the contract's value against the Standard, Acceptable, and Red Flag columns
4. Flag deviations:
   - Terms matching "Red Flag" -> Red severity
   - Terms outside "Acceptable" but not "Red Flag" -> Yellow severity
   - Terms within "Standard" or "Acceptable" -> Green (no flag)
5. Terms not found in the contract -> Yellow flag as "Missing standard term"
