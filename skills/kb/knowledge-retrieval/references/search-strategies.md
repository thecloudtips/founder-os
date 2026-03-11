# Knowledge Retrieval Search Strategies

Detailed reference for query formulation, search patterns, relevance scoring, and content extraction heuristics.

---

## Query Variant Generation Examples

### Example 1: Direct question

**User input:** "What is our refund policy?"

| Variant | Type | Query |
|---------|------|-------|
| 1 | Literal | `refund policy` |
| 2 | Synonym | `return policy` |
| 3 | Broadened | `refund` |

### Example 2: Specific document lookup

**User input:** "Find the Q4 2025 revenue report"

| Variant | Type | Query |
|---------|------|-------|
| 1 | Literal | `Q4 2025 revenue report` |
| 2 | Synonym | `Q4 2025 financial report` |
| 3 | Broadened | `revenue report` |

### Example 3: How-to question

**User input:** "How do I set up the CI/CD pipeline?"

| Variant | Type | Query |
|---------|------|-------|
| 1 | Literal | `CI/CD pipeline setup` |
| 2 | Synonym | `continuous integration deployment configuration` |
| 3 | Broadened | `CI/CD pipeline` |

### Example 4: Vague or broad question

**User input:** "What do we know about Acme Corp?"

| Variant | Type | Query |
|---------|------|-------|
| 1 | Literal | `Acme Corp` |
| 2 | Synonym | `Acme Corporation` |

Note: Skip the broadened variant when the query is already broad. Two variants are sufficient here.

### Example 5: Multi-concept question

**User input:** "What are the onboarding steps for new contractors?"

| Variant | Type | Query |
|---------|------|-------|
| 1 | Literal | `onboarding new contractors` |
| 2 | Synonym | `getting started contractors` |
| 3 | Broadened | `onboarding` |

### Variant Construction Heuristics

1. **Strip question scaffolding**: Remove "What is", "How do I", "Where can I find", "Can you show me" -- these are noise for keyword search.
2. **Preserve proper nouns**: Company names, product names, project names, and acronyms must appear verbatim in at least one variant.
3. **Synonym selection**: Use only common professional synonyms. Avoid slang or jargon not present in the user's question.
4. **Compound terms**: Keep compound terms together in at least one variant (`CI/CD pipeline`, not `CI CD pipeline`). Try the split form in a synonym variant if the compound might not match.
5. **Dates and periods**: Keep temporal qualifiers in the literal variant. Drop them in the broadened variant to catch undated versions of the same document.

---

## Notion Search Patterns

### How `notion-search` Works

The Notion API search endpoint (`POST /v1/search`) accepts a `query` string and returns pages and databases whose titles or content match.

**Key behaviors:**
- Search is **title-weighted**: a title match ranks higher than a body-content match in Notion's internal ranking.
- Search returns both **pages** and **database entries** (rows). Each database row that matches is returned as a separate result.
- The `sort` parameter accepts `last_edited_time` in ascending or descending order. Default to descending (most recently edited first) to prioritize fresh content.
- Results include `last_edited_time` on each page -- use this for the recency scoring factor.
- Boolean operators (`AND`, `OR`, `NOT`) are **not supported**. Send simple keyword strings only.

### Search Tips

1. **Short queries perform better**: 2-4 keywords yield more relevant results than long phrases. Notion's search does not do phrase matching.
2. **Run each variant as a separate search call**: Do not combine variants into one query. Each call returns its own ranked list.
3. **Inspect database containers**: When a database itself appears in results (not a specific row), it may be a relevant container. Consider querying that database's rows with a filter for more targeted results.
4. **Page properties matter**: Database entries have properties (Status, Tags, Category). When available, note these in the result metadata -- they help the answer-synthesis skill assess the document's context.
5. **Archived pages**: Notion search may return archived pages. Check the `archived` property and deprioritize archived results (reduce relevance score by 20 points).

### Notion Result Processing

After collecting results from all variant searches:

1. **Merge**: Combine results from all variant searches into a single list.
2. **Deduplicate by page ID**: If the same page appears in results for multiple variants, keep one entry. Use the highest content_snippet quality (longest, most relevant section).
3. **Cap at 20**: Limit to 20 unique results before scoring. Notion search rarely returns more than 20 relevant results for a query.
4. **Read page content**: For the top 10 results (by Notion's internal ranking), call the Notion page read tool to retrieve the full page body. The content_snippet from search results is often truncated.

---

## Google Drive Search Patterns (via gws CLI)

### How Drive Search Works

Google Drive search uses the gws CLI's `drive files list` command with the `q` parameter for full-text search across filenames and file content for Google Docs, Sheets, and Slides. PDFs are full-text indexed only if they contain selectable text (not scanned images). Check gws CLI availability with `which gws`.

**Search command:**
```bash
gws drive files list --params '{"q":"fullText contains '\''search term'\''","pageSize":20,"fields":"files(id,name,mimeType,modifiedTime,webViewLink)"}' --format json
```

**Key behaviors:**
- Full-text search indexes the **body content** of Google Docs, not just filenames. A query for "revenue report" will match a doc titled "Q4 Analysis" if "revenue report" appears in the body.
- Search results include file metadata: name, mimeType, modifiedTime, webViewLink.
- Shared Drive files and "Shared with me" files are included.
- Search does not rank results by relevance -- results are returned in recency order by default.

### Search Tips

1. **Use filename-targeted queries when appropriate**: If the user seems to know the document name, use `name contains 'term'` in the gws query parameter.
2. **Filter by MIME type**: When looking for a specific format (e.g., spreadsheet data), filter to `mimeType='application/vnd.google-apps.spreadsheet'` to reduce noise.
3. **Date-range filtering**: Use `modifiedTime > 'YYYY-MM-DDT00:00:00'` in the query to limit results to recent documents when the user's question implies recency.
4. **Folder scoping**: If the knowledge base has a known root folder, scope searches to that folder to avoid personal drafts and unrelated files.

### Drive Result Processing

1. **Filter supported types**: Keep Google Docs, Sheets, PDF, plain text, and Markdown files. Skip images, videos, folders, and binary files.
2. **Read top results**: For the top 10 files returned per variant, read the file content using `gws drive files export --params '{"fileId":"FILE_ID","mimeType":"text/plain"}' --output /tmp/kb-[fileId].txt` for Google Docs. For binary files (PDFs), use `gws drive files get --params '{"fileId":"FILE_ID","alt":"media"}' --output /tmp/kb-[fileId].pdf`.
3. **Handle large files**: Google Sheets with many tabs -- read only the first tab unless a tab name matches the query. Long PDFs -- extract the first 5 pages of text content.
4. **Deduplicate across variants**: Same file appearing for multiple variants -- keep one entry, use the best content excerpt.

---

## Relevance Scoring Formula Details

### Keyword Density (0-40)

**Formula:**

```
key_terms = extract_key_terms(user_question)  # nouns, verbs, adjectives
matched_terms = count terms present in (title + content_snippet)
match_ratio = matched_terms / len(key_terms)

base_score = match_ratio * 35
phrase_bonus = 5 if exact_phrase_match(user_question, title + content_snippet) else 0
keyword_density_score = min(base_score + phrase_bonus, 40)
```

**Key term extraction rules:**
- Strip stop words: a, an, the, is, are, was, were, do, does, did, have, has, had, will, would, can, could, should, may, might, of, in, on, at, to, for, with, by, from, about, into, through, during, before, after, above, below, between, under, again, further, then, once, here, there, when, where, why, how, all, both, each, few, more, most, other, some, such, no, nor, not, only, own, same, so, than, too, very
- Keep proper nouns (capitalized words) regardless of part of speech.
- Keep numbers and dates as key terms.
- Treat hyphenated compounds as single terms (`CI/CD`, `follow-up`).

**Exact phrase match definition:** Three or more consecutive key terms appearing in the same order in the target text. Single-word and two-word matches do not qualify for the phrase bonus.

### Title Match (0-30)

**Formula:**

```
title_terms = tokenize(result_title)
query_terms = extract_key_terms(user_question)
title_overlap = count query_terms present in title_terms
title_ratio = title_overlap / len(query_terms)

if title contains exact query phrase:
    title_match_score = 28 + min(title_ratio * 2, 2)  # 28-30
elif title_ratio > 0.7:
    title_match_score = 20 + (title_ratio - 0.7) * 23  # 20-27
elif title_ratio > 0.3:
    title_match_score = 10 + (title_ratio - 0.3) * 22.5  # 10-19
elif title_ratio > 0:
    title_match_score = 3 + title_ratio * 20  # 3-9
else:
    title_match_score = 0
```

### Recency (0-30)

**Formula:**

```
days_since_edit = (today - last_edited_date).days

if days_since_edit <= 7:
    recency_score = 28 + (7 - days_since_edit) / 7 * 2  # 28-30
elif days_since_edit <= 30:
    recency_score = 20 + (30 - days_since_edit) / 23 * 7  # 20-27
elif days_since_edit <= 90:
    recency_score = 12 + (90 - days_since_edit) / 60 * 7  # 12-19
elif days_since_edit <= 365:
    recency_score = 5 + (365 - days_since_edit) / 275 * 6  # 5-11
else:
    recency_score = max(0, 4 - (days_since_edit - 365) / 365 * 4)  # 0-4
```

### Worked Scoring Example

**User question:** "What is our client onboarding process?"
**Key terms:** `client`, `onboarding`, `process`

**Result A**: Notion page titled "Client Onboarding Checklist", last edited 3 days ago, body contains all 3 key terms plus the phrase "client onboarding".

| Factor | Calculation | Score |
|--------|-------------|-------|
| Keyword density | 3/3 terms matched = ratio 1.0; base = 35; phrase bonus = 5 | **40** |
| Title match | 2/3 terms in title ("client", "onboarding"); ratio = 0.67; band 0.3-0.7 | **18** |
| Recency | 3 days old; 28 + (7-3)/7*2 = 29.1 | **29** |
| **Total** | | **87** |

**Result B**: Drive doc titled "2024 Process Documentation", last edited 200 days ago, body contains "onboarding" and "process" but not "client".

| Factor | Calculation | Score |
|--------|-------------|-------|
| Keyword density | 2/3 terms matched = ratio 0.67; base = 23.3; no phrase bonus | **23** |
| Title match | 1/3 terms in title ("process"); ratio = 0.33; band 0.3-0.7 | **11** |
| Recency | 200 days old; 5 + (365-200)/275*6 = 8.6 | **9** |
| **Total** | | **43** |

Result A ranks first (87 > 43). This is correct -- it is more relevant, more titled, and more recent.

---

## Content Extraction Heuristics

### Heading-Based Section Extraction

When the document contains markdown headings, use this approach to extract the most relevant section:

1. **Parse headings**: Identify all headings (H1-H4) and their positions in the document.
2. **Score headings**: For each heading, count how many query key terms appear in the heading text.
3. **Select best heading**: Pick the heading with the highest key term count. On tie, prefer the heading that appears earlier in the document.
4. **Extract section**: Capture all content from the selected heading to the next heading of the same or higher level.
5. **Apply cap**: If the section exceeds 3000 characters, truncate at the last paragraph boundary before 3000 chars.

### No-Heading Extraction

For documents without headings (flat text, short notes):

1. **Paragraph scanning**: Split the document into paragraphs (double newline boundaries).
2. **Score paragraphs**: Count query key terms in each paragraph.
3. **Greedy accumulation**: Starting from the highest-scoring paragraph, accumulate adjacent paragraphs until reaching the 3000-character cap.
4. **Context preservation**: Always include at least one paragraph before the highest-scoring paragraph (context) if the document has more than 3 paragraphs.

### Database Entry Extraction

For Notion database entries (rows):

1. **Extract all properties**: Include all visible properties (Title, Status, Tags, dates, etc.) as structured key-value pairs.
2. **Extract page body**: If the database entry has a page body (expandable content), include it after the properties.
3. **Cap applies to combined content**: Properties + body must fit within 3000 characters. Prioritize properties (they are the structured data), then append body content up to the cap.

### Edge Cases

**Empty documents**: Skip results where the body content is empty or whitespace-only. Assign a keyword density score of 0 (title match and recency still apply -- an empty but well-titled recent document may still be a useful pointer).

**Very large documents (>50,000 characters)**: Do not read the entire document for scoring. Read the first 5000 characters for the content_snippet used in keyword density scoring. For extraction, use heading-based extraction only -- do not attempt paragraph scanning on very large docs.

**Spreadsheets**: Extract the header row and the first 20 data rows. If a specific sheet tab title matches the query, extract from that tab. Format as a markdown table for readability.

**PDF content**: Some PDFs contain only scanned images with no extractable text. When the read operation returns empty or garbage characters, note `content_type: "scanned_pdf"` and score keyword density as 0. The title match and recency scores still apply.

---

## Result Deduplication

The same content may exist in both Notion and Google Drive (e.g., a document copied to Drive for sharing, or a Notion export stored in Drive).

### Deduplication Rules

1. **Title match**: If two results from different sources have identical titles (case-insensitive, ignoring file extensions), flag as potential duplicate.
2. **Content overlap**: For flagged pairs, compare the first 500 characters of content. If >80% of words match (Jaccard similarity on word sets), treat as duplicate.
3. **Resolution**: Keep the Notion version (primary source) and discard the Drive version. Note `deduplicated_from: "drive"` in the kept result's metadata.
4. **Near-duplicates**: If titles are similar but not identical (e.g., "Onboarding Guide" vs "Onboarding Guide v2"), keep both -- they may be different versions with distinct content. Note the similarity for the user.

### Jaccard Similarity Calculation

```
words_a = set(tokenize(content_a[:500]))
words_b = set(tokenize(content_b[:500]))
jaccard = len(words_a & words_b) / len(words_a | words_b)
is_duplicate = jaccard > 0.80
```

---

## Search Failure Recovery

### No Results from Any Source

1. Check if the query variants were too specific. Generate a broader variant by removing all qualifiers and dates.
2. Retry with the broadened variant.
3. If still empty, suggest alternative terms to the user based on the synonym variant.
4. Report: "No documents found matching your query. Try searching for: [synonym variant terms]."

### Partial Source Failure

- **Notion search fails but Drive works**: Report results from Drive only. Note `notion_status: "error"` in output. Suggest retrying.
- **Drive search fails but Notion works** (gws CLI unavailable or authentication not configured): This is the normal degradation path. Report Notion results. Set `drive_status: "unavailable"`.
- **Both fail**: Report the error. Do not fabricate results. Suggest the user check MCP server connections.

### Low-Quality Results

When the highest-scoring result has a composite score below 30, the results are likely not relevant to the user's question. In this case:

1. Still return the results (the user may find them useful as starting points).
2. Prepend a note: "These results may not directly answer your question."
3. Suggest query reformulation based on the synonym and broadened variants.
