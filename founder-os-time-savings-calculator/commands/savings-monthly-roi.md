---
description: Generate a multi-period ROI report showing time savings trends and annualized projections across months
argument-hint: "[YYYY-MM] [--months=N] [--output=PATH] [--format=notion|file|both]"
allowed-tools: ["Read", "Write"]
---

# Generate Monthly ROI Report

Produce a comprehensive multi-period ROI report analyzing time savings trends across multiple months. Run discovery for each month, compute period-over-period changes, generate Mermaid bar charts, and project annualized savings.

## Load Skills

Read the cross-plugin-discovery skill at `${CLAUDE_PLUGIN_ROOT}/skills/cross-plugin-discovery/SKILL.md` for the plugin scanning algorithm.

Read the roi-calculation skill at `${CLAUDE_PLUGIN_ROOT}/skills/roi-calculation/SKILL.md` for calculation formulas, multi-period chart generation (xychart-beta), and report structure.

Read the task estimates registry at `${CLAUDE_PLUGIN_ROOT}/config/task-estimates.json` for the plugin-to-database mapping.

Read the report template at `${CLAUDE_PLUGIN_ROOT}/templates/savings-report-template.md` as the structural scaffold.

## Parse Arguments

Extract from `$ARGUMENTS`:

- `YYYY-MM` (optional) -- End month for the report. Default: current month.
- `--months=N` (optional, 1-6, default: 3) -- Number of months to include.
- `--output=PATH` (optional) -- File path for the report. Default: `savings-reports/monthly-roi-[YYYY-MM]-[YYYY-MM-DD].md`.
- `--format=notion|file|both` (optional, default: `both`) -- Where to save.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Workflow

### Step 1: Resolve Month Boundaries

1. Parse the end month (default: current month).
2. Calculate start month by going back `--months` months.
3. Generate list of month periods, each with first day and last day.
4. Example for `--months=3` ending March 2026: [Jan 2026, Feb 2026, Mar 2026].

### Step 2: Load Configuration

1. Read `${CLAUDE_PLUGIN_ROOT}/config/user-config.json` if it exists.
2. Fall back to task-estimates.json defaults.
3. If hourly_rate not configured, use AskUserQuestion to prompt (same as /savings:weekly).

### Step 3: Run Discovery Per Month

For each month in the period list:
1. Run the cross-plugin-discovery algorithm with that month's date range.
2. Store DiscoveryResult array per month.
3. Track which plugins are consistently available across all months.

### Step 4: Calculate Per-Month Savings

For each month:
1. Apply roi-calculation per-category calculations.
2. Compute month-level aggregates: total_hours_saved, total_dollar_value, tasks_automated, active_plugins.

### Step 5: Compute Period-Over-Period Changes

For each consecutive month pair, calculate:
- Hours saved change (absolute and percentage)
- Dollar value change
- Tasks automated change
- Apply P16-style flagging labels:
  - `> +50%` → "Significant increase"
  - `> +20%` → "Notable increase"
  - `-20% to +20%` → "Stable"
  - `< -20%` → "Notable decrease"
  - `< -50%` → "Significant drop"
  - New category appearing → "New"
  - Category disappearing → "Eliminated"

### Step 6: Generate Mermaid Bar Chart

Create a Mermaid xychart-beta bar chart:

```
xychart-beta
  title "Monthly Time Savings (hours)"
  x-axis ["Jan 2026", "Feb 2026", "Mar 2026"]
  y-axis "Hours Saved" 0 --> [max_value * 1.2]
  bar [8.5, 12.3, 15.1]
```

If hourly_rate > 0, generate a second chart for dollar values.

### Step 7: Build Report

Generate a report with these sections:

1. **Cover**: "Monthly ROI Report: [start_month] to [end_month]", generation date, config summary.

2. **Executive Summary**: Totals across all months, overall trend direction (growing/stable/declining), best month, worst month, annualized projections.

3. **Monthly Breakdown**: Table per month showing:
   | Month | Hours Saved | Tasks | Plugins | Dollar Value | Change |
   With flagging labels on the Change column.

4. **Category Trends**: For each category active in 2+ months, show month-over-month values. Highlight categories with consistent growth or decline.

5. **Trend Visualization**: Mermaid bar chart(s) from Step 6.

6. **ROI Projection**:
   - Monthly average across the period
   - Annualized projection (monthly_avg × 12)
   - Confidence note: "Based on [N] months of data"
   - If rate > 0: annual dollar value, cost per work day saved

### Step 8: Save Report

Same logic as /savings:weekly:
- File output to `--output` or default path.
- Notion upsert to "[FOS] Reports" (or fall back to "Founder OS HQ - Reports", then "Time Savings Calculator - Reports") with Type = "ROI Report" (consolidated DB) and Report Type = "Monthly ROI". If no DB is found, skip Notion output (do NOT create the database).
- Idempotent by Report Title + same calendar day.

### Present Summary

```
## Monthly ROI Report Generated

**Period**: [start_month] to [end_month] ([N] months)
**Output**: [file path]
**Saved to Notion**: [Yes/No]

### Highlights
| Metric | Total | Monthly Avg | Annualized |
|--------|-------|-------------|------------|
| Hours Saved | [N] | [N] | [N] |
| Dollar Value | $[N] | $[N] | $[N] |
| Tasks | [N] | [N] | [N] |

**Trend**: [Growing/Stable/Declining] — [description]
**Best Month**: [month] ([N] hrs)
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Graceful Degradation

- **Notion MCP unavailable**: Cannot scan plugins — report error and stop.
- **Filesystem MCP unavailable**: Skip file output, output to chat.
- **Months with no data**: Include in report as zero-value rows. Note "No data" in the monthly breakdown.
- **Only 1 month has data**: Generate report but skip period-over-period changes and trend analysis. Note "Insufficient data for trend analysis."
- **--months exceeds available data**: Report only months that have data. Note "Data available for [N] of [M] requested months."

## Usage Examples

```
/savings:monthly-roi
/savings:monthly-roi 2026-02
/savings:monthly-roi 2026-03 --months=6
/savings:monthly-roi --output=./reports/q1-roi.md
/savings:monthly-roi --format=notion
/savings:monthly-roi 2026-01 --months=1 --format=file
```
