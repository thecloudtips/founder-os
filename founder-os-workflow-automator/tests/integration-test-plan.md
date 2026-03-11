# Integration Test Plan — Workflow Automator (P27)

## Test Environment

- Claude Code with Workflow Automator plugin installed
- Filesystem MCP server connected (required)
- Notion MCP server connected (optional — test both with and without)
- At least 2 other Founder OS plugins installed (for step commands)
- Example workflows in `workflows/examples/` directory

## Test Categories

### T1: Workflow YAML Parsing & Validation

| ID | Test | Expected Result |
|----|------|-----------------|
| T1.1 | Run `/workflow:run morning-routine` with valid YAML | Parses successfully, proceeds to execution |
| T1.2 | Run `/workflow:run` with malformed YAML (missing colon) | Parse error with line number, execution blocked |
| T1.3 | Create workflow with duplicate step IDs | V002 error displayed, execution blocked |
| T1.4 | Create workflow with circular dependency (A→B→A) | V004 error with cycle steps listed |
| T1.5 | Create workflow with 26 steps | V005 error about maximum step count |
| T1.6 | Create workflow with command missing "/" prefix | V006 error displayed |
| T1.7 | Create workflow with non-string args values | V007 error displayed |
| T1.8 | Run workflow with schedule.enabled=true but no cron | V008 error displayed |
| T1.9 | Create workflow with duplicate output_as keys | V009 error displayed |
| T1.10 | Create workflow with step depending on itself | V011 error displayed |
| T1.11 | Validate workflow with warnings only (bad semver) | Warnings shown but execution proceeds |

### T2: DAG Resolution & Execution Order

| ID | Test | Expected Result |
|----|------|-----------------|
| T2.1 | Run linear pipeline (A→B→C→D) | Executes in order A, B, C, D |
| T2.2 | Run parallel roots (A, B → C) | A and B run first, then C |
| T2.3 | Run diamond pattern (A → B,C → D) | A first, B and C second batch, D last |
| T2.4 | Run single-step workflow | Step executes, workflow completes |
| T2.5 | Run `--dry-run` mode | Shows execution plan, no steps executed |
| T2.6 | Verify batch grouping in dry-run output | Steps at same topological level grouped |

### T3: Step Execution & Context Passing

| ID | Test | Expected Result |
|----|------|-----------------|
| T3.1 | Step with output_as stores result in context | Subsequent step can reference via `{{context.key}}` |
| T3.2 | Context substitution in args values | `{{context.key}}` replaced with actual value |
| T3.3 | Unresolved context key | Raw template string preserved, warning logged |
| T3.4 | Multiple context references in one arg | All resolved independently |
| T3.5 | Reserved context keys available | workflow_name, run_id, etc. accessible |
| T3.6 | Output truncation at 500 chars | Long output truncated with "..." |
| T3.7 | Step progress display | `[Step N/M] Running: name...` shown for each step |

### T4: Error Handling

| ID | Test | Expected Result |
|----|------|-----------------|
| T4.1 | Step fails, stop_on_error=true (default) | Workflow halts, downstream steps skipped |
| T4.2 | Step fails, continue_on_error=true on step | Step marked failed, downstream dependents still run |
| T4.3 | Step fails, stop_on_error=false at workflow level | Failed step's dependents skipped, independent branches continue |
| T4.4 | Step timeout exceeded | Step marked timed_out, treated as failure |
| T4.5 | All steps skipped by conditions | Workflow status = Completed with 0 steps |
| T4.6 | Resume with --from=step-id | Prior steps skipped, execution starts from specified step |
| T4.7 | Resume with invalid step-id | Error: step not found in workflow |

### T5: Condition Evaluation

| ID | Test | Expected Result |
|----|------|-----------------|
| T5.1 | Empty condition | Step always runs |
| T5.2 | `condition: "context.key"` with key present | Step runs |
| T5.3 | `condition: "context.key"` with key absent | Step skipped |
| T5.4 | `condition: "!context.key"` with key absent | Step runs |
| T5.5 | Invalid condition expression | Warning, step runs (default true) |

### T6: Scheduling

| ID | Test | Expected Result |
|----|------|-----------------|
| T6.1 | `/workflow:schedule name --cron="0 9 * * 1-5"` | Schedule set, next 3 run times shown |
| T6.2 | `/workflow:schedule name --natural="every weekday at 9am"` | Converted to `0 9 * * 1-5`, confirmed with user |
| T6.3 | `/workflow:schedule --list` | All scheduled workflows shown with cron expressions |
| T6.4 | `/workflow:schedule name --disable` | schedule.enabled set to false |
| T6.5 | `/workflow:schedule name --persistent` | Runner script generated, crontab instructions shown |
| T6.6 | Invalid cron expression (6 fields) | Error with format hint |
| T6.7 | Interval < 5 minutes | Warning about excessive frequency |

### T7: Notion Integration

| ID | Test | Expected Result |
|----|------|-----------------|
| T7.1 | Run with "[FOS] Workflows" DB present | Execution logged with Type="Execution", all fields populated |
| T7.2 | Run without HQ DB but with legacy "Workflow Automator - Executions" DB | Falls back to legacy DB, execution logged correctly |
| T7.3 | Run with neither HQ nor legacy DB present | Execution proceeds, logging skipped silently (no DB creation) |
| T7.4 | Failed run logged with error summary | Status=Failed, Error Summary populated |
| T7.5 | Notion unavailable during run | Execution proceeds, logging skipped, warning shown |
| T7.6 | `/workflow:status` queries HQ DB with Type="Execution" filter | Recent executions displayed, SOP records excluded |
| T7.7 | `/workflow:status` falls back to legacy DB when HQ not found | Recent executions displayed correctly |
| T7.8 | `/workflow:status` without Notion | Helpful error message about Notion requirement |

### T8: Commands

| ID | Test | Expected Result |
|----|------|-----------------|
| T8.1 | `/workflow:list` with workflows present | Lists all with names, descriptions, step counts |
| T8.2 | `/workflow:list` with no workflows | Empty state message with creation hint |
| T8.3 | `/workflow:list --scheduled` | Shows only scheduled workflows |
| T8.4 | `/workflow:create name --from-template` | Copies template, replaces name |
| T8.5 | `/workflow:create` (no args) | Interactive mode prompts for name |
| T8.6 | `/workflow:create existing-name` | Conflict detected, redirects to edit |
| T8.7 | `/workflow:edit name --add-step` | Interactive step addition |
| T8.8 | `/workflow:edit name --remove-step=id` | Step removed, dependencies updated |
| T8.9 | `/workflow:edit name --schedule="..."` | Schedule updated in YAML |

### T9: Edge Cases

| ID | Test | Expected Result |
|----|------|-----------------|
| T9.1 | Workflow file with unknown YAML fields | Ignored with warning |
| T9.2 | Workflow name not in kebab-case | V014 warning, still runs |
| T9.3 | Empty args object on step | Step runs with no arguments |
| T9.4 | Step with no output_as | Runs normally, no context stored |
| T9.5 | `workflows/` directory doesn't exist | Created automatically |
| T9.6 | Very long step output (>500 chars) | Truncated at 500 chars |
| T9.7 | Workflow with all optional fields omitted | Defaults applied, runs correctly |

## Acceptance Criteria Coverage

| Criterion | Test IDs |
|-----------|----------|
| YAML workflow definition and parsing | T1.1, T1.2 |
| DAG-based step execution | T2.1-T2.6 |
| Context passing between steps | T3.1-T3.6 |
| Error handling (stop/continue) | T4.1-T4.7 |
| 14 validation rules | T1.3-T1.11 |
| Cron scheduling (session + OS) | T6.1-T6.7 |
| Notion execution logging | T7.1-T7.8 |
| 6 commands functional | T8.1-T8.9 |
| Dry run mode | T2.5 |
| Resume from failure | T4.6-T4.7 |
| Graceful degradation | T7.4, T8.2 |
