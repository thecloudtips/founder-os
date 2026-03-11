# Velocity Projection Algorithm

This reference defines the complete algorithm for calculating goal velocity and projecting completion dates. Use this algorithm when generating reports, evaluating goal health, or answering "when will this goal finish?" queries.

## Source Selection Priority

Select the velocity data source in this order. Use the first source that meets its minimum data requirements:

1. **Milestone velocity** — Prefer this when the goal has 2 or more completed milestones and at least 7 days have elapsed since the first completion. Milestone completions are discrete, observable events that provide reliable velocity signals.

2. **Snapshot velocity** — Use this when milestone velocity data is insufficient but the Progress Snapshots field contains 2 or more entries spanning at least 7 days. Snapshot data is continuous and captures progress updates that may not correspond to milestone completions.

3. **No data** — When neither source meets its minimum requirements, do not project. Return the message: "Insufficient data for projection. Need 7+ days of history or 2+ milestone completions."

## Milestone Velocity Formula

Calculate the rate of milestone completion expressed as progress percentage per day:

```
velocity_progress_per_day = (completed_milestones / total_milestones) * 100 / days_since_first_completion
```

### Variable Definitions

- **completed_milestones**: Count of milestones with Status = "Done". Do not include "Skipped" milestones.
- **total_milestones**: Count of all active milestones (non-Skipped). Use the same `total_active` value from the progress formula.
- **days_since_first_completion**: Number of calendar days between the earliest milestone completion date and today. Use `ceil` to ensure a minimum of 1 day.

### Example

A goal has 8 active milestones. 3 are Done. The first milestone was completed 21 days ago.

```
velocity = (3 / 8) * 100 / 21 = 37.5 / 21 = 1.786 progress_pct/day
```

## Snapshot Velocity Formula

Calculate velocity from the Progress Snapshots array when milestone data is insufficient:

```
velocity_progress_per_day = (latest_progress - earliest_progress) / days_between
```

### Variable Definitions

- **latest_progress**: The progress value from the most recent snapshot entry.
- **earliest_progress**: The progress value from the oldest snapshot entry within the selected window.
- **days_between**: Calendar days between the earliest and latest snapshot dates. Use `ceil` to ensure a minimum of 1 day.

## Multi-Window Calculation

Calculate velocity across multiple time windows to weight recent activity more heavily than older trends. This prevents a single burst or stall from dominating the projection.

### Window Definitions

| Window | Lookback | Weight |
|--------|----------|--------|
| 7-day  | Last 7 calendar days | 0.50 |
| 14-day | Last 14 calendar days | 0.30 |
| 30-day | Last 30 calendar days | 0.20 |

### Calculation Steps

1. For each window (7d, 14d, 30d), filter the data points (milestones or snapshots) that fall within the window.
2. Calculate velocity for that window using the appropriate formula (milestone or snapshot).
3. Compute the weighted average:

```
weighted_velocity = velocity_7d * 0.50 + velocity_14d * 0.30 + velocity_30d * 0.20
```

### Sparse Data Re-normalization

When the goal has fewer days of history than a window requires, skip that window and redistribute its weight proportionally across the remaining windows.

**Rule:** If a window has fewer than 2 data points, exclude it and re-normalize.

**Example — 10 days of data:**
- 7d window: valid (has data points) — include.
- 14d window: valid (10 days of data fits within 14d) — include.
- 30d window: only 10 days of history, same data as 14d — exclude.
- Re-normalize: 7d weight = 0.50 / (0.50 + 0.30) = 0.625, 14d weight = 0.30 / (0.50 + 0.30) = 0.375.

```
weighted_velocity = velocity_7d * 0.625 + velocity_14d * 0.375
```

**Example — 5 days of data:**
- 7d window: valid — include.
- 14d window: same data as 7d — exclude (fewer than 2 distinct window data sets).
- 30d window: exclude.
- Use 7d velocity alone with weight 1.0.

When only one window has valid data, use that window's velocity directly without weighting.

## Projection Formula

Calculate the estimated completion date from the weighted velocity:

```
remaining_progress = 100 - current_progress
days_to_completion = ceil(remaining_progress / weighted_velocity)
projected_date = today + days_to_completion
```

Format the projected date as YYYY-MM-DD. Display it alongside the current Target Date (if set) so the user can compare expected vs. actual trajectory.

When a Target Date exists, also compute the delta:

```
delta_days = projected_date - target_date
```

- Positive delta: projected to finish late by N days.
- Negative delta: projected to finish early by N days.
- Zero: projected to finish on target.

## Cold-Start Guard

Do not generate a projection unless at least one of these conditions is met:

- The goal has 7 or more days of history (days since Start Date or first snapshot).
- The goal has 2 or more milestones with Status = "Done".

When neither condition is met, return: "Insufficient data for projection. Need 7+ days of history or 2+ milestone completions." Do not display a projected date. Do not include velocity metrics in reports.

This guard prevents wildly inaccurate projections from a single data point (e.g., one milestone completed on Day 1 projecting completion by Day 3).

## Edge Cases

### Velocity equals zero

When `weighted_velocity = 0` (no progress over the measurement period), do not divide by zero. Return the label **"Stalled"**. Display the message: "No progress recorded in the last N days. Goal is stalled."

Set the goal's velocity status to "Stalled" for use in reports and RAG calculations.

### Negative velocity

When `weighted_velocity < 0` (progress has decreased, e.g., milestones moved from Done back to In Progress), return the label **"Regressing"**. Display the message: "Progress has decreased over the last N days. Review milestone statuses."

Do not project a completion date for regressing goals. Negative velocity implies the goal is moving away from completion.

### Very high velocity

When the projection formula produces `projected_date <= today` (velocity so high that remaining progress would be completed in less than one day), cap the projected date to today. Display: "On track to complete today based on current velocity." Do not project dates in the past.

### Goal already complete

When `current_progress = 100`, do not run the projection. Return: "Goal is complete. No projection needed." Display the actual Completed Date instead.

### Single data point

When only one snapshot or one milestone completion exists and fewer than 7 days have elapsed, the cold-start guard blocks projection. If exactly 7 days have elapsed with one data point, use that single data point to calculate velocity. Treat the Start Date (with progress = 0) as the implicit first data point when no earlier snapshot exists.

## Output Format

Present velocity projections in this structure:

```
Velocity: N.N% per day (based on [7d/14d/30d weighted] data)
Current Progress: N%
Projected Completion: YYYY-MM-DD
Target Date: YYYY-MM-DD
Delta: +/- N days [early/late]
```

Omit the Delta line when no Target Date is set. Omit the Projected Completion line when velocity is zero, negative, or cold-start guard is active. Replace with the appropriate status label (Stalled, Regressing, Insufficient data).
