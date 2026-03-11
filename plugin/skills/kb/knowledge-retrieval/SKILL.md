---
name: Knowledge Retrieval
description: "Searches across Notion pages/databases and Google Drive to find relevant knowledge base documents. Activates when the user wants to search the knowledge base, find a document, look something up, or asks 'what do we have on [topic]?' Scores results by relevance and extracts content previews for downstream answer synthesis."
version: 1.0.0
---

# Knowledge Retrieval

Search Notion and Google Drive to find relevant documents, score them for relevance, and extract content for answer synthesis or document listing. This skill powers both `/founder-os:kb:ask` (full answer with citations) and `/founder-os:kb:find` (ranked document listing with previews).

## Multi-Source Search Pipeline

Execute searches in a fixed order. Notion is the required primary source; Google Drive is optional and additive.

**Pipeline stages:**

1. **Query formulation** -- generate 2-3 query variants from the user's input.
2. **Notion search** -- search Notion pages and databases using each variant.
3. **Drive search** (when available) -- search Google Drive using each variant.
4. **Deduplication** -- remove results that appear in both sources.
5. **Relevance scoring** -- score each unique result on three factors (0-100).
6. **Content extraction** -- pull the most relevant section from top results (3000 char cap).
7. **Preview generation** -- produce 150-char previews for `/founder-os:kb:find` output.

Always complete Notion search before starting Drive search. If gws CLI is unavailable or not authenticated, skip stage 3 and continue the pipeline -- never error on a missing optional source.

## Query Formulation

Generate 2-3 query variants from the user's original question to maximize recall. Different phrasings surface different results because Notion and Drive use simple keyword matching, not semantic search.

**Variant generation rules:**

1. **Literal variant** -- extract the core noun phrases from the question as-is. Strip question words (what, how, where, when, why) and filler.
2. **Synonym variant** -- replace key terms with common synonyms or related terms (e.g., "onboarding" -> "getting started", "pricing" -> "cost" or "rates").
3. **Broadened variant** (optional, use when the topic is specific) -- remove qualifiers to widen the net (e.g., "Q3 2025 revenue report" -> "revenue report").

**Constraints:**
- Keep each variant to 2-5 words. Longer queries reduce recall in both Notion and Drive search.
- Do not generate more than 3 variants -- diminishing returns after that.
- Do not add words the user never implied. Synonyms must be reasonable substitutions, not speculative expansions.

Consult `${CLAUDE_PLUGIN_ROOT}/skills/kb/knowledge-retrieval/references/search-strategies.md` for detailed query variant examples and source-specific search tips.

## Notion Search

Use the Notion MCP `notion-search` tool to find pages and databases matching each query variant.

**Search execution:**
1. Call `notion-search` with each query variant.
2. Collect all returned pages and database entries.
3. For database results, inspect the title property and any rich-text properties for relevance signals.
4. For page results, read the page content to assess match quality.

**Notion-specific patterns:**
- Notion search is title-weighted. Queries matching a page title rank higher than body-only matches.
- Database items are returned alongside pages. Treat each database row as a separate result if its title or content matches.
- When a database itself matches (not a row), note it as a container -- it may hold multiple relevant entries. Search within it if the initial results are sparse.
- Notion search does not support boolean operators. Rely on short keyword phrases only.

**Result capture format per item:**
```
source: "notion"
title: [page or database entry title]
url: [Notion URL]
content_snippet: [first 500 chars of page body]
last_edited: [ISO date from last_edited_time]
content_type: "page" | "database_entry"
```

## Google Drive Search

Use the gws CLI via Bash to search and read Google Drive documents. Drive is optional -- if the gws CLI is unavailable or not authenticated, set `drive_status: "unavailable"` and proceed with Notion-only results. Check availability with `which gws`.

**Search execution:**
1. Run `gws drive files list --params '{"q":"fullText contains '\''[query]'\''","pageSize":20,"fields":"files(id,name,mimeType,modifiedTime,webViewLink)"}' --format json` with each query variant.
2. From returned file metadata, filter to supported types: Google Docs, Google Sheets, PDF, plain text, Markdown.
3. For the top results (limit to 10 per variant), read file content by running `gws drive files export --params '{"fileId":"FILE_ID","mimeType":"text/plain"}' --output /tmp/kb-drive-[fileId].txt` and then reading the output file.

**Drive-specific patterns:**
- Drive full-text search indexes document body content, not just filenames. Queries can match on interior text.
- Shared drives and "Shared with me" content is included in search results. No special handling needed.
- Large files (spreadsheets with many tabs, long PDFs) may return truncated content. Extract what is available and note `truncated: true` in the result.
- Binary files (images, videos, ZIP) will not contain searchable text. Skip them silently.

**Result capture format per item:**
```
source: "drive"
title: [filename]
url: [Drive URL]
content_snippet: [first 500 chars of file content]
last_modified: [ISO date]
content_type: "doc" | "sheet" | "pdf" | "text"
```

## Relevance Scoring

Score each result on three factors. Total score range: 0-100.

### Factor 1: Keyword Density (0-40)

Count how many of the user's key terms (nouns, verbs, adjectives from the original question) appear in the result's title and content snippet combined.

| Match ratio | Score |
|-------------|-------|
| All key terms present | 35-40 |
| Most key terms (>70%) | 25-34 |
| Some key terms (40-70%) | 15-24 |
| Few key terms (<40%) | 5-14 |
| No key terms | 0-4 |

Exact phrase matches (consecutive terms in order) earn a 5-point bonus within this factor, capped at 40.

### Factor 2: Title Match (0-30)

Measure how closely the result title matches the user's query intent.

| Match level | Score |
|-------------|-------|
| Title contains the exact query phrase | 28-30 |
| Title contains most query keywords | 20-27 |
| Title contains some query keywords | 10-19 |
| Title is tangentially related | 3-9 |
| Title has no relationship to query | 0-2 |

Title matches are weighted heavily because document titles in a knowledge base are intentionally descriptive.

### Factor 3: Recency (0-30)

Score based on how recently the document was last edited.

| Age | Score |
|-----|-------|
| Edited within last 7 days | 28-30 |
| Edited within last 30 days | 20-27 |
| Edited within last 90 days | 12-19 |
| Edited within last 365 days | 5-11 |
| Older than 365 days | 0-4 |

Recency matters because knowledge bases contain living documents. A recently edited document is more likely to be current and maintained.

**Composite score**: Sum all three factors. Rank results by composite score descending.

Consult `${CLAUDE_PLUGIN_ROOT}/skills/kb/knowledge-retrieval/references/search-strategies.md` for scoring formula details, worked examples, and edge case adjustments.

## Content Extraction

For top-scoring results (top 5 for `/founder-os:kb:ask`, top 10 for `/founder-os:kb:find`), extract the most relevant content section.

**Extraction rules:**

1. Cap extracted content at **3000 characters** per result. If the full document exceeds this, extract the most relevant section rather than truncating from the top.
2. Identify the most relevant section by scanning for headings that contain query keywords. Extract that heading's section (heading through next same-level heading).
3. If no heading matches, extract the first 3000 characters of body content.
4. Preserve markdown formatting in the extracted content (headings, lists, bold, links).
5. If the extracted section ends mid-sentence, extend to the next sentence boundary.
6. Mark extracted content with source metadata: `[Source: {title} | {source} | Last edited: {date}]`.

## Preview Generation

For `/founder-os:kb:find` results, generate a 150-character preview of each document.

**Preview rules:**

1. Use the first meaningful sentence of the document body (skip titles, metadata, and blank lines).
2. If the first sentence exceeds 150 characters, truncate at the last word boundary before 150 chars and append "...".
3. If the document starts with a heading, use the first paragraph after the heading instead.
4. Strip markdown formatting from previews (no `**bold**`, `# headings`, or `[links](url)`).
5. The preview must be a readable sentence fragment, not a list of keywords.

## Graceful Degradation

Handle missing or failing sources without erroring:

- **Drive unavailable**: Skip Drive search entirely. Report `sources_searched: ["notion"]` in output. Do not mention Drive absence to the user unless no results were found at all -- then suggest installing the gws CLI and running `gws auth login` for broader coverage.
- **Notion returns empty**: This is unusual since Notion is the required source. Retry with the broadened query variant. If still empty, report "No matching documents found in the knowledge base" and suggest the user rephrase or check that the content exists.
- **Both sources return empty**: Report no results found. Suggest alternative query terms based on the synonym variant that was generated but may not have matched.

## Output Structure

Return search results in this format for consumption by commands and the answer-synthesis skill:

```
search_results:
  query_original: [user's question]
  query_variants: [list of 2-3 variants used]
  sources_searched: ["notion", "drive"] or ["notion"]
  total_results: [count]
  results:
    - rank: 1
      score: [0-100]
      source: "notion" | "drive"
      title: [document title]
      url: [link]
      content_type: [page | database_entry | doc | sheet | pdf | text]
      last_edited: [ISO date]
      preview: [150-char preview for /founder-os:kb:find]
      extracted_content: [up to 3000 chars for /founder-os:kb:ask]
      score_breakdown:
        keyword_density: [0-40]
        title_match: [0-30]
        recency: [0-30]
```

## Failure Handling

- **MCP connection timeout**: Retry once after a brief pause. If the second attempt fails, mark that source as unavailable and continue.
- **Rate limiting**: If Notion or Drive returns rate-limit errors, back off and process remaining query variants first, then retry the failed variant.
- **Very large result sets**: Limit to the top 20 results per source before scoring. Apply scoring to this capped set, not the full result list.
- **Ambiguous queries**: When the user's question maps to multiple unrelated topics, return results for all interpretations and let the consuming command or skill disambiguate.
