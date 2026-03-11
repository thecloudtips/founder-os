# Analysis Frameworks Reference

This reference file contains detailed frameworks, templates, inference rules, and worked examples for the market-analysis skill. Consult this file for expanded guidance beyond what is summarized in SKILL.md.

---

## 1. SWOT Analysis Templates

### Complete SWOT Template

Use this template structure when producing a SWOT for a single competitor:

```
## [Competitor Name] — SWOT Analysis

| | Helpful | Harmful |
|---|---|---|
| **Internal** | **Strengths** | **Weaknesses** |
| | [S1] | [W1] |
| | [S2] | [W2] |
| | [S3] | [W3] |
| **External** | **Opportunities** | **Threats** |
| | [O1] | [T1] |
| | [O2] | [T2] |
| | [O3] | [T3] |

### Strengths Detail
- **[S1 Label]**: [1-2 sentence evidence-backed explanation]
- **[S2 Label]**: [1-2 sentence evidence-backed explanation]

### Weaknesses Detail
- **[W1 Label]**: [1-2 sentence evidence-backed explanation]
- **[W2 Label]**: [1-2 sentence evidence-backed explanation]

### Opportunities Detail
- **[O1 Label]**: [1-2 sentence explanation of the opportunity and why this competitor could capture it]
- **[O2 Label]**: [explanation]

### Threats Detail
- **[T1 Label]**: [1-2 sentence explanation of the threat and why it is material]
- **[T2 Label]**: [explanation]

*Confidence: High | Medium | Low — [brief note on data coverage]*
```

### Multi-Competitor SWOT Summary Template

When running SWOT across 3+ competitors, produce a summary table before individual breakdowns:

```
## Competitive SWOT Summary

| Competitor | Key Strength | Key Weakness | Primary Opportunity | Primary Threat |
|---|---|---|---|---|
| [Name A] | [1 phrase] | [1 phrase] | [1 phrase] | [1 phrase] |
| [Name B] | [1 phrase] | [1 phrase] | [1 phrase] | [1 phrase] |
| [Name C] | [1 phrase] | [1 phrase] | [1 phrase] | [1 phrase] |
```

---

## 2. SWOT Inference Rules

### Strengths — Data Signal Mapping

| Research Signal | SWOT Strength to Infer |
|---|---|
| G2/Capterra score ≥ 4.5/5.0 | "Market-leading customer satisfaction" |
| G2/Capterra score 4.2–4.4/5.0 | "Above-average user satisfaction" |
| Review count > 500 on any single platform | "Established user base and social proof" |
| Recurring praise theme in ≥ 3 reviews (e.g., "easy setup") | "Recognized ease of use" (use the actual theme) |
| Free tier or freemium plan exists | "Low-friction acquisition via free tier" |
| Pricing is lowest in the comparison set | "Pricing advantage over alternatives" |
| Backed by >$10M in funding (from recent news) | "Well-capitalized for R&D and growth" |
| Integration count > 50 or native CRM/Slack/Drive integration | "Broad ecosystem compatibility" |
| Multiple G2 badge categories (Leader, Momentum Leader, etc.) | "Recognized across multiple review dimensions" |
| Strong SEO footprint (ranks for primary category terms) | "Organic distribution advantage" |

### Weaknesses — Data Signal Mapping

| Research Signal | SWOT Weakness to Infer |
|---|---|
| G2/Capterra score < 3.8/5.0 | "Below-average user satisfaction — retention risk" |
| Recurring complaint theme in ≥ 2 reviews (e.g., "clunky UI") | "Known UX friction" (use the actual theme) |
| "Contact Sales" required for pricing | "Lack of self-serve pricing creates adoption barrier" |
| Pricing is highest in comparison set without clear premium justification | "Premium pricing risk without differentiated positioning" |
| Mobile app missing or rated poorly (<3.5) | "Weak mobile experience limits adoption" |
| Review count < 50 despite 2+ years on market | "Slow market adoption signals" |
| API access locked behind highest tier | "Integration barrier for technical buyers" |
| No customer logos or case studies on homepage | "Weak social proof and enterprise credibility" |
| Changelog/blog last updated > 6 months ago | "Slow release cadence may indicate stagnation" |
| Multiple reviews mention "learning curve" or "complex onboarding" | "High time-to-value reduces trial conversion" |

### Opportunities — Data Signal Mapping

| Research Signal | SWOT Opportunity to Infer |
|---|---|
| Competitor review complaint = "wish it had [feature X]" | "Unmet demand for [feature X] — opportunity to build and position against this" |
| All competitors priced > $50/month | "Underserved affordable tier — room for sub-$30 positioning" |
| No competitor has self-serve free tier | "Freemium wedge opportunity to acquire leads at zero cost" |
| No competitor leads with a specific industry vertical | "Vertical specialization opportunity — be the [industry] solution" |
| Competitor recently raised funding and pivoted upmarket | "They abandoned SMB segment — opportunity to capture displaced users" |
| Highest-rated feature is narrow (e.g., "great for email outreach") | "Adjacent use cases unaddressed — expand positioning" |
| Competitor review sentiment shifted negative in last 6 months | "User churn risk = acquisition opportunity with targeted migration messaging" |
| No competitor offers strong onboarding or implementation support | "White-glove onboarding as differentiator" |

### Threats — Data Signal Mapping

| Research Signal | SWOT Threat to Infer |
|---|---|
| Competitor raised Series A or B in last 12 months | "Well-funded competitor accelerating product development" |
| Competitor launched feature directly overlapping with your key differentiator | "Feature parity threat — differentiator eroding" |
| Market leader has started offering free tier | "Incumbent entering self-serve market — price competition risk" |
| Multiple new entrants in last 6 months (news signals) | "Increasing category saturation may compress margins and CAC" |
| Competitor reduced pricing by > 20% | "Price war risk — may force defensive pricing response" |
| Competitor integrating AI features prominently | "AI-powered workflow risk — adoption preference shifting" |
| Large platform (Google, Microsoft, Salesforce) announced similar feature | "Platform integration risk — ecosystem cannibalization" |

---

## 3. Positioning Archetype Signals

### Enterprise Leader

**Primary signals** (need 2+ to classify):
- Pricing page shows "Enterprise" tier with "Contact Sales" CTA
- Homepage references Fortune 500 customer logos or recognizable enterprise brands
- Messaging uses terms: "security", "compliance", "SOC 2", "GDPR", "SSO", "audit logs", "admin controls"
- Feature list includes: role-based access control, custom SLAs, dedicated support, onboarding services
- Pricing starts at $50+/user/month or flat enterprise contract pricing
- Case studies reference IT teams, procurement, or legal/compliance stakeholders

**Messaging patterns**:
- "Enterprise-ready from day one"
- "Trusted by [number] teams at Fortune 500 companies"
- "SOC 2 Type II certified"
- "Built for scale"

**Audience signals**: CTOs, IT directors, procurement officers, compliance teams

---

### SMB Friendly

**Primary signals** (need 2+ to classify):
- Pricing page shows transparent, affordable tiers (typically $10–$50/month per user or $50–$200/month flat)
- Free tier or free trial prominently featured
- Setup time emphasized ("up and running in 5 minutes", "no onboarding required")
- Homepage messaging references "small teams", "growing businesses", "startups"
- Feature set emphasizes simplicity over breadth (fewer features, cleaner UI)
- Reviews mention "easy to use" as a top praise theme

**Messaging patterns**:
- "Get started in minutes"
- "No credit card required"
- "Built for small teams"
- "Simple pricing, no surprises"

**Audience signals**: Founders, office managers, small teams (2–20 people), non-technical users

---

### Developer-First

**Primary signals** (need 2+ to classify):
- Homepage leads with API documentation link or code snippets
- GitHub integration is a core feature (not just listed in integrations)
- Pricing tier tied to API calls or webhook events, not seats
- Tech stack or infrastructure mentioned on homepage (e.g., "built on AWS", "Postgres-native")
- Blog content is technical (how-tos, engineering posts)
- Reviews mention "great API", "well-documented", "easy to integrate"
- Open-source component or self-hosted option available

**Messaging patterns**:
- "Built by developers, for developers"
- "Integrate in minutes with our REST API"
- "Self-hosted or cloud — your choice"
- "Open source at the core"

**Audience signals**: Software engineers, CTOs of technical companies, DevOps, platform teams

---

### Non-Technical Founder

**Primary signals** (need 2+ to classify):
- Messaging explicitly references "no coding required" or "no-code"
- Onboarding uses templates, wizards, or guided flows prominently
- Screenshots show drag-and-drop interfaces
- Blog content focuses on business outcomes, not technical implementation
- Reviews mention "finally, a tool I can use without a developer"
- Integrations listed as logos with one-click connect (Zapier-style)

**Messaging patterns**:
- "No coding required"
- "Start with a template"
- "Built for founders, not engineers"
- "Launch without a developer"

**Audience signals**: Solopreneurs, bootstrapped founders, non-technical business owners, coaches, consultants

---

### Vertical Specialist

**Primary signals** (need 2+ to classify):
- Product name or homepage headline references a specific industry (e.g., "for law firms", "for agencies", "for real estate")
- Feature list includes industry-specific terminology (e.g., "matter management" for legal, "retainer billing" for agencies)
- Compliance certifications relevant to the industry (HIPAA for healthcare, BAR compliance for legal)
- Case studies are all from one or two industries
- Pricing page references industry-standard workflows
- Reviews come predominantly from one industry's professionals

**Messaging patterns**:
- "Built specifically for [industry]"
- "The [industry] platform"
- "[Feature] built for [industry] workflows"
- "Trusted by [N] [industry] professionals"

**Audience signals**: Industry-specific buyers with specialized compliance or workflow needs

---

### Challenger/Disruptor

**Primary signals** (need 2+ to classify):
- Explicit "vs [competitor]" pages on their website
- Pricing positioned as fraction of market leader's price
- Homepage calls out incumbent by name or category ("tired of [X]?")
- Recent launch (< 3 years old) with rapid review growth
- Funding announcement with disruptive positioning in press release
- Feature-for-feature comparison table on homepage or pricing page

**Messaging patterns**:
- "Everything [X] does, at half the price"
- "Why pay for [X] when you can get [Y]?"
- "[X] alternative — built for modern teams"
- "The [category] tool that doesn't require a consultant to set up"

**Audience signals**: Price-sensitive buyers switching from incumbent, early adopters seeking modern alternatives

---

## 4. Recommendation Generation Heuristics

### Signal → Recommendation Type → Example

#### Pricing Adjustment

**Trigger signals**:
- All competitors priced > $40/user/month (underserved affordable tier)
- Competitors offer free tier; user's product does not
- Pricing is highest in set without apparent premium feature differentiation

**Heuristic**: If the lowest competitor price is more than 40% below user's price, recommend a lower self-serve tier. If no freemium exists across the set and user's product has natural viral mechanics, recommend a free tier.

**Example recommendation**:
> "Introduce a $19/month solo tier — the cheapest competitor charges $35/month, creating a $16 pricing gap that targets price-sensitive solopreneurs. This tier should be limited to 3 projects or 1 user to preserve upsell path."

**Rationale template**: "Because [competitor A] charges $[X]/month and [competitor B] charges $[Y]/month, the lowest price point in the market is $[Z]. A $[lower] tier would position [product] as the most affordable entry point, capturing [segment] who currently have no affordable option."

---

#### Feature Gap

**Trigger signals**:
- 2+ competitor reviews mention the same missing feature (e.g., "wish it had Slack integration")
- A feature is present in all competitors but absent in user's product
- A feature uniquely available in user's product is absent in all competitors (opportunity to highlight, not fill)

**Heuristic**: If the same feature complaint appears in reviews of 2+ competitors, it is a category-wide gap, not a single competitor problem — high-value to fill. If the feature appears in all competitors, treat it as table stakes to match.

**Example recommendation**:
> "Add native Slack integration — this is the top complaint in G2 reviews for both [Competitor A] and [Competitor B]. Neither has solved it, making it a category-wide gap. Building a Slack bot that surfaces [product's key action] would be a differentiator, not just parity."

**Rationale template**: "Reviews for [Competitor A] (N mentions) and [Competitor B] (N mentions) both cite [feature] as a missing capability. No competitor in this set has addressed it. Building [feature] would be a genuine differentiator rather than parity-filling."

---

#### Messaging Pivot

**Trigger signals**:
- No competitor owns a specific audience segment in their homepage messaging
- A competitor recently pivoted to enterprise, abandoning SMB messaging
- User's product has unique audience claim no competitor makes

**Heuristic**: If 3+ competitors all use similar messaging (e.g., all lead with "for teams"), there is an opportunity to differentiate through a more specific audience claim. Identify the most specific unowned segment that matches user's product capabilities.

**Example recommendation**:
> "Lead with 'the CRM for solo consultants' in homepage headline — every competitor in this set targets 'teams' or 'businesses.' No competitor has claimed the solo/freelance segment in their primary messaging despite charging affordable pricing. This positioning gap is claimable without a feature change."

**Rationale template**: "All [N] competitors in this set use [common messaging theme] as their primary claim. The [specific segment] audience is mentioned by none of them, yet [signal from research] suggests demand exists. Claiming this segment requires only a messaging change, not a product change."

---

#### Market Segment

**Trigger signals**:
- A demographic segment (freelancers, agencies, non-profits, etc.) is mentioned in competitor reviews as customers but not addressed in competitor messaging
- Pricing models exclude a segment (e.g., per-seat pricing excludes freelancers)
- Geographic market has no dominant local player

**Heuristic**: If a segment appears in positive reviews (users self-identifying as segment members praising the product) but not in homepage messaging, the competitor is serving the segment accidentally. An intentional pitch to that segment is a positioning opportunity.

**Example recommendation**:
> "Target design agencies explicitly — [Competitor A]'s reviews show 23% of reviewers self-identify as agency professionals, yet their homepage targets 'marketing teams.' A dedicated 'for agencies' page with retainer billing support and multi-client workspace would own a segment no one is deliberately targeting."

**Rationale template**: "[N]% of [Competitor]'s reviews come from [segment] professionals, yet no competitor has built [segment]-specific features or messaging. [Segment] users need [specific capability] that general tools underserve. Deliberate targeting here creates a defensible niche."

---

#### Competitive Defense

**Trigger signals**:
- Competitor launched a feature directly competing with user's differentiator
- Competitor raised funding that enables faster roadmap execution
- Competitor announced a partnership that improves their offering in user's key area

**Heuristic**: When a competitor closes a feature gap within 6 months, assess whether the user's advantage was deep (hard to replicate quickly) or shallow (easily matched). Shallow advantages require immediate response; deep advantages require proactive communication to existing users.

**Example recommendation**:
> "Proactively communicate [differentiator] depth to existing users — [Competitor A] launched [feature] last month, which superficially matches [product's] [capability]. However, [product] has [N months] of iteration on [specific sub-feature] that their v1.0 lacks. Send a comparison email to existing users before they evaluate alternatives."

**Rationale template**: "[Competitor] launched [feature] on [date], creating apparent parity with [product's] [differentiator]. Their implementation lacks [specific depth]. Proactive communication of the depth difference prevents existing customer churn during their evaluation window."

---

## 5. 'vs You' Comparison Framework

### Step-by-Step Self-Comparison Process

Use this process when `--your-product="description"` is provided:

**Step 1 — Parse the product description**

Extract from the user's description:
- Pricing tier (if mentioned): "starts at $X/month", "free to start", "enterprise only"
- Target audience (if mentioned): "for freelancers", "for SaaS teams", "B2B"
- Key features (if mentioned): list all explicitly named capabilities
- Stage (if inferable): early-stage startup vs. established product

If any of these are absent, mark as "Not specified — assumed [reasonable default]" and proceed. Do not ask the user to clarify during the analysis; make reasonable assumptions and flag them.

**Step 2 — Map against each competitor dimension**

For each of the 7 matrix dimensions, assess user's product:

| Dimension | How to Assess Without Complete Data |
|---|---|
| Pricing | Use stated price; if absent, mark "TBD — assume at/above market" |
| Target Market | Use stated audience; if absent, infer from features described |
| Key Features | List explicitly mentioned features; mark others as "Unknown" |
| Positioning | Infer from description tone and audience; label as "Inferred" |
| Review Score | Mark as "N/A — not yet listed on review platforms" if not mentioned |
| Strengths | Use stated differentiators from description |
| Weaknesses | Honestly note gaps vs. competitors based on feature list |

**Step 3 — Feature gap analysis**

Build a gap table:

```
| Feature/Capability | [Competitor A] | [Competitor B] | You | Gap Type |
|---|---|---|---|---|
| [Feature 1] | Yes | Yes | Yes | Parity |
| [Feature 2] | Yes | No | No | They win (A) |
| [Feature 3] | No | No | Yes | You win |
| [Feature 4] | Yes (complaints) | Yes (complaints) | No | Unmet need |
```

**Gap types**:
- **You win**: Your product has this; competitors do not → highlight in positioning
- **They win (single)**: One competitor has it → monitor; medium priority to build
- **They win (all)**: All competitors have it → table stakes; high priority to build
- **Parity**: Feature present across all → not a differentiator for anyone
- **Unmet need**: Present in competitors but generates complaints → opportunity to do it better
- **Neither has it**: Absent everywhere → potential whitespace or signal it's not valued

**Step 4 — Positioning whitespace map**

Plot competitors on a 2x2 matrix using the two most relevant axes for the category. Common axis pairs:

- Axis pair A: **Price** (low → high) vs. **Complexity** (simple → complex)
- Axis pair B: **Audience size** (niche → broad) vs. **Technical requirement** (non-technical → developer)
- Axis pair C: **Feature breadth** (narrow → broad) vs. **Pricing model** (usage-based → seat-based)

Choose the axis pair that best reveals differentiation opportunities in the specific category.

Describe the whitespace in prose: "The lower-left quadrant (simple + affordable) is occupied only by [Competitor A], which has weak review scores. [Competitor B] and [C] dominate the complex + expensive quadrant. The simple + mid-priced quadrant is empty — a positioning opportunity."

**Step 5 — Differentiation recommendation**

Generate 1-3 self-comparison specific recommendations:
- One on positioning (how to message)
- One on features (what to build or highlight)
- One on pricing (how to price relative to competitors)

### Handling Incomplete Product Information

When the user's product description is sparse (< 2 sentences or missing key fields):

1. State your assumptions explicitly at the top of the self-comparison section: "The following analysis assumes [X, Y, Z] based on the brief description provided. Adjust these assumptions if incorrect."
2. Mark inferred fields clearly: "Inferred: pricing assumed at market rate (~$29/month)"
3. Complete the analysis anyway — a partial self-comparison is more useful than no comparison
4. End with: "To improve this analysis, provide: [list specific missing fields]"

---

## 6. Matrix Normalization Examples

### Pricing Normalization

**Goal**: Make pricing scannable and directly comparable.

**Raw data examples and normalized output**:

| Raw Pricing | Normalized Output |
|---|---|
| "Free, Pro $15/mo, Business $40/mo" | Free tier + $15/user/month (Pro) |
| "$99/month for up to 5 users" | $19.80/user/month (5-seat flat) |
| "Contact Sales" | Contact Sales (enterprise only) |
| "Free forever for 1 user, $8/user/month after" | Free (1 user) + $8/user/month |
| "$0.02 per API call, $49 platform fee" | Usage-based: $49/month + $0.02/call |
| "Starting at $500/month" | $500/month+ (floor — actual varies) |

**Normalization rules**:
1. Always include pricing model type: `per user/month`, `flat/month`, `usage-based`, `contact sales`
2. Always flag free tier existence: "Free tier" or "No free tier"
3. Convert annual pricing to monthly for comparison: divide by 12 and note "(annual billing)"
4. Never leave pricing as a sentence — reduce to a scannable phrase

---

### Feature Normalization

**Goal**: Use consistent vocabulary across all competitors so features are directly comparable.

**Vocabulary standardization table (apply consistently)**:

| Avoid using | Use instead |
|---|---|
| "API", "REST API", "Webhooks", "Zapier" | API / Integrations |
| "Slack bot", "Slack integration", "Slack app" | Slack integration |
| "Mobile", "iOS app", "Android app", "Mobile-friendly" | Mobile app |
| "Reports", "Analytics dashboard", "Insights", "Metrics" | Analytics / Reporting |
| "Team accounts", "Multi-user", "Seats", "User management" | Team collaboration |
| "Custom branding", "White-label", "Remove branding" | White-labeling |
| "Automations", "Workflows", "Triggers", "Rules" | Workflow automation |
| "Permissions", "Roles", "RBAC", "Admin controls" | Role-based access |

**When a feature doesn't fit a standard term**: Use the shortest accurate description and apply it consistently to all competitors.

---

### Review Score Normalization

**Goal**: Make review scores comparable across platforms with different scales and review volumes.

**Normalization format**: `[Score]/5.0 ([N] reviews, [Platform])`

**Examples**:

| Raw data | Normalized output |
|---|---|
| "4.7 stars on G2 with 234 reviews" | 4.7/5.0 (234 reviews, G2) |
| "4.2 on Capterra, 89 reviews" | 4.2/5.0 (89 reviews, Capterra) |
| "Listed on G2 but no reviews yet" | No reviews (G2 — unrated) |
| "Not found on review platforms" | Not listed on G2/Capterra |
| "4.5 on G2 (180 reviews), 4.3 on Capterra (45 reviews)" | 4.5/5.0 (180, G2) · 4.3/5.0 (45, Capterra) |

**Composite score calculation** (when data from multiple platforms):
- Weighted average by review count: `((score_A × count_A) + (score_B × count_B)) / (count_A + count_B)`
- Show composite as: `4.4/5.0 composite (225 total reviews across G2 + Capterra)`

**Score interpretation tiers** (use in analysis narrative):
- 4.5–5.0: Market-leading satisfaction
- 4.2–4.4: Above average; competitive
- 3.8–4.1: Average; room for improvement
- 3.5–3.7: Below average; notable user dissatisfaction
- < 3.5: Poor satisfaction; churn risk signal

---

### Matrix Example — Worked Output

**Scenario**: 3 competitors in project management space, user's product included.

```
| Dimension | Competitor A | Competitor B | Competitor C | You |
|---|---|---|---|---|
| Pricing | Free tier + $12/user/month | $25/user/month (no free) | Contact Sales | Free tier + $19/month flat ✅ |
| Target Market | Teams 5–50 people | Mid-market teams | Enterprise (100+ seats) | Freelancers & solo founders 💡 |
| Key Features | Task mgmt, Gantt, Slack integration | Task mgmt, Time tracking, Reporting | Task mgmt, SSO, Audit logs, SLA | Task mgmt, AI summaries, Client portal |
| Positioning | SMB Friendly | SMB Friendly | Enterprise Leader | Non-Technical Founder 💡 |
| Review Score | 4.3/5.0 (412 reviews, G2) | 4.1/5.0 (89 reviews, G2) | 4.6/5.0 (1,204 reviews, G2) | N/A — not yet listed |
| Strengths | Strong integrations; large user base | Deep time tracking; good reporting | Enterprise trust; strong compliance | Flat pricing; AI features; client portal |
| Weaknesses | Complex onboarding; mobile app weak | No free tier; slow release cadence | Expensive; no self-serve | Unknown review volume; limited integrations |
```

**Legend**:
- ✅ = clear advantage for "You" in this dimension
- 💡 = whitespace opportunity — no competitor owns this position

**Matrix narrative** (always follow table with prose):

"Competitor A and B both occupy SMB Friendly positioning with per-seat pricing, creating pricing pressure at the $12–$25/user/month range. Competitor C dominates enterprise and is not a direct competitive threat at this stage. The solo/freelancer segment (sub-$20/month flat pricing, non-technical messaging) is unoccupied. Your flat $19/month pricing and AI-first features create a genuine whitespace claim in the Non-Technical Founder archetype that neither Competitor A nor B is targeting."
