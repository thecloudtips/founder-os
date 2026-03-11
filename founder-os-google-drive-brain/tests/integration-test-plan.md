# Integration Test Plan: Google Drive Brain

## Overview

This test plan validates the P18 Google Drive Brain plugin against all acceptance criteria. Tests cover all four commands (`/drive:search`, `/drive:summarize`, `/drive:ask`, `/drive:organize`), both skills (drive-navigation, document-qa), Notion activity logging, graceful degradation, and cross-cutting concerns including idempotency, lazy DB creation, and `${CLAUDE_PLUGIN_ROOT}` resolution.

## Prerequisites

- Plugin installed in Claude Code
- Google gws CLI (Drive) configured with valid `GOOGLE_CREDENTIALS_PATH` and `GOOGLE_TOKEN_PATH`
- Notion MCP configured (for activity logging tests; some tests require it absent)
- Google Drive workspace populated with:
  - At least 5 Google Docs (various topics including one named "Q1 Revenue Report")
  - At least 3 Google Sheets (including one with multiple tabs and numeric data)
  - At least 2 PDFs (one native text PDF, one scanned-image PDF with no selectable text)
  - At least 1 Google Slides file
  - A folder named "Client Projects" containing 3+ files
  - A folder named "Test Organize" containing 15+ files of mixed types, dates, and naming patterns
  - A folder with 0 files named "Empty Folder"
  - A folder with 55+ items named "Large Folder"
  - Two documents with contradictory information on the same topic (e.g., different Q3 budget figures)
  - A document updated within the last 7 days and one not modified in 200+ days

---

## /drive:search Tests

### Test 1: Basic Search With Common Term

| Field | Value |
|-------|-------|
| **Test ID** | SEARCH-01 |
| **Description** | Search with a common term returns ranked results with preview snippets |
| **Prerequisites** | Google Drive contains 5+ documents matching the term "report" |
| **Steps** | 1. Run `/drive:search report` |
|  | 2. Verify results appear as a numbered list |
|  | 3. Verify each result includes: filename, type label, freshness tier, folder breadcrumb, 500-char preview, composite score, last modified date, and Drive URL |
|  | 4. Verify results are sorted by composite score descending |
|  | 5. Verify the output header shows Scope, Type, and Results count |
| **Expected Result** | Numbered list of up to 10 results (default limit). Each result has all display fields populated. Score breakdown reflects 3-factor scoring (Keyword Density 0-40, Title Match 0-30, Recency 0-30). Preview text is coherent prose (not metadata or headings). Freshness tier matches the file's last modified date (Fresh/Current/Aging/Stale). Footer reads "Search powered by Google Drive Brain". |
| **Status** | |

---

### Test 2: Search With --type=sheets Filter

| Field | Value |
|-------|-------|
| **Test ID** | SEARCH-02 |
| **Description** | Search filtered by file type returns only Google Sheets |
| **Prerequisites** | Google Drive contains at least 3 Google Sheets and 3 Google Docs matching the term "budget" |
| **Steps** | 1. Run `/drive:search budget --type=sheets` |
|  | 2. Verify every result in the output has the type label "Sheet" |
|  | 3. Verify no Google Docs, PDFs, or other file types appear in results |
|  | 4. Verify the output header shows Type: sheets |
| **Expected Result** | All results are Google Sheets. The header line reads "Type: sheets". No non-Sheet files appear even if they match the keyword "budget" more strongly. Preview for Sheets shows header row plus condensed data rows rather than paragraph text. |
| **Status** | |

---

### Test 3: Search Scoped to Folder With --in

| Field | Value |
|-------|-------|
| **Test ID** | SEARCH-03 |
| **Description** | Search with --in flag scopes results to the specified folder |
| **Prerequisites** | Folder "Client Projects" exists in Drive with 3+ files. At least 2 files in "Client Projects" and 2 files outside it match the query term "proposal" |
| **Steps** | 1. Run `/drive:search proposal --in="Client Projects"` |
|  | 2. Verify the Scope line reads "Folder: My Drive > Client Projects" (or actual breadcrumb) |
|  | 3. Verify all returned results have breadcrumb paths rooted in "Client Projects" |
|  | 4. Verify files outside "Client Projects" do not appear |
| **Expected Result** | Results are scoped to the "Client Projects" folder and its subfolders. Scope header shows the resolved folder breadcrumb. Files in other locations are excluded even if they score higher on relevance. |
| **Status** | |

---

### Test 4: Search With --limit=3

| Field | Value |
|-------|-------|
| **Test ID** | SEARCH-04 |
| **Description** | Search with --limit flag caps displayed results |
| **Prerequisites** | Google Drive contains 5+ files matching the term "meeting" |
| **Steps** | 1. Run `/drive:search meeting --limit=3` |
|  | 2. Count the number of results displayed in the numbered list |
|  | 3. Verify the Results count in the header shows the total results found (before limiting) |
|  | 4. Verify only the top 3 by score are displayed |
| **Expected Result** | Exactly 3 results displayed. The header Results count may be higher than 3 (showing total found). The 3 displayed results are the highest-scoring. Results beyond position 3 are omitted. |
| **Status** | |

---

### Test 5: Search With No Results

| Field | Value |
|-------|-------|
| **Test ID** | SEARCH-05 |
| **Description** | Search with no matching files shows suggestions and query variants |
| **Prerequisites** | Google Drive does not contain files matching "xyznonexistentterm2026" |
| **Steps** | 1. Run `/drive:search xyznonexistentterm2026` |
|  | 2. Verify the output shows "Results: 0 files" |
|  | 3. Verify the no-results block appears with suggestions |
|  | 4. Verify the 2-3 query variants that were tried are listed |
| **Expected Result** | Output displays the no-results format: `No files found matching "xyznonexistentterm2026"`. Suggestions section includes: try broader search terms (with the query variants listed), remove --type filter, remove --in filter. The 2-3 query variants generated by the drive-navigation skill are shown explicitly. Footer still present. |
| **Status** | |

---

### Test 6: Search With Missing Query

| Field | Value |
|-------|-------|
| **Test ID** | SEARCH-06 |
| **Description** | Search with no query argument prompts the user for input |
| **Prerequisites** | None |
| **Steps** | 1. Run `/drive:search` with no arguments |
|  | 2. Observe the response |
| **Expected Result** | Plugin prompts: "What would you like to search for in Google Drive? Usage: `/drive:search [query]`" and stops execution. No Drive search is performed. No Notion logging occurs. |
| **Status** | |

---

## /drive:summarize Tests

### Test 7: Summarize a Google Doc

| Field | Value |
|-------|-------|
| **Test ID** | SUMMARIZE-01 |
| **Description** | Summarize a Google Doc produces executive summary and key points |
| **Prerequisites** | Google Doc named "Q1 Revenue Report" exists in Drive with substantive content (multiple sections, headings, data) |
| **Steps** | 1. Run `/drive:summarize "Q1 Revenue Report"` |
|  | 2. Verify the metadata header shows correct Type, Last Modified, and Depth: quick |
|  | 3. Verify Executive Summary is 2-3 sentences |
|  | 4. Verify Key Points section contains 5-8 bullet points |
|  | 5. Verify each key point is a complete standalone statement |
|  | 6. Verify the Drive link appears in the footer |
| **Expected Result** | Summary output matches the quick-depth format. Executive Summary covers the document's purpose and key content in 2-3 sentences. Key Points are 5-8 substantive bullets that accurately reflect the document's content. No Detailed Analysis section (quick mode). Footer includes Drive link and "Summarized by Google Drive Brain". |
| **Status** | |

---

### Test 8: Summarize a Google Sheet

| Field | Value |
|-------|-------|
| **Test ID** | SUMMARIZE-02 |
| **Description** | Summarize a Google Sheet produces data highlights with tab counts and metrics |
| **Prerequisites** | Google Sheet with at least 2 tabs, numeric data, and identifiable header rows exists in Drive |
| **Steps** | 1. Run `/drive:summarize [sheet-name-or-id]` |
|  | 2. Verify Executive Summary is present |
|  | 3. Verify a Data Highlights section appears (not Key Points) |
|  | 4. Verify tab count is listed |
|  | 5. Verify each tab shows: tab name, row count, and key metrics or column names |
| **Expected Result** | Output includes a Data Highlights section with: Tabs count, per-tab breakdown listing tab name, row count, columns, and key metrics (totals, averages, or notable values if identifiable). Executive Summary covers the spreadsheet's purpose. No generic "Key Points" section -- Sheets use Data Highlights instead. |
| **Status** | |

---

### Test 9: Summarize With --depth=detailed

| Field | Value |
|-------|-------|
| **Test ID** | SUMMARIZE-03 |
| **Description** | Detailed depth produces section-by-section analysis |
| **Prerequisites** | Google Doc with at least 4 distinct headings/sections exists in Drive |
| **Steps** | 1. Run `/drive:summarize "Q1 Revenue Report" --depth=detailed` |
|  | 2. Verify the Depth field in the header reads "detailed" |
|  | 3. Verify Executive Summary and Key Points are present (same as quick) |
|  | 4. Verify a Detailed Analysis section appears with subsections |
|  | 5. Verify each subsection corresponds to a heading in the source document |
|  | 6. Verify each subsection contains 2-5 sentences of analysis |
| **Expected Result** | Output includes all quick-mode sections plus a Detailed Analysis section. Each subsection is an H4 heading matching a heading from the source document. Subsection analysis is 2-5 sentences covering content, takeaways, and notable details. Sections with data (tables, metrics) highlight significant items. |
| **Status** | |

---

### Test 10: Summarize With --output=PATH

| Field | Value |
|-------|-------|
| **Test ID** | SUMMARIZE-04 |
| **Description** | Summary is written to a local file using the summary template |
| **Prerequisites** | Google Doc exists in Drive. `${CLAUDE_PLUGIN_ROOT}/templates/summary-template.md` exists and is readable |
| **Steps** | 1. Run `/drive:summarize "Q1 Revenue Report" --output=./summaries/q1-summary.md` |
|  | 2. Verify the file is created at the specified path |
|  | 3. Open the file and verify all `{{PLACEHOLDER}}` variables have been replaced |
|  | 4. Verify the chat output also displays the summary |
|  | 5. Verify the message "Summary saved to [path]" appears |
| **Expected Result** | File written at `./summaries/q1-summary.md`. File content uses the template structure with all placeholders replaced: `{{DOCUMENT_TITLE}}`, `{{FILE_TYPE}}`, `{{LAST_MODIFIED}}`, `{{FILE_ID}}`, `{{DRIVE_LINK}}`, `{{DEPTH_LEVEL}}`, `{{EXECUTIVE_SUMMARY}}`, `{{KEY_POINTS}}`, `{{GENERATED_DATE}}`. No raw `{{...}}` tokens remain in the file. Chat output also shows the full summary. Confirmation message printed. |
| **Status** | |

---

### Test 11: Summarize With Invalid File Name

| Field | Value |
|-------|-------|
| **Test ID** | SUMMARIZE-05 |
| **Description** | Summarize with a file name that does not exist in Drive shows a not-found message |
| **Prerequisites** | No file named "Nonexistent Document XYZ 9999" exists in Drive |
| **Steps** | 1. Run `/drive:summarize "Nonexistent Document XYZ 9999"` |
|  | 2. Observe the error output |
| **Expected Result** | Output displays: "No file found matching 'Nonexistent Document XYZ 9999'. Try a more specific name or use a Google Drive file ID." No summary is generated. No Notion logging occurs. No stack trace or raw error. |
| **Status** | |

---

### Test 12: Summarize a Scanned PDF

| Field | Value |
|-------|-------|
| **Test ID** | SUMMARIZE-06 |
| **Description** | Summarize a scanned-image PDF that yields no extractable text shows an appropriate note |
| **Prerequisites** | A scanned-image PDF (no selectable text, no embedded OCR text) exists in Drive |
| **Steps** | 1. Run `/drive:summarize [scanned-pdf-name-or-id]` |
|  | 2. Verify the plugin attempts content extraction |
|  | 3. Verify the output communicates that text could not be extracted |
| **Expected Result** | Output displays: "Unable to extract content from this file. It may be empty, password-protected, or in an unsupported format." The plugin does not attempt OCR beyond what the Drive API provides natively. No fabricated summary is generated. |
| **Status** | |

---

## /drive:ask Tests

### Test 13: Ask a Factual Question With Citations

| Field | Value |
|-------|-------|
| **Test ID** | ASK-01 |
| **Description** | Factual question produces a cited answer with [1][2] inline references |
| **Prerequisites** | Google Drive contains a document with a clear, factual answer to "What is our refund policy?" (e.g., a customer policies doc) |
| **Steps** | 1. Run `/drive:ask What is our refund policy?` |
|  | 2. Verify the answer contains inline citation markers [1], [2], etc. |
|  | 3. Verify a Sources block appears at the bottom with numbered entries |
|  | 4. Verify each source entry includes a document title and Drive URL |
|  | 5. Verify the Confidence level is displayed (High, Medium, or Low) |
|  | 6. Verify the footer shows files searched count, total results, and top relevance score |
| **Expected Result** | Answer has a direct response (1-3 sentences) followed by supporting detail. Inline citations [1], [2], etc. appear after factual claims. Sources block lists 1-5 entries with titles and Drive URLs. Confidence is High or Medium (since the answer was found). Footer shows search statistics. Answer does not contain fabricated information beyond what the source documents state. |
| **Status** | |

---

### Test 14: Ask With --in=folder Scoping

| Field | Value |
|-------|-------|
| **Test ID** | ASK-02 |
| **Description** | Ask with --in flag scopes the search to a specific folder |
| **Prerequisites** | Folder "Client Projects" contains documents with answer-relevant content. Documents outside "Client Projects" also match the question |
| **Steps** | 1. Run `/drive:ask What were the key decisions from the kickoff? --in="Client Projects"` |
|  | 2. Verify all cited sources in the Sources block are from the "Client Projects" folder |
|  | 3. Verify sources outside "Client Projects" are not cited |
| **Expected Result** | Answer is synthesized only from documents within "Client Projects" and its subfolders. Sources block lists only files from that folder. If the folder does not contain sufficient information, the no-answer pathway activates with suggestions to search more broadly. |
| **Status** | |

---

### Test 15: Ask With No Relevant Documents

| Field | Value |
|-------|-------|
| **Test ID** | ASK-03 |
| **Description** | Ask a question with no relevant Drive documents triggers the no-answer pathway |
| **Prerequisites** | Google Drive does not contain documents about "quantum entanglement physics theory" |
| **Steps** | 1. Run `/drive:ask What is the quantum entanglement decoherence threshold?` |
|  | 2. Verify the no-answer pathway activates |
|  | 3. Verify closest documents are listed (if any tangential results exist) |
|  | 4. Verify alternative search terms are suggested |
|  | 5. Verify a pointer to `/drive:search` is provided |
| **Expected Result** | Output reads: "I could not find a definitive answer to this in Google Drive." Closest documents section shows 0-3 tangential results (if any) with titles and descriptions of what they cover. Alternative search terms section suggests 2-3 rephrased queries. Next steps suggest `/drive:search` with different keywords. No fabricated answer is generated. |
| **Status** | |

---

### Test 16: Ask a Multi-Part Question

| Field | Value |
|-------|-------|
| **Test ID** | ASK-04 |
| **Description** | Multi-part question surfaces a partial coverage note when not all parts are answered |
| **Prerequisites** | Google Drive contains a document with Q3 targets but no document identifying owners of each target |
| **Steps** | 1. Run `/drive:ask What are our Q3 targets and who owns each one?` |
|  | 2. Verify the answer addresses the covered component (Q3 targets) |
|  | 3. Verify a partial coverage note appears for the uncovered component (owners) |
| **Expected Result** | Answer provides the Q3 targets with citations. A note appended at the bottom reads: "This answer covers [Q3 targets]. No documents were found for [target ownership]." The uncovered component is clearly identified. The plugin does not fabricate owner information. |
| **Status** | |

---

### Test 17: Ask About Conflicting Documents

| Field | Value |
|-------|-------|
| **Test ID** | ASK-05 |
| **Description** | Question answered by conflicting documents discloses the conflict with reconciliation |
| **Prerequisites** | Two documents exist in Drive with contradictory information on the same topic (e.g., Document A says Q3 budget is $500K, Document B says $750K). Documents have different last-modified dates |
| **Steps** | 1. Run `/drive:ask What is the Q3 budget?` |
|  | 2. Verify the answer references both sources |
|  | 3. Verify the conflict is disclosed, not silently resolved |
|  | 4. Verify the reconciliation follows precedence rules (date, specificity, authority, transparent disagreement) |
| **Expected Result** | Answer acknowledges the discrepancy. If date precedence applies, the newer source is preferred with a note: "As of [date], [newer value] [citation]. Note: an earlier document stated [older value] [citation]." Both documents are cited. The conflict is never hidden. If no precedence rule resolves the conflict, both versions are presented explicitly with a suggestion to verify with the document owner. |
| **Status** | |

---

### Test 18: Confidence Assessment Verification

| Field | Value |
|-------|-------|
| **Test ID** | ASK-06 |
| **Description** | Confidence level (High/Medium/Low) is correctly assigned based on documented criteria |
| **Prerequisites** | Prepare three separate question scenarios: (a) a question answered by 2+ recent, agreeing sources, (b) a question answered by a single strong but older source, (c) a question with only weak keyword matches |
| **Steps** | 1. Run scenario (a): ask a well-documented question with multiple recent sources |
|  | 2. Verify confidence is "High" |
|  | 3. Run scenario (b): ask a question answered by one authoritative but >90-day-old source |
|  | 4. Verify confidence is "Medium" |
|  | 5. Run scenario (c): ask a question with only tangential keyword matches |
|  | 6. Verify confidence is "Low" and the low-confidence warning is prepended |
| **Expected Result** | Scenario (a): Confidence: High (2+ agreeing recent sources, strong match, no conflicts). Scenario (b): Confidence: Medium (single strong source, older than 90 days). Scenario (c): Confidence: Low with prepended warning "Low confidence -- this answer is based on limited or potentially outdated sources. Verify before acting on it." Confidence criteria match the document-qa skill's definitions precisely. |
| **Status** | |

---

## /drive:organize Tests

### Test 19: Organize With --strategy=project

| Field | Value |
|-------|-------|
| **Test ID** | ORGANIZE-01 |
| **Description** | Project strategy groups files by detected topic/project |
| **Prerequisites** | Folder "Test Organize" contains 15+ files with at least 3 recognizable topic clusters (e.g., 4 files with "Phoenix" in the name, 3 with "Acme", 5 with "Marketing") |
| **Steps** | 1. Run `/drive:organize "Test Organize" --strategy=project` |
|  | 2. Verify the current structure is displayed as a tree |
|  | 3. Verify the recommended structure shows topic-based folder groupings |
|  | 4. Verify the Move Suggestions table lists each file with current location, suggested location, and reason |
|  | 5. Verify ungrouped files are placed in a "Miscellaneous" suggestion |
|  | 6. Verify the disclaimer "These are recommendations only. No files have been moved or modified." appears |
| **Expected Result** | Recommended structure shows folders named after detected topics (e.g., "Project Phoenix", "Client - Acme Corp", "Marketing Assets"). Each folder lists the files that belong in it. Move Suggestions table provides a reason for each grouping. Ungrouped files go to "Miscellaneous". Tree structure accurately reflects the current folder contents. |
| **Status** | |

---

### Test 20: Organize With --strategy=date

| Field | Value |
|-------|-------|
| **Test ID** | ORGANIZE-02 |
| **Description** | Date strategy groups files by year and month |
| **Prerequisites** | Folder "Test Organize" contains files with last-modified dates spanning at least 2 months |
| **Steps** | 1. Run `/drive:organize "Test Organize" --strategy=date` |
|  | 2. Verify the recommended structure uses `YYYY/MM-MonthName/` format |
|  | 3. Verify files are grouped by their last-modified date into the correct year/month folders |
|  | 4. Verify the Move Suggestions table reflects date-based grouping |
| **Expected Result** | Recommended structure shows folders like `2026/01-January/`, `2026/02-February/`, `2025/12-December/`. Each file is placed in the folder matching its last-modified date. Files with unknown dates are placed in an "Unsorted" suggestion. |
| **Status** | |

---

### Test 21: Organize With --strategy=type

| Field | Value |
|-------|-------|
| **Test ID** | ORGANIZE-03 |
| **Description** | Type strategy groups files by file type |
| **Prerequisites** | Folder "Test Organize" contains a mix of Google Docs, Google Sheets, PDFs, and at least one other type |
| **Steps** | 1. Run `/drive:organize "Test Organize" --strategy=type` |
|  | 2. Verify the recommended structure uses type-based folder names: "Documents", "Spreadsheets", "Presentations", "PDFs", "Images", "Other" |
|  | 3. Verify MIME type to folder name mapping is correct |
|  | 4. Verify any type folder with >10 files has sub-groupings by topic |
| **Expected Result** | Files are grouped into type folders matching MIME type mappings: Google Docs -> "Documents", Google Sheets -> "Spreadsheets", Google Slides -> "Presentations", PDF -> "PDFs", image/* -> "Images", everything else -> "Other". If any single type folder contains more than 10 files, it is further sub-grouped by topic. |
| **Status** | |

---

### Test 22: Organize an Empty Folder

| Field | Value |
|-------|-------|
| **Test ID** | ORGANIZE-04 |
| **Description** | Organizing an empty folder produces a clear "nothing to organize" message |
| **Prerequisites** | Folder "Empty Folder" exists in Drive with 0 files and 0 subfolders |
| **Steps** | 1. Run `/drive:organize "Empty Folder"` |
|  | 2. Observe the output |
| **Expected Result** | Output displays: "The folder 'Empty Folder' is empty. Nothing to organize." No tree structure, no recommendations, no move suggestions. No Notion logging occurs (nothing to log). |
| **Status** | |

---

### Test 23: CRITICAL -- Verify Recommend-Only Behavior

| Field | Value |
|-------|-------|
| **Test ID** | ORGANIZE-05 |
| **Description** | Confirm that /drive:organize never moves, renames, creates, or deletes any files or folders |
| **Prerequisites** | Folder "Test Organize" contains 15+ files. Record exact file names, locations, and folder structure before the test |
| **Steps** | 1. Record the complete state of "Test Organize" folder: all file names, file IDs, folder structure, timestamps |
|  | 2. Run `/drive:organize "Test Organize" --strategy=project` |
|  | 3. After execution completes, list the contents of "Test Organize" again |
|  | 4. Compare the before and after states |
|  | 5. Verify no new folders were created in Drive |
|  | 6. Verify no files were moved, renamed, or deleted |
|  | 7. Verify the disclaimer "These are recommendations only. No files have been moved or modified." is present in output |
| **Expected Result** | Folder state is 100% identical before and after the command. Zero Drive write operations were executed. No files moved, renamed, or deleted. No folders created. The output contains only suggestions. The disclaimer footer confirms recommend-only behavior. This is the most critical safety test for the entire plugin. |
| **Status** | |

---

### Test 24: Organize a Large Folder (>50 Items)

| Field | Value |
|-------|-------|
| **Test ID** | ORGANIZE-06 |
| **Description** | Large folder analysis is capped at 50 items with a note about the total |
| **Prerequisites** | Folder "Large Folder" contains 55+ files |
| **Steps** | 1. Run `/drive:organize "Large Folder"` |
|  | 2. Verify the output notes the total file count |
|  | 3. Verify the analysis covers only the first 50 items |
|  | 4. Verify the cap note is displayed |
| **Expected Result** | Output header shows "Files analyzed: 50". A note appears: "Analyzing first 50 of [N] items." where [N] is the total count (e.g., 55). Recommendations are based on the 50 analyzed files only. The remaining files beyond 50 are not included in move suggestions or pattern analysis. |
| **Status** | |

---

## Cross-Cutting Tests

### Test 25: gws CLI (Drive) Unavailable

| Field | Value |
|-------|-------|
| **Test ID** | CROSS-01 |
| **Description** | All commands stop with install instructions when gws CLI (Drive) is not connected |
| **Prerequisites** | gws CLI (`gws drive`) is disconnected or not configured |
| **Steps** | 1. Run `/drive:search report` |
|  | 2. Verify it stops with a gws CLI (Drive) install message |
|  | 3. Run `/drive:summarize "Q1 Revenue Report"` |
|  | 4. Verify it stops with a gws CLI (Drive) install message |
|  | 5. Run `/drive:ask What is our refund policy?` |
|  | 6. Verify it stops with a gws CLI (Drive) install message |
|  | 7. Run `/drive:organize "Client Projects"` |
|  | 8. Verify it stops with a gws CLI (Drive) install message |
| **Expected Result** | All four commands display: "gws CLI (`gws drive`) is not connected. Install it per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`:" followed by setup steps mentioning `GOOGLE_CREDENTIALS_PATH` and `GOOGLE_TOKEN_PATH`. No search, summary, answer, or analysis is attempted. No Notion logging occurs. No stack trace or raw error output. |
| **Status** | |

---

### Test 26: Notion MCP Unavailable

| Field | Value |
|-------|-------|
| **Test ID** | CROSS-02 |
| **Description** | All commands continue successfully without Notion logging when Notion MCP is unavailable |
| **Prerequisites** | Google gws CLI (Drive) connected. Notion MCP disconnected or not configured |
| **Steps** | 1. Run `/drive:search report` -- verify search results appear normally |
|  | 2. Run `/drive:summarize "Q1 Revenue Report"` -- verify summary appears normally |
|  | 3. Run `/drive:ask What is our refund policy?` -- verify answer appears normally |
|  | 4. Run `/drive:organize "Test Organize"` -- verify recommendations appear normally |
|  | 5. Verify none of the outputs mention Notion, logging, or activity tracking |
| **Expected Result** | All four commands produce their full user-facing output without any mention of Notion. No error messages about Notion appear. Activity logging is silently skipped. The commands behave identically to when Notion is connected, minus the behind-the-scenes logging. |
| **Status** | |

---

### Test 27: Notion Activity DB Discovery

| Field | Value |
|-------|-------|
| **Test ID** | CROSS-03 |
| **Description** | Commands discover the activity database using HQ name first, falling back to legacy name |
| **Prerequisites** | Notion MCP connected. Database "[FOS] Activity Log" exists in Notion |
| **Steps** | 1. Verify "[FOS] Activity Log" database exists in Notion |
|  | 2. Run `/drive:search report` |
|  | 3. Verify the activity entry was logged to "[FOS] Activity Log" |
|  | 4. Remove "[FOS] Activity Log" and create "Founder OS HQ - Activity Log" instead |
|  | 5. Run `/drive:search report` again |
|  | 6. Verify the activity entry was logged to "Founder OS HQ - Activity Log" (second fallback) |
|  | 7. Remove that and create "Google Drive Brain - Activity" instead |
|  | 8. Run `/drive:search report` again and verify it logs to "Google Drive Brain - Activity" (legacy fallback) |
|  | 9. Remove all databases and run `/drive:search report` |
|  | 10. Verify logging is silently skipped and search results still appear |
| **Expected Result** | The plugin searches for "[FOS] Activity Log" first. If not found, tries "Founder OS HQ - Activity Log". If not found, falls back to "Google Drive Brain - Activity". If none exists, logging is silently skipped and the command completes normally. No database is created automatically. |
| **Status** | |

---

### Test 28: Idempotent Re-Runs

| Field | Value |
|-------|-------|
| **Test ID** | CROSS-04 |
| **Description** | Running the same command with the same query on the same day updates the existing Notion entry instead of creating a duplicate |
| **Prerequisites** | Notion MCP connected. "[FOS] Activity Log" (or fallback "Founder OS HQ - Activity Log" / "Google Drive Brain - Activity") database exists with at least one entry |
| **Steps** | 1. Run `/drive:search report` and note the Notion entry |
|  | 2. Count the total entries in the activity log database |
|  | 3. Run `/drive:search report` again on the same calendar day |
|  | 4. Count the total entries again |
|  | 5. Verify the count has not increased |
|  | 6. Verify the existing entry's Generated At timestamp was updated |
|  | 7. Repeat with `/drive:ask What is our refund policy?` (run twice same day) |
|  | 8. Verify same idempotent behavior for the "ask" Command Type |
| **Expected Result** | Entry count does not increase on re-run. The existing entry (matched by Query + same calendar day + Command Type) is updated with fresh data (Files Found, Top Result, Generated At). No duplicate rows are created. This applies across all four command types. |
| **Status** | |

---

### Test 29: Graceful Degradation on Partial Failures

| Field | Value |
|-------|-------|
| **Test ID** | CROSS-05 |
| **Description** | When one of the 2-3 query variants fails, the command continues with successful results |
| **Prerequisites** | Google gws CLI (Drive) connected. A search query that produces results from at least 2 query variants |
| **Steps** | 1. Run `/drive:search report` (which generates 2-3 query variants internally) |
|  | 2. Verify results are returned even if one variant produces an error or empty result |
|  | 3. Run `/drive:ask What are our HR policies?` |
|  | 4. Verify the answer is synthesized from whichever variants returned results |
|  | 5. Verify no individual query variant errors are surfaced to the user |
| **Expected Result** | Results are produced from the successful query variants. Failed variants are silently dropped. No error messages about individual variant failures appear in the output. The composite result set reflects all successful variants merged and deduplicated. For /drive:ask, if at least one variant produces relevant documents, the answer is synthesized normally. |
| **Status** | |

---

### Test 30: CLAUDE_PLUGIN_ROOT Resolution

| Field | Value |
|-------|-------|
| **Test ID** | CROSS-06 |
| **Description** | All `${CLAUDE_PLUGIN_ROOT}` references in skills and commands resolve correctly |
| **Prerequisites** | Plugin installed in Claude Code |
| **Steps** | 1. Run `/drive:search test` and verify the drive-navigation skill loads without path errors |
|  | 2. Run `/drive:summarize [file] --output=./test-output.md` and verify the summary template at `${CLAUDE_PLUGIN_ROOT}/templates/summary-template.md` loads correctly |
|  | 3. Run `/drive:ask test question` and verify both drive-navigation and document-qa skills load |
|  | 4. Run `/drive:organize "Test Organize"` and verify drive-navigation skill loads |
|  | 5. Verify no "file not found" or "path not resolved" errors referencing `${CLAUDE_PLUGIN_ROOT}` |
| **Expected Result** | All skill files resolve correctly: `skills/drive-navigation/SKILL.md`, `skills/document-qa/SKILL.md`, `templates/summary-template.md`, and all `references/` files within skills. No path resolution errors. The `${CLAUDE_PLUGIN_ROOT}` variable is replaced with the actual plugin installation path at runtime. Commands that reference skills via `${CLAUDE_PLUGIN_ROOT}/skills/...` can read those files without error. |
| **Status** | |

---

## Test Execution Summary

| Section | Test Count | Passed | Failed | Blocked |
|---------|-----------|--------|--------|---------|
| /drive:search | 6 | | | |
| /drive:summarize | 6 | | | |
| /drive:ask | 6 | | | |
| /drive:organize | 6 | | | |
| Cross-Cutting | 6 | | | |
| **Total** | **30** | | | |

## Notes

- Tests should be executed with Drive and Notion MCP both connected unless the specific test requires otherwise (Tests 25, 26).
- Test 23 (recommend-only verification) is the highest-priority safety test. It must pass before any release.
- Tests 25 and 26 require toggling MCP availability; run these in a separate session with the relevant MCP server disabled.
- For Test 27, ensure the appropriate databases exist or are removed per the test steps to validate discovery and fallback behavior.
- Idempotent tests (Test 28) must be run on the same calendar day -- running across midnight will correctly create a new entry.
