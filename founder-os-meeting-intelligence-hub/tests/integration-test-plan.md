# Integration Test Plan: Meeting Intelligence Hub

## Test Environment

- Notion workspace with meeting notes pages (some in a "Meeting Notes" database, some standalone)
- Filesystem MCP configured with read access to local transcript files
- Sample transcript files prepared in multiple formats: `.txt`, `.md`, `.json`, `.srt`, `.vtt`
- Google Drive configured (optional -- some tests verify graceful degradation without it)
- Gmail configured (optional -- some tests verify graceful degradation without it)
- Notion integration API key configured

### Sample Files Required

Prepare these files in a local `test-fixtures/` directory before running tests:

- `fireflies-export.txt` -- Fireflies.ai TXT export with header, speaker labels, HH:MM:SS timestamps
- `fireflies-export.json` -- Fireflies.ai JSON export with structured fields
- `otter-export.txt` -- Otter.ai TXT export with speaker labels and "Transcribed by Otter" footer
- `otter-export.srt` -- Otter.ai SRT subtitle export with sequential IDs and `-->` timestamps
- `gemini-notes.md` -- Exported Gemini meeting notes with attendees and speaker labels
- `generic-transcript.txt` -- Plain text with `Name: text` speaker labels, no service signatures
- `generic-no-speakers.txt` -- Plain text meeting content without any speaker labels
- `subtitles.vtt` -- WebVTT file with `WEBVTT` header and cue timestamps
- `empty-file.txt` -- Zero-byte file
- `short-meeting.txt` -- Meeting transcript under 500 words with 1 decision and 1 follow-up
- `non-english.txt` -- Meeting transcript primarily in Spanish/French
- `multi-meeting.txt` -- Two concatenated meetings with clear boundary markers ("Meeting adjourned")
- `music-only.srt` -- SRT file containing only `[Music]` and `[Applause]` cues
- `binary-file.pdf` -- Binary file to test unsupported format rejection

## Test Scenarios

---

### Section 1: Source Gathering -- Adapter Detection

---

#### Scenario 1.1: Fireflies.ai TXT Auto-Detection

**Preconditions**: `fireflies-export.txt` exists with "Fireflies.ai" in the header, `Speaker Name:` labels, and `HH:MM:SS` timestamps.

**Steps**:
1. Run `/meeting:intel test-fixtures/fireflies-export.txt`
2. Observe the detected source type in the output.

**Expected Result**:
- Source detected as "Fireflies.ai" (reported before processing)
- NormalizedTranscript produced with: title from file header, date parsed from metadata, attendees extracted from speaker labels, duration computed from first/last timestamps
- Speaker names preserved and deduplicated (e.g., "John S." merged with "John Smith")
- Full pipeline completes with analysis report

**Validates**: Design doc "5 source adapters" / Source-gathering skill "Adapter 1: Fireflies.ai" / Auto-detection priority 1

---

#### Scenario 1.2: Fireflies.ai JSON Structured Parse

**Preconditions**: `fireflies-export.json` exists with structured fields (title, date, duration, attendees, transcript.segments).

**Steps**:
1. Run `/meeting:intel test-fixtures/fireflies-export.json --source=fireflies`
2. Observe field extraction from JSON structure.

**Expected Result**:
- Fields extracted directly from JSON: title, date, duration, attendees, segments
- Speaker turns reconstructed from `transcript.segments[].speaker` and `transcript.segments[].text`
- NormalizedTranscript `source_type` is `fireflies`
- Full pipeline completes

**Validates**: Source-gathering skill "Adapter 1: Fireflies.ai -- JSON handling"

---

#### Scenario 1.3: Otter.ai TXT Auto-Detection

**Preconditions**: `otter-export.txt` exists with "Transcribed by Otter" footer and `Speaker Name HH:MM:SS` patterns.

**Steps**:
1. Run `/meeting:intel test-fixtures/otter-export.txt`
2. Observe the detected source type.

**Expected Result**:
- Source detected as "Otter.ai" (footer signature match)
- Speaker labels parsed from `Speaker Name  HH:MM:SS` format
- Meeting title and date extracted from header
- NormalizedTranscript `source_type` is `otter`
- Full pipeline completes

**Validates**: Source-gathering skill "Adapter 3: Otter.ai" / Auto-detection priority 2

---

#### Scenario 1.4: Otter.ai SRT Format

**Preconditions**: `otter-export.srt` exists with sequential numeric IDs, `-->` timestamp lines, and speaker-prefixed subtitle text, plus "Otter.ai" in the file.

**Steps**:
1. Run `/meeting:intel test-fixtures/otter-export.srt`
2. Observe detection and SRT parsing.

**Expected Result**:
- Detected as Otter.ai (specific adapter preferred over generic SRT per ambiguity rule)
- SRT blocks parsed: timestamps converted to `HH:MM:SS`, text lines joined per block
- HTML formatting tags (`<b>`, `<i>`) stripped from subtitle text
- Speaker labels extracted from subtitle text prefixes
- NormalizedTranscript produced with inline timestamps

**Validates**: Source-gathering skill "Adapter 3: Otter.ai -- SRT handling" / Ambiguity handling rule

---

#### Scenario 1.5: Notion Meeting Notes Search

**Preconditions**: Notion workspace contains 3+ pages with titles containing "meeting", "sync", or "standup". At least one has a Date property matching today.

**Steps**:
1. Run `/meeting:intel --notion --date=2026-03-05`
2. If multiple matches, select one from the numbered list.

**Expected Result**:
- Notion searched for pages matching meeting-note title patterns
- Results filtered to pages with date matching 2026-03-05
- If single match: used automatically. If multiple: numbered list presented with title, date, and parent context
- Page content extracted and converted to plain text
- Participants extracted from "Participants"/"Attendees" property or @-mentions
- NormalizedTranscript `source_type` is `notion`, `source_path` is the Notion page URL
- Full pipeline completes

**Validates**: Design doc "Notion meeting notes source" / Source-gathering skill "Adapter 2: Notion Meeting Notes"

---

#### Scenario 1.6: Notion Search -- No Results

**Preconditions**: Notion workspace contains no meeting notes pages matching the filter date.

**Steps**:
1. Run `/meeting:intel --notion --date=2020-01-01`

**Expected Result**:
- Halt with: "No meeting notes found in Notion matching the criteria. Try a different date or provide a local file path instead."
- No analysis performed, no Notion DB written

**Validates**: Command meeting-intel.md "Step 1 -- --notion Flag Provided" point 5

---

#### Scenario 1.7: Gemini via Google Drive

**Preconditions**: Google gws CLI (Drive) configured. Drive contains a Google Doc with "Meeting notes" in the title.

**Steps**:
1. Run `/meeting:intel --source=gemini --date=2026-03-05`
2. If multiple matches, select one from the list.

**Expected Result**:
- Drive searched for docs with "Meeting notes" in title
- Results filtered by date
- Document content extracted: meeting title, date, attendees, transcript body
- NormalizedTranscript `source_type` is `gemini`, `source_path` is the Drive document URL
- Full pipeline completes

**Validates**: Design doc "Gemini (Google Drive)" source adapter / Source-gathering skill "Adapter 4: Gemini"

---

#### Scenario 1.8: Gemini Source Without gws CLI (Drive)

**Preconditions**: Google gws CLI (Drive) is NOT configured.

**Steps**:
1. Run `/meeting:intel --source=gemini`

**Expected Result**:
- Halt with: "Google gws CLI (Drive) is not configured. Export the Gemini transcript as a local file and run: `/meeting:intel path/to/file --source=gemini`"
- No fallback attempted

**Validates**: Command meeting-intel.md "Step 1 -- --source=gemini" point 5 / Design doc "Graceful Degradation" for Drive

---

#### Scenario 1.9: Generic Local File -- Plain Text

**Preconditions**: `generic-transcript.txt` exists with `Name: text` speaker labels but no Fireflies/Otter signatures.

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt`

**Expected Result**:
- Auto-detection finds no service signatures; falls back to Generic Local Files adapter
- Source reported as "Local File"
- Speaker labels detected from `Name: text` patterns
- Title inferred from filename: "generic-transcript"
- Date inferred from content patterns or file modification date (flagged if using modification date)
- Full pipeline completes

**Validates**: Source-gathering skill "Adapter 5: Generic Local Files" / Auto-detection fallback (priority 4)

---

#### Scenario 1.10: Generic Local File -- VTT Format

**Preconditions**: `subtitles.vtt` exists with `WEBVTT` header and cue timing lines.

**Steps**:
1. Run `/meeting:intel test-fixtures/subtitles.vtt`

**Expected Result**:
- VTT format detected from file extension and `WEBVTT` header
- VTT headers and metadata stripped
- Cue timing lines converted to inline `[HH:MM:SS]` timestamps in plain text
- NormalizedTranscript `source_type` is `local_file`
- Full pipeline completes

**Validates**: Source-gathering skill "Adapter 5: Generic Local Files -- VTT conversion" / Auto-detection step 1 (extension routing)

---

#### Scenario 1.11: Explicit Source Hint Overrides Auto-Detection

**Preconditions**: `generic-transcript.txt` exists without Fireflies signatures.

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt --source=fireflies`

**Expected Result**:
- Fireflies adapter used directly (explicit hint overrides auto-detection)
- Fireflies-specific parsing applied (may extract less data since signatures are absent)
- Source reported as "Fireflies.ai"
- Pipeline completes (gracefully handles missing Fireflies-specific metadata)

**Validates**: Source-gathering skill "Source Detection Algorithm" step 1 -- explicit source hint

---

### Section 2: Analysis Pipeline Tests

---

#### Scenario 2.1: Meeting Summary Extraction

**Preconditions**: A transcript with 3+ distinct discussion topics, identifiable facilitator, and clear conclusion.

**Steps**:
1. Run `/meeting:analyze test-fixtures/generic-transcript.txt --output=chat`
2. Inspect the Summary section of the report.

**Expected Result**:
- Summary is 3-5 sentences
- Written in past tense
- Identifies 2-4 main topics discussed
- Names key participants only when central to outcome
- Closes with outcome, decision, or open questions
- No filler language

**Validates**: Meeting-analysis skill "Pipeline 1: Meeting Summary" / Summary Rules

---

#### Scenario 2.2: Key Decisions -- Explicit and Inferred

**Preconditions**: A transcript containing explicit decision phrases ("We decided to use React for the frontend") and implicit consensus (proposal with no objection, discussion moves on).

**Steps**:
1. Run `/meeting:analyze test-fixtures/generic-transcript.txt --output=chat`
2. Inspect the Key Decisions section.

**Expected Result**:
- Explicit decisions detected with confidence "Explicit"
- Inferred decisions detected with confidence "Inferred"
- Each decision has: decision_text, proposer, context, confidence
- Disagreement flagged where present (dissent field populated)
- No duplicate decisions for repeated/similar content (>80% overlap deduplication)

**Validates**: Meeting-analysis skill "Pipeline 2: Key Decisions Log" / Disagreement Flagging / Overlapping content dedup

---

#### Scenario 2.3: Follow-Up Commitments -- #06 Compatibility

**Preconditions**: A transcript containing commitment patterns ("I'll send the proposal by Friday", "Sarah will review the budget", "Can you update the roadmap by next Monday?").

**Steps**:
1. Run `/meeting:analyze test-fixtures/generic-transcript.txt --output=chat`
2. Inspect the Follow-Up Commitments section.

**Expected Result**:
- Each commitment extracted with: who, what, deadline (ISO date), mentioned_by
- "I'll" resolved to the speaker's name from transcript label
- Deadlines parsed from relative language (e.g., "by Friday" resolved to ISO date relative to meeting date)
- Delegation cases: "Can you X?" sets `who` to addressee, `mentioned_by` to speaker
- Each commitment includes `promise_type`: "Promise Made" for self-commits, "Promise Received" for assignments
- Output note: "Follow-ups are formatted for #06 Follow-Up Tracker compatibility."

**Validates**: Meeting-analysis skill "Pipeline 3: Follow-Up Commitments" / #06 Compatibility Format / Design doc "Follow-ups feed: #06"

---

#### Scenario 2.4: Topic Extraction with Tag Range

**Preconditions**: A transcript discussing multiple distinct topics (e.g., "Q2 budget", "hiring timeline", "product launch", "marketing strategy").

**Steps**:
1. Run `/meeting:analyze test-fixtures/generic-transcript.txt --output=chat`
2. Inspect the Topics section.

**Expected Result**:
- 3-7 topic tags extracted
- Tags are specific ("Q2 Marketing Budget" not "budget")
- Generic meeting language filtered out ("agenda", "minutes", "next steps")
- Synonyms consolidated (no "Marketing Plan" and "Marketing Strategy" as separate tags)
- Tags ranked by frequency (multi-speaker mentions weighted higher)

**Validates**: Meeting-analysis skill "Pipeline 4: Topic Extraction" / Extraction Steps 1-5

---

#### Scenario 2.5: Topic Tags -- Notion Existing Tag Matching

**Preconditions**: "[FOS] Meetings" DB exists in Notion with Topics multi_select options including "Marketing", "Engineering", "Budget".

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt --output=notion`
2. Inspect Topics property on the created Notion row.

**Expected Result**:
- Extracted topic "Marketing Strategy" matched to existing "Marketing" tag
- New topics not in existing options created as new tags
- Tag taxonomy stays consistent (no near-duplicate tags like "Marketing" and "marketing")

**Validates**: Meeting-analysis skill "Pipeline 4: Topic Extraction -- Notion Tag Matching"

---

#### Scenario 2.6: All Pipelines Run Independently

**Preconditions**: A transcript where the decisions section will produce results but the follow-up section will be empty (no commitment language).

**Steps**:
1. Run `/meeting:analyze test-fixtures/generic-transcript.txt --output=chat`

**Expected Result**:
- Summary section populated
- Decisions section populated
- Follow-Ups section shows: "None detected -- no follow-up commitments found."
- Topics section populated
- Empty follow-ups did not block or affect other pipelines

**Validates**: Meeting-analysis skill "Run all four pipelines independently" / "A failure or empty result in one pipeline does not block the others"

---

### Section 3: Command Tests -- `/meeting:intel`

---

#### Scenario 3.1: Full Pipeline -- Default Flags

**Preconditions**: `generic-transcript.txt` exists. Notion MCP configured.

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt`

**Expected Result**:
1. Source detected and reported
2. NormalizedTranscript produced
3. All 4 analysis pipelines run
4. Transcript saved to `transcripts/[slug]-[date].md` with metadata header
5. Notion row created in "[FOS] Meetings"
6. Chat report displayed with all sections (Meeting header, Summary, Key Decisions table, Follow-Up Commitments table, Topics, Files)
7. Cross-plugin suggestions displayed: `/actions:extract-file` and `/followup:check` mentions

**Validates**: Design doc "Commands -- /meeting:intel" full workflow (Steps 1-7)

---

#### Scenario 3.2: Explicit Source Flag

**Preconditions**: `fireflies-export.txt` exists.

**Steps**:
1. Run `/meeting:intel test-fixtures/fireflies-export.txt --source=fireflies`

**Expected Result**:
- Fireflies adapter used directly (no auto-detection)
- Pipeline completes with Fireflies-specific metadata extraction
- Source Type in output and Notion row shows "Fireflies"

**Validates**: Command meeting-intel.md "Parse Arguments -- --source"

---

#### Scenario 3.3: Date Filter Flag

**Preconditions**: `generic-transcript.txt` contains a meeting dated 2026-03-01.

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt --date=2026-03-05`

**Expected Result**:
- Warning: "File date 2026-03-01 does not match --date filter 2026-03-05. Proceeding with file content."
- Analysis proceeds with the file content as-is
- Pipeline does not halt

**Validates**: Command meeting-intel.md "Step 1 -- Local File Path Provided" point 5

---

#### Scenario 3.4: Output Chat Only

**Preconditions**: `generic-transcript.txt` exists. Notion MCP configured.

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt --output=chat`

**Expected Result**:
- Full analysis report displayed in chat
- Transcript file saved locally
- No Notion write operations performed
- Notion line omitted from Files section of report

**Validates**: Command meeting-intel.md "Step 5 -- output includes notion" condition / "Step 6 -- output includes chat" condition

---

#### Scenario 3.5: Output Notion Only

**Preconditions**: `generic-transcript.txt` exists. Notion MCP configured.

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt --output=notion`

**Expected Result**:
- Notion row created with all 12 properties populated
- Transcript file saved locally
- Chat report still displayed (verify whether chat output is suppressed or always shown)

**Validates**: Command meeting-intel.md "Step 5" + "Step 6" output routing

---

#### Scenario 3.6: Email Enrichment with --with-email

**Preconditions**: gws CLI (Gmail) configured. `generic-transcript.txt` exists with identifiable meeting title and attendee names.

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt --with-email`

**Expected Result**:
- Gmail searched for threads matching meeting title, attendee names, or meeting date (3-day window)
- Email context (agendas, follow-ups, shared materials) attached as supplemental input
- Analysis pipelines incorporate email context (decisions/follow-ups from email threads captured)
- Report may include richer context from email enrichment

**Validates**: Command meeting-intel.md "Step 2: Email Enrichment" / Design doc "Gmail -- Email context enrichment"

---

#### Scenario 3.7: Email Enrichment -- Gmail Unavailable

**Preconditions**: gws CLI (Gmail) is NOT configured.

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt --with-email`

**Expected Result**:
- Warning: "gws CLI (Gmail) not configured -- skipping email enrichment. Analysis proceeds without email context."
- Full pipeline continues without email data
- Analysis report produced from transcript only
- No error or halt

**Validates**: Command meeting-intel.md "Step 2" point 5 / Design doc "Graceful Degradation" for Gmail

---

#### Scenario 3.8: Transcript File Saved with Correct Slug

**Preconditions**: Transcript with title "Q2 Planning & Budget Review" dated 2026-03-05.

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt --output=chat`
2. Check the `transcripts/` directory.

**Expected Result**:
- File created at `transcripts/q2-planning-budget-review-2026-03-05.md`
- Slug is lowercase, spaces replaced with hyphens, special characters stripped, consecutive hyphens collapsed
- File contains metadata header (title, date, source type, attendees, duration) followed by full normalized transcript
- `transcripts/` directory created if it did not exist

**Validates**: Command meeting-intel.md "Step 4: Save Transcript" (points 1-5)

---

#### Scenario 3.9: No Source Argument Provided

**Preconditions**: None.

**Steps**:
1. Run `/meeting:intel` (no arguments)

**Expected Result**:
- Prompt: "Provide a file path to a transcript, or use `--notion` to search Notion for meeting notes."
- Command stops and waits for input
- No analysis performed

**Validates**: Command meeting-intel.md "Parse Arguments -- [source-or-file]" fallback

---

#### Scenario 3.10: Cross-Plugin Suggestions Displayed

**Preconditions**: `generic-transcript.txt` processed successfully.

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt --output=chat`
2. Inspect the "Next Steps" section at the end of the report.

**Expected Result**:
- Suggestion: "Run `/actions:extract-file transcripts/[actual-file-path]` to extract granular action items with priority scoring and Notion task creation"
- Suggestion: "Follow-up commitments above are compatible with `/followup:check` for automated nudge tracking"
- Actual transcript file path included in the `/actions:extract-file` suggestion (not a placeholder)

**Validates**: Command meeting-intel.md "Step 7: Cross-Plugin Suggestions" / Design doc "Suggests: #04 Action Item Extractor"

---

### Section 4: Command Tests -- `/meeting:analyze`

---

#### Scenario 4.1: Analyze Local File -- Default (Chat Output)

**Preconditions**: `generic-transcript.txt` exists.

**Steps**:
1. Run `/meeting:analyze test-fixtures/generic-transcript.txt`

**Expected Result**:
- File read successfully
- Minimal NormalizedTranscript constructed (title from filename, date from content or today, source_type "Local File")
- All 4 analysis pipelines run
- Report displayed in chat (default output for `/meeting:analyze` is `chat`)
- No Notion write operations
- Cross-plugin suggestion includes `/actions:extract-file` with the actual file path

**Validates**: Command meeting-analyze.md full workflow / Default output=chat

---

#### Scenario 4.2: Analyze Pasted Text

**Preconditions**: None (user pastes text directly).

**Steps**:
1. Run `/meeting:analyze`
2. Paste multi-line meeting text in conversation.

**Expected Result**:
- Input detected as pasted text (no file extension, multi-line)
- Title set from first non-empty line (truncated to 80 chars) or "Untitled Meeting"
- Source type set to "Direct Input"
- All 4 analysis pipelines run
- `/actions:extract-file` suggestion omitted (pasted text has no file path)
- `/followup:check` suggestion still present

**Validates**: Command meeting-analyze.md "Step 1 -- Pasted text detected" / "Step 5" suggestion file-path condition

---

#### Scenario 4.3: Analyze with Notion Output

**Preconditions**: `generic-transcript.txt` exists. Notion MCP configured.

**Steps**:
1. Run `/meeting:analyze test-fixtures/generic-transcript.txt --output=notion`

**Expected Result**:
- Analysis performed
- Notion row created in "[FOS] Meetings" with Source Type "Local File"
- All 12 properties populated
- Chat report also displayed
- Notion saved line present in footer

**Validates**: Command meeting-analyze.md "Step 3: Save to Notion"

---

#### Scenario 4.4: Analyze with --output=both

**Preconditions**: `generic-transcript.txt` exists. Notion MCP configured.

**Steps**:
1. Run `/meeting:analyze test-fixtures/generic-transcript.txt --output=both`

**Expected Result**:
- Report displayed in chat
- Notion row created
- Footer shows "Saved to Notion: [FOS] Meetings"

**Validates**: Command meeting-analyze.md "Step 3" + "Step 4" combined output

---

#### Scenario 4.5: Analyze -- No Input Provided

**Preconditions**: None.

**Steps**:
1. Run `/meeting:analyze` (no arguments, no pasted text)

**Expected Result**:
- Prompt: "Provide a file path to a transcript, or paste the meeting text directly."
- Command stops and waits for input

**Validates**: Command meeting-analyze.md "Step 1" point 3

---

#### Scenario 4.6: Analyze Does NOT Load Source-Gathering Skill

**Preconditions**: `generic-transcript.txt` exists.

**Steps**:
1. Run `/meeting:analyze test-fixtures/generic-transcript.txt`
2. Observe which skills are loaded.

**Expected Result**:
- Only meeting-analysis skill loaded
- No source detection or auto-detection logic executed
- No source type reported (input treated directly)
- Analysis pipelines run on raw content

**Validates**: Command meeting-analyze.md "Do not load the source-gathering skill"

---

### Section 5: Notion Integration

---

#### Scenario 5.1: No Database Found -- Graceful Fallback

**Preconditions**: Neither "[FOS] Meetings" nor "Meeting Intelligence Hub - Analyses" database exists in Notion.

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt --output=notion`

**Expected Result**:
- Database search finds no match for "[FOS] Meetings"
- Fallback search finds no match for "Meeting Intelligence Hub - Analyses"
- Warning: "No Meetings database found in Notion. Analysis displayed in chat only."
- No database lazy-created
- Full analysis pipeline completes
- Report displayed in chat
- Transcript file saved locally
- No Notion write operations performed

**Validates**: Meeting-analysis skill "Database Discovery" -- no lazy creation, graceful fallback to chat

---

#### Scenario 5.2: Existing Database Discovered and Used

**Preconditions**: "[FOS] Meetings" database exists in Notion (created by HQ setup).

**Steps**:
1. Run `/meeting:intel test-fixtures/fireflies-export.txt --output=notion`

**Expected Result**:
- "[FOS] Meetings" database discovered and used
- New row added with P07-owned fields populated
- P03-owned fields left empty (Prep Notes, Talking Points, Importance Score, Sources Used)
- Company relation set if attendees match CRM contacts
- Schema unchanged

**Validates**: Meeting-analysis skill "Database Discovery" step 1-2

---

#### Scenario 5.3: Idempotent Update -- Same Meeting Re-Analyzed

**Preconditions**: A row already exists in the database for meeting "Q2 Planning" on 2026-03-05.

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt --output=notion` (same meeting title and date as existing row)

**Expected Result**:
- Existing row detected via Event ID (rich_text) match, or Meeting Title + Date compound lookup as fallback
- Existing row updated with fresh P07-owned analysis results (not duplicated)
- P03-owned fields preserved if they had values
- Re-analysis note appended: "Re-analyzed at [timestamp] -- replaces previous analysis."
- No duplicate row created
- Generated At timestamp updated

**Validates**: Meeting-analysis skill "Idempotent Updates" -- Event ID primary key, Title+Date fallback

---

#### Scenario 5.3b: Cross-Plugin Deduplication -- P03 Record Already Exists

**Goal**: Verify that when P03 Meeting Prep Autopilot has already created a record for a meeting (same Event ID), P07 updates that record with analysis fields instead of creating a duplicate.

**Preconditions**:
- "[FOS] Meetings" database exists
- A row already exists for a specific Event ID, created by P03 (has Prep Notes, Talking Points, Importance Score, Sources Used populated)
- The P03 row's P07-specific fields (Summary, Decisions, Follow-Ups, Topics, Source Type, Transcript File, Duration) are empty

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt --output=notion` where the transcript's meeting matches the P03 record's Event ID
2. Inspect the database row

**Expected Result**:
- Existing row detected via Event ID match
- P07-owned fields now populated: Summary, Decisions, Follow-Ups, Topics, Source Type, Transcript File, Duration
- P03-owned fields preserved (not overwritten or cleared): Prep Notes, Talking Points, Importance Score, Sources Used
- Company relation set if attendees match CRM contacts (may already be set by P03)
- Database still contains exactly one row for this Event ID
- Generated At timestamp updated

**Validates**: Cross-plugin merge via shared Event ID key

---

#### Scenario 5.4: All 12 Properties Populated Correctly

**Preconditions**: Analysis completed for a meeting with rich content (multiple decisions, follow-ups, topics).

**Steps**:
1. Run `/meeting:intel test-fixtures/fireflies-export.txt --output=notion`
2. Inspect the Notion row.

**Expected Result**:
- Meeting Title: populated from NormalizedTranscript title
- Event ID: populated when calendar event ID is available
- Date: ISO date from the meeting
- Source Type: "Fireflies" (select value)
- Attendees: comma-separated participant names
- Summary: 3-5 sentence summary text
- Decisions: formatted numbered list
- Follow-Ups: list with owner, action, deadline per line
- Topics: multi_select tags (3-7 tags)
- Duration: meeting length in minutes (number)
- Transcript File: path to saved transcript file
- Company: relation set if attendees match CRM contacts
- Generated At: current timestamp
- P03 fields (Prep Notes, Talking Points, Importance Score, Sources Used): empty (not populated by P07)

**Validates**: Command meeting-intel.md "Step 5" / P07-owned fields schema

---

#### Scenario 5.5: Direct Input Source Type in Notion

**Preconditions**: Notion MCP configured.

**Steps**:
1. Run `/meeting:analyze` and paste text directly, with `--output=notion`

**Expected Result**:
- Source Type set to "Direct Input" in Notion row (note: "Direct Input" may need to be added as an option if not present)
- Transcript File left empty (no file saved for pasted text via `/meeting:analyze`)
- P03-owned fields left empty

**Validates**: Command meeting-analyze.md "Step 3" point 3 -- Source Type for direct input

---

### Section 6: MCP Degradation

---

#### Scenario 6.1: Notion MCP Unavailable -- /meeting:intel with --output=both

**Preconditions**: Notion MCP is NOT configured. `generic-transcript.txt` exists.

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt --output=both`

**Expected Result**:
- Warning: "Notion MCP not configured -- results displayed in chat only. Transcript saved locally."
- Full analysis pipeline completes
- Report displayed in chat with all sections
- Transcript file saved locally
- "Saved to Notion" line omitted from report
- No error or halt -- pipeline is fully functional without Notion for chat + file output
- No database lazy-creation attempted

**Validates**: Design doc "Graceful Degradation" / Command meeting-intel.md "Error Handling" / Meeting-analysis skill "Notion Unavailable"

---

#### Scenario 6.2: Notion MCP Unavailable -- /meeting:analyze with --output=notion

**Preconditions**: Notion MCP is NOT configured.

**Steps**:
1. Run `/meeting:analyze test-fixtures/generic-transcript.txt --output=notion`

**Expected Result**:
- Warning: "Notion MCP not configured -- displaying results in chat only. Re-run with Notion connected to save."
- Falls back to chat output
- Pipeline does not halt

**Validates**: Command meeting-analyze.md "Error Handling" -- Notion unavailable fallback

---

#### Scenario 6.3: Google gws CLI (Drive) Unavailable -- Non-Gemini Source

**Preconditions**: Google gws CLI (Drive) is NOT configured. `generic-transcript.txt` exists.

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt`

**Expected Result**:
- No warning about Drive (Drive not needed for local file processing)
- Full pipeline completes normally

**Validates**: Source-gathering skill "MCP Requirements" -- Drive only needed for Gemini adapter

---

#### Scenario 6.4: gws CLI (Gmail) Unavailable -- Without --with-email

**Preconditions**: gws CLI (Gmail) is NOT configured. `generic-transcript.txt` exists.

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt`

**Expected Result**:
- No warning about Gmail (email enrichment not requested)
- Full pipeline completes normally

**Validates**: Source-gathering skill "MCP Requirements" -- Gmail only needed when email enrichment requested

---

#### Scenario 6.5: All Optional MCP Servers Unavailable

**Preconditions**: Only Notion and Filesystem MCP configured. No Drive, no Gmail.

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt --with-email --output=both`

**Expected Result**:
- Gmail warning: "Gmail not connected -- email context unavailable."
- Email enrichment skipped
- Analysis proceeds with transcript only
- Notion write succeeds (required MCP available)
- Full report displayed in chat
- Pipeline does not halt or degrade beyond skipping email enrichment

**Validates**: Source-gathering skill "When an optional MCP source is unavailable, continue the pipeline"

---

### Section 7: Edge Cases

---

#### Scenario 7.1: Empty File

**Preconditions**: `empty-file.txt` exists as a zero-byte file.

**Steps**:
1. Run `/meeting:intel test-fixtures/empty-file.txt`

**Expected Result**:
- Halt with: "File is empty: test-fixtures/empty-file.txt. No content to analyze."
- No NormalizedTranscript produced
- No Notion writes, no transcript saved

**Validates**: Command meeting-intel.md "Step 1" point 2 / Source-gathering skill "Edge Cases -- Empty file"

---

#### Scenario 7.2: Short Transcript (< 500 words)

**Preconditions**: `short-meeting.txt` exists with fewer than 500 words, containing 1 decision and 1 follow-up.

**Steps**:
1. Run `/meeting:analyze test-fixtures/short-meeting.txt --output=chat`

**Expected Result**:
- Warning: "Short transcript ([N] words) -- some extraction pipelines may produce limited results."
- All 4 pipelines still run
- Summary is 2-3 sentences (not padded to 5)
- Decision detected and listed
- Follow-up detected and listed
- Topics may be fewer than 3 (accepted without additional warning)

**Validates**: Meeting-analysis skill "Edge Cases -- Short Transcripts (< 500 words)"

---

#### Scenario 7.3: Non-English Content

**Preconditions**: `non-english.txt` contains meeting transcript primarily in Spanish.

**Steps**:
1. Run `/meeting:analyze test-fixtures/non-english.txt --output=chat`

**Expected Result**:
- Warning about reduced accuracy for non-English content
- Best-effort extraction attempted
- Decision/commitment patterns may match if English business phrases are mixed in
- Pipeline does not error
- Report produced (may have limited extraction results)

**Validates**: Meeting-analysis skill "Edge Cases -- Non-English Transcripts" / Command meeting-analyze.md "Error Handling -- Non-English content"

---

#### Scenario 7.4: Multiple Meetings in One File

**Preconditions**: `multi-meeting.txt` contains two meetings separated by "Meeting adjourned" and new date headers/attendees.

**Steps**:
1. Run `/meeting:intel test-fixtures/multi-meeting.txt --output=both`

**Expected Result**:
- Meeting boundaries detected (date header change, "Meeting adjourned" marker, new attendees)
- Each meeting segment analyzed independently
- Separate Notion records created for each meeting
- Separate transcript files saved for each meeting
- Report covers both meetings (clearly delineated)

**Validates**: Meeting-analysis skill "Edge Cases -- Multiple Meetings in One Transcript"

---

#### Scenario 7.5: No Speaker Labels

**Preconditions**: `generic-no-speakers.txt` exists with meeting content but no speaker labels (no "Name:", "[Name]:", "SPEAKER_N:" patterns).

**Steps**:
1. Run `/meeting:analyze test-fixtures/generic-no-speakers.txt --output=chat`

**Expected Result**:
- Note in output: "Transcript lacks speaker labels -- participant attribution is unavailable."
- Attendees field set to empty array / "Not identified"
- Proposer, who, and mentioned_by fields all set to "Unknown Speaker"
- Summary, decisions, and topic extraction still work (content-based, not speaker-dependent)
- Follow-ups detected from action language even without speaker attribution

**Validates**: Meeting-analysis skill "Edge Cases -- No Speaker Labels" / Source-gathering skill "Edge Cases -- No speaker labels"

---

#### Scenario 7.6: Unsupported File Format

**Preconditions**: `binary-file.pdf` exists.

**Steps**:
1. Run `/meeting:intel test-fixtures/binary-file.pdf`

**Expected Result**:
- Halt with: "Unsupported file format. Supported formats: .txt, .md, .json, .srt, .vtt"
- No analysis performed

**Validates**: Command meeting-intel.md "Step 1" point 2 -- supported formats check

---

#### Scenario 7.7: File Not Found

**Preconditions**: No file exists at the given path.

**Steps**:
1. Run `/meeting:intel nonexistent/path/transcript.txt`

**Expected Result**:
- Halt with: "File not found: nonexistent/path/transcript.txt. Check the path and try again."
- No analysis performed

**Validates**: Command meeting-intel.md "Error Handling" / Command meeting-analyze.md "Error Handling"

---

#### Scenario 7.8: SRT/VTT with No Speech Content

**Preconditions**: `music-only.srt` contains only `[Music]`, `[Applause]`, and empty cues.

**Steps**:
1. Run `/meeting:intel test-fixtures/music-only.srt`

**Expected Result**:
- Non-speech cues filtered out (`[Music]`, `[Applause]`)
- Remaining content is minimal or empty
- Warning about content not appearing to be a meeting transcript (or minimal content)
- If all content filtered: halt or warn appropriately

**Validates**: Source-gathering skill "Edge Cases -- SRT/VTT with no speech content"

---

#### Scenario 7.9: Content Does Not Appear to Be a Meeting

**Preconditions**: A `.txt` file containing a recipe or random prose with no meeting signals.

**Steps**:
1. Run `/meeting:intel test-fixtures/not-a-meeting.txt`

**Expected Result**:
- Warning: "Content does not appear to be a meeting transcript or notes. Attempting analysis anyway -- results may be limited."
- Analysis proceeds best-effort
- Pipeline does not halt
- Results likely sparse (no decisions, no follow-ups, generic topics)

**Validates**: Command meeting-intel.md "Error Handling -- No meeting content detected"

---

#### Scenario 7.10: Very Large Transcript (> 50,000 words)

**Preconditions**: A transcript file exceeding 50,000 words.

**Steps**:
1. Run `/meeting:intel test-fixtures/large-transcript.txt --output=chat`

**Expected Result**:
- Warning: "Large transcript ([N] words) -- analysis may take longer."
- Full transcript processed (not truncated)
- All 4 pipelines complete
- Results may take longer but are not degraded

**Validates**: Source-gathering skill "Edge Cases -- Very large files"

---

#### Scenario 7.11: Date Conflict Between Metadata and Filename

**Preconditions**: A file named `meeting-2026-03-01.txt` whose content header says the meeting date is 2026-03-05.

**Steps**:
1. Run `/meeting:intel test-fixtures/meeting-2026-03-01.txt`

**Expected Result**:
- Log: "Date conflict -- metadata says 2026-03-05, filename says 2026-03-01. Using metadata date."
- NormalizedTranscript `date` set to 2026-03-05 (metadata preferred)

**Validates**: Source-gathering skill "Edge Cases -- Date conflicts"

---

#### Scenario 7.12: Duplicate Sources (Same Meeting in File and Notion)

**Preconditions**: Same meeting exists as a local file and a Notion page.

**Steps**:
1. Run `/meeting:intel --notion` and also have the same meeting available as a local file.

**Expected Result**:
- If both are somehow gathered, the source with richer content preferred
- Flag: "Duplicate source detected -- using [source] (more complete)."
- Only one NormalizedTranscript produced

**Validates**: Source-gathering skill "Edge Cases -- Duplicate sources"

---

### Section 8: Cross-Plugin Integration

---

#### Scenario 8.1: Action Item Extractor Suggestion with Correct Path

**Preconditions**: `/meeting:intel` pipeline completed, transcript saved to `transcripts/team-sync-2026-03-05.md`.

**Steps**:
1. Run `/meeting:intel test-fixtures/generic-transcript.txt`
2. Inspect the "Next Steps" section.

**Expected Result**:
- Suggestion includes: `/actions:extract-file transcripts/team-sync-2026-03-05.md`
- Path is the actual saved transcript path, not a placeholder
- Suggestion notes that the transcript is "pre-formatted with speaker labels for optimal extraction"
- Suggestion is informational only (does not auto-run #04)

**Validates**: Design doc "Suggests: #04 Action Item Extractor" / Meeting-analysis skill "#04 Action Item Extractor" integration

---

#### Scenario 8.2: Follow-Up Commitments -- #06 Promise Format Verification

**Preconditions**: Transcript analyzed with multiple follow-up commitments detected.

**Steps**:
1. Run `/meeting:analyze test-fixtures/generic-transcript.txt --output=chat`
2. Inspect each follow-up commitment record.

**Expected Result**:
- Each commitment has `promise_type` field: "Promise Made" or "Promise Received"
- Each commitment has `promise_text` with verbatim commitment phrase from transcript
- Each commitment has `who`, `what`, `deadline`, `source` fields
- `source` is set to "Meeting Transcript"
- Format is directly importable by #06 Follow-Up Tracker
- Output includes note: "Follow-ups are formatted for #06 Follow-Up Tracker compatibility."

**Validates**: Meeting-analysis skill "#06 Compatibility Format" / Design doc "Follow-ups feed: #06 Follow-Up Tracker"

---

#### Scenario 8.3: Pasted Text -- No /actions:extract-file Suggestion

**Preconditions**: None.

**Steps**:
1. Run `/meeting:analyze` and paste text directly.
2. Inspect the "Next Steps" section.

**Expected Result**:
- `/actions:extract-file` suggestion omitted (no file path for pasted text)
- `/followup:check` suggestion still present

**Validates**: Command meeting-analyze.md "Step 5 -- Include the actual file path only when input was a file"

---

## Summary Matrix

| Section | Scenario Count | Key Coverage |
|---------|---------------|--------------|
| 1. Source Gathering | 11 | Fireflies, Otter, Notion, Gemini, Generic, auto-detection, explicit hints |
| 2. Analysis Pipelines | 6 | Summary, decisions, follow-ups, topics, independence, Notion tag matching |
| 3. /meeting:intel | 10 | Full pipeline, flags (--source, --date, --output, --with-email), transcript saving, suggestions |
| 4. /meeting:analyze | 6 | File input, pasted text, output modes, skill loading boundary |
| 5. Notion Integration | 6 | DB discovery, fallback, idempotent updates, cross-plugin dedup, schema, Direct Input type |
| 6. MCP Degradation | 5 | Notion down, Drive down, Gmail down, all optional down, non-relevant MCP |
| 7. Edge Cases | 12 | Empty, short, non-English, multi-meeting, no speakers, unsupported format, large files, date conflicts |
| 8. Cross-Plugin | 3 | #04 suggestion with path, #06 promise format, pasted text omission |
| **Total** | **59** | |
