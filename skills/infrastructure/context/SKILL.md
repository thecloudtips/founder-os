---
name: business-context
description: "Loads structured business context files into plugin execution context. Activates at the start of any plugin command to provide business knowledge, current strategy, and operational data. Plugins inline the loading logic directly (same pattern as gws CLI usage)."
---

## Overview

Founder OS plugins can load structured business context files to personalize their output. Context files live at `_infrastructure/context/active/` and contain business information, current strategy, and operational data maintained by the user.

## Context Files

| File | Purpose | Update Frequency |
|------|---------|-----------------|
| `business-info.md` | Company overview, team, tools, clients | Quarterly or when business changes |
| `strategy.md` | Current priorities, constraints, opportunities | Monthly or at quarter boundaries |
| `current-data.md` | Active clients, key metrics, Notion DB IDs | Weekly or as data changes |

## Loading Pattern (for plugin command files)

Add this section near the top of any plugin command, AFTER skill loading but BEFORE main logic:

~~~markdown
## Step 0: Business Context
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read:
- `_infrastructure/context/active/business-info.md`
- `_infrastructure/context/active/strategy.md`
- `_infrastructure/context/active/current-data.md`
Inject their contents into your working memory for this execution. Use this context to personalize output (e.g., prioritize known VIP clients, use correct company terminology, align recommendations with current strategy).
If files don't exist or directory is empty, skip silently and proceed without business context (graceful degradation).
~~~

## How Context Improves Plugin Output

- **P01 Inbox Zero**: Knows which clients are VIP, prioritizes their emails
- **P02 Daily Briefing**: Aligns briefing sections with current strategic priorities
- **P10 Client Health**: Uses active client list instead of requiring manual input
- **P12 Proposal Automator**: Pre-fills company info, aligns with current positioning
- **P20 Client Context**: Cross-references with known client data

## Setup

Run `/founder-os:context:setup` to create context files via guided interview. Or copy templates from `_infrastructure/context/templates/` to `_infrastructure/context/active/` and fill them in manually.

## Relationship to Memory Engine

These context files are Phase 0 of the Founder OS Memory Engine (spec: `docs/superpowers/specs/2026-03-11-memory-engine-design.md`). When the full Memory Engine ships (SQLite+HNSW), it will:
1. Read these files as seed data on first run
2. The memory context-injection skill will supersede this simple file-loading approach
3. Context files can continue to exist as a human-editable layer alongside the database
