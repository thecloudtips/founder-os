# Blocker Detection Algorithm

Detect blockers by scanning goal and milestone data against four independent detection rules. Run all four checks for every goal. Report ALL blockers found per goal — never suppress a lower-severity blocker because a higher one exists.

---

## Blocker Types

### 1. `milestone_blocked` (Severity: high)

Query the Milestones DB for all records matching:
- **Status** = "In Progress"
- **Due Date** < today (ISO 8601 date comparison, strip time component)

For each matching milestone, extract:
- The parent goal name from the Goal relation property.
- The milestone name from the Title property.
- The milestone due date.
- Calculate `days_overdue` as the difference in calendar days between today and the due date.

Generate one blocker flag per overdue in-progress milestone. Use this detail format:

```
Milestone "[milestone_name]" was due [YYYY-MM-DD] ([days_overdue] days ago) and remains In Progress.
```

Do not flag milestones with Status = "Completed" or "Not Started". Only flag milestones actively being worked on that have passed their due date.

### 2. `stale_progress` (Severity: medium)

For each goal, determine the most recent activity date by checking two sources:
1. The latest Progress Snapshot `Snapshot Date` for that goal.
2. The most recent milestone `Completed At` date for that goal.

Take the later of these two dates as `last_activity_date`. If neither exists (no snapshots and no completed milestones), use the goal's `Created At` date as `last_activity_date`.

Calculate `stale_days` as the difference in calendar days between today and `last_activity_date`.

Flag the goal when `stale_days >= 14`. Use this detail format:

```
No progress recorded for [stale_days] days (last activity: [YYYY-MM-DD]).
```

Exclude goals with Status = "Completed" or "Abandoned" from stale detection. Only active goals qualify.

**Severity escalation:** When `stale_days >= 30`, upgrade severity from `medium` to `high`. Set the severity field to `high` in the output. Append " (escalated: stale > 30 days)" to the detail string.

### 3. `deadline_overrun` (Severity: critical)

For each goal with a Target Date, check:
- **Target Date** < today
- **Progress** < 100

Calculate `days_overdue` as the difference in calendar days between today and the Target Date.

Use this detail format:

```
Goal is [days_overdue] days past target date ([YYYY-MM-DD]) at [progress]% completion.
```

Do not flag goals without a Target Date — they cannot overrun. Do not flag goals at 100% progress even if the Target Date has passed (they finished, even if late).

### 4. `velocity_collapse` (Severity: high)

Calculate two velocity values from Progress Snapshots:

**7-day velocity:** Query snapshots from the last 7 days. Compute the progress delta (latest snapshot progress minus earliest snapshot progress in the window). Divide by the number of days between those two snapshots. If fewer than 2 snapshots exist in the 7-day window, set 7-day velocity to 0.

**30-day velocity:** Query snapshots from the last 30 days. Compute the progress delta (latest minus earliest). Divide by the number of days between those two snapshots. If fewer than 2 snapshots exist in the 30-day window, skip this blocker type entirely for this goal — insufficient data.

Calculate `velocity_ratio` as `7d_velocity / 30d_velocity`. Flag the goal when `velocity_ratio < 0.50` (7-day velocity is less than 50% of the 30-day velocity).

Use this detail format:

```
7-day velocity ([7d_vel]/day) is [ratio]% of 30-day velocity ([30d_vel]/day). Progress is slowing.
```

Round velocity values to 1 decimal place. Express the ratio as a percentage rounded to the nearest integer.

**Severity escalation:** Determine how many consecutive days the velocity ratio has remained below 0.50 by checking historical snapshots. When the collapse has persisted for 21 or more days, upgrade severity from `high` to `critical`. Append " (escalated: velocity collapse > 21 days)" to the detail string.

---

## Output Schema

Emit one object per detected blocker with these fields:

| Field | Type | Description |
|:---|:---|:---|
| `blocker_type` | string | One of: `milestone_blocked`, `stale_progress`, `deadline_overrun`, `velocity_collapse` |
| `severity` | string | One of: `critical`, `high`, `medium` (after any escalation) |
| `goal_name` | string | The goal's Title property, verbatim |
| `detail` | string | Human-readable explanation following the format strings above |
| `detected_at` | string | ISO 8601 timestamp of when detection ran (e.g., `2026-03-07T09:30:00Z`) |

---

## Sorting

Sort the final blocker list by two keys:

1. **Severity** (descending priority): `critical` first, then `high`, then `medium`.
2. **Within same severity**, sort by the primary metric descending:
   - `deadline_overrun`: sort by `days_overdue` descending (most overdue first).
   - `milestone_blocked`: sort by `days_overdue` descending.
   - `velocity_collapse`: sort by `velocity_ratio` ascending (worst ratio first).
   - `stale_progress`: sort by `stale_days` descending (most stale first).

When two blockers share the same severity and the same blocker type, apply the metric sort. When two blockers share the same severity but differ in type, sort by type in this order: `deadline_overrun`, `velocity_collapse`, `milestone_blocked`, `stale_progress`.

---

## Multi-Blocker Interaction

A single goal can trigger multiple blocker types simultaneously. Report every blocker independently. Do not deduplicate or suppress. For example, a goal may have both a `deadline_overrun` (critical) and a `stale_progress` (medium) — emit both.

When presenting blockers in a dashboard or report, group by goal name for readability but preserve the severity sort order across goals. The most critical blocker across all goals appears first in the flat list.

---

## Edge Cases

- **New goals** (created < 14 days ago with no snapshots): Do not flag as stale. The 14-day clock starts from `Created At`.
- **Goals at 100% progress**: Exclude from all blocker checks. Completed goals have no blockers.
- **Goals with Status "Abandoned"**: Exclude from all blocker checks.
- **Milestones without a Due Date**: Skip from `milestone_blocked` detection. Only milestones with explicit due dates can be overdue.
- **Zero 30-day velocity**: If the 30-day velocity is exactly 0 and the 7-day velocity is also 0, do not flag `velocity_collapse` (no motion to collapse from). If the 30-day velocity is 0 but the 7-day velocity is positive, do not flag (progress is resuming).
