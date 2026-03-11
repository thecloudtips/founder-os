---
description: Close or archive a goal with completion summary
argument-hint: "[goal name] [--archive] [--force] [--note=TEXT]"
allowed-tools: ["Read"]
---

# /goal:close

Close a goal as completed or archive it. Validate milestone completion, warn about incomplete work, generate final summary.

## Load Skills

Read `${CLAUDE_PLUGIN_ROOT}/skills/goal-tracking/SKILL.md`

## Parse Arguments

- **goal name** (required positional) — fuzzy match. If empty, prompt.
- `--archive` (optional flag) — archive instead of completing. Sets Status to "Archived" instead of "Completed".
- `--force` (optional flag) — skip incomplete milestone warning. Close without confirmation.
- `--note=TEXT` (optional) — closing note appended to Notes field.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Steps

1. **Verify Notion**: Check connection. Required.

2. **Resolve Goal**: Search Goals DB. Fuzzy match. If ambiguous, present selection. If not found, suggest similar.

3. **Validate Status**: Check current status against lifecycle transitions (goal-tracking skill reference `references/status-lifecycle.md`):
   - If already Completed: "This goal is already completed (closed on YYYY-MM-DD)."
   - If already Archived: "This goal is already archived. Use --reopen to restore."
   - If Not Started and not --archive: "Cannot complete a goal that hasn't started. Update progress first or use --archive."

4. **Check Incomplete Milestones**: Fetch milestones for this goal. Count milestones with Status != "Done" and Status != "Skipped".
   - If incomplete milestones exist AND --force not provided:
     ```
     ⚠️ This goal has N incomplete milestone(s):
       🔄 Milestone A (in progress)
       ⬜ Milestone B (not started)

     Close anyway? Use --force to skip this check, or complete milestones first with /goal:update --done="name".
     ```
     Wait for confirmation before proceeding.
   - If --force provided, skip warning and proceed.

5. **Close the Goal**:
   - If --archive: Set Status = "Archived". Leave Progress as-is.
   - If not --archive: Set Status = "Completed". Set Progress = 100.
   - Append to Notes: `[YYYY-MM-DD] Goal [completed/archived]. [--note text if provided]`
   - If incomplete milestones and closing anyway: `[YYYY-MM-DD] Goal closed with N incomplete milestone(s).`

6. **Calculate Duration**: Compute days from Start Date (or Created At) to today.

7. **Display Final Summary**:
```
✅ Goal [completed/archived]: [Goal Name]

📊 Final Progress: ██████████ 100% (or current % if archived)
📂 Category: [Category]
📅 Duration: N days (Start → Today)
🏁 Milestones: X/Y completed [Z skipped]

📝 Closing note: [note text or "None"]

🎉 [If completed: "Congratulations! Goal achieved."]
[If archived: "Goal archived. It won't appear in future reports."]

Use /goal:report for updated dashboard
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Edge Cases

- Already closed/archived: Inform, no action
- All milestones already Done: Close smoothly, no warning
- 0 milestones: Close smoothly
- Goal with active blockers: Warn but allow close with --force
- Archived → reopen not handled here (future enhancement, display message)

## Usage Examples

```
/goal:close "Launch MVP" --note="Shipped successfully to 50 beta users"
/goal:close "Old Q1 initiative" --archive
/goal:close "Hire engineer" --force --note="Position deprioritized"
```
