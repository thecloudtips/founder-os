---
name: Answer Synthesis
description: "Synthesizes sourced answers with inline citations from retrieved knowledge base documents. Activates when the user asks a question that should be answered from docs, wants cited answers, or asks 'what does our knowledge base say about [topic]?' Handles multi-source reconciliation, confidence rating, and graceful no-answer pathways."
---

## Overview

Take retrieved source documents from the knowledge-retrieval skill and synthesize a sourced answer with inline citations, confidence assessment, and structured formatting. Accept a set of retrieved sources (each containing title, content snippet, URL or Notion page ID, relevance score, and last-updated date) and the original user question. Assess source quality, construct an answer that reconciles multiple sources, attach numbered inline citations, and output a confidence rating. When sources are insufficient, activate the no-answer pathway to suggest alternatives rather than guessing.

This skill handles answer construction, citation formatting, confidence assessment, and conflict reconciliation only. Source retrieval, indexing, and search are the responsibility of the knowledge-retrieval skill. The command layer (`/founder-os:kb:ask`) orchestrates the handoff between retrieval and synthesis.

## Answer Construction Pipeline

Process every question through three sequential phases. Do not skip phases or reorder them.

### Phase 1: Assess

Evaluate the retrieved sources before attempting to construct an answer.

1. **Relevance check**: For each retrieved source, verify that it actually addresses the user's question. A source about "onboarding workflow" is not relevant to a question about "billing invoices" even if both appear in the same database. Discard sources with relevance scores below 0.3.
2. **Sufficiency check**: Count the remaining sources after relevance filtering. Determine whether the surviving sources contain enough information to answer the question. A single source with a direct answer is sufficient. Multiple tangential sources that do not address the core question are not.
3. **Freshness check**: Flag sources older than 90 days as potentially stale. Do not discard them -- stale sources may still contain valid information -- but factor staleness into the confidence assessment in Phase 3.
4. **Coverage check**: Identify which parts of the question each source addresses. For multi-part questions ("What is our refund policy and how do I request one?"), map sources to question components. Note any components with zero source coverage.
5. **Route decision**: Based on the assessment, route to one of two paths:
   - **Answer path**: At least one source directly addresses the question with relevant content. Proceed to Phase 2.
   - **No-answer path**: No source adequately addresses the question. Skip Phase 2 and activate the no-answer pathway (see No-Answer Pathway section below).

### Phase 2: Synthesize

Construct the answer from assessed sources.

1. **Identify the primary source**: Select the source with the highest relevance score that most directly answers the question. This source anchors the answer.
2. **Extract key facts**: Pull specific facts, procedures, definitions, or policies from each relevant source. Do not paraphrase loosely -- preserve the precision of the original content.
3. **Reconcile conflicts**: When two or more sources provide contradictory information, apply the conflict reconciliation rules (see Multi-Source Conflict Reconciliation below). Do not silently pick one version.
4. **Compose the answer**: Write a clear, direct response to the question. Lead with the answer, not with background context. Structure the response as:
   - **Direct answer** (1-3 sentences): Answer the question immediately.
   - **Supporting detail** (1-5 sentences): Provide context, caveats, or additional relevant information from the sources.
   - **Related information** (0-3 sentences, optional): Include only if the sources contain closely related information the user likely needs.
5. **Attach citations**: Insert inline citation markers as the answer is composed. Every factual claim, procedure step, or policy statement must have at least one citation. See Citation System below.

### Phase 3: Format

Structure the final output for delivery.

1. **Confidence indicator**: Assess and attach a confidence level (High, Medium, or Low) based on the criteria in Confidence Assessment below.
2. **Citation block**: Append the numbered citation block at the bottom of the answer with source titles and URLs.
3. **Preview line**: Generate a one-sentence preview (max 120 characters) that summarizes the answer. The preview is used for Notion logging and command output headers.
4. **Staleness warning**: If any cited source is older than 90 days, append a note: "Some sources may be outdated. Verify critical details against current documentation."
5. **Partial coverage note**: If the assessment in Phase 1 identified question components with zero source coverage, append: "This answer covers [covered components]. No documentation was found for [uncovered components]."

## Citation System

Use numbered inline references and a citation block. Every answer must include at least one citation. See `${CLAUDE_PLUGIN_ROOT}/skills/kb/answer-synthesis/references/citation-formats.md` for full format specification, examples, and edge cases.

### Inline Citations

Insert bracketed numbers after the sentence or clause they support:

```
The default retention period is 30 days [1]. After that, archived items
are permanently deleted unless a hold has been placed [2].
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
[1] "Page or Document Title" - URL or Notion link
[2] "Page or Document Title" - URL or Notion link
[3] "Page or Document Title" - URL or Notion link
```

Include the source's title and its URL (for Google Drive documents) or Notion page link (for Notion pages). When a source has no URL (e.g., inline Notion database content), use the page title and database name: `[1] "Entry Title" - Notion DB: Database Name`.

## Confidence Assessment

Assign one of three confidence levels to every answer. Display the level prominently at the top of the answer output.

### High Confidence

Assign when ALL of the following are true:
- Two or more sources agree on the core answer.
- At least one source contains a strong keyword or phrase match to the question.
- The primary source was updated within the last 90 days.
- No conflicting information exists across sources.

### Medium Confidence

Assign when ANY of the following are true:
- Only one source directly addresses the question, but it is a strong match.
- Multiple sources provide partial but non-contradictory coverage.
- Sources agree but the most relevant source is older than 90 days.
- A minor conflict exists between sources but the newer source is clearly authoritative.

### Low Confidence

Assign when ANY of the following are true:
- Only weak keyword matches exist across all sources (relevance scores below 0.5).
- Sources contain contradictory information with no clear resolution.
- All relevant sources are older than 180 days.
- The answer required significant inference beyond what the sources explicitly state.

When confidence is Low, prepend a warning: "Low confidence -- this answer is based on limited or potentially outdated sources. Verify before acting on it."

For detailed scoring criteria with worked examples, see `${CLAUDE_PLUGIN_ROOT}/skills/kb/answer-synthesis/references/citation-formats.md`.

## No-Answer Pathway

Activate when the assessment phase determines that retrieved sources are insufficient to answer the question. Never fabricate an answer from general knowledge when the knowledge base lacks coverage.

### Response Structure

1. **Acknowledge the gap**: "I could not find a definitive answer to this in the knowledge base." Do not say "I don't know" -- the knowledge base may simply lack documentation on the topic.
2. **Show what was found**: If any partially relevant sources were retrieved, list them: "Here are the closest documents I found that may be related:" followed by 1-3 source titles with brief descriptions of what they cover.
3. **Suggest alternative terms**: Propose 2-3 rephrased queries the user could try: "Try searching for: [alternative term 1], [alternative term 2], [alternative term 3]." Base suggestions on synonyms, broader terms, or related concepts.
4. **Offer next steps**: "Would you like me to search again with different keywords, or would you like to browse [related topic area]?"

### Triggering Criteria

Activate the no-answer pathway when:
- Zero sources survive the relevance filter (all below 0.3).
- All surviving sources are tangential (relevance below 0.5) and none directly addresses the question.
- The only relevant sources are contradictory with no clear resolution and no recent authoritative source.

## Multi-Source Conflict Reconciliation

When two or more sources provide different answers to the same question, reconcile rather than ignoring the conflict.

### Decision Rules (apply in order)

1. **Date precedence**: Prefer the more recently updated source when the conflict is factual (a number, a policy, a procedure). State: "As of [date], [newer information] [citation]. Note: an earlier document stated [older information] [citation]."
2. **Specificity precedence**: Prefer the more specific source. A page titled "Refund Policy for Enterprise Plans" overrides a general "Policies Overview" page on the topic of enterprise refunds.
3. **Authority precedence**: Prefer official policy pages over meeting notes, announcements over draft documents, and published documentation over internal comments.
4. **Transparent disagreement**: When no precedence rule resolves the conflict, present both versions explicitly: "Source A states [X] [1], while Source B states [Y] [2]. The discrepancy may reflect a policy change or an error in one of the documents. Verify with the document owner."

### Conflict Disclosure

Never silently choose one source over another when a conflict exists. Always disclose the conflict to the user, even when a precedence rule resolves it. Transparency builds trust in the system.

## Output Structure

Deliver the synthesized answer in this format:

```
**Confidence:** [High | Medium | Low]

[Answer text with inline citations]

---
Sources:
[1] "Source Title" - URL or Notion link
[2] "Source Title" - URL or Notion link

[Optional: staleness warning]
[Optional: partial coverage note]
```

For the preview line (used by the command layer for logging), generate a single sentence of no more than 120 characters that captures the core answer. Do not include citations in the preview.

## Edge Cases

### Single-Source Answer
When only one source is relevant, cite it and assign Medium confidence at best (never High for single-source answers unless the source is an official policy page updated within the last 30 days).

### Question Beyond Knowledge Base Scope
When the question is clearly outside the knowledge base domain (e.g., asking about weather when the KB covers internal company docs), state: "This question appears to be outside the scope of the knowledge base, which covers [brief KB scope description]. Try rephrasing if you believe relevant documentation exists."

### Ambiguous Question
When the question is too vague to match sources effectively (e.g., "How does it work?"), ask for clarification: "Could you be more specific? For example: [2-3 concrete question suggestions based on the knowledge base content areas]."

### Very Long Source Content
When a source document is very long, cite the specific section or heading within the document rather than the entire page. Use the format: `[1] "Document Title > Section Heading" - URL`.

## Graceful Degradation

- **Notion unavailable**: Cannot retrieve sources. Report: "Knowledge base search is unavailable -- Notion MCP server is not connected." Do not attempt to answer from memory.
- **Google Drive unavailable** (gws CLI not installed or not authenticated): Proceed with Notion-only sources. Note: "Google Drive sources were not searched. Results are from Notion only."
- **No sources retrieved**: Activate the no-answer pathway. Do not generate answers from training data.
- **knowledge-retrieval skill unavailable**: Cannot proceed. Report: "Source retrieval is unavailable. Ensure the knowledge-retrieval skill is configured."
