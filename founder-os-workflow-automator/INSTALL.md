# Installation

## Prerequisites

- Claude Code CLI installed and configured
- At least one Founder OS plugin installed (for workflow steps to invoke)

## MCP Server Setup

### Filesystem (Required)

The Filesystem MCP server enables reading and writing workflow YAML files.

Already configured in `.mcp.json`. Set the `ALLOWED_PATH` environment variable to your project directory:

```bash
export ALLOWED_PATH="/path/to/your/project"
```

### Notion (Optional)

The Notion MCP server enables execution history logging.

1. Create a Notion integration at https://www.notion.so/my-integrations
2. Copy the API key
3. Set the environment variable:

```bash
export NOTION_API_KEY="your-notion-api-key"
```

4. Share target Notion pages/databases with your integration

Execution logs are written to the "[FOS] Workflows" database (Type="Execution"). If that database does not exist, the plugin falls back to "Founder OS HQ - Workflows", then the legacy "Workflow Automator - Executions" database. The plugin does not create either database — set up the HQ database using the Notion HQ consolidation process or create it manually from `_infrastructure/notion-db-templates/hq-workflows.json`.

## Plugin Installation

Install the plugin in Claude Code:

```bash
claude plugin install founder-os-workflow-automator
```

Or use local development mode:

```bash
claude --plugin-dir /path/to/founder-os-workflow-automator
```

## Verification

After installation, verify the plugin is working:

```
/workflow:list
```

If no workflows exist yet, create one:

```
/workflow:create my-first-workflow --from-template
```

## Directory Setup

The plugin expects this directory structure in your project:

```
workflows/           # Your workflow YAML files
workflows/examples/  # Example workflows (included with plugin)
workflows/runners/   # Generated cron runner scripts
```

These directories are created automatically as needed.
