---
name: Progress Analysis
description: "Analyzes goal health with RAG scoring, velocity tracking, and projected completion dates. Activates when the user wants to check goal progress, see a health dashboard, check velocity, or asks 'am I on track for [goal]?' Covers blocker detection, trend analysis, and milestone completion forecasting."
globs:
  - "commands/goal-update.md"
  - "commands/goal-check.md"
  - "commands/goal-report.md"
---

# Progress Analysis

Health analysis engine for goals. Compute RAG status, velocity projections, and blocker detection to determine whether goals are on-track, at-risk, or behind. Used by: `/goal:check`, `/goal:report`, `/goal:update`.

## Purpose and Context

Provide a structured health assessment for every tracked goal. Combine time-based expected progress with actual progress data to classify goals into Red/Amber/Green tiers. Layer velocity projections on top to forecast completion dates. Detect blockers automatically from milestone stalls, progress plateaus, deadline overruns, and velocity collapses. All analysis operates against goal data stored in the Notion database and outputs health scores, projections, and blocker flags consumed by commands and reports.

---

## RAG Status Classification

Classify each goal into a health tier by comparing actual progress against time-based expected progress. Calculate the gap between the two values and map to a RAG tier.

### Core Calculation

1. Calculate `expected_progress`:

   ```
   expected_progress = (days_elapsed / total_duration) * 100
   ```

   Where `days_elapsed = today - start_date` and `total_duration = target_date - start_date`.

2. Calculate `gap`:

   ```
   gap = actual_progress - expected_progress
   ```

3. Map the gap to a RAG tier.

### RAG Tier Table

| Tier | Condition | Interpretation |
|------|-----------|----------------|
| Green | gap >= -10 | On track or ahead of schedule. No intervention needed. |
| Yellow | -25 <= gap < -10 | At risk. Falling behind expected pace. Review and adjust. |
| Red | gap < -25 | Behind schedule. Significant intervention required. |
| Red | Target Date < today AND progress < 100 | Past deadline with incomplete work. Automatically Red regardless of gap. |
| Not Started | Status = "Not Started" | No RAG calculated. Display as "Not Started" without a color tier. |
| Too Early | Goal age < 7 days | Suppress RAG to avoid misleading Red on brand-new goals. Display "Too early" instead. |

### Cold-Start Guard

Do not calculate RAG for goals younger than 7 days. Early data points produce volatile scores that mislead more than inform. Display "Too early" as the RAG status and omit the goal from aggregate health summaries until the 7-day threshold is met.

For the full RAG algorithm including cold-start edge cases, clamping logic, and status override rules, read `${CLAUDE_PLUGIN_ROOT}/skills/progress-analysis/references/rag-status-calculation.md`.

---

## Expected Progress Formula

Calculate expected progress as a linear interpolation between start and target dates.

```
expected_progress = ((today - start_date) / (target_date - start_date)) * 100
```

### Date Resolution Rules

- Use `Start Date` property when available.
- Fall back to `Created At` timestamp when no explicit start date exists.
- If no `Target Date` exists, skip RAG calculation entirely. Display "No deadline" in place of the RAG tier.
- Clamp the result to the 0-100 range. Never return negative expected progress or values above 100.

### Clamping Examples

| Scenario | Raw Value | Clamped Value |
|----------|-----------|---------------|
| Goal not yet started (start_date is in the future) | -15 | 0 |
| Goal past its deadline | 120 | 100 |
| Normal in-progress goal | 45 | 45 |

---

## Velocity Projection

Project a completion date based on the rate of progress over recent time windows. Use multi-window averaging with a recency bias to smooth out short-term fluctuations while staying responsive to recent changes.

### Velocity Source Selection Rule

Select the velocity data source in priority order:

1. **Milestone velocity** — Use when `Milestone Count > 0` AND at least 1 milestone has been completed. Calculate as milestones completed per week, then convert to progress-per-day using `(milestones_completed / milestone_count) * 100 / days_elapsed`.
2. **Progress Snapshots velocity** — Fall back to this when no milestones exist or none are completed. Calculate as progress delta per week from the JSON array stored in the Progress Snapshots property.
3. **No velocity data** — When neither source is available (no milestones, no snapshots), mark the goal as "No velocity data" and skip projection entirely.

### Multi-Window Averaging

Calculate velocity independently across three time windows to balance responsiveness with stability:

| Window | Lookback Period | Weight |
|--------|----------------|--------|
| Short | 7 days | 0.5 |
| Medium | 14 days | 0.3 |
| Long | 30 days | 0.2 |

Compute the weighted average:

```
weighted_velocity = (velocity_7d * 0.5) + (velocity_14d * 0.3) + (velocity_30d * 0.2)
```

This gives recent activity 50% influence while maintaining a stabilizing baseline from longer trends. When fewer than 14 days of data exist, use only the available windows and re-normalize weights to sum to 1.0. When fewer than 7 days of data exist, defer to the cold-start guard.

### Projected Completion Date

Calculate the projected completion date from the weighted velocity:

```
remaining_progress = 100 - actual_progress
days_to_complete = remaining_progress / weighted_velocity_per_day
projected_completion = today + days_to_complete
```

Round `days_to_complete` up to the nearest whole day.

### Cold-Start Guard

Require a minimum of 7 days of data OR 2 or more milestones completed before producing a projection. When the threshold is not met, display "Insufficient data" in place of a projected date. This prevents wildly inaccurate projections from a single early data point.

### Velocity Edge Cases

- **Velocity = 0**: Display "Stalled" instead of calculating an infinite projected date. Flag as a blocker (see Blocker Detection below).
- **Negative velocity** (progress decreased): Display "Regressing" and flag as a critical blocker. Do not project a completion date from negative velocity.
- **Velocity exceeding remaining work**: Cap projected completion at today (goal is effectively complete or will be within the day).

For full velocity formulas, window calculation details, and milestone-to-progress conversion math, read `${CLAUDE_PLUGIN_ROOT}/skills/progress-analysis/references/velocity-projection.md`.

---

## Blocker Detection

Detect blockers automatically from goal data signals. Each blocker type has a defined detection condition and severity level. Scan every goal for all four blocker types on each analysis run.

### Blocker Type Table

| Blocker Type | Detection Condition | Severity | Interpretation |
|--------------|-------------------|----------|----------------|
| `milestone_blocked` | Any milestone with Status = "In Progress" AND Due Date < today | high | An active milestone has blown past its deadline. The goal cannot advance until this milestone is unblocked. |
| `stale_progress` | No progress change in 14+ days. Compare the latest Progress Snapshot timestamp or the most recent milestone completion date against today. | medium | The goal has gone dormant. No measurable forward movement in two weeks. |
| `deadline_overrun` | Target Date < today AND progress < 100 | critical | The goal has passed its deadline without reaching completion. Requires immediate attention or deadline extension. |
| `velocity_collapse` | Current 7-day velocity < 50% of 30-day velocity | high | Progress rate has dropped sharply. The goal was moving but has significantly slowed, indicating an emerging problem. |

### Blocker Output Format

Produce each detected blocker as a structured flag with these fields:

- `blocker_type`: One of the four types above.
- `severity`: critical, high, or medium.
- `goal_name`: The affected goal title.
- `detail`: A human-readable explanation of what triggered the flag (e.g., "Milestone 'Design mockups' was due 2026-02-28 but is still In Progress").
- `detected_at`: ISO 8601 timestamp of detection.

Sort blockers by severity (critical first, then high, then medium) within each goal. Across goals in a report, sort by severity first, then by staleness or overrun duration descending.

### Multiple Blockers Per Goal

A single goal may trigger multiple blocker types simultaneously. Report all detected blockers — do not suppress lower-severity flags when a higher-severity flag exists on the same goal. The combination of flags provides a richer diagnostic picture.

For the full detection logic, severity escalation rules, and output schema, read `${CLAUDE_PLUGIN_ROOT}/skills/progress-analysis/references/blocker-detection.md`.

---

## Health Score Computation

Combine RAG status, velocity, and blocker flags into a single numeric health score (0-100) for each goal. Use this score for sorting and aggregate dashboards.

### Scoring Formula

Start with a base score derived from the RAG gap:

```
base_score = clamp(50 + (gap * 2), 0, 100)
```

Apply modifiers:

| Modifier | Condition | Adjustment |
|----------|-----------|------------|
| Velocity bonus | Projected completion before Target Date | +10 |
| Velocity penalty | Projected completion after Target Date | -15 |
| Stalled penalty | Velocity = 0 for 7+ days | -20 |
| Blocker penalty (critical) | Any `deadline_overrun` blocker | -25 |
| Blocker penalty (high) | Any `milestone_blocked` or `velocity_collapse` | -15 per flag |
| Blocker penalty (medium) | Any `stale_progress` blocker | -10 |

Clamp the final score to the 0-100 range after all modifiers. Map score ranges to health labels:

| Score Range | Label |
|-------------|-------|
| 80-100 | Healthy |
| 60-79 | Needs Attention |
| 40-59 | At Risk |
| 0-39 | Critical |

---

## Report Aggregation Rules

When producing multi-goal reports, apply these aggregation rules:

- **Portfolio health**: Average the health scores of all active goals (exclude "Not Started" and closed goals).
- **Goal count by tier**: Count goals in each RAG tier (Green/Yellow/Red) for the summary header.
- **Top blockers**: Surface the 5 highest-severity blockers across all goals.
- **Velocity leaders and laggards**: Identify the 3 fastest-progressing and 3 slowest-progressing goals by weighted velocity.
- **Stale goals**: List all goals with `stale_progress` blockers, sorted by staleness descending (longest stall first).
- **Ready to close**: List goals at 100% progress that have not been marked as closed.

---

## Edge Cases

### Brand-New Goal (< 7 Days Old)

Display RAG as "Too early" instead of computing a potentially misleading Red score. Exclude from portfolio health averages. Show progress percentage and milestones only.

### Goal With No Target Date

Skip RAG calculation and velocity projection. Report actual progress, milestones completed, and blockers only. Display "No deadline" in the RAG column.

### Goal at 100% but Not Closed

Flag as "Ready to close" in reports. Do not include in portfolio health averages (the goal is complete but lacks a status update). Display a reminder to close the goal.

### Multiple Stale Goals

Sort by staleness descending (longest stall first) in reports. When more than 5 stale goals exist, display the top 5 and indicate the remaining count.

### Velocity = 0

Display "Stalled" as the projected completion value. Trigger the `stale_progress` blocker if the stall duration exceeds 14 days. Never attempt to divide by zero in the projection formula — guard against zero velocity before the division step.

### Negative Velocity

Display "Regressing" as the projected completion value. Treat as a critical anomaly. Do not produce a projected date from negative velocity data.

---

## Additional Resources

### Reference Files

For detailed algorithms, formulas, and edge case handling, consult:

- **`${CLAUDE_PLUGIN_ROOT}/skills/progress-analysis/references/velocity-projection.md`** — Full velocity formulas with multi-window math, milestone-to-progress conversion, window re-normalization when data is sparse, and negative velocity handling
- **`${CLAUDE_PLUGIN_ROOT}/skills/progress-analysis/references/rag-status-calculation.md`** — Complete RAG algorithm with cold-start guards, clamping logic, status override rules, and no-deadline handling
- **`${CLAUDE_PLUGIN_ROOT}/skills/progress-analysis/references/blocker-detection.md`** — Detection logic for all four blocker types, severity levels, escalation rules, output schema, and multi-blocker interaction patterns
