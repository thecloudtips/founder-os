---
description: Configure hourly rate and custom time estimates for savings calculations
argument-hint: "[--rate=N] [--reset]"
allowed-tools: ["Read", "Write"]
---

# Configure Savings Calculator

Set up or update the hourly rate and custom time estimates used by all savings commands. Configuration is stored in `${CLAUDE_PLUGIN_ROOT}/config/user-config.json`.

## Load Skills

Read the roi-calculation skill at `${CLAUDE_PLUGIN_ROOT}/skills/savings/roi-calculation/SKILL.md` for the configuration resolution priority order and user config schema.

## Parse Arguments

Extract from `$ARGUMENTS`:

- `--rate=N` (optional) -- Set hourly rate directly without interactive prompt. N must be a positive number.
- `--reset` (optional) -- Reset all custom overrides back to defaults. Keeps hourly rate.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Workflow

### Step 1: Load Current Configuration

1. Read `${CLAUDE_PLUGIN_ROOT}/config/user-config.json` if it exists.
2. Read `${CLAUDE_PLUGIN_ROOT}/config/task-estimates.json` for default values.
3. Display current configuration:

```
## Current Configuration

**Hourly Rate**: $[rate]/hr (or "Not set — using default $150/hr")
**Currency**: [currency]
**Custom Overrides**: [N categories customized] (or "None")
**Last Updated**: [date] (or "Never")
```

### Step 2: Handle --reset Flag

If `--reset` is provided:
1. Remove the `overrides` object from user-config.json (keep hourly_rate and currency).
2. Confirm: "Reset N custom overrides to defaults. Hourly rate unchanged at $[rate]/hr."
3. Stop here.

### Step 3: Set Hourly Rate

If `--rate=N` was provided:
- Validate N is a positive number.
- Set hourly_rate to N.
- Skip the interactive prompt.

If `--rate` was NOT provided:
- Use AskUserQuestion: "What is your hourly rate? (Current: $[rate]/hr, enter to keep, 0 to disable dollar calculations)"
- Parse the response. Accept numbers, "0" (disables dollar calc), or empty (keep current).

### Step 4: Offer Category Customization

Use AskUserQuestion: "Would you like to customize time estimates for any categories? (y/n)"

If yes:
1. Display current estimates table:
   | Category | Manual (min) | AI (min) | Savings | Source |
   |----------|-------------|----------|---------|--------|
   List all 24 categories with current values. Mark overridden ones with "(custom)".

2. Use AskUserQuestion: "Enter category key to customize (e.g., 'email_triage'), or 'done' to finish:"

3. For each category the user wants to customize:
   - Ask for manual_minutes (must be > 0)
   - Ask for ai_minutes (must be > 0, must be < manual_minutes)
   - Validate: manual_minutes > ai_minutes
   - If validation fails, explain and re-ask
   - Add to overrides object

4. Repeat until user says "done".

### Step 5: Save Configuration

Write `${CLAUDE_PLUGIN_ROOT}/config/user-config.json`:

```json
{
  "hourly_rate": [number],
  "currency": "USD",
  "configured_at": "[ISO date]",
  "overrides": {
    "category_key": {
      "manual_minutes": [number],
      "ai_minutes": [number]
    }
  }
}
```

### Present Summary

Display:
```
## Configuration Updated

**Hourly Rate**: $[rate]/hr
**Currency**: [currency]
**Custom Overrides**: [N categories]
**Saved**: config/user-config.json

Run `/founder-os:savings:quick` to see your updated calculations.
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Graceful Degradation

- If user-config.json doesn't exist yet, create it fresh.
- If task-estimates.json is missing, report error: "Default task estimates not found. Plugin may be corrupted."
- If user enters invalid data, explain the validation rule and re-ask (never save invalid config).

## Usage Examples

```
/founder-os:savings:configure
/founder-os:savings:configure --rate=200
/founder-os:savings:configure --reset
```
