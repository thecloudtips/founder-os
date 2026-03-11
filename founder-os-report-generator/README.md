# founder-os-report-generator

> **Plugin #09** -- Pipeline-based report generation factory that transforms raw data from CSV, JSON, Notion, and text files into polished Markdown reports with Mermaid charts and executive summaries.

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | Code Without Coding |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Intermediate |
| **Week** | 3 |

## What It Does

Report Generator Factory takes your raw data -- CSV spreadsheets, JSON exports, Notion databases, text files -- and runs it through a 5-agent pipeline to produce professional Markdown reports complete with Mermaid charts and executive summaries. It operates in two modes:

- **Default mode**: Quick single-agent report generation that reads your data, analyzes key metrics, and produces a formatted Markdown report with an executive summary.
- **Team mode** (`--team`): Full 5-agent pipeline that runs Research, Analysis, Writing, Formatting, and QA sequentially -- extracting data from multiple sources, identifying trends, generating prose, adding Mermaid visualizations, and validating accuracy.

## Features

- **Two-mode commands**: Quick single-agent reports or full 5-agent pipeline with `--team`
- **Mermaid charts**: Auto-generated pie charts, bar charts, flow diagrams, and timelines embedded in Markdown
- **Three report templates**: Executive Summary, Full Business Report, and Project Status Report
- **Recommend-only QA**: QA agent flags issues and suggests improvements but never silently alters content
- **Notion HQ integration**: Logs reports to the consolidated "Founder OS HQ - Reports" database with Type="Business Report" (falls back to legacy "Report Generator - Reports")
- **Graceful degradation**: Works with filesystem alone; Notion and gws CLI (Google Drive) enhance but are never required
- **Multi-source data extraction**: Reads CSV, JSON, Markdown, plain text, Notion databases, and Google Drive documents (via gws CLI)

## Commands

| Command | Description | Flags |
|---------|-------------|-------|
| `/report:generate` | Generate a report from local data files | `--team`, `--template=NAME`, `--output=PATH`, `--sources=PATH` |
| `/report:generate --team` | Run the full 5-agent pipeline (research, analysis, writing, formatting, QA) | `--hours=N`, `--template=NAME`, `--output=PATH` |
| `/report:from-template` | Generate a report using a predefined template | `--template=NAME`, `--sources=PATH`, `--output=PATH` |

## Agent Pipeline

This plugin uses a **Pipeline** Agent Team pattern with 5 agents:

```
 Data Sources           5-Agent Pipeline                    Output
 +-----------+    +-------------------------------------------+    +-----------+
 | CSV files |    |                                           |    | Markdown  |
 | JSON data |--->| Research --> Analysis --> Writing -->      |--->| report    |
 | Notion DB |    |             Formatting --> QA             |    | + Mermaid |
 | Text files|    |                                           |    | charts    |
 +-----------+    +-------------------------------------------+    +-----------+
```

| Step | Agent | Role |
|------|-------|------|
| 1 | **Research Agent** | Gather and extract data from all specified sources (files, Notion, Drive) |
| 2 | **Analysis Agent** | Process, analyze, and identify trends, patterns, and key metrics |
| 3 | **Writing Agent** | Generate report prose with executive summary and section narratives |
| 4 | **Formatting Agent** | Add Mermaid charts, format tables, polish Markdown output |
| 5 | **QA Agent** | Review report for accuracy and consistency (recommend-only, no silent edits) |

See `teams/` for agent definitions and `teams/config.json` for pipeline configuration.

## Skills

- **data-extraction**: Patterns for reading and normalizing data from CSV, JSON, Notion databases, and plain text files into a unified internal format.
- **data-analysis**: Statistical analysis techniques, trend detection, outlier identification, and comparison logic for structured datasets.
- **report-writing**: Report structure conventions, section ordering, executive summary writing, narrative generation, and audience-appropriate language.
- **chart-generation**: Mermaid diagram syntax for pie charts, bar charts, flow diagrams, Gantt charts, and timelines with data-driven rendering rules.
- **executive-summary**: Condensation rules for distilling full reports into 1-page executive summaries with key metrics, findings, and recommendations.

## Requirements

### MCP Servers

| Server | Required | Package | Purpose |
|--------|----------|---------|---------|
| **Filesystem** | Yes | `@modelcontextprotocol/server-filesystem` | Read local data files (CSV, JSON, text) and write report output |
| **Notion** | Optional | `@modelcontextprotocol/server-notion` | Read data from Notion databases, store generated reports |
| **gws CLI** | Optional | `gws` (CLI tool) | Read source documents from Google Drive |

### Platform

- **Claude Code** with Node.js 18+ and npx

## Report Templates

| Template | File | Description |
|----------|------|-------------|
| **Executive Summary** | `templates/report-templates/executive-summary.md` | 1-page summary with key metrics, findings, and recommendations |
| **Full Business Report** | `templates/report-templates/full-business-report.md` | Comprehensive multi-section report with analysis, charts, and appendices |
| **Project Status Report** | `templates/report-templates/project-status-report.md` | Sprint/project update with milestones, risks, blockers, and timeline |

## Dependencies

This plugin has no dependencies on other Founder OS plugins. It can be enhanced by:

- **#20 Client Context Loader**: Provides client data that can be used as report input
- **#21 CRM Sync**: Supplies CRM data for client-facing business reports
- **#27 Workflow Automator**: Can chain Report Generator into automated workflows

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Blog Post

**Week 3**: "Reports That Write Themselves: Building an AI Report Factory"

How a 5-agent pipeline turns raw CSV data into polished business reports with charts -- with a breakdown of each agent's role, real output examples, and the decision to use Mermaid for portable visualizations.

## License

MIT
