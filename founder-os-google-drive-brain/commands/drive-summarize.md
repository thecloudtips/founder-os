---
description: Generate summary of a Google Drive document
argument-hint: "[file-id-or-name] [--depth=quick|detailed] [--output=PATH]"
allowed-tools: ["Read", "Write"]
---

# Drive Summarize

Generate a structured summary of a Google Drive document. Supports quick (2-3 paragraphs + key points) and detailed (section-by-section analysis) depth levels. Optionally save to a local file using the summary template.

## Load Skills

Read the document-qa skill at `${CLAUDE_PLUGIN_ROOT}/skills/document-qa/SKILL.md` for content extraction, summary generation, and file type handling.

Read the drive-navigation skill at `${CLAUDE_PLUGIN_ROOT}/skills/drive-navigation/SKILL.md` for file resolution and type detection.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `[file-id-or-name]` (required) -- Google Drive file ID or filename. If looks like an ID (alphanumeric string with no spaces, typically 25+ characters), use directly. If text, search Drive for the file. If missing, prompt: "Which file would you like to summarize? Provide a file name or Google Drive file ID." Wait for a response before proceeding.
- `--depth=LEVEL` (optional) -- summary depth. Accepts: `quick`, `detailed`. Default: `quick`.
- `--output=PATH` (optional) -- local file path for saved output. Uses `${CLAUDE_PLUGIN_ROOT}/templates/summary-template.md` as scaffold.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Step 1: Resolve File

Apply the drive-navigation skill to locate the target file:

1. **If input is a file ID**: Fetch file metadata via gws CLI (Drive) (title, MIME type, last modified date, web view URL).
2. **If input is a name**: Search Drive for matching files using the drive-navigation skill's search strategy. If multiple matches, present a disambiguation list:
   ```
   Multiple files found for "[input]":
   1. "Q1 Revenue Report" (Google Docs) - /Finance/Reports/ - Modified 2026-02-28
   2. "Q1 Revenue Report - Draft" (Google Docs) - /Finance/Drafts/ - Modified 2026-02-15
   Which file? Enter the number.
   ```
   Wait for user selection before proceeding.
3. **Validate file type**: Confirm the file is a supported type (Google Docs, Google Sheets, Google Slides, PDF, plain text, Markdown). If unsupported, stop with: "[type] files are not supported for summarization. Supported types: Docs, Sheets, Slides, PDFs, plain text, Markdown."

Track for output:
- `file_title`: the resolved file name.
- `file_type`: human-readable type (e.g., "Google Docs", "PDF").
- `last_modified`: last modified date.
- `file_url`: web view URL.

## Step 2: Extract Content

Apply content extraction from the document-qa skill:

1. **Read file content** via Google gws CLI (Drive).
2. **Handle by type**:
   - **Google Docs** -- extract as markdown. Preserve heading hierarchy (H1, H2, H3) for section-based analysis.
   - **Google Sheets** -- extract as structured data with column headers per tab. Note tab names, row counts, and column names.
   - **Google Slides** -- extract text content per slide. Note slide numbers and titles.
   - **PDF** -- extract as plain text. Attempt to detect heading structure from font size or formatting cues.
   - **Plain text / Markdown** -- read content directly.
3. **Cap at 3000 characters per source section**. For documents exceeding this limit, use heading-based section extraction: split by top-level headings and process each section individually.
4. **Record document structure**: Identify the major sections/headings for use in detailed mode.

## Step 3: Generate Summary

### Quick Mode (default)

1. **Executive Summary**: Write 2-3 sentences covering the document's purpose, audience, and key content.
2. **Key Points**: Extract 5-8 bullet points capturing the most important facts, decisions, or findings in the document. Each point should be a complete, standalone statement.
3. **For Sheets**: Add a Data Highlights section:
   - Tab count and names.
   - Row count per tab.
   - Key metrics or totals if identifiable from headers and data patterns.

### Detailed Mode (--depth=detailed)

1. **Executive Summary**: Same as quick mode.
2. **Key Points**: Same as quick mode.
3. **Detailed Analysis**: Generate one subsection per major heading/section in the source document. Each subsection includes:
   - The section heading as an H4.
   - 2-5 sentence analysis covering what the section contains, key takeaways, and notable details.
   - For sections with data (tables, lists, metrics), highlight the most significant items.
4. **For Sheets**: Data Highlights with per-tab breakdown:
   - Tab name, row count, column list.
   - Key aggregations if identifiable (sums, averages, min/max).
   - Notable data patterns or outliers.
5. **For Slides**: Slide-by-slide breakdown:
   - Slide number and title.
   - Key content and visuals described.
   - Presentation flow analysis (how slides build on each other).

## Step 4: Save to File (if --output)

1. Read the summary template at `${CLAUDE_PLUGIN_ROOT}/templates/summary-template.md`.
2. Replace all `{{PLACEHOLDER}}` variables with generated values:
   - `{{DOCUMENT_TITLE}}` -- file title.
   - `{{FILE_TYPE}}` -- human-readable file type.
   - `{{LAST_MODIFIED}}` -- last modified date.
   - `{{FILE_ID}}` -- the Google Drive file ID.
   - `{{DRIVE_LINK}}` -- the file's web view URL.
   - `{{DEPTH_LEVEL}}` -- "quick" or "detailed".
   - `{{EXECUTIVE_SUMMARY}}` -- the executive summary text.
   - `{{KEY_POINTS}}` / `{{KEY_POINT}}` -- iterate over key points using Mustache block syntax `{{#KEY_POINTS}}`.
   - `{{DETAILED_SECTIONS}}` -- Mustache block `{{#DETAILED_SECTIONS}}` containing `{{#SECTIONS}}` with `{{SECTION_TITLE}}` and `{{SECTION_CONTENT}}` per section (empty in quick mode).
   - `{{DATA_HIGHLIGHTS}}` -- Mustache block `{{#DATA_HIGHLIGHTS}}` with per-tab breakdown (omit for non-Sheet files).
   - `{{GENERATED_DATE}}` -- current date in YYYY-MM-DD format.
3. Write the populated template to the `--output` path.
4. Report: "Summary saved to [path]."

## Step 5: Notion Logging (Optional)

Log the summarization activity to Notion for tracking.

1. **Check for database**: Search Notion for a database titled "[FOS] Activity Log". If not found, try "Founder OS HQ - Activity Log". If not found, fall back to "Google Drive Brain - Activity".
2. If neither is found, skip Notion logging silently and proceed with chat output. Do not create the database. If found, log with these properties:
   - Query (title) -- the file title that was summarized
   - Command Type (select: search, summarize, ask, organize) -- set to "summarize"
   - Files Found (number) -- set to 1
   - Top Result (rich_text) -- the file title
   - Company (relation) -- if the summarized file's path or name matches a known client from [FOS] Companies, set the Company relation to that record. See drive-navigation skill's Company Detection rules.
   - Generated At (date) -- timestamp of the summarization
3. **Idempotent check**: Search for an existing record where Query matches the file title (case-insensitive) AND Generated At is the same calendar day AND Command Type is "summarize". Update if found, create if not.
4. **Save**: Write the activity record to the Notion database.
5. **Continue on failure**: If Notion logging fails for any reason (MCP unavailable, permissions, rate limit), skip silently and proceed with chat output.

## Step 6: Output

Display the summary in chat regardless of whether `--output` was specified.

```
## Summary: [Document Title]

**Type**: [file type] | **Last Modified**: [date] | **Depth**: [quick|detailed]

---

### Executive Summary
[2-3 sentences]

### Key Points
- [point 1]
- [point 2]
- [point 3]
- [point 4]
- [point 5]
...

[If --depth=detailed:]
### Detailed Analysis
#### [Section Title]
[2-5 sentence analysis]

#### [Section Title]
[2-5 sentence analysis]
...

[If Sheets:]
### Data Highlights
**Tabs**: [count]
- **[Tab Name]**: [rows] rows, [columns]
  - Key metrics: [metric: value, ...]

[If Slides and --depth=detailed:]
### Slide Breakdown
- **Slide 1**: [title] -- [key content]
- **Slide 2**: [title] -- [key content]
...

---
*[Drive link] · Summarized by Google Drive Brain*
```

## Graceful Degradation

**Google gws CLI (Drive) unavailable**: Stop execution. Display:
"gws CLI (`gws drive`) is not connected. Drive Summarize requires Google Drive access.
Install it per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`:
1. Set your Google Drive credentials
2. Ensure the Drive integration has access to your files"

**File not found**: Display:
"No file found matching '[input]'. Try a more specific name or use a Google Drive file ID."

**Content extraction fails**: Display:
"Unable to extract content from this file. It may be empty, password-protected, or in an unsupported format."

**Unsupported file type**: Display:
"[type] files are not supported for summarization. Supported types: Docs, Sheets, Slides, PDFs, plain text, Markdown."

**Notion MCP unavailable**: Skip Notion logging silently. Do not mention Notion absence to the user.

**Summary template missing** (when `--output` specified): Generate the file output using the Step 6 chat format directly. Append: "Note: Summary template not found. Output written using default format."

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/drive:summarize "Q1 Revenue Report"
/drive:summarize 1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74OgVE2upms --depth=detailed
/drive:summarize budget --output=./summaries/budget-summary.md
/drive:summarize "Project Phoenix SOW" --depth=detailed --output=./sow-summary.md
```
