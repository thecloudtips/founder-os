---
name: Source Indexing
description: "Crawls Notion and Google Drive to build a structured catalog of knowledge sources with classification and freshness tracking. Activates when the user wants to index the knowledge base, refresh the source catalog, scan for new documents, or asks 'update the knowledge base index.' Uses a 9-type taxonomy with metadata extraction."
---

## Overview

Crawl the Notion workspace and Google Drive to build a structured catalog of all available knowledge sources. For each discovered source, extract metadata (title, URL, type, classification, keywords, word count, last edited, parent location), assign a content classification from a 9-type taxonomy, compute a freshness tier, and write the result to the "[FOS] Knowledge Base" Notion database with Type="Source" (falls back to "Founder OS HQ - Knowledge Base", then legacy "Knowledge Base Q&A - Sources" if the consolidated database is not found). The index serves as the lookup layer for `/founder-os:kb:ask` and `/founder-os:kb:find` commands, enabling fast retrieval by classification, keywords, and freshness without re-scanning the entire workspace on every query.

This skill handles source discovery and cataloging only. Content retrieval and answer synthesis are handled by the knowledge-retrieval and answer-synthesis skills respectively.

## Source Discovery Pipeline

Execute the discovery pipeline in two phases: Notion first (required), then Google Drive (optional). Each phase produces a list of source records that are merged and written to the Sources DB.

### Phase 1: Notion Discovery (Required)

Scan the Notion workspace for all accessible pages and databases using the Notion MCP server.

#### Step 1: Search for Pages

Call `notion-search` with an empty query and `filter.property: "object"`, `filter.value: "page"` to retrieve all accessible pages. Paginate through all results using the `start_cursor` from each response until `has_more` is false. Cap at 500 pages per index run to prevent runaway scans on large workspaces. When the cap is reached, warn: "Reached 500-page limit. Re-run with specific parent filters to index additional pages."

#### Step 2: Search for Databases

Call `notion-search` with `filter.property: "object"`, `filter.value: "database"` to retrieve all accessible databases. Databases are indexed as sources themselves (not their contents). Record the database title, URL, property schema summary, and item count when available.

#### Step 3: Extract Page Metadata

For each discovered page, extract:

1. **Title**: From the page title property. If the page has no title, use "Untitled" and flag for review.
2. **URL**: Construct from the page ID: `https://www.notion.so/[page_id_without_hyphens]`.
3. **Source Type**: Set to "Notion Page" for pages, "Notion Database" for databases.
4. **Content**: Retrieve page content via `notion-fetch` for classification and keyword extraction. Limit content retrieval to the first 3000 characters to control API usage.
5. **Last Edited**: From the `last_edited_time` property on the page object.
6. **Parent Location**: From the `parent` property -- resolve to the parent page title or workspace root. Format as a breadcrumb path: "Workspace > Parent Page > Current Page".

#### Step 4: Rate Management

Process pages sequentially. After every 10 pages, emit a progress update: "Indexed [N] of [total] Notion pages..." to keep the user informed during long scans.

### Phase 2: Google Drive Discovery (Optional)

When gws CLI is available (check with `which gws`), scan for documents to supplement the Notion index.

#### Step 1: Search for Documents

Use the gws CLI via Bash to search for documents. Execute three targeted searches:

1. `mimeType = 'application/vnd.google-apps.document'` -- Google Docs
2. `mimeType = 'application/pdf'` -- PDFs
3. `mimeType = 'application/vnd.google-apps.spreadsheet'` -- Google Sheets

Cap at 200 files total across all searches. Skip files in Trash.

#### Step 2: Extract Drive Metadata

For each discovered file, extract:

1. **Title**: From the file name.
2. **URL**: From the `webViewLink` property.
3. **Source Type**: Set to "Google Drive".
4. **Last Edited**: From the `modifiedTime` property.
5. **Parent Location**: From the parent folder name. Format as folder path when available.

Content retrieval from Drive files is limited to the title and folder context for classification purposes. Full content retrieval happens at query time via the knowledge-retrieval skill.

#### Step 3: Graceful Degradation

When gws CLI is unavailable or not authenticated, skip Phase 2 entirely. Log: "Google Drive unavailable -- indexing Notion sources only." Do not treat Drive unavailability as an error. The index is fully functional with Notion sources alone.

## Content Classification

Assign exactly one classification from the 9-type taxonomy to each source. Use a first-match-wins priority system: evaluate classification rules in the order listed and stop at the first match.

| Priority | Classification | Summary |
|----------|---------------|---------|
| 1 | `wiki` | Long-form knowledge articles, documentation hubs, team wikis |
| 2 | `meeting-notes` | Records of meetings, standups, retrospectives |
| 3 | `project-docs` | Project plans, briefs, specs, roadmaps, PRDs |
| 4 | `process` | SOPs, how-tos, step-by-step workflows, runbooks |
| 5 | `reference` | Lookup tables, glossaries, FAQs, config references |
| 6 | `template` | Reusable scaffolds, form templates, starter docs |
| 7 | `database` | Notion databases and structured data collections |
| 8 | `archive` | Deprecated, outdated, or explicitly archived content |
| 9 | `other` | Default when no classification matches |

### Classification Method

Apply three detection layers in order. Each layer can produce a classification. Accept the first classification that reaches sufficient confidence:

1. **Title pattern matching**: Match the source title against known patterns for each type. This is the fastest and most reliable signal. See `${CLAUDE_PLUGIN_ROOT}/skills/kb/source-indexing/references/content-classification.md` for the full pattern list.

2. **Content structure analysis**: When title matching produces no result, analyze the first 3000 characters of content for structural signals (headings, list formats, Q&A patterns, step numbering). See the reference file for signal definitions per type.

3. **Parent location heuristics**: When content analysis is inconclusive, use the parent page or folder name as a classification hint. A page under a "Wiki" parent inherits the `wiki` classification. See the reference file for parent-to-classification mappings.

When all three layers are inconclusive, assign `other`.

For Notion databases, always assign `database` regardless of title or parent -- the object type itself is the classification signal.

## Metadata Extraction

Extract these fields for every discovered source:

| Field | Extraction Method |
|-------|------------------|
| Source Title | Page title property or file name. Max 200 characters, truncate with "..." |
| URL | Notion page URL or Drive webViewLink. This is the idempotent key |
| Source Type | "Notion Page", "Notion Database", or "Google Drive" |
| Classification | From the 9-type taxonomy (see above) |
| Topic Keywords | Top 5-8 keywords extracted from content (see keyword extraction below) |
| Word Count | Approximate word count from content body. For databases, use 0 |
| Last Edited | `last_edited_time` (Notion) or `modifiedTime` (Drive) as ISO 8601 |
| Freshness | Computed tier based on Last Edited date (see freshness tracking below) |
| Parent Location | Breadcrumb path: "Workspace > Parent > Page" or Drive folder path |
| Status | "Active" for accessible sources, "Archived" for archived pages, "Error" for fetch failures |
| Indexed At | Current timestamp at time of index write |

### Keyword Extraction

Extract 5-8 topic keywords from the source content to enable keyword-based search in the `/founder-os:kb:ask` and `/founder-os:kb:find` commands.

1. Retrieve the first 3000 characters of content (already fetched for classification).
2. Tokenize into words. Remove common stop words (the, a, an, is, are, was, were, in, on, at, to, for, of, and, or, but, with, by, from, as, it, this, that, which, who, what, how, when, where, why, be, been, being, have, has, had, do, does, did, will, would, could, should, may, might, can, shall, not, no, all, each, every, some, any, many, few, more, most, other, than, then, into, out, up, about, over, after, before, between, under, through, during, also, just, only, very).
3. Count word frequency. Prefer nouns and noun phrases -- words that appear in headings carry 2x weight.
4. Select the top 5-8 words by weighted frequency.
5. Store as a comma-separated string: "project, timeline, budget, deliverables, milestone".

For pages with insufficient content (fewer than 50 words), extract keywords from the title only. For databases, extract keywords from the database title and property names.

## Freshness Tracking

Compute a freshness tier for each source based on the elapsed time between its `Last Edited` date and the current date.

| Tier | Days Since Edit | Meaning |
|------|----------------|---------|
| Fresh | 0-29 days | Recently updated, highly reliable |
| Current | 30-89 days | Reasonably up to date |
| Aging | 90-179 days | May contain outdated information |
| Stale | 180+ days | Likely outdated, use with caution |

### Calculation

```
days_since_edit = (current_date - last_edited_date).days

if days_since_edit < 30:   freshness = "Fresh"
elif days_since_edit < 90:  freshness = "Current"
elif days_since_edit < 180: freshness = "Aging"
else:                       freshness = "Stale"
```

Recalculate freshness on every index run. A source that was "Fresh" last month may now be "Current" or "Aging". The freshness tier is always relative to the current date, never cached from a previous run.

### Freshness in Downstream Use

The knowledge-retrieval skill uses freshness tiers to weight search results: Fresh sources rank higher than Stale sources for the same keyword match. The answer-synthesis skill includes freshness caveats when citing Aging or Stale sources (e.g., "Note: this source was last updated 5 months ago").

## Notion DB Output

Write all indexed sources to the Notion database.

### Database Discovery

Discover the target database using the consolidated name first, then fall back to legacy:
1. Search Notion for a database titled "[FOS] Knowledge Base". If not found, try "Founder OS HQ - Knowledge Base". If found, use it. Set the **Type** property to `"Source"` on every record written.
2. If not found, search for "Knowledge Base Q&A - Sources". If found, use it.
3. If neither is found, skip Notion writing entirely (do NOT create the database). Output results to chat only.

On subsequent runs, reuse the discovered database.

### Idempotent Updates

Match existing records by the **URL** property. For each source in the current scan:

1. Search the Sources DB for a record with a matching URL.
2. If a match exists, update the existing record with the new metadata (title, classification, keywords, word count, last edited, freshness, status, indexed at). Do not create a duplicate.
3. If no match exists, create a new record with all 11 properties populated.

This ensures re-running `/founder-os:kb:index` updates existing entries and adds new sources without creating duplicates.

### Removed Source Handling

Sources that existed in a previous index but are no longer discoverable (deleted pages, revoked Drive access) are not automatically removed from the Sources DB. Instead, when a previously indexed URL returns a 404 or access error during a re-index, set the record's Status to "Archived" and preserve the existing metadata. This maintains a historical record while signaling that the source is no longer accessible.

## Index Summary Output

After completing the full pipeline, present a summary to the user:

```
Index Complete
--------------
Notion Pages:    [N] indexed
Notion Databases: [N] indexed
Google Drive:    [N] indexed (or "skipped -- Drive unavailable")
Total Sources:   [N]

By Classification:
  wiki:          [N]
  meeting-notes: [N]
  project-docs:  [N]
  process:       [N]
  reference:     [N]
  template:      [N]
  database:      [N]
  archive:       [N]
  other:         [N]

By Freshness:
  Fresh:   [N]
  Current: [N]
  Aging:   [N]
  Stale:   [N]

New:     [N] sources added
Updated: [N] sources refreshed
Errors:  [N] sources failed (see details below)
```

Include error details for any sources that failed metadata extraction, listing the source title and error reason.

## Edge Cases

### Pages with No Content

When a Notion page exists but has an empty body:
- Set Word Count to 0.
- Extract keywords from the title only.
- Classify based on title patterns and parent location (skip content structure analysis).
- Set Status to "Active" -- empty pages are valid sources that may be populated later.

### Untitled Pages

When a page has no title property:
- Set Source Title to "Untitled".
- Classify based on content structure and parent location only.
- Extract keywords from content only.
- Include in the index -- untitled pages may still contain valuable content.

### Databases as Sources

When indexing Notion databases:
- Always classify as `database`.
- Set Word Count to 0.
- Extract keywords from the database title and property names.
- Record the number of items in the database (if available from the search response) in the Topic Keywords field appended as: "..., [N] items".
- Set Parent Location from the database's parent page.

### Access Errors

When a page or file returns a permission error during metadata extraction:
- Set Status to "Error".
- Record the source with whatever metadata was available from the search results (title, URL, type).
- Leave Classification, Keywords, and Word Count empty.
- Include in the error count of the index summary.

### Very Large Workspaces

When the Notion search returns more than 500 pages:
- Index the first 500 pages (sorted by last edited, most recent first).
- Warn: "Workspace contains more than 500 pages. Indexed the 500 most recently edited. Run /founder-os:kb:index with parent filters to index additional sections."
- Record the total page count in the summary for user awareness.

## Reference Files

For the complete 9-type classification taxonomy with detection signals, title patterns, content structure indicators, parent location mappings, keyword extraction methodology, and example index outputs, consult:

`${CLAUDE_PLUGIN_ROOT}/skills/kb/source-indexing/references/content-classification.md`
