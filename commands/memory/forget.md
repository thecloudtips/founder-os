---
description: Delete a memory and revert any behavior it triggered
argument-hint: '<key> [--force]'
allowed-tools: Read, Bash
---

# Memory Forget

Delete a named memory from the Founder OS memory store and revert any active behavior adaptations it triggered.

## Parse Arguments

Extract these from `$ARGUMENTS`:
- `key` (string, required) — the memory key to delete (e.g., `acme-vip-flag`)
- `--force` (boolean, default: false) — skip the confirmation prompt and delete immediately

## Step 1: Initialize Memory Store

Read the core memory skill at `_infrastructure/memory/SKILL.md` for the full API.

Check that the store exists:

```bash
if [ ! -f ".memory/memory.db" ]; then
  echo "Memory store not found at .memory/memory.db — nothing to forget."
  exit 0
fi
```

Validate the schema:

```sql
SELECT name FROM sqlite_master
WHERE type='table'
AND name IN ('memories', 'observations', 'adaptations');
-- Expected: 3 rows. If fewer, the store is uninitialized — nothing to delete.
```

If the store is missing or uninitialized, report "No memory store found — nothing to forget." and stop.

## Step 2: Look Up the Memory

Call `memory_get(key)` — exact key lookup:

```sql
SELECT id, key, category, content, source_plugin, company_id, tags,
       confidence, status, times_used, times_confirmed, created_at, updated_at, last_used_at
FROM memories
WHERE key = ?;
```

**If not found**: run a fuzzy search to suggest alternatives:

```sql
-- Fuzzy match: keys that contain the search term as a substring
SELECT key, content, confidence, status
FROM memories
WHERE key LIKE '%' || ? || '%'
   OR content LIKE '%' || ? || '%'
ORDER BY confidence DESC
LIMIT 3;
```

If fuzzy matches exist, output:

```
Memory 'acme-vip' not found. Did you mean:
  - acme-vip-flag
  - acme-action-emails
  - acme-payment-terms

Run: /founder-os:memory:forget acme-vip-flag
```

If no matches at all: output "Memory '[key]' not found. Use /founder-os:memory:list to browse all stored memories." and stop.

## Step 3: Check for Active Adaptations

Before prompting, look up any active adaptations linked to this memory:

```sql
SELECT id, plugin, description, applied_at
FROM adaptations
WHERE memory_id = (SELECT id FROM memories WHERE key = ?)
  AND reverted_at IS NULL;
```

Note the count and descriptions for display in the confirmation prompt.

## Step 4: Confirm Deletion (unless --force)

If `--force` is NOT present, display the memory details and ask for confirmation:

```
Delete this memory?

  Key:         acme-vip-flag
  Category:    preference
  Content:     Always flag @acmecorp.com emails as VIP
  Confidence:  95 (applied)
  Source:      P21 (last used 2 days ago, 14 times)
  Active adaptation: Auto-flagging @acmecorp.com emails as VIP (P01 Inbox Zero)

  Warning: deleting this memory will revert the active adaptation.

Confirm? (y/n):
```

- If user replies `n` or anything other than `y`/`yes`: output "Deletion cancelled." and stop.
- If `--force` is set: skip this prompt entirely and proceed.

## Step 5: Execute Deletion

Run `memory_delete(key)` as a three-step transaction:

### Step 5a: Revert active adaptations

```sql
UPDATE adaptations
SET reverted_at = unixepoch()
WHERE memory_id = (SELECT id FROM memories WHERE key = ?)
  AND reverted_at IS NULL;
```

### Step 5b: Delete the memory row (also removes the inline embedding)

```sql
DELETE FROM memories WHERE key = ?;
```

### Step 5c: Verify deletion

```sql
SELECT COUNT(*) FROM memories WHERE key = ?;
-- Expected: 0
```

If COUNT is still 1, report a SQLite error and stop.

## Step 6: Archive in Notion (soft delete)

Look up the `[FOS] Memory` database in Notion (search "FOS Memory" first, then "Founder OS HQ - Memory" for fallback).

Find the page where the `Key` property matches the deleted key:

- Set the page `Status` property to `Archived`
- Add a `Deleted At` timestamp property with the current date
- Do NOT hard-delete the Notion page — it serves as an audit trail

If the Notion MCP is unavailable or the page is not found, skip silently and note `notion_sync: "unavailable"` in output. This is a non-blocking step.

## Step 7: Confirm to User

Output a clean confirmation:

```
Forgotten: acme-vip-flag

  - Memory deleted from local store
  - Embedding removed from HNSW index
  - Adaptation reverted: Auto-flagging @acmecorp.com emails as VIP (P01)
  - Archived in Notion [FOS] Memory (audit trail preserved)

This behavior will no longer apply. To re-teach it, use /founder-os:memory:teach.
```

If there were no active adaptations, omit the adaptation line.

If Notion sync was skipped, append: `(Notion sync skipped — archived locally only)`

## Error Handling

| Error | Action |
|-------|--------|
| `.memory/memory.db` not found | Report "No memory store found — nothing to forget." and stop |
| Key not found, no fuzzy matches | Report not-found message, suggest `/founder-os:memory:list` |
| Key not found, fuzzy matches exist | Show up to 3 suggestions and stop |
| SQLite locked | Retry up to 3 times with 500ms delay (WAL mode); report failure if all retries fail |
| Notion MCP unavailable | Skip Notion archive step silently, note in output |
| Deletion verification fails | Report SQLite error with raw message; do not claim success |

## Usage Examples

```
/founder-os:memory:forget acme-vip-flag            # Look up, show details, confirm before deleting
/founder-os:memory:forget acme-vip-flag --force    # Delete immediately, no confirmation prompt
/founder-os:memory:forget acme-vip                 # Key not found → suggest acme-vip-flag etc.
```
