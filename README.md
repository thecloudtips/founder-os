# Founder OS

**32-namespace AI automation ecosystem for SMB founders, built on Claude Code.**

Stop drowning in email, meetings, and manual busywork. Founder OS gives you a full AI-powered command center — from inbox triage to client health dashboards to automated proposals — all running inside Claude Code.

94 slash commands. 7 agent teams. 22 Notion databases. Zero coding required.

---

## Install

### Step 1: Add the Marketplace and Install

```bash
# Add the Founder OS marketplace
claude plugin marketplace add thecloudtips/founder-os

# Install the plugin
claude plugin install founder-os
```

That's it — the plugin is now installed globally. All 94 commands are available in any Claude Code project.

### Step 2: Set Your Notion API Key

Most commands need Notion access. Get your key at [notion.so/my-integrations](https://www.notion.so/my-integrations):

1. Click **"+ New integration"**
2. Name it **"Founder OS"**
3. Enable capabilities: **Read content**, **Update content**, **Insert content**
4. Copy the **Internal Integration Secret** (starts with `ntn_`)

Then add it to your shell profile so it persists:

```bash
# Add to ~/.zshrc (macOS) or ~/.bashrc (Linux)
export NOTION_API_KEY=ntn_your_token_here
```

Reload your shell: `source ~/.zshrc`

### Step 3: Set Up Notion Databases (Recommended)

Open Claude Code in any project and run:

```
/founder-os:setup:notion-hq
```

This creates 22 interconnected Notion databases — CRM, task management, content library, financial tracking, and more. The command is idempotent: if some databases already exist, it only creates the missing ones.

### Step 4: Verify

```
/founder-os:setup:verify
```

This checks all connections (Notion, Google, Filesystem) and reports pass/fail for each.

### Optional: Google Workspace

For email, calendar, and drive features (20 namespaces), install the [gws CLI](https://github.com/nicholasgasior/gws) and authenticate:

```bash
gws auth login
```

### Optional: Slack

For the Slack Digest namespace, set your bot token:

```bash
export SLACK_BOT_TOKEN=xoxb_your_token_here
```

### Upgrading

```bash
claude plugin marketplace remove founder-os-marketplace
claude plugin marketplace add thecloudtips/founder-os
claude plugin install founder-os
```

---

## How It Works

Founder OS is a single Claude Code plugin that installs via the standard marketplace system. Here's what happens under the hood:

### At Install Time

- Claude Code downloads the plugin from GitHub
- The plugin's `.mcp.json` auto-configures Notion and Filesystem MCP servers
- All 94 slash commands become available as `/founder-os:<namespace>:<action>`
- No files are created in your project directory

### On First Use

- **Memory Engine** — A local SQLite database (`.memory/memory.db`) is created automatically the first time a command uses memory. It stores cross-namespace context, learned preferences, and patterns. Commands work fine without it — if the DB is missing, memory features are silently skipped.

- **Intelligence Engine** — A separate SQLite database (`.intelligence/intelligence.db`) is created when the hooks system first logs an event. It powers adaptive behavior and pattern detection. Also optional — commands degrade gracefully without it.

- **Notion HQ** — The 22 Notion databases are created on-demand when you run `/founder-os:setup:notion-hq`. Individual commands also search for their required databases and work with whatever exists. You don't need all 22 databases to use specific namespaces.

### Data Storage

| What | Where | Created When |
|------|-------|-------------|
| Commands, skills, agents | Plugin install directory (managed by Claude Code) | At install |
| Notion databases (22) | Your Notion workspace | When you run `/founder-os:setup:notion-hq` |
| Memory store | `.memory/memory.db` in project root | First command that uses memory |
| Intelligence store | `.intelligence/intelligence.db` in project root | First intelligence event |
| File outputs (reports, exports) | `~/founder-os-workspace` (configurable) | When a command writes a file |

All data stays local or in your own Notion workspace. Nothing is sent to third-party servers.

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

Founder OS uses Notion as its data backbone. The `/founder-os:setup:notion-hq` command creates 22 interconnected databases:

| Category | Databases |
|----------|-----------|
| CRM | Companies (central hub), Contacts, Deals, Communications |
| Operations | Tasks, Meetings, Finance |
| Intelligence | Briefings, Knowledge Base, Research, Reports |
| Content | Content, Deliverables, Prompts |
| Growth | Goals, Milestones, Learnings, Weekly Insights, Workflows, Activity Log, Memory |

Companies is the central hub — all client-facing databases relate back to it. The setup command is idempotent: run it anytime to create missing databases without affecting existing ones.

---

## Requirements

| Requirement | Why | Required? |
|-------------|-----|-----------|
| **Claude Code** (latest) | Runs all commands | Yes |
| **Node.js 18+** | MCP servers (Notion, Filesystem) | Yes |
| **Notion API key** | Data backbone for 21 namespaces | Yes |
| **gws CLI** | Gmail, Calendar, Drive access | Optional (20 namespaces) |
| **Slack Bot Token** | Slack Digest namespace | Optional (1 namespace) |

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

# Teach the system a preference
/founder-os:memory:teach

# Check your goals
/founder-os:goal:check
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
