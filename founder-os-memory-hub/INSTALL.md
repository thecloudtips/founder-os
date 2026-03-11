# Installation Guide: Memory Hub

> Cross-plugin shared memory with adaptive behavior — teach, view, forget, and sync memories that enrich all Founder OS plugins with learned preferences, patterns, and facts.

## Prerequisites

- [ ] Claude Desktop with the **Code** tab enabled
- [ ] Founder OS HQ workspace deployed in Notion (for Notion sync)

### Connectors

| Service | Required? | How |
|---------|-----------|-----|
| **Notion** | Optional | Enable native connector in Claude Desktop Settings > Integrations. Deploy the Founder OS HQ template — the `[FOS] Memory` database is included. Memory store works locally without Notion; sync is optional. |

## Installation

1. Zip the `founder-os-memory-hub/` folder
2. Upload the zip in Claude Desktop's Code tab

## First Run

```
/memory:show
```

This verifies the memory store is initialized and displays any existing memories. The store auto-initializes on first use — no manual database setup needed.

If Notion is connected, the command also reports sync status with the `[FOS] Memory` database.

## How Memory Auto-Initializes

On the first `/memory:show` or `/memory:teach` command, the plugin:

1. Checks for an existing local memory store at `.memory/memory.db` in the project root
2. If absent, creates the directory and initializes SQLite from `_infrastructure/memory/schema/memory-store.sql`
3. If Notion is connected, checks for the `[FOS] Memory` database and links it for sync
4. Reports initialization status

No manual file creation or database configuration is needed.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Unknown skill" error | Re-upload the plugin zip, restart Claude Desktop |
| "Memory store not found" | Run `/memory:show` — it auto-initializes on first run |
| Notion sync fails | Verify Notion MCP is enabled in Claude Desktop Settings > Integrations |
| `[FOS] Memory` DB missing | Deploy or re-import the Founder OS HQ Notion template |
| Plugin not loading | Ensure folder is in `~/.claude/plugins/` and restart Claude Code |
