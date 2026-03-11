# Review Structure Reference

Detailed templates, formatting rules, metrics formulas, and a complete example for each of the 6 weekly review sections. Use this reference when assembling the final review document.

---

## Notion Block Type Mapping

Apply these block types consistently across all review sections.

| Element | Notion Block Type | Notes |
|---------|-------------------|-------|
| Section headings | `heading_2` | One H2 per section, numbered 1-6 |
| Sub-headings (project names, categories) | `heading_3` | Used inside Wins by Project and Blockers & Risks |
| Metric highlights | `callout` (icon: bar chart) | Place at top of Executive Summary and any section with computed metrics |
| Task lists, meeting lists, blocker lists | `bulleted_list_item` | Default list type; use for all enumerated items |
| Detailed breakdowns (per-project tasks, per-day calendar) | `toggle` | Collapse detail under toggle heading to keep review scannable |
| Inline status indicators | Emoji prefix in text | See Status Indicators table below |
| Priority labels | Bold text prefix | `**P1**`, `**P2**`, etc. |
| Section dividers | `divider` | Place between each of the 6 sections |

### Status Indicators

| Indicator | Meaning | Usage |
|-----------|---------|-------|
| `[DONE]` | Task completed this week | Wins by Project items |
| `[OPEN]` | Task still in progress | Carryover Items |
| `[BLOCKED]` | Task explicitly blocked | Blockers & Risks |
| `[OVERDUE]` | Task past due date | Blockers & Risks |
| `[STAGNANT]` | Task unchanged for 7+ days | Blockers & Risks |

---

## Metrics Calculation Formulas

Compute these metrics before assembling any section. All metrics reference the review period (default: Monday 00:00 through Sunday 23:59 of the target week).

### Tasks Completed Count

```
tasks_completed = COUNT(tasks WHERE status changed to "Done" during review period)
```

Include tasks from all tracked Notion databases. Count each task once even if status toggled multiple times.

### Tasks Created Count

```
tasks_created = COUNT(tasks WHERE created_time falls within review period)
```

### Meetings Held Count

```
meetings_held = COUNT(calendar events WHERE start_time falls within review period
                      AND event was not cancelled
                      AND event duration >= 15 minutes)
```

Exclude all-day events. Exclude events with title matching hold/block patterns ("Focus Block", "Hold", "Blocked", "OOO", "Lunch").

### Email Threads Count

```
email_threads = COUNT(DISTINCT thread_ids WHERE any message sent or received during review period)
```

Use Gmail thread IDs for deduplication. Count threads, not individual messages.

### Blocker Count

```
blocker_count = COUNT(tasks WHERE status = "Blocked")
               + COUNT(tasks WHERE due_date < review_period_start AND status != "Done")
               + COUNT(tasks WHERE last_edited < (review_period_start - 7 days) AND status NOT IN ("Done", "Blocked", "Archived"))
```

The three components correspond to blocked tasks, overdue tasks, and stagnant tasks respectively.

### Meeting Density

```
meeting_hours = SUM(event duration in hours for all counted meetings)
meeting_density = meeting_hours / 40
```

Express as a percentage. Use 40 hours as the baseline work week.

### Completion Rate

```
completion_rate = tasks_completed / (tasks_completed + open_tasks_at_end_of_week) * 100
```

---

## Week Assessment Logic

Assign one of three assessment levels based on task completion and meeting density.

### Assessment Thresholds

| Assessment | Criteria |
|------------|----------|
| **Productive** | `completion_rate >= 70%` AND `tasks_completed >= 8` |
| **Moderate** | `completion_rate >= 40%` OR `tasks_completed >= 5` (when not meeting Productive thresholds) |
| **Light** | `completion_rate < 40%` AND `tasks_completed < 5` |

### Modifier Rules

Apply these modifiers after the base assessment.

- If `meeting_density > 50%`, append "(meeting-heavy)" to the assessment. A meeting-heavy week with fewer completed tasks is expected behavior, not a negative signal.
- If `blocker_count >= 3`, append "(blocked)" to the assessment. Indicate systemic impediment rather than low effort.
- If the week contains a holiday or PTO day (detected from all-day calendar events with keywords "Holiday", "PTO", "Vacation", "Day Off"), append "(short week)" and adjust the Productive threshold down proportionally: reduce `tasks_completed` threshold by 2 per day off.

### Assessment Phrasing

| Assessment | Template Sentence |
|------------|-------------------|
| Productive | "A productive week with {tasks_completed} tasks completed across {project_count} projects." |
| Productive (meeting-heavy) | "A productive but meeting-heavy week ({meeting_hours}h in meetings) with {tasks_completed} tasks still completed." |
| Moderate | "A moderate week with {tasks_completed} tasks completed; {blocker_count} items need attention." |
| Moderate (blocked) | "A moderate week with progress slowed by {blocker_count} blockers across {theme_count} themes." |
| Light | "A lighter week with {tasks_completed} tasks completed. Review carryover priorities below." |
| Light (short week) | "A short week ({days_worked} working days) with {tasks_completed} tasks completed." |

---

## Section 1: Executive Summary

Render as a `callout` block (icon: clipboard) followed by 2-3 sentences.

### Template

```
> [callout block]
> Tasks Done: {tasks_completed} | Meetings: {meetings_held} | Email Threads: {email_threads} | Blockers: {blocker_count}

{assessment_sentence}

{highlight_sentence - name the single most impactful win or biggest risk from this week.}

{optional: one sentence noting any cross-project dependency or theme that emerged.}
```

### Assembly Rules

- Limit to 3 sentences maximum after the metrics callout.
- Write the assessment sentence first using the assessment phrasing table above.
- Select the highlight by scanning Wins for the highest-impact item (largest project, most tasks, or externally visible deliverable). If no clear win, highlight the top blocker instead.
- Omit the third sentence if no cross-project theme is apparent. Do not force a theme.

---

## Section 2: Wins by Project

Group completed tasks by their source Notion database or project property. Render each project as an H3 toggle containing a bulleted list.

### Template

```
## Wins by Project

### {Project Name A} ({completed_count_a} tasks)
- [DONE] {Task title 1}
- [DONE] {Task title 2}
- [DONE] {Task title 3}

### {Project Name B} ({completed_count_b} tasks)
- [DONE] {Task title 1}
- [DONE] {Task title 2}
```

### Assembly Rules

- Sort projects by completed task count descending. Place the project with the most completions first.
- Within each project, sort tasks by completion date ascending (earliest first).
- Include only tasks whose status changed to "Done" during the review period.
- If a task has a "Priority" property, prefix the task title with the priority: `[DONE] **P1** {Task title}`.
- Collapse each project group inside a `toggle` block. Display the project name and count in the toggle heading.
- If a task belongs to no project or has no project property, group under "Uncategorized".
- If zero tasks were completed, display a single bullet: "No tasks completed this week. Review Carryover Items and Blockers sections below."

---

## Section 3: Meetings & Outcomes

List all meetings held during the review period with extracted outcomes.

### Template

```
## Meetings & Outcomes

> [callout block]
> {meetings_held} meetings | {meeting_hours}h total | {meeting_density}% of work week

### {Day of Week, Date}
- **{Meeting Title}** ({start_time}-{end_time}) -- Attendees: {attendee_names} -- Outcome: {outcome_summary}
- **{Meeting Title}** ({start_time}-{end_time}) -- Attendees: {attendee_names} -- Outcome: {outcome_summary}

### {Day of Week, Date}
- **{Meeting Title}** ({start_time}-{end_time}) -- Attendees: {attendee_names} -- Outcome: {outcome_summary}
```

### Outcome Extraction Rules

- Extract the outcome from the event description, linked Notion page, or meeting notes if available.
- If no description or notes exist, set outcome to "No notes captured."
- Summarize the outcome in one sentence maximum. Focus on decisions made, next steps agreed, or information exchanged.
- For recurring meetings (detected by recurrence rule on the event), note only what was different or decided this occurrence. Default: "Recurring sync -- no notable decisions."

### Assembly Rules

- Group meetings by day. Use H3 headings for each day that had meetings.
- Sort days Monday through Friday (then Saturday/Sunday if applicable).
- Within each day, sort by start time ascending.
- Bold the meeting title. Follow with time range, attendees (first names only, max 5 then "+N others"), and outcome.
- Wrap each day inside a `toggle` block. Display day name and meeting count in the toggle heading.
- Skip days with zero meetings entirely. Do not display empty days.

---

## Section 4: Blockers & Risks

Detect and display items requiring attention using three signal sources. Group by theme when possible.

### Signal Sources

| Signal | Detection Rule | Indicator |
|--------|---------------|-----------|
| Blocked tasks | `status = "Blocked"` | `[BLOCKED]` |
| Overdue tasks | `due_date < today AND status != "Done"` | `[OVERDUE]` by {days} days |
| Stagnant tasks | `last_edited < (today - 7 days) AND status NOT IN ("Done", "Blocked", "Archived")` | `[STAGNANT]` for {days} days |

### Template

```
## Blockers & Risks

> [callout block]
> {blocker_count} items need attention: {blocked_count} blocked, {overdue_count} overdue, {stagnant_count} stagnant

### {Theme Name} ({item_count} items)
- [BLOCKED] **{Task title}** -- {project} -- Blocked since {date}. Reason: {reason if available, else "No reason recorded."}
- [OVERDUE] **{Task title}** -- {project} -- Due {due_date}, {days_overdue} days overdue.

### {Theme Name} ({item_count} items)
- [STAGNANT] **{Task title}** -- {project} -- Unchanged since {last_edited_date} ({days_stagnant} days).
```

### Theme Grouping Rules

- Attempt to group blockers by common project, common owner, or common dependency.
- If 3+ items share the same project, group under that project name.
- If 3+ items share the same assignee, group under "{Assignee Name}'s queue".
- If no natural grouping emerges (fewer than 3 items per potential group), use a flat list under a single heading "Active Blockers & Risks".
- Sort themes by total item count descending.
- Within each theme, sort by severity: `[BLOCKED]` first, then `[OVERDUE]` (sorted by days overdue descending), then `[STAGNANT]` (sorted by days stagnant descending).

### Zero Blockers

If blocker_count is zero, display:

```
## Blockers & Risks

No blocked, overdue, or stagnant items detected. All tracked tasks are progressing.
```

---

## Section 5: Carryover Items

List open tasks that were not completed during the review period, grouped by priority.

### Template

```
## Carryover Items

> [callout block]
> {carryover_count} open items carrying into next week

### Priority 1 - Critical ({p1_count})
- [OPEN] **{Task title}** -- {project} -- In "{status}" for {days_in_status} days
- [OPEN] **{Task title}** -- {project} -- In "{status}" for {days_in_status} days

### Priority 2 - High ({p2_count})
- [OPEN] **{Task title}** -- {project} -- In "{status}" for {days_in_status} days

### Priority 3 - Medium ({p3_count})
- [OPEN] **{Task title}** -- {project} -- In "{status}" for {days_in_status} days

### No Priority ({np_count})
- [OPEN] **{Task title}** -- {project} -- In "{status}" for {days_in_status} days
```

### Assembly Rules

- Include all tasks with status NOT IN ("Done", "Archived", "Cancelled") at the end of the review period.
- Exclude tasks with status "Blocked" (those appear in Section 4 instead).
- Group by priority level. Use H3 headings per priority group.
- Sort within each priority group by days_in_status descending (longest-waiting items first).
- Calculate `days_in_status` as the number of days since the task's status last changed.
- Wrap each priority group in a `toggle` block.
- If a task has no priority property, place in "No Priority" group at the end.
- Flag any task with `days_in_status > 14` by appending " -- Consider re-prioritizing or closing." to the line.

---

## Section 6: Next Week Priorities & Calendar Preview

Combine AI-ranked top priorities with a calendar shape analysis for the upcoming week.

### Top 5 Priorities Sub-section

Rank the top 5 items from Carryover Items using a weighted scoring formula.

```
priority_score = (priority_weight * 0.35)
               + (days_in_status_normalized * 0.25)
               + (dependency_weight * 0.20)
               + (deadline_proximity_weight * 0.20)
```

| Factor | Calculation |
|--------|-------------|
| `priority_weight` | P1=100, P2=75, P3=50, P4=25, No Priority=10 |
| `days_in_status_normalized` | `min(days_in_status / 30, 1.0) * 100` |
| `dependency_weight` | 100 if other tasks depend on this one (detected via Notion relation property), else 0 |
| `deadline_proximity_weight` | `max(0, 100 - (days_until_due * 10))`. If no due date, use 0. |

### Template

```
## Next Week Priorities & Calendar Preview

### Top 5 Priorities
1. **{Task title}** -- {project} -- Score: {priority_score} -- {one-sentence rationale}
2. **{Task title}** -- {project} -- Score: {priority_score} -- {one-sentence rationale}
3. **{Task title}** -- {project} -- Score: {priority_score} -- {one-sentence rationale}
4. **{Task title}** -- {project} -- Score: {priority_score} -- {one-sentence rationale}
5. **{Task title}** -- {project} -- Score: {priority_score} -- {one-sentence rationale}

### Calendar Preview: Week of {next_monday_date}
| Day | Meetings | Hours Blocked | Available Focus Time |
|-----|----------|---------------|---------------------|
| Monday | {count} | {hours}h | {available}h |
| Tuesday | {count} | {hours}h | {available}h |
| Wednesday | {count} | {hours}h | {available}h |
| Thursday | {count} | {hours}h | {available}h |
| Friday | {count} | {hours}h | {available}h |

**Meeting-heavy days:** {list days where meeting hours > 4h}
**Focus blocks:** {list days where available focus time > 4h}
**Best day for deep work:** {day with most available focus time}
```

### Calendar Preview Rules

- Scan the next Monday through Friday on Google Calendar.
- Calculate available focus time as `8 - meeting_hours` per day (assume 8h workday).
- Flag any day with meeting_hours > 4 as "meeting-heavy".
- Flag any day with available_focus_time >= 4 as a "focus block".
- Identify the single day with the highest available focus time as "Best day for deep work."
- If no calendar data is available, omit the Calendar Preview sub-section and note: "Calendar preview unavailable -- connect Google gws CLI (Calendar) for next week's shape."

### Rationale Rules

- Write each rationale in one sentence explaining why the item ranks where it does.
- Reference the dominant scoring factor: "Highest priority due to P1 status and approaching deadline." or "Long-stagnant item (18 days) with downstream dependencies."
- Do not repeat the task title in the rationale.

---

## Complete Example Output

Below is a realistic example for the week of February 23-27, 2026 for a founder running two active projects.

```markdown
## Executive Summary

> Tasks Done: 11 | Meetings: 8 | Email Threads: 34 | Blockers: 3

A productive but meeting-heavy week (12.5h in meetings) with 11 tasks still completed.

The client onboarding flow for Acme Corp shipped on Thursday, marking the biggest deliverable of the month.

---

## Wins by Project

### NaluForge Platform (6 tasks)
- [DONE] **P1** Implement client onboarding wizard API endpoints
- [DONE] **P1** Write integration tests for onboarding flow
- [DONE] **P2** Update API documentation for v2.3 endpoints
- [DONE] **P3** Refactor notification service error handling
- [DONE] **P3** Add rate limiting to public API routes
- [DONE] Configure staging environment variables

### Founder OS (3 tasks)
- [DONE] **P2** Build Plugin #19 Slack Digest Engine
- [DONE] **P2** Write integration test plan for Plugin #19
- [DONE] **P3** Update CLAUDE.md with Plugin #19 reference

### Uncategorized (2 tasks)
- [DONE] Review and sign updated vendor agreement
- [DONE] Submit Q1 estimated tax payment

---

## Meetings & Outcomes

> 8 meetings | 12.5h total | 31% of work week

### Monday, Feb 23
- **Acme Corp Kickoff** (10:00-11:30) -- Attendees: Sarah, James, Priya -- Outcome: Agreed on 3-phase rollout starting March 3; Priya to send asset list by Wednesday.
- **Team Standup** (14:00-14:30) -- Attendees: Marcus, Lena, Kai -- Outcome: Recurring sync -- flagged staging deploy blocker.

### Tuesday, Feb 24
- **Product Roadmap Review** (09:00-10:00) -- Attendees: Marcus, Lena -- Outcome: Deprioritized analytics dashboard to Q2; moved notification overhaul to March sprint.

### Wednesday, Feb 25
- **Investor Update Prep** (11:00-12:00) -- Attendees: Sarah -- Outcome: Finalized Q1 metrics deck; Sarah to review final slides by Friday.
- **Acme Corp Technical Walkthrough** (14:00-15:30) -- Attendees: James, Priya, Kai -- Outcome: Confirmed API integration approach; identified auth token refresh issue needing fix.

### Thursday, Feb 26
- **1:1 with Marcus** (10:00-10:45) -- Attendees: Marcus -- Outcome: Discussed career growth path; agreed on tech lead responsibilities starting April.
- **Client Health Check: Bolt Industries** (15:00-15:45) -- Attendees: Tanya, Ravi -- Outcome: Bolt requesting scope change on Phase 2; need revised SOW by March 7.

### Friday, Feb 27
- **Weekly Retro** (16:00-17:00) -- Attendees: Marcus, Lena, Kai, Tanya -- Outcome: Adopted new PR review SLA (24h max); will trial for 2 weeks.

---

## Blockers & Risks

> 3 items need attention: 1 blocked, 1 overdue, 1 stagnant

### NaluForge Platform (2 items)
- [BLOCKED] **Deploy staging environment update** -- NaluForge Platform -- Blocked since Feb 24. Reason: Waiting on DevOps to provision new SSL certificate.
- [STAGNANT] **Migrate legacy webhook handlers** -- NaluForge Platform -- Unchanged since Feb 14 (13 days).

### Active Blockers & Risks (1 item)
- [OVERDUE] **Send revised SOW to Bolt Industries** -- Uncategorized -- Due Feb 21, 6 days overdue.

---

## Carryover Items

> 7 open items carrying into next week

### Priority 1 - Critical (1)
- [OPEN] **Fix auth token refresh for Acme integration** -- NaluForge Platform -- In "In Progress" for 2 days

### Priority 2 - High (3)
- [OPEN] **Prepare Q1 investor metrics deck (final)** -- NaluForge Platform -- In "In Progress" for 4 days
- [OPEN] **Draft revised SOW for Bolt Industries Phase 2** -- Uncategorized -- In "To Do" for 6 days
- [OPEN] **Build Plugin #20 Client Context Loader** -- Founder OS -- In "To Do" for 3 days

### Priority 3 - Medium (2)
- [OPEN] **Set up monitoring alerts for production API** -- NaluForge Platform -- In "To Do" for 10 days
- [OPEN] **Research competitor pricing for Q2 positioning** -- Uncategorized -- In "To Do" for 8 days

### No Priority (1)
- [OPEN] **Organize shared Drive folders for client assets** -- Uncategorized -- In "To Do" for 16 days -- Consider re-prioritizing or closing.

---

## Next Week Priorities & Calendar Preview

### Top 5 Priorities
1. **Fix auth token refresh for Acme integration** -- NaluForge Platform -- Score: 82 -- P1 item with Acme launch dependency on March 3.
2. **Draft revised SOW for Bolt Industries Phase 2** -- Uncategorized -- Score: 74 -- Already 6 days overdue with client expecting delivery by March 7.
3. **Prepare Q1 investor metrics deck (final)** -- NaluForge Platform -- Score: 68 -- Sarah reviewing Friday; needs finalization before investor send.
4. **Build Plugin #20 Client Context Loader** -- Founder OS -- Score: 51 -- P2 item blocking downstream Plugin #21 CRM Sync Hub.
5. **Set up monitoring alerts for production API** -- NaluForge Platform -- Score: 45 -- Long-stagnant item (10 days) needed before Acme goes live.

### Calendar Preview: Week of March 2
| Day | Meetings | Hours Blocked | Available Focus Time |
|-----|----------|---------------|---------------------|
| Monday | 3 | 3.5h | 4.5h |
| Tuesday | 1 | 1.0h | 7.0h |
| Wednesday | 2 | 2.5h | 5.5h |
| Thursday | 4 | 5.0h | 3.0h |
| Friday | 2 | 2.0h | 6.0h |

**Meeting-heavy days:** Thursday
**Focus blocks:** Tuesday, Wednesday, Friday
**Best day for deep work:** Tuesday
```
