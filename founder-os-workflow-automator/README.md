# Workflow Automator

Plugin #27 of Founder OS — a meta-orchestrator that chains any Founder OS plugin commands into automated YAML-defined workflows.

## What It Does

Define multi-step automation pipelines in YAML files, where each step invokes a Founder OS slash command. Steps can run in sequence or parallel (DAG-based), pass context between each other, and execute on a cron schedule.

## Commands

| Command | Description |
|---------|-------------|
| `/workflow:run [name]` | Execute a workflow (core command) |
| `/workflow:create [name]` | Create a new workflow interactively or from template |
| `/workflow:list` | List available workflows and their metadata |
| `/workflow:edit [name]` | Modify steps, schedule, or configuration |
| `/workflow:status [name]` | View execution history from Notion |
| `/workflow:schedule [name]` | Configure recurring execution (session or OS cron) |

## Skills

| Skill | Purpose |
|-------|---------|
| workflow-design | YAML schema, DAG resolution, validation rules |
| workflow-execution | Step runner, context management, error handling |
| workflow-scheduling | Cron syntax, NL-to-cron conversion, OS cron generation |

## Key Features

- **DAG-based execution**: Steps run in dependency order with parallel batch identification
- **Context passing**: Steps share data via `{{context.key}}` substitution
- **Error handling**: Three-tier strategy with configurable stop-on-error and continue-on-error
- **Cron scheduling**: Session-level and persistent OS-level cron jobs
- **Dry run mode**: Preview execution plan without running any steps
- **Resume from failure**: Restart from a specific step with `--from=step-id`
- **Notion logging**: Execution history tracked in "[FOS] Workflows" database (Type="Execution")
- **14 validation rules**: Comprehensive pre-execution validation

## MCP Requirements

| Server | Required | Purpose |
|--------|----------|---------|
| Filesystem | Yes | Read/write workflow YAML files |
| Notion | Optional | Execution history logging |

## Example Workflows

See `workflows/examples/` for ready-to-use workflows:
- `morning-routine.yaml` — Weekday morning check-in (4 steps)
- `weekly-review.yaml` — End-of-week review (6 steps, diamond dependency)
- `client-onboarding.yaml` — New client setup with CRM sync (5 steps)

## Plugin Info

- **Pillar**: Meta & Growth
- **Type**: Chained
- **Difficulty**: Advanced
- **Platform**: Claude Code
- **Dependencies**: Works with any Founder OS plugin commands
