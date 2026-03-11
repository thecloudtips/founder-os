---
name: intel-patterns
description: View and explore learned patterns from the Adaptive Intelligence Engine
usage: /intel:patterns [plugin|all]
arguments:
  - name: scope
    description: Plugin name to filter by, or "all" for everything (default: all)
    required: false
  - name: --type
    description: Filter by pattern type (taste|workflow|autonomy)
    required: false
  - name: --status
    description: Filter by status (candidate|active|approved|rejected)
    required: false
  - name: --detail
    description: Show full history for a specific pattern ID
    required: false
---

## View Learned Patterns

### Step 1: Parse Arguments

- `scope`: plugin name or "all" (default: "all")
- `--type`: filter by pattern_type
- `--status`: filter by status
- `--detail <id>`: show detailed view of one pattern

### Step 2: Query Patterns

Read from the Intelligence database (`_infrastructure/intelligence/.data/intelligence.db`).

If `--detail <id>` is provided:
```sql
SELECT * FROM patterns WHERE id = ?
```
Also query related events:
```sql
SELECT * FROM events
WHERE plugin = (SELECT plugin FROM patterns WHERE id = ?)
  AND command = (SELECT command FROM patterns WHERE id = ?)
  AND event_type IN ('decision_point', 'post_command')
ORDER BY timestamp DESC
LIMIT 20
```

Otherwise, build a filtered query:
```sql
SELECT id, pattern_type, plugin, command, description, instruction, confidence, observations, confirmations, rejections, status, updated_at
FROM patterns
WHERE 1=1
  [AND plugin = ? -- if scope != 'all']
  [AND pattern_type = ? -- if --type provided]
  [AND status = ? -- if --status provided]
ORDER BY confidence DESC, observations DESC
```

### Step 3: Display Results

**List view** (default):
```
── Learned Patterns ──────────────────────────────
Filter: {scope} | Type: {type or "all"} | Status: {status or "all"}

ID        Plugin          Type    Confidence  Status     Description
────────  ──────────────  ──────  ──────────  ─────────  ───────────────────────────
abc123    inbox-zero      taste   0.82        active     concise email drafts under 150 words
def456    daily-briefing  taste   0.71        active     lead briefings with revenue metrics
ghi789    cross-plugin    taste   0.65        active     Acme Corp prefers formal tone

Total: {count} patterns
```

**Detail view** (`--detail <id>`):
```
── Pattern Detail: {id} ──────────────────────────
Plugin:       {plugin}
Command:      {command or "all commands"}
Type:         {pattern_type}
Status:       {status}
Confidence:   {confidence} ({confirmations} confirmed, {rejections} rejected)
Observations: {observations}
Created:      {created_at}
Updated:      {updated_at}

Instruction (injected into plugin context):
  "{instruction}"

Recent Related Events:
  {timestamp}  {event_type}  {summary from payload}
  ...
```

### Step 4: Offer Actions

After displaying patterns, suggest available actions:
- "Run `/intel:approve <id>` to promote a pattern to permanent"
- "Run `/intel:reset <plugin>` to clear patterns for a plugin"
