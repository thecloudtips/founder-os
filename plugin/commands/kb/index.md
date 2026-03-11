---
description: Discover and catalog all knowledge sources from Notion and Google Drive into a searchable index with content classification, freshness tracking, and keyword extraction
argument-hint: "[--scope=notion|drive|all] [--folder=PATH]"
allowed-tools: ["Read"]
---

# Knowledge Base Index

Crawl the Notion workspace and Google Drive to build a structured catalog of all available knowledge sources. For each source, extract metadata, classify content into the 9-type taxonomy, compute freshness tiers, extract topic keywords, and write results to the "[FOS] Knowledge Base" Notion database (with Type="Source"). Falls back to "Founder OS HQ - Knowledge Base", then legacy "Knowledge Base Q&A - Sources" if the consolidated database is not found. The index powers `/founder-os:kb:ask` and `/founder-os:kb:find` for fast retrieval without re-scanning on every query.

## Load Skills

Read the source-indexing skill at `${CLAUDE_PLUGIN_ROOT}/skills/kb/source-indexing/SKILL.md` for the full source discovery pipeline, 9-type content classification taxonomy, metadata extraction schema, freshness tier calculation, keyword extraction methodology, and Notion DB output logic.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `--scope=notion|drive|all` (optional) — which platforms to scan. Default: `all`.
  - `notion` — scan Notion pages and databases only.
  - `drive` — scan Google Drive documents only.
  - `all` — scan both Notion and Google Drive.
- `--folder=PATH` (optional) — scope Google Drive discovery to a specific folder path. Only applies when scope includes Drive. Ignored when scope is `notion`.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Step 1: Validate MCP Availability

Before scanning, verify required MCP connections:

1. **Notion MCP** (always required): Attempt a `notion-search` call. If unavailable, stop execution. Display:
   "Notion MCP server is not connected. Notion is required for both source discovery and index storage. Install it per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`:
   1. Set `NOTION_API_KEY` with an integration that has access to your workspace
   2. Add `@modelcontextprotocol/server-notion` to your MCP configuration"

2. **gws CLI** (required only when scope includes Drive): Check availability with `which gws`. If unavailable and scope is `all`, log "Google Drive unavailable -- indexing Notion sources only." and continue with Notion-only scanning. If unavailable and scope is `drive`, stop with: "gws CLI is not available or not authenticated and --scope=drive was specified. Install gws CLI and run `gws auth login` per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`, or use --scope=notion."

## Step 2: Discover Sources

Apply the source-indexing skill's discovery pipeline. Track counts as scanning proceeds.

### Phase 1: Notion Discovery (when scope includes `notion` or `all`)

1. Search for all accessible pages via `notion-search` with `filter.property: "object"`, `filter.value: "page"`. Paginate through all results using `start_cursor` until `has_more` is false. Cap at 500 pages.
2. Search for all accessible databases via `notion-search` with `filter.property: "object"`, `filter.value: "database"`.
3. Display progress every 10 pages: "Discovering sources... [N] found so far"
4. When 500-page cap is reached, warn: "Reached 500-page limit. Indexed the 500 most recently edited pages. Re-run with specific parent filters to index additional sections."

### Phase 2: Google Drive Discovery (when scope includes `drive` or `all`)

Execute only when gws CLI is available (check with `which gws`).

1. Search for Google Docs, PDFs, and Spreadsheets using three targeted `mimeType` queries via Bash:
   ```bash
   gws drive files list --params '{"q":"mimeType='\''application/vnd.google-apps.document'\'' and trashed=false","pageSize":200,"fields":"files(id,name,mimeType,modifiedTime,webViewLink)"}' --format json
   ```
   Repeat for `application/pdf` and `application/vnd.google-apps.spreadsheet`.
2. If `--folder` is provided, scope all searches to that folder path by adding `and '\''FOLDER_ID'\'' in parents` to the query.
3. Cap at 200 files total across all searches. Skip files in Trash.
4. Display progress: "Scanning Google Drive... [N] files found"

If gws CLI returns errors mid-scan, stop Drive scanning, keep whatever Drive results were collected, and continue to the next step. Log: "Drive scan interrupted -- [N] files indexed before error."

## Step 3: Extract Metadata

For each discovered source, extract the metadata fields defined in the source-indexing skill:

1. **Source Title**: Page title property or file name. Max 200 characters, truncate with "...".
2. **URL**: Notion page URL (construct from page ID) or Drive `webViewLink`. This is the idempotent key.
3. **Source Type**: "Notion Page", "Notion Database", or "Google Drive".
4. **Last Edited**: `last_edited_time` (Notion) or `modifiedTime` (Drive) as ISO 8601.
5. **Parent Location**: Breadcrumb path from parent property (Notion) or folder path (Drive).
6. **Word Count**: Approximate word count from content. 0 for databases and empty pages.
7. **Content**: Retrieve the first 3000 characters via `notion-fetch` for Notion pages (for classification and keyword extraction). For Drive files, use title and folder context only.

Display progress every 10 sources: "Extracting metadata... [N] of [total] sources processed"

When a source returns a permission error or 404 during metadata extraction, set Status to "Error", record whatever metadata was available from the search result, and continue with the next source.

## Step 4: Classify Content

Apply the source-indexing skill's 9-type classification taxonomy to each source using first-match-wins priority:

1. **Title pattern matching** — match against known patterns per classification type (consult `${CLAUDE_PLUGIN_ROOT}/skills/kb/source-indexing/references/content-classification.md`).
2. **Content structure analysis** — analyze the first 3000 characters for structural signals (headings, lists, Q&A patterns, step numbering).
3. **Parent location heuristics** — use parent page or folder name as classification hint.

Special rules:
- Notion databases are always classified as `database` regardless of title or parent.
- When all three layers are inconclusive, assign `other`.
- Sources with Status "Error" skip classification (leave empty).

## Step 5: Compute Freshness

Calculate the freshness tier for each source based on elapsed time since `Last Edited`:

- **Fresh**: 0-29 days since edit
- **Current**: 30-89 days since edit
- **Aging**: 90-179 days since edit
- **Stale**: 180+ days since edit

Recalculate freshness on every run. Never cache freshness from a previous index -- it is always relative to today's date.

## Step 6: Extract Keywords

Extract 5-8 topic keywords from each source's content using the source-indexing skill's keyword extraction method:

1. Tokenize the first 3000 characters of content. Remove stop words.
2. Count word frequency. Words in headings carry 2x weight.
3. Select top 5-8 words by weighted frequency.
4. Store as comma-separated string.

For pages with fewer than 50 words of content, extract keywords from the title only. For databases, extract keywords from the database title and property names.

## Step 7: Write to Notion

Write all indexed sources to the Notion database.

### Database Discovery

Discover the target database using the consolidated name first, then fall back to legacy:
1. Search Notion for a database titled "[FOS] Knowledge Base". If found, use it.
2. If not found, try "Founder OS HQ - Knowledge Base". If found, use it.
3. If not found, search for "Knowledge Base Q&A - Sources". If found, use it.
4. If none is found, skip Notion writing entirely (do NOT create the database). Display: "No Knowledge Base database found in Notion. Index results not saved." and output summary to chat only.

When writing to the consolidated "[FOS] Knowledge Base" or "Founder OS HQ - Knowledge Base" database, always set the **Type** property to `"Source"` to distinguish indexed source records from query records.

### Record Properties

   - Source Title (title)
   - Type (select) -- "Source" (set when using consolidated DB)
   - URL (url)
   - Source Type (select: Notion Page, Notion Database, Google Drive)
   - Classification (select: wiki, meeting-notes, project-docs, process, reference, template, database, archive, other)
   - Topic Keywords (rich_text)
   - Word Count (number)
   - Last Edited (date)
   - Freshness (select: Fresh, Current, Aging, Stale)
   - Parent Location (rich_text)
   - Status (select: Active, Archived, Error)
   - Indexed At (date)

### Idempotent Updates

For each source in the current scan:
1. Search the Sources DB for a record with a matching URL.
2. If a match exists, update the existing record with new metadata. Count as "updated".
3. If no match exists, create a new record. Count as "new".

### Soft-Delete Removed Sources

After processing all sources from the current scan:
1. Query the Sources DB for all records with Status = "Active".
2. Compare against the URLs discovered in this run.
3. For any Active record whose URL was NOT found in this scan, set Status to "Archived". Count as "archived".
4. Do not delete these records -- preserve them as historical entries.

Display progress during writes: "Writing to Notion... [N] of [total] sources saved"

## Step 8: Output Summary

Display the final summary report:

```
## Knowledge Base Index Complete

**Sources indexed**: [total] ([new] new, [updated] updated, [archived] archived)
**Scope**: [Notion, Google Drive] | **Duration**: [time]

### By Classification
| Type | Count | Fresh | Current | Aging | Stale |
|------|-------|-------|---------|-------|-------|
| wiki | N | N | N | N | N |
| meeting-notes | N | N | N | N | N |
| project-docs | N | N | N | N | N |
| process | N | N | N | N | N |
| reference | N | N | N | N | N |
| template | N | N | N | N | N |
| database | N | N | N | N | N |
| archive | N | N | N | N | N |
| other | N | N | N | N | N |

### Freshness Overview
- Fresh (<30d): [N] sources
- Current (30-90d): [N] sources
- Aging (90-180d): [N] sources
- Stale (>180d): [N] sources
```

Conditional lines after the freshness overview:
- If the Sources DB was not found (neither consolidated nor legacy): "No Knowledge Base database found in Notion. Index results displayed in chat only."
- If total sources exceed 500: "Large workspace detected. Consider narrowing scope with `--folder` for Drive sources or running targeted index passes."
- If any sources had errors: "[N] sources failed metadata extraction. Details: [list source titles and error reasons]."
- If Drive was unavailable when scope included it: "Google Drive was unavailable -- only Notion sources were indexed."

Always end with:
```
*Index stored in Notion · Run `/founder-os:kb:ask [question]` to query your knowledge base*
```

## Graceful Degradation

**Notion MCP unavailable**: Stop execution. Display:
"Notion MCP server is not connected. Notion is required for both source discovery and index storage. Install it per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`:
1. Set `NOTION_API_KEY` with an integration that has access to your workspace
2. Add `@modelcontextprotocol/server-notion` to your MCP configuration"

**gws CLI unavailable or not authenticated** (and scope includes Drive): Continue with Notion-only indexing. Append to output: "Google Drive was unavailable -- only Notion sources were indexed. Install gws CLI and run `gws auth login` per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`."

**Rate limiting during Notion scan**: Pause for 2 seconds and retry the failed request once. If the retry also fails, skip the current source, increment the error count, and continue with the next source. If 5 consecutive requests fail with rate limits, stop scanning with: "Notion rate limit hit repeatedly. Indexed [N] of [total] sources. Re-run to continue from where indexing left off."

**Very large workspace (500+ sources)**: Index the 500 most recently edited Notion pages. Warn at the end of the summary: "Large workspace detected. Consider narrowing scope with `--folder` for Drive sources or running targeted index passes."

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/founder-os:kb:index
/founder-os:kb:index --scope=notion
/founder-os:kb:index --scope=drive --folder="Client Projects"
/founder-os:kb:index --scope=all
/founder-os:kb:index --scope=drive
```
