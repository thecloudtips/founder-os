# Installing Founder OS Setup Plugin

This plugin is installed automatically by `./install.sh`. No manual setup needed.

## Prerequisites

- Claude Code installed
- Node.js 18+
- `.env` file with `NOTION_API_KEY` configured

## Manual Installation

If not using the installer:

1. Symlink this plugin:
   ```bash
   mkdir -p .claude/plugins
   ln -sf "$(pwd)/founder-os-setup" .claude/plugins/founder-os-setup
   ```

2. Ensure `.mcp.json` in project root has a Notion server entry. See `.mcp.json.example` for reference.

## Verification

Run `/setup:verify` in Claude Code to confirm everything is working.
