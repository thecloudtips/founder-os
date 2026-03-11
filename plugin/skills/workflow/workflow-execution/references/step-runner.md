# Step Runner Protocol Reference

## Overview
Detailed protocol for executing individual workflow steps, including condition evaluation, command invocation, output capture, timeout enforcement, and status tracking.

## Step Execution Sequence

For each step in the topologically sorted execution order:

### Phase 1: Pre-Execution Checks
1. Check if step should be skipped (dependency failed and step does not have continue_on_error=true on the failed upstream step)
2. Evaluate condition expression if present
3. If condition evaluates to false, mark step as `skipped` with reason "condition_false" and proceed to next step

### Phase 2: Context Substitution
1. Scan all values in the step's args map for `{{context.key}}` patterns
2. For each match, look up the key in the current context object
3. If key exists, replace the pattern with the stored value
4. If key does not exist, leave the raw `{{context.key}}` string and emit a warning:
   `Warning: Unresolved context key 'key' in step 'step-id'. Leaving raw template.`
5. Do NOT apply substitution to the command field, id, name, or any structural field

### Phase 3: Command Invocation
1. Display progress indicator: `[Step N/M] Running: step-name...`
2. Invoke the step's command as a Founder OS slash command with the resolved args
3. Start a timeout timer set to the step's timeout_seconds (or defaults.timeout_seconds if not specified)
4. Capture the command's output text

### Phase 4: Post-Execution
1. If command completed successfully:
   - Mark step status as `completed`
   - If output_as is defined, store the command output in context[output_as] (truncated to 500 chars)
   - Display: `✓ (Ns)` with elapsed time
2. If command failed:
   - Mark step status as `failed`
   - Store error message
   - Display: `✗ Failed (reason)`
   - Apply error handling rules (see error-handling.md)
3. If timeout exceeded:
   - Mark step status as `timed_out`
   - Display: `✗ Timed out after Ns`
   - Treat as a failure for error handling purposes

## Condition Evaluation

Condition expressions are simple string-based checks evaluated before step execution:

| Expression | Meaning |
|-----------|---------|
| `""` (empty) | Always run (no condition) |
| `"context.key"` | Run if context key exists and is non-empty |
| `"!context.key"` | Run if context key does NOT exist or is empty |
| `"context.key == value"` | Run if context key equals the specified value |
| `"context.key != value"` | Run if context key does not equal the specified value |

Condition evaluation rules:
- All comparisons are case-sensitive string comparisons
- Whitespace around operators is trimmed
- Invalid expressions default to true (run the step) with a warning
- Condition evaluation never throws — errors degrade to warnings

## Output Capture

Step output is the text response from the invoked command. Capture rules:
- Truncate to 500 characters maximum
- Strip leading/trailing whitespace
- If the command produces no output, store an empty string
- If the command fails before producing output, store the error message instead
- Output stored in context is a flat string — no JSON parsing or structure extraction

## Timeout Enforcement

- Default timeout: 300 seconds (from defaults.timeout_seconds)
- Per-step override: step's timeout_seconds field
- Valid range: 10-3600 seconds
- On timeout: immediately halt the step, mark as timed_out
- Timeout applies to the command invocation only, not pre/post processing
