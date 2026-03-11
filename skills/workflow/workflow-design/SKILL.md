---
name: Workflow Design
description: "Designs YAML-based automation workflows with DAG dependency resolution and validation. Activates when the user wants to create, design, or define a workflow, write YAML steps, or asks 'help me build an automation workflow.' Covers schema structure, step definition, dependency chaining, and validation rules."
globs:
  - commands/workflow-create.md
  - commands/workflow-edit.md
  - commands/workflow-list.md
---

## Overview

Define, validate, and manage YAML-based workflow files that chain Founder OS plugin commands into automated pipelines. Each workflow file specifies metadata, optional scheduling, default settings, and an ordered set of steps forming a directed acyclic graph (DAG). The automator resolves step dependencies, substitutes context variables between steps, and executes the pipeline in topological order.

## YAML Schema Structure

Every workflow file contains four top-level blocks.

### 1. `workflow` (required)

Workflow identity and metadata.

- **name** — Kebab-case string, unique identifier across all workflows. Must match the filename (without `.yaml`).
- **description** — One-to-two sentence plain-text summary of what the workflow accomplishes.
- **version** — Semantic version string (`MAJOR.MINOR.PATCH`). Increment on every structural change.
- **tags** — Array of lowercase strings for categorization and filtering. Use existing tags before inventing new ones.

### 2. `schedule` (optional)

Automated execution timing. Omit the entire block for on-demand-only workflows.

- **enabled** — Boolean. Set to `true` to activate scheduled runs.
- **cron** — Five-field cron expression (minute, hour, day-of-month, month, day-of-week). Required when `enabled: true`.
- **timezone** — IANA timezone string (e.g., `America/Los_Angeles`). Defaults to `UTC` when omitted.

### 3. `defaults`

Pipeline-wide settings applied to every step unless overridden at the step level.

- **stop_on_error** — Boolean, default `true`. Halt the entire pipeline when any step fails.
- **timeout_seconds** — Number, default `300`. Maximum wall-clock seconds per step.
- **output_format** — One of `chat`, `notion`, or `both`. Controls where step results are written.

### 4. `steps` (required, array)

Ordered list of pipeline steps. Each step object contains:

| Field | Type | Required | Description |
|---|---|---|---|
| id | string | yes | Unique kebab-case identifier within this workflow |
| name | string | yes | Human-readable step label |
| command | string | yes | Founder OS slash command to execute (must start with `/`) |
| args | map | no | Key-value pairs passed as command arguments. Values must be strings. |
| depends_on | array | no | List of step IDs that must complete before this step runs |
| continue_on_error | boolean | no | Override `stop_on_error` for this step. Default `false`. |
| output_as | string | no | Context key name to store this step's output for downstream steps |
| timeout_seconds | number | no | Per-step timeout override |
| condition | string | no | Expression evaluated at runtime; skip the step when it evaluates to false |

Refer to `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-design/references/yaml-schema.md` for the complete field-by-field specification with types, defaults, constraints, and annotated examples.

## Step Dependencies & DAG Model

Steps form a directed acyclic graph (DAG) via the `depends_on` field.

### Execution Order

- Steps with an empty or missing `depends_on` are root nodes and run first.
- A step executes only after every step listed in its `depends_on` array has completed successfully (or completed with error when `continue_on_error: true`).
- Steps that share no dependency relationship are grouped into the same execution batch. Report them as parallelizable, but execute sequentially within the batch since Claude cannot fork processes.

### Dependency Rules

- **Diamond dependencies** are allowed. Example: A feeds B and C independently; both B and C feed D. Step D waits for both B and C.
- **Cycle detection** is mandatory. Reject any workflow where following `depends_on` links forms a cycle. Report every step involved in the cycle.
- **Self-loops** are a special case of cycles. A step listing its own ID in `depends_on` is always invalid.

### Topological Sort

Resolve execution order using Kahn's algorithm:

1. Build an adjacency list and compute in-degree for every step.
2. Enqueue all steps with in-degree zero.
3. Dequeue a step, append it to the execution order, and decrement in-degree of its dependents.
4. Repeat until the queue is empty.
5. If the execution order contains fewer steps than the total step count, a cycle exists.

Refer to `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-design/references/dag-resolution.md` for the full algorithm implementation, cycle detection logic, parallel batch identification, and worked examples with diagrams.

## Validation Rules

Apply these checks before executing or saving any workflow. Reject the workflow and report all violations, not just the first.

1. All step IDs unique within the workflow.
2. All `depends_on` references point to existing step IDs.
3. No circular dependencies (DAG check).
4. Maximum 25 steps per workflow.
5. `command` field starts with `/`.
6. `args` values are strings only (no nested objects or arrays).
7. `cron` expression has exactly 5 fields when `schedule.enabled` is `true`.
8. `condition` expressions reference only valid context keys (reserved keys or `output_as` keys from upstream steps).
9. `output_as` keys are unique across all steps.
10. `version` follows semver format (`N.N.N`).
11. `workflow.name` uses kebab-case with no uppercase or special characters.
12. `steps` array is non-empty.
13. Step `id` values use kebab-case with no uppercase or special characters.
14. `timeout_seconds` is a positive integer when provided.

Refer to `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-design/references/validation-rules.md` for all 14 rules with error codes, messages, severity levels, and fix suggestions.

## Workflow File Conventions

- Store workflow files in the `workflows/` directory at the plugin root.
- File name must match `workflow.name` with a `.yaml` extension (e.g., `morning-pipeline.yaml` for `name: morning-pipeline`).
- Use kebab-case for workflow names and step IDs throughout.
- Start new workflows from `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-design/templates/workflow-template.yaml` to ensure correct structure.
- Commit workflows to version control. Track changes via the `version` field.

## Context Variable Substitution

Steps pass data downstream through context variables.

### Producing Context

Set `output_as` on a step to publish its output under that key. The value becomes available to all downstream steps (those that depend on the producing step, directly or transitively).

### Consuming Context

Reference a context value in any `args` field value using `{{context.key}}` syntax, where `key` matches the `output_as` value of an upstream step.

- Substitution occurs **only** in `args` field values. It does not apply to structural YAML fields like `command`, `id`, or `depends_on`.
- Unresolved references (no matching `output_as` from a completed upstream step) cause the step to fail with a clear error message.
- Multiple substitutions in a single value are allowed: `"{{context.client_name}} - {{context.report_date}}"`.

### Reserved Context Keys

These keys are auto-populated for every run and available to all steps without `output_as`:

| Key | Value |
|---|---|
| `workflow_name` | The `workflow.name` from the YAML |
| `workflow_version` | The `workflow.version` from the YAML |
| `run_id` | Unique identifier for this execution run |
| `run_timestamp` | ISO 8601 timestamp when the run started |

Do not use reserved key names as `output_as` values. Validation rejects collisions.

## Edge Cases

- **Empty steps array** — Reject with error. A workflow must contain at least one step.
- **Single-step workflow** — Valid. Runs as a standalone command with workflow metadata and optional scheduling.
- **Self-referencing depends_on** — Reject. A step listing its own ID is a self-loop.
- **Missing optional fields** — Apply defaults from the `defaults` block. When `defaults` itself omits a field, use the hardcoded defaults (`stop_on_error: true`, `timeout_seconds: 300`, `output_format: chat`).
- **Unknown fields** — Ignore with a warning logged to the run output. Do not reject the workflow.
- **Duplicate workflow names** — Reject when saving. Only one `.yaml` file per `workflow.name` may exist in `workflows/`.

## Additional Resources

- `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-design/references/yaml-schema.md` — Complete field-by-field schema specification with types, defaults, constraints, and examples for every YAML field.
- `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-design/references/dag-resolution.md` — Kahn's topological sort algorithm implementation, cycle detection logic, parallel batch identification, and worked examples.
- `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-design/references/validation-rules.md` — All 14 validation rules with error codes, messages, severity levels, and fix suggestions.
