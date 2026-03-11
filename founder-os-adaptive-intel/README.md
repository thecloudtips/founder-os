# founder-os-adaptive-intel

> **Plugin #32** -- Adaptive intelligence control panel. View learned patterns, manage self-healing, and tune confidence thresholds across all Founder OS plugins.

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | Meta & Growth |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Intermediate |
| **Week** | — |
| **Dependencies** | Memory Hub (optional) |

## What It Does

Adaptive Intelligence is the user-facing control panel for the intelligence layer that operates beneath all Founder OS plugins. The infrastructure layer (`_infrastructure/intelligence/`) silently captures behavioral events, learns patterns from your usage, and heals transient failures — this plugin exposes that activity through six commands.

Key behaviors:

- **Pattern visibility**: See every behavioral pattern the engine has learned from your plugin usage — filtered by plugin, type, or confidence.
- **Manual control**: Approve patterns to make them permanent, or reset patterns that are incorrect, without waiting for confidence thresholds.
- **Self-healing transparency**: Inspect every error recovery attempt, see which fixes are working, and identify systemic issues that need manual attention.
- **Configuration**: Tune all intelligence engine settings — confidence thresholds, autonomy ceiling, retry behavior, and event retention — from a single interface.
- **Notion sync**: Mirror patterns and healing data to the `[FOS] Intelligence` Notion database for backup and review.

## Requirements

### MCP Servers

| Tool | Required | Purpose |
|------|----------|---------|
| **Notion** | Optional | Sync intelligence patterns to `[FOS] Intelligence` database |

### Platform

- **Claude Code** with the shared intelligence infrastructure at `_infrastructure/intelligence/`
- At least one pilot plugin (Inbox Zero, Daily Briefing, or Client Health) for event capture

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples and tips.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Usage | Description |
|---------|-------|-------------|
| `/intel:status` | `/intel:status` | Dashboard: hooks activity, pattern counts, top patterns, recent healing events |
| `/intel:patterns` | `/intel:patterns [--plugin=name] [--type=taste\|workflow] [id]` | List all patterns or view a single pattern in detail |
| `/intel:approve` | `/intel:approve <id>` | Promote a pattern to approved status at maximum confidence |
| `/intel:reset` | `/intel:reset [--plugin=name] [--type=taste\|workflow] [--all]` | Clear learned patterns with confirmation |
| `/intel:healing` | `/intel:healing [--plugin=name]` | Self-healing event log, error frequency, and fix effectiveness |
| `/intel:config` | `/intel:config [key] [value] [--reset]` | View or update intelligence engine configuration |

## Configuration

All configuration keys are readable and writable via `/intel:config`:

| Key | Default | Description |
|-----|---------|-------------|
| `learning.enabled` | `true` | Enable/disable pattern learning |
| `learning.taste.threshold` | `0.5` | Confidence threshold to auto-apply taste patterns |
| `learning.workflow.suggest_threshold` | `0.5` | Confidence threshold to suggest next command |
| `learning.workflow.trigger_threshold` | `0.8` | Confidence threshold to auto-trigger command chains |
| `learning.autonomy.max_level` | `notify` | Ceiling for autonomous actions: `ask`, `suggest`, `notify`, `silent` |
| `healing.enabled` | `true` | Enable/disable self-healing retries |
| `healing.max_retries` | `3` | Number of retry attempts for transient errors |
| `healing.fallback.enabled` | `true` | Allow graceful degradation when all retries fail |
| `hooks.retention_days` | `30` | Raw event retention period in days |
| `hooks.decision_points` | `true` | Capture decision-point events for richer pattern data |

## Notion Integration

When Notion MCP is configured, the `notion-sync` skill syncs intelligence data to and from the `[FOS] Intelligence` database:

- **Push**: Patterns and healing patterns are pushed after each sync trigger, using incremental updates (only rows changed since last sync)
- **Pull**: Status changes, instruction edits, and confidence overrides made in Notion are pulled back to the local database
- **Conflict resolution**: Local data is the source of truth; Notion reflects it. Manual Notion edits to status, instruction, and confidence are respected on pull

Sync is triggered via `/memory:sync` (shared trigger with Memory Hub) or on demand. It never blocks plugin execution — if Notion is unavailable, sync is silently skipped.

## Architecture

```
founder-os-adaptive-intel/       # This plugin (user-facing control panel)
├── commands/                    # /intel:status, :patterns, :approve, :reset, :healing, :config
└── skills/notion-sync/          # Bidirectional sync with [FOS] Intelligence Notion DB

_infrastructure/intelligence/    # Shared infrastructure (not user-facing)
├── .data/                       # Runtime data (gitignored)
│   └── intelligence.db
├── hooks/                       # Event capture layer (pre/post command hooks)
│   ├── schema/
│   │   └── intelligence.sql     # 4-table schema
│   └── SKILL.md                 # Event observation conventions
├── learning/                    # Pattern detection and injection
│   ├── taste-learning/
│   │   └── SKILL.md             # Tier 1: output preference detection
│   └── SKILL.md                 # Learning cycle reference
├── self-healing/                # Error recovery
│   ├── fallback-registry/
│   │   └── SKILL.md             # Seed fallback data for all 30 plugins
│   └── SKILL.md                 # Error classification and retry engine
└── SKILL.md                     # Master reference
```

The plugin is a thin command layer. All event capture, pattern detection, pattern injection, and self-healing are implemented in `_infrastructure/intelligence/` and operate transparently across all Founder OS plugins that have hooks integration.

```
Event Flow:
  Plugin command runs
       │
       ▼
  [hooks] pre_command event written
       │
       ▼
  [pattern-injector] active patterns prepended to context
       │
       ▼
  Command executes
       │
  (on error) ──────────────────────────────────────────────────────────┐
       │                                                                │
       ▼                                                                ▼
  [hooks] post_command event written               [self-healing] retry or fallback
       │                                                                │
       ▼                                                                ▼
  [pattern-detector] observations logged               [hooks] healing event written
       │
       ▼
  Pattern confidence updated
       │
  (threshold reached) → pattern promoted to active/approved
```

## Relationship to Memory Engine

Memory Engine and Adaptive Intelligence are complementary layers:

| | Memory Engine | Adaptive Intelligence |
|--|---|---|
| **Source** | User-taught (`/memory:teach`) | Observed behavior (hooks) |
| **Storage** | `.memory/memory.db` | `_infrastructure/intelligence/.data/intelligence.db` |
| **Notion DB** | `[FOS] Memory` | `[FOS] Intelligence` |
| **Control plugin** | Memory Hub (#31) | Adaptive Intelligence (#32) |
| **Injection point** | Step 0 of every command | Step 0 of every command (after memory injection) |

Both layers inject context at the start of each plugin command. Memory Engine provides explicit facts; Adaptive Intelligence provides inferred behavioral preferences.

## Design Spec

For full architecture details, see:
- Intelligence engine spec: `docs/superpowers/specs/[3]-2026-03-11-intelligence-engine-design.md`
- Infrastructure layer: `_infrastructure/intelligence/hooks/SKILL.md`

## Dependencies

This plugin has no hard dependencies on other Founder OS plugins. Memory Hub is optional but recommended — when both are installed, the context injection step combines memory facts with learned intelligence patterns.

## License

MIT
