---
name: Cross-Plugin Discovery
description: "Discovers and enumerates active Founder OS plugin databases to count task completions for ROI calculations. Activates when the system needs to scan plugins, check usage across the ecosystem, or gather task counts. Iterates across all plugin Notion databases using the HQ consolidation map for accurate cross-plugin metrics."
globs:
  - "founder-os-time-savings-calculator/**"
---

## Purpose

Scan all Founder OS plugin Notion databases to discover which plugins are actively installed and count their completed task records. This skill provides the data gathering layer that feeds into the roi-calculation skill -- it produces raw counts per plugin, not time or dollar savings. The discovery algorithm iterates a plugin registry, searches Notion for each database by name, applies optional date and status filters, and returns a structured array of results with per-plugin status tracking and graceful degradation.

## Plugin Registry

Load the authoritative plugin registry from `${CLAUDE_PLUGIN_ROOT}/config/task-estimates.json`. This file defines all Founder OS plugins that produce trackable Notion database records. Parse the `categories` object where each key is a task category identifier.

Each registry entry contains:

| Field | Type | Purpose |
|-------|------|---------|
| `plugin` | string | Plugin identifier and display name (e.g., "P01 Inbox Zero Commander") |
| `notion_db` | string | Primary Notion database title to search for first (e.g., "[FOS] Tasks") |
| `notion_db_legacy` | string | Legacy Notion database title to fall back to if the consolidated DB is not found |
| `type_filter` | string or null | When non-null, filter records in the consolidated DB by Type property matching this value (e.g., "Email Task") |
| `date_property` | string | Name of the date property used for date-range filtering |
| `count_filter` | object or null | Additional filter to narrow counted records (e.g., Status in ["Done", "Archived"]) |
| `manual_minutes` | number | Estimated manual time per task (consumed by roi-calculation, not this skill) |
| `ai_minutes` | number | Estimated AI-assisted time per task (consumed by roi-calculation, not this skill) |
| `unit` | string | Human-readable unit label (consumed by roi-calculation, not this skill) |
| `description` | string | Task category description |

Only the `plugin`, `notion_db`, `notion_db_legacy`, `type_filter`, `date_property`, and `count_filter` fields are relevant to the discovery algorithm. The time estimate fields (`manual_minutes`, `ai_minutes`, `unit`) belong to the roi-calculation skill and are ignored during discovery.

## Discovery Algorithm

Execute the following procedure for each category entry in the registry. Process categories sequentially to avoid Notion API rate pressure.

### Step 1: Load Registry

Read and parse `${CLAUDE_PLUGIN_ROOT}/config/task-estimates.json`. Extract the `categories` object. Validate that the file contains at least one category entry. If the file is missing or unparseable, abort with error: "Cannot load plugin registry from config/task-estimates.json."

### Step 2: Iterate Categories

For each key-value pair in `categories`, execute Steps 3 through 7.

### Step 3: Search Notion for Database (Consolidated First, Then Legacy Fallback)

Search the Notion workspace for the database using a two-step discovery process:

1. **Try consolidated name first**: Search for a database matching the `notion_db` field value exactly. Use the Notion MCP `notion-search` tool with the database name as the query string. Filter results to object type "database" only. Match by title using case-insensitive exact matching.

2. **Fall back to legacy name**: If no database matches the consolidated `notion_db` name AND `notion_db_legacy` is different from `notion_db`, search for the `notion_db_legacy` name using the same matching rules.

When multiple databases match the same title, select the first result. Notion search returns results ordered by relevance, and exact title matches appear first.

When neither the consolidated nor legacy database is found, record the category with `status: "not_installed"` and `completed_count: 0`. Proceed to the next category immediately -- do not retry or attempt fuzzy matching.

Track which database was found (consolidated or legacy) in the result for diagnostic reporting.

### Step 4: Query Total Record Count

When a matching database is found, query the database to count total records. Use the Notion MCP `notion-fetch` tool to query the database. Construct the filter by combining applicable conditions:

1. **Type filter** (consolidated DB only): If `type_filter` is non-null AND the consolidated database was found (not the legacy DB), add a filter condition for the Type property matching the `type_filter` value. This ensures only the relevant plugin's records are counted when multiple plugins share a consolidated database.

2. **Count filter**: If the `count_filter` field is non-null for this category, apply it as an additional filter condition. For example, when `count_filter` is `{ "property": "Status", "values": ["Done", "Archived"] }`, construct a Notion filter that matches records where the Status property equals any of the specified values.

Combine all applicable filter conditions using AND logic. When no filters apply, count all records in the database.

Record the total count as `completed_count`.

### Step 5: Apply Date Range Filter

When the calling command provides a date range (start date and end date), apply an additional date filter using the category's `date_property` field. Construct a compound Notion filter:

- `date_property` is on or after the start date (inclusive)
- `date_property` is on or before the end date (inclusive)

Combine the date filter with any existing `count_filter` using AND logic. Both conditions must be satisfied for a record to be counted.

Record the filtered count as `filtered_count`.

When no date range is provided by the calling command, set `filtered_count` to 0 and skip date filtering entirely. Return only the `completed_count` (total records).

### Step 6: Handle Date Property Variations

Different plugins use different date property types in Notion (date, created_time, last_edited_time). The `date_property` field in the registry specifies the exact property name. Use this name directly in the Notion filter construction.

When the date property does not exist on the database schema (e.g., the plugin was installed with an older schema version), fall back to the database's built-in `created_time` property for date filtering. Log a warning: "Date property '[name]' not found on [db_name], falling back to created_time."

### Step 7: Record Result

Construct a DiscoveryResult object for the current category and append it to the results array.

### Step 8: Error Handling Per Category

Wrap Steps 3 through 7 in error handling for each category independently. When any step fails for a given category:

1. Record the category with `status: "error"`.
2. Set `completed_count: 0` and `filtered_count: 0`.
3. Capture the error message in `error_message`.
4. Continue to the next category. Never abort the entire discovery loop because of a single category failure.

Common error conditions:
- Notion API timeout: Record status "error", message "Notion API timeout".
- Permission denied on database: Record status "error", message "Permission denied".
- Malformed database response: Record status "error", message "Unexpected response format".

## DiscoveryResult Schema

Each category produces one DiscoveryResult object with the following fields:

```
plugin_number:   string        # Plugin identifier (e.g., "P01")
plugin_name:     string        # Full plugin name (e.g., "Inbox Zero Commander")
db_name:         string        # Notion database name that was actually found and queried
db_source:       string        # "consolidated" or "legacy" indicating which DB name matched
task_category:   string        # Category key from task-estimates.json (e.g., "email_triage")
status:          string        # One of: "found", "not_installed", "error"
completed_count: number        # Total records matching type_filter + count_filter, 0 if not found
filtered_count:  number        # Records within date range, 0 if no date filter applied
error_message:   string | null # Error description if status is "error", null otherwise
```

Extract `plugin_number` by parsing the first token of the `plugin` field (e.g., "P01" from "P01 Inbox Zero Commander"). Extract `plugin_name` by stripping the plugin number prefix and leading space from the `plugin` field.

Set `status` according to these rules:
- `"found"` -- Database exists in the Notion workspace and was successfully queried.
- `"not_installed"` -- No database matching `notion_db` was found. The plugin is either not installed or has not been used yet.
- `"error"` -- Database search or query failed due to an API error, timeout, or permission issue.

## Date Filtering

Apply date range filtering only when the calling command explicitly provides start and end dates. The three commands that invoke this skill pass dates as follows:

- `/savings:weekly` -- Provides a 7-day window (Monday through Sunday of the target week).
- `/savings:monthly-roi` -- Provides a calendar month window (first day through last day of the target month).
- `/savings:quick` -- Provides no date range. Return total counts only.

### Filter Construction

Construct the Notion date filter using the category's `date_property`:

```
{
  "and": [
    {
      "property": "[date_property]",
      "date": { "on_or_after": "[start_date ISO 8601]" }
    },
    {
      "property": "[date_property]",
      "date": { "on_or_before": "[end_date ISO 8601]" }
    }
  ]
}
```

When `count_filter` and/or `type_filter` are also present for the category, nest all applicable filters inside a top-level AND:

```
{
  "and": [
    { date >= start },
    { date <= end },
    { Type == type_filter },       // only when type_filter is non-null AND consolidated DB was found
    { status in [values] }          // only when count_filter is non-null
  ]
}
```

### Timezone Handling

Use the start and end dates as provided by the calling command without timezone conversion. Notion stores dates in UTC. The calling command is responsible for passing UTC-compatible date boundaries.

## Graceful Degradation

Never abort the full discovery scan because a single plugin database is missing or errored. Apply these degradation rules:

### Per-Plugin Resilience

- **Database not found**: Mark `status: "not_installed"`. This is an expected condition -- most users will not have all 24 plugins installed. Not finding a database is informational, not an error.
- **API error on query**: Mark `status: "error"` with the error message. Continue scanning remaining categories.
- **Empty database**: Mark `status: "found"` with `completed_count: 0`. An empty database means the plugin is installed but has no completed tasks yet -- this is valid data.

### Minimum Viability

Require at least 1 category with `status: "found"` to produce useful output. When all categories return `"not_installed"` or `"error"`, report: "No Founder OS plugin databases found in this Notion workspace. Ensure at least one plugin has been used and its Notion database exists."

### Status Summary

After completing all categories, compile a status summary:

```
plugins_found:         N  # Categories with status "found"
plugins_not_installed: N  # Categories with status "not_installed"
plugins_errored:       N  # Categories with status "error"
```

Include the summary in the output so the calling command can report scan coverage to the user.

## Aggregation Output

The final output of the discovery algorithm is a structured object containing the full results array plus summary statistics.

### Output Structure

```
discovery_output:
  results:               # Array of DiscoveryResult objects (one per category)
    - plugin_number: "P01"
      plugin_name: "Inbox Zero Commander"
      db_name: "[FOS] Tasks"
      db_source: "consolidated"
      task_category: "email_triage"
      status: "found"
      completed_count: 147
      filtered_count: 23
      error_message: null
    - plugin_number: "P03"
      plugin_name: "Meeting Prep Autopilot"
      db_name: "Meeting Prep Autopilot - Prep Notes"
      db_source: "legacy"
      task_category: "meeting_prep"
      status: "not_installed"
      completed_count: 0
      filtered_count: 0
      error_message: null
    ...
  summary:
    total_plugins_scanned:  N  # Total categories in registry
    plugins_found:          N  # Databases discovered successfully
    plugins_not_installed:  N  # Databases not found in workspace
    plugins_errored:        N  # Databases that failed during query
    total_completed_tasks:  N  # Sum of completed_count across all found plugins
    total_filtered_tasks:   N  # Sum of filtered_count across all found plugins
    date_range_applied:     boolean  # Whether a date filter was used
    scan_timestamp:         string   # ISO 8601 timestamp of scan completion
```

### Summary Computation

Calculate summary fields after all categories have been processed:

- `total_plugins_scanned` = count of all entries in the `categories` object.
- `plugins_found` = count of results where `status == "found"`.
- `plugins_not_installed` = count of results where `status == "not_installed"`.
- `plugins_errored` = count of results where `status == "error"`.
- `total_completed_tasks` = sum of `completed_count` across all results where `status == "found"`.
- `total_filtered_tasks` = sum of `filtered_count` across all results where `status == "found"` and `filtered_count > 0`.
- `date_range_applied` = `true` if a date range was provided, `false` otherwise.
- `scan_timestamp` = current UTC timestamp in ISO 8601 format.

The roi-calculation skill consumes this output structure directly, joining each DiscoveryResult with the corresponding `manual_minutes` and `ai_minutes` from the registry to compute time and dollar savings.

## Additional Resources

The authoritative plugin registry is maintained at:
`${CLAUDE_PLUGIN_ROOT}/config/task-estimates.json`

This file is the single source of truth for which plugins to scan, which Notion databases to search for, which date properties to filter on, and which count filters to apply. When new plugins are added to the Founder OS ecosystem, add a corresponding entry to this file to include them in time savings discovery.
