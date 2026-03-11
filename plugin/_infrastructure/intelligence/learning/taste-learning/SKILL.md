---
name: taste-learning
description: Tier 1 learning — detects user output preferences from repeated corrections and injects them as instructions into future plugin runs.
---

## Overview

Taste learning detects patterns in how users modify or react to plugin outputs, then automatically adjusts future outputs to match preferences.

## Detection Mechanism

1. **Post-command observation**: After a command runs, the post_command event records the output
2. **User correction detection**: If the user edits, rejects, or re-runs the command with different parameters, record a decision_point event noting the change
3. **Pattern matching**: When the same type of correction is observed 3+ times for the same plugin/command, create a candidate pattern
4. **Distillation**: Convert the repeated correction into an instruction (e.g., "user shortened drafts 4/5 times" → "Keep email drafts concise, under 150 words")

## What Taste Learning Captures

| Signal | Example | Resulting Pattern |
|---|---|---|
| Output length corrections | User consistently shortens briefings | "Keep briefings under 500 words" |
| Tone adjustments | User rewrites drafts to be more formal | "Use formal business tone in email drafts" |
| Prioritization overrides | User re-orders urgent items | "Prioritize revenue-related items first" |
| Formatting preferences | User restructures output into bullets | "Use bullet-point format for task summaries" |
| Content inclusion/exclusion | User removes calendar section from briefing | "Exclude calendar items from daily briefing" |

## Creating a Taste Pattern

When distilling a pattern from observations:

1. Query recent decision_point events for this plugin/command
2. Group by similar correction types
3. If a correction type appears 3+ times with consistent direction:
   - Create a new row in the `patterns` table
   - `pattern_type`: "taste"
   - `plugin`: the specific plugin
   - `command`: the specific command (or null if applies to all commands)
   - `description`: human-readable summary of the preference
   - `instruction`: the text to inject into future command context
   - `confidence`: 0.0 (starts as candidate)
   - `observations`: count of times this pattern was seen
4. Subsequent observations update `observations`, `confirmations`, `rejections`, and recalculate `confidence`

## Confirmation vs Rejection

- **Confirmation**: User runs the command, pattern is applied, user accepts the output without changes
- **Rejection**: User runs the command, pattern is applied, user undoes/overrides the pattern's effect
- Track via post_command events: if outcome is "success" and no subsequent correction → confirmation
- If user re-runs or explicitly corrects → rejection

## Notification

Always notify the user when a taste pattern is applied:
```
[Intel] Applying learned preference: "concise email drafts under 150 words"
```

If the user says "stop applying this" or rejects 3 times in a row, set status to "rejected".
