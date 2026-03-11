# Quick Start: founder-os-proposal-automator

> Generates professional client proposals with 7 sections and 3 pricing packages

## Overview

**Plugin #12** | **Pillar**: Code Without Coding | **Platform**: Claude Code

Create polished client proposals from briefs and scope notes, with optional CRM context enrichment. Each proposal includes a Cover Letter, Executive Summary, Understanding & Approach, Scope of Work, Timeline, 3 Pricing Packages, and Terms.

### What This Plugin Does

- Generates 7-section professional proposals in Markdown
- Creates 3 pricing packages (good-better-best) with comparison tables
- Produces SOW-compatible brief files for `/sow:from-brief` handoff
- Optionally enriches proposals with CRM context from Notion

## Available Commands

| Command | Description |
|---------|-------------|
| `/proposal:create [client]` | Generate a proposal interactively or from a brief file |
| `/proposal:from-brief [file-or-url]` | Generate a proposal from an existing brief |

## Usage Examples

### Example 1: Create a proposal interactively

```
/proposal:create Acme Corp
```

**What happens:**
Claude searches Notion CRM for Acme Corp context, asks you about the project scope, deliverables, and timeline, then generates a complete proposal with 3 pricing packages. Saves to `proposals/proposal-acme-corp-2026-03-05.md`.

### Example 2: Create a proposal from a brief

```
/proposal:from-brief briefs/project-alpha.md
```

**What happens:**
Claude reads the brief file, extracts client name, project description, deliverables, and constraints, then generates a full proposal. Also produces a SOW-compatible brief at `proposals/brief-[client]-[date].md`.

### Example 3: Create a proposal from a Notion page

```
/proposal:from-brief https://www.notion.so/your-brief-page --client="TechStart"
```

**What happens:**
Claude fetches the Notion page content, uses it as the project brief, and generates a proposal for TechStart.

### Example 4: Custom output directory

```
/proposal:create "NaluForge" --output=./client-proposals/
```

**What happens:**
Same as Example 1, but saves files to the `client-proposals/` directory instead of the default `proposals/`.

## Tips

- Always review the generated pricing — adjust numbers to match your actual rates and the client's budget
- Use `/sow:from-brief` on the generated brief file to create a detailed SOW from the same proposal
- If Notion CRM has data on the client, the Cover Letter and Understanding sections will be personalized automatically
- The Professional (middle) package is always marked as recommended — adjust if needed

## Related Plugins

This plugin connects with:
- **#14 SOW Generator**: Use the generated brief file with `/sow:from-brief` for detailed SOW creation
- **#20 Client Context Loader**: Reads same CRM Pro databases for deeper client dossiers
- **#13 Contract Analyzer**: Proposal terms can reference standard terms from contract analysis

## Troubleshooting

| Issue | Solution |
|-------|----------|
| MCP server not responding | Check `.mcp.json` configuration and API keys |
| Command not found | Verify plugin is installed in the correct directory |
| No CRM context found | Ensure Notion integration has access to CRM Pro databases |
| Brief file not found | Check the file path — relative to current working directory |

## Next Steps

1. Try `/proposal:create` with a client name
2. Review the generated proposal and adjust pricing
3. Use `/sow:from-brief` on the generated brief for a detailed SOW
4. Check `INSTALL.md` for advanced MCP configuration
