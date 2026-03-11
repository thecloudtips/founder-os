---
name: adaptive-intelligence
description: Master reference for the Adaptive Intelligence Engine. Describes the four modules (hooks, learning, self-healing, routing), how plugins integrate, and the relationship to the Memory Engine.
---

## Overview

The Adaptive Intelligence Engine is a behavioral layer that observes, learns from, and improves Founder OS plugin execution. It sits on top of the Memory Engine (storage) and provides:

1. **Hooks** — structured event capture from every plugin execution
2. **Learning** — pattern detection and preference learning across three tiers
3. **Self-Healing** — error classification, retry, and graceful degradation
4. **Routing** — adaptive task routing (future)

## Architecture

```
Memory Engine (storage) ← Intelligence Layer (behavior) ← Adaptive Intel plugin (user commands)
                              ↑
                         All 30 plugins (emit events via convention)
```

- **Infrastructure**: `_infrastructure/intelligence/` — SKILL.md files, SQL schema. No commands.
- **Plugin**: `founder-os-adaptive-intel/` — 6 slash commands for user control
- **Database**: Own SQLite DB (`intelligence.db`), separate from Memory Engine

## Plugin Integration

Every plugin command file adds observation blocks to emit events. See `_infrastructure/intelligence/hooks/SKILL.md` for the full convention and annotation templates.

**Minimum integration** (all plugins):
- Pre-command observation block (~5 lines at top of command)
- Post-command observation block (~5 lines at bottom of command)

**Enhanced integration** (plugins with complex logic):
- MCP call annotations before significant external calls
- Decision point annotations at key branching logic

## Modules

| Module | Location | Ships In |
|---|---|---|
| Hooks | `hooks/SKILL.md` | Chunk 1 |
| Taste Learning | `learning/taste-learning/SKILL.md` | Chunk 2 |
| Self-Healing | `self-healing/SKILL.md` | Chunk 3 |
| Workflow Optimization | `learning/workflow-optimization/SKILL.md` | Chunk 5 (future) |
| Confidence Gating | `learning/confidence-gating/SKILL.md` | Chunk 6 (future) |
| Routing | `routing/SKILL.md` | Chunk 7 (future) |

## Cross-Plugin Knowledge Boundary

Patterns that reference a Company or Contact are promoted to the Memory Engine for cross-plugin availability. Plugin-specific output preferences stay in the Intelligence DB. See the design spec for the full mapping table.

**Confidence scale conversion**: Intelligence uses 0.0-1.0; Memory Engine uses 0-100. Convert with `round(confidence * 100)`.
