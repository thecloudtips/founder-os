---
name: Document QA
description: "Answers questions from Google Drive documents and generates summaries with inline citations. Activates when the user wants to ask about a document, summarize a Drive file, extract information, or asks 'what does this doc say about [topic]?' Handles multi-format extraction, answer synthesis, confidence assessment, and graceful no-answer responses."
version: 1.0.0
---

## Overview

Extract content from Google Drive documents and synthesize answers with inline citations, or generate structured summaries. This skill serves two modes: Q&A mode (for `/founder-os:drive:ask`) produces cited answers to user questions from one or more Drive files, and summarization mode (for `/founder-os:drive:summarize`) produces structured summaries at quick or detailed depth.

This skill handles content extraction, answer synthesis, citation formatting, confidence assessment, summary generation, and conflict reconciliation. File discovery, search, and relevance scoring are the responsibility of the drive-navigation skill. The command layer (`/founder-os:drive:ask`, `/founder-os:drive:summarize`) orchestrates the handoff between search and document QA.

## Content Extraction Pipeline

Extract text content from Google Drive files before performing any analysis. Handle each file format according to its extraction rules.

### Format-Specific Extraction

**Google Docs**: Extract as markdown text. Preserve heading hierarchy (H1-H4), bullet lists, numbered lists, bold/italic emphasis, and table structure. Strip comments, suggestions, and revision history.

**Google Sheets**: Extract as structured tabular data. Detect header rows by checking the first row for non-numeric, label-like values. Preserve sheet/tab names as section headings. For multi-tab spreadsheets, extract each tab as a separate section labeled with the tab name. Represent tables in markdown pipe format.

**PDFs**: Extract available text content. Note that scanned PDFs without embedded text will yield limited or no content -- report this clearly rather than guessing. Do not attempt OCR beyond what the Drive API provides natively.

**Other formats** (plain text, CSV, markdown files stored in Drive): Extract raw text content directly.

### Extraction Cap

Limit extraction to 3000 characters per source document. When a document exceeds this cap, identify the most relevant section by scanning headings and subheadings for keywords matching the user's query or the summarization target. Extract the best-matching section plus surrounding context up to the 3000-character limit. When no heading match exists, extract from the beginning of the document.

### Section Identification

For long documents, scan the heading structure first before extracting body text. Build a heading map (heading text + approximate position) and select the section most relevant to the query. This heading map also supports section-level citation (see Citation System below).

## Answer Synthesis (Q&A Mode)

Process every question through three sequential phases when operating in Q&A mode (`/founder-os:drive:ask`). Do not skip phases or reorder them.

### Phase 1: Assess

Evaluate extracted content before attempting to construct an answer.

1. **Relevance check**: For each extracted document, verify that it actually addresses the user's question. A spreadsheet of Q3 revenue data is not relevant to a question about the employee handbook. Discard sources where extracted content has no meaningful overlap with the query.
2. **Sufficiency check**: Count remaining sources after relevance filtering. Determine whether the surviving sources contain enough information to answer the question. A single source with a direct answer is sufficient. Multiple tangential sources that do not address the core question are not.
3. **Freshness check**: Flag sources with a last-modified date older than 90 days as potentially stale. Do not discard them -- stale sources may still contain valid information -- but factor staleness into confidence assessment in Phase 3.
4. **Coverage check**: Identify which parts of the question each source addresses. For multi-part questions ("What are our Q3 targets and who owns each one?"), map sources to question components. Note any components with zero source coverage.
5. **Route decision**: Based on the assessment, route to one of two paths:
   - **Answer path**: At least one source directly addresses the question with relevant content. Proceed to Phase 2.
   - **No-answer path**: No source adequately addresses the question. Skip Phase 2 and activate the no-answer pathway (see No-Answer Pathway section below).

### Phase 2: Synthesize

Construct the answer from assessed sources.

1. **Identify the primary source**: Select the document with the highest relevance to the question. This source anchors the answer.
2. **Extract key facts**: Pull specific facts, figures, procedures, definitions, or policies from each relevant source. Preserve the precision of the original content -- do not paraphrase loosely.
3. **Reconcile conflicts**: When two or more sources provide contradictory information, apply the conflict reconciliation rules (see Multi-Source Conflict Reconciliation below). Do not silently pick one version.
4. **Compose the answer**: Write a clear, direct response. Lead with the answer, not with background. Structure as:
   - **Direct answer** (1-3 sentences): Answer the question immediately.
   - **Supporting detail** (1-5 sentences): Provide context, caveats, or additional relevant information.
   - **Related information** (0-3 sentences, optional): Include only if sources contain closely related information the user likely needs.
5. **Attach citations**: Insert inline citation markers as the answer is composed. Every factual claim, procedure step, or data point must have at least one citation. See Citation System below.

### Phase 3: Format

Structure the final output for delivery.

1. **Confidence indicator**: Assess and attach a confidence level (High, Medium, or Low) based on the criteria in Confidence Assessment below.
2. **Citation block**: Append the numbered citation block at the bottom of the answer with source titles and Drive URLs.
3. **Preview line**: Generate a one-sentence preview (max 120 characters) summarizing the answer. The preview is used for Notion logging and command output headers.
4. **Staleness warning**: If any cited source was last modified more than 90 days ago, append: "Some sources may be outdated. Verify critical details against current documents."
5. **Partial coverage note**: If the assessment in Phase 1 identified question components with zero source coverage, append: "This answer covers [covered components]. No documentation was found for [uncovered components]."

## Citation System

Use numbered inline references and a citation block. Every Q&A answer must include at least one citation. See `${CLAUDE_PLUGIN_ROOT}/skills/drive/document-qa/references/citation-formats.md` for full format specification, examples, and edge cases.

### Inline Citations

Insert bracketed numbers after the sentence or clause they support:

```
The Q3 revenue target is $2.4M. [1] Marketing owns the lead generation
milestone, while Sales owns the conversion target. [2]
```

Rules:
- Place the citation marker after the period when it cites the entire sentence.
- Place the citation marker before the period when it cites only the final clause of a compound sentence.
- Multiple citations on the same claim use adjacent brackets: `[1][3]`.
- Do not cite common knowledge or definitions obvious from context.
- Maximum 5 unique citations per answer. If more than 5 sources are relevant, select the 3-5 most authoritative and relevant.

### Citation Block

Append a citation block at the end of every answer:

```
---
Sources:
[1] "Document Title" - https://docs.google.com/document/d/...
[2] "Spreadsheet Title > Tab Name" - https://docs.google.com/spreadsheets/d/...
[3] "Document Title > Section Heading" - https://drive.google.com/file/d/...
```

For Google Sheets, include the tab name after the spreadsheet title. For long documents where a specific section was cited, include the section heading after the document title.

## Confidence Assessment

Assign one of three confidence levels to every Q&A answer. Display the level prominently at the top of the answer output.

### High Confidence

Assign when ALL of the following are true:
- Two or more sources agree on the core answer.
- At least one source contains a strong keyword or phrase match to the question.
- The primary source was modified within the last 90 days.
- No conflicting information exists across sources.

### Medium Confidence

Assign when ANY of the following are true:
- Only one source directly addresses the question, but it is a strong match.
- Multiple sources provide partial but non-contradictory coverage.
- Sources agree but the most relevant source is older than 90 days.
- A minor conflict exists between sources but the newer source is clearly authoritative.

### Low Confidence

Assign when ANY of the following are true:
- Only weak keyword matches exist across all sources.
- Sources contain contradictory information with no clear resolution.
- All relevant sources are older than 180 days.
- The answer required significant inference beyond what the sources explicitly state.

When confidence is Low, prepend a warning: "Low confidence -- this answer is based on limited or potentially outdated sources. Verify before acting on it."

For detailed scoring criteria with worked examples, see `${CLAUDE_PLUGIN_ROOT}/skills/drive/document-qa/references/citation-formats.md`.

## Summary Generation (Summarization Mode)

Generate structured summaries when operating in summarization mode (`/founder-os:drive:summarize`). Support two depth levels.

### Quick Depth (Default)

Produce a concise summary consisting of:
- **Executive summary**: 2-3 sentences capturing the document's purpose and key conclusion or finding.
- **Key points**: 3-7 bulleted items highlighting the most important facts, decisions, or data points.

For Sheets: replace "Key points" with **Data highlights** -- surface the key metrics, totals, outliers, or trends visible in the data. Include specific numbers.

### Detailed Depth (--depth=detailed)

Produce a full section-by-section analysis:
- **Executive summary**: 2-3 sentences (same as quick).
- **Section breakdown**: For each major section or heading in the document, provide a 1-3 sentence summary. Preserve the document's organizational structure.
- **Key data and figures**: Extract specific numbers, dates, percentages, or quoted statements that carry significance.
- **Notable items**: Flag anything that appears incomplete, contradictory, or marked as draft/pending.

For Sheets with multiple tabs: summarize each tab as a separate section under its tab name.

### Summary Output

When the `--output` flag is provided, write the summary to a local file using the template at `${CLAUDE_PLUGIN_ROOT}/templates/summary-template.md`. When no `--output` flag is provided, deliver the summary directly in chat.

All summaries include a metadata header: document title, Drive URL, last modified date, and file type.

## No-Answer Pathway

Activate when the assessment phase determines that extracted content is insufficient to answer the question. Never fabricate an answer from general knowledge when Drive documents lack coverage.

### Response Structure

1. **Acknowledge the gap**: "Could not find a definitive answer to this in the searched Drive documents." Do not say "I don't know" -- the relevant document may simply not have been in the search results or may not exist.
2. **Show what was found**: If any partially relevant documents were retrieved, list them: "Here are the closest documents found that may be related:" followed by 1-3 document titles with brief descriptions of what they cover.
3. **Suggest alternative terms**: Propose 2-3 rephrased queries to try: "Try searching for: [alternative term 1], [alternative term 2], [alternative term 3]." Base suggestions on synonyms, broader terms, or related concepts.
4. **Offer next steps**: "Try `/founder-os:drive:search` with different keywords, or specify a folder with `--in` to narrow the search."

### Triggering Criteria

Activate the no-answer pathway when:
- Zero sources survive the relevance filter.
- All surviving sources are tangential and none directly addresses the question.
- The only relevant sources are contradictory with no clear resolution and no recent authoritative source.

## Multi-Source Conflict Reconciliation

When two or more sources provide different answers to the same question, reconcile rather than ignore the conflict.

### Decision Rules (apply in order)

1. **Date precedence**: Prefer the more recently modified source when the conflict is factual (a number, a policy, a procedure). State: "As of [date], [newer information] [citation]. Note: an earlier document stated [older information] [citation]."
2. **Specificity precedence**: Prefer the more specific source. A document titled "Q3 Marketing Budget" overrides a general "Annual Budget Overview" on the topic of Q3 marketing spend.
3. **Authority precedence**: Prefer shared/published documents over personal drafts, official templates over ad-hoc notes, and documents with broader sharing permissions over restricted ones.
4. **Transparent disagreement**: When no precedence rule resolves the conflict, present both versions explicitly: "Document A states [X] [1], while Document B states [Y] [2]. The discrepancy may reflect an update not yet propagated or an error. Verify with the document owner."

Never silently choose one source over another when a conflict exists. Always disclose the conflict, even when a precedence rule resolves it.

## Output Structure

### Q&A Mode

```
**Confidence:** [High | Medium | Low]

[Answer text with inline citations]

---
Sources:
[1] "Source Title" - Drive URL
[2] "Source Title > Section" - Drive URL

[Optional: staleness warning]
[Optional: partial coverage note]
```

### Summarization Mode

```
**Summary of "[Document Title]"**
**Source:** [Drive URL]
**Last Modified:** [date]
**Type:** [Google Doc | Google Sheet | PDF | ...]

[Executive summary]

**Key Points:**
- [point 1]
- [point 2]
- [point 3]

[Optional: Section breakdown for detailed depth]
```

## Company Detection for Activity Logging

When logging activity to the [FOS] Activity Log Notion database, populate the **Company** relation if the source document's file path or filename matches a known client from [FOS] Companies. Populate Company relation when the Drive file belongs to a known client folder or filename contains a client name. Use the detection rules defined in the drive-navigation skill.

## Edge Cases

### Single-Source Answer
When only one source is relevant, cite it and assign Medium confidence at best (never High for single-source answers unless the source is an official shared document updated within the last 30 days).

### Spreadsheet with No Headers
When a Google Sheet lacks a clear header row, treat the first row as data rather than headers. Note in the answer: "Spreadsheet lacks headers; column references use column letters (A, B, C)."

### Very Large Spreadsheets
When a spreadsheet exceeds the 3000-character extraction cap, prioritize the tab or range most relevant to the query. Cite the specific tab name in the citation block.

### Ambiguous Question
When the question is too vague to match document content effectively, ask for clarification: "Could you be more specific? For example: [2-3 concrete question suggestions based on the document titles in scope]."

### Deleted or Inaccessible Files
When a file referenced in search results is no longer accessible, note it in the citation: `[1] "Document Title" - [file deleted or inaccessible]`. Do not count inaccessible files toward confidence scoring.

## Graceful Degradation

- **Google Drive unavailable**: Cannot extract content. Report: "Google Drive is not connected -- ensure the gws CLI is available and authenticated." Do not attempt to answer from training data.
- **File extraction fails**: Skip the failed file and proceed with remaining sources. Note: "Could not extract content from [filename]. Results are based on [N] other documents."
- **No sources retrieved**: Activate the no-answer pathway. Do not generate answers from training data.
- **drive-navigation skill unavailable**: Cannot discover files. Report: "File search is unavailable. Provide a direct file URL or ensure the drive-navigation skill is configured."
