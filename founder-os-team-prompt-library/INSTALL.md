# Installation: Team Prompt Library (#26)

## Prerequisites

| Requirement | Version | Notes |
|------------|---------|-------|
| Claude Code | Latest | [claude.ai/code](https://claude.ai/code) |
| Node.js | 18+ | Required by MCP servers |
| npx | Bundled with Node.js 18+ | Used to launch MCP servers |

---

## Step 1: Create a Notion Integration

1. Go to [notion.so/my-integrations](https://notion.so/my-integrations)
2. Click **New integration**
3. Name it something like `Founder OS - Claude Code`
4. Set **Associated workspace** to your workspace
5. Under **Capabilities**, ensure **Read content**, **Update content**, and **Insert content** are enabled
6. Click **Submit** and copy the **Internal Integration Token** (starts with `ntn_` or `secret_`)

---

## Step 2: Set the Environment Variable

Add your Notion API key to your shell profile so Claude Code can access it.

**macOS / Linux (zsh):**
```bash
echo 'export NOTION_API_KEY="your_token_here"' >> ~/.zshrc
source ~/.zshrc
```

**macOS / Linux (bash):**
```bash
echo 'export NOTION_API_KEY="your_token_here"' >> ~/.bashrc
source ~/.bashrc
```

**Windows (PowerShell):**
```powershell
[System.Environment]::SetEnvironmentVariable("NOTION_API_KEY", "your_token_here", "User")
```

---

## Step 3: Share Your Workspace with the Integration

The integration needs access to the pages where it will create and read databases.

1. Open Notion and navigate to the page or workspace root where you want the prompt library to live
2. Click the **...** menu in the top-right corner of the page
3. Select **Add connections**
4. Search for your integration name (e.g., `Founder OS - Claude Code`) and select it
5. Repeat for any other pages or databases you want the integration to access

> The plugin searches for the **[FOS] Prompts** database first, then falls back to **Founder OS HQ - Prompts**, then **Team Prompt Library - Prompts**. Use the Founder OS HQ workspace template to provision this database. Grant the integration access to the page containing the database.

---

## Step 4: Configure the MCP Server

Create or update the `.mcp.json` file in the `founder-os-team-prompt-library/` directory:

```json
{
  "mcpServers": {
    "notion": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-notion"
      ],
      "env": {
        "NOTION_API_KEY": "${NOTION_API_KEY}"
      }
    }
  }
}
```

This uses the `${NOTION_API_KEY}` environment variable set in Step 2 — no hardcoded secrets.

---

## Step 5: Verify the Installation

Open Claude Code in the `founder-os-team-prompt-library/` directory and run:

```
/prompt:list
```

Expected result: Claude will search for a **[FOS] Prompts** database (or fallback **Founder OS HQ - Prompts**, then **Team Prompt Library - Prompts**) in Notion. If found, it will list any stored prompts. If no database exists, it will display an empty library message.

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| `NOTION_API_KEY not set` | Env var missing or shell not reloaded | Run `source ~/.zshrc` and verify with `echo $NOTION_API_KEY` |
| `Could not find database` | Integration not shared with parent page | Follow Step 3 — share integration with the target page |
| `Unauthorized` error | Wrong token or token not copied fully | Return to [notion.so/my-integrations](https://notion.so/my-integrations) and copy the token again |
| `npx: command not found` | Node.js not installed or too old | Install Node.js 18+ from [nodejs.org](https://nodejs.org) |
| MCP server fails to start | Port conflict or npx cache issue | Run `npx clear-npx-cache` then retry |
| Database created but empty | First-run expected behavior | Add your first prompt with `/prompt:add` |
