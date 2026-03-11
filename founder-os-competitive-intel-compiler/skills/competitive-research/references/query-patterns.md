# Competitive Research Query Patterns

Reference for building targeted search queries across all 5 research dimensions.

**Placeholders:**
- `{{company_name}}` — Company name (e.g., "Notion", "Linear", "Figma")
- `{{domain}}` — Company domain without protocol (e.g., "notion.so", "linear.app", "figma.com")
- `{{year}}` — Current year (always use current year for pricing and news queries)
- `{{category}}` — Product category (e.g., "project management", "design tool", "CRM")

---

## 1. Pricing Research

### Query Templates

| Template | Purpose |
|----------|---------|
| `{{company_name}} pricing {{year}}` | General pricing page — usually surfaces the official page or a reliable roundup |
| `site:{{domain}} pricing` | Direct hit on the official pricing page, bypasses SEO noise |
| `{{company_name}} pricing plans enterprise` | Surfaces enterprise tier details often buried below the fold |
| `{{company_name}} cost per user per month {{year}}` | Targets per-seat billing pages and comparison articles |
| `{{company_name}} "annual plan" OR "billed annually" pricing` | Surfaces annual commitment discounts explicitly |
| `{{company_name}} free plan limits OR free tier` | Confirms free tier existence and its upgrade triggers |

### Site-Specific Variants

```
site:g2.com {{company_name}} pricing
site:capterra.com {{company_name}} pricing
"{{company_name}}" pricing site:getapp.com
```

G2 and Capterra both display vendor-confirmed pricing summaries that are often more accurate than search-engine-aggregated results. Use these as secondary verification when the official page is ambiguous.

### What to Extract

- Plan names and tier labels (Free, Starter, Pro, Business, Enterprise, Growth)
- Price per user/month at monthly billing rate
- Price per user/month at annual billing rate (and the discount percentage)
- Minimum seat requirements (e.g., "minimum 5 seats for Business plan")
- Free trial duration and whether a credit card is required
- Usage limits that gate plan tiers (e.g., storage, API calls, seats, workspaces)
- Enterprise pricing signal: "Contact Sales", "Talk to us", or "Custom pricing"
- Startup or nonprofit discount programs (search `{{company_name}} startup program` if not visible)

### Normalization Notes

- Always record both monthly and annual pricing if both exist.
- If a plan says "$X/month, billed annually as $Y/year", record both and compute the effective monthly rate (Y ÷ 12).
- If pricing is listed in a currency other than USD, note the currency and do not convert — conversion rates fluctuate.
- Mark any price that is more than 6 months old as "(verify on official site)".

---

## 2. Features Research

### Query Templates

| Template | Purpose |
|----------|---------|
| `site:{{domain}} features` | Official features page — most reliable for core capability list |
| `{{company_name}} features list {{year}}` | Surfaces recent comparison blog posts and roundups |
| `{{company_name}} vs alternatives features` | Exposes how the company frames its differentiators against competitors |
| `{{company_name}} "new feature" OR changelog OR "product update" {{year}}` | Captures recently shipped capabilities |
| `site:{{domain}} integrations` | Lists native integrations — a proxy for platform maturity |
| `{{company_name}} API OR "developer platform" OR "open API"` | Signals extensibility and technical differentiation |

### Site-Specific Variants

```
site:g2.com {{company_name}} features
site:capterra.com {{company_name}}
site:producthunt.com {{company_name}}
```

ProductHunt listings include user-written feature summaries at launch that are often more readable than marketing copy. G2's "Features" tab on a product profile shows which specific features users rate most highly.

### What to Extract

- Primary feature categories listed on the official features page
- Any "coming soon" or "beta" features — signals roadmap direction
- Named integrations (especially with common tools: Slack, Notion, Google Workspace, Zapier)
- AI or automation capabilities — note specifically if AI is native vs. add-on
- Mobile app availability (iOS/Android)
- Offline capability
- White-label or custom branding options
- SSO, SAML, and enterprise security features
- Data export formats (CSV, API, native export)
- Features explicitly called out on the comparison page (usually the company's strongest claims)

### Categorization Guidance

After extraction, assign each feature to one of three buckets:

1. **Core** — available in most tools in this category (table stakes).
2. **Differentiating** — unique, unusually strong, or prominently featured vs. alternatives.
3. **Gap** — absent, mentioned frequently as missing in reviews, or clearly weaker than competitors.

---

## 3. Customer Reviews Research

### Query Templates

| Template | Purpose |
|----------|---------|
| `site:g2.com {{company_name}} reviews` | G2 profile — structured review data, user ratings, and pros/cons |
| `site:capterra.com {{company_name}} reviews` | Capterra profile — SMB-weighted audience, detailed pros/cons |
| `{{company_name}} reviews {{year}}` | Surfaces recent independent review articles and roundups |
| `{{company_name}} reddit reviews OR "my experience" OR "honest review"` | Unfiltered user sentiment from communities |
| `site:producthunt.com {{company_name}}` | Launch reviews and upvote count — captures early-adopter sentiment |
| `{{company_name}} trustpilot` | Customer service and billing complaint patterns |

### Site-Specific Variants

```
site:g2.com "{{company_name}}" reviews
"{{company_name}}" site:reddit.com reviews OR complaints OR problems
{{company_name}} reviews site:softwareadvice.com
```

Reddit is particularly valuable for surfacing raw complaints that polished review platforms suppress. Focus on subreddits like r/SaaS, r/ProjectManagement, r/Entrepreneur, r/productivity, and the company's own subreddit if one exists.

### What to Extract

**From G2 / Capterra profiles:**
- Overall star rating (out of 5.0) and total review count
- Category-specific scores if shown (Ease of Use, Features, Customer Support, Value for Money)
- Top 3 "Pros" themes from the review summary panel
- Top 3 "Cons" themes from the review summary panel
- Most recent 3-5 reviews (to check for sentiment drift)
- Reviewer industry and company size distribution (indicates target market fit)

**From Reddit / community:**
- Recurring complaint themes (note the pattern, not individual posts)
- Specific competitor comparisons users make ("switched from X to Y because...")
- Praise themes that appear organically (unprompted)

**From ProductHunt:**
- Total upvote count and rank in category
- Launch date (indicates product age)
- Comment sentiment themes from the launch discussion

### Normalization Notes

- All platform scores normalize to /5.0 for the composite. Do not convert ProductHunt upvotes to a score — record separately.
- Composite score = average of all available /5.0 platform scores, weighted equally.
- Flag any platform score based on <50 reviews as `low_confidence: true`.
- If the overall score differs significantly from the most recent 30-day score (when platforms show both), note the trend direction ("trending down" or "trending up").

---

## 4. Positioning & Messaging Research

### Query Templates

| Template | Purpose |
|----------|---------|
| `site:{{domain}}` | Homepage — primary tagline and hero value proposition |
| `site:{{domain}} about` | About page — mission, founding story, team focus |
| `{{company_name}} "for" target audience` | Surfaces how the company self-identifies its customer |
| `{{company_name}} "the only" OR "the best" OR "#1"` | Captures strong positioning claims and superlatives |
| `{{company_name}} marketing OR positioning OR "value proposition"` | Surfaces analyst and media framing of the company |
| `{{company_name}} "built for" OR "designed for" OR "made for"` | Explicit audience targeting language |

### Site-Specific Variants

```
site:{{domain}} customers OR case-studies OR success-stories
site:linkedin.com/company/{{company_name_slug}} about
```

LinkedIn company pages often contain a condensed positioning statement that reflects current messaging. Customer/case study pages reveal which industries and company sizes the company is targeting.

### What to Extract

**From the homepage:**
- H1 headline verbatim (the primary tagline)
- Subheadline or descriptor below the H1
- Primary CTA button text (e.g., "Start free", "Get a demo", "Try for free")
- Social proof visible above the fold: customer logos, user count, award badges, analyst ratings
- Hero image or video subject (what they show doing in the product demo)

**From the about page:**
- Mission statement if listed
- Founding story headline or positioning statement
- Values or principles listed

**From customer/case study pages:**
- Industries represented in customer logos (enterprise vs. SMB vs. developer)
- Company sizes in case studies (startup, SMB, mid-market, enterprise)
- Use case themes in case study titles

### Analysis Notes

After extraction, assess the messaging angle:

| Angle | Signals |
|-------|---------|
| Efficiency / Speed | "faster", "automate", "save time", "streamline" |
| Collaboration / Team | "together", "aligned", "team", "shared" |
| Simplicity | "simple", "easy", "no code", "just works" |
| Power / Depth | "powerful", "flexible", "enterprise-grade", "customizable" |
| Price / Value | "free", "affordable", "no credit card", "save money" |
| Niche Authority | "built for [role]", "the [role] tool", "[industry]-specific" |

Record the dominant angle (usually reflected in the H1) and secondary angle (usually the subheadline).

---

## 5. Recent News Research

### Query Templates

| Template | Purpose |
|----------|---------|
| `{{company_name}} funding {{year}}` | Funding rounds, investors, valuations |
| `{{company_name}} "Series A" OR "Series B" OR "seed round" OR IPO` | Specific funding stage language |
| `{{company_name}} launch OR "launches" OR "released" {{year}}` | Product launches and feature announcements |
| `{{company_name}} acquisition OR acquires OR acquired` | M&A activity — buying or being bought |
| `{{company_name}} layoffs OR "headcount" OR restructuring {{year}}` | Negative signals: workforce changes |
| `{{company_name}} partnership OR "integrates with" OR "joins forces"` | Strategic alliances and distribution deals |
| `{{company_name}} CEO OR CTO OR "leadership" OR "hired" {{year}}` | Leadership changes |

### Site-Specific Variants

```
site:techcrunch.com {{company_name}}
site:venturebeat.com {{company_name}}
site:crunchbase.com/organization/{{company_name_slug}}
site:linkedin.com/company/{{company_name_slug}} posts
```

Crunchbase is the authoritative source for funding history. TechCrunch and VentureBeat cover product launches and funding. LinkedIn company posts often contain announcements before press coverage.

### What to Extract

For each news item found, record:
- **Date**: YYYY-MM-DD format
- **Event type**: funding | product_launch | acquisition | partnership | leadership_change | negative_event | regulatory
- **Headline**: Paraphrase in one sentence if the original headline is misleading or SEO-optimized
- **Source**: Publication name and URL
- **Significance**: One-line analysis of what this means competitively (e.g., "Entering enterprise market", "Pricing pressure incoming", "Talent flight risk")

### Recency Rules

- Apply a strict 90-day cutoff for the "Recent Developments" section of any report.
- Include older items only in a "Background Context" note if they are foundational (e.g., a large funding round that explains the company's current aggressive pricing or R&D investment).
- If no news exists in the last 90 days, note "No significant announcements in the last 90 days" — this itself is a signal (stalled momentum or intentionally quiet period).

### Significance Classification

Classify each news item's competitive significance:

| Category | Examples | Implication |
|----------|---------|-------------|
| High threat | Large funding, major acquisition, enterprise push | Increased competitive pressure likely |
| Opportunity | Layoffs, product pivot, leadership turmoil | Potential to capture displaced customers |
| Neutral | Minor feature launch, routine partnership | Monitor but no immediate action needed |
| Positive signal for market | Category funding trend, analyst report | Validates market; rising tide for all players |

---

## 6. Matrix Queries (Multi-Competitor)

Use these patterns when running `/compete:matrix` across two or more companies.

### Head-to-Head Comparison Queries

```
{{company_a}} vs {{company_b}} {{year}}
{{company_a}} vs {{company_b}} comparison features pricing
{{company_a}} vs {{company_b}} site:g2.com
{{company_a}} vs {{company_b}} reddit
"{{company_a}}" OR "{{company_b}}" {{category}} review {{year}}
```

G2's comparison pages (g2.com/compare/{{slug-a}}-vs-{{slug-b}}) aggregate side-by-side scoring — search for these directly when available.

### Category Overview Queries

When the user has not specified all competitors, use these to discover the competitive landscape:

```
best {{category}} tools {{year}}
top {{category}} software {{year}} comparison
{{category}} alternatives to {{company_name}}
{{company_name}} competitors {{year}}
{{category}} market leaders {{year}}
```

Category overview queries surface roundup articles that may identify competitors the user has not considered. Extract company names from the top 3-5 results and present them as suggested additions to the matrix.

### Shared Signal Queries

For the market-level section of a matrix report:

```
{{category}} market trends {{year}}
{{category}} industry report {{year}}
{{category}} pricing trends {{year}}
VC investment {{category}} {{year}}
```

These queries provide the market context section of a matrix report, independent of individual companies.

### Matrix Assembly Rules

When building a matrix from per-company data objects:

1. Run dimensions 1-5 for each company individually before assembly.
2. Normalize all pricing to the same billing unit (per user/month, monthly equivalent) for comparison.
3. Normalize all review scores to /5.0.
4. Use a consistent feature list (union of all features found) as the matrix rows — mark each company's support as: Yes / No / Partial / Unknown.
5. Flag any cell where data confidence is low (e.g., pricing unverified, feature claim from Tier 3 source).
6. Sort competitors in the matrix by overall review score descending by default; allow re-sorting by price or feature count on request.

### Suggested Matrix Dimensions

| Dimension | Sub-fields to compare |
|-----------|----------------------|
| Pricing | Lowest paid tier, per-seat model, free tier, enterprise pricing |
| Reviews | Composite score, review count, top complaint |
| Features | Core count, differentiating features, notable gaps |
| Positioning | Target audience, messaging angle, proof elements |
| Momentum | Recent funding, recent launches, headcount trend |
