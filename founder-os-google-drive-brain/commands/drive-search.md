---
description: Search Google Drive for files with preview snippets
argument-hint: "[query] [--type=docs|sheets|pdf|all] [--in=FOLDER] [--limit=N] [--schedule=EXPR] [--persistent]"
allowed-tools: ["Read"]
---

# Drive Search

Search Google Drive for files matching the user's query. Rank results by relevance, generate preview snippets, and present as a numbered list. Ephemeral output; optional Notion activity logging.

## Load Skills

Read the drive-navigation skill at `${CLAUDE_PLUGIN_ROOT}/skills/drive-navigation/SKILL.md` for search pipeline, query formulation, relevance scoring, folder traversal, and preview generation.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `[query]` (required) -- the search query. This is all non-flag text (the positional argument before any flags). If missing or empty, prompt the user: "What would you like to search for in Google Drive? Usage: `/drive:search [query]`" and stop.
- `--type=TYPE` (optional) -- filter by file type. Accepts: `docs`, `sheets`, `pdf`, `all`. Default: `all`. Map to MIME types: `docs` -> Google Docs, `sheets` -> Google Sheets, `pdf` -> PDF files.
- `--in=FOLDER` (optional) -- scope search to a specific folder. Resolve folder by name using the drive-navigation skill's folder traversal logic. If the value contains spaces, it must be quoted (e.g., `--in="Client Projects"`).
- `--limit=N` (optional) -- maximum number of results to display. Accepts integer 1-20. Default: `10`. If the user provides a value above 20, cap at 20 silently. If below 1, set to 1.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Scheduling Support

If `$ARGUMENTS` contains `--schedule`:
1. Extract the schedule value and any `--persistent` flag
2. Read `_infrastructure/scheduling/SKILL.md` for scheduling bridge logic
3. Read `_infrastructure/scheduling/references/schedule-flag-spec.md` for argument parsing
4. Default suggestion if no expression given: `"0 6 * * *"` (Daily 6:00am)
5. Handle the schedule operation (create/disable/status) per the spec
6. Exit after scheduling — do NOT continue to main command logic

## Step 1: Formulate Queries

Apply the query formulation rules from the drive-navigation skill:
1. Generate 2-3 query variants from the user's query (literal, synonym, broadened).
2. Keep each variant to 2-5 words.
3. Do not generate more than 3 variants.

## Step 2: Execute Search

1. Search Google Drive via gws CLI (`gws drive files list --params '{"q":"QUERY"}' --format json`) with each query variant.
2. If `--type` is set to anything other than `all`, filter results to that specific file type using the MIME type mapping above.
3. If `--in` is specified, resolve the folder name to a folder ID using the drive-navigation skill's folder traversal. Scope the search to that folder and its subfolders.
4. Deduplicate results across query variants by file ID. Keep the first occurrence.
5. Cap the combined result set at 20 results before scoring.

## Step 3: Score and Rank

Apply 3-factor relevance scoring from the drive-navigation skill:
1. **Keyword Density** (0-40) -- key term presence in file name and content snippet.
2. **Title Match** (0-30) -- how closely the file name matches the query intent.
3. **Recency** (0-30) -- freshness based on last modified date.

Sum the three factors for a composite score (0-100). Sort results by composite score descending. Take the top `--limit` results.

## Step 4: Generate Previews

For each result up to `--limit`:
1. Generate a 500-character preview following the preview rules from the drive-navigation skill:
   - Use the first meaningful content from the document body.
   - Skip titles, metadata, headers, and blank lines.
   - Truncate at the last word boundary before 500 characters and append "..." if needed.
   - Strip formatting artifacts from the preview text.
2. Determine the freshness tier for display:
   - 0-29 days since last modified: "Fresh"
   - 30-89 days: "Current"
   - 90-179 days: "Aging"
   - 180+ days: "Stale"
3. Build the folder breadcrumb path for each file (e.g., "My Drive > Clients > Phoenix > Proposals").

## Step 5: Notion Logging (Optional)

If Notion MCP is available:
1. Search for a database titled "[FOS] Activity Log". If not found, try "Founder OS HQ - Activity Log". If not found, fall back to "Google Drive Brain - Activity".
2. If none is found, skip Notion logging silently and proceed with user-facing output. Do not create the database. If found, log with these properties:
   - Query (title) -- the search query
   - Command Type (select: search, summarize, ask, organize) -- set to "search"
   - Files Found (number) -- total result count
   - Top Result (rich_text) -- title of the highest-scoring file
   - File IDs (rich_text) -- comma-separated Drive file IDs of top results
   - Folder Context (rich_text) -- folder scope if `--in` was used, empty otherwise
   - Sources Used (multi_select: Google Drive, Notion) -- set to "Google Drive"
   - Company (relation) -- if the top result's file path or name matches a known client from [FOS] Companies, set the Company relation to that record. See drive-navigation skill's Company Detection rules.
   - Generated At (date) -- current timestamp
3. Check for an existing entry with the same Query value and today's calendar date. If found, update it (idempotent). If not, create a new entry.
4. If any step fails, continue silently. Notion logging must never block the user-facing output.

If Notion MCP is not available, skip this step entirely without any message.

## Step 6: Output

Display the results in this exact format:

### Results Found

```
## Drive Search: [query]

**Scope**: [All Drive | Folder: breadcrumb/path] | **Type**: [all | docs | sheets | pdf] | **Results**: [count] files

---

1. **[Filename]** ([type label] · [freshness])
   [folder breadcrumb path]
   [500-char preview text...]
   _Score: [XX]/100 · Last modified: [YYYY-MM-DD] · [Drive URL]_

2. **[Filename]** ([type label] · [freshness])
   [folder breadcrumb path]
   [500-char preview text...]
   _Score: [XX]/100 · Last modified: [YYYY-MM-DD] · [Drive URL]_

...

---
*Search powered by Google Drive Brain*
```

**Scope** reflects the actual search scope:
- If no `--in` flag: "All Drive"
- If `--in` was specified and resolved: "Folder: [breadcrumb path]"
- If `--in` was specified but not found (fell back to all): "All Drive (folder '[name]' not found)"

**Type labels** for display: Google Docs -> "Doc", Google Sheets -> "Sheet", PDF -> "PDF", Google Slides -> "Slides", Google Forms -> "Form", other -> the MIME type short name.

**Results count** is the total number of scored results before applying `--limit`. The displayed list is capped at `--limit`.

### No Results Found

```
## Drive Search: [query]

**Scope**: [scope] | **Type**: [type] | **Results**: 0 files

No files found matching "[query]". Suggestions:
- Try broader search terms (query variants tried: [variant1], [variant2], [variant3])
- Remove the --type filter to search all file types
- Remove the --in filter to search all of Drive

---
*Search powered by Google Drive Brain*
```

## Graceful Degradation

**Google gws CLI (Drive) unavailable**: Stop execution immediately. Display:
"gws CLI (`gws drive`) is not connected. Install it per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`:
1. Set `GOOGLE_CREDENTIALS_PATH` and `GOOGLE_TOKEN_PATH` environment variables
2. Restart Claude Code and run `/drive:search` again"

**Folder not found** (when `--in` is specified): Do not stop. Display a warning and fall back to searching all of Drive:
"Folder '[name]' not found in Drive. Searching all of Drive instead."
Then execute the search without folder scope.

**Notion MCP unavailable**: Skip activity logging silently. Do not mention Notion in the output.

**Partial failures**: If one query variant fails but others succeed, continue with the successful results. Do not surface individual query errors to the user.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/drive:search quarterly report
/drive:search budget --type=sheets
/drive:search proposal --in="Client Projects" --limit=5
/drive:search SOW Phoenix --type=pdf
/drive:search onboarding checklist --type=docs --in="HR" --limit=3
```
