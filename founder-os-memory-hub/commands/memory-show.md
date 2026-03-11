---
description: View what the system has learned — memories, patterns, and active adaptations
argument-hint: "[company|plugin|all] [--candidates] [--adaptations]"
allowed-tools: Read, Bash
---

# Memory Show

Display the system's learned memories, detected patterns, and active adaptations. Reads directly from the SQLite memory store at `.memory/memory.db`.

## Parse Arguments

Extract from `$ARGUMENTS`:
- **filter** (string, optional): a company name, plugin ID (e.g., `P02`, `P10`), or the literal `all`. Default: `all`.
- `--candidates` (boolean, default: false): include `status='candidate'` memories in results.
- `--adaptations` (boolean, default: false): show active adaptations table instead of (or in addition to) memories.

Examples:
```
/memory:show                          # all confirmed + applied memories
/memory:show all --candidates         # all memories including candidates
/memory:show Acme Corp                # memories scoped to Acme Corp
/memory:show P02                      # memories created by Daily Briefing plugin
/memory:show --adaptations            # show active adaptations
/memory:show Acme Corp --adaptations  # Acme Corp memories + their adaptations
```

## Step 1: Initialize Memory Store

Read `_infrastructure/memory/SKILL.md` for the full memory API and schema details.

Verify the store exists and is initialized:

```bash
if [ ! -f ".memory/memory.db" ]; then
  echo "Memory store not found. Initializing..."
  mkdir -p .memory
  sqlite3 .memory/memory.db < _infrastructure/memory/schema/memory-store.sql
fi
```

Validate schema:

```sql
SELECT name FROM sqlite_master
WHERE type='table'
AND name IN ('memories', 'observations', 'adaptations');
```

If fewer than 3 rows returned, re-apply the schema:

```bash
sqlite3 .memory/memory.db < _infrastructure/memory/schema/memory-store.sql
```

## Step 2: Query Memories

Choose the query path based on the parsed filter.

### Path A: No filter or "all"

Fetch the top 20 confirmed and applied memories ordered by confidence, then recency:

```sql
SELECT id, key, category, content, source_plugin, company_id, tags,
       confidence, status, times_confirmed, times_used, last_used_at, updated_at
FROM memories
WHERE status IN ('confirmed', 'applied')
ORDER BY confidence DESC, last_used_at DESC
LIMIT 20;
```

If `--candidates` is present, extend the status filter:

```sql
SELECT id, key, category, content, source_plugin, company_id, tags,
       confidence, status, times_confirmed, times_used, last_used_at, updated_at
FROM memories
WHERE status IN ('confirmed', 'applied', 'candidate')
ORDER BY
  CASE status WHEN 'applied' THEN 1 WHEN 'confirmed' THEN 2 ELSE 3 END,
  confidence DESC,
  last_used_at DESC
LIMIT 20;
```

### Path B: Company filter

The filter value is a company name (not a plugin ID pattern like `P\d+`). Look up the Notion Companies page ID first:

Search Notion for the company: use the Notion MCP or search "[FOS] Companies" database for a page whose title matches the filter string. Extract the page `id`.

Then query by that company ID:

```sql
SELECT id, key, category, content, source_plugin, tags,
       confidence, status, times_confirmed, times_used, last_used_at, updated_at
FROM memories
WHERE company_id = '<notion-page-id>'
  AND status IN ('confirmed', 'applied')
ORDER BY confidence DESC, updated_at DESC
LIMIT 20;
```

If `--candidates` is present, add `'candidate'` to the status IN list.

If no Notion page is found, fall back to a text search on the `content` column:

```sql
SELECT id, key, category, content, source_plugin, tags,
       confidence, status, times_confirmed, times_used, last_used_at, updated_at
FROM memories
WHERE lower(content) LIKE lower('%<company-name>%')
  AND status IN ('confirmed', 'applied')
ORDER BY confidence DESC, updated_at DESC
LIMIT 20;
```

Warn the user: "Company not found in Notion — showing text matches instead."

### Path C: Plugin filter

The filter value matches the pattern `P\d+` (e.g., `P01`, `P22`) or is a plugin name slug. Map common plugin names to their IDs if needed (e.g., "daily briefing" → `P02`).

```sql
SELECT id, key, category, content, company_id, tags,
       confidence, status, times_confirmed, times_used, last_used_at, updated_at
FROM memories
WHERE source_plugin = '<plugin-id>'
  AND status IN ('confirmed', 'applied')
ORDER BY confidence DESC, updated_at DESC
LIMIT 20;
```

If `--candidates` is present, add `'candidate'` to the status IN list.

## Step 3: Query Adaptations (when --adaptations is set)

Fetch active adaptations joined with their source memories. An adaptation is "active" when `reverted_at IS NULL`.

```sql
SELECT a.id AS adaptation_id,
       a.plugin,
       a.description,
       a.applied_at,
       m.id AS memory_id,
       m.key AS memory_key,
       m.content AS memory_content,
       m.category,
       m.confidence,
       m.status AS memory_status
FROM adaptations a
JOIN memories m ON a.memory_id = m.id
WHERE a.reverted_at IS NULL
ORDER BY a.applied_at DESC;
```

If a company filter was provided, further restrict to adaptations whose source memory is company-scoped:

```sql
-- Add to WHERE clause:
AND m.company_id = '<notion-page-id>'
```

If a plugin filter was provided:

```sql
-- Add to WHERE clause:
AND a.plugin = '<plugin-id>'
```

## Step 4: Get Count Summary

Always run these counts to populate the footer summary:

```sql
SELECT
  SUM(CASE WHEN status = 'confirmed' THEN 1 ELSE 0 END) AS confirmed_count,
  SUM(CASE WHEN status = 'applied'   THEN 1 ELSE 0 END) AS applied_count,
  SUM(CASE WHEN status = 'candidate' THEN 1 ELSE 0 END) AS candidate_count,
  SUM(CASE WHEN status = 'dismissed' THEN 1 ELSE 0 END) AS dismissed_count
FROM memories;
```

And count active adaptations:

```sql
SELECT COUNT(*) AS active_adaptations
FROM adaptations
WHERE reverted_at IS NULL;
```

## Step 5: Format Output

Group memories by `category`. Present the result in this structure:

```
## Memories (12 confirmed, 3 applied)
> Showing: all  |  Filter: —  |  Candidates: hidden

### Preferences
- **briefing-format** (P02, confidence: 95, applied): Prefers bullet-point daily briefings with max 5 items
- **email-tone-formal** (user, confidence: 100, applied): Use formal tone in email drafts for client communications

### Patterns
- **acme-action-emails** (P01, confidence: 82, applied): Emails from @acmecorp.com are 90% action-required
- **friday-followups** (P06, confidence: 71, confirmed): User sends follow-ups predominantly on Friday afternoons

### Facts
- **acme-payment-terms** (P11, confidence: 90, applied): Acme Corp pays invoices on net-30 terms

### Contacts
- **sarah-acme-primary** (P21, confidence: 85, applied): Sarah at sarah@acme.com is the primary Acme Corp contact

### Workflows
- **weekly-review-sequence** (P05, confidence: 63, confirmed): Weekly review always starts with inbox triage then calendar review
```

If `--adaptations` is present (or if the adaptations query returned results), append:

```
### Active Adaptations
- Auto-flagging @acmecorp.com emails as VIP · P01 · applied Mar 10
- Using bullet-point format for daily briefings · P02 · applied Mar 8
- Net-30 payment terms pre-filled on Acme invoices · P11 · applied Mar 7
```

If `--candidates` is present, add a Candidates section after the main memory groups:

```
### Candidates (pending confirmation)
- **slack-response-speed** (P19, confidence: 35): User typically responds to Slack within 2 hours during business hours
- **quarterly-reporting** (P09, confidence: 42): Reports are generated at the end of each quarter
```

Finish with the count summary line:

```
---
12 confirmed · 3 applied · 5 candidates pending · 2 dismissed · 3 active adaptations
```

### Empty states

- If no memories exist at all: "No memories stored yet. The system learns as you use Founder OS plugins. Try running `/inbox:triage`, `/client:health`, or any other plugin to start building memory."
- If filter returns no results: "No memories found for [filter]. Try `/memory:show all` to see everything."
- If `--adaptations` returns no rows: "No active adaptations. Memories become adaptations once they reach 'applied' status (confidence ≥ 80, confirmed ≥ 3 times)."

## Error Handling

- If `.memory/memory.db` does not exist after initialization attempt: report "Memory store could not be initialized. Check that sqlite3 is installed (`which sqlite3`) and that the schema file exists at `_infrastructure/memory/schema/memory-store.sql`."
- If Notion is unavailable during company lookup: fall back to text search (see Path B above) and note the fallback.
- If SQLite returns a locked error: retry up to 3 times with a brief pause; WAL mode allows concurrent reads.
- Never error out entirely — always show whatever data is available and note any partial failures inline.
