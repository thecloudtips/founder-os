---
description: Answer questions from Google Drive documents with citations
argument-hint: "[question] [--in=FOLDER] [--limit=N]"
allowed-tools: ["Read"]
---

# Drive Ask

Search Google Drive for relevant documents, extract content, and synthesize a sourced answer with inline citations and confidence assessment. Combines drive-navigation (search) and document-qa (answer synthesis) skills.

## Load Skills

Read the drive-navigation skill at `${CLAUDE_PLUGIN_ROOT}/skills/drive-navigation/SKILL.md` for search pipeline, query formulation, relevance scoring, and content extraction.

Read the document-qa skill at `${CLAUDE_PLUGIN_ROOT}/skills/document-qa/SKILL.md` for answer synthesis, citation system, confidence assessment, and no-answer pathway.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `[question]` (required) -- natural-language question. All non-flag text. If missing, prompt: "What would you like to know? Ask a question and I'll search Google Drive for the answer."
- `--in=FOLDER` (optional) -- scope search to specific Drive folder. Resolve folder by name using the drive-navigation skill's folder traversal logic. If the value contains spaces, it must be quoted (e.g., `--in="Client Projects"`).
- `--limit=N` (optional) -- max source documents for answer synthesis. Default: 5. Clamp to 1-5 silently (0 or negative becomes 1, >5 becomes 5).

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Step 1: Search Drive

Apply the drive-navigation skill's search pipeline:

1. Formulate 2-3 query variants from the question (literal, synonym, broadened) using the query formulation rules.
2. Search Google Drive via gws CLI (`gws drive files list`) with each variant. Display progress: "Searching Google Drive..."
3. If `--in` is specified, resolve the folder name to a folder ID and scope the search to that folder and its subfolders.
4. Filter to supported file types (Google Docs, Google Sheets, PDFs, plain text, Markdown).
5. Deduplicate results across query variants by file ID.
6. Score each unique result using 3-factor relevance scoring: Keyword Density (0-40), Title Match (0-30), Recency (0-30). Composite score: 0-100.
7. Rank by composite score descending. Take the top `--limit` results.

Track for logging and output:
- `total_results`: count of all unique results before limiting.
- `top_score`: highest composite score among results.
- `query_variants`: list of 2-3 variants used.

## Step 2: Extract Content

For each top result:

1. Read file content via gws CLI (Drive).
2. Cap extraction at 3000 characters per document.
3. For long documents, use heading-based section extraction -- scan heading structure, select sections containing query keywords, extract those sections plus surrounding context up to the 3000-character cap. When no heading match exists, extract from the beginning.
4. For Google Sheets: extract header row plus relevant data rows as a markdown pipe table. Include tab name as a section heading for multi-tab sheets.
5. Tag each extracted result with source metadata: `[Source: {title} | Google Drive | Last modified: {date}]`
6. For scanned PDFs that yield no text, note `scanned: true` and skip content extraction for that file.

## Step 3: Synthesize Answer

Apply the document-qa skill's 3-phase pipeline:

### Phase 1: Assess

1. **Relevance check**: Discard sources with composite relevance scores below 30.
2. **Sufficiency check**: Determine if surviving sources contain enough information to answer the question. A single source with a direct answer is sufficient. Multiple tangential sources that do not address the core question are not.
3. **Freshness check**: Flag sources with last-modified date older than 90 days as potentially stale. Do not discard them -- factor staleness into confidence assessment in Phase 3.
4. **Coverage check**: For multi-part questions, map sources to question components. Note any components with zero source coverage.
5. **Route decision**:
   - **Answer path**: At least one source directly addresses the question. Continue to Phase 2.
   - **No-answer path**: No source adequately addresses the question. Skip Phase 2 and activate the no-answer pathway.

### Phase 2: Synthesize (answer path)

1. **Identify the primary source**: Select the document with the highest relevance score and most direct answer. This source anchors the answer.
2. **Extract key facts**: Pull specific facts, figures, procedures, definitions, or policies from each relevant source. Preserve the precision of the original content -- do not paraphrase loosely.
3. **Reconcile conflicts**: When sources provide contradictory information, apply the document-qa skill's conflict reconciliation rules in order: date precedence, specificity precedence, authority precedence, transparent disagreement. Never silently pick one version.
4. **Compose the answer**:
   - **Direct answer** (1-3 sentences): Answer the question immediately.
   - **Supporting detail** (1-5 sentences): Provide context, caveats, or additional relevant information.
   - **Related information** (0-3 sentences, optional): Include only if sources contain closely related information the user likely needs.
5. **Attach inline citations**: Insert `[1]`, `[2]`, etc. after every factual claim. Maximum 5 unique citations per answer.

### Phase 3: Format

1. **Confidence level**: Assign High, Medium, or Low per the document-qa skill's criteria. When confidence is Low, prepend: "Low confidence -- this answer is based on limited or potentially outdated sources. Verify before acting on it."
2. **Citation block**: Build the numbered citation block with source titles and Drive URLs. For Sheets, include tab name. For long documents, include section heading after the title.
3. **Preview line**: Generate a one-sentence preview (max 120 characters) summarizing the answer for Notion logging.
4. **Staleness warning**: If any cited source was last modified more than 90 days ago, append: "Some sources may be outdated. Verify critical details."
5. **Partial coverage note**: If the assessment in Phase 1 identified question components with zero source coverage, append: "This answer covers [covered components]. No documents were found for [uncovered components]."

## Step 4: Notion Logging (Optional)

Log the query to Notion for tracking. This step must never block user-facing output.

1. **Check for database**: Search Notion for a database titled "[FOS] Activity Log". If not found, try "Founder OS HQ - Activity Log". If not found, fall back to "Google Drive Brain - Activity".
2. If neither is found, skip Notion logging silently and proceed with user-facing output. Do not create the database. If found, log with these properties:
   - Query (title) -- the user's original question
   - Command Type (select: search, summarize, ask, organize) -- set to "ask" for this command
   - Files Found (number) -- `total_results`
   - Top Result (rich_text) -- title of the primary source document
   - File IDs (rich_text) -- comma-separated Drive file IDs of processed files
   - Folder Context (rich_text) -- folder scope if `--in` was used, empty otherwise
   - Sources Used (multi_select: Google Drive, Notion) -- set to "Google Drive"
   - Company (relation) -- if the primary source file's path or name matches a known client from [FOS] Companies, set the Company relation to that record. See drive-navigation skill's Company Detection rules.
   - Generated At (date) -- current timestamp
3. **Idempotent check**: Search for an existing entry where Query matches the user's question (case-insensitive) AND Generated At is the same calendar day. Update if found, create if not.
4. **Continue on failure**: If Notion logging fails for any reason (MCP unavailable, permissions, rate limit, connectivity), continue silently. Do not mention Notion in the output.

## Step 5: Output

### When answer found:

```
## Drive Answer

**Confidence:** [High | Medium | Low]

[Answer text with inline [1] citations]

---
Sources:
[1] "Source Title" - Drive URL
[2] "Source Title" - Drive URL

[Optional: "Some sources may be outdated. Verify critical details."]
[Optional: "This answer covers [X]. No documents were found for [Y]."]

---
*Searched [N] files in Google Drive · [total_results] results found · Top relevance: [top_score]/100*
```

### When no answer found (no-answer pathway):

```
## Drive Answer

I could not find a definitive answer to this in Google Drive.

**Closest documents found:**
- "[Title]" - [what it covers] ([Drive URL])

**Try searching for:**
- [alternative term 1]
- [alternative term 2]

Would you like me to search again with different keywords, or try `/drive:search` to browse results?

---
*Searched [N] files in Google Drive · Top relevance: [top_score]/100*
```

## Graceful Degradation

**Google gws CLI (Drive) unavailable**: Stop execution immediately. Display:
"gws CLI (`gws drive`) is not connected. Install it per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`:
1. Set `GOOGLE_CREDENTIALS_PATH` and `GOOGLE_TOKEN_PATH` environment variables
2. Restart Claude Code and run `/drive:ask` again"

**Folder not found** (when `--in` is specified): Do not stop. Display a warning and fall back to searching all of Drive:
"Folder '[name]' not found. Searching all of Drive."
Then execute the search without folder scope.

**No results found**: Activate the no-answer pathway from the document-qa skill. Suggest alternative search terms based on synonym variants.

**File extraction fails**: Skip the failed file and proceed with remaining sources. Note in output: "Could not extract content from [filename]. Results are based on [N] other documents."

**Notion MCP unavailable**: Skip activity logging silently. Do not mention Notion in the output.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/drive:ask What is our refund policy?
/drive:ask How much did we budget for Q2 marketing? --in="Finance"
/drive:ask What were the key decisions from the Phoenix kickoff? --limit=3
/drive:ask What are the payment terms in the Acme contract?
```
