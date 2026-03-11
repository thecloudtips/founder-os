---
description: Generate a detailed automation scorecard with recommendations and Notion logging
argument-hint: "[--save-notion] [--compare]"
allowed-tools: ["Read", "Glob", "Bash"]
---

# /audit:report

Generate a detailed automation scorecard from the latest scan, with recommendations and optional Notion persistence.

## Load Skills

Read `_infrastructure/automation-audit/SKILL.md` for scorecard format and Notion output conventions.

## Parse Arguments

- `--save-notion` (optional) — Write report to Notion Reports DB (Type = "Automation Audit")
- `--compare` (optional) — Compare current scan with previous scan to show progress

## Prerequisites

Check if `_infrastructure/automation-audit/last-scan.json` exists. If not, inform user: "No scan data found. Run `/audit:scan` first."

## Steps

### Step 1: Load Scan Data

Read `_infrastructure/automation-audit/last-scan.json`.

### Step 2: Generate Detailed Report

Produce the full scorecard including:
- Header with Plugin Deployment % and Area Coverage %
- Per-area breakdown with progress bars
- Per-plugin status table (all 30 plugins with install/config/active status)
- Top gap recommendations
- Scheduling coverage (how many installed plugins have `--schedule` configured, links to Phase 3)

### Step 3: Compare (if --compare)

If a previous scan exists (check for `last-scan-previous.json`):
- Show delta for each metric (up or down arrow)
- Highlight newly installed plugins since last scan
- Show area coverage changes

### Step 4: Save to Notion (if --save-notion)

Follow SKILL.md Notion output conventions:
1. Search for "[FOS] Reports" using HQ DB discovery
2. Check for existing "Automation Audit — [today's date]" entry
3. If exists: update it (idempotent)
4. If not: create new entry with Type = "Automation Audit"

### Step 5: Archive Current Scan

Copy `last-scan.json` to `last-scan-previous.json` for future comparisons.

## Output Format

```
Founder OS Automation Report — [date]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SUMMARY
  Plugin Deployment: [X]% ([N]/30) [delta if --compare]
  Area Coverage:     [Y]%          [delta if --compare]

COVERAGE BY AREA
  Operations    ████████░░  80%   P01,P02,P04,P05,P06,P19,P22,P27
  Finance       ██████░░░░  60%   P11,P13
  Sales/CRM     █████████░  90%   P06,P10,P12,P15,P20,P21
  Marketing     ███████░░░  70%   P08,P15,P24
  Content       ██████████  100%  P08,P24
  Client Dlvry  ████████░░  80%   P03,P07,P09,P10,P12,P14
  Product/Dev   ██████████  100%  P26
  Admin         ████████░░  80%   P05,P17,P18,P23,P25,P27,P28,P30
  HR/People     ░░░░░░░░░░  0%    (no plugins cover this area)

TOP GAPS
  1. HR/People (0%) — No plugins available. Consider custom workflow via P27.
  2. Finance (60%) — Install P16 Expense Report for +15% coverage.
  3. Operations (80%) — Install P03 Meeting Prep for +10% coverage.

SCHEDULING STATUS
  Scheduled: [N] plugins have active schedules
  Unscheduled: [list of installed schedulable plugins without schedules]
  Run /[command] --schedule "..." to enable scheduling.

ALL PLUGINS
  | # | Plugin | Status | Areas |
  |---|--------|--------|-------|
  (full 30-row table)
```

## Graceful Degradation

- If Notion unavailable for --save-notion: display report in terminal only, warn about Notion
- If no previous scan for --compare: skip comparison, note "first scan"
