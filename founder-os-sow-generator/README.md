# Founder OS: SOW Generator

**Plugin #14** | Pillar: Code Without Coding | Platform: Claude Code | Week 5

> From one project brief, get three ready-to-send SOW options — conservative, balanced, and ambitious — with risk scores, pricing, and a recommendation.

## What It Does

The SOW Generator reads a project brief (inline text, local file, or Notion page) and produces a complete, client-ready Statement of Work with three named scope packages. Each package covers deliverables, timeline, investment, assumptions, and risk profile — so the client can choose the right fit without you writing the same document three times.

The engine uses a competing hypotheses approach: three independent scope agents each interpret the brief from a different angle before risk and pricing agents evaluate every proposal. A synthesis lead scores the matrix and writes the final document. This prevents anchoring bias (no single agent anchors the others) and produces a defensible recommendation backed by explicit scoring.

Two modes for every command:

- **Default**: Fast single-agent SOW generation with no external dependencies
- **`--team`**: Full 6-agent competing-hypotheses pipeline for a more thorough, scored output

## Commands

| Command | Description |
|---------|-------------|
| `/sow:generate [brief]` | Generate a SOW from an inline brief or interactive interview |
| `/sow:from-brief [file-or-url]` | Load a brief from a local file or Notion page, then generate |

### Key Options

| Flag | Description |
|------|-------------|
| `--team` | Run the full 6-agent competing-hypotheses pipeline |
| `--client=NAME` | Client name for the SOW header |
| `--budget=AMOUNT` | Maximum budget constraint (e.g., `$75,000` or `75000`) |
| `--weeks=N` | Maximum timeline in weeks |
| `--output=PATH` | Output directory for the generated SOW file (default: `./sow-output/`) |

## Examples

```bash
# Quick SOW from an inline brief
/sow:generate "Build a customer portal with login, dashboard, and reporting for Acme Corp"

# Full pipeline with budget and timeline constraints
/sow:generate --team --client="TechCo" --budget=75000 --weeks=16

# Load a brief from a local Markdown file
/sow:from-brief ./briefs/acme-portal.md

# Load from Notion, override client name, save to specific folder
/sow:from-brief https://www.notion.so/acme/portal-brief-abc123 --client="Acme Corp" --output=./proposals/

# Full team pipeline from a local brief file
/sow:from-brief ./brief.md --team --output=./client-sows/

# Interactive mode — the command asks for all inputs
/sow:generate
```

## The 6-Agent Pipeline

When using `--team`, the pipeline runs in three phases:

```
Phase 1 — Parallel Hypothesis Generation
┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐
│  scope-agent-a  │  │  scope-agent-b  │  │  scope-agent-c  │
│  Conservative   │  │    Balanced     │  │    Ambitious    │
│  P90 · 20% buf  │  │  P75 · 10% buf  │  │  P60 · no buf   │
└────────┬────────┘  └────────┬────────┘  └────────┬────────┘
         └───────────────────┬┴───────────────────-┘
                             ↓ all proposals collected
Phase 2 — Parallel Analysis
              ┌──────────────┴──────────────┐
              │                             │
       ┌──────┴──────┐               ┌──────┴──────┐
       │  risk-agent │               │pricing-agent│
       │ Risk scoring│               │Cost + value │
       └──────┬──────┘               └──────┬──────┘
              └──────────────┬──────────────┘
                             ↓ risk + pricing data for all 3
Phase 3 — Synthesis
                     ┌───────────┐
                     │ sow-lead  │
                     │ Scoring   │
                     │ matrix +  │
                     │ final SOW │
                     └─────┬─────┘
                           ↓
              sow-[client]-[YYYY-MM-DD].md
```

Minimum 2 of 3 Phase 1 agents must succeed for the pipeline to continue. If exactly 2 succeed, the lead notes which agent failed and synthesizes from the remaining proposals.

## Skills

| Skill | Purpose |
|-------|---------|
| `scope-definition` | Scope framework, confidence levels (P60/P75/P90), effort estimation, deliverable definition, boundary-setting rules |
| `sow-writing` | SOW document structure, three-option format, client-facing language, pricing tables, payment terms |
| `risk-assessment` | 7-dimension risk framework, flag taxonomy (Low / Medium / High / Critical), mitigation library |

## MCP Requirements

| Server | Required | Purpose |
|--------|----------|---------|
| Filesystem | Yes | Read local brief files; write SOW output files |
| Notion | Optional | Load briefs from Notion pages; search historical SOWs for calibration; write SOW records to "Founder OS HQ - Deliverables" (Type="SOW") with Company + Deal relations |
| Google Drive | Optional | Store generated SOW Markdown files in Drive for client sharing |

## SOW Output Format

Each generated SOW is a single Markdown file (`sow-[client-slug]-[YYYY-MM-DD].md`) containing:

- **Cover page** — client name, project name, date, prepared by
- **Executive summary** — 2–3 sentence overview of the engagement
- **Option comparison table** — all three options side-by-side: scope, timeline, investment, risk profile, buffer, best-fit guidance
- **Three full SOW sections** — one per option (Conservative, Balanced, Ambitious), each with: scope of work, out-of-scope table, timeline and milestones, investment breakdown, assumptions, change management clause, payment and IP terms
- **Provider recommendation** — a direct, scored statement of which option is recommended and why
- **Next steps** — actions for the client after selecting an option

The template structure lives at `templates/sow-template.md`.

## Competing Hypotheses Pattern

Rather than generating one SOW and adjusting it, three independent scope agents each produce a genuinely different interpretation of the same brief. This prevents anchoring bias — no agent sees the others' work — and surfaces scope interpretations that a single pass would collapse into a single middle-ground answer. The risk and pricing agents then evaluate every proposal on the same dimensions, so the synthesis lead can produce a scoring matrix and a recommendation that is traceable to the inputs rather than a judgment call.

## Installation

See [INSTALL.md](INSTALL.md)

## Quick Start

See [QUICKSTART.md](QUICKSTART.md)
