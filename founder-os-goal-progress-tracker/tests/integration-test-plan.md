# Integration Test Plan: Goal Progress Tracker (#30)

## Prerequisites

- Notion MCP server connected and verified
- `NOTION_API_KEY` environment variable set
- Integration shared with target Notion workspace page
- Clean test environment (no existing Goal Progress Tracker or Founder OS HQ databases)

---

## Test Cases

### TC-01: First Goal Creation (Full Arguments)

**Command:**
```
/goal:create "Launch MVP by end of Q2" --target=2026-06-30 --category=Product --milestones="Design mockups,Build prototype,User testing,Ship v1"
```

**Expected:**
- Searches for "[FOS] Goals" database first, tries "Founder OS HQ - Goals", falls back to "Goal Progress Tracker - Goals". If none exists, reports error.
- Searches for "[FOS] Milestones" database first, tries "Founder OS HQ - Milestones", falls back to "Goal Progress Tracker - Milestones". If none exists, reports error.
- Goal page: Title="Launch MVP by end of Q2", Status="Not Started", Progress=0, Category=Product, Target Date=2026-06-30, RAG Status="Not Started"
- 4 milestone pages linked to goal via relation, Order 1-4, all Status="Not Started"
- Milestone Count=4, Completed Milestones=0
- Progress Snapshots initialized: `[{"date":"YYYY-MM-DD","progress":0}]`
- Notes: `[YYYY-MM-DD] Goal created.`
- Chat confirmation displayed with all fields and milestone list

### TC-02: Goal Creation with Missing Arguments (Interactive)

**Command:**
```
/goal:create
```

**Expected:**
- Prompts: "What goal would you like to create?"
- Waits for user input
- After input, auto-detects category from goal name
- Saves successfully without target date or milestones
- RAG Status = "Not Started", no Projected Completion

### TC-03: Goal Creation without Milestones

**Command:**
```
/goal:create "Reach $50K MRR" --target=2026-12-31 --category=Revenue
```

**Expected:**
- Creates goal with Milestone Count=0
- No milestones created
- Progress tracking will be manual (via --progress flag)
- Confirmation shows "None -- track progress manually with /goal:update"

### TC-04: Duplicate Goal Detection

**Command:** (run after TC-01)
```
/goal:create "Launch MVP by end of Q2"
```

**Expected:**
- Detects existing goal with matching title (case-insensitive)
- Displays current Status and Progress of existing goal
- Offers to update instead of creating duplicate
- Does NOT create a second goal

### TC-05: Milestone Completion

**Command:**
```
/goal:update "Launch MVP" --done="Design mockups" --note="Finalized with client approval"
```

**Expected:**
- Finds "Launch MVP by end of Q2" via fuzzy match
- Sets "Design mockups" milestone Status=Done, Completed At=today
- Recalculates progress: (1 + 0*0.5) / 4 * 100 = 25%
- Auto-transitions goal Status from "Not Started" to "In Progress"
- Sets Start Date to today
- Appends Progress Snapshot: `{"date":"YYYY-MM-DD","progress":25}`
- Appends note: `[YYYY-MM-DD] Finalized with client approval`
- Computes RAG status (should be Green or Too Early if < 7 days)
- Displays updated summary with progress bar ███░░░░░░░ 25%

### TC-06: Manual Progress Update (No Milestones)

**Command:**
```
/goal:update "Reach 50K MRR" --progress=35
```

**Expected:**
- Sets Progress=35 on goal
- Appends Progress Snapshot
- Auto-transitions to "In Progress" if was "Not Started"
- Computes RAG status against Target Date
- Computes velocity projection

### TC-07: Manual Progress Rejected on Milestone Goal

**Command:**
```
/goal:update "Launch MVP" --progress=50
```

**Expected:**
- Rejects with message: "Progress is auto-calculated from milestones. Use --done to complete milestones instead."
- No changes made

### TC-08: Add Milestone to Existing Goal

**Command:**
```
/goal:update "Launch MVP" --add="QA testing phase"
```

**Expected:**
- Creates new milestone with Order=5 (next after existing 4)
- Updates Milestone Count to 5
- Recalculates progress (now out of 5 instead of 4)
- Displays updated milestone list

### TC-09: Status Change with Lifecycle Validation

**Command:**
```
/goal:update "Launch MVP" --status=on-hold --note="Waiting for vendor contract"
```

**Expected:**
- Valid transition: In Progress -> On Hold
- Updates Status to "On Hold"
- Appends note
- Does NOT change Progress or milestones

### TC-10: Invalid Status Transition

**Command:**
```
/goal:update "Launch MVP" --status=completed
```

**Expected:**
- Rejects with lifecycle error: cannot manually complete (use /goal:close or complete all milestones)
- OR if On Hold, suggests resuming first

### TC-11: Goal Check - Single Goal Detail

**Command:**
```
/goal:check "Launch MVP"
```

**Expected:**
- Displays detailed view with progress bar, RAG status, velocity, milestones with status icons
- Shows milestone list: ✅ Design mockups, 🔄/⬜ others
- Shows recent notes
- Shows blockers if any
- NEVER writes to Notion (ephemeral read-only)

### TC-12: Goal Check - All Goals Dashboard

**Command:**
```
/goal:check
```

**Expected:**
- Displays compact dashboard table for all non-archived goals
- Shows RAG emoji, progress bars, target dates
- Summary line: N on track, N at risk, N behind
- NEVER writes to Notion

### TC-13: Goal Report - Full Dashboard

**Command:**
```
/goal:report
```

**Expected:**
- 4-section report: Dashboard Table, RAG Breakdown, Needs Attention, Gantt Timeline
- Dashboard table sorted by RAG severity
- RAG Breakdown groups goals by tier with analysis
- Needs Attention lists blocker details
- Mermaid Gantt chart with sections by Category, color directives
- Updates RAG Status and Projected Completion on goal pages (writes to Notion)

### TC-14: Goal Report with Filters

**Command:**
```
/goal:report --status=red --category=Product
```

**Expected:**
- Only shows Red RAG goals in Product category
- If no matches: "No goals match the selected filters."
- Gantt chart only includes filtered goals

### TC-15: Goal Report to File

**Command:**
```
/goal:report --output=file --path=q2-goals.md
```

**Expected:**
- Writes full report to q2-goals.md
- All 4 sections present, no truncation
- Mermaid source included in file

### TC-16: Goal Close - Normal Completion

**Setup:** Complete all milestones on a goal first

**Command:**
```
/goal:close "Launch MVP" --note="Shipped successfully"
```

**Expected:**
- Status set to "Completed"
- Progress set to 100%
- Duration calculated (Start Date to today)
- Closing note appended
- Final summary with celebration message

### TC-17: Goal Close - Incomplete Milestones Warning

**Setup:** Goal with incomplete milestones

**Command:**
```
/goal:close "Launch MVP"
```

**Expected:**
- Lists incomplete milestones with status icons
- Asks for confirmation
- Does NOT close without confirmation or --force

### TC-18: Goal Close - Force Close

**Command:**
```
/goal:close "Launch MVP" --force --note="Deprioritized"
```

**Expected:**
- Skips incomplete milestone warning
- Sets Status to "Completed"
- Appends note about incomplete milestones

### TC-19: Goal Archive

**Command:**
```
/goal:close "Old initiative" --archive
```

**Expected:**
- Sets Status to "Archived"
- Leaves Progress as-is (not forced to 100%)
- Goal excluded from future reports and dashboards

### TC-20: Blocker Detection

**Setup:** Create goal with milestone past its due date

**Expected on /goal:check or /goal:report:**
- Detects `milestone_blocked` (overdue milestone)
- Detects `deadline_overrun` if goal past target date
- Displays blocker details with severity

### TC-21: Velocity and Projection

**Setup:** Goal with 3+ milestones completed over 14+ days

**Expected on /goal:check:**
- Calculates weighted velocity (7d/14d/30d windows)
- Projects completion date
- Displays projected date in output

---

## Graceful Degradation Tests

### TC-GD-01: Notion Unavailable on Create

**Setup:** Disconnect Notion MCP or use invalid API key

**Command:**
```
/goal:create "Test goal"
```

**Expected:**
- Detects Notion unavailability
- Displays goal details in chat format for manual logging
- Does not error or crash

### TC-GD-02: Notion Unavailable on Check

**Setup:** Disconnect Notion MCP

**Command:**
```
/goal:check
```

**Expected:**
- Reports: "Cannot check goals -- Notion is not connected."
- Does not fabricate results

### TC-GD-03: Goal Not Found

**Command:**
```
/goal:update "Nonexistent Goal"
```

**Expected:**
- Reports no match found
- Suggests similar goal names if available
- Offers to create a new goal

---

## Validation Checklist

| # | Test | Status |
|---|------|--------|
| TC-01 | First goal creation with full arguments | ⬜ |
| TC-02 | Interactive goal creation | ⬜ |
| TC-03 | Goal creation without milestones | ⬜ |
| TC-04 | Duplicate goal detection | ⬜ |
| TC-05 | Milestone completion with progress recalculation | ⬜ |
| TC-06 | Manual progress update (no milestones) | ⬜ |
| TC-07 | Manual progress rejected on milestone goal | ⬜ |
| TC-08 | Add milestone to existing goal | ⬜ |
| TC-09 | Status change with lifecycle validation | ⬜ |
| TC-10 | Invalid status transition | ⬜ |
| TC-11 | Goal check - single goal detail | ⬜ |
| TC-12 | Goal check - all goals dashboard | ⬜ |
| TC-13 | Goal report - full dashboard | ⬜ |
| TC-14 | Goal report with filters | ⬜ |
| TC-15 | Goal report to file | ⬜ |
| TC-16 | Goal close - normal completion | ⬜ |
| TC-17 | Goal close - incomplete milestones warning | ⬜ |
| TC-18 | Goal close - force close | ⬜ |
| TC-19 | Goal archive | ⬜ |
| TC-20 | Blocker detection | ⬜ |
| TC-21 | Velocity and projection | ⬜ |
| TC-GD-01 | Graceful degradation: create without Notion | ⬜ |
| TC-GD-02 | Graceful degradation: check without Notion | ⬜ |
| TC-GD-03 | Goal not found handling | ⬜ |
