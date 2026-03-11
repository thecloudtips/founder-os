# Integration Test Plan: Report Generator Factory

## Overview

This test plan covers end-to-end scenarios for the Report Generator Factory plugin (#09), mapping to acceptance criteria from the plugin spec. Tests require a live Filesystem MCP server connection, and optionally Notion MCP and the gws CLI (for Google Drive). The plugin uses a 5-agent pipeline (Research -> Analysis -> Writing -> Formatting -> QA) to transform raw data into polished Markdown reports with Mermaid charts.

## Test Environment

- Claude Code with plugin installed
- Filesystem MCP configured with access to a test data directory
- Notion MCP configured (for report logging tests)
- gws CLI installed and authenticated (optional, for multi-source research tests)
- Test data files prepared:
  - `test.csv` (tabular data with headers and numeric columns)
  - `test.json` (nested JSON with arrays and objects)
  - `notes.txt` (unstructured text with embedded metrics and observations)
  - `metrics.json` (project KPIs: velocity, budget, milestones)
  - `./data/` directory (mixed CSV, JSON, and text files for multi-file ingestion)

---

## Scenario 1: Default Mode with CSV Data

**Description**: Verify that `/report:generate` ingests a CSV file and produces a complete Markdown report containing an executive summary and Mermaid charts derived from numerical columns.

**Prerequisites**:
- Filesystem MCP configured and accessible
- `test.csv` exists in the working directory with at least 3 numeric columns and 20+ rows

**Steps**:
1. Place `test.csv` in the working directory (e.g., sales data with columns: Month, Revenue, Expenses, Profit)
2. Run `/report:generate --data=test.csv`
3. Inspect the generated Markdown output file

**Expected Results**:
- Report is valid Markdown with proper heading hierarchy (H1 title, H2 sections)
- Executive summary section appears within the first 500 words
- At least one Mermaid chart block is present (```mermaid ... ```)
- CSV column headers are referenced in analysis sections
- Numerical trends are identified and described (e.g., "Revenue increased by X%")
- Report file saved to the working directory with a descriptive filename
- No raw CSV rows dumped verbatim into the report

**Pass Criteria**: Report contains an executive summary, at least one Mermaid chart, and data-driven narrative derived from the CSV columns.

---

## Scenario 2: Default Mode with JSON Data

**Description**: Verify that `/report:generate` correctly parses nested JSON structures, traverses arrays and objects, and extracts meaningful data for report generation.

**Prerequisites**:
- Filesystem MCP configured and accessible
- `test.json` exists with nested structure (e.g., `{ "company": { "departments": [ { "name": "...", "metrics": { ... } } ] } }`)

**Steps**:
1. Place `test.json` in the working directory with at least 2 levels of nesting and array data
2. Run `/report:generate --data=test.json`
3. Inspect the generated Markdown output file

**Expected Results**:
- Nested objects are flattened into readable sections (not rendered as raw JSON)
- Array data is presented in tables or lists as appropriate
- Nested numeric values are extracted for chart generation
- Key-value pairs at all nesting levels are accessible to the analysis
- No JSON syntax artifacts (braces, brackets, quotes) in prose sections
- Report structure reflects the logical hierarchy of the JSON data

**Pass Criteria**: Nested JSON is fully traversed; report sections map to JSON structure without raw syntax leaking into prose.

---

## Scenario 3: Default Mode with Text Files

**Description**: Verify that `/report:generate` can extract structured insights from unstructured plain text, identifying metrics, dates, and key findings embedded in narrative form.

**Prerequisites**:
- Filesystem MCP configured and accessible
- `notes.txt` exists with unstructured content containing embedded numbers, dates, and qualitative observations

**Steps**:
1. Place `notes.txt` in the working directory (e.g., meeting notes with scattered metrics: "Q3 revenue hit $2.1M, up 15% from Q2", "Team headcount: 24", "Launch date pushed to March 15")
2. Run `/report:generate --data=notes.txt`
3. Inspect the generated Markdown output file

**Expected Results**:
- Numeric values are extracted and referenced in the report (e.g., "$2.1M", "15%", "24")
- Dates are identified and used for timeline context
- Qualitative observations are synthesized into findings (not just quoted verbatim)
- Data extraction skill identifies at least 80% of embedded metrics
- Report distinguishes between facts and opinions found in the text
- Executive summary captures the key takeaways from unstructured input

**Pass Criteria**: Structured data is successfully extracted from unstructured text; report contains quantitative references and qualitative synthesis.

---

## Scenario 4: Team Mode Full Pipeline

**Description**: Verify that `/report:generate --team` executes all 5 pipeline agents in the correct order (Research -> Analysis -> Writing -> Formatting -> QA), with each agent's output feeding into the next.

**Prerequisites**:
- Filesystem MCP configured and accessible
- `test.csv` exists in the working directory
- Notion MCP configured (optional, for QA logging)

**Steps**:
1. Run `/report:generate --team --data=test.csv`
2. Observe agent execution order in output
3. Inspect the final Markdown report

**Expected Results**:
- **Research Agent** runs first: reads `test.csv`, extracts raw data, identifies data types and structure
- **Analysis Agent** runs second: receives research output, performs statistical analysis, identifies trends and outliers
- **Writing Agent** runs third: receives analysis output, produces narrative prose with sections and findings
- **Formatting Agent** runs fourth: receives writing output, applies Markdown formatting, generates Mermaid chart blocks
- **QA Agent** runs fifth: receives formatted report, validates structure, checks for completeness, flags issues
- Each agent's handoff is visible in the pipeline output
- Final report reflects contributions from all 5 stages
- Pipeline completes without errors or agent timeouts

**Pass Criteria**: All 5 agents execute in sequence; final report demonstrates research, analysis, narrative, formatting, and QA validation.

---

## Scenario 5: Template - Executive Summary

**Description**: Verify that the `executive-summary` template produces a concise 1-2 page report focused on key findings, recommendations, and high-level metrics.

**Prerequisites**:
- Filesystem MCP configured and accessible
- `test.csv` exists with business metrics data
- Template `executive-summary` is available in `templates/report-templates/`

**Steps**:
1. Run `/report:from-template --template=executive-summary --data=test.csv`
2. Measure the output length
3. Verify structural compliance with the executive summary template

**Expected Results**:
- Report length is between 400-1200 words (approximately 1-2 pages)
- Contains required sections: Key Findings, Recommendations, Metrics Overview
- No deep-dive analysis sections (those belong in full reports)
- Bullet points used for findings and recommendations
- At most 1 Mermaid chart (summary-level, not detailed)
- Language is executive-appropriate: concise, action-oriented, jargon-free
- Report title includes "Executive Summary" designation

**Pass Criteria**: Report is 1-2 pages, contains Key Findings and Recommendations, and uses concise executive language.

---

## Scenario 6: Template - Full Business Report

**Description**: Verify that the `full-business-report` template in team mode produces a comprehensive multi-section report from a directory of mixed data sources.

**Prerequisites**:
- Filesystem MCP configured and accessible
- `./data/` directory exists containing at least: 1 CSV file, 1 JSON file, 1 text file
- Template `full-business-report` is available in `templates/report-templates/`

**Steps**:
1. Populate `./data/` with mixed source files (financials.csv, team-metrics.json, strategy-notes.txt)
2. Run `/report:from-template --template=full-business-report --team --data=./data/`
3. Verify all source files are ingested
4. Inspect the multi-section report structure

**Expected Results**:
- Research Agent discovers and reads all files in the `./data/` directory
- Report contains distinct sections derived from each data source
- Table of Contents or section index is present
- Multiple Mermaid charts generated (at least 2, covering different data sets)
- Cross-referencing between data sources (e.g., correlating financial data with team metrics)
- Report length exceeds 2000 words
- Full business report structure: Executive Summary, Methodology, Findings, Analysis, Recommendations, Appendix
- Source attribution: each section references which data file(s) informed it

**Pass Criteria**: All files in `./data/` are ingested; report has 6+ sections, multiple charts, and cross-references between data sources.

---

## Scenario 7: Template - Project Status Report

**Description**: Verify that the `project-status-report` template produces a status report from project metrics JSON, with progress tracking, risk flags, and milestone status.

**Prerequisites**:
- Filesystem MCP configured and accessible
- `metrics.json` exists with project KPIs (e.g., `{ "velocity": 42, "budget_used": 0.73, "milestones": [ { "name": "Alpha", "status": "complete" }, { "name": "Beta", "status": "at_risk" } ] }`)
- Template `project-status-report` is available in `templates/report-templates/`

**Steps**:
1. Place `metrics.json` in the working directory with velocity, budget, milestone, and risk data
2. Run `/report:from-template --template=project-status-report --data=metrics.json`
3. Inspect the generated status report

**Expected Results**:
- Report contains standard status sections: Overall Status, Progress, Milestones, Risks, Next Steps
- Milestones rendered with status indicators (complete, in-progress, at-risk, blocked)
- Budget utilization presented as percentage with visual indicator (Mermaid pie or bar chart)
- Velocity/throughput metrics charted over time if historical data is present
- At-risk items highlighted with recommended mitigations
- RAG (Red/Amber/Green) status or equivalent health indicator for overall project
- Report is action-oriented with clear next steps

**Pass Criteria**: Status report contains milestone tracking, budget visualization, risk flags, and actionable next steps.

---

## Scenario 8: Graceful Degradation without Notion

**Description**: Verify the pipeline completes successfully when Notion MCP is unavailable, skipping database logging without errors.

**Prerequisites**:
- Filesystem MCP configured and accessible
- Notion MCP disabled (unset `NOTION_API_KEY` or remove Notion from `mcp.json`)
- `test.csv` exists in the working directory

**Steps**:
1. Disable Notion MCP
2. Run `/report:generate --team --data=test.csv`
3. Verify pipeline completion and output

**Expected Results**:
- Warning message about Notion not being configured (not an error)
- Research, Analysis, Writing, and Formatting agents run normally (no Notion dependency)
- QA Agent completes validation but skips Notion DB logging
- QA Agent reports that report metadata was not persisted to Notion
- Final Markdown report is generated and saved to the filesystem
- Report quality is identical to Notion-enabled runs
- No Notion database creation or logging attempted
- Pipeline completes with partial results summary, no crash or stack trace
- Subsequent runs with Notion re-enabled resume normal logging

**Pass Criteria**: Full pipeline completes; Markdown report is generated; Notion skip is logged as a warning, not an error.

---

## Scenario 9: Graceful Degradation without Google Drive

**Description**: Verify the Research Agent skips Google Drive as a data source when the gws CLI is unavailable or not authenticated, falling back to local filesystem sources only.

**Prerequisites**:
- Filesystem MCP configured and accessible
- gws CLI not installed or not authenticated
- `test.csv` exists in the working directory

**Steps**:
1. Ensure gws CLI is unavailable (uninstall or remove from PATH)
2. Run `/report:generate --team --data=test.csv`
3. Check Research Agent output for source status

**Expected Results**:
- Warning message about gws CLI not being available
- Research Agent marks Drive source status as "unavailable"
- Research Agent continues with local filesystem sources
- No attempt to access Google Drive (no authentication errors)
- Pipeline proceeds through all 5 agents without interruption
- Final report is generated from local data only
- Report metadata (if Notion is available) records sources used as "filesystem" only
- Report quality reflects available data without placeholder sections for missing Drive data

**Pass Criteria**: Pipeline completes with local files only; Drive unavailability is handled gracefully with a warning.

---

## Scenario 10: QA Agent Recommend-Only

**Description**: Verify the QA Agent operates in recommend-only mode -- it flags issues and suggests improvements but does NOT modify the report file generated by the Formatting Agent.

**Prerequisites**:
- Filesystem MCP configured and accessible
- `test.csv` exists with data that will produce a report with minor issues (e.g., sparse data for some columns)

**Steps**:
1. Run `/report:generate --team --data=test.csv`
2. Record the MD5/checksum of the report file after the Formatting Agent completes
3. Verify the QA Agent's output includes recommendations
4. Compare the final report file checksum to the pre-QA checksum

**Expected Results**:
- QA Agent produces a validation report with:
  - Completeness check (all expected sections present)
  - Chart validity check (Mermaid syntax is parseable)
  - Data accuracy spot-checks (numbers in prose match source data)
  - Readability assessment (section flow, heading hierarchy)
- QA Agent flags any issues as recommendations with severity levels (info, warning, error)
- The Markdown report file is NOT modified by the QA Agent
- Report file content after QA is byte-identical to content before QA
- QA recommendations are included in the pipeline output summary, not injected into the report
- If QA finds critical issues, they are flagged for human review (not auto-corrected)

**Pass Criteria**: QA Agent produces recommendations; report file remains unmodified; no automated corrections applied.

---

## Scenario 11: Mermaid Chart Generation

**Description**: Verify that numerical data in the source files produces valid Mermaid chart syntax that renders correctly in standard Mermaid-compatible viewers.

**Prerequisites**:
- Filesystem MCP configured and accessible
- `test.csv` exists with at least 2 numeric columns and 10+ rows of time-series or categorical data

**Steps**:
1. Run `/report:generate --data=test.csv`
2. Extract all Mermaid code blocks from the generated report
3. Validate each Mermaid block against Mermaid syntax rules
4. Verify chart type appropriateness for the data

**Expected Results**:
- At least one Mermaid chart block is present in the report
- Each Mermaid block starts with a valid chart type declaration (e.g., `pie`, `xychart-beta`, `graph`, `flowchart`)
- Chart data values correspond to actual values from the source data (not fabricated)
- Mermaid syntax is valid -- no unclosed brackets, missing semicolons, or malformed directives
- Chart type is appropriate for the data:
  - Time-series data produces line or bar charts
  - Categorical proportions produce pie charts
  - Process/workflow data produces flowcharts
- Chart titles and labels are descriptive (not generic like "Chart 1")
- Charts are embedded inline within relevant report sections (not all grouped at the end)

**Pass Criteria**: All Mermaid blocks use valid syntax, chart types match data characteristics, and values trace back to source data.

---

## Scenario 12: Notion DB Discovery with Fallback

**Description**: Verify that the QA Agent discovers the consolidated "Founder OS HQ - Reports" database first, falls back to the legacy "Report Generator - Reports" name, and skips Notion logging if neither exists. Verify that records are created with Type="Business Report".

**Prerequisites**:
- Filesystem MCP configured and accessible
- Notion MCP configured with a valid API key and workspace access
- `test.csv` exists in the working directory

**Steps**:
1. Ensure "Founder OS HQ - Reports" database exists in Notion
2. Run `/report:generate --team --data=test.csv`
3. Verify record is created with Type="Business Report"
4. Remove "Founder OS HQ - Reports", create legacy "Report Generator - Reports" database
5. Run `/report:generate --team --data=test.csv`
6. Verify fallback to legacy database
7. Remove both databases
8. Run `/report:generate --team --data=test.csv`
9. Verify Notion logging is skipped (no database created)

**Expected Results**:
- Run with consolidated DB: record created in "Founder OS HQ - Reports" with Type="Business Report"
- Run with legacy DB only: record created in "Report Generator - Reports" with Type="Business Report"
- Run with neither DB: pipeline completes, Notion logging skipped, no database auto-created
- Report file is generated in all cases regardless of Notion availability
- Second run to same DB: existing database reused, no duplicate creation

**Pass Criteria**: Consolidated DB preferred; legacy DB used as fallback; no lazy creation; Type="Business Report" set on all records.

---

## Summary Matrix

| Scenario | Command | MCP Required | Key Validation |
|----------|---------|--------------|----------------|
| 1. CSV Data | `/report:generate` | Filesystem | Markdown output, exec summary, charts |
| 2. JSON Data | `/report:generate` | Filesystem | Nested JSON traversal, no syntax leakage |
| 3. Text Files | `/report:generate` | Filesystem | Structured extraction from unstructured text |
| 4. Team Pipeline | `/report:generate --team` | Filesystem | 5 agents in order, handoff integrity |
| 5. Executive Summary | `/report:from-template` | Filesystem | 1-2 pages, concise, action-oriented |
| 6. Full Business Report | `/report:from-template --team` | Filesystem | Multi-source, 6+ sections, cross-references |
| 7. Project Status | `/report:from-template` | Filesystem | Milestones, RAG status, risks, next steps |
| 8. No Notion | `/report:generate --team` | Filesystem | Pipeline completes, skip DB logging |
| 9. No Drive | `/report:generate --team` | Filesystem | Research skips Drive, uses local files |
| 10. QA Recommend-Only | `/report:generate --team` | Filesystem | Report file unmodified by QA agent |
| 11. Mermaid Charts | `/report:generate` | Filesystem | Valid syntax, appropriate chart types |
| 12. Notion DB Discovery | `/report:generate --team` | Filesystem, Notion | Consolidated DB preferred, legacy fallback, no lazy creation, Type="Business Report" |
