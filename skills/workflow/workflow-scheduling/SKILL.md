---
name: Workflow Scheduling
description: "Schedules workflows using cron expressions with natural language conversion and OS-level integration. Activates when the user wants to schedule, automate timing, set up recurring runs, or asks 'run this workflow every Monday at 9am.' Covers cron syntax validation, natural language to cron conversion, and schedule management."
globs:
  - commands/workflow-schedule.md
  - commands/workflow-edit.md
---

## Overview
Configure recurring execution of workflow files using cron-based scheduling. Support both session-level scheduling (active while Claude Code is running) and persistent OS-level cron jobs that survive session termination. Convert natural language scheduling descriptions to standard 5-field cron expressions and validate cron syntax.

## Cron Expression Format
Use standard 5-field cron expressions:
```
┌───────── minute (0-59)
│ ┌─────── hour (0-23)
│ │ ┌───── day of month (1-31)
│ │ │ ┌─── month (1-12 or JAN-DEC)
│ │ │ │ ┌─ day of week (0-7, 0 and 7 = Sunday, or SUN-SAT)
│ │ │ │ │
* * * * *
```

Supported special characters: `*` (any), `,` (list), `-` (range), `/` (step)

Common patterns:
| Pattern | Cron | Description |
|---------|------|-------------|
| Weekday mornings | `0 9 * * 1-5` | 9 AM Mon-Fri |
| Every Monday | `0 8 * * 1` | 8 AM Monday |
| Twice daily | `0 9,17 * * *` | 9 AM and 5 PM |
| First of month | `0 10 1 * *` | 10 AM on 1st |
| Every 30 min | `*/30 * * * *` | Every half hour |

Reference `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-scheduling/references/cron-syntax.md` for complete syntax reference, validation rules, and edge cases.

## Natural Language to Cron Conversion
Convert common natural language schedule descriptions to cron expressions:

| Natural Language | Cron Expression |
|-----------------|-----------------|
| "every weekday at 9am" | `0 9 * * 1-5` |
| "every morning" | `0 9 * * *` |
| "every Monday" | `0 9 * * 1` |
| "twice a day" | `0 9,17 * * *` |
| "every hour" | `0 * * * *` |
| "every 15 minutes" | `*/15 * * * *` |
| "first of the month" | `0 10 1 * *` |
| "weekday evenings at 6" | `0 18 * * 1-5` |

Apply these conversion rules:
- Default hour: 9 (when time not specified, use 9 AM)
- Default minute: 0 (always use :00 unless specific minutes given)
- "morning" = 9 AM, "evening" = 18:00, "afternoon" = 14:00, "night" = 21:00
- "daily" = every day, "weekdays" = Mon-Fri, "weekends" = Sat-Sun
- Always confirm the conversion with the user before applying

## Scheduling Modes

### Session-Level Scheduling
Use CronCreate tool to create a schedule active during the current Claude Code session:
- Schedule runs workflow command at specified intervals
- Automatically removed when session ends
- Suitable for temporary or one-off automation
- Display confirmation with next 3 run times

### OS-Level Cron (Persistent)
Generate a shell script and crontab entry for persistent scheduling:
- Create a runner script at `workflows/runners/[workflow-name]-runner.sh`
- Script invokes `claude --command "/founder-os:workflow:run [name]"` (or equivalent CLI)
- Generate the crontab entry for the user to install
- Never modify the user's crontab directly — output instructions for manual installation
- Include the timezone in a comment above the crontab entry

Reference `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-scheduling/references/os-cron-generation.md` for runner script template, crontab format, and installation instructions.

## Schedule Management
Support these operations on scheduled workflows:
- **Enable**: Set schedule.enabled=true in the workflow YAML
- **Disable**: Set schedule.enabled=false
- **Update**: Modify the cron expression or timezone
- **List**: Show all workflows with schedule.enabled=true and their next run times
- **Remove**: Delete the runner script and provide crontab removal instructions

## Timezone Handling
- Store timezone as IANA identifier (e.g., "America/New_York", "Europe/London")
- Validate timezone strings against known IANA zones
- Display scheduled times in the workflow's configured timezone
- Default timezone: system local timezone if not specified
- Warn when scheduling across DST boundaries

## Validation
Validate schedule configuration:
- cron field must have exactly 5 space-separated fields
- Each field must be within its valid range
- Minute intervals shorter than 5 minutes: warn (may be excessive)
- schedule.enabled=true requires a valid cron expression
- timezone must be a valid IANA timezone identifier

## Edge Cases
- Schedule without timezone: default to system timezone, warn user
- Cron expression with seconds (6 fields): reject, inform user that only 5-field format is supported
- Schedule for past time today: next execution will be tomorrow at the specified time
- Conflicting schedules: multiple workflows can run at the same time — warn but allow

## Additional Resources
- `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-scheduling/references/cron-syntax.md` — Complete 5-field cron syntax specification, validation rules, special characters, common patterns, and edge cases
- `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-scheduling/references/os-cron-generation.md` — Runner script template, crontab entry format, installation/removal instructions, and troubleshooting guide
