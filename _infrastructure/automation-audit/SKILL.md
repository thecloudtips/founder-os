---
name: automation-audit
description: "Scans Founder OS plugin deployment, scores coverage by business area, and produces an actionable automation scorecard. Used by /audit:scan and /audit:report commands."
---

## Overview

The automation audit infrastructure detects which of the 30 Founder OS plugins are installed and actively configured, then scores coverage across 9 business areas using weighted metrics from the audit registry.

## Detection Logic

For each plugin in `schema/audit-registry.json`:

1. **Installed**: Check if `[directory]/.claude-plugin/plugin.json` exists on the filesystem
2. **Configured**: Check if required MCP servers are configured (via `.mcp.json` in plugin directory)
3. **Active**: (Optional, requires Notion) Query for the plugin's associated Notion database using HQ DB discovery pattern: search "[FOS] [DB Name]" first, fall back to "Founder OS HQ - [DB Name]"

### Scoring

- **Plugin Deployment %** = (installed plugins / 30) x 100
- **Area Coverage %** = for each area: (sum of installed plugin weights / total area weight) x 100
- **Overall Area Coverage** = weighted average across all 9 areas (weighted by area total weight to reflect importance)

## Scorecard Format

```
Founder OS Automation Scorecard
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Plugin Deployment: [X]% ([N]/30 plugins installed)
Area Coverage: [Y]% (weighted by business impact)

By Business Area:
  [Area Name]    [bar]  [%]  ([active plugins])
  ...

Top Gaps:
  1. [Area] at [%] — install [Plugin] for +[weight]% boost
  2. ...

Scheduled Plugins: [N]/[installed] (see /audit:report for details)
```

## Notion Output

Write audit results to Reports DB:
- Type: "Automation Audit"
- Title: "Automation Audit — [date]"
- Follow HQ DB discovery: search "[FOS] Reports" first
- Idempotent: if an audit for today's date exists, update it; don't duplicate

## References

- `schema/audit-registry.json` — Plugin-to-area mapping with coverage weights
- `references/task-categories.md` — Detailed breakdown of what each area covers
