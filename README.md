# Founder OS

**32-namespace AI automation ecosystem for SMB founders, built on Claude Code.**

Stop drowning in email, meetings, and manual busywork. Founder OS gives you a full AI-powered command center — from inbox triage to client health dashboards to automated proposals — all running inside Claude Code.

94 slash commands. 7 agent teams. 22 Notion databases. Zero coding required.

---

## Install

```bash
# 1. Remove any previous marketplace (if upgrading)
claude plugin marketplace remove founder-os-marketplace

# 2. Add the marketplace
claude plugin marketplace add thecloudtips/founder-os

# 3. Install the plugin
claude plugin install founder-os
```

### Configure

```bash
# Set your Notion API key (required for most commands)
# Get yours at: https://www.notion.so/my-integrations
export NOTION_API_KEY=ntn_your_token_here
```

Add the export to your `~/.zshrc` or `~/.bashrc` so it persists across sessions.

### Verify

Open Claude Code in any project and type `/founder-os:` — you should see all available commands in autocomplete.

---

## What's Included

### Pillar 1: Daily Work

Automate the tasks that eat your morning before real work starts.

| Namespace | Commands | What It Does |
|-----------|----------|-------------|
| `inbox` | triage, drafts-approved | AI-powered email triage — categorize, prioritize, draft replies |
| `briefing` | briefing, review | Daily briefing from Gmail, Calendar, Notion, and Slack |
| `prep` | prep, today | Meeting prep with attendee research, agenda, and talking points |
| `actions` | extract, extract-file | Pull action items from meeting notes or documents |
| `review` | review | Weekly review aggregating accomplishments and blockers |
| `followup` | check, nudge, remind | Track follow-ups and auto-generate nudge emails |
| `meeting` | analyze, intel | Post-meeting analysis with sentiment and key decisions |
| `newsletter` | draft, newsletter, outline, research | Research topics, outline, and draft newsletters |

### Pillar 2: Code Without Coding

Generate business documents that used to take hours.

| Namespace | Commands | What It Does |
|-----------|----------|-------------|
| `report` | from-template, generate | Generate business reports from templates or freeform |
| `health` | report, scan | Client health dashboard — contact frequency, payment, sentiment |
| `invoice` | batch, process | Process invoices from files, extract line items to Notion |
| `proposal` | create, from-brief | Generate proposals from briefs with scope, timeline, pricing |
| `contract` | analyze, compare | Analyze contracts for risks, compare versions |
| `sow` | from-brief, generate | Generate statements of work with deliverables and milestones |
| `compete` | matrix, research | Competitive intelligence — research competitors, build matrices |
| `expense` | report, summary | Expense reports from receipts and invoices |

### Pillar 3: MCP & Integrations

Connect your tools into a unified command center.

| Namespace | Commands | What It Does |
|-----------|----------|-------------|
| `notion` | create, query, template, update | Direct Notion operations — create pages, query databases |
| `drive` | ask, organize, search, summarize | Search, summarize, and organize Google Drive files |
| `slack` | catch-up, digest | Slack digest — catch up on channels you missed |
| `client` | brief, load | Load full client context — emails, meetings, deals, history |
| `crm` | context, sync-email, sync-meeting | Sync Gmail and Calendar data into Notion CRM |
| `morning` | quick, sync | Morning sync — Gmail + Calendar + Notion + Slack in one command |
| `kb` | ask, find, index | Knowledge base — index documents, search with natural language |
| `linkedin` | from-doc, post, variations | Draft LinkedIn posts from documents or scratch |

### Pillar 4: Meta & Growth

Track ROI, build workflows, and keep learning.

| Namespace | Commands | What It Does |
|-----------|----------|-------------|
| `savings` | configure, monthly-roi, quick, weekly | Track time saved per automation, calculate monthly ROI |
| `prompt` | add, get, list, optimize, share | Prompt library — store, optimize, and share prompts |
| `workflow` | create, edit, list, run, schedule, status | Build multi-step workflows chaining any namespace |
| `workflow-doc` | diagram, document | Document workflows as SOPs with diagrams |
| `learn` | log, search, weekly | Learning log — capture insights, search past learnings |
| `goal` | check, close, create, report, update | Goal tracking with milestones and progress reports |
| `memory` | forget, show, sync, teach | Cross-namespace memory — teach preferences, recall context |
| `intel` | approve, config, healing, patterns, reset, status | Intelligence engine — adaptive behavior and pattern detection |

### Infrastructure

| Namespace | Commands | What It Does |
|-----------|----------|-------------|
| `setup` | notion-hq, verify | One-command Notion workspace setup + health check |

---

## Agent Teams

Seven namespaces include full AI agent teams for complex multi-step tasks. Use the `--team` flag to activate them.

| Team | Pattern | Agents | Use Case |
|------|---------|--------|----------|
| Inbox Zero | Pipeline | Classifier → Drafter → Reviewer | High-volume email processing |
| Daily Briefing | Parallel Gathering | Gmail + Calendar + Notion + Slack agents | Comprehensive morning briefing |
| Meeting Prep | Parallel Gathering | Attendee + History + Agenda agents | Deep meeting preparation |
| Client Context | Parallel Gathering | Email + Calendar + CRM + Drive agents | Full client dossier |
| Invoice Processor | Pipeline + Batch | Extractor → Validator → Logger | Bulk invoice processing |
| Report Generator | Pipeline | Data Collector → Analyzer → Writer | Complex business reports |
| SOW Generator | Competing Hypotheses | Multiple proposal agents → Synthesizer | Best-of-breed SOW creation |

---

## Notion HQ

Founder OS uses Notion as its data backbone. After installing, create all 22 interconnected databases with one command inside Claude Code:

```
/founder-os:setup:notion-hq
```

This creates a full workspace with CRM, task management, content library, financial tracking, and more — all cross-linked with Companies as the central hub.

---

## Requirements

- **Claude Code** (latest version)
- **Node.js 18+**
- **Notion workspace + API key** (free tier works) — [Get your key](https://www.notion.so/my-integrations)

### Optional

- **Google account + [gws CLI](https://github.com/nicholasgasior/gws)** — for Gmail, Calendar, and Drive features (20 namespaces)
- **Slack Bot Token** — for Slack Digest (`slack` namespace)

---

## Quick Start Commands

After installing, try these inside Claude Code:

```bash
# Get a morning briefing
/founder-os:morning:sync

# Triage your inbox
/founder-os:inbox:triage

# Prep for your next meeting
/founder-os:prep:today

# Check client health
/founder-os:health:scan

# Generate a report
/founder-os:report:generate
```

---

## Documentation

| Guide | Description |
|-------|-------------|
| [SETUP-GUIDE.md](docs/getting-started/SETUP-GUIDE.md) | Detailed setup walkthrough |
| [FAQ.md](docs/getting-started/FAQ.md) | Common questions |
| [TROUBLESHOOTING.md](docs/getting-started/TROUBLESHOOTING.md) | Fixes for common issues |

---

## License

MIT
