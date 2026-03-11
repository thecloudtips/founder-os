# Installation Guide: Adaptive Intelligence Engine

> The control panel for the Founder OS intelligence layer — view learned patterns, manage self-healing, and tune confidence thresholds across all 30 plugins.

## Prerequisites

- [ ] Claude Code with the **Code** tab enabled
- [ ] At least one Founder OS pilot plugin installed (Inbox Zero, Weekly Review, or Client Health recommended)
- [ ] Memory Hub plugin (`founder-os-memory-hub`) — optional but recommended for shared memory integration

### Connectors

| Service | Required? | How |
|---------|-----------|-----|
| **Notion** | Optional | Enable native connector in Claude Desktop Settings > Integrations. Deploy the Founder OS HQ template — the `[FOS] Intelligence` database is included. All intelligence commands work locally without Notion; sync is optional. |

## Installation

1. Zip the `founder-os-adaptive-intel/` folder
2. Upload the zip in Claude Desktop's Code tab

The intelligence database (`_infrastructure/intelligence/.data/intelligence.db`) auto-creates on first use. No manual database setup is required.

## First Run

```
/intel:status
```

This verifies the intelligence layer is active and shows the dashboard. If no events have been captured yet, you will see:

```
── Adaptive Intelligence Status ──────────────────
Status: Not initialized
Run any plugin command to begin capturing events.
```

This is expected on a fresh install. Run a few commands from any pilot plugin, then run `/intel:status` again — you will see events appearing in the dashboard.

## How Intelligence Auto-Initializes

On the first command run by any pilot plugin, the hooks layer:

1. Checks for the intelligence database at `_infrastructure/intelligence/.data/intelligence.db`
2. If absent, creates the directory and initializes SQLite from the schema at `_infrastructure/intelligence/hooks/schema/intelligence.sql`
3. Begins capturing `pre_command` and `post_command` events from that point forward
4. Pattern detection and self-healing activate automatically as events accumulate

No manual file creation or configuration is needed.

## Verifying the Notion Integration (Optional)

If you want to sync learned patterns to Notion:

1. Configure the Notion MCP with your API key (see `.mcp.json` in this plugin directory)
2. Deploy the Founder OS HQ Notion template — it includes the `[FOS] Intelligence` database
3. Share the HQ workspace page with your Notion integration
4. Run `/memory:sync` — this triggers both Memory Hub and Intelligence Engine sync

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Not initialized" after running other plugins | Ensure a pilot plugin with hooks integration is installed and has been run at least once |
| `/intel:status` shows zero events | Check that `_infrastructure/intelligence/.data/intelligence.db` exists; if absent, re-run a pilot plugin |
| Notion sync fails | Verify Notion MCP is enabled in Claude Desktop Settings > Integrations |
| `[FOS] Intelligence` DB missing | Deploy or re-import the Founder OS HQ Notion template |
| Patterns not appearing | Patterns require multiple observations to reach the confidence threshold — continue using pilot plugins normally |
| Plugin not loading | Ensure the folder is in `~/.claude/plugins/` and restart Claude Code |
