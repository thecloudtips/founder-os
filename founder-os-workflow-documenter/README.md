# founder-os-workflow-documenter

> **Plugin #28** -- Document Any Workflow in 10 Minutes: AI-Powered SOPs

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | Meta & Growth |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Intermediate |
| **Week** | 28 |

## What It Does

Transforms workflow descriptions into structured 7-section Standard Operating Procedures (SOPs) with Mermaid flowchart diagrams. Accepts input as inline text, file references, or interactive prompts. Outputs to local Markdown files and/or the "[FOS] Workflows" Notion database (Type="SOP").

## Requirements

### MCP Servers

- **Notion** (`@modelcontextprotocol/server-notion`) -- Store SOPs in a searchable database (required)
- **Filesystem** (`@modelcontextprotocol/server-filesystem`) -- Read input files and write SOP documents (required)

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/workflow:document` | Transform a workflow description into a structured 7-section SOP with Mermaid diagram |
| `/workflow:diagram` | Generate a Mermaid flowchart from a workflow description or existing SOP |

## Skills

- **workflow-documentation**: Decomposes workflow descriptions into structured components (steps, tools, handoffs, decisions, complexity scoring)
- **sop-writing**: Produces 7-section SOP documents with writing style enforcement, Mermaid diagram generation, and troubleshooting tables

## Agent Teams

This plugin does not use Agent Teams.

## Dependencies

This plugin has no dependencies on other Founder OS plugins.

## Blog Post

**Week 28**: "Document Any Workflow in 10 Minutes: AI-Powered SOPs"

Turn any process description into a professional SOP with step-by-step instructions, decision trees, and visual flowcharts.

## License

MIT
