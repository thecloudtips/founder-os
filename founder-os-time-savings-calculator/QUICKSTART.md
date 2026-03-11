# Quick Start: founder-os-time-savings-calculator

> Know Exactly How Much Time (and Money) Your AI Plugins Save

## Overview

**Plugin #25** | **Pillar**: Meta & Growth | **Platform**: Claude Code

Scans all active Founder OS plugin Notion databases, counts completed tasks across 24 categories, and calculates time saved, dollar value, and ROI multiplier. Produces weekly reports with Mermaid pie charts and monthly reports with bar charts and annualized projections.

### What This Plugin Does

- Scans 24 task categories across all active Founder OS plugin databases
- Calculates hours saved, dollar value, and ROI multiplier per category
- Generates Mermaid pie charts (weekly) and bar charts (monthly)
- Supports configurable hourly rate with an hourly rate gate (omits dollar figures when rate is 0)

### Time Savings

Estimated **30 minutes** per week compared to manually tallying plugin usage across databases.

## Available Commands

| Command | Description |
|---------|-------------|
| `/savings:quick` | Quick chat-only summary of recent savings (no file/Notion output) |
| `/savings:weekly` | Full weekly savings report with Mermaid chart, saved to file and Notion |
| `/savings:monthly-roi` | Multi-month ROI report with trends, bar charts, and annualized projections |
| `/savings:configure` | Set hourly rate and customize time estimates |

## Usage Examples

### Example 1: Quick Savings Check

```
/savings:quick
```

**What happens:** Scans all active Founder OS plugin databases, counts completed tasks from the past week, and displays a chat-only summary with hours saved per category. No file output, no Notion logging.

### Example 2: Full Weekly Report

```
/savings:weekly
```

**What happens:** Generates a complete weekly savings report with a breakdown by plugin and task category, a Mermaid pie chart showing time distribution, and total hours/dollar savings. Saves to a local Markdown file and logs to the "[FOS] Reports" Notion database with Type="ROI Report" (falls back to "Founder OS HQ - Reports", then "Time Savings Calculator - Reports" if not found).

### Example 3: Monthly ROI Report

```
/savings:monthly-roi
```

**What happens:** Produces a multi-month ROI report with trend analysis, Mermaid bar charts comparing months, ROI multiplier calculation, and annualized savings projections. Saves to file and Notion.

### Example 4: Configure Your Hourly Rate

```
/savings:configure
```

**What happens:** Prompts you to set your hourly rate (used for dollar value calculations) and optionally customize time estimates for any of the 24 task categories. When hourly rate is set to 0, reports omit dollar figures and show time savings only.

## Tips

- Run `/savings:quick` first to see what data is available before generating a full report
- Set your hourly rate with `/savings:configure` before running weekly or monthly reports to see dollar values
- Weekly reports are idempotent -- re-running for the same week updates the existing report rather than creating a duplicate
- The plugin only reads from other plugin databases; it never modifies them

## Troubleshooting

| Issue | Solution |
|-------|----------|
| MCP server not responding | Check `.mcp.json` configuration and API keys |
| No data found | Ensure other Founder OS plugin databases are shared with your Notion integration |
| Dollar values missing | Run `/savings:configure` to set a non-zero hourly rate |
| Command not found | Verify plugin is installed in the correct directory |

## Next Steps

1. Try `/savings:quick` to see your current savings at a glance
2. Run `/savings:configure` to set your hourly rate
3. Generate your first `/savings:weekly` report
4. Check `INSTALL.md` for advanced configuration options
