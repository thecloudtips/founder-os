# Workflow Validation Rules Reference

## Overview

Apply these 14 validation rules before executing any workflow. Run all rules and report all violations at once (do not stop at the first error). Each rule has a code, severity, message template, and suggested fix.

## Rules

### Rule 1: V001 -- Steps Array Required

- **Severity**: Error
- **Check**: steps array exists and is not empty
- **Message**: "Workflow must contain at least one step"
- **Fix**: Add at least one step to the steps array

### Rule 2: V002 -- Unique Step IDs

- **Severity**: Error
- **Check**: All step IDs are unique within the workflow
- **Message**: "Duplicate step ID: '{id}'. Each step must have a unique ID."
- **Fix**: Rename the duplicate step ID

### Rule 3: V003 -- Valid depends_on References

- **Severity**: Error
- **Check**: Every ID in every step's depends_on array exists as a step ID in the workflow
- **Message**: "Step '{id}' depends on unknown step '{dep_id}'"
- **Fix**: Correct the depends_on reference or add the missing step

### Rule 4: V004 -- No Circular Dependencies

- **Severity**: Error
- **Check**: The dependency graph forms a valid DAG (no cycles)
- **Message**: "Circular dependency detected among steps: [{cycle_ids}]"
- **Fix**: Remove one dependency to break the cycle

### Rule 5: V005 -- Maximum Step Count

- **Severity**: Error
- **Check**: steps array contains 25 or fewer steps
- **Message**: "Workflow has {count} steps (maximum 25). Split into smaller workflows."
- **Fix**: Break the workflow into multiple smaller workflows

### Rule 6: V006 -- Command Format

- **Severity**: Error
- **Check**: Each step's command field starts with "/"
- **Message**: "Step '{id}' command '{cmd}' must start with '/'"
- **Fix**: Prefix the command with "/"

### Rule 7: V007 -- Args Values Type

- **Severity**: Error
- **Check**: All values in args map are strings (no nested objects, arrays, numbers, or booleans)
- **Message**: "Step '{id}' arg '{key}' must be a string value"
- **Fix**: Convert the value to a string

### Rule 8: V008 -- Cron Expression Format

- **Severity**: Error
- **Check**: When schedule.enabled=true, cron field has exactly 5 space-separated fields
- **Message**: "Invalid cron expression: expected 5 fields, got {count}"
- **Fix**: Use standard 5-field cron format (minute hour day month weekday)

### Rule 9: V009 -- Unique output_as Keys

- **Severity**: Error
- **Check**: All output_as values across all steps are unique
- **Message**: "Duplicate output_as key: '{key}'. Each output key must be unique."
- **Fix**: Rename the duplicate output_as key

### Rule 10: V010 -- Semver Version Format

- **Severity**: Warning
- **Check**: version field follows MAJOR.MINOR.PATCH format
- **Message**: "Version '{version}' does not follow semantic versioning"
- **Fix**: Use format like "1.0.0"

### Rule 11: V011 -- No Self-Dependencies

- **Severity**: Error
- **Check**: No step lists its own ID in depends_on
- **Message**: "Step '{id}' depends on itself"
- **Fix**: Remove the self-reference from depends_on

### Rule 12: V012 -- Timeout Range

- **Severity**: Warning
- **Check**: timeout_seconds is between 10 and 3600 (both defaults and per-step)
- **Message**: "Timeout {value}s is outside recommended range (10-3600)"
- **Fix**: Set timeout between 10 and 3600 seconds

### Rule 13: V013 -- Reserved Context Keys

- **Severity**: Error
- **Check**: No step uses a reserved key (workflow_name, workflow_version, run_id, run_timestamp) as output_as
- **Message**: "Step '{id}' uses reserved context key '{key}' as output_as"
- **Fix**: Choose a different output_as key name

### Rule 14: V014 -- Workflow Name Format

- **Severity**: Warning
- **Check**: workflow.name uses kebab-case (lowercase letters, numbers, and hyphens only)
- **Message**: "Workflow name '{name}' should use kebab-case format"
- **Fix**: Rename using lowercase letters, numbers, and hyphens only

## Severity Levels

- **Error**: Blocks execution. Must fix before running.
- **Warning**: Allows execution. Recommend fixing.

## Validation Output Format

```
Validation Results for: workflow-name
---
x V002 Error: Duplicate step ID: 'fetch-data'. Each step must have a unique ID.
x V004 Error: Circular dependency detected among steps: [process, transform, process]
! V010 Warning: Version '1.0' does not follow semantic versioning
---
Result: FAILED (2 errors, 1 warning)
```

When all rules pass:

```
Validation Results for: workflow-name
---
* All 14 validation rules passed
---
Result: PASSED
```
