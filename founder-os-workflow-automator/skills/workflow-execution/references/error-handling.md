# Error Handling Reference

## Overview
Three-tier error classification with configurable behavior at both workflow and step level. Error handling follows a deterministic decision tree with well-defined outcomes.

## Error Classification

### Tier 1: Validation Errors (Pre-Execution)
Detected during the validation phase, before any step runs.

| Error Type | Example | Behavior |
|-----------|---------|----------|
| YAML parse failure | Invalid YAML syntax | Abort, display parse error |
| Schema violation | Missing required field | Abort, display all violations |
| DAG cycle | Circular dependency | Abort, list cycle steps |
| Constraint violation | >25 steps | Abort, display rule and count |

**Behavior**: Collect ALL validation errors, display them at once, abort execution. Never run partial workflows with validation errors.

### Tier 2: Step Execution Errors (Runtime)
Detected during step execution.

| Error Type | Example | Behavior |
|-----------|---------|----------|
| Command failure | Plugin returns error | Apply error decision tree |
| Timeout | Step exceeds timeout_seconds | Treat as failure |
| Context error | Unresolved {{context.key}} | Warning only, continue |
| Missing command | Plugin not installed | Treat as failure |

**Behavior**: Apply the error decision tree below.

### Tier 3: Infrastructure Errors (Silent Degradation)
External system failures that don't affect core execution.

| Error Type | Example | Behavior |
|-----------|---------|----------|
| Notion unavailable | Can't log execution | Warn, skip logging, continue |
| Filesystem read-only | Can't write runner script | Warn, output to chat instead |
| Network timeout | MCP server unreachable | Step failure (Tier 2 handling) |

**Behavior**: Warn the user, degrade gracefully, never abort workflow due to infrastructure issues.

## Error Decision Tree

When a step fails at runtime:

```
Step Failed
├── step.continue_on_error = true?
│   ├── YES → Mark step "failed", continue to next step
│   │         Downstream dependent steps still run
│   └── NO → Check workflow defaults
│       ├── defaults.stop_on_error = true?
│       │   ├── YES → HALT WORKFLOW
│       │   │         Mark step "failed"
│       │   │         Mark all downstream dependents "skipped"
│       │   │         Mark workflow status "Failed"
│       │   │         Report error summary
│       │   └── NO → Mark step "failed", continue to next step
│       │             Downstream dependents are SKIPPED
│       │             (they depend on a failed step)
│       └── (defaults.stop_on_error defaults to true if not set)
```

### Key Distinction
- `continue_on_error=true` on a step: downstream steps that depend on this step STILL RUN (the failure is fully absorbed)
- `stop_on_error=false` at workflow level + step failure: the failed step's downstream dependents are SKIPPED, but independent branches continue

## Downstream Dependency Handling

When a step fails and its failure is NOT absorbed (continue_on_error=false):
1. Compute transitive closure: find all steps that directly or transitively depend on the failed step
2. Mark all steps in the transitive closure as `skipped` with reason: "upstream_dependency_failed"
3. Steps NOT in the transitive closure continue executing normally (independent branches)

Example:
```
A → B → D
A → C → E
```
If B fails (continue_on_error=false, stop_on_error=false):
- D is skipped (depends on B)
- C and E continue (independent of B)

## Error Message Templates

### Step Failure
```
✗ Step 'step-id' failed: [error message]
  Command: /plugin:command
  Duration: Ns
  Action: [Halting workflow | Continuing to next step | Skipping downstream steps]
```

### Workflow Halted
```
Workflow 'workflow-name' HALTED at step 'step-id'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Completed: N steps
Failed: 1 step
Skipped: M steps (downstream dependencies)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Error: [error message]
Suggestion: Fix the issue and resume with: /workflow:run workflow-name --from=step-id
```

### Workflow Completed with Failures
```
Workflow 'workflow-name' completed with failures
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Completed: N steps
Failed: F steps
Skipped: S steps
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Failed steps:
  - step-a: [error]
  - step-c: [error]
```

## Recovery Strategies

### Resume from Failure
Use `--from=step-id` flag on /workflow:run to resume:
1. Parse the workflow YAML normally
2. Resolve the full DAG
3. Skip all steps that come before the specified step in topological order
4. Begin execution from the specified step
5. If Notion execution log exists from previous run, attempt to restore context values for completed steps

### Retry Individual Step
Not supported as a dedicated command — recommend using `--from=step-id` which re-runs from the failed step forward.

### Manual Override
User can edit the workflow YAML to:
- Set continue_on_error=true on the problematic step
- Remove the step temporarily
- Add a fallback step with a condition checking for the error
