---
name: intel-approve
description: Promote a learned pattern to permanently approved status
usage: /founder-os:intel:approve <pattern-id>
arguments:
  - name: pattern-id
    description: The ID of the pattern to approve
    required: true
---

## Approve a Pattern

### Step 1: Validate Pattern

Query the Intelligence database for the pattern:
```sql
SELECT * FROM patterns WHERE id = ?
```

If not found, display: `"Pattern '{id}' not found. Run /founder-os:intel:patterns to see available patterns."`

If already approved, display: `"Pattern '{id}' is already approved."`

### Step 2: Confirm with User

Display the pattern details and ask for confirmation:
```
Approving pattern: "{description}"
Plugin: {plugin} | Command: {command or "all"}
Current confidence: {confidence} | Status: {status}

This pattern will be:
- Permanently applied to all matching command runs
- Confidence locked at 1.0
- Will not be automatically rejected by future corrections

Confirm? (yes/no)
```

### Step 3: Apply Approval

```sql
UPDATE patterns
SET status = 'approved', confidence = 1.0, updated_at = datetime('now')
WHERE id = ?
```

Display: `"✓ Pattern '{id}' approved. It will be applied to all future {plugin}/{command} runs."`
