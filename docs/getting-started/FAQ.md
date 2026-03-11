# Founder OS — Frequently Asked Questions

## General

### Do I need all 32 plugins?

All 32 plugins are installed together (they share infrastructure), but you only use the ones you need. Unused plugins have zero overhead — they're just symlinked directories that Claude Code discovers on demand.

### What does Founder OS cost?

Founder OS itself is free and open source. You need:
- A Claude Code subscription (for the AI)
- A Notion account (free tier works, but Pro recommended for API limits)
- A Google Workspace or personal Gmail account (free)

### Is my data sent anywhere?

No. Everything runs locally on your machine. API calls go directly from your computer to Notion, Google, and Slack — Founder OS never routes your data through third-party servers.

### Can I use this with a team?

Yes. Each team member clones the repo and runs the installer with their own API keys. Everyone gets their own Notion HQ databases and Google authentication. Shared data happens through your existing Notion workspace.

## Setup

### Can I use Founder OS without Notion?

Partially. Notion is the backbone for 21 of 32 plugins. Without it, you can still use file-based plugins like Report Generator, Contract Analyzer, and LinkedIn Post Generator. Run `./install.sh --skip-notion` to install without Notion.

### What Google permissions does gws need?

- **Gmail**: Read and send emails (for inbox triage, follow-up tracking)
- **Calendar**: Read and create events (for meeting prep, daily briefing)
- **Google Drive**: Read and upload files (for document search, report storage)

You can revoke access anytime at https://myaccount.google.com/permissions.

### Can I change the workspace directory after installation?

Yes. Update `WORKSPACE_DIR` in `.env` and re-run `./install.sh`. The installer updates the MCP configuration automatically.

### The installer failed midway — is it safe to re-run?

Yes. The installer is idempotent — it detects what's already done and skips completed steps. Re-running is always safe.

## Plugins

### Can I add custom plugins?

Yes. Create a new directory following the plugin format (see `_templates/plugin-scaffold/`), add a `.claude-plugin/plugin.json` manifest, and symlink it into `.claude/plugins/`.

### How do I disable a specific plugin?

Remove its symlink from `.claude/plugins/`:
```bash
rm .claude/plugins/founder-os-[plugin-name]
```

Re-running `./install.sh` will re-link it. To permanently exclude a plugin, remove it before running the installer or delete its symlink after.

### What are the four pillars?

| Pillar | Focus | Plugins |
|--------|-------|---------|
| Daily Work | Email, meetings, reviews | #01-#08 |
| Code Without Coding | Reports, invoices, contracts | #09-#16 |
| MCP & Integrations | Notion, Drive, Slack, CRM | #17-#24 |
| Meta & Growth | ROI, workflows, templates | #25-#30 |
| Infrastructure | Memory, adaptive intelligence | #31-#32 |

> **Note**: Plugins #31 (Memory Hub) and #32 (Adaptive Intel) are infrastructure plugins that enhance all other plugins. They are installed alongside the four-pillar plugins but operate transparently in the background.

## Updating

### How do I update Founder OS?

```bash
git pull
./install.sh
```

The installer picks up new plugins, updated configurations, and any new Notion databases.

### What about my existing Notion databases?

If you had older plugin-specific Notion databases (before the HQ consolidation), they're preserved. Plugins search for HQ databases first, then fall back to legacy names. See `_infrastructure/notion-hq/MIGRATION.md` for details.

## Troubleshooting

### Where do I get help?

1. Check `docs/getting-started/TROUBLESHOOTING.md` for common issues
2. Run `./install.sh --verify` to diagnose problems
3. Run `/setup:verify` inside Claude Code for detailed checks
