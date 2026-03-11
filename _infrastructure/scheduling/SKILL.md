---
name: scheduling-bridge
description: "Adds --schedule flag support to any Founder OS plugin command. Generates P27 Workflow Automator YAML files behind the scenes so users can schedule recurring plugin execution without knowing P27 exists."
---

## Overview

The scheduling bridge enables any plugin command to accept a `--schedule` flag that configures recurring execution. Behind the scenes, it generates a P27 Workflow Automator workflow YAML and registers it with P27's scheduling system.

## --schedule Flag Specification

Any plugin command that supports scheduling adds this flag to its argument parsing:

| Flag | Value | Behavior |
|------|-------|----------|
| `--schedule "expression"` | Natural language or 5-field cron | Generate workflow + register schedule |
| `--schedule disable` | literal "disable" | Remove schedule for this command |
| `--schedule status` | literal "status" | Show current schedule status |
| `--persistent` | (no value, used with --schedule) | Generate OS-level cron instead of session-level |

See `references/schedule-flag-spec.md` for full parsing rules.

## How It Works

When a user runs e.g. `/briefing:daily --schedule "weekdays 7:30am"`:

1. Parse the schedule expression (NL or cron)
2. Generate workflow YAML from template at `templates/workflow-template.yaml`
3. Write to `founder-os-workflow-automator/workflows/auto-[command-name].yaml`
4. Read P27's scheduling skill at `founder-os-workflow-automator/skills/workflow-scheduling/SKILL.md`
5. Register the schedule (session-level by default, OS-level if `--persistent`)
6. Display confirmation with next 3 run times
7. Exit without running the main command logic

## Plugin Integration

Add this section to any plugin command file that should support scheduling:

~~~markdown
## Scheduling Support

If `$ARGUMENTS` contains `--schedule`:
1. Extract the schedule value and any `--persistent` flag
2. Read `_infrastructure/scheduling/SKILL.md` for scheduling bridge logic
3. Read `_infrastructure/scheduling/references/schedule-flag-spec.md` for argument parsing
4. Handle the schedule operation (create/disable/status) per the spec
5. Exit after scheduling — do NOT continue to main command logic
~~~

## Natural Language to Cron

Use P27's existing NL-to-cron conversion table (from `founder-os-workflow-automator/skills/workflow-scheduling/SKILL.md`):

| Natural Language | Cron |
|-----------------|------|
| "weekdays 8am" | `0 8 * * 1-5` |
| "every morning" | `0 9 * * *` |
| "every Monday" | `0 9 * * 1` |
| "Fridays 5pm" | `0 17 * * 5` |
| "daily 6am" | `0 6 * * *` |
| "twice daily" | `0 9,17 * * *` |

Always confirm the converted expression with the user before applying.

## Default Schedule Suggestions

When a plugin supports scheduling, suggest a sensible default if user hasn't specified one:

| Command | Suggested Default |
|---------|-------------------|
| `/briefing:daily` | Weekdays 7:30am |
| `/sync:morning` (`morning-sync`) | Weekdays 8:00am |
| `/review:weekly` (`review`) | Fridays 5:00pm |
| `/crm:sync-email` | Weekdays 9:00am, 2:00pm |
| `/client:health-scan` (`health-scan`) | Weekdays 9:30am |
| `/followup:check` | Weekdays 10:00am |
| `/drive:search` (`drive-search`) | Daily 6:00am |
| `/slack:digest` | Weekdays 6:00pm |
| `/learn:weekly` | Fridays 4:00pm |
