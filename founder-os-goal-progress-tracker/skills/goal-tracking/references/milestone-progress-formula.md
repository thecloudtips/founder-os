# Milestone Progress Formula

This reference defines the complete algorithm for calculating goal progress from milestone statuses. Apply this formula whenever a milestone status changes, when the user runs `/goal:update`, or when `/goal:report` generates output.

## Core Formula

```
progress = (completed_count + in_progress_count * 0.5) / total_active * 100
```

## Variable Definitions

### completed_count

Count every milestone whose Status equals "Done". Include only milestones belonging to the current goal. Do not count milestones marked "Skipped" as completed.

**Example:** A goal has 6 milestones. Three have Status = "Done". Set `completed_count = 3`.

### in_progress_count

Count every milestone whose Status equals "In Progress". This includes milestones actively being worked on but not yet finished.

**Example:** Of the remaining 3 milestones above, one has Status = "In Progress". Set `in_progress_count = 1`.

### total_active

Count all milestones that are NOT "Skipped". Sum milestones with Status in {"Not Started", "In Progress", "Done"}. Exclude "Skipped" milestones entirely from the denominator.

**Example:** The goal has 6 milestones total. One is "Skipped". Set `total_active = 5`.

### Partial Credit Rationale

Assign In Progress milestones a weight of 0.5. This prevents a common perception problem: without partial credit, a goal with 0 completed milestones but 3 actively in progress would show 0% — giving the misleading impression of no progress. The 0.5 weight acknowledges that work has begun without overstating completion.

## Division by Zero Guard

When `total_active = 0` (all milestones are "Skipped" or the goal has no milestones), return `progress = 0` and set a `stale` flag on the goal. Do not divide by zero. Do not throw an error. Log a warning: "All milestones skipped or absent — progress set to 0%."

When a goal has no milestones defined at all, treat it the same way: return 0 and flag as stale.

## Rounding and Clamping

Round the result to the nearest integer using standard rounding (0.5 rounds up). After rounding, clamp the value to the range 0-100 inclusive. Never return a negative progress value. Never return a value above 100.

```
progress = clamp(round(raw_progress), 0, 100)
```

## Progress Snapshots

After every recalculation, append a snapshot entry to the goal's Progress Snapshots field (rich_text, JSON array). Each entry follows this schema:

```json
{"date": "YYYY-MM-DD", "progress": N}
```

Where `N` is the clamped integer progress value. Use today's date in ISO 8601 format. If a snapshot already exists for today's date, overwrite it rather than appending a duplicate. Maintain chronological order in the array.

The Progress Snapshots field provides the data source for velocity calculations (see `velocity-projection.md`). Never delete or modify historical snapshot entries — only overwrite today's entry if it already exists.

## Worked Examples

### Example 1: Mixed statuses with a skip

A goal has 5 milestones:
- Milestone A: Done
- Milestone B: Done
- Milestone C: In Progress
- Milestone D: Not Started
- Milestone E: Skipped

Calculate:
- `completed_count = 2` (A, B)
- `in_progress_count = 1` (C)
- `total_active = 4` (A, B, C, D — exclude E)
- `raw_progress = (2 + 1 * 0.5) / 4 * 100 = 2.5 / 4 * 100 = 62.5`
- `progress = round(62.5) = 63`

Result: **63%**

### Example 2: All milestones complete

A goal has 3 milestones:
- Milestone A: Done
- Milestone B: Done
- Milestone C: Done

Calculate:
- `completed_count = 3`
- `in_progress_count = 0`
- `total_active = 3`
- `raw_progress = (3 + 0) / 3 * 100 = 100.0`
- `progress = 100`

Result: **100%**

### Example 3: Single milestone in progress

A goal has 1 milestone:
- Milestone A: In Progress

Calculate:
- `completed_count = 0`
- `in_progress_count = 1`
- `total_active = 1`
- `raw_progress = (0 + 1 * 0.5) / 1 * 100 = 50.0`
- `progress = 50`

Result: **50%**

### Example 4: All milestones skipped

A goal has 3 milestones:
- Milestone A: Skipped
- Milestone B: Skipped
- Milestone C: Skipped

Calculate:
- `completed_count = 0`
- `in_progress_count = 0`
- `total_active = 0`
- Division by zero guard triggers.
- Set `stale = true` on the goal.

Result: **0%**, flagged as stale.

### Example 5: Large goal with mixed progress

A goal has 10 milestones:
- 4 Done, 3 In Progress, 2 Not Started, 1 Skipped

Calculate:
- `completed_count = 4`
- `in_progress_count = 3`
- `total_active = 9` (exclude 1 Skipped)
- `raw_progress = (4 + 3 * 0.5) / 9 * 100 = 5.5 / 9 * 100 = 61.11`
- `progress = round(61.11) = 61`

Result: **61%**

## When to Recalculate

Trigger a full recalculation under these conditions:

1. **Milestone status change** — Any milestone transitions between Not Started, In Progress, Done, or Skipped.
2. **`/goal:update` command** — User explicitly updates a goal. Recalculate even if no milestone changed (the user may have added or removed milestones).
3. **`/goal:report` command** — Recalculate before generating any report to ensure the displayed value reflects current state.
4. **Milestone added or removed** — Adding a new milestone or deleting an existing one changes `total_active`.

Do not recalculate on read-only operations like `/goal:list` or `/goal:search`. Use the cached progress value for those commands.
