# Founder OS Setup (P00)

Infrastructure plugin providing installation and maintenance commands for the Founder OS ecosystem.

## Commands

| Command | Description |
|---------|-------------|
| `/setup:notion-hq` | Create all 22 Notion HQ databases automatically |
| `/setup:verify` | Run health checks on the installation |

## When to Use

- **First install**: Run `./install.sh` from the repo root — it handles everything including invoking `/setup:notion-hq`.
- **Manual Notion setup**: If the installer's automated Notion step fails, run `/setup:notion-hq` directly in Claude Code.
- **Health check**: Run `/setup:verify` anytime to check integration status.
- **After updates**: Run `git pull && ./install.sh` to pick up changes.

## Prerequisites

- Notion API key configured in `.env`
- Notion integration with Read, Update, Insert capabilities
