---
name: memory-notion-sync
description: Bidirectional sync between local memory store and [FOS] Memory Notion database. Reference this skill whenever pushing memories to Notion or pulling user changes back to the local SQLite store.
---

# Memory Notion Sync

This skill manages the full lifecycle of syncing the local `.memory/memory.db` SQLite store with the `[FOS] Memory` Notion database. It covers DB discovery, schema, field mapping, conflict resolution, sync triggers, and rate-limit handling.

---

## DB Discovery

Always search in this order to locate the target database. Never hard-code a database ID.

1. Search Notion for `[FOS] Memory` (exact name match preferred)
2. If not found, search for `Founder OS HQ - Memory`
3. If neither found: lazy-create the database using the schema below (only for non-HQ users who did not install the full HQ template)

To search via Notion MCP:
```
mcp_notion_search({ query: "[FOS] Memory", filter: { value: "database", property: "object" } })
```

Store the resolved database ID in memory for the duration of the sync session. Do not re-query on every API call.

---

## DB Schema

The `[FOS] Memory` Notion database has these properties:

| Property | Notion Type | Notes |
|----------|------------|-------|
| Key | title | Unique identifier for the memory (e.g., `pref:email:archive_newsletters`) |
| Category | select | Options: `preference`, `pattern`, `fact`, `contact`, `workflow` |
| Content | rich_text | The human-readable memory content |
| Source Plugin | select | Options: `P01`–`P30`, `User`, `System` |
| Confidence | number | Integer 0–100 |
| Status | select | Options: `candidate`, `confirmed`, `applied`, `dismissed` |
| Company | relation | Relates to `[FOS] Companies` database (optional) |
| Tags | multi_select | Free-form tags for grouping and filtering |
| Times Used | number | How many times this memory has influenced plugin output |
| Last Used | date | Date of most recent application |
| Synced At | date | Timestamp of most recent successful sync |

### Lazy-Create Schema (non-HQ users only)

If neither HQ database is found, create the database with this structure:

```json
{
  "title": [{ "type": "text", "text": { "content": "[FOS] Memory" } }],
  "properties": {
    "Key": { "title": {} },
    "Category": {
      "select": {
        "options": [
          { "name": "preference", "color": "blue" },
          { "name": "pattern", "color": "green" },
          { "name": "fact", "color": "yellow" },
          { "name": "contact", "color": "purple" },
          { "name": "workflow", "color": "orange" }
        ]
      }
    },
    "Content": { "rich_text": {} },
    "Source Plugin": {
      "select": {
        "options": [
          { "name": "P01", "color": "gray" }, { "name": "P02", "color": "gray" },
          { "name": "P03", "color": "gray" }, { "name": "P04", "color": "gray" },
          { "name": "P05", "color": "gray" }, { "name": "P06", "color": "gray" },
          { "name": "P07", "color": "gray" }, { "name": "P08", "color": "gray" },
          { "name": "P09", "color": "gray" }, { "name": "P10", "color": "gray" },
          { "name": "P11", "color": "gray" }, { "name": "P12", "color": "gray" },
          { "name": "P13", "color": "gray" }, { "name": "P14", "color": "gray" },
          { "name": "P15", "color": "gray" }, { "name": "P16", "color": "gray" },
          { "name": "P17", "color": "gray" }, { "name": "P18", "color": "gray" },
          { "name": "P19", "color": "gray" }, { "name": "P20", "color": "gray" },
          { "name": "P21", "color": "gray" }, { "name": "P22", "color": "gray" },
          { "name": "P23", "color": "gray" }, { "name": "P24", "color": "gray" },
          { "name": "P25", "color": "gray" }, { "name": "P26", "color": "gray" },
          { "name": "P27", "color": "gray" }, { "name": "P28", "color": "gray" },
          { "name": "P29", "color": "gray" }, { "name": "P30", "color": "gray" },
          { "name": "User", "color": "pink" },
          { "name": "System", "color": "red" }
        ]
      }
    },
    "Confidence": { "number": { "format": "number" } },
    "Status": {
      "select": {
        "options": [
          { "name": "candidate", "color": "gray" },
          { "name": "confirmed", "color": "blue" },
          { "name": "applied", "color": "green" },
          { "name": "dismissed", "color": "red" }
        ]
      }
    },
    "Company": { "relation": {} },
    "Tags": { "multi_select": {} },
    "Times Used": { "number": { "format": "number" } },
    "Last Used": { "date": {} },
    "Synced At": { "date": {} }
  }
}
```

---

## Push Logic (Local → Notion)

### Field Mapping

| Local SQLite Column | Notion Property | Transform |
|--------------------|----------------|-----------|
| `key` | Key (title) | Plain string |
| `category` | Category | Select value |
| `content` | Content | Rich text block |
| `source_plugin` | Source Plugin | Select value (e.g., `"P01"`) |
| `confidence` | Confidence | Integer |
| `status` | Status | Select value |
| `company_id` | Company | Relation page ID (if not null) |
| `tags` | Tags | JSON array → multi-select options |
| `times_used` | Times Used | Integer |
| `last_used_at` | Last Used | ISO 8601 date string |
| `datetime('now')` | Synced At | ISO 8601 date string, set at push time |

### Notion Page Body (create or update)

```json
{
  "parent": { "database_id": "{db_id}" },
  "properties": {
    "Key": {
      "title": [{ "type": "text", "text": { "content": "{key}" } }]
    },
    "Category": { "select": { "name": "{category}" } },
    "Content": {
      "rich_text": [{ "type": "text", "text": { "content": "{content}" } }]
    },
    "Source Plugin": { "select": { "name": "{source_plugin}" } },
    "Confidence": { "number": {confidence} },
    "Status": { "select": { "name": "{status}" } },
    "Company": { "relation": [{ "id": "{company_notion_page_id}" }] },
    "Tags": { "multi_select": [ {/* one object per tag */} ] },
    "Times Used": { "number": {times_used} },
    "Last Used": { "date": { "start": "{last_used_at}" } },
    "Synced At": { "date": { "start": "{now_iso8601}" } }
  }
}
```

Omit `Company` entirely if `company_id` is null. Omit `Last Used` if `last_used_at` is null. Omit `Tags` if the array is empty.

### Batch Creates

Group new records into batches of up to 10 and create them sequentially (the Notion API does not support bulk create in a single call — create 10 in parallel using concurrent requests, then proceed to the next batch). Store each returned page ID back in `memories.notion_page_id`.

### Archive for Deletions

For locally deleted memories (where `deleted_at IS NOT NULL`):
```json
PATCH /pages/{notion_page_id}
{ "archived": true }
```

---

## Pull Logic (Notion → Local)

### Query Modified Pages

```json
POST /databases/{db_id}/query
{
  "filter": {
    "timestamp": "last_edited_time",
    "last_edited_time": { "after": "{last_sync_iso8601}" }
  }
}
```

Paginate until `has_more: false`.

### Field Mapping (Notion → Local)

| Notion Property | Local Column | Notes |
|----------------|-------------|-------|
| Key (title) | `key` | Extract plain text from title array |
| Category | `category` | Select name |
| Content | `content` | Concatenate rich text plain text |
| Source Plugin | `source_plugin` | Select name |
| Confidence | `confidence` | Number (but see conflict rules below) |
| Status | `status` | Select name |
| Company (relation) | `company_id` | Map Notion page ID back to local company ID via CRM lookup |
| Tags | `tags` | Multi-select names → JSON array |
| Times Used | `times_used` | Number (but see conflict rules below) |
| Last Used | `last_used_at` | Date start field |
| Synced At | `last_synced_at` | Date start field |

### Conflict Resolution Rules

These rules apply when a Notion value differs from the local value:

| Field | Winner | Rationale |
|-------|--------|-----------|
| `status` | **Notion wins** | User is source of truth for dismissals and promotions |
| `content` | **Notion wins** | User edits in Notion are intentional corrections |
| `category` | **Notion wins** | User may recategorize memories |
| `tags` | **Notion wins** | User adds/removes tags in Notion UI |
| `confidence` | **Local wins** | Computed by the engine, not user-editable |
| `times_used` | **Local wins** | Tracked by runtime, Notion value can only go stale |
| `last_used_at` | **Local wins** | Set by runtime on each application |
| `key` | **Local wins** | Never change a memory key after creation |

### Dismissal Handling

When a Notion page is archived by the user (`archived: true`) and the local record exists:
1. Set `deleted_at = datetime('now')` locally
2. Set `status = 'dismissed'`
3. Freeze the confidence value (disable decay for this record)
4. If the memory was `applied`, revert any downstream behavioral adaptations it drove (set the relevant plugin behavior flags back to default)

When a Notion page's Status is changed to `dismissed`:
1. Update local `status = 'dismissed'`
2. Freeze confidence (set a `frozen` flag or simply stop processing it in decay runs)
3. Do not delete the local record — keep for audit history

---

## Sync Triggers

Three conditions trigger a sync:

### Auto-Push (after status promotion)

Triggered internally by the memory engine after any memory transitions to `confirmed` or `applied` status.

Rules:
- Debounced: do not push more than once per 5 minutes regardless of how many memories promote in that window
- Batch: collect all promotions within the debounce window and push together
- Only push records that haven't been synced yet or have changed since last sync

Implementation: check `.memory/sync-state.json` for `last_auto_push` timestamp before triggering.

### Auto-Pull (on plugin start)

Triggered by any plugin when it initializes the memory engine.

Rules:
- Only pull if `last_sync` timestamp in `.memory/sync-state.json` is more than 1 hour ago
- Pull only — do not push on auto-pull (avoid accidental overwrites during read-heavy operations)
- Runs silently in the background; does not block the plugin's main workflow

### Manual (/memory:sync command)

Full sync in the specified direction. Always runs immediately regardless of debounce timers. Resets the debounce window after completing.

---

## Rate Limit Handling

Notion API enforces a rate limit of approximately 3 requests per second per integration.

### Retry Strategy

On receiving a `429 Too Many Requests` response:
1. Read the `Retry-After` header (in seconds). If absent, default to 1 second.
2. Wait for the specified duration before retrying.
3. Retry the same request.
4. If it fails again: double the wait time (exponential backoff).
5. After 3 total attempts: skip the record, log the error, increment error count, continue with the next record.

### Backoff Schedule

| Attempt | Wait Before Retry |
|---------|------------------|
| 1st retry | `Retry-After` header or 1s |
| 2nd retry | 2× previous wait |
| 3rd retry | 4× previous wait |
| Give up | Log error, skip record |

### Proactive Pacing

When pushing batches, insert a 350ms pause between each batch of 10 to stay safely below the rate limit without relying on retry logic.

---

## Sync State File

Maintain `.memory/sync-state.json` to track sync history:

```json
{
  "last_sync": "2026-03-11T09:15:00Z",
  "last_auto_push": "2026-03-11T08:45:00Z",
  "last_auto_pull": "2026-03-11T09:00:00Z",
  "direction": "both",
  "db_id": "{notion_database_id}"
}
```

Read this file at the start of every sync. Write it at the end of every successful sync. If the file is missing or malformed, treat `last_sync` as epoch 0 (full re-sync).

---

## Error Surface

These are the failure modes to handle gracefully:

| Error | Action |
|-------|--------|
| Notion MCP unavailable | Abort sync, surface error to user |
| DB not found (all names searched) | Lazy-create DB, proceed |
| Invalid field value (e.g., unknown category) | Skip that field, log warning, continue |
| 429 after 3 retries | Skip record, log error, continue |
| 500/503 from Notion | Treat as transient, apply same retry logic as 429 |
| Local DB locked (SQLite BUSY) | Wait 200ms, retry up to 3 times |
| Malformed Notion page (missing required fields) | Skip page, log warning |
