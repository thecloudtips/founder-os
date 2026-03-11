---
name: intel-reset
description: Clear learned patterns for a specific plugin or all plugins
usage: /founder-os:intel:reset [plugin|all]
arguments:
  - name: scope
    description: Plugin name to reset, or "all" for everything (if omitted, prompts user to specify)
    required: false
  - name: --type
    description: Only reset patterns of a specific type (taste|workflow|autonomy)
    required: false
---

## Reset Learned Patterns

### Step 1: Count Affected Patterns

Query the Intelligence database:
```sql
SELECT COUNT(*) FROM patterns
WHERE 1=1
  [AND plugin = ? -- if scope != 'all']
  [AND pattern_type = ? -- if --type provided]
```

If count is 0, display: `"No patterns found matching the filter."`

### Step 2: Confirm with User

```
This will remove {count} learned patterns:
  Scope: {plugin or "all plugins"}
  Type: {type or "all types"}

Raw events will NOT be deleted — only distilled patterns.
Patterns can be re-learned from future observations.

Type 'confirm' to proceed:
```

Wait for user to type "confirm". Any other input cancels.

### Step 3: Delete Patterns

```sql
DELETE FROM patterns
WHERE 1=1
  [AND plugin = ? -- if scope != 'all']
  [AND pattern_type = ? -- if --type provided]
```

Display: `"✓ Removed {count} patterns. The Intelligence Engine will re-learn from future observations."`
