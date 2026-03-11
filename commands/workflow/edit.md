---
description: Modify an existing workflow's steps, schedule, or configuration
argument-hint: "[workflow-name] [--add-step] [--remove-step=ID] [--schedule=CRON] [--disable-schedule]"
allowed-tools: ["Read", "Write"]
---

# /founder-os:workflow:edit

Modify an existing workflow YAML file — add/remove steps, update schedule, or change configuration.

## Load Skills

Read these skills before starting:

1. `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-design/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-scheduling/SKILL.md`

## Parse Arguments

- **workflow-name** (required positional) — name of workflow to edit. If not provided, list available workflows and prompt for selection.
- `--add-step` (optional) — interactively add a new step
- `--remove-step=ID` (optional) — remove step with given ID
- `--schedule=CRON-OR-NATURAL` (optional) — set or update the cron schedule. Accepts cron expression or natural language (e.g., "every weekday at 9am")
- `--disable-schedule` (optional) — set schedule.enabled=false

If no modification flags are provided, display the current workflow configuration and ask what the user wants to change.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Steps

1. **Locate Workflow**: Find `workflows/[workflow-name].yaml`. If not found, suggest closest match or list available workflows.

2. **Parse Current State**: Read and parse the YAML file. Display current configuration summary.

3. **Apply Modifications**:

   **--add-step**:
   a. Ask: "What command should this step run? (e.g., /founder-os:inbox:triage)"
   b. Ask: "Step name (human-readable):"
   c. Ask: "Any arguments? (key=value, comma-separated, or Enter to skip)"
   d. Ask: "Should it depend on any existing step? Available: [list step IDs]"
   e. Generate step ID from name (kebab-case)
   f. Insert step into the steps array

   **--remove-step=ID**:
   a. Find the step with matching ID
   b. Check if other steps depend on it. If so, warn: "Step '[ID]' is depended on by: [list]. Removing it will break those dependencies."
   c. Remove the step
   d. Remove the ID from all other steps' depends_on arrays

   **--schedule=VALUE**:
   a. If value looks like a cron expression (5 space-separated fields), use directly
   b. If natural language, convert to cron using workflow-scheduling skill's NL-to-cron rules
   c. Confirm the interpretation: "Schedule: [cron] ([description]). Correct?"
   d. Update schedule block: set cron, enabled=true

   **--disable-schedule**:
   a. Set schedule.enabled=false in the YAML

4. **Validate**: Run all 14 validation rules on the modified workflow.

5. **Write File**: Save the modified YAML back to the same file path.

6. **Display Confirmation**:
```
✅ Workflow updated: [name]

Changes:
  [+ Added step 'new-step' at position N]
  [- Removed step 'old-step']
  [~ Schedule updated: 0 9 * * 1-5 (weekdays at 9 AM)]

Use /founder-os:workflow:run [name] --dry-run to preview changes
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Edge Cases

- Workflow not found: suggest /founder-os:workflow:create
- Removing the only step: reject "Cannot remove the last step. Delete the workflow file instead."
- Adding step creates cycle: reject with cycle error
- Schedule NL ambiguous: present options and confirm

## Usage Examples

```
/founder-os:workflow:edit morning-routine --add-step
/founder-os:workflow:edit weekly-review --remove-step=old-report
/founder-os:workflow:edit morning-routine --schedule="every weekday at 8:30am"
/founder-os:workflow:edit client-onboarding --disable-schedule
/founder-os:workflow:edit morning-routine
```
