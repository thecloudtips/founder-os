---
name: intelligence-self-healing
description: Error classification, retry engine, and graceful degradation for Founder OS plugins. Classifies errors into four categories and applies appropriate recovery strategies.
---

## Overview

The self-healing module detects errors during plugin execution and applies recovery strategies. It classifies errors into four categories and learns which recovery approaches work over time.

## Error Categories

| Category | Signal | Action | Max Retries |
|---|---|---|---|
| **Transient** | HTTP 429, 503, timeout, network error | Retry with exponential backoff | 3 (configurable) |
| **Recoverable** | Auth expired, DB not found, schema mismatch | Apply known fix, then retry | 1 |
| **Degradable** | Optional source unavailable | Fall back to reduced capability | 0 |
| **Fatal** | Invalid input, missing required resource | Stop + notify user | 0 |

## Classification Rules

### Rule-Based (initial)

```
HTTP 429 → transient
HTTP 503 → transient
HTTP 502 → transient
"timeout" in error → transient
"ECONNREFUSED" in error → transient
"ENOTFOUND" in error → transient

HTTP 401 → recoverable (auth refresh)
HTTP 403 → fatal (permissions)
HTTP 404 + "database" → recoverable (DB discovery)
HTTP 404 + other → fatal

"not found" + Notion DB name → recoverable (try alternate names)
"rate limit" → transient

Slack/Drive/Calendar unavailable → degradable
Optional MCP source error → degradable

All other errors → fatal (safe default)
```

### Learned (over time)

The healing_patterns table tracks which classifications and fixes actually work. If a "transient" error persists across 3+ sessions, it gets reclassified to "recoverable" or "fatal". If a "fatal" error gets manually resolved by the user, the system learns the recovery path.

## Retry Engine

### Transient Errors

```
Attempt 1: wait 2 seconds, retry same call
Attempt 2: wait 5 seconds, retry same call
Attempt 3: wait 15 seconds, retry same call
Exhausted: reclassify as degradable (if optional source) or fatal (if required)
```

### Recoverable Errors

1. Look up the error_signature in healing_patterns table
2. If a known fix exists with success_count > failure_count, apply it
3. Known fixes:
   - Auth expired → re-run `gws auth login` prompt
   - Notion DB not found → apply 3-step discovery (search "[FOS] Name", then "Founder OS HQ - Name", then legacy name)
4. After applying fix, retry once
5. If still fails, reclassify as fatal

### Degradable Errors

1. Look up fallback in the fallback registry
2. Execute the fallback path (continue with available data)
3. Mark the output as "degraded" with clear explanation of what was skipped
4. Log which data source was unavailable and what the user lost

### Fatal Errors

1. Stop execution immediately
2. Present clear error message with suggested manual fix
3. Log the error for pattern analysis

## User Notifications

Every self-healing action produces a visible notification:

```
[Heal] {error_description} — retrying in {wait}s (attempt {n}/{max})
[Heal] {source} unavailable — continuing without {data_type}
[Heal] Recovered: {fix_description}, resuming command
[Heal] FAILED: {error_description} — {suggested_fix}
```

## Plugin Integration

Plugins integrate self-healing by including the error observation block (from hooks convention) and checking healing configuration:

```
## Self-Healing: Error Recovery
If an error occurs during this command:
1. Classify using the rules in _infrastructure/intelligence/self-healing/SKILL.md
2. Check healing.enabled config (default: true)
3. Apply the appropriate recovery strategy
4. Record an error event with recovery_attempted field
5. If recovery succeeds, continue execution and note the recovery in post_command
6. If recovery fails, stop and present the error to the user
```

## Learning From Failures

After each error event:
1. Look up or create a healing_pattern for this error_signature
2. If recovery was attempted and succeeded, increment success_count
3. If recovery was attempted and failed, increment failure_count
4. If success_count / (success_count + failure_count) drops below 0.5, demote the fix
5. If an error classified as "transient" appears 3+ times across sessions without resolution, reclassify
