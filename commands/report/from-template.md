---
description: Generate a report from a predefined template with structured sections
argument-hint: --template=NAME --data=PATH --team --output=PATH
allowed-tools: Read, Glob, Grep, Write, Task
---

# Report From Template

Generate a report using a predefined template structure. Templates provide section layout and formatting guidance; data fills the content.

## Parse Arguments

- `--template=NAME` (string, optional) — template name: `executive-summary`, `full-business-report`, `project-status-report`. If not provided, list available templates and ask user to choose.
- `--data=PATH` (string, optional) — path to data source. If not provided, ask user.
- `--team` (boolean, default: false) — use full 5-agent pipeline
- `--output=PATH` (string, default: `./report-output/`) — output directory

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Available Templates

When no `--template` is specified, or when listing templates:

Read all template files from `${CLAUDE_PLUGIN_ROOT}/templates/report-templates/` and present:

| Template | Description | Best For |
|----------|-------------|----------|
| `executive-summary` | 1-2 page key metrics + recommendations | Quick stakeholder updates |
| `full-business-report` | Multi-section comprehensive analysis | Quarterly reviews, deep dives |
| `project-status-report` | RAG status, milestones, action items | Weekly/monthly project updates |

Ask the user to select a template.

## Mode 1: Default (Single-Agent)

When `--team` is NOT present:

1. Read all 5 skills from `${CLAUDE_PLUGIN_ROOT}/skills/report/*/SKILL.md`.
2. Read the selected template from `${CLAUDE_PLUGIN_ROOT}/templates/report-templates/[template-name].md`.
3. Read the data source (auto-detect format per data-extraction skill).
4. Analyze data per data-analysis skill.
5. Generate report following the template structure:
   - Fill each `{{placeholder}}` with data-derived content
   - Insert Mermaid charts at `<!-- CHART: description -->` markers
   - Follow template section order exactly
6. Write output to `--output` path.

## Mode 2: Team Pipeline (`--team`)

When `--team` IS present:

1. Read template and pass it as part of the pipeline input.
2. Read `${CLAUDE_PLUGIN_ROOT}/agents/report/config.json` and execute the 5-agent pipeline.
3. The Writing Agent receives both analysis results AND template structure — it must follow the template.
4. Present final output with pipeline report.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Error Handling

- Unknown template name: list available templates and ask user to choose
- Missing data source: ask user to provide
- Template file missing: report error, suggest running with no template flag

## Usage Examples

```
/founder-os:report:from-template                                           # Interactive: list templates, ask for choice
/founder-os:report:from-template --template=executive-summary --data=q4.csv
/founder-os:report:from-template --template=full-business-report --data=./data/ --team
/founder-os:report:from-template --template=project-status-report --data=sprint-metrics.json --output=./status/
```
