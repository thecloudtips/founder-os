---
name: Executive Summary
description: "Produces concise, decision-ready executive summaries from report data. Activates when the user wants a TLDR, management summary, key takeaways, or top-level overview — including 'give me the highlights' or 'what are the main findings?' Covers metric highlighting, recommendation prioritization, and risk/opportunity framing."
globs:
  - "teams/agents/writing-agent.md"
  - "teams/agents/qa-agent.md"
---

## Overview

Produce a concise, self-contained executive summary for every generated report. Target the summary at busy decision-makers who may read only this section and never open the full report body. Distill the entire report into a maximum of 400 words that answer three questions: what was analyzed, what was found, and what to do about it. Every claim must be backed by a specific number or metric drawn from the report body. Never include a finding in the summary that does not appear in the full report.

## Structure Template

Follow this five-part structure for every executive summary. Maintain the order strictly -- readers expect a predictable flow from context through action.

### 1. Situation Statement (1-2 sentences)

Open with what was analyzed and why. State the report's scope, time period, and triggering event. Avoid vague openers like "This report covers various metrics." Always name the specific subject, time window, and motivation.

Example: "This report analyzes Q3 2025 sales performance across all four regional teams, triggered by the 15% revenue shortfall flagged in the September flash report."

### 2. Key Findings (3-5 bullet points)

Present the most important discoveries ranked by business impact, placing the single most important finding first. Each bullet must contain at least one specific number or metric. Use parallel grammatical structure across all bullets.

Format each bullet as: **[Topic]**: [Finding with metric] ([comparison context])

Example:
- **Revenue**: Total revenue declined **12%** to **$3.6M** (vs. $4.1M target)
- **Customer Acquisition**: New customer count grew **8%** to **247** (vs. 229 last quarter)
- **Churn**: Monthly churn rate increased from **2.1%** to **3.4%** (highest since Q1 2024)

Limit to 5 bullets maximum. When the report contains more findings, select the 5 with the greatest business impact.

### 3. Critical Insights (1-2 sentences)

Answer the "so what?" question. Explain what the findings mean in aggregate -- the narrative connecting data points into a coherent story. State the implication plainly without hedging. Avoid restating findings; synthesize across them to surface the underlying pattern or root cause.

Example: "The combination of rising churn and strong acquisition suggests the product attracts new users but fails to retain them past the 90-day mark, pointing to an onboarding gap."

### 4. Recommendations (3-5 prioritized actions)

Provide concrete, prioritized actions flowing logically from findings and insights. Each recommendation must include: what to do, expected impact, and suggested timeline. Use the prioritization framework defined below.

Format: **[Priority level] - [Action]**: [Expected impact]. Timeline: [Suggested timeframe].

Example:
- **P1 - Launch 90-day onboarding health check**: Expected to reduce churn by 0.8-1.2 percentage points. Timeline: 4 weeks.
- **P2 - Expand West region sales team by 2 reps**: Close rate lags other regions by 12 points despite 45% pipeline growth. Timeline: 8 weeks.

### 5. Next Steps (optional)

Include only when immediate actions are required before the next reporting cycle. List 1-3 time-sensitive items with owners and deadlines. Omit entirely if all actions are captured in Recommendations.

## Writing Rules

### Word Limit

Enforce a hard cap of 400 words for the entire executive summary. When the draft exceeds 400 words, cut Key Findings first (reduce to 3 bullets), then trim Recommendations (reduce to 3), then tighten the Situation Statement. Never cut Critical Insights.

### Lead with Impact

Place the single most important finding first under Key Findings. Select the one with the largest financial impact or the one most likely to change a decision.

### Quantitative Rigor

Every Key Findings bullet must contain a specific number, percentage, dollar amount, or measurable metric. Never write qualitative-only bullets like "Sales performance was mixed." Rewrite as "Sales declined **7%** to **$2.8M**."

### Information Flow

Follow "Situation, Finding, Implication, Recommendation" (SFIR) flow throughout. Each section builds on the previous one. Findings connect to Situation, Insights reference Findings, Recommendations address Insights.

### Language Standards

- Use active voice exclusively. Replace "Revenue was impacted by declining renewals" with "Declining renewals reduced revenue by **$400K**."
- Avoid technical jargon. Write for a non-technical audience. When a technical term is unavoidable, define it inline in parentheses.
- Write in present tense for findings, imperative mood for recommendations.
- Eliminate hedge words: remove "somewhat", "relatively", "fairly", "arguably", and "it appears that."

## Metric Highlighting

### Bold Formatting

Wrap key numbers in bold: "Revenue grew **23%** to **$4.2M**." Bold both percentage change and absolute value when both appear.

### Direction Indicators

Always show direction of change with explicit language -- "up", "down", "grew", "declined" -- rather than relying on signs alone.

### Comparison Context

Never present a metric in isolation. Always provide at least one comparison:
- **Period-over-period**: "vs. $3.4M last quarter"
- **Target-based**: "vs. $4.5M target"
- **Benchmark-based**: "above the industry average of 2.1%"

Lead with the most relevant comparison; include a secondary in parentheses when available.

### Rounding Conventions

- **Percentages**: Round to whole numbers above 10%; one decimal place below 10% (e.g., "3.4%").
- **Currency**: Use K/M/B suffixes. Write "$4.2M" not "$4,200,000." Full numbers only below $1,000.
- **Counts**: Commas for thousands ("1,247 customers"). K suffix above 10,000 ("15K users").

## Recommendation Prioritization

### Priority 1: Quick Wins (High Impact, Low Effort)

Place first. Leverages existing tools, requires no additional headcount, delivers results within one reporting cycle. Label "P1." Timeline: 1-4 weeks. Include expected impact estimate.

### Priority 2: Strategic Initiatives (High Impact, High Effort)

Place second. Requires cross-team collaboration, may need budget approval, involves process or system changes. Label "P2." Timeline: 4-12 weeks.

### Priority 3: Optimizations (Low Impact, Low Effort)

Place third. Incremental improvements worth capturing but not urgent. Batch together when possible. Label "P3."

### Drop Zone: Low Impact, High Effort

Do not include as formal recommendations. Mention only when the report data specifically highlights them. State explicitly: "Not recommended at this time due to unfavorable effort-to-impact ratio."

## Risk and Opportunity Framing

### Risk Framing

Present negative findings as risks paired with mitigation strategies. Structure as: "[Finding] creates a risk of [consequence]. Mitigate by [action]."

Example: "The **3.4%** churn rate creates a risk of **$1.2M** annual revenue loss. Mitigate by launching retention campaigns for 60-90 day accounts."

### Opportunity Framing

Present positive findings as opportunities paired with capture strategies. Structure as: "[Finding] creates an opportunity to [outcome]. Capture by [action]."

### Traffic Light System

Apply traffic light status to each major finding for at-a-glance assessment:

- **Red (Requires Immediate Action)**: Deviation exceeds 15% from target, or trend continued for 2+ consecutive periods.
- **Yellow (Monitor Closely)**: Deviation 5-15% from target, or trend appeared in most recent period only.
- **Green (On Track)**: Meets or exceeds target. Include only when notably strong (10%+ above target). Otherwise summarize: "All other KPIs on track."

Apply inline: "Churn: **3.4%** [RED] -- above 2.5% threshold for 2 consecutive months."

## QA Checklist for Executive Summaries

Run every executive summary through this checklist before finalizing. Every item must pass.

### Data Integrity

- Every number in the summary matches the report body. Zero tolerance for mismatches.
- No finding in the summary is absent from the report. The summary is a strict subset of report content.

### Logical Coherence

- Each recommendation traces back to a specific finding or insight.
- SFIR flow is unbroken: Situation sets up Findings, Findings feed Insights, Insights drive Recommendations.

### Readability

- Summary is self-contained -- readable without the full report.
- No jargon without inline definition.
- Active voice throughout; flag and rewrite any passive constructions.

### Format Compliance

- Within 400-word hard cap.
- Bold formatting on all key metrics.
- Each Key Findings bullet contains at least one specific number.
- Each Recommendation includes what, expected impact, and timeline.
- Priority labels (P1/P2/P3) assigned to every recommendation.
- Comparison context accompanies every metric.

## Edge Cases

### Contradictory Findings

When findings point in opposite directions (e.g., revenue growing but margins shrinking), do not paper over the contradiction. Present both explicitly and dedicate Critical Insights to explaining the tension: "Revenue grew **18%** but gross margin declined **4 points**, suggesting growth is being purchased through discounting." Never average contradictory metrics into a single "neutral" assessment.

### Insufficient Data for Strong Recommendations

When data is insufficient for confident recommendations, state so explicitly. Downgrade affected recommendations to P3 with qualifier: "Preliminary recommendation pending additional data." Include a data-gathering action as a P1: "Collect 2 additional months of cohort data before committing to retention program design."

### Purely Qualitative Reports

When the report contains no quantitative data, adapt Key Findings to use evidence-count bullets: "**4 of 6** stakeholders cited onboarding friction as the primary pain point." Quantify qualitative data wherever possible -- convert themes to frequency counts, rank by mention count. Note in the Situation Statement that findings represent themes rather than statistical measurements.

### Single-Metric Reports

When the report focuses on a single KPI, collapse Key Findings into a breakdown of that metric: present 3-5 facets (time periods, segments, cohorts, contributing factors) instead of separate findings. Maintain the full Recommendations structure -- multiple actions always influence a single outcome.
