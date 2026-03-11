# Founder OS Setup Guide

This guide walks you through installing and configuring Founder OS — a single-plugin AI automation ecosystem for SMB founders, built on Claude Code with 32 command namespaces.

## What You're Installing

- **1 AI plugin with 32 command namespaces** organized into 4 pillars (Daily Work, Code Without Coding, MCP & Integrations, Meta & Growth)
- **22 Notion databases** (CRM, tasks, meetings, reports, and more — all interconnected)
- **MCP server connections** (Notion, Filesystem)
- **Google Workspace access** via gws CLI (Gmail, Calendar, Drive)

## Prerequisites

Install these before running the Founder OS installer:

### 1. Claude Code

The AI coding assistant that runs Founder OS.

Install: https://docs.anthropic.com/en/docs/claude-code

Verify:
```bash
claude --version
```

### 2. Node.js 18+

Required for MCP servers (Notion, Filesystem).

Install: https://nodejs.org/ (LTS recommended)

Verify:
```bash
node --version   # Should be v18.x or higher
npx --version    # Should be available
```

### 3. gws CLI

Command-line tool for Gmail, Calendar, and Drive access. Used by 20+ namespaces for email, scheduling, and document operations.

Install: Follow the gws CLI installation instructions for your platform.

Verify:
```bash
gws --version
```

## Getting Your API Keys

### Notion API Key (Required)

Your Notion key allows Founder OS to read and write to your Notion workspace.

1. Go to https://www.notion.so/my-integrations
2. Click **"+ New integration"**
3. Name it **"Founder OS"**
4. Under **Capabilities**, ensure these are enabled:
   - Read content
   - Update content
   - Insert content
5. Click **"Submit"**
6. Copy the **"Internal Integration Secret"** (starts with `ntn_`)
7. Save this — you'll paste it into `.env` in the next section

### Google Account (Required)

The gws CLI handles Google authentication. No API key needed — just your Google account.

During installation, the script runs `gws auth login` which:
1. Opens your browser
2. Asks you to sign in with your Google account
3. Requests access to Gmail, Calendar, and Drive
4. Confirms authentication in the terminal

You only need to do this once. The token is stored locally.

### Slack Bot Token (Optional)

Only needed for P19 Slack Digest. Skip this if you don't use Slack.

1. Go to https://api.slack.com/apps
2. Click **"Create New App"** → **"From scratch"**
3. Name it **"Founder OS"**, select your workspace
4. Go to **OAuth & Permissions** → **Bot Token Scopes** and add:
   - `channels:history`
   - `channels:read`
   - `users:read`
5. Click **"Install to Workspace"** and approve
6. Copy the **"Bot User OAuth Token"** (starts with `xoxb-`)

### Web Search API Key (Optional)

Only needed for P08 Newsletter Engine and P15 Competitive Intel. Skip if not using these namespaces.

## Installation

### Step 1: Clone the repository

```bash
git clone https://github.com/[org]/founderOS.git
cd founderOS
```

### Step 2: Configure your environment

```bash
cp .env.example .env
```

Open `.env` in your editor and fill in:
- `NOTION_API_KEY` — paste your Notion integration secret
- `WORKSPACE_DIR` — directory for file operations (default: `~/founder-os-workspace`)
- `SLACK_BOT_TOKEN` — (optional) paste your Slack bot token
- `WEB_SEARCH_API_KEY` — (optional) paste your search API key

### Step 3: Run the installer

```bash
./install.sh
```

The installer runs 6 phases:

| Phase | What It Does |
|-------|-------------|
| 1. Prerequisites | Checks Node.js, npx, Claude Code, gws CLI |
| 2. Environment | Loads `.env`, validates API keys against live APIs |
| 3. Google Auth | Runs `gws auth login` if not already authenticated |
| 4. Plugin Config | Configures MCP servers in the root `.mcp.json` |
| 5. Notion HQ | Creates 22 databases in your Notion workspace |
| 6. Verification | Tests all connections and reports results |

## After Installation

### First Commands to Try

Open Claude Code in the `founderOS` directory and try:

```
/founder-os:inbox:triage                          # Triage your inbox
/founder-os:report:generate --type=weekly         # Generate a weekly report
/founder-os:client:load --company="Acme Corp"     # Load client context
/founder-os:setup:verify                          # Check installation health
```

### Updating Founder OS

Pull the latest changes and re-run the installer (safe — it skips completed steps):

```bash
git pull
./install.sh
```

### Installer Flags

| Flag | Purpose |
|------|---------|
| `--verify` | Run only the verification phase |
| `--skip-notion` | Skip Notion database setup |
| `--reset` | Remove MCP entries and reset config (clean slate) |
| `--help` | Show usage information |
