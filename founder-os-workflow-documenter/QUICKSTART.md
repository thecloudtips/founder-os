# Quick Start: founder-os-workflow-documenter

> Document Any Workflow in 10 Minutes: AI-Powered SOPs

## Overview

**Plugin #28** | **Pillar**: Meta & Growth | **Platform**: Claude Code

Transforms any workflow description into a structured SOP with step-by-step instructions, decision trees, handoff protocols, troubleshooting guides, and Mermaid flowcharts.

### What This Plugin Does

- Converts workflow descriptions (text or file) into 7-section SOPs
- Generates Mermaid flowchart diagrams for any workflow
- Stores SOPs in Notion for search and retrieval
- Assesses workflow complexity (Simple/Moderate/Complex/Very Complex)

### Time Savings

Estimated **2-3 hours** per SOP compared to writing documentation manually.

## Available Commands

| Command | Description |
|---------|-------------|
| `/workflow:document` | Full SOP generation pipeline (7 sections + Mermaid diagram) |
| `/workflow:diagram` | Quick flowchart generation (chat-only by default) |

## Usage Examples

### Example 1: Basic Workflow Documentation

```
/workflow:document "New client onboarding: sales hands off signed contract, ops creates account in Notion, CS sends welcome email, AM schedules kickoff meeting"
```

**What happens:** Generates a complete SOP with workflow overview, prerequisites, step-by-step procedure, decision points, handoff protocol, troubleshooting guide, and revision history. Includes a Mermaid flowchart. Saves to `sops/sop-new-client-onboarding-[date].md` and Notion.

### Example 2: Document from File

```
/workflow:document --file=processes/invoice-approval.md
```

**What happens:** Reads the workflow description from a local file, then runs the full SOP pipeline.

### Example 3: File-Only Output (No Notion)

```
/workflow:document "Employee offboarding process" --format=file --output=hr/offboarding-sop.md
```

**What happens:** Generates the SOP and saves to the specified path. Skips Notion entirely.

### Example 4: Quick Diagram

```
/workflow:diagram "User signs up, verifies email, completes profile, gets welcome tour, starts first project"
```

**What happens:** Displays a Mermaid flowchart in chat with a step/decision/complexity summary. No file output, no Notion.

### Example 5: Diagram from Existing SOP

```
/workflow:diagram "Invoice Approval Process"
```

**What happens:** Looks up the SOP in Notion by name, extracts its steps, and generates a flowchart.

### Example 6: Save Diagram to File

```
/workflow:diagram "client onboarding" --output=diagrams/onboarding-flow.md
```

**What happens:** Generates the flowchart and saves a minimal Markdown file with the Mermaid diagram.

## Tips

- Start with a simple workflow to get familiar with the output format
- Use `--format=file` if you don't have Notion set up yet
- Run `/workflow:diagram` first for a quick visual, then `/workflow:document` for the full SOP
- Workflows with more than 20 steps will be truncated -- consider splitting into sub-workflows

## Troubleshooting

| Issue | Solution |
|-------|----------|
| MCP server not responding | Check `.mcp.json` configuration and API keys |
| Command not found | Verify plugin is installed in the correct directory |
| File not found error | Check the `--file` path is correct and accessible |
| Notion not saving | Verify Notion API key and workspace sharing permissions |

## Next Steps

1. Try the basic commands above
2. Explore the `skills/` folder for domain knowledge this plugin uses
3. Check `INSTALL.md` for advanced configuration options
