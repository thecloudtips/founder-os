---
description: Generate a goal progress dashboard with RAG status, blockers, and Gantt timeline
argument-hint: "[--category=CAT] [--status=red|yellow|green|active|all] [--output=chat|notion|file] [--path=PATH]"
allowed-tools: ["Read", "Write"]
---

# /founder-os:goal:report

Generate a comprehensive goal progress dashboard with dashboard table, RAG breakdown, blockers analysis, and Mermaid Gantt timeline.

## Load Skills

Read all three skills:

1. `${CLAUDE_PLUGIN_ROOT}/skills/goal/goal-tracking/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/skills/goal/progress-analysis/SKILL.md`
3. `${CLAUDE_PLUGIN_ROOT}/skills/goal/goal-reporting/SKILL.md`

## Parse Arguments

- `--category=CAT` (optional) — filter by goal category
- `--status=VALUE` (optional) — filter: red, yellow, green, active (In Progress only), all (default)
- `--output=DEST` (optional) — chat (default), notion, file
- `--path=PATH` (optional) — local file path for file output. Default: `goal-report-YYYY-MM-DD.md`
- No positional arguments. If arguments provided that look like a goal name, suggest /founder-os:goal:check instead.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Steps

1. **Verify Notion**: Check connection. Required for this command.

2. **Fetch All Goals**: Query Goals DB for all non-archived goals. Apply filters (--category, --status) using AND logic per filtering rules in goal-reporting skill.

3. **Fetch Milestones**: For each goal with Milestone Count > 0, fetch linked milestones from Milestones DB.

4. **Recompute Analysis**: For each goal, run:
   - Milestone progress formula (if milestones exist)
   - RAG status calculation
   - Velocity projection
   - Blocker detection
   Update the goal pages with fresh RAG Status and Projected Completion values.

5. **Render Dashboard Table**: Build table per dashboard-table-format specification. Read `${CLAUDE_PLUGIN_ROOT}/skills/goal/goal-reporting/references/dashboard-table-format.md` for full formatting rules. Sort by RAG severity.

6. **Render RAG Breakdown**: Group goals by RAG tier. Red first, then Yellow, Green, Not Started. 1-2 sentence analysis per group.

7. **Render Needs Attention**: List goals with active blockers sorted by severity. Include blocker detail and suggested action.

8. **Generate Gantt Timeline**: Build Mermaid gantt chart per gantt-generation specification. Read `${CLAUDE_PLUGIN_ROOT}/skills/goal/goal-reporting/references/gantt-generation.md` for syntax. Group by category, apply color directives.

9. **Output Report**: Based on --output:
   - chat: Display full report in chat with Mermaid in fenced code block
   - notion: Create/update a report page in Notion
   - file: Write to --path (or default path)

10. **Display Summary Stats**:

```
📊 Goal Progress Report — YYYY-MM-DD

🟢 On Track: N  |  🟡 At Risk: N  |  🔴 Behind: N  |  ⚪ Not Started: N

[Dashboard Table]

[RAG Breakdown]

[Needs Attention]

[Gantt Timeline]

Generated from N goals | Use /founder-os:goal:check [name] for detail
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Edge Cases

- 0 goals: "No goals tracked yet. Use /founder-os:goal:create to get started."
- All filtered out: "No goals match the selected filters."
- All completed: Celebration summary
- Goals without target date: Include in table, exclude from Gantt, list in footnote

## Usage Examples

```
/founder-os:goal:report
/founder-os:goal:report --status=red
/founder-os:goal:report --category=Product --output=file --path=q2-goals.md
/founder-os:goal:report --output=notion
```
