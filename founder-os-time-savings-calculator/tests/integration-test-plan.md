# Integration Test Plan: Time Savings Calculator (P25)

## Prerequisites

- Notion MCP configured with API key
- Filesystem MCP configured
- At least 2-3 other Founder OS plugins installed with Notion databases containing records
- `config/task-estimates.json` present with valid category registry

## /savings:quick Tests

### Input Handling

1. **Default lookback**: `/savings:quick` -- produces compact chat summary for last 7 days
2. **Custom lookback (days)**: `/savings:quick --since=30d` -- captures wider date range, higher task counts than 7d
3. **Custom lookback (date)**: `/savings:quick --since=2026-01-01` -- uses absolute start date, end date is today
4. **No Notion MCP**: Run with Notion unavailable -- displays "Notion unavailable" error and stops
5. **No plugins found**: Run against empty Notion workspace -- displays "No Founder OS plugin databases found" message

### Output Format

6. **Compact format**: Output matches quick summary format -- hours saved, work days, top savers list, active plugins count
7. **Top savers table**: Top 3 categories listed by time_saved_hours descending, remaining shown as "+N more categories"
8. **Rate=0 no dollars**: Configure rate=0 in user-config.json, run quick -- no dollar figures appear anywhere in output
9. **Footer prompt**: Output ends with "For full report: /savings:weekly" and "Configure: /savings:configure"
10. **Zero tasks in range**: Run with `--since=1d` when no recent tasks exist -- displays "No tasks recorded in the last 1 days" message

### Configuration

11. **Missing user-config.json**: Delete user-config.json, run quick -- uses $150/hr default silently, no error
12. **User override applied**: Set custom manual_minutes for a category in user-config.json -- quick output reflects overridden estimate

## /savings:weekly Tests

### Report Generation

13. **Current week report**: `/savings:weekly` -- generates 6-section Markdown report, saves file to default path, creates Notion record
14. **Specific week**: `/savings:weekly --week=2026-W09` -- resolves to correct Monday-Sunday boundaries, report title reflects "Week 9, 2026"
15. **Partial week note**: Run mid-week without --week -- report notes "partial week" in output
16. **Mermaid pie chart**: Report contains valid `pie title` Mermaid syntax with top 5 categories + "Other" rollup

### Output Routing

17. **Default (both)**: File saved to `savings-reports/` AND Notion record created
18. **File only**: `--format=file` -- file created, no Notion record
19. **Notion only**: `--format=notion` -- Notion record created, no file saved
20. **Custom output path**: `--output=./custom-report.md` -- file saved at specified path

### Notion Integration

21. **DB discovery with fallback**: Delete "[FOS] Reports" and "Founder OS HQ - Reports" from Notion, ensure legacy "Time Savings Calculator - Reports" exists -- run weekly -- falls back to legacy DB. Delete all three -- run weekly -- Notion output skipped (no DB auto-created)
22. **Idempotent re-run**: Run same week twice on same day -- existing Notion record updated, not duplicated
23. **Report properties**: Notion record includes Report Title, Type="ROI Report" (consolidated DB), Report Type="Weekly", Date Range, Total Hours Saved, Dollar Value, Tasks Automated, Active Plugins, Top Category, Report File, Generated At

### Configuration Prompts

24. **First-run rate prompt**: Delete user-config.json, run weekly -- AskUserQuestion prompts for hourly rate
25. **Rate prompt saves config**: Enter rate at prompt -- user-config.json created with provided rate
26. **Rate prompt default**: Press Enter at rate prompt -- uses $150/hr default

## /savings:monthly-roi Tests

### Report Generation

27. **Default 3-month report**: `/savings:monthly-roi` -- produces report covering current month and 2 prior months
28. **Custom month count**: `/savings:monthly-roi --months=6` -- covers 6 months of data
29. **Specific end month**: `/savings:monthly-roi 2026-02` -- report ends at February 2026, goes back 3 months by default
30. **Month boundaries**: Verify each month uses first day through last day (e.g., Feb 1-28)

### Period-Over-Period Analysis

31. **Change labels**: Consecutive months with >50% increase show "Significant increase" flag
32. **Stable label**: Months within -20% to +20% show "Stable" flag
33. **Decline labels**: Months with >20% decrease show "Notable decrease" flag
34. **New category**: Category appearing for the first time shows "New" flag
35. **Eliminated category**: Category disappearing shows "Eliminated" flag

### Charts and Projections

36. **Mermaid bar chart**: Report contains valid `xychart-beta` syntax with monthly x-axis labels
37. **Dollar value chart**: When hourly_rate > 0, a second chart for dollar values is generated
38. **Annualized projections**: Projections section shows monthly_avg x 12 calculation with confidence note
39. **Confidence note**: Report includes "Based on [N] months of data" disclaimer

### Edge Cases

40. **Single month**: `/savings:monthly-roi --months=1` -- generates report without trend analysis, notes "Insufficient data for trend analysis"
41. **Months with no data**: Empty months appear as zero-value rows, noted as "No data"
42. **Months exceeding available data**: Request 6 months when only 3 have data -- reports "Data available for 3 of 6 requested months"

### Output Routing

43. **Default (both)**: File saved AND Notion record created with Type="ROI Report" and Report Type="Monthly ROI"
44. **File only**: `--format=file --output=./reports/q1-roi.md` -- saves to custom path, no Notion
45. **Idempotent re-run**: Run same end-month twice on same day -- Notion record updated, not duplicated

## /savings:configure Tests

### Initial Setup

46. **Fresh configuration**: Delete user-config.json, run `/savings:configure` -- prompts for rate, offers category customization, creates file
47. **Current config display**: Run with existing config -- shows current rate, currency, override count, last updated

### Rate Configuration

48. **Direct rate set**: `/savings:configure --rate=200` -- updates rate to 200 without interactive prompt
49. **Interactive rate set**: Run without --rate -- AskUserQuestion prompts for rate
50. **Rate=0 disable**: `/savings:configure --rate=0` -- disables dollar calculations in all subsequent commands
51. **Empty rate input**: Press Enter at rate prompt with existing rate -- keeps current rate unchanged

### Category Customization

52. **Offer customization**: After rate setup, prompted "Would you like to customize time estimates?" (y/n)
53. **Category table display**: Say yes -- displays all 24 categories with current manual/ai minutes and Source column
54. **Override a category**: Enter category key, provide new manual_minutes and ai_minutes -- saved to overrides
55. **Validation: ai >= manual**: Try setting ai_minutes > manual_minutes -- rejected with explanation, re-prompted
56. **Multiple overrides**: Customize 2+ categories in sequence, say "done" -- all saved
57. **Custom marker**: Overridden categories show "(custom)" in the estimates table

### Reset

58. **Reset overrides**: `/savings:configure --reset` -- overrides object removed, rate and currency preserved
59. **Reset confirmation**: Output confirms "Reset N custom overrides to defaults. Hourly rate unchanged."

### File Output

60. **Config file schema**: Verify user-config.json contains hourly_rate, currency, configured_at, and overrides object
61. **Configured_at timestamp**: Verify configured_at updates on each save

## Cross-Plugin Discovery Edge Cases

### Plugin Coverage

62. **Mixed plugin states**: Some plugins installed, some not -- report shows found/not_installed/error counts accurately
63. **Plugin with count_filter**: Plugins like P01 (Status in ["Done", "Archived"]) only count filtered records, not all records
64. **Empty Notion DB**: Plugin DB exists with 0 records -- status "found", completed_count 0, excluded from report as inactive
65. **Date property fallback**: Plugin DB missing expected date_property -- falls back to created_time with warning logged
66. **Consolidated DB with Type filter**: When "[FOS] Tasks" exists, P01 scans with Type="Email Task" filter, P04 with Type="Action Item", P06 with Type="Follow-Up" -- each returns only its own records
67. **Legacy DB fallback**: When consolidated DB is not found, falls back to legacy DB name (e.g., "Inbox Zero - Action Items") without Type filter
68. **Consolidated DB discovery order**: Consolidated name is always tried before legacy name; if consolidated exists, legacy is not searched

### Error Resilience

66. **Single plugin API error**: One database query fails -- marked status "error", remaining plugins continue scanning
67. **All plugins not installed**: No databases found -- "No Founder OS plugin databases found" message
68. **Sequential processing**: Categories processed sequentially (not parallel) to avoid Notion API rate pressure

## Report Quality Checks

### Calculation Accuracy

69. **Hours formula**: Verify: (manual_minutes - ai_minutes) x count / 60 matches reported time_saved_hours per category
70. **Dollar formula**: Verify: time_saved_hours x hourly_rate matches reported dollar_value per category
71. **ROI multiplier**: Verify: manual_minutes / ai_minutes matches reported roi_multiplier per category
72. **Equivalent work days**: Verify: total_hours_saved / 8 matches reported equivalent_work_days
73. **Efficiency gain pct**: Verify: ((manual - ai) / manual) x 100 matches reported percentage

### Report Formatting

74. **Rate gate weekly**: When rate=0, weekly report omits Dollar Value line from Executive Summary and Value column from Category Breakdown
75. **Rate gate monthly**: When rate=0, monthly-roi report omits dollar chart and dollar projection lines
76. **Chart data rounding**: All Mermaid chart values rounded to one decimal place
77. **Category labels**: Chart labels use shortened 2-3 word names from task-estimates.json description field
78. **Zero-data chart omission**: When total_hours_saved is 0, Trend Visualization section omitted entirely

## Cross-Cutting Tests

### Consistency

79. **Skill loading**: All 4 commands read both skills before execution (cross-plugin-discovery + roi-calculation)
80. **Task estimates loaded**: All 4 commands load config/task-estimates.json as the plugin registry
81. **PLUGIN_ROOT paths**: All file paths in commands and skills use `${CLAUDE_PLUGIN_ROOT}` prefix

### Graceful Degradation

82. **Notion required**: All 4 commands fail gracefully when Notion MCP unavailable -- clear error, no crash
83. **Filesystem unavailable on weekly**: Skips file output, outputs report to chat, skips Notion file path field
84. **Filesystem unavailable on monthly-roi**: Same behavior as weekly -- chat output fallback
85. **user-config.json write fails**: weekly/monthly-roi continue with defaults, note in output

## Acceptance Criteria Mapping

| Acceptance Criterion | Covered By |
|---------------------|------------|
| `/savings:weekly` generates weekly report | Tests 13-26 |
| `/savings:monthly-roi` generates management report | Tests 27-45 |
| Uses task type estimates for calculations | Tests 69-73, 52-57 |
| Shows hours saved, $ value, productivity gain % | Tests 6, 13, 27, 69-73 |
| Compares actual vs. estimated time | Tests 54-57 (custom overrides) |
| Visualizes trends over time | Tests 16, 36-37 |
