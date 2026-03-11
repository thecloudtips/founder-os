# Founder OS

**32-plugin AI automation ecosystem for SMB founders, built on Claude Code.**

Stop drowning in email, meetings, and manual busywork. Founder OS gives you a full AI-powered command center — from inbox triage to client health dashboards to automated proposals — all running inside Claude Code.

---

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/your-org/founder-os.git
cd founder-os

# 2. Set up your environment
cp .env.example .env
# Edit .env with your Notion token and other credentials

# 3. Run the installer
./install.sh
```

That's it. Follow the prompts in `./install.sh` to authenticate gws (Gmail/Calendar/Drive) and connect Notion.

---

## What's Included

**32 plugins across 4 pillars:**

| Pillar | Plugins | Focus |
|--------|---------|-------|
| Daily Work | #01–#08 | Inbox zero, meeting prep, weekly reviews |
| Code Without Coding | #09–#16 | Reports, invoices, proposals, contracts |
| MCP & Integrations | #17–#24 | Notion, Drive, Slack, CRM sync |
| Meta & Growth | #25–#32 | ROI tracking, workflows, templates, memory |

Each plugin ships with:
- Slash commands (e.g., `/inbox:triage`, `/client:load`)
- INSTALL.md, QUICKSTART.md, README.md
- Notion HQ database integration

---

## Documentation

| Guide | Description |
|-------|-------------|
| [SETUP-GUIDE.md](docs/getting-started/SETUP-GUIDE.md) | Full setup walkthrough, MCP configuration, Notion HQ install |
| [FAQ.md](docs/getting-started/FAQ.md) | Common questions and answers |
| [TROUBLESHOOTING.md](docs/getting-started/TROUBLESHOOTING.md) | Fixes for common issues |

---

## Requirements

- Claude Code (latest)
- Node.js 18+
- A Notion workspace (free tier works)
- Google account (for Gmail/Calendar/Drive plugins)

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

*Built with Claude Code by the Founder OS team.*
