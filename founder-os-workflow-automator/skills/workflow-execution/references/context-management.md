# Context Management Reference

## Overview
The context object is a flat key-value dictionary that enables data flow between workflow steps. Each run starts with a fresh context pre-populated with reserved keys, and steps add entries via output_as.

## Context Lifecycle

### Initialization (Before Step 1)
Create a new context object with reserved keys:
```
{
  "workflow_name": "morning-routine",
  "workflow_version": "1.0.0",
  "run_id": "550e8400-e29b-41d4-a716-446655440000",
  "run_timestamp": "2026-03-07T09:00:00Z"
}
```

### Growth (During Execution)
After each step with output_as completes successfully:
```
{
  "workflow_name": "morning-routine",
  "workflow_version": "1.0.0",
  "run_id": "...",
  "run_timestamp": "...",
  "email_summary": "You have 12 unread emails...",    // from step-1
  "calendar_events": "3 meetings today: ..."           // from step-2
}
```

### Disposal (After Completion)
Context is ephemeral — discarded after the workflow run completes. The final context state is preserved only in the Notion execution log's Context Snapshot property (truncated to 2000 chars).

## Reserved Keys

| Key | Type | Source | Description |
|-----|------|--------|-------------|
| workflow_name | string | workflow.name | Workflow identifier |
| workflow_version | string | workflow.version | Current version string |
| run_id | string | Generated UUID v4 | Unique run identifier |
| run_timestamp | string | ISO 8601 datetime | Execution start time |

Reserved keys cannot be overwritten by step output_as. Validation rule V013 prevents this.

## Substitution Rules

### Pattern
```
{{context.key_name}}
```

### Regex
```
\{\{context\.([a-zA-Z0-9_]+)\}\}
```

### Application Scope
Substitution applies ONLY to:
- Values in the step's `args` map

Substitution NEVER applies to:
- `command` field (could enable injection)
- `id`, `name`, or other metadata fields
- Keys in the args map (only values)
- `depends_on`, `condition`, `output_as`

### Unresolved Keys
When a context key is referenced but not found:
- Leave the raw `{{context.key}}` string unchanged
- Emit warning: `Warning: Unresolved context key 'key' in step 'step-id'`
- Do NOT abort the step — the command will receive the raw template string

### Multiple Substitutions
A single args value can contain multiple context references:
```yaml
args:
  message: "Summary: {{context.email_summary}} | Calendar: {{context.calendar_events}}"
```
Each reference is resolved independently. Partially resolved strings are allowed.

## Truncation Policy

### Step Output (output_as)
- Maximum length: 500 characters
- Truncation indicator: append "..." when truncated
- Applied immediately when storing in context

### Context Snapshot (Notion Log)
- Maximum length: 2000 characters total for JSON serialization
- If context exceeds 2000 chars, include only reserved keys + last 3 step outputs
- Use compact JSON (no indentation)

## Security Considerations

### Command Injection Prevention
- Context values are substituted only into args values (strings)
- Never interpolate context into the command field
- This prevents a step from injecting arbitrary commands through its output

### Data Size Limits
- 500-char truncation per context value prevents memory bloat
- 25-step limit caps total context growth
- Maximum theoretical context size: 25 x 500 = 12,500 chars + reserved keys

### Sensitive Data
- Context values may contain sensitive information from plugin outputs
- Context is stored in the Notion execution log — warn users about sensitive workflows
- No built-in redaction mechanism — recommend users avoid storing credentials in context
