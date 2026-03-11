---
description: Quick view of time savings across all active Founder OS plugins for a recent period
argument-hint: "[--since=Nd|YYYY-MM-DD]"
allowed-tools: ["Read"]
---

# Quick Savings Summary

Display a compact, chat-only summary of time saved by Founder OS plugins. No file output, no Notion logging. For a full report saved to disk and Notion, use `/savings:weekly`.

## Load Skills

Read the cross-plugin-discovery skill at `${CLAUDE_PLUGIN_ROOT}/skills/cross-plugin-discovery/SKILL.md` for the plugin scanning algorithm and DiscoveryResult schema.

Read the roi-calculation skill at `${CLAUDE_PLUGIN_ROOT}/skills/roi-calculation/SKILL.md` for the calculation formulas, configuration resolution, and quick summary format.

Read the task estimates registry at `${CLAUDE_PLUGIN_ROOT}/config/task-estimates.json` for the plugin-to-database mapping.

## Parse Arguments

Extract from `$ARGUMENTS`:

- `--since=Nd|YYYY-MM-DD` (optional) -- Lookback period. `Nd` means N days ago (e.g., `7d`, `30d`). `YYYY-MM-DD` means from that date to today. Default: `7d`.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Workflow

### Step 1: Resolve Date Range

1. Parse `--since` into a start_date and end_date (today).
2. For `Nd` format: start_date = today minus N days.
3. For `YYYY-MM-DD` format: start_date = provided date, end_date = today.

### Step 2: Load Configuration

1. Read `${CLAUDE_PLUGIN_ROOT}/config/user-config.json` if it exists for hourly_rate and overrides.
2. Fall back to defaults from task-estimates.json (hourly_rate_default: 150).

### Step 3: Discover Active Plugins

Run the cross-plugin-discovery algorithm:
1. Load the task-estimates.json registry.
2. For each category, search Notion for the database by name.
3. If found, count records within the date range using the category's date_property.
4. Record status per plugin (found/not_installed/error).

### Step 4: Calculate Savings

For each discovered plugin with status "found" and filtered_count > 0:
1. Look up manual_minutes and ai_minutes from task-estimates.json (with user overrides applied).
2. Calculate time_saved_hours = (manual_minutes - ai_minutes) × filtered_count / 60.
3. Calculate dollar_value = time_saved_hours × hourly_rate (skip if rate == 0).
4. Calculate roi_multiplier = manual_minutes / ai_minutes.

Compute aggregate totals: total_hours_saved, total_dollar_value, equivalent_work_days, tasks_automated.

### Step 5: Display Summary

Present results in this compact format:

```
## Time Savings Summary (Last [N] Days)

**[total_hours_saved] hours saved** across [tasks_automated] tasks
{{if rate > 0}} — worth **$[total_dollar_value]** at $[hourly_rate]/hr{{/if}}

### Top Savers
| Category | Tasks | Time Saved | ROI |
|----------|-------|------------|-----|
| [top 5 categories by time_saved, descending] |

**[active_plugins]** plugins active, **[not_installed]** not installed
```

If rate is 0 or not configured, omit dollar figures entirely.

End with: `For full report: /savings:weekly • Configure: /savings:configure`

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Graceful Degradation

- **No Notion MCP**: Report "Notion unavailable — cannot scan plugin databases." and stop.
- **No plugins found**: Display "No Founder OS plugin databases found in Notion. Install and use some plugins first."
- **All plugins have 0 tasks in range**: Display "No tasks recorded in the last [N] days. Try a wider range with --since=30d."
- **user-config.json missing**: Use defaults silently, no error.

## Usage Examples

```
/savings:quick
/savings:quick --since=30d
/savings:quick --since=2026-01-01
```
