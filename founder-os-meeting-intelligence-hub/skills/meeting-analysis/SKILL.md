---
name: Meeting Analysis
description: "Processes meeting transcripts to extract summaries, decisions, follow-up commitments, and topic tags. Activates when the user wants to analyze a meeting, summarize a transcript, find what was decided, or pull action items from meeting notes — even a casual 'what happened in that meeting?' Runs four independent extraction pipelines on any transcript format."
globs:
  - "commands/meeting-intel.md"
  - "commands/meeting-analyze.md"
---

## Overview

Process a normalized meeting transcript through four independent extraction pipelines: summary generation, key decisions logging, follow-up commitment detection, and topic extraction. Each pipeline operates independently on the same input and produces its own output section. The combined result forms a structured meeting intelligence report suitable for Notion storage or chat display. This skill handles analysis only -- source gathering and transcript normalization are the responsibility of the source-gathering skill.

For the complete detection pattern libraries referenced throughout this document, see `${CLAUDE_PLUGIN_ROOT}/skills/meeting-analysis/references/extraction-patterns.md`.

## Input Format

Accept a NormalizedTranscript object produced by the source-gathering skill. The normalized structure contains:

- **title**: Meeting name or title.
- **date**: ISO date (YYYY-MM-DD) of the meeting.
- **duration**: Meeting length (e.g., "45 minutes").
- **attendees**: List of participant names.
- **source_type**: Origin platform (Fireflies, Notion, Otter, Gemini, Local File).
- **source_path**: File path or Notion URL of the original source.
- **transcript_text**: Full transcript content with speaker labels and timestamps where available.

When the input is raw text (from `/meeting:analyze` with pasted content or a file path), construct a minimal NormalizedTranscript with `title` set to the filename or "Untitled Meeting", `date` set to today, `source_type` set to "Local File", and `attendees` inferred from speaker labels in the text. Leave `duration` empty if not determinable from timestamps.

## Extraction Pipelines

Run all four pipelines independently against the transcript text. Each pipeline produces its own output section. A failure or empty result in one pipeline does not block the others.

### Pipeline 1: Meeting Summary

Generate a concise 3-5 sentence summary capturing the essential meeting content.

#### Extraction Steps

1. Identify the 2-4 main topics discussed by scanning for shifts in subject matter, agenda items, or explicit topic transitions ("Moving on to...", "Next item...").
2. Note key participants and their roles in the discussion. Identify the meeting facilitator or chair when one is evident (opens the meeting, directs discussion, calls for votes).
3. Determine the meeting outcome: decisions reached, consensus achieved, open questions remaining, or next steps agreed upon.
4. Compose a 3-5 sentence summary in plain English. Lead with the meeting purpose, follow with key discussion points, and close with the outcome or status.

#### Summary Rules

- Write in past tense ("The team discussed...", "A decision was made to...").
- Name specific participants only when their contribution is central to the outcome.
- Avoid filler language ("Various topics were covered"). Be specific about what was discussed.
- When the transcript is short or unfocused, reduce to 2-3 sentences rather than padding.

### Pipeline 2: Key Decisions Log

Detect and extract explicit and inferred decisions from the transcript.

#### Detection Approach

Scan for decision language using two confidence tiers:

**Explicit decisions** (confidence: Explicit) -- Direct statements of a resolved choice. Key patterns include "We decided...", "Agreement:", "Let's go with...", "The decision is...", "Going forward...", "We'll proceed with...", "Final answer is...". See `${CLAUDE_PLUGIN_ROOT}/skills/meeting-analysis/references/extraction-patterns.md` for the full pattern list.

**Inferred decisions** (confidence: Inferred) -- Contextual consensus without direct decision language. Detect when a proposal receives no objection and discussion moves on, when a participant states a plan and others agree or remain silent, or when a topic concludes with an implicit resolution.

#### Decision Record Fields

For each detected decision, extract:

- **decision_text**: The decision statement in clear, standalone language.
- **proposer**: The participant who proposed or announced the decision. Set to "Group" when no single proposer is identifiable.
- **context**: 1-2 sentences of surrounding discussion that led to the decision.
- **confidence**: "Explicit" or "Inferred" based on the detection method.
- **disputed**: Boolean. Set to `true` when disagreement markers appear within 3 speaker turns of the decision. Set to `false` when consensus was clear.
- **dissent**: When `disputed` is true, note the dissenting position and who raised it. Set to null when `disputed` is false.

#### Disagreement Flagging

When a decision is preceded by explicit disagreement ("I disagree", "I'm not sure about that", "My concern is...", "I'd prefer..."), include the dissenting position in the `dissent` field. This preserves minority viewpoints for the meeting record. Do not editorialize on who was right -- capture the positions factually.

### Pipeline 3: Follow-Up Commitments

Detect actionable commitments that participants made during the meeting. Format output to be compatible with #06 Follow-Up Tracker's promise pattern structure.

#### Detection Approach

Scan for commitment language where a named person accepts or is assigned a task. Key patterns include "I'll send...", "I'll have that by...", "[Name] will...", "Can you [action] by [date]?", "By [date] we need to...", "[Name], please...", "I'm going to...", "Let me take care of...". See `${CLAUDE_PLUGIN_ROOT}/skills/meeting-analysis/references/extraction-patterns.md` for the full pattern list.

#### Commitment Record Fields

For each detected follow-up, extract:

- **who**: The person responsible for the commitment. Parse from speaker label, named reference ("[Name] will..."), or self-reference ("I'll..."). When the speaker uses "I'll", resolve to the speaker's name from the transcript label.
- **what**: The committed action in clear, standalone language. Strip conversational filler to produce a clean task description.
- **deadline**: Parsed deadline when temporal language is present. Convert relative references ("by end of week", "next Monday", "tomorrow") to ISO dates relative to the meeting date. Set to null when no deadline is mentioned.
- **mentioned_by**: The speaker who stated or assigned the commitment (may differ from `who` in delegation cases like "John, can you handle that?").

#### #06 Compatibility Format

Structure each commitment to align with #06 Follow-Up Tracker's promise patterns:

```
promise_type: "Promise Made" | "Promise Received"
promise_text: [the verbatim commitment phrase from transcript]
who: [assignee name]
what: [cleaned task description]
deadline: [ISO date or null]
source: "Meeting Transcript"
```

Set `promise_type` to "Promise Made" when the meeting attendee self-commits ("I'll do X") and "Promise Received" when someone is assigned a task by another participant.

### Pipeline 4: Topic Extraction

Identify 3-7 topic tags that characterize the meeting content.

#### Extraction Steps

1. Scan the transcript for recurring noun phrases and domain-specific terms. Weight by frequency -- terms appearing in multiple speaker turns carry more signal than single mentions.
2. Filter out generic meeting language ("agenda", "minutes", "next steps") that describes the meeting format rather than its content.
3. Consolidate synonyms and related terms into a single tag. Prefer the more specific term ("Q2 marketing budget" over "budget").
4. Cap at 7 tags. When more than 7 candidates emerge, rank by frequency and keep the top 7.
5. Aim for a minimum of 3 tags. When the transcript is too short or unfocused to yield 3 distinct topics, produce whatever is identifiable and note the limited scope.

#### Notion Tag Matching

When saving to Notion, check the existing `multi_select` options on the Topics property of the target database ("[FOS] Meetings" or fallback "Founder OS HQ - Meetings" / "Meeting Intelligence Hub - Analyses"). Prefer matching existing tags over creating new ones:

1. For each extracted topic, check if a case-insensitive match exists in the current tag options.
2. If a close match exists (e.g., extracted "Marketing Strategy" vs existing "Marketing"), use the existing tag.
3. If no match exists, create a new tag with the extracted term.

This keeps the tag taxonomy consistent across meeting analyses and enables filtering by topic in the Notion database.

## Output Schema

Produce a structured meeting intelligence report combining all four pipeline outputs:

```
Meeting Title:     [from NormalizedTranscript]
Date:              [YYYY-MM-DD]
Duration:          [from NormalizedTranscript or "Unknown"]
Source:            [source_type]
Attendees:         [comma-separated list]

## Summary
[3-5 sentence summary from Pipeline 1]

## Key Decisions
[For each decision:]
- **Decision**: [decision_text]
  - Proposed by: [proposer]
  - Confidence: [Explicit/Inferred]
  - Context: [context]
  - Disputed: [Yes/No]
  - Dissent: [dissent or "None"]

## Follow-Up Commitments
[For each commitment:]
- **[who]**: [what]
  - Deadline: [ISO date or "Not specified"]
  - Mentioned by: [mentioned_by]

## Topics
[Comma-separated topic tags]
```

When a pipeline produces no results (e.g., no decisions detected), include the section header with an explanatory note: "No explicit decisions detected in this transcript."

## Notion DB Integration

### Database Discovery

Search Notion for the shared meetings database. Do NOT lazy-create the database.

**Lookup flow:**
1. Search Notion for a database titled "[FOS] Meetings".
2. If found, use it.
3. If not found, try "Founder OS HQ - Meetings".
4. If not found, fall back to "Meeting Intelligence Hub - Analyses".
5. If none is found, warn: "No Meetings database found in Notion. Analysis will be displayed in chat only." Continue without Notion storage.

### P07-Owned Fields

Only write these fields when saving analysis results:

| Property | Type | Description |
|----------|------|-------------|
| Meeting Title | title | Meeting name |
| Event ID | rich_text | Calendar event ID when available (shared idempotent key with P03) |
| Date | date | Meeting date |
| Attendees | rich_text | Comma-separated participant names |
| Source Type | select | Fireflies / Otter / Gemini / Notion / Generic |
| Transcript File | rich_text | Path to saved transcript file |
| Summary | rich_text | 3-5 sentence summary |
| Decisions | rich_text | Formatted decisions list |
| Follow-Ups | rich_text | Formatted commitments list |
| Topics | multi_select | Extracted topic tags |
| Duration | number | Meeting duration in minutes |
| Company | relation | Associated company when attendees match CRM contacts (relation to "[FOS] Companies") |
| Generated At | date | Timestamp of analysis generation |

**P03-owned fields** (do NOT overwrite if they already have values): Prep Notes, Talking Points, Importance Score, Sources Used.

### Idempotent Updates

Use Event ID as the primary idempotent key when available (e.g., when the transcript can be matched to a calendar event). Fall back to Meeting Title + Date as a compound lookup key when Event ID is not available.

Before creating a new record, query the database for an existing row matching the Event ID (or Meeting Title + Date). When a match is found (possibly created by P03 Meeting Prep Autopilot), update the existing row with P07-owned fields only. Do not overwrite P03 fields. Append a note to the page: "Re-analyzed at [timestamp] -- replaces previous analysis." Never create duplicate records for the same meeting.

**Company relation:**
When meeting attendees can be matched to CRM contacts (via Notion CRM search by name or email), set the Company relation to the matching company from "[FOS] Companies". If no CRM match is found, leave the Company relation empty.

### Notion Unavailable

When the Notion MCP server is not connected, output the full intelligence report to chat. Do not treat Notion unavailability as an error. Append: "Notion unavailable -- analysis displayed in chat only. Re-run with Notion connected to save."

## Cross-Plugin Integration

### #04 Action Item Extractor

After completing the analysis, suggest running the Action Item Extractor on the transcript for deeper action item extraction:

> "For additional action items, run `/actions:extract-file [transcript-path]` -- the transcript is pre-formatted with speaker labels for optimal extraction."

Include the actual transcript file path in the suggestion. Do not auto-run #04 -- present the suggestion and let the user decide.

### #06 Follow-Up Tracker

Follow-up commitments from Pipeline 3 are formatted to be compatible with #06's promise pattern structure. When #06 is available, the commitments can be directly imported into the Follow-Up Tracker database. The `promise_type`, `promise_text`, `who`, `what`, `deadline`, and `source` fields map directly to #06's tracking schema.

Note this integration in the output: "Follow-ups are formatted for #06 Follow-Up Tracker compatibility."

## Edge Cases

### Short Transcripts (< 500 words)

When the transcript is fewer than 500 words:
- Warn: "Short transcript ([word count] words) -- some extraction pipelines may produce limited results."
- Still run all four pipelines. Short meetings may still contain decisions and commitments.
- Expect the summary to be 2-3 sentences rather than the full 3-5.
- Accept fewer than 3 topic tags without additional warnings.

### No Speaker Labels

When the transcript lacks speaker identification (plain text without "Speaker:", "[Name]:", or similar labels):
- Set all `proposer`, `who`, and `mentioned_by` fields to "Unknown Speaker".
- Note in the output: "Transcript lacks speaker labels -- participant attribution is unavailable."
- All other extraction logic proceeds normally.

### Overlapping or Repeated Content

When the transcript contains repeated segments (common in auto-generated transcripts with corrections or disfluencies):
- Deduplicate decisions and commitments by content similarity. Two entries with >80% text overlap count as one.
- Prefer the version with more context or clearer language.

### Non-English Transcripts

When the transcript is primarily non-English, warn about reduced accuracy and attempt best-effort extraction. Decision and commitment patterns may still match if the transcript uses common English business phrases.

### Multiple Meetings in One Transcript

When the transcript contains clear meeting boundaries (new date headers, "Meeting adjourned" followed by new attendees), treat as separate meetings. Run pipelines independently for each segment and create separate Notion records.

## Additional Resources

Consult these reference files for detailed implementation guidance:

- `${CLAUDE_PLUGIN_ROOT}/skills/meeting-analysis/references/extraction-patterns.md` -- Complete detection pattern libraries for decisions, commitments, topic extraction, and disagreement signals. Includes language variants, edge case patterns, and false positive filters.
