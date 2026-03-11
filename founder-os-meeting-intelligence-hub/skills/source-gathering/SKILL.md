---
name: Source Gathering
description: "Gathers and normalizes meeting transcripts from Fireflies, Otter, Gemini, Notion, or local files into a unified format. Activates when the user has a transcript to import, wants to pull meeting notes from a service, or provides a file to analyze. Auto-detects the source format and normalizes speaker labels, dates, and structure for downstream analysis."
globs:
  - "commands/meeting-intel.md"
  - "commands/meeting-analyze.md"
---

## Overview

Gather meeting transcripts and notes from multiple sources, normalize them into a unified NormalizedTranscript structure, and pass the result downstream to the meeting-analysis skill. Support five source adapters: Fireflies.ai file exports, Notion meeting notes pages, Otter.ai file exports, Gemini transcripts from Google Drive, and generic local files. When the user does not specify a source type, auto-detect from content patterns.

For detailed format detection patterns, signature strings, and example content per source, see `${CLAUDE_PLUGIN_ROOT}/skills/source-gathering/references/source-formats.md`.

## Source Detection Algorithm

When processing a source, follow this decision tree in order:

1. **Explicit source hint**: If the user provided `--source=fireflies|otter|gemini|notion|auto`, use that adapter directly. Skip to the adapter section.
2. **Input type routing**: If the input is `--notion`, route to the Notion adapter. If a file path or pasted text, proceed to content-based detection.
3. **Content-based auto-detection**: Read the first 100 lines (or 4 KB) of the file content and apply signature matching in priority order:

| Priority | Source | Detection Signals |
|----------|--------|-------------------|
| 1 | Fireflies.ai | Header containing "Fireflies.ai", speaker labels in `Speaker Name:` format, timestamp format `HH:MM:SS` |
| 2 | Otter.ai | Footer containing "Otter.ai" or "Transcribed by Otter", SRT subtitle format with sequential numeric IDs |
| 3 | SRT/VTT subtitle | `.srt` extension with `-->` timestamp arrows, or `.vtt` extension with `WEBVTT` header |
| 4 | Generic text/markdown | `.txt` or `.md` with no recognized service signatures |

Apply first-match-wins: stop at the first matching signature. When no signature matches, fall back to the Generic Local Files adapter.

4. **Ambiguity handling**: When content matches multiple signatures (e.g., an `.srt` file with "Otter.ai" in the footer), prefer the more specific adapter (Otter.ai over generic SRT).

Report the detected source before processing: "Detected source: [Fireflies.ai/Otter.ai/Notion/Gemini/Local File]".

## NormalizedTranscript Schema

All source adapters produce output conforming to this schema. Downstream skills (meeting-analysis) depend on this structure.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | Yes | Meeting title. Infer from filename or metadata if not explicit. |
| `date` | string (ISO 8601) | Yes | Meeting date in `YYYY-MM-DD` format. Parse from metadata, filename, or file modified date as fallback. |
| `duration` | string | No | Meeting length (e.g., "45 minutes"). Compute from first/last timestamp when available. |
| `attendees` | string[] | Yes | List of participant names. Empty array `[]` when participants cannot be determined. |
| `source_type` | enum | Yes | One of: `fireflies`, `otter`, `notion`, `gemini`, `local_file` |
| `source_path` | string | Yes | Absolute file path, Notion page URL, or Drive document URL. |
| `transcript_text` | string | Yes | Full transcript with speaker labels and timestamps preserved where available. |

### Field Extraction Priority

For each field, attempt extraction in this order and use the first successful result:

- **title**: Explicit metadata field > first heading in content > filename (strip extension, convert hyphens/underscores to spaces) > "Untitled Meeting"
- **date**: Metadata date field > date in filename (YYYY-MM-DD pattern) > date in content header > file modification date
- **duration**: Metadata duration > computed from first and last timestamp in transcript > omit
- **attendees**: Metadata participant list > unique speaker labels extracted from transcript > empty array

## Source Adapter Guidelines

Each adapter handles source-specific ingestion and maps output to the NormalizedTranscript schema. Detailed format patterns and example content live in `${CLAUDE_PLUGIN_ROOT}/skills/source-gathering/references/source-formats.md`.

### Adapter 1: Fireflies.ai

Read `.txt` or `.json` exports from local disk via Filesystem MCP.

- **Detection**: "Fireflies.ai" string in the file header (first 20 lines), speaker labels in `Speaker Name:` format, timestamps in `HH:MM:SS` format.
- **JSON handling**: When the file is `.json`, parse structured fields directly: `title`, `date`, `duration`, `attendees`, `transcript.segments[].speaker`, `transcript.segments[].text`.
- **TXT handling**: Parse the header block for title, date, and participant list. Extract speaker turns from `Speaker Name: text` patterns. Compute duration from first and last `HH:MM:SS` timestamps.
- **Speaker normalization**: Preserve original speaker names. Deduplicate variations of the same name (e.g., "John S." and "John Smith") by matching first name + initial when full names appear elsewhere.

### Adapter 2: Notion Meeting Notes

Search Notion for meeting note pages via Notion MCP.

- **Discovery**: Search for pages whose title contains any of: "meeting", "notes", "sync", "standup", "retro", "kickoff" (case-insensitive). Also search for pages within databases titled "Meeting Notes" or "Meetings".
- **Date filtering**: When `--date` is provided, filter results to pages with a Date property or Created time matching that date. When no date filter, return the most recent 5 matching pages and prompt the user to select.
- **Content extraction**: Retrieve full page content as blocks. Convert Notion block types to plain text. Extract participants from a "Participants" or "Attendees" property, or from @-mentions within page content.
- **Source path**: Record the Notion page URL as `source_path`.
- **Multiple results**: When multiple pages match, present a numbered list with title and date for user selection. Process the selected page.

### Adapter 3: Otter.ai

Read `.txt` or `.srt` exports from local disk via Filesystem MCP.

- **Detection**: "Otter.ai" or "Transcribed by Otter" string in the file (typically footer), or SRT format with sequential numeric IDs and `-->` timestamp separators.
- **TXT handling**: Parse speaker turns from `Speaker Name  HH:MM:SS` or `Speaker Name:` patterns. Extract meeting title and date from the header if present.
- **SRT handling**: Parse SRT blocks (index, timestamp line `HH:MM:SS,mmm --> HH:MM:SS,mmm`, text lines). Convert timestamps to `HH:MM:SS` format. Join text lines per block. Strip HTML formatting tags (`<b>`, `<i>`, etc.) from subtitle text.
- **Speaker normalization**: Otter often prefixes speaker labels to subtitle text as "Speaker: text". Extract and normalize these labels.

### Adapter 4: Gemini (Google Drive)

Search Google Drive for Gemini-generated meeting transcripts via Google gws CLI (Drive).

- **Discovery**: Search Drive for documents with titles containing "Meeting notes" or "Gemini transcript". Filter to Google Docs type.
- **Content extraction**: Read the document content. Parse Gemini's auto-generated format: meeting title, date, attendees list, and transcript body with speaker labels.
- **Graceful degradation**: When Google gws CLI is unavailable for Drive, skip this adapter entirely. Report: "Google Drive not connected -- Gemini transcript search skipped." Do not fail the pipeline.
- **Source path**: Record the Drive document URL as `source_path`.

### Adapter 5: Generic Local Files

Accept `.txt`, `.md`, `.srt`, `.vtt` files from local disk via Filesystem MCP.

- **SRT conversion**: Parse SRT format (index, timestamps, text) and convert to plain text with inline timestamps: `[HH:MM:SS] text`.
- **VTT conversion**: Parse WebVTT format (cue timing lines with `-->`, optional cue settings). Strip VTT headers and metadata. Convert to plain text with inline timestamps.
- **Markdown handling**: Read `.md` files as-is. Extract title from the first `#` heading. Treat the body as transcript text.
- **Plain text handling**: Read `.txt` files as-is. Attempt speaker label detection (patterns: `Name:`, `[Name]`, `SPEAKER_N:`). When no speaker labels are found, treat entire content as a single-speaker transcript.

## Auto-Detection Logic

When `--source=auto` (the default) and the input is a file path, apply this procedure:

1. Read the file extension. Route `.srt` and `.vtt` files through format-specific parsing regardless of content signatures.
2. Read the first 100 lines of content.
3. Apply signature matching from the Source Detection Algorithm table (priority 1-4).
4. When a signature match is found, log the detection and route to the corresponding adapter.
5. When no signature matches, route to the Generic Local Files adapter with the appropriate format handler based on file extension.

### Content Signature Patterns

Maintain a lookup of signature patterns per source. The primary patterns:

- **Fireflies.ai**: `/Fireflies\.ai/i` in first 20 lines, `HH:MM:SS` timestamps preceding or following speaker names.
- **Otter.ai**: `/Otter\.ai|Transcribed by Otter/i` anywhere in file, or SRT format with speaker prefixes in subtitle text.
- **SRT format**: Lines matching `^\d+$` followed by lines matching `\d{2}:\d{2}:\d{2},\d{3} --> \d{2}:\d{2}:\d{2},\d{3}$`.
- **VTT format**: File begins with `WEBVTT` header line.

For the full pattern catalog with examples, see `${CLAUDE_PLUGIN_ROOT}/skills/source-gathering/references/source-formats.md`.

## Speaker Label Normalization

Transcripts from different sources use inconsistent speaker label formats. Normalize all speaker labels before producing the NormalizedTranscript.

### Normalization Rules

1. **Strip prefixes**: Remove "Speaker:", "SPEAKER", "S" numbering prefixes. Preserve actual names.
2. **Case normalization**: Title-case all speaker names ("john smith" becomes "John Smith").
3. **Deduplication**: Merge labels that refer to the same person. Match by: exact string, first name + last initial vs full name, common nickname mappings (e.g., "Mike" / "Michael"). When uncertain, keep both labels and note the potential match.
4. **Generic labels**: When a source uses generic labels like "Speaker 1", "Speaker 2", preserve them. Do not fabricate names.
5. **Attendee list alignment**: When an attendee list is available from metadata, attempt to match speaker labels to attendee names. Use the attendee name as the canonical form.

## Date Parsing

Meeting dates appear in varied formats across sources and metadata.

### Parsing Priority

1. Explicit ISO 8601 format: `YYYY-MM-DD` or `YYYY-MM-DDTHH:MM:SS`.
2. Common US format: `MM/DD/YYYY`, `Month DD, YYYY`.
3. Common European format: `DD/MM/YYYY` (use locale context to disambiguate from US format; default to US when ambiguous).
4. Filename pattern: Extract `YYYY-MM-DD` from filename strings like `meeting-2026-03-05.txt`.
5. Relative terms: "today", "yesterday" -- resolve relative to the current date.
6. File modification date: Use as last resort fallback. Flag in output: "Date inferred from file modification time."

Always output dates in `YYYY-MM-DD` format in the NormalizedTranscript.

## MCP Requirements

| Server | Purpose | Required | Degradation |
|--------|---------|----------|-------------|
| Notion | Search for meeting notes pages, save intelligence output to "[FOS] Meetings" | Required | Abort with error if unavailable |
| Filesystem | Read local transcript files (.txt, .json, .srt, .vtt, .md) | Required | Abort with error if unavailable |
| Google Drive | Search for Gemini-generated meeting transcripts | Optional | Skip Gemini adapter. Report: "Drive not connected -- Gemini source unavailable." |
| Gmail | Enrich meeting context with related email threads | Optional | Skip email enrichment. Report: "Gmail not connected -- email context unavailable." |

When an optional MCP source is unavailable, continue the pipeline with remaining sources. Never fail the entire gathering process due to an optional source being offline.

## Edge Cases

- **Empty file**: When a file exists but contains no text content, return an error: "File is empty -- no transcript content to process." Do not produce a NormalizedTranscript.
- **Encoding issues**: Attempt UTF-8 decoding first, then fall back to Latin-1. When decoding fails, report: "Unable to read file -- unsupported encoding."
- **Mixed-source content**: When a file contains content from multiple services (e.g., a manually compiled document with Fireflies and Otter transcripts concatenated), treat as a single generic transcript. Do not attempt to split by source.
- **Very large files**: For transcripts exceeding 50,000 words, process in full but warn: "Large transcript ([N] words) -- analysis may take longer."
- **No speaker labels**: When transcript text contains no identifiable speaker labels, set `attendees` to `[]` and proceed. The meeting-analysis skill handles unlabeled transcripts.
- **Duplicate sources**: When the same meeting appears in both a local file and Notion, prefer the source with richer content (more speaker labels, timestamps, or metadata). Flag: "Duplicate source detected -- using [source] (more complete)."
- **SRT/VTT with no speech content**: Subtitle files that contain only music notations ("[Music]", "[Applause]") or empty cues. Filter non-speech cues and warn if remaining content is minimal.
- **Date conflicts**: When metadata date and filename date disagree, prefer metadata. Log: "Date conflict -- metadata says [X], filename says [Y]. Using metadata date."

## Integration with Meeting Analysis

The NormalizedTranscript output feeds directly into the meeting-analysis skill. Ensure:

- `transcript_text` preserves speaker labels in a consistent `Speaker Name: text` format per line or paragraph.
- Timestamps, when available, are inline in `[HH:MM:SS]` format preceding the associated text.
- The `source_type` field provides context about transcript origin quality. Professional transcription services (Fireflies, Otter) typically produce more accurate speaker labels and timestamps than generic local files.
- The `attendees` list enables the meeting-analysis skill to attribute decisions and follow-ups to specific people.

## Additional Resources

Consult this reference file for detailed implementation guidance:

- `${CLAUDE_PLUGIN_ROOT}/skills/source-gathering/references/source-formats.md` -- Detailed format detection patterns per source, example file headers and footers, JSON schema examples for Fireflies exports, SRT/VTT format specifications, Notion page structure patterns, and Gemini transcript format samples.
