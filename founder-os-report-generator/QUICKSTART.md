# Quick Start: Report Generator Factory

> Pipeline-based report generation factory that transforms raw data from CSV, JSON, Notion, and text files into polished Markdown reports with Mermaid charts and executive summaries.

## Overview

**Plugin #09** | **Pillar**: Code Without Coding | **Platform**: Claude Code

Report Generator Factory turns your raw data into polished, professional reports. Point it at a CSV, JSON file, or Notion database and get a formatted Markdown report with charts, analysis, and an executive summary -- in minutes, not hours.

### What This Plugin Does

- Reads data from CSV, JSON, Markdown, text files, Notion databases, and Google Drive documents (via gws CLI)
- Analyzes trends, patterns, and key metrics automatically
- Generates structured Markdown reports with executive summaries
- Creates Mermaid charts (pie, bar, flow, Gantt, timeline) embedded in the output
- Validates report accuracy with a recommend-only QA pass

### Time Savings

Estimated **3-5 hours per report** compared to manually gathering data, analyzing metrics, writing prose, and formatting charts.

## Available Commands

| Command | Description |
|---------|-------------|
| `/report:generate` | Generate a report from local data files |
| `/report:generate --team` | Run the full 5-agent pipeline (research, analysis, writing, formatting, QA) |
| `/report:from-template` | Generate a report using a predefined template |

## Your First Report in 5 Minutes

Make sure the Filesystem MCP server is configured (see [INSTALL.md](INSTALL.md)). That is the only requirement to get started.

### Example 1: Quick Report from a CSV File

The simplest way to generate a report. Point the plugin at a data file and get a Markdown report back.

```
/report:generate --sources=./quarterly-sales.csv
```

**What happens:**
- Reads and parses the CSV file
- Identifies key columns, metrics, and trends
- Generates a structured Markdown report with an executive summary
- Outputs the report to your workspace directory
- Takes about 30-60 seconds for a typical dataset

**Sample output structure:**
```markdown
# Quarterly Sales Report
## Executive Summary
Revenue grew 12% QoQ, driven by Enterprise segment...

## Key Metrics
| Metric | Q3 | Q4 | Change |
|--------|-----|-----|--------|
| Revenue | $1.2M | $1.34M | +12% |
...

## Trends
- Enterprise segment up 18%
- SMB segment flat at 2% growth
```

### Example 2: Template-Based Report

Use a predefined template to generate a report with a specific structure. Three templates are included out of the box.

```
/report:from-template --template=project-status-report --sources=./sprint-data.json
```

**What happens:**
- Loads the `project-status-report` template from `templates/report-templates/`
- Reads and parses the JSON data file
- Maps data to template sections: milestones, progress, risks, blockers, timeline
- Generates a formatted report following the template structure
- Includes a Mermaid Gantt chart for timeline visualization

**Available templates:**

| Template Name | Best For |
|---------------|----------|
| `executive-summary` | Board meetings, investor updates, 1-page overviews |
| `full-business-report` | Quarterly reviews, annual reports, deep-dive analysis |
| `project-status-report` | Sprint reviews, project updates, team standups |

### Example 3: Full Pipeline with --team

For the most thorough reports, activate the full 5-agent pipeline. Each agent specializes in one step of the report generation process.

```
/report:generate --team --sources=./revenue-data.csv --template=full-business-report --output=./reports/q4-review.md
```

**What happens:**
1. **Research Agent** reads and extracts data from `revenue-data.csv` (plus Notion and Drive if configured)
2. **Analysis Agent** processes the data, identifies trends, outliers, and key metrics
3. **Writing Agent** generates the full report prose following the `full-business-report` template, including an executive summary
4. **Formatting Agent** adds Mermaid charts (pie charts for breakdowns, bar charts for comparisons, timelines for trends), formats tables, and polishes the Markdown
5. **QA Agent** reviews the report for accuracy, consistency, and completeness -- flagging any issues as recommendations (never silently editing)
6. Final report is written to `./reports/q4-review.md`

**Sample Mermaid chart in output:**
```markdown
```mermaid
pie title Revenue by Segment
    "Enterprise" : 58
    "SMB" : 27
    "Startup" : 15
``​`
```

## Common Flags Reference

| Flag | Default | Description |
|------|---------|-------------|
| `--team` | off | Activate the full 5-agent pipeline (Research, Analysis, Writing, Formatting, QA) |
| `--sources=PATH` | current dir | Path to data file(s) -- supports CSV, JSON, Markdown, text |
| `--template=NAME` | none | Use a report template: `executive-summary`, `full-business-report`, `project-status-report` |
| `--output=PATH` | auto-named | Output file path for the generated report |

## Tips and Best Practices

- **Start with default mode** before using `--team` -- it is faster and gives you a feel for how the plugin reads your data
- **Use templates for recurring reports** -- the `project-status-report` template is great for weekly standups and sprint reviews
- **Name your CSV columns clearly** -- the Research Agent maps columns by name, so "revenue_q4" is better than "col_3"
- **Combine multiple sources** by placing data files in a directory and pointing `--sources` at the folder
- **QA is recommend-only** -- the QA agent will flag potential issues (missing data, inconsistent totals, unclear language) but never silently changes your report
- **Mermaid charts render anywhere** -- GitHub, Notion, VS Code, and most Markdown viewers support Mermaid natively
- **Connect Notion for report storage** -- with Notion configured, completed reports are stored in the "Founder OS HQ - Reports" database with Type="Business Report" (falls back to legacy "Report Generator - Reports")
- **Graceful degradation** -- if Notion or the gws CLI (Google Drive) are not configured, the plugin simply skips those sources and works with local files only

## Related Plugins

This plugin connects with:
- **#20 Client Context Loader**: Client data can serve as input for client-facing reports
- **#21 CRM Sync**: CRM data feeds into business and account reports
- **#27 Workflow Automator**: Chain report generation into automated workflows (e.g., weekly auto-reports)

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Filesystem MCP not configured" | Set `WORKSPACE_DIR` and configure filesystem in `.mcp.json` (see INSTALL.md) |
| Empty report output | Verify the data file exists and has content; try an absolute path with `--sources` |
| Template not found | Use one of: `executive-summary`, `full-business-report`, `project-status-report` |
| Mermaid charts not rendering | View the Markdown in a Mermaid-compatible viewer (GitHub, VS Code, Notion) |
| "Notion MCP not configured" | Set `NOTION_API_KEY` or run without Notion -- plugin works with filesystem alone |
| QA agent flags issues | Review the QA recommendations in the report footer and decide which to address |

## Next Steps

1. Try `/report:generate --sources=./your-data.csv` for a quick report
2. Explore templates with `/report:from-template --template=executive-summary`
3. Run the full pipeline with `/report:generate --team` for maximum quality
4. Connect Notion for report storage and retrieval
5. Check [INSTALL.md](INSTALL.md) for advanced configuration and optional MCP servers
