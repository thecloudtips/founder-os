# Status Lifecycle

This reference defines the complete state machine for goal status transitions. Enforce these rules on every status change. Reject invalid transitions with the specified error messages. Fire auto-triggers when their conditions are met.

## States

A goal has exactly one of five statuses at any time:

| Status | Description |
|--------|-------------|
| Not Started | Goal created but no work has begun. Default state on creation. |
| In Progress | Active work is underway. At least one milestone has started or progress has been recorded. |
| On Hold | Work intentionally paused. Goal remains visible but excluded from active reports. |
| Completed | All milestones are Done and progress equals 100%. Goal is finished. |
| Archived | Goal moved to long-term storage. Read-only unless explicitly reopened. |

## Transition Matrix

Use this matrix to validate every status change. Rows represent the current status. Columns represent the requested target status.

| From \ To | Not Started | In Progress | On Hold | Completed | Archived |
|-----------|:-----------:|:-----------:|:-------:|:---------:|:--------:|
| **Not Started** | -- | Valid | Invalid | Invalid | Valid |
| **In Progress** | Invalid | -- | Valid | Valid | Valid |
| **On Hold** | Invalid | Valid | -- | Invalid | Valid |
| **Completed** | Invalid | Invalid | Invalid | -- | Valid |
| **Archived** | Invalid | Invalid | Invalid | Invalid | -- |

## Valid Transitions

### Not Started --> In Progress

**Triggers:** First progress update recorded. First milestone status changed to "In Progress" or "Done". User runs `/founder-os:goal:update` with explicit `--status=in-progress`. User runs any command that records progress data.

**Guard conditions:** None. This transition is always permitted from Not Started.

**Side effects:** Set the goal's Start Date to today's date (YYYY-MM-DD). Append the first progress snapshot. Log the transition timestamp.

### In Progress --> On Hold

**Triggers:** User explicitly sets `--status=on-hold`. No automatic trigger exists for this transition — it requires manual action.

**Guard conditions:** Goal must have Status = "In Progress". Confirm the hold with the user before applying (display current progress and milestone summary).

**Side effects:** Record the hold date. Preserve all progress data and snapshots. Exclude the goal from active velocity calculations and reports (unless explicitly included with a flag).

### In Progress --> Completed

**Triggers:** Progress reaches 100% with all milestones in "Done" status. User runs `/founder-os:goal:close` without `--archive`. User manually sets `--status=completed`.

**Guard conditions:** Verify progress equals 100%. Verify every active milestone (non-Skipped) has Status = "Done". If milestones remain incomplete, warn the user and require confirmation before allowing manual completion.

**Side effects:** Set the Completed Date to today. Append a final progress snapshot at 100%. Calculate total duration (Completed Date minus Start Date). Set RAG status to Green.

### On Hold --> In Progress

**Triggers:** User explicitly sets `--status=in-progress`. User runs `/founder-os:goal:update` while goal is On Hold.

**Guard conditions:** Goal must have Status = "On Hold".

**Side effects:** Clear the hold date. Resume velocity tracking from today (do not backfill the hold period). Append a progress snapshot for today at the current progress value.

### Any --> Archived

**Triggers:** User runs `/founder-os:goal:close --archive`. User explicitly sets `--status=archived`.

**Guard conditions:** None. Any status can transition to Archived. Display a confirmation prompt before archiving, showing the goal's current progress and status.

**Side effects:** Set the Archived Date to today. Mark the goal as read-only. Exclude the goal from all active queries, reports, and velocity calculations. Preserve all historical data.

## Invalid Transitions

Reject these transitions and return the specified error message. Do not modify the goal's status.

### Completed --> In Progress

**Error message:** "Completed goals cannot be reopened. Create a new goal or use --reopen."

**Rationale:** Completed goals represent finished work. Reopening them corrupts historical metrics. Direct the user to `--reopen` which creates a deliberate audit trail.

### Completed --> On Hold

**Error message:** "Completed goals cannot be placed on hold. The goal is already finished."

**Rationale:** Holding a completed goal has no meaningful semantics.

### Completed --> Not Started

**Error message:** "Completed goals cannot be reset to Not Started. Create a new goal instead."

**Rationale:** Resetting would destroy progress history.

### Archived --> Any (except via --reopen)

**Error message:** "Archived goals are read-only. Use --reopen to restore."

**Rationale:** Archived goals are intentionally frozen. The `--reopen` flag provides a deliberate escape hatch that logs the restoration event.

### Not Started --> Completed

**Error message:** "Cannot complete a goal that hasn't started. Update progress first."

**Rationale:** A goal with no recorded work cannot be marked complete. Require at least one progress update or milestone completion before allowing completion.

### Not Started --> On Hold

**Error message:** "Cannot hold a goal that hasn't started. Start the goal first or archive it."

**Rationale:** Holding implies pausing active work. A goal with no work to pause should either begin or be archived.

### In Progress --> Not Started

**Error message:** "Cannot revert an in-progress goal to Not Started. Progress has already been recorded."

**Rationale:** Progress data and Start Date have been set. Reverting would require deleting history.

### On Hold --> Completed

**Error message:** "Cannot complete a goal directly from On Hold. Resume the goal first, then complete it."

**Rationale:** Enforce the resume step so velocity calculations and completion dates reflect reality.

### On Hold --> Not Started

**Error message:** "Cannot revert a held goal to Not Started. Resume it to In Progress instead."

**Rationale:** The goal has a recorded Start Date and progress history.

## Auto-Triggers

Implement these automatic status transitions. Fire them after every relevant operation without requiring user input.

### Auto-Start on First Progress

**Condition:** Goal status is "Not Started" AND (a milestone changes to "In Progress" or "Done" OR a progress value is recorded).

**Action:** Transition status to "In Progress". Set Start Date to today. Append the first progress snapshot. Do not prompt the user — this transition is implicit.

### Auto-Complete on Last Milestone

**Condition:** Goal status is "In Progress" AND recalculated progress equals 100% AND every active milestone has Status = "Done".

**Action:** Transition status to "Completed". Set Completed Date to today. Append a final 100% progress snapshot. Set RAG to Green. Display a congratulatory confirmation message to the user.

Do not auto-complete if any active milestone is still "In Progress" or "Not Started", even if the math rounds to 100%. Require every active milestone to be "Done".

### Auto-Red on Missed Deadline

**Condition:** Goal status is "In Progress" or "On Hold" AND today's date is past the Target Date AND progress is less than 100%.

**Action:** Set RAG status to "Red". Do not change the goal's lifecycle status — the goal remains In Progress or On Hold. Append a note: "Target date passed with progress at N%." Evaluate this condition on every `/founder-os:goal:report`, `/founder-os:goal:update`, and `/founder-os:goal:list` invocation.

## The --reopen Escape Hatch

When a user passes `--reopen` on a Completed or Archived goal:

1. Transition the goal to "In Progress" regardless of current status.
2. Clear the Completed Date and Archived Date.
3. Preserve all existing progress snapshots and milestone data.
4. Append a snapshot for today at the current progress value.
5. Log the reopen event with a timestamp and reason (prompt the user for a reason).
6. Resume velocity tracking from today.

Treat `--reopen` as an explicit override that bypasses the normal invalid-transition rules. It exists for legitimate cases where scope changes or new requirements emerge after a goal was considered finished.
