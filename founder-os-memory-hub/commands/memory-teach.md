---
description: Explicitly teach the system a fact, preference, or rule
argument-hint: '"Always flag emails from @bigclient.com as urgent" [--company "Acme Corp"] [--category preference]'
allowed-tools: Read, Bash
---

# /memory:teach

Explicitly teach the memory engine a fact, preference, rule, or contact detail. The user provides a plain-language statement; this command stores it with maximum confidence (`100`) and `confirmed` status so it is immediately applied to all future plugin runs.

## Load Skills

Read the memory engine skill before starting any step:

`_infrastructure/memory/SKILL.md`

Apply its initialization, store, fuzzy search, and upsert patterns throughout this command.

## Parse Arguments

Extract from `$ARGUMENTS`:

- **statement** (required) — the first quoted string, or all non-flag text. This is the memory content. If no statement can be parsed, prompt: "What would you like me to remember? State it in plain language (e.g., 'Always flag emails from @bigclient.com as urgent')." Wait for input.
- `--company "NAME"` (optional) — the company this memory is scoped to. If provided, the memory will be linked to the matching Notion Companies record.
- `--category CATEGORY` (optional) — one of `preference`, `fact`, `contact`, `workflow`. If omitted, auto-detect from the statement content (see Step 2).

## Business Context (Optional)

Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md` and `current-data.md`. Use this context to enrich company lookups and improve key generation. If files don't exist, skip silently.

## Step 1: Initialize Memory Store

Verify the store exists and the schema is current:

```bash
[ -f ".memory/memory.db" ] || (mkdir -p .memory && sqlite3 .memory/memory.db < _infrastructure/memory/schema/memory-store.sql)
```

Validate the schema by checking for required tables:

```sql
SELECT name FROM sqlite_master
WHERE type = 'table'
  AND name IN ('memories', 'observations', 'adaptations');
```

If fewer than 3 rows are returned, re-apply the schema:

```bash
sqlite3 .memory/memory.db < _infrastructure/memory/schema/memory-store.sql
```

If initialization fails for any reason, stop and display:

```
Error: Could not initialize the memory store at .memory/memory.db.
Check that the schema file exists at _infrastructure/memory/schema/memory-store.sql.
```

## Step 2: Auto-Detect Category

If `--category` was provided by the user, use it directly. Validate it is one of `preference`, `fact`, `contact`, `workflow`. If not valid, respond:

```
Invalid category "[value]". Must be one of: preference, fact, contact, workflow.
```

Then stop.

If `--category` was not provided, infer it from the statement using these rules (evaluated in order):

| Signal words / patterns | Inferred category |
|------------------------|-------------------|
| "always", "never", "prefer", "prefer to", "use", "format", "don't", "do not", "make sure", "remember to" | `preference` |
| Company name (matches `--company` value), "client", "customer", "account", "they ", "their " | `fact` |
| Person's name + email address, person's name + role/title, "prefers to be contacted", "decision-maker", "reports to" | `contact` |
| "after X run Y", "workflow", "process", "every time", "step", "trigger", "automate" | `workflow` |
| (none of the above match) | `fact` |

Apply rules in the order shown — the first match wins. Note the detected category for use in Step 6.

## Step 3: Generate Memory Key

Create a unique, human-readable key that identifies this memory for lookups. Rules:

1. Extract the core subject from the statement (company name, person name, domain, topic).
2. Combine with the detected category and a short slug of the action or attribute.
3. Lowercase, replace spaces and special characters with hyphens, truncate to 60 characters.

Examples:

| Statement | Key |
|-----------|-----|
| "Always flag emails from @bigclient.com as urgent" | `pref-bigclient-email-urgent` |
| "Acme Corp pays on net-30 terms" | `acme-payment-net-30` |
| "Sarah at sarah@acme.com is the main contact" | `contact-sarah-acme` |
| "After weekly review, run the follow-up tracker" | `workflow-weekly-review-followup` |

If the key exceeds 60 characters, truncate at a word boundary.

## Step 4: Check for Similar Memory

Before storing, search for existing memories with the same key or semantically similar content. This prevents duplicate entries for the same knowledge.

### Exact key check

```sql
SELECT id, key, content, confidence, status, updated_at
FROM memories
WHERE key = ?;
```

### Fuzzy semantic check (HNSW)

Generate an embedding for the statement. Load all memory embeddings and compute cosine similarity. Return the top match if similarity > 0.85:

```sql
SELECT id, key, content, confidence, status, embedding
FROM memories
WHERE status IN ('candidate', 'confirmed', 'applied');
```

Compute cosine similarity in the application layer. If the top result has similarity > 0.85 and is not the exact key match, it is a near-duplicate candidate.

### Conflict resolution

If an exact key match OR a near-duplicate (similarity > 0.85) is found, display:

```
A similar memory already exists:

  Key:        [existing key]
  Content:    [existing content]
  Confidence: [n]
  Status:     [status]
  Updated:    [date]

Options:
  1. Update it with your new statement (reinforces confidence)
  2. Create a new separate memory
  3. Cancel

Which would you prefer? (1/2/3)
```

Wait for the user's response.

- **Option 1**: proceed with UPDATE flow (Step 6, update branch).
- **Option 2**: generate an alternate key by appending a suffix (e.g., `-v2`) and proceed with INSERT flow.
- **Option 3**: display "No memory stored. Run /memory:teach again when ready." Then stop.

If no similar memory exists, proceed directly to Step 5.

## Step 5: Resolve Company Relation

If `--company "NAME"` was provided:

1. Search the Notion workspace for a database named "[FOS] Companies". If not found, try "Founder OS HQ - Companies" or "Founder OS CRM - Companies".
2. Within that database, search for a page whose title contains the provided company name (case-insensitive). Use `notion-search`.
3. If exactly one match is found, capture its Notion page ID as `company_id`.
4. If multiple matches are found, present a numbered list:

```
Multiple companies match "[NAME]":
  1. [Exact name] — [last edited date]
  2. [Alternate name] — [last edited date]

Which company? (1/2/...)
```

Wait for the user's response and use the selected page ID.

5. If no match is found, inform the user:

```
Company "[NAME]" not found in your Notion CRM.
The memory will be stored without a company relation.
You can link it later via Notion directly.
```

Set `company_id = NULL` and continue.

If `--company` was not provided but the statement content mentions a company name that matches a known client (from business context), suggest the relation: "This memory mentions [company name] — should I link it to the [Company Name] record in your CRM? (yes/no)" If the user confirms, run the lookup above. If no, set `company_id = NULL`.

## Step 6: Store Memory

Determine the correct SQL operation based on whether an existing record was found in Step 4.

### INSERT — new memory

Generate an embedding for the statement content, then insert:

```sql
INSERT INTO memories (
  id, key, category, content, source_plugin,
  company_id, tags, embedding, confidence, status,
  times_used, times_confirmed,
  created_at, updated_at
) VALUES (
  lower(hex(randomblob(16))),        -- UUID
  'acme-payment-net-30',             -- resolved key (example)
  'fact',                            -- resolved category (example)
  'Acme Corp pays invoices on net-30 terms.',  -- statement
  'User',                            -- source_plugin always "User" for /memory:teach
  'notion-page-id-or-null',          -- company_id (nullable)
  NULL,                              -- tags (null by default; user can add later)
  '[0.021, -0.134, ...]',            -- embedding JSON array
  100,                               -- confidence = 100 (explicit user teaching)
  'confirmed',                       -- status = confirmed immediately (100 >= 60)
  0,                                 -- times_used
  1,                                 -- times_confirmed = 1 (user explicitly taught it)
  unixepoch(),                       -- created_at
  unixepoch()                        -- updated_at
);
```

Key values for `/memory:teach`:
- `source_plugin` is always `"User"` — distinguishes explicit teaching from plugin-detected patterns.
- `confidence` is always `100` — explicit user instruction carries maximum confidence.
- `status` is always `"confirmed"` — confidence 100 exceeds the 60-threshold immediately; skip `candidate`.
- `times_confirmed` starts at `1` — counts this teaching session as the first confirmation.

### UPDATE — reinforcing an existing memory

When the user chose to update an existing memory (Option 1 from Step 4):

```sql
UPDATE memories
SET
  content         = 'Updated statement content here',
  embedding       = '[updated embedding array]',
  source_plugin   = 'User',
  confidence      = 100,
  status          = 'confirmed',
  times_confirmed = times_confirmed + 1,
  updated_at      = unixepoch()
WHERE key = 'existing-key-here';
```

After either INSERT or UPDATE, run promotion checks to ensure status is correctly set. Since confidence is always 100 for this command, both promotion conditions are satisfied immediately:

```sql
-- Promote candidate → confirmed (confidence >= 60)
UPDATE memories
SET status = 'confirmed', updated_at = unixepoch()
WHERE status = 'candidate'
  AND confidence >= 60;

-- Promote confirmed → applied (confidence >= 80 AND times_confirmed >= 3)
UPDATE memories
SET status = 'applied', updated_at = unixepoch()
WHERE status = 'confirmed'
  AND confidence >= 80
  AND times_confirmed >= 3;
```

Note: a freshly taught memory with `times_confirmed = 1` will remain `confirmed` until it has been reinforced twice more (total `times_confirmed >= 3`), at which point it automatically promotes to `applied`.

## Step 7: Sync to Notion

After successfully writing to the local SQLite store, sync this memory record to the Notion workspace.

1. Search for a database named "[FOS] Memory". If not found, try "Founder OS HQ - Memory".
2. If the database is found, upsert a page for this memory:
   - **Title**: the memory key (e.g., `acme-payment-net-30`)
   - **Content**: the statement text
   - **Category**: the resolved category
   - **Confidence**: 100
   - **Status**: confirmed
   - **Source**: User
   - **Company**: relation to company page (if `company_id` was resolved)
   - **Updated**: current date
3. If the Memory database is not found, skip the Notion sync silently — the memory is safely stored in the local SQLite store. Note `notion_sync: "skipped — database not found"` in the confirmation output.
4. If Notion MCP is unavailable, skip silently and note `notion_sync: "unavailable"`.

## Step 8: Confirm

Display the confirmation block:

```
Learned: [key] — [statement content]

  Category:     [category]
  Confidence:   100 (confirmed)
  Status:       confirmed
  Source:       User (explicit teaching)
  Company:      [Company Name] or "not linked"
  Notion sync:  [synced | skipped — database not found | unavailable]

This memory is now active. All plugins will apply it going forward.
To view your memories: /memory:show
To forget this:        /memory:forget "[key]"
```

## Graceful Degradation

| Failure | Behavior |
|---------|----------|
| Memory store unavailable | Stop at Step 1 with clear error and schema path |
| Invalid category | Stop at Step 2 with correction prompt |
| Notion Companies DB not found | Continue without company relation; note in confirmation |
| Notion MCP unavailable | Skip Notion sync; local store write always succeeds |
| Embedding generation fails | Store without embedding (`embedding = NULL`); memory excluded from semantic search but accessible via exact key lookup |
| Statement too short (< 5 characters) | Reject: "Statement is too short to be a useful memory. Please describe the rule or fact in plain language." |

## Usage Examples

```
/memory:teach "Always flag emails from @bigclient.com as urgent"
/memory:teach "Acme Corp pays invoices on net-30 terms" --company "Acme Corp"
/memory:teach "Sarah at sarah@acme.com is the main decision-maker at Acme" --company "Acme Corp" --category contact
/memory:teach "After the weekly review, always run the follow-up tracker" --category workflow
/memory:teach "Never send proposals on Fridays — clients don't read them until Monday" --category preference
/memory:teach "TechCorp's budget cycle resets in January" --company "TechCorp" --category fact
```
