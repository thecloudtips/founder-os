# Quick Start

## 1. Create Your First Workflow

```
/workflow:create morning-routine
```

Follow the interactive builder, or use the template:

```
/workflow:create morning-routine --from-template
```

## 2. Preview the Execution Plan

```
/workflow:run morning-routine --dry-run
```

This shows the step execution order without running anything.

## 3. Run the Workflow

```
/workflow:run morning-routine
```

Watch as each step executes in dependency order with progress indicators.

## 4. Check Execution History

```
/workflow:status morning-routine
```

## 5. Schedule It

### Session-level (active while Claude Code runs):
```
/workflow:schedule morning-routine --cron="0 9 * * 1-5"
```

### Persistent (survives session end):
```
/workflow:schedule morning-routine --natural="every weekday at 9am" --persistent
```

## Example: Morning Routine

Copy the example to your workflows directory:

```bash
cp workflows/examples/morning-routine.yaml workflows/morning-routine.yaml
```

Edit the steps to match your preferred plugins, then:

```
/workflow:run morning-routine
```

## Example: Weekly Review

```bash
cp workflows/examples/weekly-review.yaml workflows/weekly-review.yaml
/workflow:run weekly-review --dry-run
/workflow:run weekly-review
```

## Key Concepts

### Steps & Dependencies

Each step runs a plugin command. Use `depends_on` to control execution order:

```yaml
steps:
  - id: "gather"
    command: "/inbox:triage"
    depends_on: []          # Runs first (no dependencies)

  - id: "analyze"
    command: "/daily:briefing"
    depends_on: ["gather"]  # Runs after gather completes
```

### Context Passing

Steps share data using `{{context.key}}`:

```yaml
  - id: "gather"
    command: "/inbox:triage"
    output_as: "email_data"

  - id: "report"
    command: "/report:generate"
    args:
      data: "{{context.email_data}}"
    depends_on: ["gather"]
```

### Error Handling

By default, workflows stop on the first error. Override per-step:

```yaml
  - id: "optional-step"
    command: "/slack:catch-up"
    continue_on_error: true  # Workflow continues if this fails
```

### Resume from Failure

If a step fails, resume from that point:

```
/workflow:run my-workflow --from=failed-step-id
```

## All Commands

| Command | What it does |
|---------|-------------|
| `/workflow:create` | Create a new workflow |
| `/workflow:run` | Execute a workflow |
| `/workflow:list` | List all workflows |
| `/workflow:edit` | Modify a workflow |
| `/workflow:status` | View run history |
| `/workflow:schedule` | Set up recurring runs |
