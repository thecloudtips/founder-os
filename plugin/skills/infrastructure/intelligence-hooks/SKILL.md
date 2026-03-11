---
name: intelligence-hooks
description: Event observation system for the Adaptive Intelligence Engine. Defines event schema, observation conventions, and annotation templates that plugins use to emit structured events during execution.
---

## Overview

The hooks system captures structured events from plugin command execution. Events are written to the Intelligence SQLite database (`intelligence.db`) and used by the learning and self-healing modules to detect patterns and improve over time.

## Event Types

| Event Type | When | Who Emits |
|---|---|---|
| `pre_command` | Before command starts | Plugin command file (convention block) |
| `post_command` | After command completes | Plugin command file (convention block) |
| `mcp_call` | After a significant MCP tool call | Plugin command file (opt-in annotation) |
| `decision_point` | Agent makes a key choice | Plugin command file (opt-in annotation) |
| `error` | Any failure or exception | Plugin command file (convention block) |

## Plugin Integration

Plugins emit events by including observation blocks in their command files. This follows the same pattern as AIOS Enrichment context-loading blocks — a ~5-line addition per command file.

### Pre-Command Block (required)

Add to the top of every command file, after any context-loading block:

```
## Observation: Start
Before executing this command, record the following to the Intelligence event store:
- Event type: pre_command
- Plugin: [plugin-name]
- Command: [command-name]
- Payload: { input parameters, context files loaded, memories injected }
- Generate a session_id (UUID) for this execution and use it for all subsequent events
```

### Post-Command Block (required)

Add to the bottom of every command file:

```
## Observation: End
After execution completes, record the following to the Intelligence event store:
- Event type: post_command
- Use the same session_id from the pre_command event
- Payload: { outcome summary, items processed count, outputs created }
- Outcome: "success" | "failure" | "degraded"
- Duration: time elapsed since pre_command event
- If any errors occurred during execution, also record an error event with:
  - Event type: error
  - Payload: { error_type, error_message, context, recovery_attempted }
```

### MCP Call Annotation (opt-in)

Add before significant MCP calls where latency or failure matters for learning:

```
## Observation: MCP Call
Record this MCP tool invocation to the Intelligence event store:
- Event type: mcp_call
- Payload: { tool_name, key_parameters, response_status, latency_ms, data_size }
- Use the same session_id from the pre_command event
```

Not every MCP call needs this annotation. Focus on calls that:
- Access external services (Notion, Gmail, Calendar, Drive, Slack)
- Are known failure points
- Have variable latency that affects user experience

### Decision Point Annotation (opt-in)

Add at key decision moments within a command:

```
## Observation: Decision
Record this decision to the Intelligence event store:
- Event type: decision_point
- Payload: { decision_description, options_considered, choice_made, reasoning }
- Use the same session_id from the pre_command event
```

Use for decisions that:
- Affect output quality (e.g., classifying email priority, choosing tone)
- The user might want to override or learn from (e.g., which data to include in a briefing)
- Represent branching logic where the system could go multiple ways

## Event Payload Examples

### pre_command
```json
{
  "input_params": { "filter": "is:unread", "limit": 50 },
  "context_files_loaded": ["business-info.md", "strategy.md"],
  "memories_injected": ["prefers concise email drafts", "Acme Corp is VIP"]
}
```

### post_command
```json
{
  "outcome_summary": "Triaged 23 emails: 5 urgent, 12 normal, 6 low priority",
  "items_processed": 23,
  "outputs_created": { "tasks": 5, "drafts": 3 }
}
```

### mcp_call
```json
{
  "tool_name": "notion-query",
  "key_parameters": { "database": "[FOS] Tasks", "filter": "Status=Open" },
  "response_status": "success",
  "latency_ms": 450,
  "data_size": 12
}
```

### decision_point
```json
{
  "decision_description": "Classify email priority",
  "options_considered": ["urgent", "normal", "low"],
  "choice_made": "urgent",
  "reasoning": "Sender is CEO of VIP client Acme Corp, subject contains 'ASAP'"
}
```

### error
```json
{
  "error_type": "notion_api_error",
  "error_message": "429 Too Many Requests",
  "context": "Querying [FOS] Tasks database during inbox triage",
  "recovery_attempted": "retry_with_backoff"
}
```

## Retention

- Raw events: kept for 30 days (configurable via `hooks.retention_days`)
- Aggregated patterns: kept indefinitely in the patterns table
- Event cleanup: old events purged when `/founder-os:intel:status` is run or on session start

## Database Location

The Intelligence database (`intelligence.db`) is stored at:
- `${CLAUDE_PLUGIN_ROOT}/../.intelligence/intelligence.db` (relative to any plugin)
- Or `_infrastructure/intelligence/.data/intelligence.db` (repo-relative)

The `.data/` directory should be added to `.gitignore` — it contains user-specific runtime data.
