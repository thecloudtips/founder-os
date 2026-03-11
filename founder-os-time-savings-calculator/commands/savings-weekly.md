---
description: Generate a weekly time savings report showing hours and dollars saved by Founder OS plugins
argument-hint: "[--week=YYYY-WNN] [--output=PATH] [--format=notion|file|both]"
allowed-tools: ["Read", "Write"]
---

# Generate Weekly Savings Report

Produce a complete weekly savings report covering one calendar week. Scan all active Founder OS plugin Notion databases, calculate time and dollar savings per category, generate a formatted Markdown report with Mermaid pie chart, and save to file and/or Notion.

## Load Skills

Read the cross-plugin-discovery skill at `${CLAUDE_PLUGIN_ROOT}/skills/cross-plugin-discovery/SKILL.md` for the plugin scanning algorithm and DiscoveryResult schema.

Read the roi-calculation skill at `${CLAUDE_PLUGIN_ROOT}/skills/roi-calculation/SKILL.md` for calculation formulas, report structure, chart generation, and configuration resolution.

Read the task estimates registry at `${CLAUDE_PLUGIN_ROOT}/config/task-estimates.json` for the plugin-to-database mapping.

Read the report template at `${CLAUDE_PLUGIN_ROOT}/templates/savings-report-template.md` as the structural scaffold for the output.

## Parse Arguments

Extract from `$ARGUMENTS`:

- `--week=YYYY-WNN` (optional) -- ISO week to report on. E.g., `2026-W10`. Default: current calendar week (Monday to Sunday).
- `--output=PATH` (optional) -- File path for the generated report. Default: `savings-reports/weekly-[YYYY-WNN]-[YYYY-MM-DD].md`.
- `--format=notion|file|both` (optional, default: `both`) -- Where to save. `notion` = Notion DB only, `file` = local file only, `both` = both.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Workflow

### Step 1: Resolve Week Boundaries

1. Parse `--week` into start_date (Monday) and end_date (Sunday).
2. If no `--week` provided, use the current week's Monday through today (partial week is ok — note "partial week" in report).
3. Store `week_label` (e.g., "Week 10, 2026") and `date_range` (e.g., "2026-03-02 to 2026-03-08").

### Step 2: Load Configuration

1. Read `${CLAUDE_PLUGIN_ROOT}/config/user-config.json` if it exists.
2. Fall back to task-estimates.json defaults.
3. If hourly_rate is not configured (no user-config.json and first run):
   - Use AskUserQuestion: "No hourly rate configured. Enter your rate ($/hr) or press Enter to use default ($150/hr), or 0 to disable dollar calculations:"
   - Save response to user-config.json via the Write tool.

### Step 3: Discover Active Plugins

Run the full cross-plugin-discovery algorithm with the resolved date range.

### Step 4: Calculate Savings

Apply the roi-calculation skill's per-category calculation for each discovered plugin. Compute all aggregate metrics.

### Step 5: Generate Mermaid Pie Chart

Create a Mermaid pie chart showing time saved by category (top 8 categories, group remainder as "Other"):

```
pie title Time Saved by Category (Week [NN])
  "Email Triage" : 4.5
  "Report Generation" : 3.2
  ...
```

### Step 6: Build Report

Populate the savings-report-template.md with calculated values:
- Fill all 6 sections (Cover, Executive Summary, Category Breakdown, Plugin Coverage, Trend Analysis, ROI Projection).
- For trend analysis: if previous week data is available, include period comparison. Otherwise, set `has_trend` to false and omit the section.
- Set `rate_set` conditional based on whether hourly_rate > 0.

### Step 7: Save Report

Based on `--format`:

**File output** (when format is `file` or `both`):
1. Determine output path (use `--output` or default).
2. Create directory if needed.
3. Write the report using Write tool.

**Notion output** (when format is `notion` or `both`):
1. Search for "[FOS] Reports" database first. If not found, try "Founder OS HQ - Reports". If not found, search for "Time Savings Calculator - Reports". If none is found, skip Notion output (do NOT create the database).
2. When writing to "[FOS] Reports" or "Founder OS HQ - Reports", set the **Type** property to `"ROI Report"`.
3. Check for existing record with same Report Title on same calendar day (idempotent upsert).
4. Create or update record with: Report Title = "Weekly Savings: [date_range]", Type = "ROI Report" (consolidated DB only), Report Type = "Weekly", Date Range, Total Hours Saved, Dollar Value, Tasks Automated, Active Plugins, Top Category, Report File path, Generated At.

### Present Summary

```
## Weekly Savings Report Generated

**Period**: [week_label] ([date_range])
**Output**: [file path]
**Saved to Notion**: [Yes/No]

### Highlights
| Metric | Value |
|--------|-------|
| Hours Saved | [N] hrs |
| Dollar Value | $[N] |
| Tasks Automated | [N] |
| Top Saver | [category] ([N] hrs) |
| Active Plugins | [N] |
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Graceful Degradation

- **Notion MCP unavailable**: Cannot scan plugins — report error and stop. Notion is required for this plugin.
- **Filesystem MCP unavailable**: Skip file output. Output report to chat. Skip Notion file path field.
- **No plugins found**: Generate minimal report noting "No active plugins detected."
- **user-config.json write fails**: Continue with defaults, note in output.
- **Previous week data unavailable**: Set has_trend=false, skip trend section.

## Usage Examples

```
/savings:weekly
/savings:weekly --week=2026-W09
/savings:weekly --output=./reports/week10.md
/savings:weekly --format=notion
/savings:weekly --week=2026-W08 --format=file --output=./archive/w08.md
```
