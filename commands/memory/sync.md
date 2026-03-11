---
description: Force sync between local memory store and Notion [FOS] Memory database
argument-hint: "[--direction push|pull|both] [--dry-run]"
allowed-tools: Read, Bash
---

# Memory Sync

Force a bidirectional (or one-way) sync between the local SQLite memory store and the `[FOS] Memory` Notion database.

## Parse Arguments

Extract these flags from `$ARGUMENTS`:
- `--direction` (string, one of: `push`, `pull`, `both`; default: `both`) — which direction to sync
- `--dry-run` (boolean, default: false) — when present, show what would happen without writing any changes

## Load Skills

Read both skills before proceeding:
1. `_infrastructure/memory/SKILL.md` — core memory engine API (SQLite operations, status rules, confidence mechanics)
2. `${CLAUDE_PLUGIN_ROOT}/skills/memory/notion-sync/SKILL.md` — Notion field mapping, conflict rules, rate-limit handling

Then initialize the memory store per the core skill's initialization steps:
```bash
if [ ! -f ".memory/memory.db" ]; then
  echo "Initializing memory store..."
  mkdir -p .memory
  sqlite3 .memory/memory.db < _infrastructure/memory/schema/memory-store.sql
fi
```

## Step 1: Discover [FOS] Memory DB

Use the DB discovery procedure from the notion-sync skill:
1. Search Notion for `[FOS] Memory`
2. If not found, search for `Founder OS HQ - Memory`
3. If neither found, lazy-create using the schema defined in the notion-sync skill
4. Store the database ID for all subsequent API calls

## Step 2: Push (Local → Notion)

Skip if `--direction pull`.

Query the local store for memories that need pushing:

```sql
-- Records never synced OR updated since last sync
SELECT id, key, category, content, confidence, status,
       source_plugin, company_id, tags, times_used, last_used_at,
       updated_at, notion_page_id, deleted_at
FROM memories
WHERE deleted_at IS NULL
  AND (notion_page_id IS NULL OR updated_at > last_synced_at)

UNION ALL

-- Records deleted locally that have a Notion page
SELECT id, key, category, content, confidence, status,
       source_plugin, company_id, tags, times_used, last_used_at,
       updated_at, notion_page_id, deleted_at
FROM memories
WHERE deleted_at IS NOT NULL
  AND notion_page_id IS NOT NULL
  AND (last_synced_at IS NULL OR deleted_at > last_synced_at);
```

For each record to push:

**New records** (no `notion_page_id`):
- Create a new Notion page using the field mapping from the notion-sync skill
- Store the returned Notion page ID in `memories.notion_page_id`

**Updated records** (has `notion_page_id`):
- Update the existing Notion page with current field values

**Deleted records** (has `deleted_at` + `notion_page_id`):
- Archive the Notion page (set `archived: true`)

Batch creates in groups of up to 10. On 429 errors, apply exponential backoff per the notion-sync skill's rate-limit rules.

Track counts: `pushed_new`, `pushed_updated`, `pushed_deleted`.

If `--dry-run`: list what would be pushed without executing API calls.

## Step 3: Pull (Notion → Local)

Skip if `--direction push`.

Fetch Notion pages modified since `last_sync_timestamp` (read from `.memory/sync-state.json`, or use epoch 0 for first run):

```
GET /databases/{db_id}/query
filter: { last_edited_time: { after: last_sync_timestamp } }
```

For each Notion page:

**User archived/deleted a page**:
- If `archived: true` and local record exists:
  - Set `deleted_at = now()` in local store
  - Revert any applied adaptations linked to this memory (set downstream behavior back to default)
  - Set `status = 'dismissed'`

**User changed status in Notion**:
- If Notion status differs from local: apply Notion's status (Notion wins for status)
- If new status is `dismissed`: freeze confidence, disable decay

**User changed content in Notion**:
- If Notion content differs from local: apply Notion's content (Notion wins for content)

**Conflict resolution** (applied per field):
- Notion wins: `status`, `content`, `category`, `tags`
- Local wins: `confidence`, `times_used`, `last_used_at`
- Most recent wins: `updated_at` (take whichever timestamp is newer for all other fields not listed above)

Track counts: `pulled_updated`, `pulled_dismissed`.

If `--dry-run`: list what would be pulled without writing to local store.

## Step 4: Update Sync Timestamps

If not `--dry-run`:

For all successfully processed memories, update:
```sql
UPDATE memories
SET last_synced_at = datetime('now')
WHERE id IN (:processed_ids);
```

Write the new sync timestamp to `.memory/sync-state.json`:
```json
{
  "last_sync": "2026-03-11T09:15:00Z",
  "direction": "both"
}
```

## Step 5: Report Results

Output the sync summary in this exact format:

```
Sync complete:
- Pushed: {pushed_new} new, {pushed_updated} updated, {pushed_deleted} deleted
- Pulled: {pulled_updated} updated, {pulled_dismissed} dismissed by user
- Last sync: {timestamp}
```

If `--dry-run`, prefix the output with:
```
[DRY RUN] No changes written. Would have:
```

If any errors occurred (network failures, Notion API errors after retries), append:
```
- Errors: {count} — see details below
  - {key}: {error message}
```

## Error Handling

- If Notion MCP is not configured or unreachable: halt with message `"Notion MCP unavailable — cannot sync. Check .mcp.json configuration."`
- If local memory store does not exist and cannot be initialized: halt with message `"Memory store not found. Run /founder-os:memory:store first to initialize."`
- If a single record fails to push/pull: log the error and continue with remaining records (never abort the full sync for one bad record)
- After 3 retries with exponential backoff on a record: skip it, add to error count

## Usage Examples

```
/founder-os:memory:sync
/founder-os:memory:sync --direction push
/founder-os:memory:sync --direction pull
/founder-os:memory:sync --direction both --dry-run
/founder-os:memory:sync --dry-run
```
