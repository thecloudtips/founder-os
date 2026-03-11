---
description: Update goal progress, complete milestones, add notes, or change status
argument-hint: "[goal name] [--progress=N] [--done=MILESTONE] [--add=MILESTONE] [--status=STATUS] [--note=TEXT]"
allowed-tools: ["Read"]
---

# /goal:update

Update an existing goal's progress, milestones, status, or notes. Recalculate RAG status and velocity after changes.

## Load Skills

Read both:
1. `${CLAUDE_PLUGIN_ROOT}/skills/goal-tracking/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/skills/progress-analysis/SKILL.md`

## Parse Arguments

- **goal name** (required positional) — fuzzy match against existing goals. If ambiguous, present numbered list for selection. If empty, prompt.
- `--progress=N` (optional) — manual progress override 0-100. Only valid for goals without milestones.
- `--done=MILESTONE` (optional) — mark named milestone as Done. Set Completed At to today.
- `--add=MILESTONE` (optional) — add a new milestone. Assign next Order number.
- `--status=STATUS` (optional) — change goal status. Validate against lifecycle transitions.
- `--note=TEXT` (optional) — append note to goal's Notes field.
- Multiple flags can combine: `--done=M1 --note="Shipped ahead of schedule"`

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Steps

1. **Verify Notion**: Check connection. If unavailable, display error and stop.

2. **Resolve Goal**: Search Goals DB for matching goal by name. Fuzzy match (case-insensitive substring). If multiple matches, present numbered list. If no match, suggest similar names or offer to create.

3. **Apply Changes** (in this order):
   a. If `--done=MILESTONE`: Find milestone by name under this goal, set Status="Done", set Completed At=today. If milestone not found, list available milestones.
   b. If `--add=MILESTONE`: Create new milestone page linked to this goal. Assign Order = current max Order + 1. Update Milestone Count on goal.
   c. If `--progress=N`: Set Progress to N. Only allowed when Milestone Count = 0 (manual tracking). If milestones exist, reject: "Progress is auto-calculated from milestones. Use --done to complete milestones instead."
   d. If `--status=STATUS`: Validate transition per status lifecycle. Apply if valid. If invalid, display error message from lifecycle reference.
   e. If `--note=TEXT`: Prepend `[YYYY-MM-DD] TEXT` to Notes field.

4. **Recalculate Progress**: If milestones exist, recalculate using milestone progress formula. Append new Progress Snapshot entry.

5. **Auto-Transition Status**: If progress went from 0 to >0 and Status was "Not Started", auto-transition to "In Progress" and set Start Date. If progress = 100% and all milestones Done, auto-transition to "Completed".

6. **Recompute Analysis**: Run RAG status calculation, velocity projection, and blocker detection from progress-analysis skill. Update RAG Status and Projected Completion on the goal page.

7. **Update Goal Page**: Write all changed properties to Notion.

8. **Display Summary**:
```
✅ Goal updated: [Goal Name]

📊 Progress: ███████░░░ 70% (was 50%)
🔴/🟡/🟢 RAG: [Status] (was [Previous])
📅 Projected: [YYYY-MM-DD]
🏁 Milestones: [X/Y completed]

Changes applied:
  • [Milestone "Design mockups" marked Done]
  • [Note added]
  • [etc.]

⚠️ Blockers detected:
  • [blocker detail if any]

Use /goal:check for full status | /goal:report for dashboard
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Graceful Degradation

- Notion unavailable: Error message, stop.
- Goal not found: Suggest similar names, offer to create.
- Invalid milestone name: List available milestones.
- Invalid status transition: Display error with valid options.
- Manual progress on milestone goal: Reject with explanation.

## Usage Examples

```
/goal:update "Launch MVP" --done="Design mockups" --note="Finalized with client approval"
/goal:update "Reach 50K MRR" --progress=35
/goal:update "Hire senior engineer" --add="Post job listing" --add="Screen candidates"
/goal:update "Launch MVP" --status=on-hold --note="Waiting for vendor contract"
```
