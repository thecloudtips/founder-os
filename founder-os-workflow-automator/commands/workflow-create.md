---
description: Create a new workflow YAML file from a template or interactive builder
argument-hint: "[workflow-name] [--steps=N] [--from-template]"
allowed-tools: ["Read", "Write"]
---

# /workflow:create

Create a new workflow YAML file interactively or from the template scaffold.

## Load Skills

Read: `${CLAUDE_PLUGIN_ROOT}/skills/workflow-design/SKILL.md`

## Parse Arguments

- **workflow-name** (optional positional) — kebab-case name for the workflow. If not provided, ask: "What should this workflow be called? Use kebab-case (e.g., morning-routine, client-onboarding)."
- `--steps=N` (optional) — pre-create N placeholder steps (default: 2)
- `--from-template` (optional) — copy from `templates/workflow-template.yaml` with the new name

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Steps

1. **Get Workflow Name**: Use provided name or prompt. Validate kebab-case format (lowercase, hyphens, no spaces).

2. **Check for Conflicts**: Check if `workflows/[name].yaml` already exists. If so: "Workflow '[name]' already exists. Use /workflow:edit to modify it, or choose a different name."

3. **Choose Creation Mode**:
   - If `--from-template`: Copy template, replace placeholder values with workflow name
   - If interactive (default): Guide user through building the workflow

4. **Interactive Builder** (when not --from-template):
   a. Ask for workflow description: "Describe what this workflow does (1-2 sentences):"
   b. Ask for steps: "What Founder OS commands should this workflow run? List them in order (e.g., /inbox:triage, /daily:briefing):"
   c. For each command, ask: "Any arguments for [command]? (press Enter to skip)"
   d. Ask about dependencies: "Should steps run sequentially (each depends on the previous) or in parallel where possible?"
   e. Ask about scheduling: "Should this workflow run on a schedule? If so, describe when (e.g., 'every weekday at 9am'):"

5. **Generate YAML**: Build the workflow YAML following the schema from workflow-design skill. Apply defaults for timeout, stop_on_error, etc.

6. **Validate**: Run all 14 validation rules on the generated YAML.

7. **Write File**: Save to `workflows/[name].yaml`. Ensure the `workflows/` directory exists.

8. **Display Confirmation**:
```
Workflow created: workflows/[name].yaml

[name] — "[description]"
   Steps: [N]
   Schedule: [cron expression or "None"]

Use /workflow:run [name] to execute
Use /workflow:run [name] --dry-run to preview
Use /workflow:edit [name] to modify
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Edge Cases

- Name not kebab-case: suggest correction
- File already exists: redirect to /workflow:edit
- Empty steps list: create with template defaults (2 placeholder steps)
- Invalid commands in step list: accept them (validation happens at run time)

## Usage Examples

```
/workflow:create morning-routine
/workflow:create weekly-review --from-template
/workflow:create client-onboarding --steps=5
/workflow:create
```
