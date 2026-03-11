---
description: Execute a YAML-defined workflow by running all steps in dependency order
argument-hint: "[workflow-name] [--from=step-id] [--dry-run] [--output=chat|notion|both]"
allowed-tools: ["Read", "Write"]
---

# /workflow:run

Execute a workflow YAML file by parsing its steps, resolving the dependency DAG, and running each step's command in order with context passing between steps.

## Load Skills

Read all three skills before starting:

1. `${CLAUDE_PLUGIN_ROOT}/skills/workflow-design/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/skills/workflow-execution/SKILL.md`
3. `${CLAUDE_PLUGIN_ROOT}/skills/workflow-scheduling/SKILL.md`

## Parse Arguments

Extract from `$ARGUMENTS`:

- **workflow-name** (required positional) — name of the workflow to run (matches filename in `workflows/` without .yaml extension). If not provided, list available workflows in `workflows/` and ask the user to choose.
- `--from=step-id` (optional) — resume execution from this step, skipping all prior steps
- `--dry-run` (optional) — validate and show execution plan without running any steps
- `--output=chat|notion|both` (optional) — override the workflow's defaults.output_format

If `$ARGUMENTS` is empty, list workflow files found in `workflows/` directory and prompt for selection.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Step 1: Locate Workflow File

Search for `workflows/[workflow-name].yaml`. If not found, search case-insensitively. If still not found:

```
❌ Workflow '[name]' not found.
Available workflows:
  - morning-routine
  - weekly-review
  - client-onboarding
Use: /workflow:run [name]
```

## Step 2: Parse YAML

Read and parse the workflow YAML file. If YAML parsing fails, display the parse error with line number and stop.

## Step 3: Validate

Run all 14 validation rules from the workflow-design skill (read `${CLAUDE_PLUGIN_ROOT}/skills/workflow-design/references/validation-rules.md`). Collect all violations. If any errors (not warnings) exist, display all violations and stop. Warnings are displayed but do not block execution.

## Step 4: Resolve DAG

Apply Kahn's topological sort to determine step execution order (read `${CLAUDE_PLUGIN_ROOT}/skills/workflow-design/references/dag-resolution.md`). Identify parallel batches for display.

## Step 5: Handle --dry-run

If `--dry-run` is set, display the execution plan and stop:

```
Workflow: [name] v[version]
Execution Plan (dry run):
━━━━━━━━━━━━━━━━━━━━━━━━━━━

Batch 1 (parallel):
  [1] step-id-1: "Step Name" → /command
  [2] step-id-2: "Step Name" → /command

Batch 2:
  [3] step-id-3: "Step Name" → /command (depends on: step-id-1, step-id-2)

Batch 3:
  [4] step-id-4: "Step Name" → /command (depends on: step-id-3)

━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: [N] steps in [M] batches
Estimated time: ~[N*default_timeout]s max
```

Do not execute any steps.

## Step 6: Handle --from (Resume)

If `--from=step-id` is set:
1. Verify the step-id exists in the workflow
2. Determine all steps before this step in topological order
3. Skip those steps during execution
4. If a Notion execution log exists from a previous run of this workflow, attempt to restore context values for previously completed steps
5. Display: "Resuming from step '[step-id]'. Skipping [N] prior steps."

## Step 7: Execute Steps

Follow the step execution protocol from workflow-execution skill:

1. Initialize fresh context with reserved keys (workflow_name, workflow_version, run_id as UUID, run_timestamp)
2. Display workflow header:
   ```
   Workflow: [name] v[version]
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```
3. For each step in topological order:
   a. Check if step should be skipped (upstream failure or --from)
   b. Evaluate condition (if present)
   c. Apply context substitution to args
   d. Display: `[Step N/M] Running: step-name...`
   e. Invoke the command with args
   f. Capture output, store in context under output_as
   g. Display result: `✓ (Ns)` or `✗ Failed (reason)` or `⊘ Skipped (reason)`
   h. On failure, apply error handling rules from `${CLAUDE_PLUGIN_ROOT}/skills/workflow-execution/references/error-handling.md`

## Step 8: Display Summary

After all steps complete:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━
Result: [COMPLETED|FAILED|PARTIAL] ([N/M] steps)
  Completed: N ✓
  Failed: N ✗
  Skipped: N ⊘
Duration: [total time]
━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If any steps failed, add suggestion:
```
💡 Resume from failure: /workflow:run [name] --from=[failed-step-id]
```

## Step 9: Log to Notion

If Notion is available, log the execution to the "[FOS] Workflows" DB with Type="Execution", following the execution logging protocol in workflow-execution skill. Use the database discovery sequence: search for "[FOS] Workflows" first, try "Founder OS HQ - Workflows", fall back to "Workflow Automator - Executions". Do NOT create the database if none is found — skip logging silently. If Notion is unavailable, skip silently.

When logging to [FOS] Workflows, populate the Company relation if the workflow is scoped to a specific client.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Graceful Degradation

- **Workflow file not found**: List available workflows, suggest correct name
- **YAML parse error**: Show error with line number, stop
- **Validation errors**: Display all errors at once, stop
- **Step failure**: Follow error handling decision tree
- **Notion unavailable**: Skip execution logging, warn once
- **No workflows directory**: Create it and inform user: "No workflows found. Create a workflow file in `workflows/` or use /workflow:create."

## Usage Examples

```
/workflow:run morning-routine
/workflow:run weekly-review --dry-run
/workflow:run client-onboarding --from=health-check
/workflow:run morning-routine --output=notion
```
