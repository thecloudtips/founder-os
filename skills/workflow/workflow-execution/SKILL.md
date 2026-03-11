---
name: Workflow Execution
description: "Runs workflow steps, manages execution context, and handles errors during workflow automation. Activates when the user wants to run, execute, resume, or check status on a workflow, or asks 'start the [name] workflow.' Covers step execution protocol, context passing between steps, error recovery, and Notion execution logging."
globs:
  - commands/workflow-run.md
  - commands/workflow-status.md
---

## Overview
Execute YAML-defined workflows by resolving the step DAG, running each step's command in dependency order, passing context between steps, handling errors according to configured strategy, and logging execution results to Notion. The execution engine operates as a stateless pipeline — each run initializes fresh context.

## Execution Pipeline (5 Phases)
1. **Locate & Parse**: Find the workflow YAML file in `workflows/` by name, parse YAML
2. **Validate**: Run all 14 validation rules from workflow-design skill
3. **Resolve DAG**: Apply Kahn's topological sort to determine execution order
4. **Execute Steps**: Run each step in resolved order, passing context between steps
5. **Log to Notion**: Record execution results in "[FOS] Workflows" DB (Type="Execution")

## Step Execution Protocol
For each step in the resolved execution order:
1. Evaluate condition expression (if present). Skip step if condition evaluates to false.
2. Apply context substitution: replace `{{context.key}}` patterns in args values
3. Display step progress: `[Step N/M] Running: step-name...`
4. Invoke the step's command with its args
5. Capture step output and store in context under the output_as key (truncated to 500 chars)
6. Record step status: completed, failed, or skipped
7. On failure: check continue_on_error flag. If false and defaults.stop_on_error is true, halt the workflow. If true, mark step as failed and continue.
8. Enforce timeout: if step exceeds timeout_seconds, terminate and mark as timed_out

Reference `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-execution/references/step-runner.md` for detailed execution protocol, condition evaluation, and timeout handling.

## Context Management
- Initialize a fresh context object at the start of each run
- Pre-populate reserved keys: workflow_name, workflow_version, run_id (UUID), run_timestamp (ISO 8601)
- After each step completes, store its output under the step's output_as key
- Context values are strings truncated to 500 characters max
- Substitution pattern: `{{context.key}}` — match with regex `\{\{context\.([a-zA-Z0-9_]+)\}\}`
- Substitution applies ONLY to args field values, never to command, id, or structural fields
- Unresolved context references (key not found): leave the raw `{{context.key}}` string and log a warning
- Context is ephemeral — discarded after run completion

Reference `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-execution/references/context-management.md` for substitution rules, reserved keys, truncation policy, and security considerations.

## Error Handling Strategy
Three-tier error classification:
1. **Validation Errors** (pre-execution): YAML parse failures, validation rule violations. Abort before any step runs. Display all errors at once.
2. **Step Execution Errors** (runtime): Command failures, timeouts, missing context keys. Behavior controlled by continue_on_error (per-step) and stop_on_error (workflow default).
3. **Infrastructure Errors** (silent degradation): Notion unavailable for logging, filesystem permission issues. Log warning, continue execution.

Error handling decision tree:
- Step fails + continue_on_error=true → mark failed, continue to next step
- Step fails + continue_on_error=false + stop_on_error=true → halt workflow, report failure
- Step fails + continue_on_error=false + stop_on_error=false → mark failed, continue
- Multiple steps depend on failed step → skip all downstream dependents

Reference `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-execution/references/error-handling.md` for decision trees, error message templates, and recovery strategies.

## Resume Capability
Support resuming a failed workflow from a specific step using `--from=step-id`:
- Skip all steps before the specified step in the execution order
- Re-initialize context with any available cached values from the previous run (if Notion log exists)
- Re-run from the specified step forward

## Notion Execution Logging
Log each workflow run to the "[FOS] Workflows" database with Type="Execution".

### Database Discovery
1. Search Notion for a database titled "[FOS] Workflows".
2. If not found, try "Founder OS HQ - Workflows".
3. If not found, fall back to searching for "Workflow Automator - Executions" (legacy DB name).
4. If none exists, skip Notion logging silently (do NOT create the database).

### Property Mapping
Write these properties on each execution record:

| Property | Type | Value |
|----------|------|-------|
| Title | title | Run ID (UUID identifier for this execution) |
| Type | select | "Execution" (always) |
| Status | select | Running, Completed, Failed, Cancelled |
| Description | rich_text | Name from workflow.name |
| Steps Count | number | Total step count |
| Steps Completed | number | Successfully completed steps |
| Steps Failed | number | Failed steps |
| Steps Skipped | number | Skipped steps (condition false or downstream of failure) |
| Started At | date | Execution start timestamp |
| Completed At | date | Execution end timestamp |
| Duration | rich_text | Human-readable duration (e.g., "2m 34s") |
| Triggered By | select | Manual, Schedule, Chained |
| Workflow Version | rich_text | Version from workflow.version |
| Context Snapshot | rich_text | JSON of final context state (truncated to 2000 chars) |
| Error Summary | rich_text | First error message if failed |
| Generated At | date | Timestamp when record was written |
| Company | relation | Populate Company relation when the workflow execution is client-scoped (triggered for a specific client or involves client-specific data) |

### Idempotent Key
Upsert by Run ID (title) with an additional filter on Type="Execution" to avoid collisions with SOP records in the same database.

## Progress Display
During execution, display real-time progress to the user:
```
Workflow: morning-routine v1.0.0
[Step 1/4] Running: check-email... ✓ (12s)
[Step 2/4] Running: review-calendar... ✓ (8s)
[Step 3/4] Running: generate-briefing... ✗ Failed (timeout)
[Step 4/4] Skipped: send-summary (depends on failed step)

Result: PARTIAL (2/4 completed, 1 failed, 1 skipped)
Duration: 23s
```

## Edge Cases
- Workflow with all steps skipped by conditions: Status = Completed with 0 steps completed
- Single step workflow failure: Status = Failed
- Notion unavailable or none of "[FOS] Workflows", "Founder OS HQ - Workflows", "Workflow Automator - Executions" DB found: proceed with execution, skip logging, warn user
- Empty context reference in args: leave raw template string, log warning

## Additional Resources
- `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-execution/references/step-runner.md` — Step execution protocol, condition evaluation, timeout enforcement, and command invocation details
- `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-execution/references/context-management.md` — Context initialization, substitution rules, reserved keys, truncation, and security considerations
- `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-execution/references/error-handling.md` — Error classification, decision trees, error templates, recovery strategies, and resume protocol
