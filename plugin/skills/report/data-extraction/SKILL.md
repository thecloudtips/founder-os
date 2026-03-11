---
name: Data Extraction
description: "Extracts and normalizes data from CSV, JSON, text files, Notion databases, and Google Drive (via gws CLI) into a unified schema. Activates when the user wants to load data, parse files, import data sources, or prepare raw data for report generation — handles delimiter detection, encoding, type inference, and cross-source merging."
globs:
  - "teams/agents/research-agent.md"
---

## Overview

Extract, parse, and normalize data from heterogeneous sources into a single unified structure that the Analysis Agent can consume without further transformation. Support five source types: CSV files, JSON files, plain text files, Notion databases, and Google Drive documents (via the gws CLI). Treat each source independently -- detect its format, apply format-specific extraction rules, normalize the result into the common output schema, and attach source metadata for traceability. Process multiple sources per report request by extracting from each in sequence and merging all results into a single dataset collection before handing off. Never modify original source files. All extraction is read-only.

## CSV Extraction

### Delimiter Detection

Detect the delimiter by sampling the first 20 lines. Check for a `.tsv` extension first (assume tab). Otherwise count occurrences of comma, tab, semicolon, and pipe across sampled lines. Select the delimiter producing the most consistent column count (>=90% of lines yield the same count). Break ties with this preference order: comma > tab > semicolon > pipe. If no delimiter produces consistent columns, default to comma and flag the file as potentially malformed.

### Encoding Handling

Default to UTF-8. On decode failure: attempt UTF-8 with BOM detection, fall back to Latin-1, then Windows-1252 if Latin-1 produces garbled output (3+ consecutive non-ASCII characters outside known language ranges). Record the detected encoding in source metadata and flag non-UTF-8 as a warning.

### Header Detection

Determine whether the first row is a header by checking if it contains exclusively non-numeric strings while subsequent rows contain mixed types. Look for header patterns: underscores, camelCase, or title-cased words. When the first row matches the data pattern of other rows, treat the file as headerless and generate synthetic names (`column_1`, `column_2`, ..., `column_N`). Record header status in source metadata.

### Type Inference

Infer each column's type by sampling all values:

- **Numeric**: Integer or float patterns. Accept comma-thousands separators, period decimals, negative signs. Strip currency symbols but record currency in metadata.
- **Date**: ISO 8601, US (MM/DD/YYYY), European (DD/MM/YYYY), natural language. Default to US when ambiguous and flag.
- **Boolean**: Case-insensitive match on true/false, yes/no, 1/0, on/off, y/n.
- **Text**: Fallback for unmatched values.

Assign the dominant type when >=80% of non-empty values match. Otherwise assign text.

### Quoted Fields and Escapes

Follow RFC 4180: fields containing delimiters, newlines, or double quotes must be quoted. Doubled double quotes represent a literal quote. Preserve newlines within quoted fields. Strip whitespace from unquoted fields only.

## JSON Extraction

### Path Traversal

Start at the root. If the root is an array, use it as the data collection. If the root is an object, search for the first key whose value is an array of objects (common keys: `data`, `results`, `records`, `items`, `rows`). Accept a user-specified dot-notation or bracket-notation path for deeper nesting. If no data array is found, flatten the entire object into a single-record dataset.

### Nested Object Flattening

Flatten nested objects using dot-notation keys (`address.city`). Limit depth to 5 levels; serialize deeper structures as JSON strings. Join primitive arrays into comma-separated strings. Expand object arrays into indexed columns (`contacts[0].name`), capping at 20 elements with a truncation note.

### Schema Detection

Infer schema from the first 50 records. Collect all unique keys, classify value types using CSV type-inference rules, and mark keys present in >=95% of records as required. Record the schema in source metadata.

### Malformed JSON Handling

On syntax errors: report the error location, attempt common auto-repairs (trailing comma removal, single-to-double quote conversion, unquoted key quoting). If repair succeeds, proceed and flag in metadata. If repair fails, abort this source with status "extraction_failed" and continue other sources.

## Text File Extraction

### Line-Based Parsing

Classify the file structure: **Tabular** (fixed-width alignment consistent across >=80% of lines), **Delimited** (consistent delimiter patterns -- apply CSV rules), or **Freeform** (unstructured text).

### Key-Value Detection

Scan for patterns: colon-separated (`Key: Value`), equals-separated (`Key = Value`), tab-separated, or arrow-separated (`Key -> Value`). When >=60% of non-empty lines match a consistent pattern, extract as a key-value dataset. Handle multi-line values via continuation-line detection (indented lines after a key-value pair).

### Table Detection in Plain Text

Identify embedded tables by horizontal separators (`---`, `===`, `|---|`), consistent column alignment across 3+ lines, or Markdown table syntax. Extract each table as a separate dataset named by preceding heading text or position.

### Log File Patterns

Detect timestamped logs (extract timestamp, level, message), key-value logs (parse `key=value` pairs), and Apache/Nginx access logs (extract IP, timestamp, method, path, status, size, referrer, user agent). Apply the matched parser to produce structured records.

### Structured Section Extraction

Detect sections by Markdown headings, underlined headings, numbered sections, or all-caps header lines. Extract each section as a record: `section_title`, `section_level`, `section_content`, `section_order`.

## Notion Database Extraction

### Dynamic Database Discovery

Never hardcode database IDs. Search by title via the Notion MCP search endpoint. Prefer exact matches over partial matches. Try variations (with/without prefixes, with/without emoji). When multiple exact matches exist, select the most recently edited. Record discovered database ID and title in source metadata.

### Property Type Handling

| Notion Type | Extraction Rule |
|-------------|-----------------|
| title | Plain text string |
| rich_text | Plain text, strip formatting, preserve `\n` |
| number | Numeric value, null for empty |
| select | Option name as string |
| multi_select | Comma-separated option names |
| date | ISO start date; include end date if present |
| checkbox | Boolean |
| url, email, phone_number | String |
| relation | Page IDs as array; optionally resolve to titles |
| formula, rollup | Computed value by result type |
| created_time, last_edited_time | ISO datetime string |
| created_by, last_edited_by | User name |
| files | File URLs as array |
| status | Status name as string |

### Pagination Handling

Fetch 100 records per request. Follow `next_cursor` while `has_more` is true. Stop at 10,000 records (safety limit), flag truncation in metadata, and track total API calls.

### Filter Construction

Translate human-readable conditions from the report spec into Notion filter objects. Support compound AND/OR filters (default AND). Support `sort_by` and `sort_direction`. Retrieve all records when no filters are specified.

## Google Drive Extraction (via gws CLI)

Check for gws CLI availability before attempting Drive extraction:

```bash
which gws || echo "gws CLI not available"
```

If the gws CLI is unavailable or authentication is not configured, skip Drive extraction entirely and mark the source as unavailable in metadata.

### File Type Detection

- **Google Sheets**: Export as CSV via `gws drive files export --params '{"fileId":"FILE_ID","mimeType":"text/csv"}' --output /tmp/sheet.csv`, then apply CSV rules. Extract each sheet tab as a separate dataset.
- **Google Docs**: Export as plain text via `gws drive files export --params '{"fileId":"FILE_ID","mimeType":"text/plain"}' --output /tmp/doc.txt`, then apply text extraction rules. Preserve heading hierarchy.
- **Google Slides**: Export as plain text via `gws drive files export`. One record per slide: `slide_number`, `title`, `body_text`.
- **PDF**: Extract text, apply text rules. Flag image-heavy PDFs.
- **Other** (Excel, Word): Attempt compatible export. Flag unsupported formats.

### Search and Selection

Search by file name from the report spec using the gws CLI:

```bash
gws drive files list --params '{"q":"name contains '\''SEARCH_TERM'\''","pageSize":20,"fields":"files(id,name,mimeType,modifiedTime,webViewLink)"}' --format json
```

Support wildcard patterns. Filter by MIME type or folder path when specified. Extract from all matching files, naming each dataset by file name.

### Downloading File Contents

Use `gws drive files export` for Google-native formats, direct download for uploaded files. Skip files exceeding 50 MB and record the skip. Track download status per file.

## Data Normalization

### Column Name Normalization

Convert to snake_case: lowercase, replace spaces with underscores, remove special characters. Collapse consecutive underscores. Prefix numeric names with `col_`. Resolve collisions with numeric suffixes (`revenue`, `revenue_2`).

### Value Normalization

- **Dates**: Convert to ISO 8601 (YYYY-MM-DD or YYYY-MM-DDTHH:MM:SSZ).
- **Numbers**: Strip commas, currency symbols, percent signs. Store raw values. Record original format in metadata.
- **Booleans**: Normalize to `true`/`false`.
- **Nulls**: Normalize empty strings, "N/A", "None", "n/a" to `null`.
- **Strings**: Trim whitespace, collapse internal runs to single spaces, preserve case.

### Cross-Source Merging

Match records across sources using a join key when specified in the report spec. Without a join key, keep datasets separate. When merging, prefix column names with source name to avoid collisions. Record merge statistics in metadata.

## Output Schema

Produce a JSON object conforming to this structure for handoff to the Analysis Agent:

```json
{
  "extraction_id": "uuid-v4",
  "generated_at": "ISO-8601 datetime",
  "report_spec": {
    "title": "Report title from user request",
    "sources_requested": ["source references from the report spec"]
  },
  "datasets": [
    {
      "dataset_id": "uuid-v4",
      "source": {
        "type": "csv | json | text | notion | gdrive",
        "name": "Original file name or database title",
        "path": "File path, database ID, or Drive file ID",
        "encoding": "Detected encoding",
        "format_details": {
          "delimiter": ",",
          "header_detected": true,
          "record_count": 150,
          "column_count": 12
        }
      },
      "schema": {
        "columns": [
          {
            "name": "snake_case_name",
            "original_name": "Original Name",
            "type": "numeric | date | boolean | text",
            "nullable": true,
            "sample_values": ["first 3 non-null values"]
          }
        ]
      },
      "records": [
        {"column_name": "value"}
      ],
      "warnings": ["Issues encountered during extraction"],
      "status": "success | partial | failed"
    }
  ],
  "metadata": {
    "total_datasets": 3,
    "total_records": 450,
    "extraction_duration_ms": 2340,
    "sources_successful": 3,
    "sources_failed": 0,
    "warnings": ["Pipeline-level warnings"]
  }
}
```

Every field is required. Use `null` for unavailable scalars and `[]` for unavailable lists. Never omit a key.

## Edge Cases

### Empty Files

Set dataset status to "partial". Produce an empty records array. Add warning: "Source file is empty -- no data extracted." Continue to the next source.

### Mixed Encodings

Attempt the primary detected encoding first. Replace problematic bytes with the Unicode replacement character (U+FFFD) on per-field failures and add a per-record warning. Record encoding issues in source metadata.

### Very Large Files

Extract the first 10,000 rows when a source exceeds 10,000 rows or 50 MB. Record total row count in metadata. Add truncation warning and suggest applying filters or splitting the source.

### Unsupported Formats

Set dataset status to "failed" for binary files, images, video, or proprietary formats. Record the MIME type or extension. Add warning: "Unsupported file format: [format]. Skipping extraction." Move to the next source.

### API Errors

Retry once after a 5-second delay. On second failure, set dataset status to "failed". Record error type, HTTP status code, and error message. Continue processing remaining sources -- never halt the entire extraction for one API failure.

### Duplicate Sources

When the same source is referenced twice, extract once and reuse the dataset entry. Add metadata note: "Duplicate source reference detected -- extracted once."

### Circular or Self-Referencing Data

Extract Notion self-referencing relations as page IDs only. Do not recursively resolve. Limit relation resolution to one level of depth. Add a metadata note if circular references are detected.
