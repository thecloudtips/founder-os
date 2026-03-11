---
description: Scan which Founder OS plugins are installed and produce a deployment coverage report
argument-hint: "[--notion] [--json]"
allowed-tools: ["Read", "Glob", "Bash"]
---

# /audit:scan

Detect which of the 30 Founder OS plugins are installed and configured, then produce a coverage report.

## Load Skills

Read `_infrastructure/automation-audit/SKILL.md` for detection logic and scoring methodology.

## Parse Arguments

- `--notion` (optional) — Also check Notion for active database usage (requires Notion MCP)
- `--json` (optional) — Output raw JSON instead of formatted scorecard

## Steps

### Step 1: Load Registry

Read `_infrastructure/automation-audit/schema/audit-registry.json` to get the list of all 30 plugins and their detection criteria.

### Step 2: Scan Filesystem

For each plugin in the registry:
1. Use Glob to check if `[directory]/.claude-plugin/plugin.json` exists
2. Record status: "installed" or "not_found"

### Step 3: Check Configuration (for installed plugins)

For each installed plugin:
1. Check if `[directory]/.mcp.json` exists (if plugin requires MCP servers)
2. Record: "configured" or "installed_unconfigured"

### Step 4: Check Notion (if --notion)

For each installed plugin that has a `notion_db` in its detection config:
1. Search Notion for the database name using HQ discovery pattern
2. If found and has recent entries (last 30 days): "active"
3. If found but no recent entries: "configured"
4. If not found: keep current status

### Step 5: Calculate Scores

Per SKILL.md scoring methodology:
- Plugin Deployment %
- Per-area Coverage %
- Overall weighted Area Coverage %

### Step 6: Output

If `--json`: output raw JSON with all plugin statuses and scores.

Otherwise, display the formatted scorecard per SKILL.md format. Include:
- Deployment and coverage percentages
- Per-area bar chart
- Top 3 gap recommendations (areas with lowest coverage, suggesting specific plugins)

### Step 7: Save Results

Write results to `_infrastructure/automation-audit/last-scan.json` for use by `/audit:report`.

## Graceful Degradation

- If `--notion` but Notion MCP unavailable: skip Notion checks, warn user, continue with filesystem-only scan
- If a plugin directory exists but plugin.json is missing: count as "partial_install"
