---
name: Goal Tracking
description: "Manages the full goal lifecycle: creation, milestone tracking, progress updates, and closure. Activates when the user wants to set, create, update, or close a goal, log a milestone, or asks 'add a new goal for [objective].' Handles CRUD operations, progress calculation, and Notion database management."
globs:
  - commands/goal-create.md
  - commands/goal-update.md
  - commands/goal-close.md
---

# Goal Tracking

## Overview

Manage the full lifecycle of founder goals — creation, milestone tracking, progress calculation, and closure — with Notion as the persistent backend. Operate on a dual-database design: a Goals DB stores top-level goal records with progress metadata, and a Milestones DB stores ordered sub-tasks linked to their parent goal via a Notion relation property. Calculate progress automatically from milestone completion state, enforce idempotent upserts to prevent duplicates, and maintain an append-only audit trail in the Notes field.

## Notion Database Schemas

### Goals DB: "[FOS] Goals" (fallback: "Founder OS HQ - Goals", then "Goal Progress Tracker - Goals")

Store each goal as a single page with 14 properties:

| Property | Type | Purpose |
|----------|------|---------|
| Title | title | Goal name (primary key for upsert matching) |
| Description | rich_text | Expanded description of the goal |
| Status | select | Current lifecycle state: Not Started, In Progress, On Hold, Completed, Archived |
| Progress | number (percent) | Computed progress 0-100, updated on every milestone change or manual override |
| Target Date | date | Intended completion date |
| Start Date | date | Date goal moved to In Progress (auto-set on first progress update) |
| Category | select | One of 8 categories (see Category Taxonomy below) |
| RAG Status | select | Red, Amber, Green — derived from progress vs. target date trajectory |
| Projected Completion | date | Estimated completion based on velocity from Progress Snapshots |
| Milestone Count | number | Total milestones linked to this goal (excluding Skipped) |
| Completed Milestones | number | Count of milestones with Status = Done |
| Progress Snapshots | rich_text | JSON array of `{"date": "YYYY-MM-DD", "progress": N}` entries for velocity calculation |
| Notes | rich_text | Append-only log of updates, context, and decisions |
| Created At | date | Timestamp of initial goal creation |

### Milestones DB: "[FOS] Milestones" (fallback: "Founder OS HQ - Milestones", then "Goal Progress Tracker - Milestones")

Store each milestone as a page with 8 properties:

| Property | Type | Purpose |
|----------|------|---------|
| Title | title | Milestone name (verb-first format) |
| Goal | relation | Relation to Goals DB (parent goal link) |
| Status | select | Not Started, In Progress, Done, Skipped |
| Due Date | date | Target completion date for this milestone |
| Completed At | date | Actual completion timestamp (set when Status moves to Done) |
| Order | number | Sequential position within the goal (1-based) |
| Notes | rich_text | Append-only context for this milestone |
| Created At | date | Timestamp of milestone creation |

### Creation Order Dependency

Create the Goals DB before the Milestones DB. The Milestones DB depends on the Goals DB existing first because the Goal relation property references it by database ID. Attempting to create the Milestones DB first will fail or produce an orphaned relation.

## Database Discovery Protocol

Follow this sequence every time a command needs to read or write goal data:

1. Search Notion for a database titled "[FOS] Goals". If not found, try "Founder OS HQ - Goals". If not found, fall back to "Goal Progress Tracker - Goals".
2. If found, store the database ID and proceed. If none is found, report: "Goals database not found. Ensure the Founder OS HQ workspace template is installed in your Notion workspace." Then stop.
3. Search Notion for a database titled "[FOS] Milestones". If not found, try "Founder OS HQ - Milestones". If not found, fall back to "Goal Progress Tracker - Milestones".
4. If found, store the database ID and proceed. If none is found, report: "Milestones database not found. Ensure the Founder OS HQ workspace template is installed in your Notion workspace." Then stop.
5. Never create a database that already exists. Never assume database IDs — always discover via search.

## Goal Lifecycle

Manage status transitions according to these rules:

| From | To | Trigger |
|------|----|---------|
| Not Started | In Progress | First progress update, first milestone started, or manual status change |
| In Progress | On Hold | Manual via `/founder-os:goal:update --status=on-hold` |
| In Progress | Completed | Progress reaches 100%, all milestones Done, or manual close via `/founder-os:goal:close` |
| On Hold | In Progress | Manual resume via `/founder-os:goal:update --status=in-progress` |
| Any | Archived | Manual via `/founder-os:goal:close --archive` |

Auto-set Start Date to today when a goal transitions from Not Started to In Progress for the first time. Never overwrite an existing Start Date on subsequent transitions.

Prevent invalid transitions: a goal cannot move from Completed back to In Progress (require unarchive or re-open as a new goal). A goal cannot move from Archived to any state without explicit `--reopen` confirmation.

Reference `${CLAUDE_PLUGIN_ROOT}/skills/goal/goal-tracking/references/status-lifecycle.md` for the full transition matrix, guard conditions, and error messages for each invalid transition.

## Milestone Progress Formula

Calculate goal progress from milestone completion state using:

```
progress = (completed_count + in_progress_count * 0.5) / total_active * 100
```

Define the variables:

- `completed_count` — milestones with Status = Done
- `in_progress_count` — milestones with Status = In Progress
- `total_active` — all milestones except those with Status = Skipped

Apply partial credit: each In Progress milestone contributes 0.5 to the numerator. This prevents progress from stalling at 0% when work has begun but no milestone is fully complete.

Round the result to the nearest integer. Clamp to the range 0-100.

After every progress recalculation, append a new entry to the Progress Snapshots field: `{"date": "YYYY-MM-DD", "progress": N}`. Use these snapshots for velocity calculation and projected completion estimation.

Reference `${CLAUDE_PLUGIN_ROOT}/skills/goal/goal-tracking/references/milestone-progress-formula.md` for edge cases, division-by-zero handling, and worked examples.

## Category Taxonomy

Assign each goal to one of 8 categories:

| Category | Auto-Detection Signals |
|----------|----------------------|
| Revenue | "revenue", "sales", "ARR", "MRR", "pricing", "deal", "close", "pipeline" |
| Product | "launch", "ship", "feature", "release", "MVP", "beta", "roadmap", "build" |
| Operations | "process", "workflow", "SOP", "efficiency", "automate", "streamline" |
| Team | "hire", "onboard", "culture", "team", "recruit", "retain", "1:1" |
| Personal | "health", "fitness", "learn", "read", "habit", "meditation", "balance" |
| Technical | "infrastructure", "migrate", "deploy", "refactor", "API", "database", "security" |
| Marketing | "content", "SEO", "social", "brand", "campaign", "awareness", "funnel" |
| Other | Fallback when no signals match |

Apply auto-detection by scanning the goal title and description for keyword matches. Use case-insensitive matching. When multiple categories match, select the one with the highest keyword hit count. When the user explicitly provides a category via `--category`, always use the explicit value and skip auto-detection.

## Idempotent Upsert Rules

### Goals

Match existing goals by Title using case-insensitive comparison. When a goal with the same title already exists:

- Update the existing page with any new or changed property values.
- Never create a second goal with the same or similar title.
- Merge Description content if the existing description is non-empty and the new description differs — append the new content below a horizontal rule.

### Milestones

Match existing milestones by Title + Goal relation. When a milestone with the same title already exists under the same parent goal:

- Update the existing milestone page.
- Never create a duplicate milestone.
- Preserve the original Order value unless explicitly changed.

## Notes Append-Only Rule

Never overwrite or replace the Notes field on any goal or milestone. Always prepend new entries at the top of the existing content using the format:

```
[YYYY-MM-DD] New note content here.

[previous entries preserved below]
```

Preserve all existing Notes content verbatim. This creates a reverse-chronological audit trail of all changes, decisions, and context updates for each goal and milestone.

## Goal Naming Conventions

Apply these rules when creating or renaming goals:

- Use a concise, action-oriented phrase that describes the desired outcome.
- Capitalize the first letter of the title.
- Do not include trailing periods or punctuation.
- Avoid filler words like "Goal:", "Objective:", or "Target:" as prefixes.
- Keep titles under 80 characters.
- Prefer specific and measurable language over vague aspirations ("Reach $50K MRR by Q3" over "Grow revenue").

## Milestone Naming Conventions

Apply these rules when creating milestones:

- Use verb-first format: "Complete X", "Launch Y", "Ship Z", "Finalize Q", "Deliver W".
- Capitalize the first letter.
- Do not include trailing periods.
- Keep titles under 60 characters.
- Assign sequential Order values starting from 1 within each goal.
- When inserting a milestone between existing ones, renumber all subsequent milestones to maintain sequential integrity.

## Edge Cases

### Goal with Zero Milestones

When a goal has no milestones, progress cannot be calculated from the milestone formula. Instead:

- Accept manual progress values via `/founder-os:goal:update --progress=N`.
- Store each manual update in Progress Snapshots for velocity tracking.
- Set Milestone Count and Completed Milestones to 0.
- RAG Status and Projected Completion still function using the manual progress values against Target Date.

### All Milestones Skipped

When every milestone under a goal has Status = Skipped, `total_active` equals zero. Handle this case:

- Set Progress to 0%.
- Flag the goal as potentially stale in the response output.
- Suggest the user either add new milestones, close the goal, or archive it.
- Do not divide by zero — guard with a check before applying the formula.

### Closing a Goal with Incomplete Milestones

When the user attempts to close a goal via `/founder-os:goal:close` and one or more milestones remain with Status = Not Started or In Progress:

- Warn the user with a count of incomplete milestones and their titles.
- Require explicit confirmation or the `--force` flag to proceed.
- If confirmed, set the goal Status to Completed and leave milestone statuses unchanged.
- Append a note: `[YYYY-MM-DD] Goal closed with N incomplete milestone(s).`

### Duplicate Goal Name

When a user attempts to create a goal with a title that matches an existing goal (case-insensitive):

- Do not create a new goal.
- Inform the user that the goal already exists and display its current Status and Progress.
- Offer to update the existing goal with any new properties provided in the create command.
- Apply the upsert rules described above if the user confirms.

### Target Date in the Past

When a user creates or updates a goal with a Target Date that has already passed:

- Accept the date without error (the user may be backdating intentionally).
- Set RAG Status to Red immediately if Progress is below 100%.
- Append a note: `[YYYY-MM-DD] Target date is in the past. RAG set to Red.`

### Milestone Completion Triggers Goal Completion

When the last active milestone transitions to Done and progress reaches 100%:

- Automatically transition the goal Status from In Progress to Completed.
- Set Projected Completion to today's date.
- Append a note: `[YYYY-MM-DD] All milestones completed. Goal auto-closed.`

## Additional Resources

Consult these reference files for detailed algorithms and worked examples:

- `${CLAUDE_PLUGIN_ROOT}/skills/goal/goal-tracking/references/milestone-progress-formula.md` — Full formula specification with division-by-zero guards, partial credit rules, rounding behavior, and step-by-step worked examples for common and edge-case scenarios.
- `${CLAUDE_PLUGIN_ROOT}/skills/goal/goal-tracking/references/status-lifecycle.md` — Complete transition matrix covering all valid and invalid status changes, guard conditions for each transition, auto-trigger rules, and error messages to display for blocked transitions.
