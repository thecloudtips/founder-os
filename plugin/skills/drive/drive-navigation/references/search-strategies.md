# Drive Navigation Search Strategies

Detailed reference for query formulation, file-type filtering, folder-scoped search, relevance scoring formulas, and edge case handling for Google Drive search.

---

## Query Variant Generation Examples

### Example 1: Direct file lookup

**User input:** "Find the quarterly revenue report"

| Variant | Type | Query |
|---------|------|-------|
| 1 | Literal | `quarterly revenue report` |
| 2 | Synonym | `Q1 financial report` |
| 3 | Broadened | `revenue report` |

### Example 2: Topic-based search

**User input:** "Search Drive for anything about the Acme onboarding"

| Variant | Type | Query |
|---------|------|-------|
| 1 | Literal | `Acme onboarding` |
| 2 | Synonym | `Acme getting started` |

Note: Skip the broadened variant when the query is already broad. Two variants are sufficient here.

### Example 3: Date-qualified search

**User input:** "Find invoices from January 2026"

| Variant | Type | Query |
|---------|------|-------|
| 1 | Literal | `invoices January 2026` |
| 2 | Synonym | `bills January 2026` |
| 3 | Broadened | `invoices 2026` |

### Example 4: Specific document name

**User input:** "Look up the SOW for Project Phoenix"

| Variant | Type | Query |
|---------|------|-------|
| 1 | Literal | `SOW Project Phoenix` |
| 2 | Synonym | `statement of work Phoenix` |
| 3 | Broadened | `Project Phoenix` |

### Example 5: Format-specific search

**User input:** "Find all spreadsheets with budget data"

| Variant | Type | Query |
|---------|------|-------|
| 1 | Literal | `budget` |
| 2 | Synonym | `financial plan` |

Note: Combine with file-type filtering (see below) to restrict results to Google Sheets only.

### Variant Construction Heuristics

1. **Strip question scaffolding** -- remove "Find", "Search for", "Look up", "Where is", "Can you find" -- these are noise for keyword search.
2. **Preserve proper nouns** -- company names, project names, product names, and acronyms must appear verbatim in at least one variant.
3. **Synonym selection** -- use only common professional synonyms. "Invoice" -> "bill" is valid; "invoice" -> "receipt" is a stretch (different document types).
4. **Compound terms** -- keep compound terms together in at least one variant (`SOW`, `CI/CD`, `year-end`). Try the expanded form in a synonym variant if the abbreviation might not match.
5. **Dates and periods** -- keep temporal qualifiers in the literal variant. Drop them in the broadened variant to catch undated versions of the same document.
6. **Short queries win** -- 2-4 keywords yield more relevant results than long phrases. Drive search does not do phrase matching; it uses keyword intersection.

---

## Search by File Type

Filter search results to specific Google Drive MIME types when the user's query implies a particular format.

### MIME Type Mapping

| User intent | MIME type filter | Notes |
|-------------|-----------------|-------|
| Google Docs / documents | `application/vnd.google-apps.document` | Most common type |
| Google Sheets / spreadsheets | `application/vnd.google-apps.spreadsheet` | Structured data |
| Google Slides / presentations | `application/vnd.google-apps.presentation` | Slide decks |
| PDFs | `application/pdf` | Contracts, signed docs |
| Plain text | `text/plain` | Config files, notes |
| Markdown | `text/markdown` | Technical docs |

### When to Apply Type Filters

- Apply when the user explicitly mentions a format: "find all spreadsheets", "look for a PDF", "search docs".
- Apply when the query context implies a format: "budget tracker" likely implies a spreadsheet; "signed contract" likely implies a PDF.
- Do not apply when the user's intent is ambiguous. Default to searching all supported types and let relevance scoring sort results.

### Detection Keywords

| Keywords in query | Implied type |
|-------------------|-------------|
| spreadsheet, sheet, table, data, tracker, budget | Google Sheets |
| document, doc, write-up, draft, brief, proposal, report | Google Docs |
| slides, presentation, deck, pitch | Google Slides |
| PDF, signed, scanned, contract (signed) | PDF |

---

## Search Within Folders

Scope a search to a specific Drive folder when the user indicates a location.

### Folder Scoping Approach

1. **Resolve folder** -- locate the target folder by name using a Drive search filtered to folders (`mimeType = 'application/vnd.google-apps.folder'`). If multiple folders share the name, present a disambiguation list with parent paths.
2. **Pass folder ID as parent** -- include the resolved folder ID in the search query as a parent filter. This restricts results to files within that folder and its subfolders.
3. **Indicate scope in output** -- set `search_scope` to the folder's breadcrumb path (e.g., `"My Drive > Projects > Client A"`) so the user knows the search was scoped.

### Common Folder Scoping Patterns

| User phrase | Behavior |
|-------------|----------|
| "in the Projects folder" | Resolve "Projects" folder, scope search |
| "under Client A" | Resolve "Client A" folder, scope search |
| "in Shared Drives" | Scope to shared drives (gws CLI (Drive) typically includes these by default) |
| "in my Drive" | No scoping needed; default search covers "My Drive" |
| "in the Proposals subfolder of Client A" | Resolve "Client A" first, then find "Proposals" within it |

### Nested Folder Resolution

When the user specifies a nested path (e.g., "Projects > Client A > Proposals"):

1. Resolve "Projects" at the root level.
2. List contents of "Projects" and find "Client A" subfolder.
3. List contents of "Client A" and find "Proposals" subfolder.
4. Use the "Proposals" folder ID for scoped search.

If any step fails to find the specified folder, report which segment could not be resolved and suggest alternatives.

---

## Filename vs Full-Text Search

Google Drive indexes both filenames and file body content.

- **Filename matches** -- Drive prioritizes filename matches in its internal result ordering. A file named "Revenue Report Q1" appears before a file named "Meeting Notes" that mentions "revenue report" in the body.
- **Full-text matches** -- Drive indexes body content of Google Docs, Sheets (cell values), and Slides (text boxes). Queries can match on interior text even when the filename is unrelated.
- **PDFs** -- only native PDFs with selectable text are full-text indexed. Scanned PDFs match on filename only.

The relevance scoring Title Match factor (0-30 points) accounts for the filename weighting advantage.

### Explicit Filename Search

When the user's query suggests they know the exact filename (e.g., "find the file called Budget 2026"), run a search with the filename as the query. If exactly one result matches, return it immediately without variant expansion. If multiple results match, apply full scoring to rank them.

---

## Wildcard and Partial Matching Behavior

Google Drive does not support true wildcards (`*`, `?`), boolean operators (`AND`, `OR`, `NOT`), or regular expressions.

**What works:**
- **Prefix matching** -- "budget" matches "budgets", "budgeting", "budgetary".
- **Case insensitivity** -- "Revenue" matches "revenue", "REVENUE".
- **Word-level matching** -- "project plan" matches files containing both words anywhere, not necessarily adjacent.

**What does not work:**
- **Suffix matching** -- "report" may not match "quarterly-report" if stored as a single hyphenated token. Try both forms as separate variants.
- **Exact phrase matching** -- Drive does not guarantee word-order matching. The relevance scoring phrase bonus compensates by rewarding consecutive term matches.

---

## Common Search Patterns

| Query pattern | Variants | Notes |
|--------------|----------|-------|
| "Find all invoices" | `invoices`, `bills`, `invoice` | Optional: filter to PDF type |
| "Latest proposal for [client]" | `proposal [client]`, `bid [client]` | "Latest" implies recency-first ranking |
| "Meeting notes from last Tuesday" | `meeting notes`, `minutes` | Resolve relative date, filter by modification date |
| "Find everything related to [project]" | `[project name]`, `[abbreviation]` | No type filter; "everything" means all types |
| "Where did I save the signed contract?" | `signed contract`, `executed contract`, `contract` | Include breadcrumb path in results; filter to PDF |

---

## Relevance Scoring Worked Examples

### Worked Example 1

**User query:** "Find the SOW for Project Phoenix"
**Key terms:** `SOW`, `Project`, `Phoenix`

**Result A:** Google Doc titled "SOW - Project Phoenix - Final", last modified 5 days ago, body contains all 3 key terms plus the phrase "SOW for Project Phoenix".

| Factor | Calculation | Score |
|--------|-------------|-------|
| Keyword density | 3/3 terms matched = ratio 1.0; base = 35; phrase bonus = 5 (3+ consecutive terms) | **40** |
| Title match | 3/3 terms in title; ratio = 1.0; exact phrase present | **30** |
| Recency | 5 days old; within 7-day tier | **29** |
| **Total** | | **99** |

**Result B:** Google Sheet titled "Phoenix Project Tracker", last modified 45 days ago, body contains "Project" and "Phoenix" but not "SOW".

| Factor | Calculation | Score |
|--------|-------------|-------|
| Keyword density | 2/3 terms matched = ratio 0.67; base = 23; no phrase bonus | **23** |
| Title match | 2/3 terms in title ("Project", "Phoenix"); ratio = 0.67; band 0.3-0.7 | **18** |
| Recency | 45 days old; within 30-90 day tier | **16** |
| **Total** | | **57** |

Result A ranks first (99 > 57). Correct: it is the exact SOW document the user is looking for.

---

## Edge Cases

### Very Common Terms

Queries containing common terms ("report", "notes", "file") produce large result sets. Strip stop words from key terms before scoring. For remaining common terms, proceed normally but rely on the 20-result cap. Suggest the user add a qualifier if results are too broad.

### Empty Results

When no results are returned for any variant:

1. Generate a broader variant by removing all qualifiers and dates. Retry.
2. If still empty, report: "No files found matching your query in Google Drive."
3. Suggest alternative terms based on the synonym variant.
4. If the search was folder-scoped, suggest searching all of Drive.

### Large Result Sets

Cap at 20 results before scoring. Apply the cap after merging and deduplicating across variants. Use Drive's default recency ordering to select the top 20. Note `results_capped: true, total_raw_results: [count]` in output when capped.

### Ambiguous Folder Names

When multiple folders share the same name, retrieve parent folder information for each match and present a numbered disambiguation list with breadcrumb paths and item counts. Wait for the user to select before proceeding.

### Files in Trash

Exclude trashed files from results by checking the `trashed` property. Do not surface trashed files unless the user explicitly asks to search the trash.

### Shared Drive Permissions

When the Drive read tool returns a permission error, include the file in results with metadata only (title, type, last modified, URL). Set preview to `"[Permission denied - unable to read content]"`. Score keyword density as 0; title match and recency scores still apply.
