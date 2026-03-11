---
name: Drive Navigation
description: "Searches and navigates Google Drive to find files, list folders, and rank results by relevance. Activates when the user wants to find a file in Drive, browse folders, search for documents, or asks 'where's that spreadsheet?' Handles search query formulation, file type detection, folder traversal, and relevance scoring."
version: 1.0.0
---

# Drive Navigation

Search and navigate Google Drive to find files, traverse folder hierarchies, and rank results for relevance. This skill powers `/founder-os:drive:search` (find files by query) and `/founder-os:drive:organize` (folder-level browsing and restructuring), providing the search and traversal primitives that other skills and commands consume.

## Google Drive Search Pipeline

Execute searches against Google Drive using the gws CLI (Drive) tools. The pipeline follows a fixed sequence to maximize recall while keeping result sets manageable.

**Pipeline stages:**

1. **Query formulation** -- generate 2-3 query variants from the user's input.
2. **Search execution** -- call gws CLI (Drive) search for each variant, collecting file metadata.
3. **File type filtering** -- discard unsupported binary types, keep searchable document types.
4. **Content reading** -- read file content from top results (limit 10 per variant).
5. **Deduplication** -- remove duplicate results by file ID across variants.
6. **Relevance scoring** -- score each unique result on three factors (0-100).
7. **Preview generation** -- extract first 500 chars from top results for display.
8. **Ranking** -- sort by composite score descending, return ranked list.

Complete all variants before scoring. If gws CLI is unavailable for Drive, report status clearly and halt the pipeline -- Drive is the required source for this skill.

## Query Formulation

Generate 2-3 query variants from the user's original input to maximize recall. Google Drive uses simple keyword matching, not semantic search, so different phrasings surface different results.

**Variant generation rules:**

1. **Literal variant** -- extract core noun phrases from the query as-is. Strip question words (what, how, where, when, why) and filler words.
2. **Synonym variant** -- replace key terms with common synonyms or related terms (e.g., "invoice" -> "bill", "proposal" -> "bid", "meeting notes" -> "minutes").
3. **Broadened variant** (optional, use when the topic is specific) -- remove qualifiers to widen the net (e.g., "Q1 2026 revenue report" -> "revenue report").

**Constraints:**
- Keep each variant to 2-5 words. Longer queries reduce recall in Drive search.
- Do not generate more than 3 variants -- diminishing returns after that.
- Do not add words the user never implied. Synonyms must be reasonable substitutions, not speculative expansions.
- Preserve proper nouns (company names, product names, project names) verbatim in at least one variant.

Consult `${CLAUDE_PLUGIN_ROOT}/skills/drive/drive-navigation/references/search-strategies.md` for detailed query variant examples, file-type filtering patterns, and search-within-folder techniques.

## File Type Handling

Filter search results to supported file types and apply type-specific content extraction.

**Supported types:**
- **Google Docs** -- exported as markdown, full text searchable, extract first 3000 chars for content analysis.
- **Google Sheets** -- tab-by-tab extraction, header row detection, structured data representation.
- **PDFs** -- text extraction from native (selectable text) PDFs. Scanned-image PDFs return empty content; note `scanned: true` and score keyword density as 0.
- **Plain Text / Markdown** -- direct content reading, no conversion needed.
- **Google Slides** -- slide-by-slide text extraction including speaker notes.

**Skip silently:** images, videos, ZIP archives, and any other binary format. Do not log warnings or mention skipped files unless the user explicitly asked for a file that was skipped.

Apply content truncation rules: 3000-character cap per file for extraction, 500-character cap for previews.

Consult `${CLAUDE_PLUGIN_ROOT}/skills/drive/drive-navigation/references/file-type-handling.md` for detailed parsing patterns, extraction logic per type, and truncation rules.

## Relevance Scoring

Score each result on three factors. Total score range: 0-100.

### Factor 1: Keyword Density (0-40)

Count how many of the user's key terms (nouns, verbs, adjectives extracted from the original query) appear in the result's filename and content combined.

| Match ratio | Score |
|-------------|-------|
| All key terms present | 35-40 |
| Most key terms (>70%) | 25-34 |
| Some key terms (40-70%) | 15-24 |
| Few key terms (<40%) | 5-14 |
| No key terms | 0-4 |

Exact phrase matches (three or more consecutive key terms in order) earn a 5-point bonus within this factor, capped at 40.

**Key term extraction:** Strip stop words, keep proper nouns regardless of part of speech, keep numbers and dates, treat hyphenated compounds as single terms.

### Factor 2: Title Match (0-30)

Measure how closely the filename matches the user's query intent. Filenames in Drive are intentionally descriptive, so strong filename matches indicate high relevance.

| Match level | Score |
|-------------|-------|
| Filename contains the exact query phrase | 28-30 |
| Filename contains most query keywords | 20-27 |
| Filename contains some query keywords | 10-19 |
| Filename is tangentially related | 3-9 |
| Filename has no relationship to query | 0-2 |

### Factor 3: Recency (0-30)

Score based on the file's last modified date.

| Age | Score |
|-----|-------|
| Modified within last 7 days | 28-30 |
| Modified within last 30 days | 20-27 |
| Modified within last 90 days | 12-19 |
| Modified within last 365 days | 5-11 |
| Older than 365 days | 0-4 |

**Composite score:** Sum all three factors. Rank results by composite score descending.

Consult `${CLAUDE_PLUGIN_ROOT}/skills/drive/drive-navigation/references/search-strategies.md` for scoring formula pseudocode, worked examples with score breakdowns, and edge case adjustments.

## Folder Traversal

Navigate Drive folder hierarchies to list contents and build breadcrumb paths.

**Traversal approach:**

1. **Resolve folder** -- use gws CLI (Drive) to locate the target folder by name or ID. If the name is ambiguous (multiple folders share the same name), present a disambiguation list showing parent paths.
2. **List contents** -- call the gws CLI (Drive) list tool to retrieve all files and subfolders within the target folder. Capture name, type, last modified date, and file ID for each item.
3. **Build breadcrumb path** -- construct the full path from root to the current folder. Format as `My Drive > Projects > Client A > Proposals`. Use the file's `parents` metadata to walk up the hierarchy.
4. **Recursive listing** -- when the user requests "all files in a folder", traverse subfolders one level at a time. Cap recursion at 3 levels deep to avoid performance issues. Note when deeper content exists but was not traversed.

**Folder content display format:**

```
Folder: My Drive > Projects > Client A
Last modified: 2026-03-01

Contents (12 items):
  [Folder] Proposals (5 files, modified 2026-02-28)
  [Folder] Contracts (3 files, modified 2026-01-15)
  [Doc]    Project Brief.gdoc (modified 2026-03-01)
  [Sheet]  Budget Tracker.gsheet (modified 2026-02-20)
  [PDF]    Signed Agreement.pdf (modified 2025-12-10)
  [Doc]    Meeting Notes 2026-02.gdoc (modified 2026-02-15)
```

Group subfolders first, then files. Sort each group by last modified date descending.

**Scoped search:** When a user requests a search within a specific folder, pass the folder ID as a parent filter to the Drive search call. Indicate the search scope in the output: `search_scope: "Projects > Client A"`.

## Result Ranking and Deduplication

After collecting results from all query variants, merge and deduplicate before scoring.

**Deduplication rules:**

1. **By file ID** -- the primary deduplication key. If the same file appears in results for multiple query variants, keep one entry with the best content excerpt.
2. **Cross-variant merging** -- combine result sets from all variants into a single list. Remove duplicates by file ID. Retain the content excerpt from whichever variant produced the longest or most relevant snippet.
3. **Cap at 20** -- limit to 20 unique results before applying relevance scoring. Drive search rarely returns more than 20 genuinely relevant results for a query.

**Ranking:** After scoring, sort by composite score descending. Break ties by recency (more recently modified file wins). Assign rank numbers 1 through N.

## Preview Generation

Generate a 500-character preview of each file's content for display in search results.

**Preview rules:**

1. Use the first meaningful paragraph of the file body. Skip titles, metadata lines, and blank lines.
2. If the first paragraph exceeds 500 characters, truncate at the last word boundary before 500 chars and append "...".
3. If the file starts with a heading, use the first paragraph after the heading.
4. Strip markdown formatting from previews: remove `**bold**`, `# headings`, `[links](url)`, and other markup.
5. The preview must read as a coherent text fragment, not a list of keywords or metadata.
6. For spreadsheets, use the header row plus the first 3 data rows formatted as a condensed table.
7. For empty or unreadable files, set preview to `"[No preview available]"`.

## Company Detection for Activity Logging

When Drive activity is logged to the [FOS] Activity Log Notion database, populate the **Company** relation if the file path or filename matches a known client from [FOS] Companies. Populate Company relation when the Drive file belongs to a known client folder or filename contains a client name.

**Detection rules:**
1. Check the file's breadcrumb path for folder names that match a Company name in [FOS] Companies (case-insensitive).
2. Check the filename for a Company name substring match.
3. If a match is found, set the Company relation to the matching record. If multiple matches exist, prefer the breadcrumb path match over the filename match.
4. If no match is found, leave the Company relation empty.

## Graceful Degradation

Handle gws CLI (Drive) unavailability clearly and without crashing.

- **gws CLI (Drive) unavailable**: Report `drive_status: "unavailable"` in the output. Inform the user that the gws CLI (`gws drive`) is not connected and suggest checking the MCP configuration.
- **Drive search returns empty**: Retry with the broadened query variant. If still empty, report "No files found matching your query in Google Drive" and suggest alternative search terms based on the synonym variant.
- **MCP connection timeout**: Retry once. If the second attempt fails, mark as unavailable and report the error.
- **Rate limiting**: If Drive returns rate-limit errors, back off and process remaining query variants first, then retry the failed variant.
- **Very large result sets**: Cap at 20 results before scoring to prevent performance degradation.

## Output Structure

Return search results in this format for consumption by commands and other skills:

```
search_results:
  query_original: [user's search input]
  query_variants: [list of 2-3 variants used]
  drive_status: "available" | "unavailable"
  search_scope: "all" | [folder breadcrumb path]
  total_results: [count]
  results:
    - rank: 1
      score: [0-100]
      source: "drive"
      title: [filename]
      url: [Drive URL]
      content_type: "doc" | "sheet" | "pdf" | "text" | "slides" | "markdown"
      last_modified: [ISO date]
      preview: [up to 500 chars]
      breadcrumb: [folder path, e.g., "My Drive > Projects > Client A"]
      file_id: [Drive file ID]
      score_breakdown:
        keyword_density: [0-40]
        title_match: [0-30]
        recency: [0-30]
```

For folder traversal operations, return a folder listing format instead:

```
folder_listing:
  folder_name: [name]
  breadcrumb: [full path]
  last_modified: [ISO date]
  total_items: [count]
  subfolders: [list with name, item_count, last_modified]
  files: [list with name, content_type, last_modified, file_id, url]
```
