# founder-os-memory-hub

> **Plugin #31** -- Cross-plugin shared memory with adaptive behavior. View, teach, forget, and sync memories that enrich all Founder OS plugins with learned preferences, patterns, and facts.

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | Meta & Growth |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Intermediate |
| **Week** | 31 |

## What It Does

Memory Hub is the user-facing control panel for the Founder OS shared memory layer. It exposes four commands that let you inspect, teach, remove, and sync memories — while the underlying memory infrastructure (`_infrastructure/memory/`) handles storage, context injection, and adaptive pattern detection transparently across all 30 plugins.

Key behaviors:

- **Context injection**: Relevant memories are prepended to every plugin command automatically. You never need to repeat your preferences, client facts, or workflow patterns.
- **Adaptive learning**: The memory engine tracks confirmed patterns. After 3+ consistent confirmations, a pattern is promoted to "adapted" status and injected at higher priority. You are notified each time.
- **Notion sync**: The optional `/memory:sync` command mirrors the memory store to the `[FOS] Memory` Notion database for backup and cross-device access.
- **Manual control**: `/memory:teach` and `/memory:forget` give you direct authority over what is stored — adapted memories never override your explicit instructions.

## Requirements

### MCP Servers

| Tool | Required | Purpose |
|------|----------|---------|
| **Notion** | Optional | Sync memory store to `[FOS] Memory` database for backup and cross-device access |

### Platform

- **Claude Code** with the shared memory infrastructure at `_infrastructure/memory/`

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples and tips.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/memory:show` | Display all stored memories grouped by category |
| `/memory:show <company\|plugin>` | Filter memories by company name or plugin ID |
| `/memory:teach "<statement>"` | Teach a new fact or preference |
| `/memory:forget <key>` | Remove a memory by key |
| `/memory:sync` | Bidirectional sync with Notion `[FOS] Memory` database |
| `/memory:sync --direction=push` | Push local to Notion |
| `/memory:sync --direction=pull` | Pull from Notion to local |

## Skills

- **notion-sync**: Handles bidirectional sync between the local memory store and the Notion `[FOS] Memory` database. Manages conflict resolution (user-taught memories win; higher confidence wins for learned patterns), soft deletes, and the `last_synced` timestamp.

## Architecture

```
founder-os-memory-hub/          # This plugin (user-facing)
├── commands/                   # /memory:show, :teach, :forget, :sync
└── skills/notion-sync/         # Notion sync logic

_infrastructure/memory/         # Shared infrastructure (not user-facing)
├── SKILL.md                    # Core memory store operations
├── context-injection/          # Auto-inject memories into plugin commands
├── pattern-detection/          # Adaptive learning engine
└── schema/                     # Memory store schema definition
```

This plugin is a thin command layer. All memory store read/write operations, context injection, and pattern detection are implemented in `_infrastructure/memory/` and shared across all 30 Founder OS plugins.

## Memory Categories

| Category | What It Stores | Example |
|----------|---------------|---------|
| `preference` | User style and format preferences | `"bullet points preferred in reports"` |
| `pattern` | Recurring workflow behaviors | `"flag emails from @acmecorp.com as urgent"` |
| `fact` | Business facts and constants | `"standard invoice terms: Net 30"` |
| `contact` | People and their roles | `"Sarah Chen (sarah@acme.com) — VP Engineering"` |
| `workflow` | Plugin usage sequences | `"After inbox triage, always run follow-up scan"` |

## Design Spec

For full architecture details, see:
- Memory engine spec: `docs/superpowers/specs/[2]-2026-03-11-memory-engine-design.md`
- Infrastructure layer: `_infrastructure/memory/SKILL.md`

## Dependencies

This plugin has no dependencies on other Founder OS plugins. It enriches all 30 plugins when installed.

## License

MIT
