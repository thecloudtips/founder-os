# Drive Navigation File Type Handling

Detailed reference for parsing, extracting, and previewing content from each file type encountered in Google Drive.

---

## Google Docs

Google Docs are the primary document type in Drive. The gws CLI (Drive) read tool exports them as markdown-formatted text.

### Content Extraction

1. **Read via gws CLI** -- run `gws drive files export --params '{"fileId":"FILE_ID","mimeType":"text/plain"}' --output /tmp/doc.txt` on the file ID. The returned content is plain text with markdown formatting preserved (headings, bold, italic, links, lists).
2. **Full text is searchable** -- all content in a Google Doc is indexed by Drive search. Query matches may appear anywhere in the body, not just the title.
3. **Extraction cap** -- extract the first 3000 characters of the exported markdown. If the document exceeds 3000 characters, apply heading-based section extraction:
   - Parse all headings (H1-H4) and their character positions.
   - Score each heading by counting how many query key terms appear in the heading text.
   - Select the heading with the highest key term count. On tie, prefer the heading appearing earlier.
   - Extract from that heading to the next heading of the same or higher level.
   - If the extracted section exceeds 3000 characters, truncate at the last paragraph boundary before 3000 chars.
4. **No-heading fallback** -- if the document contains no headings, extract the first 3000 characters starting from the first non-empty paragraph.

### Preview Generation

- Use the first paragraph after the document title (skip the H1 if present).
- Strip markdown formatting: remove `#`, `**`, `_`, `[text](url)` patterns.
- Truncate at 500 characters at the nearest word boundary, append "..." if truncated.

### Edge Cases

- **Empty docs** -- set preview to `"[No preview available]"` and keyword density score to 0. Title match and recency scores still apply.
- **Very large docs (>50,000 characters)** -- read only the first 5000 characters for keyword density scoring. Use heading-based extraction only; do not attempt full-document paragraph scanning.
- **Docs with embedded images** -- image references appear as empty lines or placeholder text in the export. Ignore these; extract surrounding text normally.

---

## Google Sheets

Spreadsheets contain structured tabular data organized into tabs (worksheets). Extraction requires tab-aware handling.

### Tab Structure

1. **Enumerate tabs** -- retrieve the list of tab names within the spreadsheet. Each tab is an independent data set.
2. **Tab selection** -- if the user's query matches a specific tab name (e.g., "Q1 Revenue" tab in a "Financial Reports" sheet), extract from that tab. Otherwise, default to the first tab.
3. **Multiple relevant tabs** -- if more than one tab name matches query keywords, extract from each matching tab separately and concatenate, respecting the 3000-character cap across all tabs.

### Header Row Detection

1. **First row convention** -- treat the first non-empty row as the header row in the majority of cases.
2. **Frozen rows** -- if the spreadsheet metadata indicates frozen rows, use the frozen row(s) as header(s).
3. **No clear header** -- if the first row contains only numbers or dates without text labels, note `header_detected: false` and treat all rows as data.

### Cell Data Extraction

1. **Read cell values** -- extract values as plain strings. Preserve number formatting where visible (e.g., "$1,234.56", "85%").
2. **Formula results** -- extract the computed value, not the formula itself. Formulas are not useful for search relevance.
3. **Empty cells** -- represent as blank in the output. Do not fill with placeholders.
4. **Merged cells** -- treat as a single cell with the merged content. Note the span if relevant to layout.

### Structured Data Representation

Format extracted spreadsheet data as a markdown table for readability:

```
| Header A | Header B | Header C |
|----------|----------|----------|
| Value 1  | Value 2  | Value 3  |
| Value 4  | Value 5  | Value 6  |
```

- Include the header row and up to 20 data rows.
- If the sheet contains more than 20 rows, append a note: `[... N more rows not shown]`.
- Cap total extraction at 3000 characters across all tabs.

### Preview Generation

- Format as: header row + first 3 data rows as a condensed markdown table.
- Truncate column values to 20 characters each if needed to fit within the 500-character preview cap.
- If the sheet has many columns (>8), show only the first 6 columns and append `[+ N more columns]`.

---

## PDFs

PDF handling depends on whether the file contains selectable (native) text or scanned images.

### Native PDFs (Selectable Text)

1. **Text extraction** -- use the gws CLI (Drive) read tool to extract text content. Native PDFs return clean, structured text.
2. **Extraction cap** -- extract the first 3000 characters. For longer PDFs, focus on the first 5 pages of text content.
3. **Layout preservation** -- PDFs may have multi-column layouts. The extracted text may interleave columns. Accept this as-is; do not attempt to reconstruct layout.
4. **Headers and footers** -- page headers, footers, and page numbers often appear in extracted text. These are noise. Strip repeated short lines (<20 characters) that appear at regular intervals.

### Scanned PDFs (Image-Only)

1. **Detection** -- when the Drive read tool returns empty content, whitespace-only content, or garbled characters (high ratio of non-alphanumeric characters), classify as a scanned PDF.
2. **Marking** -- set `scanned: true` in the result metadata. Set keyword density score to 0.
3. **Title and recency still apply** -- the filename and modification date remain valid scoring signals. A scanned PDF titled "Signed Contract - Acme Corp" still matches a query for "Acme contract" on title match alone.
4. **OCR caveat** -- do not attempt OCR within this skill. If the user needs content from scanned PDFs, suggest uploading to a service that provides OCR or using a dedicated OCR tool.

### Preview Generation

- Use the first 500 characters of extracted text.
- Strip page numbers, headers, and footers (repeated short lines).
- If the PDF is scanned, set preview to `"[Scanned PDF - text not extractable]"`.

---

## Plain Text and Markdown Files

These are the simplest file types to handle. Content is read directly without conversion.

### Content Extraction

1. **Direct read** -- call the Drive read tool. The returned content is the file's raw text.
2. **Markdown formatting** -- for `.md` files, the content already contains markdown formatting. Preserve it for extraction; strip it for previews.
3. **Plain text** -- `.txt` files have no formatting. Read as-is.
4. **Encoding** -- assume UTF-8 encoding. If the read tool returns encoding errors, note `encoding_error: true` and extract whatever clean text is available.

### Extraction Cap

- Apply the standard 3000-character cap.
- For files shorter than 3000 characters, extract the full content.

### Preview Generation

- Use the first 500 characters of content.
- For markdown files, strip formatting before generating the preview.
- For plain text, use the content directly.

---

## Google Slides (Presentations)

Presentations contain text distributed across slides, with optional speaker notes.

### Slide-by-Slide Extraction

1. **Enumerate slides** -- retrieve the list of slides in order.
2. **Extract text per slide** -- for each slide, extract all visible text (titles, subtitles, body text, text boxes). Concatenate text elements within a slide with newlines.
3. **Speaker notes** -- extract speaker notes separately from slide text. Append notes after the slide's visible text, prefixed with `[Speaker notes:]`.
4. **Slide numbering** -- prefix each slide's content with `## Slide N` for structure.

### Extraction Format

```
## Slide 1
Project Kickoff - Acme Corp
Q1 2026 Roadmap Overview

[Speaker notes:] Key point: emphasize timeline changes from last quarter.

## Slide 2
Agenda
1. Revenue targets
2. Product roadmap
3. Team updates
```

### Extraction Cap

- Extract up to 3000 characters across all slides.
- If the presentation exceeds the cap, extract slides sequentially until the cap is reached. Note `[... N more slides not shown]`.
- Prioritize earlier slides (they typically contain the most important context).

### Preview Generation

- Use the title slide's text (Slide 1) as the preview.
- If Slide 1 text is short (<100 chars), append text from Slide 2.
- Strip slide numbering from the preview.
- Cap at 500 characters.

---

## Binary Files (Images, Videos, ZIP, etc.)

Binary files do not contain extractable text and are not useful for search-based workflows.

### Handling Rules

1. **Skip silently** -- when binary files appear in search results or folder listings, exclude them from the scored result set. Do not log warnings, do not report them as errors.
2. **MIME type detection** -- identify binary files by MIME type:
   - Images: `image/png`, `image/jpeg`, `image/gif`, `image/svg+xml`, `image/webp`
   - Videos: `video/mp4`, `video/quicktime`, `video/x-msvideo`, `video/webm`
   - Archives: `application/zip`, `application/x-tar`, `application/gzip`, `application/x-rar-compressed`
   - Audio: `audio/mpeg`, `audio/wav`, `audio/ogg`
   - Executables and other binaries: `application/octet-stream`, `application/x-executable`
3. **Folder listings** -- when listing folder contents, include binary files in the display (they exist in the folder) but mark them with their type and do not attempt content extraction.
4. **Explicit requests** -- if the user specifically asks for an image or video file by name, return its metadata (filename, type, size, last modified, URL) without content extraction. Note that content preview is not available for this file type.

---

## Content Truncation Rules Summary

| Context | Character Cap | Truncation Method |
|---------|--------------|-------------------|
| Content extraction (scoring) | 3000 chars | Heading-based section or first 3000 chars |
| Preview generation | 500 chars | First paragraph, word boundary truncation |
| Keyword density input | 3000 chars (title + content combined) | Title always included in full; content fills remaining cap |
| Very large files (>50K chars) | 5000 chars read for scoring | First 5000 chars only; heading extraction for content |
| Spreadsheet rows | 20 data rows max | Header + first 20 rows; note remaining count |
| Presentation slides | 3000 chars across all slides | Sequential slide extraction until cap reached |

Apply truncation consistently across all file types. When truncating, always cut at a word or paragraph boundary -- never mid-word. Append "..." when the content was truncated to signal that more content exists.
