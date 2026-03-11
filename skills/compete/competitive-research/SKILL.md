---
name: Competitive Research
description: "Researches individual competitors via web search to gather pricing, features, positioning, and reviews. Activates when the user wants to research a competitor, gather intel on a company, or asks 'what does [company] offer?' Covers multi-source intelligence gathering across official sites, review platforms, and community discussions."
version: 1.0.0
---

# Competitive Research

Gather competitive intelligence on companies via systematic web search. This skill provides a surface-scan research strategy that retrieves current pricing, features, positioning, customer reviews, and recent news for any competitor in 4-6 targeted searches.

## Research Approach

### Surface Scan Strategy

Execute 4-6 targeted searches per competitor to gather intelligence across five dimensions. This surface scan approach balances comprehensiveness with speed — enough queries to capture the key facts without exhaustive crawling.

**Research dimensions (in order):**
1. **Pricing** — current plans, price points, billing models
2. **Features** — core capabilities, differentiating features, platform strengths
3. **Customer Reviews** — G2, Capterra, ProductHunt scores and sentiment themes
4. **Positioning & Messaging** — tagline, value prop, target audience, marketing angle
5. **Recent News** — product launches, funding, leadership changes, market moves

### Selecting Research Targets

For company name input (e.g., "Notion"), construct the domain from the company name or find it in results. For URL input (e.g., "https://notion.so"), extract the company name and domain from the URL.

When the user provides multiple competitors (e.g., `/founder-os:compete:matrix Notion Linear Asana`), apply this skill independently to each company and merge outputs into a comparison structure. Process companies sequentially — complete all 5 dimensions for one company before starting the next to avoid cross-contamination of findings.

## Query Formulation

### Site-Specific Query Strategy

Use `site:` operators to target high-quality sources directly rather than relying on general search to surface them:

- **Reviews**: `site:g2.com {{company_name}}`, `site:capterra.com {{company_name}}`
- **Pricing**: `{{company_name}} pricing 2026`, `site:{{domain}} pricing`
- **Positioning**: `site:{{domain}}` (homepage), `site:{{domain}} about`
- **News**: `{{company_name}} funding OR launch OR "product update" 2026`

### Query Construction Rules

1. Include the current year in pricing and news queries — pricing changes frequently and dated results are misleading.
2. Use OR operators for news to capture multiple event types in one query.
3. For review queries, target both G2 and Capterra — they have different user bases and score differently.
4. Omit `site:` when casting a wider net (e.g., features often spread across documentation, blog posts, and landing pages).
5. Wrap exact phrases in double quotes to force phrase matching (e.g., `"product update"`, `"contact sales"`).
6. Append competitor context when disambiguating common names (e.g., `"Mercury" bank startup` not just `Mercury`).

Consult `${CLAUDE_PLUGIN_ROOT}/skills/compete/competitive-research/references/query-patterns.md` for full templated queries for each dimension, including site-specific variants and matrix query patterns for multi-competitor research.

## Data Extraction

### Pricing Normalization

Extract pricing data and normalize to a comparable format:

1. **Identify billing model**: Per seat/user, flat-rate, usage-based, or hybrid.
2. **Normalize to monthly cost**: Convert annual pricing to monthly equivalent (divide by 12).
3. **Flag billing frequency**: Note if the monthly price requires annual commitment.
4. **Identify free tier**: Note free plan existence, limitations, and upgrade triggers.
5. **Flag enterprise pricing**: "Contact us" or "Contact Sales" pricing signals an enterprise-tier product; note this and do not attempt to infer a price.
6. **Capture discounts**: Note startup programs, nonprofit rates, or annual discount percentages when listed.

**Normalized format**: `$X/user/month (billed annually)` or `$X/month flat` or `Contact Sales`.

When pricing is ambiguous or contradictory across sources, use the official product website as ground truth and flag discrepancies.

### Feature Categorization

Categorize extracted features into three buckets:

- **Core features**: Standard capabilities the product competes on (present in most alternatives in the category).
- **Differentiating features**: Capabilities that are unique to this competitor or notably stronger than alternatives — include a brief note on why each matters.
- **Missing/weak areas**: Functionality users commonly request in reviews, or capabilities where competitors clearly lead based on review complaint themes.

Source features from: product pages, feature comparison pages, G2 review "pros" sections, ProductHunt listings, and changelog or blog posts. Do not infer features that are not explicitly documented — mark uncertain claims with "(unverified)".

### Review Score Extraction

Extract and record for each platform found:
- Platform name (G2, Capterra, ProductHunt, Trustpilot, AppSumo)
- Numeric score and scale (e.g., 4.5/5.0)
- Total review count
- Top 2-3 praise themes (from "what do users like most?" or "pros" sections)
- Top 2-3 complaint themes (from "what do users dislike?" or "cons" sections)

Normalize all scores to a /5.0 scale for cross-competitor comparison. G2 and Capterra are natively /5.0. ProductHunt uses upvotes — record upvote count separately and do not convert to a score. Compute a composite score by averaging all available /5.0 platform scores, weighted equally.

When review counts are low (<50 reviews on a platform), flag the score as low-confidence.

### Positioning Extraction

From the competitor's homepage and about page, extract:
- **Tagline/headline**: The primary H1 or hero text verbatim.
- **Value proposition**: The subheadline or primary descriptor (one sentence).
- **Target audience**: Who they explicitly address ("for teams", "for developers", "for agencies", "for enterprise").
- **Messaging angle**: The core problem they claim to solve or the transformation they promise.
- **Proof elements**: Social proof signals visible above the fold (customer logos, user count, awards).

Note the tone of the messaging (technical, aspirational, pragmatic, community-driven) — this signals where they position on the market sophistication spectrum.

### Recent News Extraction

Surface and record:
- **Product launches**: New features, major releases, platform expansions.
- **Funding events**: Rounds, amounts, lead investors, implied valuation.
- **Leadership changes**: CEO, CTO, VP Sales appointments or departures.
- **Partnership announcements**: Integrations, strategic alliances, distribution deals.
- **Negative events**: Outages, layoffs, customer backlash, regulatory issues.

Limit to the last 90 days. Record each item with: date, headline (paraphrased if necessary), source, and a one-line significance note (e.g., "Signals move into enterprise segment" or "Reduces pricing moat vs. lower-tier competitors").

## Finding Quality and Deduplication

### Source Credibility Tiers

Evaluate sources by reliability:

1. **Tier 1 (authoritative)**: Official product website, verified G2/Capterra profiles, SEC filings, Crunchbase funding records.
2. **Tier 2 (reliable)**: Major tech publications (TechCrunch, VentureBeat, The Verge), official company blog, verified LinkedIn posts.
3. **Tier 3 (directional)**: Reddit discussions (especially r/SaaS, r/ProductManagement), individual blog posts, Quora answers, Twitter/X threads.
4. **Tier 4 (weak)**: Anonymous comments, reseller sites, AI-generated content farms, posts older than 12 months for pricing/features.

Prefer Tier 1-2 sources for pricing and feature claims. Accept Tier 3 for sentiment and complaint pattern analysis — acknowledge the source tier when citing. Discard Tier 4 sources unless no other source is available, in which case flag explicitly.

### Deduplication Rules

When the same fact appears across multiple sources:
- **Pricing**: Use the official website as ground truth. Flag if review sites show materially different pricing (>10% variance).
- **Features**: Merge duplicates by feature category, not by source. One feature entry per capability regardless of how many pages mention it.
- **Reviews**: Keep platform-specific scores separate — do not average G2 and Capterra into a single score before recording; compute composite only after recording both.
- **News**: Keep only the original announcement source. Remove republished coverage of the same event. If the original source cannot be determined, keep the earliest-dated version.

### Recency Filtering

Apply recency filters strictly:
- **Pricing**: Must be from the current year. Discard if the page has no date and content appears dated (e.g., references outdated products or pricing tiers that no longer exist). When uncertain, note "(pricing unverified — verify on official site)".
- **Features**: Must be <12 months old for feature availability claims. Flag major features as "available as of [month year]" when a specific date is found.
- **Reviews**: Use the platform's current overall score (aggregated). Note separately if recent reviews (last 90 days) trend materially higher or lower than the overall score.
- **News**: Surface only last 90 days for the Recent Developments section. Older news belongs in a "Background" note only if it is foundational context (e.g., a funding round that shaped the company's current trajectory).

## Output Structure

After completing research for one competitor, structure findings as a data object. This object is consumed by the market-analysis skill or report generation commands:

```
competitor_data:
  company: [name]
  domain: [url]
  research_date: [YYYY-MM-DD]

  pricing:
    model: [per_seat | flat | usage | freemium | enterprise_only | hybrid]
    plans:
      - name: [plan name]
        price_monthly: [number or "Contact Sales"]
        billing: [monthly | annual | annual_only]
        notes: [key limitations or inclusions]
    free_tier: [description or null]
    enterprise_pricing: [true | false]
    annual_discount_pct: [number or null]

  features:
    core:
      - [feature name]
    differentiating:
      - feature: [name]
        why_it_matters: [one-line explanation]
    gaps:
      - [missing or weak area]

  reviews:
    composite_score: [X.X / 5.0]
    platforms:
      - name: [G2 | Capterra | ProductHunt | Trustpilot]
        score: [X.X / 5.0 or upvote count]
        review_count: [number]
        low_confidence: [true | false]
    praise_themes:
      - [theme]
    complaint_themes:
      - [theme]

  positioning:
    tagline: [verbatim H1 text]
    value_prop: [subheadline text]
    target_audience: [description]
    messaging_angle: [core problem or transformation]
    proof_elements: [logos, user counts, awards]
    tone: [technical | aspirational | pragmatic | community-driven]

  news:
    recent_items:
      - date: [YYYY-MM-DD]
        headline: [text]
        source: [publication or URL]
        significance: [one-line note]
```

When running `/founder-os:compete:matrix`, produce one `competitor_data` object per company and pass the full array to the matrix formatter.

## Failure Handling

Apply these fallbacks when data is unavailable:

- **No pricing found**: Set `price_monthly: "Not publicly listed"` and note the last search attempted.
- **No G2/Capterra profile**: Set `composite_score: null` and note "no review platform data found".
- **Company is stealth/pre-launch**: Return what is available (positioning, news) and flag `status: "limited_data"` in the output object.
- **Domain cannot be resolved**: Ask the user to confirm the company name or URL before continuing.
- **Search returns no results**: Try the alternate query variants from the query-patterns reference before declaring no data.

Never fabricate pricing, feature claims, or review scores. When uncertain, use the phrase "unverified" and recommend the user check the source directly.

