# Installation

## Prerequisites

- Claude Code with plugin support
- Notion account with API access

## Step 1: Install the Plugin

Copy or clone the `founder-os-goal-progress-tracker/` directory to your plugins location.

## Step 2: Configure Notion MCP

1. Create a Notion integration at https://www.notion.so/my-integrations
2. Copy the Internal Integration Secret
3. Set the environment variable:
   ```bash
   export NOTION_API_KEY="your-integration-secret"
   ```
4. Share your target Notion workspace page with the integration

The plugin's `.mcp.json` is pre-configured to use `@modelcontextprotocol/server-notion`.

## Step 3: Verify Connection

Run `/goal:check` — if Notion is connected, it will display "No goals tracked yet." If not connected, it will report the connection error.

## Database Setup

The plugin searches for databases using a 3-step discovery sequence:

1. **[FOS] Goals** (preferred) or **Founder OS HQ - Goals** or **Goal Progress Tracker - Goals** (fallbacks)
2. **[FOS] Milestones** (preferred) or **Founder OS HQ - Milestones** or **Goal Progress Tracker - Milestones** (fallbacks)

Ensure your Notion workspace has the Founder OS HQ template installed, or create these databases manually and share them with the integration. The Goals database must exist before Milestones (relation dependency).
