---
description: View execution history and status of workflow runs
argument-hint: "[workflow-name] [--last=N] [--status=completed|failed|partial]"
allowed-tools: ["Read"]
---

# /founder-os:workflow:status

View execution history for workflows from the Notion execution log.

## Load Skills

Read: `${CLAUDE_PLUGIN_ROOT}/skills/workflow/workflow-execution/SKILL.md`

## Parse Arguments

- **workflow-name** (optional positional) — filter by specific workflow name
- `--last=N` (optional) — show last N executions (default: 5, max: 20)
- `--status=VALUE` (optional) — filter: completed, failed, partial, running

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Steps

1. **Check Notion**: Verify Notion MCP is available. If unavailable:
   ```
   Notion is not available. Execution history requires Notion.
   Run /founder-os:workflow:run to execute workflows — results display in chat regardless of Notion status.
   ```

2. **Query Executions DB**: Search for a database titled "[FOS] Workflows" first. If not found, try "Founder OS HQ - Workflows". If not found, fall back to "Workflow Automator - Executions" (legacy). If no DB exists, display: "No execution history yet. Run a workflow with /founder-os:workflow:run first." When querying the consolidated DB, filter by Type="Execution" to exclude SOP records.

3. **Apply Filters**: Filter by workflow name (if provided) and status (if provided). Sort by Started At descending. Limit to --last count.

4. **Display Results**:

```
Workflow Execution History
━━━━━━━━━━━━━━━━━━━━━━━━━━

morning-routine v1.0.0
  [Mar 07 09:01] Completed — 4/4 steps (2m 34s)
  [Mar 06 09:00] Completed — 4/4 steps (2m 12s)
  [Mar 05 09:02] Failed at step 'generate-briefing' — 2/4 steps (1m 45s)

weekly-review v1.2.0
  [Mar 07 17:00] Partial — 4/6 steps, 1 failed, 1 skipped (5m 20s)

━━━━━━━━━━━━━━━━━━━━━━━━━━
Showing last 5 runs | Use --last=N for more
```

5. **Empty State**: "No matching executions found."

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/founder-os:workflow:status
/founder-os:workflow:status morning-routine
/founder-os:workflow:status --status=failed --last=10
/founder-os:workflow:status weekly-review --last=3
```
