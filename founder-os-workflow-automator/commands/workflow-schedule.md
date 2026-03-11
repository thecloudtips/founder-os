---
description: Set up persistent scheduling for a workflow using session or OS-level cron
argument-hint: "[workflow-name] [--cron=EXPR] [--natural=DESC] [--persistent] [--disable] [--list]"
allowed-tools: ["Read", "Write"]
---

# /workflow:schedule

Configure recurring execution of a workflow via session-level or persistent OS cron scheduling.

## Load Skills

Read these skills:

1. `${CLAUDE_PLUGIN_ROOT}/skills/workflow-scheduling/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/skills/workflow-design/SKILL.md`

## Parse Arguments

- **workflow-name** (optional positional) — workflow to schedule. Required unless `--list`.
- `--cron=EXPR` (optional) — 5-field cron expression
- `--natural=DESC` (optional) — natural language schedule (e.g., "every weekday at 9am")
- `--persistent` (optional) — generate OS-level cron job instead of session-level
- `--disable` (optional) — disable scheduling for this workflow
- `--list` (optional) — list all scheduled workflows (no workflow-name needed)
- `--timezone=TZ` (optional) — IANA timezone (default: system local)

If workflow-name provided but no --cron or --natural, check if workflow already has a schedule block and use it.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Steps

### --list Mode

1. Scan all `.yaml` files in `workflows/`
2. Filter for schedule.enabled=true
3. Display:
```
Scheduled Workflows
━━━━━━━━━━━━━━━━━━
  morning-routine    0 9 * * 1-5    Weekdays at 9:00 AM     (session)
  weekly-review      0 17 * * 5    Fridays at 5:00 PM       (persistent)
━━━━━━━━━━━━━━━━━━
Total: 2 scheduled workflows
```
4. If none scheduled: "No workflows are currently scheduled. Use /workflow:schedule [name] --cron='...' to add one."

### Schedule Mode

1. **Locate Workflow**: Find `workflows/[workflow-name].yaml`. If not found, error.

2. **Determine Cron Expression**:
   - If `--cron` provided: validate the 5-field expression per cron-syntax reference (`${CLAUDE_PLUGIN_ROOT}/skills/workflow-scheduling/references/cron-syntax.md`)
   - If `--natural` provided: convert using NL-to-cron table from workflow-scheduling skill. Confirm: "Interpreted as: [cron] ([description]). Correct?"
   - If neither: check workflow's schedule.cron. If empty, ask user.

3. **Update Workflow YAML**: Set schedule.enabled=true, schedule.cron, schedule.timezone.

4. **Session-Level Schedule** (default):
   - Use CronCreate to register the schedule for the current session
   - Display next 3 run times
   - Note: "This schedule is active for this session only. Use --persistent for OS-level cron."

5. **Persistent Schedule** (--persistent):
   - Generate runner script at `workflows/runners/[name]-runner.sh` per os-cron-generation reference (`${CLAUDE_PLUGIN_ROOT}/skills/workflow-scheduling/references/os-cron-generation.md`)
   - Make script executable
   - Display crontab installation instructions (never modify crontab directly)
   - Display: "Runner script created. Follow the instructions above to install the persistent cron job."

### --disable Mode

1. Set schedule.enabled=false in the workflow YAML
2. If a session schedule exists, note it will stop at session end
3. If persistent, provide crontab removal instructions
4. Display: "Schedule disabled for '[name]'."

## Confirmation Display

```
✅ Schedule configured: [name]

⏰ Cron: [expression] ([human description])
🌍 Timezone: [timezone]
📋 Mode: [Session | Persistent]

Next runs:
  1. [datetime]
  2. [datetime]
  3. [datetime]

[For persistent: installation instructions]
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Edge Cases

- Invalid cron: display error with valid format hint
- Ambiguous NL: present multiple options
- Interval < 5 min: warn about excessive frequency
- No workflow name with --list: OK (list doesn't need one)
- Already scheduled: update existing schedule

## Usage Examples

```
/workflow:schedule morning-routine --cron="0 9 * * 1-5"
/workflow:schedule weekly-review --natural="every Friday at 5pm" --persistent
/workflow:schedule client-onboarding --disable
/workflow:schedule --list
/workflow:schedule morning-routine --timezone=Europe/London
```
