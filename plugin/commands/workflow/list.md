---
description: List available workflow files and their metadata
argument-hint: "[--scheduled] [--verbose]"
allowed-tools: ["Read"]
---

# /founder-os:workflow:list

List all workflow YAML files in the `workflows/` directory with their metadata.

## Load Skills

Read: `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-design/SKILL.md`

## Parse Arguments

- `--scheduled` (optional) — show only workflows with schedule.enabled=true
- `--verbose` (optional) — show full details including step count, dependencies, and schedule info

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Steps

1. **Scan Directory**: List all `.yaml` files in the `workflows/` directory (exclude `workflows/examples/` and `workflows/runners/`).

2. **Parse Metadata**: For each file, parse YAML and extract: workflow.name, workflow.description, workflow.version, workflow.tags, step count, schedule.enabled, schedule.cron.

3. **Filter**: If `--scheduled`, include only workflows where schedule.enabled=true.

4. **Display List**:

Default format:
```
Available Workflows
━━━━━━━━━━━━━━━━━━
  morning-routine     "Weekday morning check-in pipeline"      (4 steps)
  weekly-review       "End-of-week review and planning"         (6 steps)
  client-onboarding   "New client setup with CRM sync"          (5 steps, scheduled)
━━━━━━━━━━━━━━━━━━
Total: 3 workflows

Use /founder-os:workflow:run [name] to execute
```

Verbose format (--verbose): Add version, tags, schedule details, and step list for each workflow.

5. **Empty State**: If no workflows found:
```
No workflows found in workflows/ directory.
Create one with /founder-os:workflow:create or copy the template from templates/workflow-template.yaml
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/founder-os:workflow:list
/founder-os:workflow:list --scheduled
/founder-os:workflow:list --verbose
```
