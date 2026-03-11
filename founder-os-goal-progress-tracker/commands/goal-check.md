---
description: Quick status check for a single goal or all goals (read-only, no Notion writes)
argument-hint: "[goal name]"
allowed-tools: ["Read"]
---

# /goal:check

Ephemeral read-only status check. Never write to Notion. Two modes: single-goal detail view, or all-goals compact dashboard.

## Load Skills

Read:
1. `${CLAUDE_PLUGIN_ROOT}/skills/goal-tracking/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/skills/progress-analysis/SKILL.md`

## Parse Arguments

- **goal name** (optional positional) — if provided, show single-goal detail view. Fuzzy match.
- No flags. This command has no options — it's intentionally simple.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Mode 1: Single-Goal Detail (when goal name provided)

1. Search Goals DB for matching goal. Fuzzy match. If ambiguous, present selection list.
2. Fetch linked milestones from Milestones DB.
3. Compute RAG, velocity, projected completion, and blockers (do NOT write results back to Notion).
4. Display detailed view:

```
🎯 [Goal Name]
📂 [Category] | 📅 Target: [YYYY-MM-DD] | Status: [Status]

📊 Progress: ███████░░░ 70%
🟡 RAG: At Risk (gap: -15)
📈 Velocity: 3.2%/day | Projected: YYYY-MM-DD

🏁 Milestones (X/Y):
  ✅ Milestone 1 (completed YYYY-MM-DD)
  ✅ Milestone 2 (completed YYYY-MM-DD)
  🔄 Milestone 3 (in progress, due YYYY-MM-DD)
  ⬜ Milestone 4 (not started, due YYYY-MM-DD)
  🚫 Milestone 5 (skipped)

⚠️ Blockers:
  • [critical] Deadline overrun: target was YYYY-MM-DD
  • [high] Milestone "X" overdue by N days

📝 Recent Notes:
  [YYYY-MM-DD] Latest note...
  [YYYY-MM-DD] Previous note...
```

Milestone status icons: ✅ Done, 🔄 In Progress, ⬜ Not Started, 🚫 Skipped

## Mode 2: All-Goals Dashboard (when no goal name)

1. Fetch all non-archived goals from Goals DB.
2. Compute RAG for each (read-only, don't write back).
3. Display compact dashboard table (same format as goal-report but without Gantt):

```
📊 Goal Status Overview

| Goal | Category | Progress | RAG | Target Date | Status |
|:---|:---|:---:|:---:|:---:|:---|
| Launch MVP | Product | ███████░░░ 70% | 🟡 | 2026-06-30 | In Progress |
| Reach 50K MRR | Revenue | ██░░░░░░░░ 20% | 🔴 | 2026-12-31 | In Progress |
...

🟢 N on track | 🟡 N at risk | 🔴 N behind | ⚪ N not started

Use /goal:check [name] for details | /goal:report for full dashboard
```

## Key Constraint

**NEVER write to Notion.** This command is purely read-only. All computations (RAG, velocity, blockers) are calculated in-memory for display only. Use /goal:report to persist updated analysis.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Edge Cases

- 0 goals: "No goals tracked yet. Use /goal:create to get started."
- Goal not found: Suggest similar names
- Notion unavailable: "Cannot check goals — Notion is not connected."

## Usage Examples

```
/goal:check "Launch MVP"
/goal:check
```
