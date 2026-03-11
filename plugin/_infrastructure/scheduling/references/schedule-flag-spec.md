# --schedule Flag Specification

## Argument Parsing

The `--schedule` flag is parsed from `$ARGUMENTS` before any other argument processing. If present, the command enters "scheduling mode" and does NOT execute its main logic.

### Patterns

1. **Create/update schedule**: `--schedule "expression"` where expression is:
   - Natural language: `"weekdays 8am"`, `"every Monday at 9am"`, `"daily 6am"`
   - Cron expression: `"0 8 * * 1-5"`, `"0 9 * * 1"` (detected by presence of numeric fields)
   - Detection rule: if expression contains only digits, spaces, asterisks, commas, hyphens, and slashes → treat as cron. Otherwise → treat as natural language.

2. **Disable schedule**: `--schedule disable`

3. **Check status**: `--schedule status`

4. **Persistent flag**: `--persistent` (only valid alongside `--schedule "expression"`)

### Validation

- Cron expressions must have exactly 5 space-separated fields
- Each field must be within valid range (see P27 cron-syntax reference)
- Natural language must convert to a valid cron expression
- Intervals shorter than 5 minutes: warn about excessive frequency
- Always confirm interpreted schedule with user before applying

## Workflow Generation

### File Location

Generated workflows are written to:
```
founder-os-workflow-automator/workflows/auto-[command-name].yaml
```

Where `[command-name]` is the kebab-case command name (e.g., `auto-daily-briefing.yaml`, `auto-morning-sync.yaml`).

### Template Substitution

Read `_infrastructure/scheduling/templates/workflow-template.yaml` and substitute:
- `{{WORKFLOW_NAME}}` → `auto-[command-name]`
- `{{WORKFLOW_DESCRIPTION}}` → `Auto-scheduled: [plugin-name] [command-name]`
- `{{CRON_EXPRESSION}}` → the validated cron expression
- `{{TIMEZONE}}` → system local timezone (or user-specified)
- `{{COMMAND}}` → the full slash command (e.g., `/briefing:daily`)
- `{{COMMAND_ARGS}}` → any default arguments for the command (empty by default)

### On Disable

1. Set `schedule.enabled: false` in the workflow YAML
2. If persistent: provide crontab removal instructions
3. Display: "Schedule disabled for [command]."

### On Status

1. Check if `auto-[command-name].yaml` exists
2. If exists and schedule.enabled=true: show cron, next 3 run times, mode (session/persistent)
3. If exists but disabled: show "Schedule exists but is disabled"
4. If not exists: show "No schedule configured. Use --schedule 'expression' to set one."

## Confirmation Display

```
Schedule configured: [command-name]

  Cron: [expression] ([human description])
  Timezone: [timezone]
  Mode: [Session | Persistent]

  Next runs:
    1. [datetime]
    2. [datetime]
    3. [datetime]

  Workflow: workflows/auto-[command-name].yaml
  Manage with: /workflow:schedule auto-[command-name] [--disable]
```
