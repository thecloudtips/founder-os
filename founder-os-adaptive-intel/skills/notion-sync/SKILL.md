---
name: intelligence-notion-sync
description: Bidirectional sync between the local Intelligence SQLite database and the [FOS] Intelligence Notion database. Reads from both the patterns and healing_patterns tables.
---

## Overview

Syncs learned patterns and healing data between the local Intelligence DB and the `[FOS] Intelligence` Notion database. Sync is triggered explicitly by `/memory:sync` (shared with Memory Engine). It is NOT triggered automatically by read-only commands like `/intel:status`.

## Notion Database Discovery

Follow the standard 3-step discovery pattern:
1. Search for "[FOS] Intelligence"
2. Fall back to "Founder OS HQ - Intelligence"
3. If not found, skip Notion sync silently — local-only mode

## Local → Notion (Push)

### Patterns Table

For each row in `patterns` where `updated_at` is newer than the last sync timestamp (from `config` where `key = 'notion.last_sync'`):

| SQLite Column | Notion Property | Transform |
|---|---|---|
| `description` | Pattern (title) | Direct |
| `plugin` | Plugin (select) | Null → "Cross-Plugin" |
| `pattern_type` | Type (select) | Capitalize: taste → "Taste", workflow → "Workflow" |
| `confidence` | Confidence (number) | Direct (0.0–1.0) |
| `status` | Status (status) | Capitalize: active → "Active", approved → "Approved", rejected → "Rejected" |
| `observations` | Observations (number) | Direct |
| `confirmations` | Confirmations (number) | Direct |
| `rejections` | Rejections (number) | Direct |
| `updated_at` | Last Applied (date) | ISO 8601 |
| `instruction` | Instruction (rich_text) | Direct |

Use `pattern_id` as the external ID to match existing Notion pages on subsequent syncs (upsert, not duplicate).

### Healing Patterns Table

For each row in `healing_patterns` where `last_seen` is newer than the last sync timestamp:

| SQLite Column | Notion Property | Transform |
|---|---|---|
| `error_signature` | Pattern (title) | Direct |
| `plugin` | Plugin (select) | Null → "Cross-Plugin" |
| (fixed) | Type (select) | Fixed: "Healing" |
| (calculated) | Confidence (number) | `success_count / max(1, success_count + failure_count)` |
| (fixed) | Status (status) | Fixed: "Active" |
| `success_count + failure_count` | Observations (number) | Sum |
| `last_seen` | Last Applied (date) | ISO 8601 |
| `fix_action + fallback_action` | Instruction (rich_text) | Concatenate: "Fix: {fix_action}. Fallback: {fallback_action}" |

Use `healing_pattern_id` as the external ID for upsert matching.

## Notion → Local (Pull)

When a user edits a pattern page in Notion, pull the following fields back to the local `patterns` table:

- **Status changes** (e.g., Active → Rejected): write back to `patterns.status`, normalized to lowercase
- **Instruction edits**: write back to `patterns.instruction`
- **Confidence manual overrides**: write back to `patterns.confidence`

Pull is scoped to pages with a matching external ID in the local DB. Pages created directly in Notion (no external ID) are NOT synced back — patterns must originate from observations captured by the hooks layer.

## Sync Tracking

After a successful sync run, store the current timestamp in the config table:

```sql
INSERT OR REPLACE INTO config (key, value) VALUES ('notion.last_sync', datetime('now'))
```

On subsequent syncs, use this timestamp to filter only changed rows:

```sql
-- Patterns changed since last sync
SELECT * FROM patterns WHERE updated_at > (SELECT value FROM config WHERE key = 'notion.last_sync')

-- Healing patterns changed since last sync
SELECT * FROM healing_patterns WHERE last_seen > (SELECT value FROM config WHERE key = 'notion.last_sync')
```

If `notion.last_sync` does not exist (first sync), push all rows.

## Sync Report

After each sync, return a summary object:

```
{
  "pushed": {
    "patterns": <count>,
    "healing_patterns": <count>
  },
  "pulled": {
    "status_changes": <count>,
    "instruction_edits": <count>,
    "confidence_overrides": <count>
  },
  "errors": <count>,
  "last_sync": "<ISO 8601 timestamp>"
}
```

## Error Handling

- If the Notion API is unavailable, skip sync silently — local data is the source of truth. Return `{ "status": "unavailable" }`.
- If a specific row fails to sync (e.g., a property type mismatch), log the error to stderr and continue with remaining rows. Do not abort the entire sync.
- Never block plugin execution on Notion sync failure. Sync runs are best-effort.
- Rate limit: Notion allows ~3 requests/second. Batch upserts where possible; add a short delay between batches if pushing more than 20 rows.
