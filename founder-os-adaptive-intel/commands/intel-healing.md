---
name: intel-healing
description: View self-healing event log, error frequency analysis, and fallback acceptance rates
usage: /intel:healing [--plugin=<name>]
arguments:
  - name: --plugin
    description: Filter to a specific plugin
    required: false
---

## Self-Healing Event Log

### Step 1: Query Healing Data

Read from the Intelligence database.

**Recent healing events** (last 7 days):
```sql
SELECT timestamp, plugin, command, payload, outcome
FROM events
WHERE event_type = 'error'
  AND timestamp > datetime('now', '-7 days')
  [AND plugin = ? -- if --plugin provided]
ORDER BY timestamp DESC
LIMIT 20
```

**Error frequency** (last 30 days):
```sql
SELECT plugin, json_extract(payload, '$.error_type') as error_type, COUNT(*) as count
FROM events
WHERE event_type = 'error'
  AND timestamp > datetime('now', '-30 days')
GROUP BY plugin, error_type
ORDER BY count DESC
```

**Healing pattern effectiveness**:
```sql
SELECT error_signature, category, fix_action, success_count, failure_count,
  ROUND(CAST(success_count AS REAL) / MAX(1, success_count + failure_count) * 100) as success_rate
FROM healing_patterns
ORDER BY (success_count + failure_count) DESC
LIMIT 10
```

**Systemic issues** (errors recurring 3+ times across sessions):
```sql
SELECT json_extract(payload, '$.error_type') as error_type, plugin, COUNT(DISTINCT session_id) as sessions
FROM events
WHERE event_type = 'error'
  AND timestamp > datetime('now', '-30 days')
GROUP BY error_type, plugin
HAVING sessions >= 3
ORDER BY sessions DESC
```

### Step 2: Display Report

```
── Self-Healing Report ───────────────────────────
Period: last 7 days | Filter: {plugin or "all"}

── Recent Events ─────────────────────────────────
{timestamp}  {plugin}/{command}  {error_type} → {outcome}
  {recovery details from payload}
(repeat for up to 20 events)

── Error Frequency (30 days) ─────────────────────
{plugin}         {error_type}              {count}x
(heatmap-style, most frequent first)

── Fix Effectiveness ─────────────────────────────
{error_signature}  {fix_action}  {success_rate}% ({success}/{total})
(top 10 by volume)

── Systemic Issues ───────────────────────────────
⚠ {error_type} in {plugin} — recurring across {sessions} sessions
(only shown if any exist; these need manual attention)
```
