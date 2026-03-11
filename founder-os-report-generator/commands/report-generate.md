---
description: Generate a report from data sources with AI analysis and formatting
argument-hint: --team --data=PATH --output=PATH
allowed-tools: Read, Glob, Grep, Write, Task
---

# Report Generate

Generate a polished Markdown report from data sources. Operate in one of two modes depending on arguments.

## Parse Arguments

Extract these flags from `$ARGUMENTS`:
- `--team` (boolean, default: false) — activate full 5-agent pipeline mode
- `--data=PATH` (string, optional) — path to data source file or directory. If not provided, ask the user what data to analyze.
- `--output=PATH` (string, default: `./report-output/`) — output directory for generated report

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Mode 1: Default (Single-Agent Quick Report)

When `--team` is NOT present:

1. Read ALL 5 skills:
   - `${CLAUDE_PLUGIN_ROOT}/skills/data-extraction/SKILL.md`
   - `${CLAUDE_PLUGIN_ROOT}/skills/data-analysis/SKILL.md`
   - `${CLAUDE_PLUGIN_ROOT}/skills/report-writing/SKILL.md`
   - `${CLAUDE_PLUGIN_ROOT}/skills/chart-generation/SKILL.md`
   - `${CLAUDE_PLUGIN_ROOT}/skills/executive-summary/SKILL.md`
2. If `--data` is provided, read the data source. Auto-detect format (CSV, JSON, text).
3. If no `--data`, ask the user for their data source or report requirements.
4. Perform analysis using the data-analysis skill rules.
5. Generate a concise report (3-5 pages) with:
   - Executive summary
   - Key findings with supporting metrics
   - 1-2 Mermaid charts for key data visualizations
   - Recommendations
6. Write the report to `--output` as a Markdown file.
7. Present a summary to the user with the output path.

### Output Format (Default Mode)

```
## Report Generated

**Output**: ./report-output/report-2026-02-23.md
**Data Sources**: 1 file (sales-q4.csv)
**Sections**: Executive Summary, Key Findings, Analysis, Recommendations
**Charts**: 2 Mermaid diagrams embedded
**Word Count**: ~2,800 words

### Executive Summary Preview
[First 2-3 sentences of the executive summary]
```

## Mode 2: Team Pipeline (`--team`)

When `--team` IS present:

1. Read the pipeline configuration at `${CLAUDE_PLUGIN_ROOT}/teams/config.json`.
2. Execute the full 5-agent pipeline sequentially:
   - **Research Agent** → gather and extract data from all sources
   - **Analysis Agent** → process, analyze, identify trends
   - **Writing Agent** → generate report prose with executive summary
   - **Formatting Agent** → add Mermaid charts, format tables, write output file
   - **QA Agent** → review for accuracy and consistency (recommend-only)
3. Each agent reads its definition from `${CLAUDE_PLUGIN_ROOT}/teams/agents/`.
4. Pass structured JSON output from each agent as input to the next.
5. Present the final pipeline report with:
   - Report output path
   - Page count and section summary
   - Charts generated
   - QA notes and flags (if any)
   - Notion DB entry in "Founder OS HQ - Reports" with Type="Business Report" (if Notion configured)

## Data Source Detection

Detect the data source type and handle accordingly:
- `.csv` files → Parse as comma-separated values. Extract headers as column names, detect numeric vs. text columns, handle quoted fields and escaped commas. Summarize row count and column types.
- `.json` files → Parse as JSON. Support both array-of-objects and nested structures. Flatten nested keys using dot notation for analysis. Detect numeric fields for statistical analysis.
- `.txt` / `.md` / `.log` files → Read as plain text. Extract structured data via pattern matching (tables, key-value pairs, bullet lists). For log files, parse timestamps and group by time intervals.
- Notion database → Query via Notion MCP (if configured). Use `notion-search` to find the database by name, then fetch all pages. Extract property values as columns for analysis.
- Directory path → Scan for all supported file types (`.csv`, `.json`, `.txt`, `.md`, `.log`). Process each file individually, then merge results. Report which files were included and any that were skipped.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Error Handling

- If no data source provided and user doesn't specify one: halt and ask.
- If data file doesn't exist: report error with path.
- If MCP servers unavailable in team mode: warn but continue with filesystem-only.
- If Notion MCP not configured: skip Notion DB logging, output to filesystem only.
- If output directory doesn't exist: create it.

## Usage Examples

```
/report:generate --data=sales-q4.csv
/report:generate --data=./data/ --output=./reports/
/report:generate --team --data=metrics.json
/report:generate --team --data=sales-q4.csv --output=./q4-report/
/report:generate                              # Interactive: asks for data source
```
