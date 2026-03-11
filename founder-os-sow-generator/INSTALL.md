# Installation: SOW Generator

## Prerequisites

- Claude Code with plugin support
- Node.js 18+ (for MCP servers via `npx`)

## Step 1: Install Required MCP Servers

### Filesystem Server (Required)

```bash
npx -y @modelcontextprotocol/server-filesystem /path/to/your/briefs
```

The filesystem server provides read access to your project brief files and write access for SOW output. Pass the root directory where briefs are stored. If briefs and output live in different directories, you can pass multiple paths:

```bash
npx -y @modelcontextprotocol/server-filesystem /path/to/briefs /path/to/sow-output
```

## Step 2: Install Optional MCP Servers

### Notion (Optional — for brief loading and historical SOW context)

```bash
npx -y @modelcontextprotocol/server-notion
```

With Notion configured, the plugin can:
- Load briefs directly from Notion pages via `/sow:from-brief https://www.notion.so/...`
- Search historical SOWs in your Notion workspace to calibrate scope and pricing
- Save generated SOW Markdown back to a Notion page after generation

**Configure Notion API Key:**

1. Go to [notion.so/my-integrations](https://notion.so/my-integrations)
2. Click "New integration" → name it "SOW Generator"
3. Copy the Internal Integration Token
4. Set the environment variable:

```bash
export NOTION_API_KEY="your_notion_api_key_here"
```

5. Share your Notion workspace (or specific pages) with the integration:
   - Open any Notion page → click "..." → "Add connections" → select "SOW Generator"

### Google Drive (Optional — for SOW document storage)

```bash
npx -y gws CLI (Drive)
```

With Google Drive configured, the plugin can store generated SOW Markdown files in a Drive folder for easy client sharing.

**OAuth Setup:**

1. Create a project in [Google Cloud Console](https://console.cloud.google.com)
2. Enable the Google Drive API
3. Create OAuth 2.0 credentials (Desktop application)
4. Download `credentials.json`
5. Set environment variables:

```bash
export GOOGLE_CREDENTIALS_PATH="/path/to/credentials.json"
export GOOGLE_TOKEN_PATH="/path/to/drive-token.json"
```

## Step 3: Configure Environment

Add to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.):

```bash
# SOW Generator — Optional (Notion)
export NOTION_API_KEY="your_notion_api_key_here"

# SOW Generator — Optional (Google Drive)
export GOOGLE_CREDENTIALS_PATH="/path/to/credentials.json"
export GOOGLE_TOKEN_PATH="/path/to/drive-token.json"
```

Then reload your profile:

```bash
source ~/.zshrc
```

## Step 4: Enable the Plugin

In Claude Code, enable the plugin from your plugin manager or by adding the plugin directory to your configuration.

## Step 5: Verify Installation

Test with a simple inline brief:

```bash
/sow:generate "Build a simple website with a homepage, about page, and contact form"
```

You should see a 3-option summary table with Conservative, Balanced, and Ambitious packages in approximately 30 seconds. The SOW file is written to `./sow-output/`.

For team mode:

```bash
/sow:generate --team "Build a simple website with a homepage, about page, and contact form"
```

You should see a pipeline summary showing all 6 agents completing, followed by a scoring matrix.

## Notion Databases

The plugin writes generated SOW records to the consolidated **"Founder OS HQ - Deliverables"** database with Type="SOW". This database is shared across P12 (Proposal Automator), P13 (Contract Analyzer), and P14 (SOW Generator).

If the HQ Deliverables database does not exist, the plugin falls back to the legacy "SOW Generator - Outputs" database. If neither exists, Notion tracking is skipped silently — the plugin does NOT create databases automatically.

To set up the HQ Deliverables database, use the template at `_infrastructure/notion-db-templates/hq-deliverables.json`. Share the database with your Notion integration after creating it.

## Troubleshooting

**"NOTION_API_KEY not configured"**
→ Check `echo $NOTION_API_KEY` returns your key. Re-run `source ~/.zshrc`. Verify the variable is exported (use `export`, not just assignment).

**"File not found: [path]"**
→ Ensure the filesystem MCP server has access to the directory containing the brief file. Check the path passed to `@modelcontextprotocol/server-filesystem`.

**"Notion MCP is required to load Notion pages"**
→ The `/sow:from-brief` command with a Notion URL requires the Notion MCP server. Install it and set `NOTION_API_KEY` before using Notion URLs.

**"Could not access Notion page"**
→ The target page must be shared with your Notion integration. Open the page in Notion, click "..." → "Add connections" → select "SOW Generator".

**Output directory doesn't exist**
→ The plugin creates the output directory automatically. If you see a permissions error, create the directory manually: `mkdir -p ./sow-output`

**"Only 2 options generated (one scope agent failed)"**
→ In `--team` mode, the pipeline requires at least 2 of 3 Phase 1 scope agents to succeed. The pipeline continues with 2 proposals and notes which agent failed. If all 3 fail, check that the brief contains enough detail for the agents to work with.

**SOW output is very generic**
→ The brief provided was too short or vague. Add specifics: client name, key deliverables, technology preferences, success criteria, and any known constraints. A brief of 2–3 sentences produces generic output; 1–2 paragraphs produces a usable SOW.
