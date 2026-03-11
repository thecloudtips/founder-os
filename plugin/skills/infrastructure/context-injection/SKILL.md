---
name: memory-context-injection
description: Auto-inject relevant memories before plugin execution
---

# Memory Context Injection

## Overview

This skill is referenced by every plugin command as **Step 0: Memory Context** — before the plugin's primary logic runs. It queries the memory store for relevant memories based on the current input and injects them into the working context so the plugin can adapt its behavior accordingly.

**Purpose**: Enrich plugin execution with learned preferences, facts, and patterns from previous sessions.

**Trigger**: Called at plugin startup, immediately after business context loading (Step 0a) and before main plugin logic (Step 1+).

**Performance target**: < 2 seconds added to plugin startup. The three queries are small and local (SQLite on disk). If total injection time exceeds 2 seconds, skip and log a warning rather than blocking the plugin.

**Core skill reference**: Read `_infrastructure/memory/SKILL.md` for the full memory API (store, retrieve, query functions and SQL patterns).

---

## Execution Flow

### Step 1: Initialize the store

Check that `.memory/memory.db` exists. If it does not, initialize it from the schema:

```bash
if [ ! -f ".memory/memory.db" ]; then
  mkdir -p .memory
  sqlite3 .memory/memory.db < _infrastructure/memory/schema/memory-store.sql
fi
```

Quick schema validation — confirm the core tables exist:

```sql
SELECT name FROM sqlite_master
WHERE type = 'table'
  AND name IN ('memories', 'observations', 'adaptations');
-- Expected: 3 rows. If fewer, re-run the schema file.
```

If validation fails, re-apply the schema (idempotent due to `CREATE TABLE IF NOT EXISTS`) and continue.

---

### Step 2: Extract entities from input

Before querying, parse the plugin's current input to identify:

| Entity type | What to look for | Examples |
|-------------|-----------------|---------|
| Company names | Proper nouns matching known client names | "Acme Corp", "NaluForge" |
| Email domains | `@domain.com` patterns in any input text | `@acmecorp.com`, `@partner.io` |
| Contact names | First + last name pairs near email addresses | "Sarah Chen", "John Miller" |
| Contact emails | Full email addresses | `sarah@acme.com` |
| Topics / keywords | Core subject matter of the plugin's task | "invoices", "proposal", "follow-up" |
| Plugin name | The current plugin's ID (always available) | `P01`, `P10`, `P21` |

If the input is a user command string (e.g., `/founder-os:client:load acme`), parse the arguments. If the input is structured (e.g., a meeting title, email subject), extract entities from those fields.

**Company ID resolution**: If you identified a company name or domain, look up its Notion Companies page ID:

```sql
-- Check if we have any memories already scoped to this company to infer the ID,
-- or use the company name as a fallback filter on the content field.
SELECT DISTINCT company_id
FROM memories
WHERE company_id IS NOT NULL
  AND (
    content LIKE '%Acme Corp%'   -- company name match
    OR content LIKE '%acmecorp%' -- domain match
  )
LIMIT 1;
```

If a Notion Companies page ID is available from business context (`_infrastructure/context/active/current-data.md`) or the plugin's own CRM lookup, use that directly.

---

### Step 3: Query memories

Run three targeted queries. Each is bounded and fast. Execute them in order; collect all results before deduplicating.

**Query A — Semantic (relevance to current input)**

Generate a short summary of the plugin's current task (1–2 sentences capturing what it is about to do and any key entities). Use that summary as the semantic query text.

```
results_A = memory_query(input_text_summary, limit=5)
```

SQL executed internally by `memory_query`:

```sql
-- Fetch candidates for similarity scoring
SELECT id, key, category, content, source_plugin, company_id, tags,
       confidence, status, embedding
FROM memories
WHERE status IN ('confirmed', 'applied');

-- After cosine similarity ranking in the application layer,
-- take the top 5 by similarity score.
```

**Query B — Company-scoped (if a company was identified)**

Only run this if a `company_id` was resolved in Step 2.

```
results_B = memory_by_company(company_id, limit=3)
```

SQL executed internally:

```sql
SELECT id, key, category, content, source_plugin, tags,
       confidence, status, times_confirmed, updated_at
FROM memories
WHERE company_id = '<resolved_company_id>'
  AND status IN ('confirmed', 'applied')
ORDER BY confidence DESC, updated_at DESC
LIMIT 3;
```

**Query C — Plugin-specific preferences**

Fetch memories that this same plugin created in prior runs. These represent learned plugin-level preferences (e.g., "user always wants bullet format for P09 reports").

```
results_C = memory_by_plugin(current_plugin, limit=2)
```

SQL executed internally:

```sql
SELECT id, key, category, content, company_id, tags,
       confidence, status, times_confirmed, updated_at
FROM memories
WHERE source_plugin = '<current_plugin_id>'
  AND status IN ('confirmed', 'applied')
ORDER BY confidence DESC, updated_at DESC
LIMIT 2;
```

**Deduplication and capping**

Merge results_A + results_B + results_C into a single list. Remove duplicates by `id`. Apply final filter and ranking:

```sql
-- Conceptual representation of the merge and rank:
-- Filter: status IN ('confirmed', 'applied')  [already applied in each query]
-- Sort: confidence DESC, then relevance score DESC
-- Cap: return at most 5 memories total
```

Priority order when trimming to 5:
1. Memories appearing in multiple query results (highest signal)
2. Higher confidence
3. Higher semantic relevance score (from Query A)

---

### Step 4: Format the injection block

If 1 or more memories remain after deduplication and capping, format them as:

```
## Relevant Memories
- [preference] Always archive newsletters after drafting. (confidence: 85)
- [fact] Acme Corp pays invoices on net-30 terms. (confidence: 90)
- [contact] Sarah Chen at Acme is the billing decision-maker. (confidence: 72)
- [pattern] User batches invoice processing on Monday mornings. (confidence: 68)
- [workflow] Weekly review always starts with email triage before calendar. (confidence: 80)
```

Format rules:
- One bullet per memory
- Category in square brackets: `[preference]`, `[fact]`, `[contact]`, `[pattern]`, `[workflow]`
- Content verbatim from the `content` column (do not summarize or rewrite)
- Confidence value as an integer in parentheses at the end
- List ordered by confidence descending

---

### Step 5: Inject into working context

Add the formatted block to your active working context for this plugin execution. Treat each injected memory as a standing instruction:

- **preference** memories: adopt them as behavioral defaults for this run (e.g., "use bullet format" means use bullets unless the user explicitly overrides)
- **fact** memories: treat as ground truth about clients or business (e.g., payment terms, contact roles)
- **contact** memories: use when addressing or routing to specific people
- **pattern** memories: anticipate likely next steps or adjust timing/format accordingly
- **workflow** memories: follow the remembered sequence unless the user provides different instructions

The injected memories do NOT override explicit user instructions given in the current command invocation. They are defaults and background knowledge, not hard constraints.

---

### Step 6: Update usage stats

After injection, increment access counters for every memory that was included in the final 5:

```sql
UPDATE memories
SET times_used   = times_used + 1,
    last_used_at = unixepoch()
WHERE id IN (
  '<injected_memory_id_1>',
  '<injected_memory_id_2>',
  -- ... all injected IDs
);
```

Run this as a single UPDATE with an IN clause. Do not run one UPDATE per memory.

---

## When No Memories Found

If all three queries return 0 results (or all results are filtered out as `candidate` or `dismissed`):

- Skip the injection block entirely — do not render an empty `## Relevant Memories` section
- Do not log a warning; this is the expected state for new installations or first-time plugin runs
- Continue directly to plugin Step 1

---

## Graceful Degradation

Memory injection must **never block or fail a plugin's primary function**. Apply these fallback rules in order:

| Condition | Action |
|-----------|--------|
| `.memory/memory.db` does not exist | Attempt initialization once. If that fails, skip injection silently and continue. |
| Database file exists but is corrupt (SQLite error on open) | Skip injection. Log: `[memory] Warning: memory.db unreadable, skipping context injection.` Continue plugin execution. |
| Schema tables missing after init attempt | Skip injection. Log: `[memory] Warning: schema incomplete, skipping context injection.` Continue. |
| SQLite locked (WAL contention) | Retry once after 300ms. If still locked, skip injection and continue. |
| Embedding generation fails (Query A) | Fall back to Queries B and C only (company + plugin queries). These are pure SQL and do not require embeddings. |
| Injection step exceeds 2 seconds total | Abort remaining queries, use whatever results are available, and continue. Log: `[memory] Warning: context injection timed out after 2s, partial results used.` |
| Any unhandled exception | Catch, log the error message, skip injection, continue plugin execution. |

The plugin's `status` output should include `memory_status: "unavailable"` only if the database was found but completely inaccessible (corrupt or locked after retry). If injection simply found no relevant memories, omit `memory_status` from output entirely.

---

## Plugin Command Template

Add this block as **Step 0b** in every plugin command file, after Step 0a (business context) and before Step 1 (main logic). Copy verbatim:

~~~markdown
## Step 0b: Memory Context

Read `_infrastructure/memory/context-injection/SKILL.md` and follow the full Execution Flow.

Summary of what to do:
1. Verify `.memory/memory.db` exists (initialize from schema if not).
2. Extract company names, contact names, email domains, topics, and keywords from the current input.
3. Run three queries: semantic (`limit=5`), company-scoped (`limit=3`), plugin-specific (`limit=2`).
4. Deduplicate, filter to `status IN ('confirmed', 'applied')`, cap at 5 total (sort by confidence DESC).
5. If memories found, inject the `## Relevant Memories` block into working context and treat them as behavioral defaults.
6. Increment `times_used` and `last_used_at` for all injected memories.
7. If no memories or store unavailable, skip silently and continue.
~~~
