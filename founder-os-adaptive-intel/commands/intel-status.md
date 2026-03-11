---
name: intel-status
description: Dashboard view of the Adaptive Intelligence Engine — shows hooks activity, learned patterns, self-healing events, and workflow chains
usage: /intel:status
arguments: none
---

## Intelligence Status Dashboard

Display a comprehensive dashboard of the Adaptive Intelligence Engine state.

### Step 1: Read Intelligence Database

Read the Intelligence SQLite database at `_infrastructure/intelligence/.data/intelligence.db`.

If the database does not exist, display:
```
── Adaptive Intelligence Status ──────────────────
Status: Not initialized
Run any plugin command to begin capturing events.
```
And stop here.

### Step 2: Gather Metrics

Query the following from the Intelligence database:

**Hooks metrics** (last 30 days):
- Total events captured: `SELECT COUNT(*) FROM events WHERE timestamp > datetime('now', '-30 days')`
- Events by type: `SELECT event_type, COUNT(*) FROM events WHERE timestamp > datetime('now', '-30 days') GROUP BY event_type`
- Unique plugins observed: `SELECT COUNT(DISTINCT plugin) FROM events WHERE timestamp > datetime('now', '-30 days')`

**Pattern metrics**:
- Total patterns: `SELECT COUNT(*) FROM patterns`
- By status: `SELECT status, COUNT(*) FROM patterns GROUP BY status`
- Top 3 active patterns (highest confidence): `SELECT plugin, description, confidence, confirmations, rejections FROM patterns WHERE status IN ('active', 'approved') ORDER BY confidence DESC LIMIT 3`

**Healing metrics** (last 30 days):
- Total healing events: `SELECT COUNT(*) FROM events WHERE event_type = 'error' AND timestamp > datetime('now', '-30 days')`
- Recovery success rate: count events where `recovery_attempted` is not null in payload, vs total errors
- Recent healing events (last 5): `SELECT timestamp, plugin, command, payload FROM events WHERE event_type = 'error' ORDER BY timestamp DESC LIMIT 5`

### Step 3: Display Dashboard

Format output as:

```
── Adaptive Intelligence Status ──────────────────
Hooks:      active | {total_events} events captured (last 30 days)
Learning:   {enabled/disabled} | {pattern_count} patterns ({active} active, {candidate} candidate, {approved} approved, {rejected} rejected)
Self-Heal:  {enabled/disabled} | {healing_count} recoveries this month ({success_rate}% success rate)

── Top Active Patterns ───────────────────────────
#{n}  {plugin}    "{description}"     conf: {confidence}  ✓ {confirmations}/{confirmations+rejections}
(repeat for top 3, or "No patterns learned yet" if empty)

── Recent Healing Events ─────────────────────────
{timestamp}  {plugin}  {command}  {summary from payload}
(repeat for last 5, or "No healing events" if empty)

── Configuration ─────────────────────────────────
Taste threshold: {value} | Workflow threshold: {value} | Max autonomy: {value}
Healing retries: {value} | Fallback: {enabled/disabled} | Retention: {value} days
```

### Notes
- All queries use read-only access to the Intelligence database
- If any query fails, show "unavailable" for that section rather than failing the entire command
- Event counts are approximate — they reflect the retention window, not all-time totals
