---
description: Gather meeting transcripts from multiple sources and extract intelligence (summaries, decisions, follow-ups, topics)
argument-hint: "path/to/transcript.txt --source=auto --output=both"
allowed-tools: ["Read"]
---

# Meeting Intelligence

Full pipeline -- gather a transcript from any supported source, run 4 analysis pipelines (summary, decisions, follow-ups, topics), save results to Notion and/or chat, and save the normalized transcript locally.

## Load Skills

Read both skills before starting any step:

1. `${CLAUDE_PLUGIN_ROOT}/skills/source-gathering/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/skills/meeting-analysis/SKILL.md`

## Parse Arguments

Extract the source identifier and flags from `$ARGUMENTS`:

- **`[source-or-file]`** (optional positional) -- path to a local transcript file, or `--notion` to search Notion for recent meeting notes pages. If neither is provided, prompt the user: "Provide a file path to a transcript, or use `--notion` to search Notion for meeting notes." Then stop and wait for input.
- `--source=fireflies|otter|gemini|notion|auto` (optional) -- hint the source type for format detection. Default: `auto`.
- `--date=YYYY-MM-DD` (optional) -- filter results to meetings on this date.
- `--output=notion|chat|both` (optional) -- where to send the analysis report. Default: `both`.
- `--with-email` (optional flag) -- search Gmail for related email threads to enrich context before analysis.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Step 1: Detect and Gather Source

### Local File Path Provided

1. Use the Read tool to read the file at the provided path.
2. Validate the file:
   - If the file does not exist: halt with "File not found: [path]. Check the path and try again."
   - If the file is empty: halt with "File is empty: [path]. No content to analyze."
   - Supported formats: `.txt`, `.md`, `.json`, `.srt`, `.vtt`. If the file appears to be binary or an unsupported format, halt with: "Unsupported file format. Supported formats: .txt, .md, .json, .srt, .vtt"
3. If `--source` is set to a specific adapter (fireflies, otter, gemini), use that adapter's detection patterns from the source-gathering skill to parse the file.
4. If `--source=auto` (default), run auto-detection from the source-gathering skill: check content patterns for Fireflies headers, Otter footers, SRT/VTT format markers, and generic transcript patterns. Classify accordingly.
5. If `--date` is provided and the detected meeting date does not match, warn: "File date [detected] does not match --date filter [provided]. Proceeding with file content."
6. Produce a NormalizedTranscript structure per the source-gathering skill: title, date, duration, attendees[], source_type, source_path, transcript_text.

### `--notion` Flag Provided

1. Search Notion for pages matching meeting-note patterns per the source-gathering skill's Notion adapter: titles containing "meeting", "notes", "sync", "standup", or pages in a "Meeting Notes" database.
2. If `--date` is provided, filter results to pages with a date matching that value.
3. If multiple matching pages are found, present them as a numbered list with title, date, and parent database/page. Ask the user to pick one. Then stop and wait for input.
4. If exactly one match is found, use it.
5. If no matches are found, halt with: "No meeting notes found in Notion matching the criteria. Try a different date or provide a local file path instead."
6. Extract the page content and produce a NormalizedTranscript structure.

### `--source=gemini` (Google Drive)

1. Check if Google gws CLI is available for Drive.
2. If available, search Drive for documents with "Meeting notes" in the title or auto-generated Gemini transcripts per the source-gathering skill's Gemini adapter.
3. If `--date` is provided, filter results to that date.
4. If multiple matches are found, present a numbered list and ask the user to pick one. Then stop and wait for input.
5. If gws CLI is unavailable for Drive, halt with: "Google gws CLI (Drive) is not configured. Export the Gemini transcript as a local file and run: `/meeting:intel path/to/transcript.txt --source=gemini`"

## Step 2: Email Enrichment

Execute this step only if `--with-email` is present.

1. Check if gws CLI is available for Gmail.
2. If available, search Gmail for threads matching the meeting title, attendee names, or meeting date (search within 3 days before and after the meeting date).
3. Extract relevant email context: pre-meeting agendas, follow-up threads, shared materials.
4. Attach the email context as supplemental input for the analysis pipelines.
5. If gws CLI is unavailable for Gmail, warn: "gws CLI (Gmail) not configured -- skipping email enrichment. Analysis proceeds without email context." Continue to Step 3.

## Step 3: Run Analysis Pipelines

Run all 4 analysis pipelines from the meeting-analysis skill on the NormalizedTranscript. Each pipeline produces its section independently.

### Pipeline 1: Meeting Summary

Generate a 3-5 sentence summary covering main topics discussed, key participants and their roles, and the outcome/conclusion/open questions.

### Pipeline 2: Key Decisions Log

Scan the transcript for decision patterns per the meeting-analysis skill. For each decision, extract: decision text, proposer, context, confidence level (Explicit or Inferred). Flag any disagreements noted in the discussion.

### Pipeline 3: Follow-Up Commitments

Scan for follow-up commitment patterns per the meeting-analysis skill. For each commitment, extract: who (owner), what (action), deadline (parsed to ISO date where possible), mentioned_by. Format output to be compatible with Plugin #06 Follow-Up Tracker's promise patterns.

### Pipeline 4: Topic Extraction

Identify 3-7 topic tags via noun phrase extraction and frequency analysis per the meeting-analysis skill. When Notion MCP is available, check existing tags in the target database ("[FOS] Meetings" or fallback) Topics property and map to existing tags where possible for consistency.

If email enrichment was performed (Step 2), incorporate email context into all pipelines: email threads may contain decisions made asynchronously, additional follow-up commitments, or topic context not present in the transcript itself.

## Step 4: Save Transcript

1. Save the normalized transcript to `transcripts/[meeting-slug]-[date].md` relative to `${CLAUDE_PLUGIN_ROOT}`.
2. Create the `transcripts/` directory if it does not exist.
3. Generate the slug: take the meeting title, convert to lowercase, replace spaces with hyphens, strip all characters except letters, numbers, and hyphens, collapse consecutive hyphens.
4. If no date is available, use today's date in YYYY-MM-DD format.
5. File content: include a metadata header (title, date, source type, attendees, duration) followed by the full normalized transcript text.

## Step 5: Save to Notion

Execute this step only if `--output` includes `notion` (default: `both` includes `notion`).

1. **Discover database**: Search Notion for a database named "[FOS] Meetings". If not found, try "Founder OS HQ - Meetings". If not found, fall back to "Meeting Intelligence Hub - Analyses". If none exists, warn: "No Meetings database found in Notion. Analysis displayed in chat only." Skip Notion save and continue.
2. **Idempotent check**: Query the database for an existing row matching the Event ID (rich_text) when available, or both Meeting Title and Date as fallback. The row may have been created by P03 Meeting Prep Autopilot. If found, update that row with P07-owned fields only. If not found, create a new row.
3. **Populate P07-owned fields** with the analysis results: Meeting Title, Event ID (when available), Date, Attendees, Source Type, Transcript File, Summary, Decisions (formatted numbered list), Follow-Ups (list with owner, action, and deadline), Topics, Duration, Generated At. If meeting attendees match CRM contacts, set the Company relation.
4. **Preserve P03 fields**: Do not overwrite Prep Notes, Talking Points, Importance Score, or Sources Used if they already have values on an existing row.

## Step 6: Present Report

Execute this step only if `--output` includes `chat` (default: `both` includes `chat`).

Display the full analysis report:

```
## Meeting Intelligence Report

**Meeting**: [title]
**Date**: [date]
**Duration**: [duration or "Unknown"]
**Source**: [source_type] ([source_path])
**Attendees**: [comma-separated list or "Not identified"]

---

### Summary

[3-5 sentence meeting summary]

---

### Key Decisions

| # | Decision | Proposed By | Confidence |
|---|----------|-------------|------------|
| 1 | [decision text] | [proposer or "—"] | [Explicit/Inferred] |
| 2 | ... | ... | ... |

[If no decisions detected: "No explicit decisions detected in this meeting."]

---

### Follow-Up Commitments

| # | Owner | Action | Deadline | Mentioned By |
|---|-------|--------|----------|--------------|
| 1 | [who] | [what] | [deadline or "—"] | [mentioned_by or "—"] |
| 2 | ... | ... | ... | ... |

[If no follow-ups detected: "No follow-up commitments detected."]

---

### Topics

[tag1] | [tag2] | [tag3] | ...

---

### Files

- **Transcript saved**: [transcript file path]
[If Notion saved: "- **Notion**: Saved to [FOS] Meetings"]

---
```

## Step 7: Cross-Plugin Suggestions

After the report, display these suggestions:

```
### Next Steps

- Run `/actions:extract-file transcripts/[file]` to extract granular action items with priority scoring and Notion task creation
- Follow-up commitments above are compatible with `/followup:check` for automated nudge tracking
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Error Handling

Handle these error conditions:

- **No file found / invalid path**: Halt with "File not found: [path]. Check the path and try again."
- **Notion MCP unavailable + output includes notion**: Warn "Notion MCP not configured -- results displayed in chat only. Transcript saved locally." Fall back to chat output. Do not halt the pipeline.
- **Empty or unreadable file**: Halt with "File is empty or unreadable: [path]. Supported formats: .txt, .md, .json, .srt, .vtt"
- **No meeting content detected**: Warn "Content does not appear to be a meeting transcript or notes. Attempting analysis anyway -- results may be limited." Proceed with analysis.
- **Google gws CLI (Drive) unavailable for Gemini source**: Halt with "Google gws CLI (Drive) is not configured. Export the Gemini transcript as a local file and run: `/meeting:intel path/to/file --source=gemini`"
- **gws CLI (Gmail) unavailable with --with-email**: Warn and continue without email enrichment (handled in Step 2).

## Graceful Degradation

If Notion MCP is unavailable or any Notion operation fails:
- Complete the full pipeline and display all output in chat
- Save the transcript file locally
- Do not halt or error -- chat output and local file output are fully sufficient
- Omit the "Saved to Notion" line from the report

## Usage Examples

```
/meeting:intel meeting-notes.txt                    # Auto-detect source, full pipeline
/meeting:intel recording.json --source=fireflies    # Explicit Fireflies source
/meeting:intel --notion --date=2026-03-05           # Search Notion for today's meetings
/meeting:intel transcript.srt --output=chat         # Analysis to chat only
/meeting:intel notes.md --with-email --output=both  # With email context enrichment
/meeting:intel --notion                             # Search Notion for recent meeting notes
/meeting:intel call-notes.vtt --source=otter        # Otter.ai VTT export
```
