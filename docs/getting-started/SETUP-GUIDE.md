# Founder OS Setup Guide

This guide walks you through installing and configuring Founder OS — a single-plugin AI automation ecosystem for SMB founders, built on Claude Code with 32 command namespaces.

## What You're Installing

- **1 AI plugin with 32 command namespaces** organized into 4 pillars (Daily Work, Code Without Coding, MCP & Integrations, Meta & Growth)
- **94 slash commands** available in any Claude Code project
- **22 Notion databases** (CRM, tasks, meetings, reports, and more — all interconnected)
- **Automatic MCP server configuration** (Notion + Filesystem — configured by the plugin)
- **Google Workspace access** via gws CLI (Gmail, Calendar, Drive — optional)

## Prerequisites

Install these before adding Founder OS:

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

### 3. gws CLI (Optional)

Command-line tool for Gmail, Calendar, and Drive access. Used by 20 namespaces for email, scheduling, and document operations. Skip this if you only want Notion-based features.

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

### Google Account (Optional)

The gws CLI handles Google authentication. No API key needed — just your Google account.

```bash
gws auth login
```

This opens your browser, asks you to sign in, and requests access to Gmail, Calendar, and Drive. You only need to do this once — the token is stored locally.

### Slack Bot Token (Optional)

Only needed for the Slack Digest namespace. Skip this if you don't use Slack.

1. Go to https://api.slack.com/apps
2. Click **"Create New App"** → **"From scratch"**
3. Name it **"Founder OS"**, select your workspace
4. Go to **OAuth & Permissions** → **Bot Token Scopes** and add:
   - `channels:history`
   - `channels:read`
   - `users:read`
5. Click **"Install to Workspace"** and approve
6. Copy the **"Bot User OAuth Token"** (starts with `xoxb-`)

## Installation

### Step 1: Install the Plugin

```bash
# Add the Founder OS marketplace
claude plugin marketplace add thecloudtips/founder-os

# Install the plugin
claude plugin install founder-os
```

The plugin installs globally — it's available in every Claude Code project, not just one directory.

### Step 2: Set Environment Variables

Add your API keys to your shell profile so they persist across sessions:

```bash
# Add to ~/.zshrc (macOS) or ~/.bashrc (Linux)

# Required — Notion API key
export NOTION_API_KEY=ntn_your_token_here

# Optional — Slack bot token
export SLACK_BOT_TOKEN=xoxb_your_token_here
```

Reload your shell:
```bash
source ~/.zshrc   # or source ~/.bashrc
```

### Step 3: Set Up Notion HQ Databases

Open Claude Code in any project and run:

```
/founder-os:setup:notion-hq
```

This creates 22 interconnected Notion databases in your workspace:

| Category | Databases Created |
|----------|------------------|
| CRM | Companies (central hub), Contacts, Deals, Communications |
| Operations | Tasks, Meetings, Finance |
| Intelligence | Briefings, Knowledge Base, Research, Reports |
| Content | Content, Deliverables, Prompts |
| Growth | Goals, Milestones, Learnings, Weekly Insights, Workflows, Activity Log, Memory |

**This command is idempotent** — if some databases already exist (from a previous run or partial setup), it only creates the missing ones. Safe to re-run anytime.

### Step 4: Verify Installation

```
/founder-os:setup:verify
```

This checks:
- Notion API connectivity and database access
- Google Workspace authentication (if gws is installed)
- Filesystem MCP read/write capability
- Reports pass/fail for each integration

## How Everything Connects

### What Happens at Install Time

When you run `claude plugin install founder-os`:

1. Claude Code downloads the plugin files from GitHub
2. The plugin's `.mcp.json` automatically configures Notion and Filesystem MCP servers
3. All 94 slash commands become available as `/founder-os:<namespace>:<action>`
4. No files are created in your project directory — the plugin lives in Claude Code's plugin cache

### What Happens on First Use

Three local systems initialize automatically when first needed:

| System | Storage | Created When | What It Does |
|--------|---------|-------------|-------------|
| Memory Engine | `.memory/memory.db` (SQLite) | First command using memory | Stores cross-namespace context, preferences, and patterns |
| Intelligence Engine | `.intelligence/intelligence.db` (SQLite) | First intelligence event | Powers adaptive behavior and pattern detection |
| Notion HQ | 22 databases in your Notion workspace | When you run `/founder-os:setup:notion-hq` | CRM, tasks, meetings, reports — all interconnected |

**All three are optional for basic usage.** Commands gracefully skip memory/intelligence if the databases don't exist. Individual namespaces work with whatever Notion databases are available.

### Where Your Data Lives

| Data | Location | Scope |
|------|----------|-------|
| Plugin files | `~/.claude/plugins/cache/...` (managed by Claude Code) | Global |
| Notion databases | Your Notion workspace | Per workspace |
| Memory store | `.memory/memory.db` in project root | Per project |
| Intelligence store | `.intelligence/intelligence.db` in project root | Per project |
| File outputs | `~/founder-os-workspace` (default, configurable) | Global |

Everything stays local or in your own Notion workspace. No data is sent to third-party servers.

## After Installation

### First Commands to Try

Open Claude Code in any project and try:

```
/founder-os:morning:sync                    # Morning briefing from all sources
/founder-os:inbox:triage                    # AI-powered email triage
/founder-os:prep:today                      # Prep for today's meetings
/founder-os:client:load --company="Acme"    # Load client context
/founder-os:report:generate                 # Generate a business report
/founder-os:memory:teach                    # Teach the system a preference
/founder-os:setup:verify                    # Check installation health
```

### Updating Founder OS

```bash
claude plugin marketplace remove founder-os-marketplace
claude plugin marketplace add thecloudtips/founder-os
claude plugin install founder-os
```

This pulls the latest version. Your Notion databases, memory store, and intelligence data are preserved — they live outside the plugin.

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and fixes.
