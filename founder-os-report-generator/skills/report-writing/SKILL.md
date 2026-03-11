---
name: Report Writing
description: "Transforms analyzed data into polished, structured Markdown reports. Activates when the user wants to write a report, draft sections, create a narrative from data, or asks 'turn this analysis into a report.' Covers report structure, tone calibration, data narration, heading hierarchy, and audience-appropriate length."
globs:
  - "teams/agents/writing-agent.md"
---

## Overview

Transform the structured analysis output from the Analysis Agent (step 2) into a complete, polished Markdown report ready for the Formatting Agent (step 4) to enhance with charts and visual elements. Treat every report as a standalone document a reader can understand without access to the underlying data. Lead every section with its most important finding. Support every claim with specific numbers from the analysis. Maintain a consistent professional tone throughout while adapting formality to the specified audience. Produce the full Markdown document in a single pass -- never leave placeholder sections or TODO markers. When the analysis output is missing data for a planned section, either omit the section or include a brief note explaining the data gap. Never fabricate data or invent statistics to fill gaps.

## Report Structure Templates

Organize every report into the following sections in this exact order. Omit a section only when the analysis output provides insufficient data, and note the omission in the report metadata.

### Executive Summary

Place first, always. Limit to 1-2 paragraphs (200-400 words). Write it last to ensure it reflects the full report. Structure in three beats: (1) one sentence of context stating purpose and scope, (2) two to four sentences covering the most significant findings, (3) one to two sentences identifying the highest-priority recommended actions. Never introduce information absent from the body.

### Introduction / Background

Establish context in 150-300 words covering three elements: **Context** (why this report exists -- business question, milestone, or reporting cadence), **Objectives** (specific questions the report answers, framed as hypotheses when possible), and **Scope** (time period, data sources, entities covered, and explicit exclusions). Avoid previewing findings.

### Methodology

Describe data collection and analysis in 200-400 words. Include data sources by name (CSV files, Notion databases, Drive documents), a concise summary of each analytical technique the Analysis Agent applied, the exact date range, and known limitations or data quality caveats placed at the end of the section.

### Findings

Present results organized by theme or business question -- never by data source. Open each subsection with the most important result as a topic sentence. Group related metrics under shared headings ("Revenue Performance" not separate sections per metric). Present quantitative findings before qualitative observations. Use tables for dense comparisons and inline bold for critical numbers. Order subsections by business impact. Limit the body to the top 8-12 results; relegate secondary findings to Appendices.

### Discussion

Interpret findings by answering three questions: **What do they mean?** (business implications tied to strategic goals), **How do they compare?** (vs. previous period, target, industry benchmark -- always state the baseline explicitly), and **What caused them?** (evidence-based explanations, distinguishing confirmed causes from hypotheses using "likely driven by" or "correlates with" for unconfirmed links). Keep discussion at 60-80% of Findings length. Reference numbers briefly rather than repeating them.

### Recommendations

Structure each recommendation with four components: **Action** (clear imperative), **Rationale** (one sentence linking to a finding), **Priority** (High / Medium / Low), and **Expected Impact** (quantified when data supports it). Order by priority. Limit to 3-7 in the body; overflow to Appendices. Never recommend actions lacking supporting evidence.

### Appendices

Include raw data tables, a glossary of terms and acronyms, extended methodology details, secondary findings, and a complete data source inventory. Label each appendix with a letter (Appendix A, B, etc.) and reference from the main body.

## Section Writing Rules

- **Lead with importance**: State the key message in the first sentence of every section and subsection. A reader scanning only opening sentences should grasp the report's conclusions.
- **Topic sentences**: State the takeaway, not the topic. Write "Revenue exceeded target by 18%" not "This section covers revenue data."
- **Evidence-backed claims**: Support every assertion with a specific number, percentage, or date from the analysis. Replace "Customer satisfaction improved significantly" with "Customer satisfaction scores rose from 72 to 84 (a 16.7% increase)."
- **Section transitions**: Bridge sections with transitional language connecting what precedes to what follows, either as a section's closing sentence or the next section's opener.
- **Paragraph length**: Keep to 3-5 sentences. Single-sentence paragraphs acceptable for emphasis, limited to one per section.

## Tone and Voice

- **Professional but accessible**: Avoid jargon unless the audience is technical. Define technical terms on first use. Prefer plain language ("grew" over "exhibited positive growth trajectory").
- **Confident and direct**: Avoid hedging ("seems to," "might," "perhaps") unless uncertainty is genuine. When uncertainty exists, quantify it: "Results suggest 15-20% improvement, though the small sample (n=23) limits confidence."
- **Data-driven**: Anchor every section to the analysis output as the single source of truth. Flag external context explicitly: "Industry benchmarks suggest..."
- **Active voice**: Write "Revenue grew 23%" not "A 23% growth was observed." Passive voice acceptable in Methodology where the focus is process.
- **Tense**: Present tense for current findings ("Revenue stands at $4.2M"), past tense for methodology ("The Analysis Agent calculated growth rates"), future tense only in Recommendations.

## Data Narration

### Convert Numbers into Statements

Never present raw numbers without narrative context. Transform every data point into a statement that tells the reader what the number means for the business.

- Weak: "Q4 revenue: $4.2M."
- Strong: "Revenue grew 23% quarter-over-quarter, reaching $4.2M and surpassing the $3.8M target by 10.5%."

### Provide Context Always

Pair every metric with at least one comparison point. Acceptable comparison baselines include:

- **vs. previous period**: "up 12% from Q3" or "down 5 points month-over-month"
- **vs. target**: "exceeded the $5M annual target by 8%" or "fell 3% short of the projected 40% margin"
- **vs. benchmark**: "above the industry median of 2.1%" or "in line with comparable SaaS companies"
- **vs. historical norm**: "the highest since Q2 2023" or "breaking a three-quarter decline"

When multiple comparisons are available, lead with the most relevant one for the audience and include others in supporting sentences.

### Use Relative Comparisons

Supplement absolutes with relative framing: "2x the previous quarter," "nearly half the industry average," "the largest single-quarter increase in two years." Especially valuable when readers lack baseline familiarity with the metric.

### Highlight and Explain Anomalies

Flag data points deviating significantly from the trend. State the anomaly, quantify the deviation, and provide an explanation or explicitly note its absence: "February saw a 40% spike in support tickets (1,240 vs. the 6-month average of 885); the cause warrants further investigation."

## Heading Hierarchy

- **H1 (`#`)**: Report title only. One per document.
- **H2 (`##`)**: Major sections (Executive Summary, Introduction, Methodology, Findings, Discussion, Recommendations, Appendices).
- **H3 (`###`)**: Subsections within major sections.
- **H4 (`####`)**: Use rarely; prefer restructuring or bold lead-ins over deep nesting.

Never skip heading levels. Keep heading text under 8 words. Use noun phrases or findings as headings, not questions or vague labels.

## Length Guidelines

- **Executive Summary**: 200-400 words regardless of total length.
- **Introduction**: 150-300 words.
- **Methodology**: 200-400 words.
- **Findings**: 500-1,500 words (lower for 2-3 themes, upper for 6+).
- **Discussion**: 400-1,000 words (60-80% of Findings length).
- **Recommendations**: 300-700 words (50-100 words per recommendation).
- **Appendices**: Variable; include only what the body references.

Total range: 1,800 words (single-theme) to 4,500 words (complex multi-theme). When exceeding 4,500 words, split into primary and supplementary reports and flag the decision in metadata for the QA Agent.

## Output Format

Produce a complete Markdown document using standard syntax: `#` headings, pipe tables with header separators, `**bold**` for critical numbers, bullet lists for enumerations, numbered lists for prioritized items. Do not include Mermaid charts, styled HTML, or complex formatting -- the Formatting Agent handles that. Leave chart placement markers using `<!-- CHART: [description, data series, chart type] -->`.

Include a metadata block at the end of the document:

```
Report Metadata:
  Generated: [timestamp]
  Data Sources: [count and names]
  Analysis Themes: [count]
  Total Findings: [count]
  Recommendations: [count]
  Word Count: [approximate]
  Sections Omitted: [list any omitted sections and reason]
```

## Edge Cases

### Insufficient Data for a Section

- **Missing entirely**: Omit the section. Record in metadata as "Sections Omitted" with reason "Insufficient data from analysis."
- **Partially available**: Include the section with available data and note gaps explicitly: "Data for customer acquisition cost was not available. Include in future reporting cycles."
- **Low confidence data**: Include with inline qualification: "Note: This figure is based on estimated values due to incomplete source data."

### Contradictory Findings

When the analysis output contains findings that contradict each other (e.g., revenue up but profit down, or two data sources reporting different values for the same metric):

- Present both findings explicitly. Never suppress one in favor of the other.
- State the contradiction clearly: "Revenue grew 15% year-over-year, yet operating profit declined by 8%, indicating significant margin compression."
- Offer an evidence-based explanation when the data supports one: "The margin gap is attributable to the 40% increase in customer acquisition costs."
- When no explanation is available, flag it: "The cause of this divergence is not evident in the available data and warrants further investigation."
- Never silently average or reconcile contradictory numbers. The reader must see the discrepancy.

### Audience Mismatch

- **Technical data, non-technical audience**: Translate metrics into outcomes ("99% of requests complete in under a quarter of a second" not "p99 = 230ms").
- **High-level data, technical audience**: Add methodology details, confidence intervals, and raw numbers alongside summaries.
- **Mixed audience**: Write the body for the primary audience; add an appendix for the secondary audience ("Technical Details" or "Executive Overview").
- **No audience specified**: Default to business-executive: professional, non-technical, outcome-focused.

### Single-Theme Reports

Collapse Findings and Discussion into "Findings and Analysis." Maintain all other sections. Target 1,800-2,500 words total.

### Extremely Large Datasets

When analysis produces more than 15 findings, include the top 8-10 in the body ordered by impact. Move the rest to an "Additional Findings" appendix. Note the prioritization in the Executive Summary.
