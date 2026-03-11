# Founder OS — Frequently Asked Questions

## General

### Do I need all 32 namespaces?

All 32 namespaces are part of the single Founder OS plugin, but you only use the ones you need. Unused namespaces have zero overhead — they are just command and skill files on disk that Claude Code discovers on demand. No extra processes, no extra memory.

### What does Founder OS cost?

Founder OS itself is free and open source. You need:
- A Claude Code subscription (for the AI)
- A Notion account (free tier works, but Pro recommended for API limits)
- A Google Workspace or personal Gmail account (free) — optional

### Is my data sent anywhere?

No. Everything runs locally on your machine. API calls go directly from your computer to Notion, Google, and Slack — Founder OS never routes your data through third-party servers. The plugin files, memory database, and intelligence database all stay on your machine. Notion data stays in your Notion workspace.

### Can I use this with a team?

Yes. Each team member installs the plugin with their own API keys. Everyone gets their own Notion HQ databases and Google authentication. Shared data happens through your existing Notion workspace.

### Where does the plugin live on my machine?

The plugin is installed to Claude Code's plugin cache at `~/.claude/plugins/cache/`. You don't need to manage this directory — Claude Code handles it. Your project directories stay clean.

## Setup

### How do I install Founder OS?

```bash
claude plugin marketplace add thecloudtips/founder-os
claude plugin install founder-os
export NOTION_API_KEY=ntn_your_token_here
```

Then inside Claude Code: `/founder-os:setup:notion-hq`

See the [SETUP-GUIDE.md](SETUP-GUIDE.md) for the full walkthrough.

### Can I use Founder OS without Notion?

Partially. Notion is the backbone for 21 of 32 namespaces. Without it, you can still use file-based namespaces like Report Generator, Contract Analyzer, and LinkedIn Post Generator. Just skip the `NOTION_API_KEY` setup and the `/founder-os:setup:notion-hq` command.

### What Google permissions does gws need?

- **Gmail**: Read and send emails (for inbox triage, follow-up tracking)
- **Calendar**: Read and create events (for meeting prep, daily briefing)
- **Google Drive**: Read and upload files (for document search, report storage)

You can revoke access anytime at https://myaccount.google.com/permissions.

### Do I need to set up anything in my project directory?

No. The plugin installs globally and works in any Claude Code project. The only local files that may appear are:
- `.memory/memory.db` — created automatically on first memory use
- `.intelligence/intelligence.db` — created automatically on first intelligence event

Both are optional and commands work fine without them.

### What are the Notion HQ databases?

Founder OS uses 22 interconnected Notion databases as its data backbone. Running `/founder-os:setup:notion-hq` creates all of them in your workspace with proper schemas, relations, and a Command Center dashboard. Companies is the central hub — all client-facing databases relate back to it.

### Is the Notion HQ setup required?

No, but recommended. Individual commands search for their required databases and work with whatever exists. You can use specific namespaces without the full HQ. But for the best experience with cross-namespace features (like client context pulling from CRM, emails, meetings, and invoices), set up the full HQ.

### What if the Notion HQ setup fails halfway?

Re-run `/founder-os:setup:notion-hq`. It's idempotent — it checks which databases already exist and only creates the missing ones. Safe to run as many times as needed.

## Memory & Intelligence

### What is the Memory Engine?

A local SQLite database that stores cross-namespace context, learned preferences, and behavioral patterns. Before any command runs, relevant memories are injected as context. After execution, observations are logged and patterns promoted to memories when confidence is high.

It initializes automatically on first use. If the database is missing or corrupt, commands skip memory features silently — nothing breaks.

### What is the Intelligence Engine?

A separate SQLite database that captures structured events from command execution. It powers adaptive behavior, pattern detection, and self-healing. Like memory, it initializes on first use and commands work fine without it.

### Can I reset the memory or intelligence data?

Yes:
- Memory: `/founder-os:memory:forget` removes specific memories, or delete `.memory/memory.db` to start fresh
- Intelligence: `/founder-os:intel:reset` resets patterns, or delete `.intelligence/intelligence.db`

## Commands & Namespaces

### How do I invoke a command?

All commands use the format `/founder-os:namespace:action`. For example:
- `/founder-os:inbox:triage` — triage your inbox
- `/founder-os:client:load` — load client context
- `/founder-os:report:generate` — generate a report

### What are agent teams?

Seven namespaces include multi-agent teams for complex tasks. Use the `--team` flag to activate them. For example, `/founder-os:inbox:triage --team` runs a full pipeline with Classifier, Drafter, and Reviewer agents instead of a single-agent pass.

### What are the four pillars?

| Pillar | Focus | Namespaces |
|--------|-------|---------|
| Daily Work | Email, meetings, reviews | inbox, briefing, prep, actions, review, followup, meeting, newsletter |
| Code Without Coding | Reports, invoices, contracts | report, health, invoice, proposal, contract, sow, compete, expense |
| MCP & Integrations | Notion, Drive, Slack, CRM | notion, drive, slack, client, crm, morning, kb, linkedin |
| Meta & Growth | ROI, workflows, templates | savings, prompt, workflow, workflow-doc, learn, goal, memory, intel |

### Can I add custom commands?

Yes. The plugin source is on GitHub. Fork the repo, add a new markdown file under `commands/[namespace]/[action].md` following the existing command format, and install from your fork.

## Updating

### How do I update Founder OS?

```bash
claude plugin marketplace remove founder-os-marketplace
claude plugin marketplace add thecloudtips/founder-os
claude plugin install founder-os
```

Your Notion databases, memory store, and intelligence data are preserved — they live outside the plugin.

### What about my existing Notion databases?

If you had older Notion databases (before the HQ consolidation), they're preserved. Namespaces search for HQ databases first (`[FOS] <Name>`), then fall back to legacy names.

## Troubleshooting

### Where do I get help?

1. Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
2. Run `/founder-os:setup:verify` inside Claude Code for detailed checks
3. Open an issue on [GitHub](https://github.com/thecloudtips/founder-os/issues)
