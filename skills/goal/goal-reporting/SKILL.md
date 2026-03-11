---
name: Goal Reporting
description: "Formats goal progress into visual dashboards with tables, progress bars, and Mermaid Gantt charts. Activates when the user wants a goal dashboard, progress report, timeline visualization, or asks 'show me a visual of my goals.' Covers dashboard layout, Gantt generation, and formatted report assembly."
globs:
  - commands/goal-report.md
---

# Goal Reporting

## Overview

Format and visualize goal progress data into structured dashboards, timelines, and reports. Assemble dashboard tables with emoji RAG indicators and ASCII progress bars, generate Mermaid Gantt charts for timeline visualization, and structure reports for both chat and Notion output. Serve as the presentation layer that transforms raw goal tracking data into scannable, actionable summaries.

## Report Structure

Assemble every goal report using exactly four sections, always in this order. Never reorder or omit sections (display empty-state messages when a section has no content).

### 1. Dashboard Table

Render a compact Markdown table with all goals, one row per goal. Sort rows by RAG status severity (Red first, Yellow second, Green third, Not Started last). Within each RAG group, sort by Target Date ascending (earliest deadline first). Include the progress bar and percentage inline in the Progress column.

### 2. RAG Breakdown

Group goals by RAG status. Present Red goals first, then Yellow, then Green, then Not Started. Under each group header (using the corresponding RAG emoji), provide a brief 1-2 sentence analysis explaining the common patterns or root causes within that group. If a RAG group has zero goals, omit that group entirely from the breakdown rather than showing an empty section.

### 3. Needs Attention

Render a bulleted list of goals that have active blockers. Sort by blocker severity (critical blockers first, then moderate, then minor). Each bullet must include the goal name, the blocker description, and a suggested next action. If no goals have active blockers, display: "No active blockers detected across tracked goals."

### 4. Gantt Timeline

Generate a Mermaid Gantt chart showing all goals with milestones plotted on a timeline. Group goals by Category using Mermaid `section` directives. Apply color coding based on RAG status. Exclude goals without a Target Date from the chart and note their omission in a footnote below the chart.

## Dashboard Table Format

Construct the dashboard table with the following columns in this exact order:

| Goal | Category | Progress | RAG | Target Date | Status |

Apply these formatting rules:

- **Goal column**: Display the goal name. Truncate names longer than 30 characters with an ellipsis (e.g., "Implement new onboarding flo...").
- **Category column**: Display the goal category as-is.
- **Progress column**: Render a 10-character ASCII progress bar followed by the percentage. Use █ (U+2588) for filled segments and ░ (U+2591) for empty segments. Example: `███████░░░ 70%`.
- **RAG column**: Map RAG status to emoji: 🟢 Green, 🟡 Yellow, 🔴 Red, ⚪ Not Started.
- **Target Date column**: Display in YYYY-MM-DD format. Show "No deadline" for goals without a Target Date.
- **Status column**: Display the current status text (e.g., In Progress, Completed, Not Started, On Hold).

Sort the entire table by RAG severity: 🔴 Red first, 🟡 Yellow second, 🟢 Green third, ⚪ Not Started last. Apply left-alignment to text columns and center-alignment to RAG and Progress columns.

Reference `${CLAUDE_PLUGIN_ROOT}/skills/goal/goal-reporting/references/dashboard-table-format.md` for full column specifications, alignment rules, and edge case handling.

## Mermaid Gantt Chart

Generate a Mermaid Gantt chart using the following structure and rules.

### Base Structure

Open every Gantt chart with:

```
gantt
    dateFormat YYYY-MM-DD
    title Goal Progress Timeline
```

### Section Grouping

Group goals by Category using `section` directives. Place each category on its own section line. Within each section, list goals in Target Date order (earliest first).

### Color Directives

Map RAG status to Mermaid task modifiers:

- **Red RAG**: Apply `crit` modifier (renders in red/critical styling).
- **Yellow RAG or In Progress**: Apply `active` modifier (renders in blue/active styling).
- **Completed goals**: Apply `done` modifier (renders in grey/done styling).
- **Green RAG (not completed)**: Use default styling (no modifier).
- **Not Started**: Use default styling (no modifier).

### Task Bars

Render each goal as a single bar spanning from Start Date to Target Date. Use the format:

```
TaskName :modifier, startDate, endDate
```

### Milestones

Render milestones using the `milestone` keyword. Place milestone markers at their target dates within the appropriate category section. Use the format:

```
MilestoneName :milestone, targetDate, 0d
```

### Sanitization Rules

- Remove special characters from task and milestone names (keep alphanumeric, spaces, and hyphens only).
- Truncate names to 40 characters maximum.
- Replace any remaining problematic characters with hyphens.
- Enforce a maximum of 25 nodes (tasks + milestones combined) to prevent chart overflow. If the goal count exceeds 25, include the 25 highest-priority goals (by RAG severity, then by Target Date proximity) and add a footnote stating how many goals were excluded.

### Omission Handling

Exclude goals without a Target Date from the Gantt chart entirely. Add a footnote below the Mermaid code block listing omitted goals by name: "Note: The following goals are excluded from the timeline (no target date): [goal names]."

Reference `${CLAUDE_PLUGIN_ROOT}/skills/goal/goal-reporting/references/gantt-generation.md` for complete Mermaid syntax examples, sanitization rules, and overflow handling strategies.

## Filtering Rules

Apply filters to narrow the goal set before rendering any report section. All filters operate on the full goal list and reduce it to a subset.

- **Default (no filters)**: Include all non-archived goals. Archived goals never appear in reports unless explicitly requested.
- **`--status=active`**: Include only goals with Status = "In Progress".
- **`--status=red`**: Include only goals with RAG status = Red.
- **`--status=completed`**: Include only goals with Status = "Completed".
- **`--category=X`**: Include only goals matching the specified category (case-insensitive match).
- **Multiple filters**: Combine all active filters with AND logic. A goal must satisfy every active filter to appear in the report. For example, `--status=red --category=Revenue` shows only Red RAG goals in the Revenue category.
- **Empty result set**: When no goals match the applied filters, display the message: "No goals match the selected filters." Do not render empty tables or charts. Include a suggestion to broaden filters or check available categories.

## Progress Bar Construction

Build ASCII progress bars using a fixed 10-character width.

### Character Set

- Filled segment: █ (U+2588)
- Empty segment: ░ (U+2591)

### Formula

Calculate the number of filled characters:

1. Take the progress percentage as an integer (0-100).
2. Divide by 10 to get a decimal value.
3. Apply standard rounding (values ≥ 0.5 round up, values < 0.5 round down).
4. The result is `filled_count`. Calculate `empty_count = 10 - filled_count`.
5. Concatenate `filled_count` █ characters followed by `empty_count` ░ characters.
6. Append a space and the original percentage with % suffix.

### Examples

| Percentage | Filled Count | Bar | Display |
|-----------|-------------|-----|---------|
| 0% | 0 | ░░░░░░░░░░ | `░░░░░░░░░░ 0%` |
| 15% | 2 | ██░░░░░░░░ | `██░░░░░░░░ 15%` |
| 25% | 3 | ███░░░░░░░ | `███░░░░░░░ 25%` |
| 50% | 5 | █████░░░░░ | `█████░░░░░ 50%` |
| 70% | 7 | ███████░░░ | `███████░░░ 70%` |
| 100% | 10 | ██████████ | `██████████ 100%` |

Note: 25% divides to 2.5, which rounds to 3 filled characters. Always apply standard rounding at the boundary.

## RAG Emoji Mapping

Map RAG classification to display emoji consistently across all report sections:

| RAG Status | Emoji | Meaning |
|-----------|-------|---------|
| Green | 🟢 | On track — progress aligns with timeline |
| Yellow | 🟡 | At risk — progress lagging or blockers emerging |
| Red | 🔴 | Behind — significantly off-track or blocked |
| Not Started | ⚪ | No data yet — goal created but work not begun |

Apply these emoji consistently in both the Dashboard Table RAG column and the RAG Breakdown section headers. Never use text labels ("Green", "Red") in place of emoji in rendered output. Include the text meaning only in the RAG Breakdown section headers for accessibility (e.g., "🔴 Red — Behind").

## Chat vs Notion Output

Adapt the report format based on the output destination.

### Chat Output

Render the full report as Markdown directly in the chat response. Include the Mermaid Gantt chart inside a fenced code block with the `mermaid` language identifier. Present all four sections in order. Use Markdown table syntax for the dashboard. Keep the total output under 4000 characters when possible by truncating the RAG Breakdown analysis to one sentence per group.

### Notion Output

Write the report content to the discovered Goals database (see goal-tracking skill for discovery protocol) or as a standalone Notion page, depending on the command invocation. Convert Mermaid code blocks to Notion code blocks (Notion does not natively render Mermaid, so preserve the source for manual rendering). Use Notion-compatible block types: tables as Markdown in a code block or as structured paragraphs, bulleted lists as bulleted_list_item blocks.

### File Output

When `--output=PATH` is specified, write the complete report (all four sections, full Mermaid source) to the specified local file path. Use `.md` extension. Do not truncate any section for file output — include full analysis text and complete Gantt chart source.

## Edge Cases

Handle the following scenarios explicitly:

### Zero Goals

When the goal database is empty or contains only archived goals, display:

"No goals tracked yet. Use /founder-os:goal:create to get started."

Do not render empty tables, charts, or section headers. Return only the above message.

### All Goals Completed

When every non-archived goal has Status = "Completed", display a celebration summary:

- Open with: "All goals completed!"
- Show total goals completed count.
- Show the date range (earliest start to latest completion).
- Show average completion percentage (should be 100%).
- Render the dashboard table normally (all green, all 100%).
- Omit the Needs Attention section (replace with "No active blockers — all goals completed.").
- Render the Gantt chart with all tasks marked `done`.

### Goals Without Target Date

Include these goals in the Dashboard Table with "No deadline" in the Target Date column. Exclude them from the Gantt Timeline. List their names in a footnote below the Gantt chart. In the RAG Breakdown, treat them according to their calculated RAG status (which may factor in other signals beyond timeline).

### Very Long Goal Names

Truncate goal names to 30 characters in the Dashboard Table, appending "..." to indicate truncation (e.g., "Implement new onboarding flo..."). In the Gantt chart, truncate to 40 characters. Preserve the full goal name in any detail views, tooltips, or linked Notion pages.

### Single Goal

Render all four sections even with only one goal. The Dashboard Table has one row, the RAG Breakdown has one group, the Needs Attention section shows one bullet or the no-blockers message, and the Gantt chart shows one bar.

## Additional Resources

- `${CLAUDE_PLUGIN_ROOT}/skills/goal/goal-reporting/references/dashboard-table-format.md` — Full column specifications, alignment rules, and formatting edge cases for the dashboard table.
- `${CLAUDE_PLUGIN_ROOT}/skills/goal/goal-reporting/references/gantt-generation.md` — Complete Mermaid Gantt syntax reference, sanitization rules, overflow handling, and example chart source code.
