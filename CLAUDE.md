# CLAUDE.md

This file provides guidance to Claude Code when working with Founder OS plugins.

## Project Overview

Founder OS is a 32-plugin AI automation ecosystem for SMB founders, built on Claude Code using the official Anthropic plugin format. Each plugin is a working tool with slash commands, skills, and Notion HQ integration.

## Architecture

### Plugin Format (Anthropic-compatible)

Every plugin follows this structure:
```
founder-os-[plugin-name]/
├── .claude-plugin/
│   └── plugin.json           # Manifest
├── .mcp.json                 # MCP server connections
├── commands/                 # Slash commands (markdown)
├── skills/
│   └── [skill-name]/
│       └── SKILL.md          # Domain knowledge (one dir per skill)
├── teams/                    # Agent Teams (Priority 5 only)
│   ├── config.json
│   └── agents/*.md
├── tests/
│   └── integration-test-plan.md
├── INSTALL.md
├── QUICKSTART.md
└── README.md
```

### Four Pillars

| Pillar | Emoji | Plugins | Focus |
|--------|-------|---------|-------|
| Daily Work | 📧 | #01-#08 | Email, meetings, reviews |
| Code Without Coding | 🛠️ | #09-#16 | Reports, invoices, contracts |
| MCP & Integrations | 🔌 | #17-#24 | Notion, Drive, Slack, CRM |
| Meta & Growth | 📈 | #25-#32 | ROI, workflows, templates, memory, intelligence |

### Platform

All 32 plugins run on **Claude Code**. The `"platform": "claude-code"` field in each plugin.json confirms this.

### Agent Teams Patterns (Priority 5 plugins)

| Pattern | Used By | How It Works |
|---------|---------|--------------|
| Pipeline | #01 Inbox Zero, #09 Report Gen | Sequential: Input → Agent A → Agent B → Output |
| Parallel Gathering | #02 Daily Briefing, #03 Meeting Prep, #20 Client Context | All agents fetch simultaneously, lead merges |
| Pipeline + Batch | #11 Invoice Processor | Pipeline per item, batch across items |
| Competing Hypotheses | #14 SOW Generator | Multiple agents propose, lead synthesizes |

### Autonomous Spectrum

Plugins operate at different autonomy levels:

| Level | Trigger | Examples |
|-------|---------|---------|
| Interactive | User runs command | All 32 plugins (default) |
| Scheduled | Cron/timer | P02, P05, P06, P10, P18, P19, P21, P22, P29 (via `--schedule`) |
| Workflow | P27 orchestration | Any plugin via `/workflow:create` |

## MCP Servers & External Tools

Plugins use these MCP servers and tools (install in priority order):

1. **Notion** MCP (21 plugins) - CRM backbone, task tracking, output storage
2. **gws CLI** (20 plugins) - Gmail, Calendar, and Drive access via `gws` CLI tool. Install once, authenticate with `gws auth login`. No per-plugin config needed.
3. **Filesystem** MCP (8 plugins) - Local file processing, document generation
4. **Slack** MCP (2 plugins) - Team communication digests
5. **Web Search** MCP (1 plugin) - Competitive research

### MCP Package Names
- Notion: `@modelcontextprotocol/server-notion`
- Filesystem: `@modelcontextprotocol/server-filesystem`
- Gmail/Calendar/Drive: **Use `gws` CLI** (not MCP servers). See `_infrastructure/gws-skills/`.

## Key Decisions

| Topic | Decision |
|-------|----------|
| CRM | Notion (not HubSpot/Pipedrive) |
| Voice transcription | Whisper (local, free, privacy-first) |
| Morning sync tools | Gmail + Calendar + Notion + Slack + Drive |
| Time savings tracking | Pre-defined task type estimates (not manual input) |
| Client health metrics | 5 scores 0-100: contact, response, tasks, payment, sentiment |

## Plugin Quick Reference (all 32 plugins)

Each plugin's own files (SKILL.md, commands/, README) contain full implementation details. Read those when working with a specific plugin.

| # | Plugin | Folder | Pattern | Required Tools | HQ DB |
|---|--------|--------|---------|---------------|-------|
| 01 | Inbox Zero | `founder-os-inbox-zero/` | Pipeline | gws (Gmail) | Tasks (Email Task), Content (Email Draft) |
| 02 | Daily Briefing | `founder-os-daily-briefing-generator/` | Parallel Gathering | gws (Calendar, Gmail), Notion | Briefings (Daily Briefing) |
| 03 | Meeting Prep | `founder-os-meeting-prep-autopilot/` | Parallel Gathering | gws (Calendar, Gmail, Drive), Notion | Meetings |
| 04 | Action Items | `founder-os-action-item-extractor/` | None | Notion | Tasks (Action Item) |
| 05 | Weekly Review | `founder-os-weekly-review-compiler/` | None | gws (Calendar, Gmail), Notion | Briefings (Weekly Review) |
| 06 | Follow-Up Tracker | `founder-os-follow-up-tracker/` | None | gws (Gmail, Calendar), Notion | Tasks (Follow-Up) |
| 07 | Meeting Intel | `founder-os-meeting-intelligence-hub/` | None | Notion, Filesystem | Meetings |
| 08 | Newsletter Engine | `founder-os-newsletter-draft-engine/` | None | WebSearch, Filesystem | Content (Newsletter), Research (Newsletter Research) |
| 09 | Report Generator | `founder-os-report-generator/` | Pipeline | Filesystem, Notion | Reports (Business Report) |
| 10 | Client Health | `founder-os-client-health-dashboard/` | None | gws (Gmail, Calendar), Notion | Companies (health props) |
| 11 | Invoice Processor | `founder-os-invoice-processor/` | Pipeline + Batch | Filesystem, Notion | Finance (Invoice) |
| 12 | Proposal Automator | `founder-os-proposal-automator/` | None | Filesystem, Notion | Deliverables (Proposal) |
| 13 | Contract Analyzer | `founder-os-contract-analyzer/` | None | Filesystem | Deliverables (Contract) |
| 14 | SOW Generator | `founder-os-sow-generator/` | Competing Hypotheses | Filesystem, Notion | Deliverables (SOW) |
| 15 | Competitive Intel | `founder-os-competitive-intel-compiler/` | None | WebSearch, Filesystem | Research (Competitive Analysis) |
| 16 | Expense Report | `founder-os-expense-report-builder/` | None | Filesystem, Notion | Reports (Expense Report), Finance (reads) |
| 17 | Notion Command Center | `founder-os-notion-command-center/` | None | Notion | (stateless) |
| 18 | Drive Brain | `founder-os-google-drive-brain/` | None | gws (Drive), Notion | Activity Log |
| 19 | Slack Digest | `founder-os-slack-digest-engine/` | None | Slack | Briefings (Slack Digest) |
| 20 | Client Context | `founder-os-client-context-loader/` | Parallel Gathering | gws (Gmail, Calendar, Drive), Notion | Companies (dossier props) |
| 21 | CRM Sync | `founder-os-crm-sync-hub/` | None | gws (Gmail, Calendar), Notion | Communications |
| 22 | Morning Sync | `founder-os-multi-tool-morning-sync/` | None | gws (Gmail, Calendar), Notion | Briefings (Morning Sync) |
| 23 | Knowledge Base | `founder-os-knowledge-base-qa/` | None | Notion | Knowledge Base |
| 24 | LinkedIn Post | `founder-os-linkedin-post-generator/` | None | Filesystem | Content (LinkedIn Post) |
| 25 | Time Savings | `founder-os-time-savings-calculator/` | None | Notion, Filesystem | Reports (ROI Report) |
| 26 | Prompt Library | `founder-os-team-prompt-library/` | None | Notion | Prompts |
| 27 | Workflow Automator | `founder-os-workflow-automator/` | None | Filesystem | Workflows (Execution) |
| 28 | Workflow Documenter | `founder-os-workflow-documenter/` | None | Notion, Filesystem | Workflows (SOP) |
| 29 | Learning Log | `founder-os-learning-log-tracker/` | None | Notion | Learnings, Weekly Insights |
| 30 | Goal Tracker | `founder-os-goal-progress-tracker/` | None | Notion | Goals, Milestones |
| 31 | Memory Hub | `founder-os-memory-hub/` | None | Notion | Memory |
| 32 | Adaptive Intel | `founder-os-adaptive-intel/` | None | Notion | Intelligence |

### Plugin Dependencies (chained plugins)
```
#01 Inbox Zero -> #06 Follow-Up Tracker
#07 Voice Note -> #04 Action Item Extractor
#11 Invoice Processor -> #16 Expense Report Builder
#12 Proposal Automator -> #14 SOW Generator
#20 Client Context <-> #21 CRM Sync <-> #10 Client Health Dashboard
#27 Workflow Automator -> chains ANY plugins
```

## Infrastructure Commands

Shared commands that live under `_infrastructure/`. Discovered via this section (not via plugin manifests).

| Command | File | Description |
|---------|------|-------------|
| `/context:setup` | `_infrastructure/context/commands/context-setup.md` | Set up business context files via guided interview |
| `/audit:scan` | `_infrastructure/automation-audit/commands/audit-scan.md` | Scan plugin deployment and coverage |
| `/audit:report` | `_infrastructure/automation-audit/commands/audit-report.md` | Generate detailed automation scorecard |

## Conventions

- Plugin folders: `founder-os-[kebab-case-name]/`
- Slash commands: `/namespace:action` (e.g., `/inbox:triage`, `/client:load`)
- Skills are markdown files describing domain knowledge
- Commands are markdown files describing slash command behavior
- Agent definitions are markdown files with role, tools, and instructions

### Universal Plugin Patterns (apply to ALL plugins)
- **HQ DB discovery** — search "[FOS] [Name]" first, then "Founder OS HQ - [Name]", then plugin-specific legacy DB name (backward compat)
- **No lazy DB creation** — databases are pre-created in the HQ template; only fall back to lazy creation for non-HQ users
- **Type column** — every write to a merged DB MUST include the correct Type value (e.g., Type="Email Task" for P01 → Tasks DB)
- **Company relation** — populate when client context is available (email domain match, user input, CRM lookup)
- `${CLAUDE_PLUGIN_ROOT}` for all file paths in plugin markdown (portability)
- Graceful degradation — optional MCP sources return `status: "unavailable"`, never error
- Dual-mode commands — default fast single-agent mode + `--team` flag for full agent pipeline
- Idempotent re-runs — update existing output, never duplicate; add Type to compound keys for merged DBs
- `status: "complete"` standardized across all agent outputs
- **Business context loading** — all 32 plugins check `_infrastructure/context/active/` for business context files at command start. See `_infrastructure/context/SKILL.md`.
- **Scheduling support** — 9 plugins accept `--schedule "expression"` flag for recurring execution. Generates P27 workflows automatically. Supported: P02, P05, P06, P10, P18, P19, P21, P22, P29. See `_infrastructure/scheduling/SKILL.md`.
- **Memory integration** — all 32 plugins inject relevant memories at start (Step 0) and log observations at end (Final step). See `_infrastructure/memory/SKILL.md`.

## Memory Engine

Cross-plugin shared memory with adaptive behavior. Two components:

- **Infrastructure** (`_infrastructure/memory/`): 3 shared skills — core memory API, context injection, pattern detection
- **Plugin** (`founder-os-memory-hub/`): User-facing commands `/memory:show`, `/memory:teach`, `/memory:forget`, `/memory:sync`
- **Notion DB**: `[FOS] Memory` in HQ template — syncs with local SQLite store

**How it works**: Before any plugin runs, the context-injection skill queries the local memory store and injects the top 5 relevant memories. After execution, the pattern-detection skill logs observations and promotes patterns to memories when confidence reaches threshold. Auto-adaptations apply after 3+ confirmations and notify the user.

**Local store**: `.memory/memory.db` (SQLite + HNSW). Auto-initializes on first use.

## Notion HQ Template

The Founder OS HQ is a consolidated Notion workspace template with 22 interconnected databases. CRM Companies is the central hub — all client-facing databases relate back to it.

### Workspace Structure
```
Founder OS HQ
├── Command Center (Dashboard)
├── CRM: Companies, Contacts, Deals, Communications
├── Operations: Tasks, Meetings, Finance
├── Intelligence: Briefings, Knowledge Base, Research, Reports
├── Content & Deliverables: Content, Deliverables, Prompts
└── Growth & Meta: Goals, Milestones, Learnings, Weekly Insights, Workflows, Activity Log, Memory
```

### Database Consolidation Map

| Consolidated DB | Merges From | Type Values |
|----------------|-------------|-------------|
| Companies | P10 Health Scores + P20 Dossiers (absorbed as properties) | — |
| Tasks | P01 Action Items + P04 Tasks + P06 Follow-Ups | Email Task, Action Item, Follow-Up |
| Meetings | P03 Prep Notes + P07 Analyses (shared Event ID) | — |
| Finance | P11 Invoices + P16 Expenses | Invoice, Expense |
| Briefings | P02 Daily + P05 Weekly + P19 Slack + P22 Morning | Daily Briefing, Weekly Review, Slack Digest, Morning Sync |
| Knowledge Base | P23 Sources + Queries | Source, Query |
| Research | P08 Newsletter + P15 Competitive | Newsletter Research, Competitive Analysis |
| Reports | P09 Business + P16 Expense + P25 ROI | Business Report, Expense Report, ROI Report |
| Content | P01 Drafts + P08 Newsletters + P24 LinkedIn | Email Draft, Newsletter, LinkedIn Post |
| Deliverables | P12 Proposals + P13 Contracts + P14 SOWs | Proposal, Contract, SOW |
| Workflows | P27 Executions + P28 SOPs | Execution, SOP |

### Setup Files
- Install guide: `_infrastructure/notion-hq/INSTALL.md`
- Migration guide: `_infrastructure/notion-hq/MIGRATION.md`
