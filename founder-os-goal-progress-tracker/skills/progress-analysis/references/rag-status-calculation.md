# RAG Status Calculation

This reference defines the complete algorithm for calculating Red/Amber(Yellow)/Green status for a goal based on its actual progress versus expected progress over time. Evaluate RAG status on every `/goal:report`, `/goal:update`, and `/goal:list` invocation.

## Prerequisites

RAG calculation requires two date values and a progress value:

- **Start Date**: The date the goal transitioned to "In Progress". Fall back to Created At if Start Date is not set (e.g., goal was created but the auto-start trigger has not yet fired).
- **Target Date**: The user-defined deadline for the goal. If no Target Date exists, skip RAG calculation entirely.
- **Actual Progress**: The current progress percentage (integer 0-100) from the milestone progress formula.

When no Target Date is set, display "No deadline" in place of the RAG indicator. Do not assign Green, Yellow, or Red. Do not compute expected progress. Omit the RAG section from reports.

## Expected Progress Formula

Calculate the progress that should have been achieved by today, assuming linear progress from start to target:

```
total_duration = target_date - start_date  (in calendar days)
elapsed = today - start_date  (in calendar days)
expected_progress = (elapsed / total_duration) * 100
```

### Clamping

Clamp `expected_progress` to the range 0-100:

- If `elapsed <= 0` (today is before or on the start date), set `expected_progress = 0`.
- If `elapsed >= total_duration` (today is on or past the target date), set `expected_progress = 100`.

Do not allow expected progress to exceed 100 or drop below 0.

### Date Resolution

Use calendar days for all date arithmetic. Count partial days as full days (use date-only comparison, not datetime). When Start Date is absent and Created At is used as fallback, log a note: "Using Created At as Start Date proxy."

## Gap Calculation

Compute the difference between actual and expected progress:

```
gap = actual_progress - expected_progress
```

A positive gap means the goal is ahead of schedule. A negative gap means the goal is behind schedule. A gap of zero means the goal is exactly on track.

## Tier Thresholds

Classify the goal into one of three RAG tiers based on the gap value:

| RAG Status | Condition | Meaning |
|------------|-----------|---------|
| **Green** | gap >= -10 | On track or ahead. Progress is within 10 percentage points of expected. |
| **Yellow** | -25 <= gap < -10 | At risk. Progress is 10-25 percentage points behind expected. Needs attention. |
| **Red** | gap < -25 OR past deadline | Off track. Progress is more than 25 percentage points behind, or the deadline has passed. Immediate action required. |

### Threshold Boundaries

Apply thresholds with these exact comparisons:

- Green: `gap >= -10`
- Yellow: `gap >= -25 AND gap < -10`
- Red: `gap < -25`

A gap of exactly -10 is Green. A gap of exactly -25 is Yellow. These boundaries are inclusive on the less-severe side.

## Override Rules

### Past Deadline Override

When today's date is strictly after the Target Date and actual progress is less than 100%, set RAG to **Red** regardless of the gap value. This override takes precedence over all other calculations.

Apply this override even when the gap would otherwise yield Green or Yellow (e.g., a goal at 95% progress one day past deadline is still Red).

When today equals the Target Date, do not trigger the override — the user still has the remainder of the day. Trigger only when `today > target_date`.

### Completed Goal Override

When actual progress equals 100% and the goal status is "Completed", set RAG to **Green** regardless of dates. A completed goal is always Green, even if it was completed after the deadline.

### On Hold Neutralization

When the goal status is "On Hold", freeze the RAG at its last calculated value. Do not recalculate using today's date, as elapsed time during a hold should not penalize the goal. When the goal resumes, recalculate RAG using the adjusted elapsed time (exclude the hold period).

## Cold-Start Guard

When the goal has been active for fewer than 7 calendar days (`elapsed < 7`), do not assign a RAG status. Display "Too early" instead. The rationale: with fewer than 7 days of data, the expected progress value is too small to produce meaningful gap analysis, and minor fluctuations would cause misleading RAG swings.

When `elapsed` reaches 7, begin normal RAG calculation. Do not backfill RAG for the first 6 days.

## Worked Examples

### Example 1: On track (Green)

- Goal started 30 days ago (start_date = today - 30)
- Target date is 60 days from now (target_date = today + 60, total_duration = 90 days)
- Actual progress: 40%

Calculate:
```
elapsed = 30
total_duration = 90
expected_progress = (30 / 90) * 100 = 33.33%
gap = 40 - 33.33 = +6.67
```

Gap is >= -10. Result: **Green**. The goal is ahead of schedule by ~7 percentage points.

### Example 2: At risk (Yellow)

- Same dates as Example 1 (started 30 days ago, target 60 days away)
- Actual progress: 15%

Calculate:
```
expected_progress = 33.33%
gap = 15 - 33.33 = -18.33
```

Gap is >= -25 and < -10. Result: **Yellow**. The goal is 18 percentage points behind expected.

### Example 3: Off track (Red)

- Same dates as Example 1
- Actual progress: 5%

Calculate:
```
expected_progress = 33.33%
gap = 5 - 33.33 = -28.33
```

Gap is < -25. Result: **Red**. The goal is 28 percentage points behind expected. Immediate intervention needed.

### Example 4: Past deadline override (Red)

- Goal started 100 days ago
- Target date was 10 days ago (total_duration = 90 days, today is day 100)
- Actual progress: 80%

Calculate:
```
elapsed = 100
total_duration = 90
expected_progress = clamp((100 / 90) * 100, 0, 100) = 100%
gap = 80 - 100 = -20
```

The gap of -20 would normally be Yellow. However, today is past the Target Date and progress is less than 100%. The past deadline override applies. Result: **Red**.

### Example 5: Completed after deadline (Green)

- Same dates as Example 4 (past deadline)
- Actual progress: 100%, Status: Completed

The completed goal override applies. Result: **Green**. The goal was finished, and completion status supersedes the deadline.

### Example 6: Early in the goal (Too early)

- Goal started 3 days ago
- Target date is 60 days away
- Actual progress: 2%

Calculate:
```
elapsed = 3
```

Elapsed is less than 7. Cold-start guard applies. Result: **"Too early"**. Do not assign a RAG color.

### Example 7: No deadline

- Goal has no Target Date set
- Actual progress: 45%

No Target Date means no expected progress can be calculated. Skip RAG entirely. Display: **"No deadline"**.

## Recalculation Triggers

Evaluate RAG status under these conditions:

1. **`/goal:report`** — Always recalculate before rendering the report.
2. **`/goal:update`** — Recalculate after applying the update (progress may have changed).
3. **`/goal:list`** — Recalculate for each displayed goal to show current RAG in the list view.
4. **Milestone status change** — Any milestone change triggers a progress recalculation, which in turn triggers RAG recalculation.

Do not cache RAG status across commands. Always compute it fresh from current data to ensure the display reflects reality.

## Output Format

Present RAG status in reports and list views using this format:

```
RAG Status: [Green|Yellow|Red|Too early|No deadline]
Expected Progress: N% (based on timeline)
Actual Progress: N%
Gap: [+/-]N percentage points [ahead/behind]
```

Omit the Expected Progress and Gap lines when RAG is "Too early" or "No deadline". When RAG is Red due to the past deadline override, append: "Deadline passed on YYYY-MM-DD."
