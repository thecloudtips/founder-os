# Quick Start: SOW Generator

Get your first SOW in 60 seconds.

## Your First SOW (Default Mode)

No Notion setup required. Just describe the project inline:

```
/sow:generate "Build a customer portal with login, dashboard, and reporting for a SaaS company"
```

**Expected output:**

```
## SOW Generated

**Client**: SaaS Company
**Output**: ./sow-output/sow-saas-company-2026-02-24.md
**Options**: 3 (Foundation Package · Growth Package · Transformation Package)
**Recommended**: Growth Package (Option B)

### Option Summary
| Option | Timeline | Price | Risk |
|--------|----------|-------|------|
| Foundation Package | 10 weeks | $38,000 | Low |
| **Growth Package ✓** | 14 weeks | $54,000 | Medium |
| Transformation Package | 18 weeks | $72,000 | High |

_View the full SOW at ./sow-output/sow-saas-company-2026-02-24.md_
```

## Load a Brief from a File

If you already have a brief written up, point the command at it:

```
/sow:from-brief ./briefs/acme-portal.md
```

The command reads common brief fields automatically — client name, project description, budget, timeline, and priorities. A confirmation summary is shown before generation begins so you can verify what was extracted.

**Supported brief formats**: `.md`, `.txt`, `.pdf` (text layer), `.json`

**Brief fields the plugin looks for:**

```markdown
Client: Acme Corp
Budget: $60,000
Timeline: 12 weeks
Priorities: security, mobile-friendly, low maintenance

## Project Description

Build a self-service customer portal that allows clients to view invoices,
submit support tickets, and download usage reports.
```

Any fields not found in the file are treated as unconstrained — the plugin proceeds without them.

## Load a Brief from Notion

```
/sow:from-brief https://www.notion.so/your-workspace/brief-page-id
```

Requires the Notion MCP server to be installed and `NOTION_API_KEY` to be set. See [INSTALL.md](INSTALL.md) for setup.

## Full Pipeline Mode

Install the filesystem MCP server first (see [INSTALL.md](INSTALL.md)), then:

```
/sow:generate --team "Redesign onboarding for a fintech app"
```

In `--team` mode, 6 agents run across 3 phases:

1. **Phase 1 (parallel)**: Three scope agents each produce an independent proposal — conservative, balanced, and ambitious — without seeing each other's work
2. **Phase 2 (parallel)**: Risk agent scores all three proposals across 7 risk dimensions; pricing agent estimates cost and value-for-money for each
3. **Phase 3**: SOW lead builds a scoring matrix, selects the recommended option, and writes the final SOW document

This takes longer than default mode (typically 2–4 minutes) but produces a more defensible output: the recommendation is backed by a scoring matrix rather than a single judgment call.

## Common Scenarios

### Generate a SOW with budget and timeline constraints

```
/sow:generate --client="Acme Corp" --budget=50000 --weeks=12 "Build an e-commerce integration with Shopify and QuickBooks"
```

Options that exceed the budget or timeline are adjusted down and the change is noted in the output.

### Load a brief from Notion and run the full pipeline

```
/sow:from-brief https://www.notion.so/acme/portal-brief-abc123 --team --output=./proposals/
```

### Quick SOW for a client meeting (fast single-agent)

```
/sow:generate "Migrate a legacy PHP application to a React + Node.js stack"
```

Default mode is ready in under a minute — enough to walk a client through three options in a discovery call.

### Save the output to a specific folder

```
/sow:from-brief ./brief.md --output=./client-sows/acme/
```

Output directory is created automatically if it does not exist.

### Full team pipeline from a local brief file

```
/sow:from-brief ./briefs/fintech-onboarding.md --team --client="FinCo" --budget=80000
```

The `--client` and `--budget` flags override whatever values were extracted from the brief file.

### Interactive mode — no brief ready yet

```
/sow:generate
```

The command conducts a short discovery interview: client name, project description, key deliverables, budget, timeline, and priorities. Answer each prompt, and generation begins once the minimum required fields are filled.

## Understanding the Three Options

Every SOW output contains three named packages:

| Package | Confidence | Buffer | What it includes |
|---------|------------|--------|-----------------|
| **Conservative** | P90 | 20% | Core deliverables only. Well-defined scope, strict change control, lowest risk. Best for clients who need a fixed price and predictable delivery. |
| **Balanced** | P75 | 10% | Core deliverables plus the highest-value adjacent feature. Moderate risk, recommended for most engagements. |
| **Ambitious** | P60 | None | Full vision with stretch goals. Maximum client value, higher risk, assumes a flexible timeline and collaborative client. |

The recommended option is always called out explicitly — typically Balanced unless budget or timeline constraints make Conservative the only viable choice.

## Tips

- **Default mode is fast**: Use it for quick client discussions, proposal drafts, or situations where you need a starting point in under a minute
- **Team mode produces a defensible recommendation**: When the client will scrutinize the SOW or when the deal is large, the scoring matrix from `--team` mode gives you a traceable rationale
- **Add `--client` and `--budget` for realistic output**: Even in default mode, providing these flags produces a more grounded SOW with named deliverables and a meaningful price range
- **Historical SOWs in Notion improve calibration**: If the Notion MCP is configured and you have past SOWs in your workspace, the plugin searches for relevant examples and uses them to anchor scope and pricing estimates
- **The template file shows the full output structure**: `templates/sow-template.md` in the plugin directory shows every section of a complete SOW — useful for understanding what the plugin generates before running it for the first time
- **Brief quality drives SOW quality**: A brief with client name, clear deliverables, a budget range, and at least one priority produces a usable SOW in either mode. A one-sentence brief produces generic output that will need manual editing
