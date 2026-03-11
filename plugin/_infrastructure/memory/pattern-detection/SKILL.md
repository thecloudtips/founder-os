---
name: memory-pattern-detection
description: Detect usage patterns and create/promote memories automatically after plugin execution
---

# Memory Pattern Detection

## Overview

The pattern detection skill runs as the **final step** of every plugin command. It observes what just happened, logs the observation, checks whether it confirms or extends existing patterns, and promotes memories when confidence thresholds are met.

**Purpose**: detect usage patterns and create/promote memories automatically — without requiring explicit user instruction.

**Trigger**: called at the end of every plugin command, after the primary output has been delivered to the user.

**Non-blocking**: pattern detection must never delay or prevent plugin output. If any step in this skill fails, log the failure silently and continue. The user never sees pattern detection errors.

**Schema reference**: `_infrastructure/memory/schema/memory-store.sql` defines the `observations`, `memories`, and `adaptations` tables used throughout this skill.

**Core memory API**: `_infrastructure/memory/SKILL.md` covers `memory_store`, `memory_get`, and confidence promotion — use those functions when this skill writes new memories.

---

## Observation Logging

After every plugin execution completes and output has been delivered, log one observation row. This is the raw event record — pattern detection runs against the accumulated observations table.

### What to capture

- `plugin` — the plugin ID that just ran (e.g., `P01`, `P21`)
- `action` — the primary action performed (e.g., `triage_email`, `crm_sync`, `generate_briefing`)
- `context` — JSON object with key details from this specific run

### Context JSON fields (include what is available)

| Field | Type | When to include |
|-------|------|----------------|
| `company` | string | When the run was scoped to a client (e.g., company name or domain) |
| `input_type` | string | What kind of input the plugin processed (e.g., `email`, `transcript`, `invoice`) |
| `output_type` | string | What kind of output was produced (e.g., `draft`, `briefing`, `report`) |
| `category` | string | Classification made during the run (e.g., `action-required`, `newsletter`, `high-priority`) |
| `priority` | string | Priority assigned, if any (e.g., `high`, `medium`, `low`) |
| `user_edited` | boolean | True if the user modified the plugin's output before accepting it |
| `edit_description` | string | Brief description of what changed (include only if `user_edited` is true) |
| `entity_type` | string | Type of new entity encountered (e.g., `company`, `contact`) |
| `entity_value` | string | The entity itself (e.g., `sarah@newclient.com`, `Acme Corp`) |
| `run_hour` | integer | Hour of day the run started (0–23), used for temporal pattern detection |

### Insert statement

```sql
INSERT INTO observations (id, plugin, action, context, observed_at)
VALUES (
  lower(hex(randomblob(16))),          -- generated UUID
  'P01',                               -- plugin ID
  'triage_email',                      -- action name
  '{"company":"Acme Corp","category":"action-required","priority":"high","run_hour":9}',
  unixepoch()                          -- current Unix timestamp
);
```

Log exactly one observation per plugin execution, even if the run processed multiple items (e.g., a batch of invoices). If a batch run is meaningfully heterogeneous (different companies, different categories), log one observation per distinct entity processed.

---

## Pattern Detection Rules

After logging the observation, run all five rules against recent observations. Rules are independent — a single run can trigger multiple rules.

### Rule 1 — Repeated Categorization

**Trigger**: the same plugin categorizes the same entity the same way 3 or more times.

**Query**:

```sql
SELECT plugin, context->>'$.company' AS entity, context->>'$.category' AS category, COUNT(*) AS count
FROM observations
WHERE plugin = 'P01'
  AND context->>'$.company' IS NOT NULL
  AND context->>'$.category' IS NOT NULL
GROUP BY plugin, entity, category
HAVING count >= 3;
```

Run this query scoped to the current plugin after each observation insert. If any (entity, category) pair reaches 3 or more occurrences, create a candidate memory.

**Memory to create**:
- `key`: `[plugin-id]-[entity-slug]-[category-slug]` (e.g., `p01-acmecorp-action-required`)
- `category`: `pattern`
- `content`: Natural language summary (e.g., `"Emails from @acmecorp.com are typically action-required"`)
- `source_plugin`: the triggering plugin ID
- `confidence`: 20 (auto-detected)

**Example**:

P01 categorizes emails from `@acmecorp.com` as `action-required` 5 times.

```sql
-- Detection query finds count = 5 for (P01, acmecorp.com, action-required)
-- memory_store call:
INSERT INTO memories (id, key, category, content, source_plugin, confidence, status, times_used, times_confirmed, created_at, updated_at)
VALUES (
  lower(hex(randomblob(16))),
  'p01-acmecorp-action-required',
  'pattern',
  'Emails from @acmecorp.com are typically action-required',
  'P01',
  20,
  'candidate',
  0, 0,
  unixepoch(), unixepoch()
);
```

If the memory key already exists, reinforce it instead of inserting (see Confidence Promotion section).

---

### Rule 2 — User Override Detection

**Trigger**: the user edits or overrides the plugin's output before accepting it. This is captured in the observation's `context` field when `user_edited` is true.

**Query**:

```sql
SELECT plugin, context->>'$.edit_description' AS edit_description, COUNT(*) AS count
FROM observations
WHERE plugin = ?
  AND context->>'$.user_edited' = 'true'
GROUP BY plugin, edit_description
HAVING count >= 2;
```

Two overrides of the same type from the same plugin is enough to create a preference candidate (lower threshold than other rules, since overrides are explicit user signals).

**Memory to create**:
- `key`: `pref-[plugin-id]-[edit-slug]` (e.g., `pref-p02-briefing-format`)
- `category`: `preference`
- `content`: Natural language preference statement (e.g., `"User prefers bullet-point format for daily briefings"`)
- `source_plugin`: the triggering plugin ID
- `confidence`: 35 (explicit user action, higher than pure observation)

**Example**:

User changes the briefing format after P02 generates it, twice in a row.

```sql
-- Detection finds 2 occurrences of edit_description "changed to bullet-point format" for P02
INSERT INTO memories (id, key, category, content, source_plugin, confidence, status, times_used, times_confirmed, created_at, updated_at)
VALUES (
  lower(hex(randomblob(16))),
  'pref-p02-briefing-format',
  'preference',
  'User prefers bullet-point format for daily briefings',
  'P02',
  35,
  'candidate',
  0, 0,
  unixepoch(), unixepoch()
);
```

---

### Rule 3 — New Entity Discovery

**Trigger**: a plugin encounters a company, contact, or entity that has no existing memory in the store.

**Check**:

```sql
-- Does any memory reference this entity?
SELECT id FROM memories
WHERE content LIKE '%' || ? || '%'   -- entity value (e.g., 'sarah@newclient.com')
   OR tags LIKE '%' || ? || '%';
```

If 0 rows are returned, the entity is new. Create a fact memory immediately (no threshold — one occurrence is enough for new entity discovery).

**Memory to create**:
- `key`: `entity-[entity-slug]` (e.g., `entity-sarah-newclient-com`)
- `category`: `fact` (for contacts) or `fact` (for companies)
- `content`: Natural language fact (e.g., `"Sarah (sarah@newclient.com) — new contact discovered by CRM Sync"`)
- `source_plugin`: the plugin that found the entity
- `confidence`: 30 (auto-detected fact)

**Example**:

P21 CRM Sync finds a new contact `sarah@newclient.com` during a sync run.

```sql
-- No existing memory references this email — it's a new entity
INSERT INTO memories (id, key, category, content, source_plugin, confidence, status, times_used, times_confirmed, created_at, updated_at)
VALUES (
  lower(hex(randomblob(16))),
  'entity-sarah-newclient-com',
  'fact',
  'Sarah (sarah@newclient.com) — new contact discovered by CRM Sync',
  'P21',
  30,
  'candidate',
  0, 0,
  unixepoch(), unixepoch()
);
```

---

### Rule 4 — Sequential Plugin Usage

**Trigger**: the same sequence of two or more plugins is run within a single session (or within 2 hours of each other) 3 or more times across different sessions.

**Query**: look at the last N observations ordered by time and identify recurring adjacent pairs or triples.

```sql
-- Find recurring two-plugin sequences across sessions
SELECT a.plugin AS first_plugin, b.plugin AS second_plugin, COUNT(*) AS count
FROM observations a
JOIN observations b
  ON b.observed_at > a.observed_at
  AND b.observed_at < a.observed_at + 7200   -- within 2 hours
  AND b.observed_at = (
    SELECT MIN(observed_at) FROM observations
    WHERE observed_at > a.observed_at
  )
GROUP BY first_plugin, second_plugin
HAVING count >= 3;
```

For triplets, extend the join to a third observation in the same time window.

**Memory to create**:
- `key`: `workflow-seq-[plugin1]-[plugin2]` (e.g., `workflow-seq-p01-p06`)
- `category`: `workflow`
- `content`: Natural language workflow description (e.g., `"Common workflow: Inbox Triage → Follow-Up Scan → Client Health"`)
- `source_plugin`: `pattern-detection`
- `confidence`: 20

**Example**:

User runs P01 → P06 → P10 three sessions in a row.

```sql
INSERT INTO memories (id, key, category, content, source_plugin, confidence, status, times_used, times_confirmed, created_at, updated_at)
VALUES (
  lower(hex(randomblob(16))),
  'workflow-seq-p01-p06-p10',
  'workflow',
  'Common workflow: Inbox Triage → Follow-Up Scan → Client Health',
  'pattern-detection',
  20,
  'candidate',
  0, 0,
  unixepoch(), unixepoch()
);
```

---

### Rule 5 — Temporal Patterns

**Trigger**: a plugin is run consistently at the same hour of day 5 or more times.

**Query**:

```sql
SELECT plugin, context->>'$.run_hour' AS hour, COUNT(*) AS count
FROM observations
WHERE plugin = ?
  AND context->>'$.run_hour' IS NOT NULL
GROUP BY plugin, hour
HAVING count >= 5;
```

**Memory to create**:
- `key`: `temporal-[plugin-id]-[hour]h` (e.g., `temporal-p02-8h`)
- `category`: `pattern`
- `content`: Natural language timing description (e.g., `"Daily briefing typically generated at 8:00 AM"`)
- `source_plugin`: `pattern-detection`
- `confidence`: 20
- `expires_at`: set to 90 days from now (`unixepoch() + 7776000`) — temporal patterns should refresh

**Example**:

P02 Daily Briefing is run at 8am 5 days in a row.

```sql
INSERT INTO memories (id, key, category, content, source_plugin, confidence, status, times_used, times_confirmed, created_at, updated_at, expires_at)
VALUES (
  lower(hex(randomblob(16))),
  'temporal-p02-8h',
  'pattern',
  'Daily briefing typically generated at 8:00 AM',
  'pattern-detection',
  20,
  'candidate',
  0, 0,
  unixepoch(), unixepoch(),
  unixepoch() + 7776000   -- 90-day TTL
);
```

---

## Confidence Promotion

After logging the observation and evaluating all five rules, check whether this observation confirms any existing candidate memories.

### Step 1: Match against existing candidates

For each candidate memory relevant to the current plugin and context, ask: does this observation support that memory's claim?

Matching criteria:
- Same plugin as `source_plugin` in the memory, or `source_plugin = 'pattern-detection'`
- Memory `content` or `key` references an entity, company, or sequence present in the current observation's `context`

If a match is found:

```sql
UPDATE memories
SET
  times_confirmed = times_confirmed + 1,
  confidence      = MIN(100, confidence + 15),
  updated_at      = unixepoch()
WHERE id = ?;   -- matched memory ID
```

### Step 2: Apply promotion ladder

Run both promotion checks after every confidence update:

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

### Promotion summary

| Transition | Conditions |
|-----------|-----------|
| candidate → confirmed | confidence ≥ 60 |
| confirmed → applied | confidence ≥ 80 AND times_confirmed ≥ 3 |

Each confirmation adds +15 confidence (capped at 100). Starting at 20 (auto-detected), a memory reaches confirmed after 3 confirmations (20 + 45 = 65 ≥ 60) and applied after roughly 5 total observations.

---

## Adaptation Trigger

When a memory reaches `applied` status for the first time (detected by the promotion queries above returning rows), trigger an adaptation.

### Step 1: Check whether an adaptation already exists

```sql
SELECT id FROM adaptations
WHERE memory_id = ?
  AND reverted_at IS NULL;
```

If a row is returned, an adaptation is already active — skip the insertion.

### Step 2: Log the adaptation

```sql
INSERT INTO adaptations (id, memory_id, plugin, description, applied_at)
VALUES (
  lower(hex(randomblob(16))),
  'memory-uuid-here',              -- the memory_id that just reached applied status
  'P01',                           -- plugin this adaptation affects
  'Now auto-flagging @acmecorp.com emails as VIP action-required',
  unixepoch()
);
```

The `description` should be a plain-language sentence starting with "Now" that describes the concrete behavior change. Examples:

- `"Now auto-flagging @acmecorp.com emails as VIP action-required"`
- `"Now generating daily briefings in bullet-point format"`
- `"Now suggesting Follow-Up Scan after Inbox Triage"`
- `"Now pre-loading 8 AM as the default briefing schedule"`

### Step 3: Append notification to plugin output

After the plugin's primary output, append:

```
---
> Memory adapted: I'm now [description] based on your last [N] sessions.
> Run /memory:show to review all active adaptations, or /memory:forget "[key]" to revert this one.
```

Where:
- `[description]` is the adaptation's `description` field
- `[N]` is the memory's `times_confirmed` value

**Example**:

```
---
> Memory adapted: I'm now auto-flagging @acmecorp.com emails as VIP action-required based on your last 5 sessions.
> Run /memory:show to review all active adaptations, or /memory:forget "p01-acmecorp-action-required" to revert this one.
```

Only show this notification on the run where the adaptation is first created. Subsequent runs should silently apply the adaptation without announcing it again.

---

## Decay Processing

Run decay checks once per day, triggered on the first plugin execution of the day. Determine "first of the day" by checking whether any observation was logged in the past 24 hours before this run:

```sql
SELECT COUNT(*) FROM observations
WHERE observed_at > unixepoch() - 86400;   -- 86400 seconds = 24 hours
```

If this returns 0, the current run is the first of the day — proceed with decay. If it returns > 0, skip decay (already ran today).

### Step 1: Apply decay to stale memories

```sql
-- Reduce confidence by 5 for memories not used in 30+ days
UPDATE memories
SET confidence = MAX(0, confidence - 5),
    updated_at = unixepoch()
WHERE status NOT IN ('dismissed')
  AND (last_used_at IS NULL OR last_used_at < unixepoch() - 2592000)   -- 30 days
  AND confidence > 0;
```

### Step 2: Revert active adaptations for memories about to expire

```sql
-- Mark adaptations as reverted before deleting their memories
UPDATE adaptations
SET reverted_at = unixepoch()
WHERE memory_id IN (
  SELECT id FROM memories
  WHERE confidence < 10
    AND status != 'dismissed'
)
AND reverted_at IS NULL;
```

### Step 3: Delete expired memories

```sql
DELETE FROM memories
WHERE confidence < 10
  AND status != 'dismissed';
```

### Step 4: Expire TTL-based memories

```sql
-- Remove memories whose explicit TTL has passed
UPDATE adaptations
SET reverted_at = unixepoch()
WHERE memory_id IN (
  SELECT id FROM memories
  WHERE expires_at IS NOT NULL AND expires_at < unixepoch()
    AND status != 'dismissed'
)
AND reverted_at IS NULL;

DELETE FROM memories
WHERE expires_at IS NOT NULL
  AND expires_at < unixepoch()
  AND status != 'dismissed';
```

### Decay summary

| Rule | Value |
|------|-------|
| Decay trigger | Not used in 30 days |
| Decay rate | -5 confidence per daily check |
| Auto-expire threshold | confidence < 10 |
| Dismissed memories | Exempt from all decay and deletion |
| TTL-based memories | Deleted when `expires_at` passes |

---

## Plugin Integration Pattern

Add the following final step to every plugin command, after the primary output has been delivered:

~~~markdown
## Final: Memory Update

Read `_infrastructure/memory/pattern-detection/SKILL.md`.

1. Log this execution as an observation (Observation Logging section)
2. Run pattern detection rules relevant to this plugin (Pattern Detection Rules section)
3. Check for confidence promotions (Confidence Promotion section)
4. If any memory just reached applied status, log the adaptation and append the notification (Adaptation Trigger section)
5. If this is the first plugin run of the day, run decay processing (Decay Processing section)

If `.memory/memory.db` is missing or any step fails, skip silently and do not surface errors to the user.
~~~

### Action names by plugin

Use consistent action names across runs so the observations table stays queryable. Recommended values:

| Plugin | Action Name |
|--------|------------|
| P01 Inbox Zero | `triage_email` |
| P02 Daily Briefing | `generate_briefing` |
| P03 Meeting Prep | `prepare_meeting` |
| P04 Action Items | `extract_actions` |
| P05 Weekly Review | `compile_weekly_review` |
| P06 Follow-Up Tracker | `scan_followups` |
| P07 Meeting Intel | `analyze_meeting` |
| P08 Newsletter Engine | `draft_newsletter` |
| P09 Report Generator | `generate_report` |
| P10 Client Health | `score_client_health` |
| P11 Invoice Processor | `process_invoice` |
| P12 Proposal Automator | `create_proposal` |
| P13 Contract Analyzer | `analyze_contract` |
| P14 SOW Generator | `generate_sow` |
| P15 Competitive Intel | `compile_competitive_intel` |
| P16 Expense Report | `build_expense_report` |
| P17 Notion Command Center | `notion_command` |
| P18 Drive Brain | `index_drive` |
| P19 Slack Digest | `generate_slack_digest` |
| P20 Client Context | `load_client_context` |
| P21 CRM Sync | `crm_sync` |
| P22 Morning Sync | `morning_sync` |
| P23 Knowledge Base | `knowledge_query` |
| P24 LinkedIn Post | `generate_linkedin_post` |
| P25 Time Savings | `calculate_roi` |
| P26 Prompt Library | `prompt_library_op` |
| P27 Workflow Automator | `run_workflow` |
| P28 Workflow Documenter | `document_workflow` |
| P29 Learning Log | `log_learning` |
| P30 Goal Tracker | `update_goal` |

---

## Graceful Degradation

Pattern detection must never interfere with a plugin's primary function.

| Failure | Response |
|---------|---------|
| `.memory/memory.db` missing | Skip all pattern detection silently; do not attempt to create the DB (that is the core SKILL.md's job) |
| `memory.db` exists but is corrupt or locked | Skip silently; log `memory_status: "unavailable"` internally if there is an existing output object |
| Observation insert fails | Skip pattern detection; do not retry |
| Pattern detection query fails | Skip rule; continue to next rule |
| Confidence promotion query fails | Skip promotion; the next run will catch it |
| Adaptation insert fails | Skip adaptation notification; do not surface to user |
| Decay processing fails | Skip; decay will re-run next day |

The invariant: **pattern detection must never block or fail a plugin's primary function.** If in doubt, skip and continue.
