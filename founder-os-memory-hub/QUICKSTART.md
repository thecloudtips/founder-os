# Quick Start: founder-os-memory-hub

> Cross-plugin shared memory with adaptive behavior — teach, view, forget, and sync memories that enrich all Founder OS plugins with learned preferences, patterns, and facts.

## Overview

**Plugin #31** | **Pillar**: Meta & Growth | **Platform**: Claude Code

Memory Hub gives you direct control over the shared memory layer that all Founder OS plugins draw from. Teach it new facts about your business, review what it has learned, remove stale memories, and keep Notion in sync — all through four simple commands.

### What This Plugin Does

- Stores persistent memories (preferences, client facts, workflow patterns) accessible to all 30 Founder OS plugins
- Injects relevant memories automatically at the start of every plugin command — no user action needed
- Adapts behavior autonomously after 3+ consistent confirmations of a pattern, then notifies you
- Syncs memory state to/from the Notion `[FOS] Memory` database for backup and cross-device access
- Lets you inspect, add, and remove memories at any time

### Time Savings

Estimated **30-60 minutes per week** saved from not repeating preferences and context to each plugin. Memories compound over time — the longer Memory Hub runs, the more it personalizes every interaction.

## Available Commands

| Command | Description |
|---------|-------------|
| `/memory:show` | Display all stored memories grouped by category |
| `/memory:show --candidates` | Show all memories including pending candidates |
| `/memory:teach "<statement>"` | Teach the system a new fact or preference |
| `/memory:forget <key>` | Remove a specific memory by its key |
| `/memory:sync` | Sync local memory store with Notion `[FOS] Memory` database |
| `/memory:sync --direction=push` | Push local memories to Notion (overwrite remote) |
| `/memory:sync --direction=pull` | Pull memories from Notion (overwrite local) |

## Usage Examples

### Example 1: See What's Been Learned

```
/memory:show
```

**What happens:**
- Reads the local memory store
- Groups memories by category: `preference`, `pattern`, `fact`, `contact`, `workflow`
- Shows each memory's key, content, confidence score (0-100), and last-used timestamp
- Reports total count and sync status

**Sample output:**
```
Memory Hub — 12 memories stored

### Preferences
- **email-tone-formal** (User, confidence: 100, confirmed): Use formal tone in email drafts
- **briefing-format** (P02, confidence: 95, applied): Prefers bullet-point daily briefings
- **invoice-net-terms** (User, confidence: 100, confirmed): Standard payment terms are Net 30

### Contacts
- **acme-primary-contact** (P21, confidence: 85, applied): Sarah Chen, VP Engineering at Acme Corp

### Patterns
- **acme-action-emails** (P01, confidence: 82, applied): Emails from @acmecorp.com are 90% action-required

Last synced: 2026-03-11 09:14 UTC  |  Notion: connected
```

### Example 2: Teach a New Fact

```
/memory:teach "Always CC legal@mycompany.com on contracts over $50k"
```

**What happens:**
- Parses the statement and assigns a category (`preference`, `fact`, `contact`, or `workflow`)
- Generates a memory key (e.g., `contracts-cc-legal-threshold`)
- Stores with confidence 100 (user-taught memories start at full confidence)
- Confirms storage and shows which plugins will benefit (e.g., Contract Analyzer, SOW Generator)

### Example 3: Remove a Stale Memory

```
/memory:forget client.oldcorp.contact
```

**What happens:**
- Looks up the key in the memory store
- Shows you the current value and asks for confirmation
- Deletes on confirmation
- Marks the entry as deleted in Notion on next sync (soft delete)

### Example 4: Sync with Notion

```
/memory:sync
```

**What happens:**
- Compares local store with Notion `[FOS] Memory` database
- Merges changes: local wins for user-taught memories, higher-confidence wins for learned patterns
- Reports: memories pushed, pulled, and any conflicts resolved
- Updates `last_synced` timestamp

## How Context Injection Works

Memory injection is automatic — you do not need to run any command. When any Founder OS plugin command starts, the shared memory layer:

1. Reads the active plugin and command context
2. Queries the memory store for relevant keys (semantic match on category and plugin tags)
3. Prepends a compact memory block to the plugin's working context
4. The plugin uses those memories silently — they shape responses without prompting you

You will see memory influence reflected in plugin outputs (e.g., email drafts already in your preferred tone, invoices with your standard Net 30 terms) without any extra steps.

## How Adaptation Works

The memory engine tracks confirmed patterns automatically:

- When you accept or approve the same type of output 3+ times in a row, the engine raises that pattern's confidence score
- At confidence 80+ with 3+ confirmations, the pattern is promoted to "applied" status
- You receive a notification: `"Memory adapted: I'm now using bullet-point format for daily briefings based on your last 5 sessions."`
- Applied memories are injected with higher priority than candidate ones
- You can override any adapted memory at any time with `/memory:teach` or `/memory:forget`

## Tips

- Use `/memory:teach` liberally at the start — the more you seed, the faster all plugins improve
- Run `/memory:show` after a week to review what the engine has learned on its own
- Use `/memory:show Acme Corp` to audit client-specific memories before a big engagement
- `/memory:sync` before switching machines to avoid stale memories on a new device
- Memories are shared across all 30 plugins — one fact taught here enriches every command

## Related Plugins

Memory Hub enriches all 30 Founder OS plugins. Highest-impact integrations:

- **#01 Inbox Zero**: Email tone and VIP sender preferences
- **#10 Client Health**: Client relationship context and preferences
- **#12 Proposal Automator**: Pricing, terms, and scope patterns
- **#25 Time Savings**: ROI framing preferences

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `/memory:show` returns empty | Memory store is new — run `/memory:teach` to add your first memory |
| Notion sync fails | Verify Notion MCP is enabled in Claude Desktop Settings > Integrations |
| Memory not injecting into other plugins | Ensure other plugins are on the latest version (memory injection requires the shared skill) |
| Adaptation notification not appearing | Adaptation triggers after 3+ confirmations — continue using plugins normally |
| Wrong memory being injected | Use `/memory:forget <key>` to remove the incorrect entry, then `/memory:teach` the correct one |

## Next Steps

1. Run `/memory:show` to verify the store is initialized
2. Run `/memory:teach "..."` with 3-5 key facts about your business (tone, terms, VIP clients)
3. Use your other Founder OS plugins normally — memories inject automatically
4. After one week, run `/memory:show` to review what the engine has learned
5. Run `/memory:sync` to back up to Notion
