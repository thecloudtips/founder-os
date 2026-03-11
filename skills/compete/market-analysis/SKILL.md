---
name: Market Analysis
description: "Synthesizes competitive research into strategic insights, SWOT analyses, and positioning recommendations. Activates when the user wants a competitive analysis, market positioning review, competitor comparison matrix, or asks 'how do we stack up against the competition?' Identifies market gaps and strategic opportunities."
version: 1.0.0
---

# Market Analysis

Synthesize competitive research data into strategic insights. This skill takes structured competitor data (from the competitive-research skill) and produces SWOT analyses, positioning characterizations, multi-competitor matrices, and actionable strategic recommendations.

## SWOT Synthesis

### Building from Research Data

Construct SWOT analysis from gathered data rather than guessing. Each quadrant maps to specific data signals:

**Strengths** (infer from):
- High review scores (>4.2/5.0 on G2/Capterra) with specific praise themes
- Differentiating features users explicitly highlight
- Strong free tier that drives adoption
- Clear market leadership signals (high review count = established user base)
- Pricing advantage (lower than comparable alternatives)

**Weaknesses** (infer from):
- Recurring complaint themes in reviews (e.g., "complex setup", "poor mobile app")
- Missing features competitors commonly offer
- Pricing higher than alternatives without clear justification
- Low review count relative to age (indicates slow adoption)
- "Contact Sales" only pricing (barrier to self-serve adoption)

**Opportunities** (infer from):
- Complaints competitors can't address (e.g., "we wish it had X" = unmet need)
- High pricing creating room for affordable alternative
- No strong player in specific segment (enterprise vs. SMB gap)
- Recent news showing pivots away from certain segments

**Threats** (infer from):
- Recent product launches closing feature gaps
- Pricing reductions increasing competitive pressure
- Funding announcements enabling faster development
- New entrants targeting same positioning

### SWOT Output Format

Present SWOT as a 2x2 matrix summary followed by bulleted details. Consult `${CLAUDE_PLUGIN_ROOT}/skills/compete/market-analysis/references/analysis-frameworks.md` for SWOT templates and inference rules.

## Competitive Positioning Framework

### Positioning Archetypes

Classify each competitor into a primary positioning archetype based on messaging and target audience signals:

| Archetype | Signals | Example Messaging |
|-----------|---------|-------------------|
| Enterprise Leader | "Security", "compliance", "scale", complex pricing | "Built for teams of all sizes" |
| SMB Friendly | Affordable pricing, simple UI focus, self-serve | "Get started in minutes" |
| Developer-First | API-first, technical docs, GitHub integration | "Built by developers, for developers" |
| Non-Technical Founder | No-code, templates, guided setup | "No coding required" |
| Vertical Specialist | Industry-specific features, compliance focus | "Built for [industry]" |
| Challenger/Disruptor | "vs [category leader]", price disruption | "Everything [X] does, at half the price" |

### Messaging Analysis

Analyze tagline, value prop, and homepage content to extract:
1. **Primary claim**: What single benefit do they lead with?
2. **Audience signal**: Who are they addressing? ("for teams", "for developers", "for agencies")
3. **Differentiation angle**: How do they claim to be different?
4. **Proof points**: What evidence do they cite? (customer logos, statistics, awards)

### Market Segmentation

Identify which market segments each competitor targets:
- **Size**: Solo/freelancer → SMB → Mid-market → Enterprise
- **Technical level**: Technical → Semi-technical → Non-technical
- **Vertical**: General → Industry-specific (legal, healthcare, e-commerce, etc.)
- **Geography**: Global → Regional focus

## 'vs You' Analysis

### When --your-product is Provided

Activate self-comparison analysis when the user provides `--your-product="description"`. Use the description to:
1. Infer the product's pricing tier, target audience, and feature set
2. Identify where the product likely overlaps with each competitor
3. Identify where the product differs from each competitor
4. Surface positioning whitespace

### Feature Gap Analysis

Build a feature comparison across key dimensions.

For each research dimension, assess:
- **You win**: Feature/capability where the user's product is notably stronger
- **They win**: Feature/capability where the competitor is notably stronger
- **Parity**: Comparable capability (no meaningful advantage)
- **Neither has it**: Potential unmet market need

Prioritize gaps that appear in competitor review complaints — these are unmet needs users actively express.

### Differentiation Opportunities

Identify positioning whitespace by mapping:
1. Which archetypes are overcrowded (multiple strong competitors)
2. Which archetypes have no strong player
3. Which price points are underserved
4. Which audience segments are underserved

The most valuable differentiation opportunity = overcrowded segment with high user complaints + underserved segment with demand signals.

### Pricing Positioning

Assess price positioning relative to competitors:
- **Below market**: Potential price-to-win angle, but check feature parity first
- **At market**: Requires feature or experience differentiation to win
- **Above market**: Requires clear premium justification (enterprise features, compliance, support SLA)

Recommend pricing angle based on the product description and competitive gaps found.

## Strategic Recommendations

### Recommendation Generation Rules

Generate 3-5 actionable recommendations. Each recommendation must:
1. **Be specific**: "Offer a freemium tier with 3 projects" > "Consider a free plan"
2. **Be grounded**: Tied to a specific competitive data finding
3. **Have a clear action**: A founder can act on it this quarter
4. **State the rationale**: "Because X competitor's users complain about Y..."

### Recommendation Types

| Type | Trigger Signal | Example |
|------|---------------|---------|
| Pricing adjustment | Competitors significantly cheaper/pricier | "Introduce a $19/month solo tier to capture self-serve market" |
| Feature gap | Competitors missing feature users want | "Add Slack integration — top complaint across 3 competitors" |
| Messaging pivot | Positioning whitespace identified | "Lead with 'for agencies' messaging — no competitor owns this segment" |
| Market segment | Underserved segment found | "Target freelancers — no competitor has self-serve pricing below $30/month" |
| Competitive defense | Competitor directly threatening position | "Highlight [differentiator] in onboarding — competitor X just launched similar feature" |

### Prioritization Framework

Order recommendations by: **Impact x Urgency**

- **High impact + high urgency**: Do first (competitive threats, pricing gaps)
- **High impact + low urgency**: Plan for next quarter (feature gaps, messaging)
- **Low impact + high urgency**: Quick wins (copy changes, positioning tweaks)
- **Low impact + low urgency**: Monitor (emerging threats, niche opportunities)

## Matrix Building (for /founder-os:compete:matrix)

### Matrix Dimensions

Use these 7 dimensions as matrix rows when comparing multiple competitors:

| Dimension | What to Include |
|-----------|----------------|
| Pricing | Starting price, pricing model, free tier |
| Target Market | Primary audience and company size |
| Key Features | 3-5 standout capabilities |
| Positioning | Primary messaging angle and archetype |
| Review Score | Composite score with platform breakdown |
| Strengths | Top 2-3 competitive advantages |
| Weaknesses | Top 2-3 notable gaps or complaints |

### Normalization for Comparison

Make matrix entries scannable by normalizing:
- Pricing: Always include `per user/month` or `flat/month` for comparability
- Review scores: Show as `X.X/5.0 (N reviews on G2)`
- Features: Use consistent feature names across rows (do not call it "API" for one and "Integrations" for another)
- Strengths/Weaknesses: 3-5 word phrases, not sentences

### 'You' Column

When `--your-product` is provided, add a rightmost "You" column. For each dimension:
- Pricing: State the price/model or "TBD"
- Other dimensions: Assess based on the user's product description
- Highlight cells where the product has a clear advantage with a checkmark marker
- Note whitespace opportunities (where no competitor excels) with a lightbulb marker

## Analysis Quality Standards

### Data Sufficiency Checks

Before generating analysis, verify minimum data thresholds:
- SWOT: Requires at least 3 data signals per quadrant; mark quadrants as "Insufficient data" when below threshold
- Positioning archetype: Requires homepage messaging + at least 1 other signal; default to "Unclear" if only one signal exists
- Recommendations: Only generate recommendations grounded in actual research findings; never fabricate competitive signals

### Confidence Levels

Assign confidence levels to major conclusions:
- **High confidence**: Based on 3+ independent signals (e.g., review themes + pricing page + feature page)
- **Medium confidence**: Based on 2 signals or 1 strong signal (e.g., homepage messaging only)
- **Low confidence / inferred**: Based on 1 weak signal or logical inference; flag clearly as "inferred from..."

### Avoiding Fabrication

When research data is sparse or ambiguous:
- State what is known vs. what is inferred explicitly
- Do not invent competitor features or pricing not found in research
- Use hedging language: "Based on available data...", "Signals suggest...", "Could not verify..."
- Flag data gaps as research opportunities: "Recommend checking G2 reviews directly for complaint themes"

## Synthesis Workflow

When called after `/founder-os:compete:research` or with structured competitor data, follow this sequence:

1. **Inventory the data**: List all competitors researched and the data fields gathered for each
2. **Normalize fields**: Standardize pricing formats, review score formats, and feature terminology
3. **Classify archetypes**: Assign each competitor a positioning archetype with 2-3 supporting signals
4. **Run SWOT per competitor**: Apply inference rules from `${CLAUDE_PLUGIN_ROOT}/skills/compete/market-analysis/references/analysis-frameworks.md`
5. **Build matrix**: Compile normalized data into comparison matrix
6. **Identify whitespace**: Map overcrowded vs. underserved positions
7. **Generate recommendations**: Apply recommendation heuristics, prioritize by Impact x Urgency
8. **Self-comparison (if --your-product provided)**: Run feature gap analysis and differentiation mapping — see `${CLAUDE_PLUGIN_ROOT}/skills/compete/market-analysis/references/analysis-frameworks.md` Section 5 for step-by-step process
