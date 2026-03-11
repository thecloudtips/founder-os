---
name: intel-config
description: View and modify Adaptive Intelligence Engine configuration
usage: /founder-os:intel:config [key] [value]
arguments:
  - name: key
    description: Configuration key to view or set (e.g., learning.taste.threshold)
    required: false
  - name: value
    description: New value to set
    required: false
  - name: --reset
    description: Reset all configuration to defaults
    required: false
---

## Intelligence Configuration

### Step 1: Determine Action

- No arguments → show all config
- `key` only → show that key's value
- `key value` → update that key
- `--reset` → reset all to defaults

### Step 2: Show All Config (no arguments)

```sql
SELECT key, value FROM config ORDER BY key
```

Display as:
```
── Intelligence Configuration ────────────────────
learning.enabled              true
learning.taste.threshold      0.5       # confidence to auto-apply taste patterns
learning.workflow.suggest_threshold 0.5  # confidence to suggest next command
learning.workflow.trigger_threshold 0.8  # confidence to auto-trigger chains
learning.autonomy.max_level   notify    # cap: ask | suggest | notify | silent
healing.enabled               true
healing.max_retries           3         # retry attempts for transient errors
healing.fallback.enabled      true      # allow graceful degradation
hooks.retention_days          30        # raw event retention period
hooks.decision_points         true      # capture decision-point events

Usage: /founder-os:intel:config <key> <value> to change a setting
       /founder-os:intel:config --reset to restore defaults
```

### Step 3: Show Single Key (key only, no value)

```sql
SELECT value FROM config WHERE key = ?
```

If not found: `"Unknown config key '{key}'. Run /founder-os:intel:config to see available keys."`

Display as:
```
── Intelligence Configuration ────────────────────
{key}: {value}
```

### Step 4: Update Config (key + value)

Validate the key exists:
```sql
SELECT value FROM config WHERE key = ?
```

If not found: `"Unknown config key '{key}'. Run /founder-os:intel:config to see available keys."`

Validate the value:
- Boolean keys (`*.enabled`, `hooks.decision_points`): accept "true"/"false"
- Number keys (`*.threshold`, `*.max_retries`, `*.retention_days`): accept numeric values
- Enum keys (`learning.autonomy.max_level`): accept "ask"/"suggest"/"notify"/"silent"

If validation fails, show: `"Invalid value '{value}' for {key}. Expected: {expected_type_or_options}."`

Update:
```sql
UPDATE config SET value = ? WHERE key = ?
```

Display: `"✓ Updated {key}: {old_value} → {new_value}"`

### Step 5: Reset (--reset flag)

Confirm: `"Reset all intelligence configuration to defaults? Type 'confirm':"`

If not confirmed, display: `"Reset cancelled."` and stop.

On confirmation, delete and re-insert defaults:
```sql
DELETE FROM config WHERE key NOT IN ('notion.last_sync');

INSERT OR REPLACE INTO config (key, value) VALUES
    ('learning.enabled', 'true'),
    ('learning.taste.threshold', '0.5'),
    ('learning.workflow.suggest_threshold', '0.5'),
    ('learning.workflow.trigger_threshold', '0.8'),
    ('learning.autonomy.max_level', 'notify'),
    ('healing.enabled', 'true'),
    ('healing.max_retries', '3'),
    ('healing.fallback.enabled', 'true'),
    ('hooks.retention_days', '30'),
    ('hooks.decision_points', 'true');
```

Display: `"✓ All configuration reset to defaults."`

### Notes

- The `notion.last_sync` key is managed internally and excluded from reset
- Threshold values are in the range 0.0–1.0 (probability)
- `learning.autonomy.max_level` sets the ceiling for autonomous behavior — the engine never acts above this level even if confidence warrants it
- Changes take effect immediately; no restart needed
