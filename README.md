# Founder OS

**32-namespace AI automation ecosystem for SMB founders, built on Claude Code.**

Stop drowning in email, meetings, and manual busywork. Founder OS gives you a full AI-powered command center — from inbox triage to client health dashboards to automated proposals — all running inside Claude Code.

---

## Install

```bash
# 1. Add the marketplace
claude plugin marketplace add thecloudtips/founder-os

# 2. Install the plugin
claude plugin install founder-os

# 3. Set your Notion API key (required for most commands)
#    Get yours at: https://www.notion.so/my-integrations
export NOTION_API_KEY=ntn_your_token_here
```

That's it. All 94 commands are now available as `/founder-os:<namespace>:<action>`.

---

## What's Included

**32 namespaces across 4 pillars:**

| Pillar | Namespaces | Focus |
|--------|------------|-------|
| Daily Work | inbox, briefing, prep, actions, review, followup, meeting, newsletter | Email, meetings, reviews |
| Code Without Coding | report, health, invoice, proposal, contract, sow, compete, expense | Reports, invoices, proposals |
| MCP & Integrations | notion, drive, slack, client, crm, morning, kb, linkedin | Notion, Drive, Slack, CRM |
| Meta & Growth | savings, prompt, workflow, workflow-doc, learn, goal, memory, intel | ROI, workflows, templates |

---

## Requirements

- Claude Code (latest)
- Node.js 18+
- Notion workspace + API key (free tier works)
- Google account + [gws CLI](https://github.com/nicholasgasior/gws) for Gmail/Calendar/Drive features

---

## Optional: Google Workspace

For email, calendar, and drive features, install and authenticate the gws CLI:

```bash
# Install gws (see gws docs for your platform)
gws auth login
```

---

## Optional: Notion HQ Databases

After installing, run the setup command inside Claude Code to create all 22 Notion databases:

```
/founder-os:setup:notion-hq
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
