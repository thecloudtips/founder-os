---
name: memory-engine
description: "Core API for reading and writing cross-plugin shared memory in Founder OS. Use this skill whenever any plugin needs to store, retrieve, or query persistent memories. Covers initialization, store/retrieve/delete operations, confidence mechanics, and decay rules."
---

# Memory Engine

## Overview

The Founder OS Memory Engine is a shared, persistent memory store that all 30 plugins read and write. It enables the system to learn from repeated user behavior, carry context across sessions, and personalize plugin output over time.

**Store location**: `.memory/memory.db` in the project root (distinct from `.swarm/`).

**Tech stack**: SQLite (WAL mode) for structured storage + HNSW vector index for semantic search.

**Schema source**: `_infrastructure/memory/schema/memory-store.sql`

### Memory Categories

Every memory must belong to one of five categories:

| Category | What It Stores | Examples |
|----------|---------------|---------|
| `preference` | User behavioral preferences | "Always archive newsletters", "Reply to clients within 24h" |
| `pattern` | Detected recurring behaviors | "Sends follow-ups on Friday afternoons", "Batch-processes invoices weekly" |
| `fact` | Stable business facts | "Acme Corp pays net-30", "Main contact is Sarah at sarah@acme.com" |
| `contact` | Person-specific knowledge | "John prefers Slack over email", "Maria is the decision-maker" |
| `workflow` | Repeatable process knowledge | "Weekly review always starts with email triage" |

### Memory Statuses

| Status | Meaning | Confidence Range |
|--------|---------|-----------------|
| `candidate` | Newly detected, not yet confirmed | 0–59 |
| `confirmed` | Seen enough times to trust | 60–79 |
| `applied` | Actively used to adapt behavior | 80–100 (+ ≥3 confirmations) |
| `dismissed` | User explicitly rejected | Any (frozen, no decay) |

---

## Initialization

Before any memory operation, verify the store exists.

```bash
# Check if store exists
if [ ! -f ".memory/memory.db" ]; then
  echo "Initializing memory store..."
  mkdir -p .memory
  sqlite3 .memory/memory.db < _infrastructure/memory/schema/memory-store.sql
  echo "Memory store initialized."
fi
```

If the file exists, verify the schema version to catch stale databases:

```sql
-- Check that core tables exist (quick schema validation)
SELECT name FROM sqlite_master
WHERE type='table'
AND name IN ('memories', 'observations', 'adaptations');
-- Expected: 3 rows. If fewer, re-run schema migration.
```

If the table count is less than 3, re-apply the schema:

```bash
sqlite3 .memory/memory.db < _infrastructure/memory/schema/memory-store.sql
```

The schema uses `CREATE TABLE IF NOT EXISTS`, so re-running is safe and idempotent.

---

## Store a Memory

### Function signature

```
memory_store(key, category, content, source_plugin, company_id?, tags?, confidence?)
```

| Parameter | Type | Required | Notes |
|-----------|------|----------|-------|
| `key` | string | yes | Human-readable, unique identifier (e.g., `"acme-payment-terms"`, `"user-pref-newsletter-archive"`) |
| `category` | string | yes | One of: `preference`, `pattern`, `fact`, `contact`, `workflow` |
| `content` | string | yes | The memory content in plain language |
| `source_plugin` | string | yes | Plugin ID that created this (e.g., `P01`, `P21`, `User`) |
| `company_id` | string | no | Notion Companies page ID if memory is client-scoped |
| `tags` | JSON array | no | e.g., `["email","archiving"]` for filtering |
| `confidence` | integer | no | Override default starting confidence (0–100) |

### Default starting confidence

If `confidence` is not supplied:
- **Explicit** (source_plugin = `"User"` or triggered by direct user instruction): start at **50**
- **Auto-detected** (system observed the pattern without explicit instruction): start at **20**

### Generate embedding

Before inserting, generate a vector embedding from `content` for HNSW semantic search. Store it as a JSON array of floats in the `embedding` column:

```
embedding = generate_embedding(content)
# Result: "[0.021, -0.134, 0.876, ...]"  (JSON array of floats, same format as .swarm/ vectors)
```

Use Claude's built-in embedding capability (same approach used by the `.swarm/` intelligence layer). Store as a JSON string in the `embedding` TEXT column.

### Insert new memory

```sql
INSERT INTO memories (
  id, key, category, content, source_plugin,
  company_id, tags, embedding, confidence, status,
  times_used, times_confirmed,
  created_at, updated_at
) VALUES (
  lower(hex(randomblob(16))),   -- UUID
  'acme-payment-terms',          -- key
  'fact',                        -- category
  'Acme Corp pays invoices on net-30 terms.',  -- content
  'P11',                         -- source_plugin
  'notion-page-id-here',         -- company_id (nullable)
  '["invoices","payment"]',      -- tags as JSON array (nullable)
  '[0.021, -0.134, ...]',        -- embedding JSON
  50,                            -- confidence
  'candidate',                   -- status (always start as candidate)
  0,                             -- times_used
  0,                             -- times_confirmed
  unixepoch(),                   -- created_at
  unixepoch()                    -- updated_at
);
```

### Update existing memory (key already exists)

When the same `key` is stored again, reinforce rather than duplicate:

```sql
UPDATE memories
SET
  content       = 'Updated content here',
  embedding     = '[updated embedding array]',
  times_confirmed = times_confirmed + 1,
  confidence    = MIN(100, confidence + 15),
  updated_at    = unixepoch()
WHERE key = 'acme-payment-terms';
```

After the update, check for status promotion (see Confidence & Decay section below).

### Check before insert: upsert pattern

Always check if the key exists before deciding to INSERT or UPDATE:

```sql
SELECT id, confidence, times_confirmed, status
FROM memories
WHERE key = ?;
```

- If 0 rows: run INSERT
- If 1 row: run UPDATE (reinforce)

---

## Retrieve Memories

All retrieval operations increment `access_count` (via `times_used`) and update `last_used_at`.

### memory_query — semantic search

```
memory_query(text, limit=5)
```

Returns the top N memories most semantically similar to `text`, restricted to active memories (`status IN ('confirmed', 'applied')`).

Steps:
1. Generate an embedding for `text` using the same method as storage
2. Load all `embedding` values from memories where `status IN ('confirmed', 'applied')`
3. Compute cosine similarity between the query embedding and each stored embedding
4. Return the top `limit` results, sorted by similarity descending

```sql
-- Step 2: fetch candidates for similarity comparison
SELECT id, key, category, content, source_plugin, company_id, tags,
       confidence, status, embedding
FROM memories
WHERE status IN ('confirmed', 'applied');

-- Step 4: after computing cosine similarity in application layer,
-- update access stats for each returned memory
UPDATE memories
SET times_used = times_used + 1,
    last_used_at = unixepoch()
WHERE id IN (/* returned IDs */);
```

### memory_get — exact key lookup

```
memory_get(key)
```

```sql
SELECT id, key, category, content, source_plugin, company_id, tags,
       confidence, status, times_used, times_confirmed, created_at, updated_at, last_used_at
FROM memories
WHERE key = ?;

-- Update access stats
UPDATE memories
SET times_used = times_used + 1,
    last_used_at = unixepoch()
WHERE key = ?;
```

Returns null/empty if the key does not exist. Does not filter by status — returns any status including `dismissed` (so callers can check status and skip if needed).

### memory_by_company — all memories for a company

```
memory_by_company(company_id, limit=10)
```

```sql
SELECT id, key, category, content, source_plugin, tags,
       confidence, status, times_confirmed, updated_at
FROM memories
WHERE company_id = ?
  AND status IN ('confirmed', 'applied')
ORDER BY confidence DESC, updated_at DESC
LIMIT ?;

-- Update access stats for returned rows
UPDATE memories
SET times_used = times_used + 1,
    last_used_at = unixepoch()
WHERE company_id = ?
  AND status IN ('confirmed', 'applied');
```

### memory_by_plugin — all memories created by a plugin

```
memory_by_plugin(plugin, limit=10)
```

```sql
SELECT id, key, category, content, company_id, tags,
       confidence, status, times_confirmed, updated_at
FROM memories
WHERE source_plugin = ?
  AND status IN ('confirmed', 'applied')
ORDER BY confidence DESC, updated_at DESC
LIMIT ?;

-- Update access stats for returned rows
UPDATE memories
SET times_used = times_used + 1,
    last_used_at = unixepoch()
WHERE source_plugin = ?
  AND status IN ('confirmed', 'applied');
```

---

## Delete a Memory

```
memory_delete(key)
```

Removes the memory entry and cleans up any active adaptations that referenced it.

### Step 1: look up the memory ID

```sql
SELECT id FROM memories WHERE key = ?;
```

### Step 2: mark any active adaptations as reverted

```sql
UPDATE adaptations
SET reverted_at = unixepoch()
WHERE memory_id = (SELECT id FROM memories WHERE key = ?)
  AND reverted_at IS NULL;
```

### Step 3: delete the memory row

```sql
DELETE FROM memories WHERE key = ?;
```

The `embedding` column is stored inline in the `memories` table, so deleting the row also removes the vector. No separate HNSW index cleanup is required at the SQL level — the embedding is gone when the row is gone.

### Dismissed vs. deleted

- **Dismiss** (user says "stop doing this"): set `status = 'dismissed'` — memory is retained for audit but never injected
- **Delete** (hard removal): use `memory_delete(key)` — row is removed entirely

```sql
-- Dismiss (soft)
UPDATE memories
SET status = 'dismissed', updated_at = unixepoch()
WHERE key = ?;
```

---

## Confidence & Decay

### Confidence range

All confidence values are integers 0–100. They are stored in the `confidence` column and constrained by `CHECK (confidence >= 0 AND confidence <= 100)`.

### Confirmation: reinforcing a memory

Each time the same key is observed again (via `memory_store` with an existing key), apply:

```
new_confidence = MIN(100, current_confidence + 15)
times_confirmed = times_confirmed + 1
```

```sql
UPDATE memories
SET confidence    = MIN(100, confidence + 15),
    times_confirmed = times_confirmed + 1,
    updated_at    = unixepoch()
WHERE key = ?;
```

### Promotion thresholds

After any confidence update, check and apply promotion:

```sql
-- Promote candidate → confirmed (confidence ≥ 60)
UPDATE memories
SET status = 'confirmed', updated_at = unixepoch()
WHERE status = 'candidate'
  AND confidence >= 60;

-- Promote confirmed → applied (confidence ≥ 80 AND times_confirmed ≥ 3)
UPDATE memories
SET status = 'applied', updated_at = unixepoch()
WHERE status = 'confirmed'
  AND confidence >= 80
  AND times_confirmed >= 3;
```

Run these two UPDATE statements after every `memory_store` call.

### Decay: memories fade when unused

Run decay once per day (e.g., at the start of the first plugin command each day, or via a scheduled P27 workflow).

Memories not used in 30 days lose 5 confidence per week of disuse:

```sql
-- Apply weekly decay to memories not used in the past 30 days
UPDATE memories
SET confidence  = MAX(0, confidence - 5),
    updated_at  = unixepoch()
WHERE status NOT IN ('dismissed')
  AND (last_used_at IS NULL OR last_used_at < unixepoch() - 2592000)  -- 30 days
  AND confidence > 0;
```

### Auto-expire: remove memories below confidence threshold

After decay, delete any memories that have fallen below confidence 10:

```sql
-- Before deleting, revert active adaptations
UPDATE adaptations
SET reverted_at = unixepoch()
WHERE memory_id IN (
  SELECT id FROM memories WHERE confidence < 10 AND status != 'dismissed'
)
AND reverted_at IS NULL;

-- Delete expired memories
DELETE FROM memories
WHERE confidence < 10
  AND status != 'dismissed';
```

Dismissed memories are exempt from auto-expire (they are preserved indefinitely for audit).

### Decay summary

| Rule | Value |
|------|-------|
| Confidence range | 0–100 |
| Reinforcement gain | +15 per confirmation (capped at 100) |
| Decay trigger | Not used in 30 days |
| Decay rate | −5 confidence per week |
| Auto-expire threshold | confidence < 10 (non-dismissed) |
| Confirmed threshold | confidence ≥ 60 |
| Applied threshold | confidence ≥ 80 AND times_confirmed ≥ 3 |

---

## Plugin Integration Pattern

Add this block near the top of any plugin command that should read or write memory, after business context loading (Step 0) and before main logic:

~~~markdown
## Step 0b: Memory Context

Initialize the memory store if needed:
```bash
[ -f ".memory/memory.db" ] || (mkdir -p .memory && sqlite3 .memory/memory.db < _infrastructure/memory/schema/memory-store.sql)
```

Read `_infrastructure/memory/SKILL.md` for the full memory API.

Query for relevant memories before executing:
- Call `memory_query(task_description, limit=5)` to surface confirmed/applied memories
- Call `memory_by_company(company_id)` if this command is client-scoped
- Inject returned memories into your working context

After execution, store any new patterns observed:
- Call `memory_store(key, category, content, source_plugin)` for each notable behavior
- Categories to look for: user preferences revealed during the run, new facts about companies or contacts
~~~

---

## Error Handling

| Error | Action |
|-------|--------|
| `.memory/` directory missing | Create it silently: `mkdir -p .memory` |
| `memory.db` missing | Initialize from schema (see Initialization section) |
| Schema tables missing | Re-apply `memory-store.sql` (idempotent) |
| SQLite locked (WAL mode) | Retry up to 3 times with 500ms delay; WAL mode allows concurrent reads |
| Invalid category value | Fail with clear error: `"Invalid category: must be one of preference, pattern, fact, contact, workflow"` |
| Confidence out of range | Clamp silently: `MIN(100, MAX(0, value))` |
| Embedding generation failure | Store memory without embedding; mark `embedding = NULL`; memory will be excluded from semantic search but available for exact/filtered queries |

When the memory store is unavailable for any reason, plugins MUST degrade gracefully: skip memory operations, note `memory_status: "unavailable"` in output, and continue with the main task.
