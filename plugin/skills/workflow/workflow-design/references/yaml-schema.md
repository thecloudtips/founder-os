# Workflow YAML Schema Reference

## workflow Block (Required)

| Field | Type | Required | Default | Constraints |
|-------|------|----------|---------|-------------|
| name | string | yes | — | kebab-case, 3-50 chars, unique identifier, must match filename |
| description | string | yes | — | 10-200 chars, human-readable purpose |
| version | string | no | "1.0.0" | Semantic versioning format (MAJOR.MINOR.PATCH) |
| tags | array[string] | no | [] | 0-10 tags, each 2-30 chars, kebab-case |

## schedule Block (Optional)

| Field | Type | Required | Default | Constraints |
|-------|------|----------|---------|-------------|
| enabled | boolean | yes (if block present) | false | true/false |
| cron | string | yes (if enabled=true) | — | 5-field cron expression |
| timezone | string | no | system local | Valid IANA timezone identifier |

## defaults Block (Optional)

| Field | Type | Required | Default | Constraints |
|-------|------|----------|---------|-------------|
| stop_on_error | boolean | no | true | Halt workflow on first step failure |
| timeout_seconds | number | no | 300 | 10-3600, per-step default timeout |
| output_format | string | no | "chat" | One of: chat, notion, both |

## steps Array (Required)

| Field | Type | Required | Default | Constraints |
|-------|------|----------|---------|-------------|
| id | string | yes | — | kebab-case, unique within workflow, 2-40 chars |
| name | string | yes | — | Human-readable, 3-80 chars |
| command | string | yes | — | Must start with "/", valid Founder OS slash command |
| args | map[string, string] | no | {} | Key-value pairs, values are strings only |
| depends_on | array[string] | no | [] | Step IDs that must complete before this step |
| continue_on_error | boolean | no | false | Override: allow workflow to continue if this step fails |
| output_as | string | no | — | Context key to store output, unique across steps, alphanumeric + underscore |
| timeout_seconds | number | no | defaults.timeout_seconds | Per-step timeout override, 10-3600 |
| condition | string | no | "" | Expression evaluated before execution |

## Context Substitution in Args

Pattern: `{{context.key}}`
- Only applied to args values (not keys, not command, not other fields)
- key must match: `[a-zA-Z0-9_]+`
- Reserved keys (auto-populated): workflow_name, workflow_version, run_id, run_timestamp
- Unresolved keys: left as raw template string with warning

## Complete Example

```yaml
workflow:
  name: "client-onboarding"
  description: "Automated client onboarding pipeline with CRM sync and briefing"
  version: "1.2.0"
  tags: ["client", "onboarding", "crm"]

schedule:
  enabled: false
  cron: "0 9 * * 1"
  timezone: "America/New_York"

defaults:
  stop_on_error: true
  timeout_seconds: 300
  output_format: "both"

steps:
  - id: "load-context"
    name: "Load Client Context"
    command: "/founder-os:client:load"
    args:
      client: "Acme Corp"
      refresh: "true"
    depends_on: []
    output_as: "client_context"
    timeout_seconds: 120

  - id: "sync-crm"
    name: "Sync CRM Records"
    command: "/founder-os:crm:sync-email"
    args:
      client: "Acme Corp"
      since: "7d"
    depends_on: []
    output_as: "crm_data"

  - id: "health-check"
    name: "Run Client Health Check"
    command: "/founder-os:client:health-report"
    args:
      client: "Acme Corp"
    depends_on:
      - "load-context"
      - "sync-crm"
    output_as: "health_report"

  - id: "generate-briefing"
    name: "Generate Client Briefing"
    command: "/founder-os:report:generate"
    args:
      data: "{{context.health_report}}"
      template: "client-summary"
    depends_on:
      - "health-check"
    output_as: "briefing"
```
