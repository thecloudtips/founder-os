---
name: Pricing Strategy
description: "Designs 3-tier pricing packages for client proposals using the good-better-best framework. Activates when the user wants to price a proposal, create pricing tiers, figure out what to charge, or asks 'how should I package this?' Covers value differentiation, comparison tables, payment terms, milestone structures, and ROI framing."
version: 1.0.0
---

# Pricing Strategy

Design 3-tier pricing packages for client proposals using the good-better-best framework. Translate project scope into differentiated packages with clear value progression, appropriate pricing, and a comparison table that guides clients toward the recommended option.

## Good-Better-Best Philosophy

Every proposal presents exactly 3 packages. The purpose is not to offer choice for its own sake — it is to anchor the conversation around value rather than cost, and to give the client a path at every budget level.

| Tier | Role in the Framework | Typical Scope |
|------|----------------------|---------------|
| Starter | Entry point — solves the core problem with minimum scope | Core deliverables only, minimal customization, shortest timeline |
| Professional | Sweet spot — recommended option with the best value-to-scope ratio | Core + key enhancements, moderate customization, standard timeline |
| Enterprise | Full vision — maximum scope for clients with flexible budgets | Everything in Professional + stretch deliverables, premium support, longest timeline |

The Professional package is always the recommended default. Mark it clearly in the comparison table.

## Package Naming

Name packages to signal value and fit, not size or price.

**Effective naming patterns:**
- **Outcome-based**: Launch-Ready / Launch + Optimize / Full-Scale Launch
- **Functional scope**: Foundation / Growth / Transformation
- **Progression-based**: Essentials / Professional / Complete

**Naming anti-patterns:**
- Size-based labels ("Small / Medium / Large") — anchor clients on quantity, not value
- Generic tiers ("Basic / Pro / Enterprise") — overused, say nothing about the project
- Price-anchoring labels ("Budget / Standard / Premium") — frame the decision around cost

Choose names that a client would use when referring to the package in conversation. "We're going with the Growth package" reads better than "We're going with Option B."

## Pricing Calculation Frameworks

Apply one or more of three frameworks depending on the project type and available information. When multiple frameworks apply, calculate with each and use the results to sanity-check one another.

### Effort-Based Pricing

Calculate from hours and rates:

```
Total = (Estimated Hours × Hourly Rate) + Margin
```

- Break work into task areas before estimating hours (never estimate the project as a single number)
- Apply role-specific rates if multiple skill levels are involved
- Add a margin of 15-25% on top of raw labor cost for overhead, coordination, and profit
- The Starter package uses the conservative estimate; Enterprise uses the full-scope estimate

### Value-Based Pricing

Anchor to client ROI:

```
Price ≤ 10-20% of Year 1 Expected Value to Client
```

- Identify the measurable business outcome (revenue increase, cost reduction, time saved)
- Quantify the annual value of that outcome
- Price the engagement at 10-20% of Year 1 value — the client pays a fraction of what they gain
- Frame pricing conversations around this ratio: "For an investment of $X, you gain $Y annually"

### Competitive Pricing

Position relative to market rates:

- Research comparable services in the client's industry
- Position Starter at or slightly below market rate to lower barriers
- Position Professional at market rate with differentiated value
- Position Enterprise above market rate justified by premium scope and support

## Scope Differentiation Rules

Define clear boundaries for what each tier includes. The tiers must feel distinct — if a client cannot articulate the difference between two tiers in one sentence, they are too similar.

### Starter Package
- Core deliverables only — the minimum that solves the stated problem
- No customization beyond what the brief requests
- Standard documentation (no training, no extended support)
- Shortest timeline (minimum viable delivery)
- 1 round of revisions per deliverable

### Professional Package
- Everything in Starter, plus 2-3 high-value enhancements
- Moderate customization (client branding, workflow adjustments)
- Enhanced documentation plus a training session or walkthrough
- Standard timeline with adequate buffer
- 2 rounds of revisions per deliverable
- Post-delivery hypercare period (2 weeks recommended)

### Enterprise Package
- Everything in Professional, plus stretch deliverables from the full vision
- Full customization (integrations, advanced features, premium design)
- Comprehensive documentation, training, and admin dashboard
- Extended timeline to accommodate full scope
- Unlimited revisions within scope
- Extended hypercare period (4 weeks recommended)
- Priority support channel during engagement

## Comparison Table Layout

The comparison table is the first thing most clients read in the Pricing section. Follow these rules:

```
| | [Starter Name] | **[Professional Name] ✓** | [Enterprise Name] |
|---|---|---|---|
| **Scope** | [Brief scope description] | [Brief scope description] | [Brief scope description] |
| **Deliverables** | [Count] | [Count] | [Count] |
| **Timeline** | [N weeks] | [N weeks] | [N weeks] |
| **Revisions** | 1 round | 2 rounds | Unlimited |
| **Support** | [Support level] | [Support level] | [Support level] |
| **Investment** | $[X] | $[X] | $[X] |
```

Rules:
- **Scope first, price last**: Lead with what the client gets. Investment is the last row.
- **Bold the recommended column header**: Mark Professional with ✓ in the header.
- **Keep cells brief**: 3-8 words per cell. Detail lives in the individual package sections.
- **No ranges**: Every cell uses a single committed value.
- **Consistent units**: All prices in the same currency and format ($XX,XXX).

## ROI Framing

Connect every pricing tier to business outcomes. Clients buy results, not hours.

- State the expected return for each package: "The Growth package pays for itself within [N] months through [specific saving or revenue gain]"
- Use concrete comparisons: "At $28,000, this represents less than the cost of [comparable business expense] and delivers [quantified outcome]"
- Include a "cost of inaction" perspective when relevant: "Each month without [solution] costs approximately $[X] in [lost revenue / manual labor / risk exposure]"

## Payment Terms Patterns

Propose payment terms tied to deliverable acceptance, not calendar dates:

### Milestone-Based (Recommended)
```
30% at project kickoff
30% at mid-project milestone acceptance
40% at final delivery acceptance
```

### Monthly
```
Equal monthly installments over the project duration
First payment at kickoff, last payment at delivery
```

### Upfront Discount
```
Full payment at kickoff: 10% discount applied
Standard terms otherwise: milestone-based
```

Choose the pattern that matches the client's likely preference. For new clients, recommend milestone-based (lowest risk for both parties). For returning clients, offer the upfront discount as a relationship benefit.

## Anti-Patterns

**Tiers too similar**: If the price difference between Starter and Professional is less than 30%, the tiers lack differentiation. Widen the scope gap.

**Anchoring too low**: Setting Starter at an artificially low price to "get the foot in the door" devalues the work. Starter should be profitable on its own.

**Hidden costs**: Every cost must appear in the proposal. Hosting, licenses, third-party fees — if the client pays for it, it is in the pricing table or explicitly noted as a client-side cost.

**Scope overlap confusion**: If an item appears in Professional but not Enterprise, the client assumes Enterprise is worse. Enterprise always includes everything from lower tiers plus additions.

**Price-first presentation**: Never present pricing before the client understands the scope. The comparison table structure enforces this, but individual package sections must also lead with scope before stating the price.

## Additional Resources

### Reference Files

For detailed pricing calculation examples and worked scenarios:
- **`${CLAUDE_PLUGIN_ROOT}/skills/proposal/pricing-strategy/references/pricing-models.md`** — Complete examples of effort-based, value-based, and competitive pricing calculations with different project types
