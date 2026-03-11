# Quick Start: founder-os-adaptive-intel

> The control panel for the Founder OS intelligence layer — view learned patterns, manage self-healing, and tune confidence thresholds across all 30 plugins.

## Overview

**Plugin #32** | **Pillar**: Meta & Growth | **Platform**: Claude Code

Adaptive Intelligence gives you direct visibility and control over the intelligence layer that operates beneath all Founder OS plugins. Every time you run a plugin command, the hooks layer captures behavioral events, learns patterns from your usage, and heals transient failures automatically. This plugin lets you see what's been learned, approve patterns, tune thresholds, and inspect healing activity — all through six commands.

### What This Plugin Does

- Displays a live dashboard of hooks activity, learned patterns, and self-healing events
- Lets you browse, filter, approve, and reset learned behavioral patterns
- Shows a self-healing event log with error frequency analysis and fix effectiveness rates
- Exposes all configuration knobs for the intelligence engine in a single interface
- Syncs intelligence state to/from the Notion `[FOS] Intelligence` database

## Available Commands

| Command | Description |
|---------|-------------|
| `/intel:status` | Dashboard view of intelligence state |
| `/intel:patterns` | View learned patterns |
| `/intel:approve <id>` | Promote a pattern to permanent |
| `/intel:reset` | Clear learned patterns |
| `/intel:healing` | Self-healing event log |
| `/intel:config` | View and modify configuration |

---

## Command Examples

### /intel:status — Dashboard View

```
/intel:status
```

Shows the full intelligence dashboard: hooks activity, pattern counts by status, top 3 active patterns by confidence, and recent healing events. Run this any time to get a health snapshot of the intelligence engine.

```
/intel:status
```

Sample output:
```
── Adaptive Intelligence Status ──────────────────
Hooks:      active | 342 events captured (last 30 days)
Learning:   enabled | 8 patterns (5 active, 2 candidate, 1 approved, 0 rejected)
Self-Heal:  enabled | 12 recoveries this month (91% success rate)

── Top Active Patterns ───────────────────────────
#1  inbox-zero    "prefer bullet-point summaries"  conf: 0.87  ✓ 12/13
#2  weekly-review "include time metrics"           conf: 0.81  ✓ 9/11
#3  cross-plugin  "formal tone in all outputs"     conf: 0.75  ✓ 7/10
```

---

### /intel:patterns — Browse Learned Patterns

```
/intel:patterns
```

Lists all learned patterns across all plugins. Patterns are ordered by confidence.

```
/intel:patterns --plugin=inbox-zero
```

Filters to patterns learned from Inbox Zero usage only.

```
/intel:patterns --type=taste
```

Filters to taste patterns (user style and format preferences). Also supports `--type=workflow`.

```
/intel:patterns 3
```

Shows the full detail view for pattern #3, including the complete instruction text that gets injected into plugin commands.

---

### /intel:approve — Make a Pattern Permanent

```
/intel:approve 3
```

Promotes pattern #3 to "approved" status with maximum confidence (1.0). Approved patterns are always applied and are never automatically demoted. Use this to lock in behaviors you want to make permanent before they reach the automatic threshold.

---

### /intel:reset — Clear Patterns

```
/intel:reset --plugin=inbox-zero
```

Clears all patterns learned from Inbox Zero. Other plugins' patterns are untouched. Prompts for confirmation before deleting.

```
/intel:reset --type=workflow
```

Clears all workflow-type patterns (command sequence suggestions). Taste patterns are preserved.

```
/intel:reset --all
```

Clears all patterns and healing data. Requires explicit confirmation. Use with caution — this cannot be undone.

---

### /intel:healing — Self-Healing Event Log

```
/intel:healing
```

Shows the last 7 days of healing events, error frequency analysis for the last 30 days, and fix effectiveness rates for all known healing patterns.

```
/intel:healing --plugin=client-health
```

Filters the recent events section to Client Health plugin failures only. Error frequency and fix effectiveness tables remain unfiltered for full context.

---

### /intel:config — View and Modify Configuration

```
/intel:config
```

Shows all 10 configuration keys with current values and inline comments explaining each setting.

```
/intel:config learning.autonomy.max_level suggest
```

Changes the autonomy ceiling from the default "notify" to "suggest". Valid values: `ask`, `suggest`, `notify`, `silent`.

```
/intel:config learning.taste.threshold 0.7
```

Raises the confidence threshold for automatically applying taste patterns. Higher values mean the engine waits for more evidence before adapting.

```
/intel:config --reset
```

Resets all configuration to defaults. Prompts for confirmation.

---

## Tips

- Run `/intel:status` after your first week of plugin usage to see what the engine has learned
- Use `/intel:approve` liberally for patterns you know are correct — don't wait for the confidence threshold
- If a pattern is wrong, use `/intel:reset --plugin=<name>` to clear it and start fresh for that plugin
- Lower `learning.taste.threshold` (e.g., to `0.3`) if you want the engine to adapt faster
- Raise `learning.workflow.trigger_threshold` (e.g., to `0.9`) if auto-triggered command chains feel premature
- Set `learning.autonomy.max_level=ask` if you want explicit approval before any autonomous action

## Related Plugins

- **Memory Hub (#31)**: Manages user-taught memories (explicit facts). Adaptive Intelligence manages observed patterns (inferred from behavior). Both share the context injection layer.
- **Workflow Automator (#27)**: Workflow patterns learned by the intelligence engine can feed into P27 automation chains.
- **Time Savings Calculator (#25)**: ROI tracking benefits from accurate plugin usage data captured by the hooks layer.

## Next Steps

1. Run `/intel:status` to verify the engine is active
2. Use your Founder OS plugins normally for a few days
3. Run `/intel:patterns` to review what's been learned
4. Run `/intel:approve <id>` on any pattern you want to lock in
5. Run `/intel:config` to tune thresholds to your preferred autonomy level
