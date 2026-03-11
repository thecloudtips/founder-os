---
description: Search the knowledge base and answer a question with sourced citations and confidence rating
argument-hint: "[question] [--sources=notion|drive|all] [--limit=N]"
allowed-tools: ["Read"]
---

# Knowledge Base Q&A

Search Notion pages/databases and Google Drive documents to answer the user's question. Score results for relevance, synthesize a cited answer, assess confidence, and log the query to Notion.

## Load Skills

Read the knowledge-retrieval skill at `${CLAUDE_PLUGIN_ROOT}/skills/kb/knowledge-retrieval/SKILL.md` for multi-source search across Notion and Google Drive, query formulation, relevance scoring, content extraction, and preview generation.

Read the answer-synthesis skill at `${CLAUDE_PLUGIN_ROOT}/skills/kb/answer-synthesis/SKILL.md` for source assessment, answer construction with inline citations, confidence rating, conflict reconciliation, and the no-answer pathway.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `[question]` (required) -- the user's natural-language question. This is all non-flag text in the arguments. If no question text is present, prompt the user: "What would you like to search the knowledge base for?" Wait for a response before proceeding.
- `--sources=notion|drive|all` (optional) -- which sources to search. Default: `all`.
  - `notion` -- search Notion only, skip Google Drive even if available.
  - `drive` -- search Google Drive only, skip Notion. **Note:** if Notion MCP is unavailable in this mode, stop with the Notion-required error (Notion is always required for logging even in drive-only search mode). If the gws CLI is unavailable, stop with a message: "gws CLI is not available or not authenticated. Use `--sources=notion` or `--sources=all` to search Notion instead."
  - `all` -- search both Notion and Google Drive. Drive is optional; Notion is required.
- `--limit=N` (optional) -- maximum number of source results to use for answer synthesis. Accepts 1-5. Default: `5`. Values outside 1-5 are clamped silently (0 or negative becomes 1, >5 becomes 5).

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Step 1: Search Knowledge Sources

Apply the knowledge-retrieval skill:

1. **Formulate queries**: Generate 2-3 query variants from the user's question using the literal, synonym, and broadened variant rules.
2. **Search Notion**: Execute `notion-search` with each query variant. Collect all returned pages and database entries. Display progress: "Searching Notion..."
3. **Search Google Drive** (when `--sources` is `all` or `drive` AND gws CLI is available): Use Bash to run `gws drive files list --params '{"q":"fullText contains '\''[query]'\''","pageSize":20,"fields":"files(id,name,mimeType,modifiedTime,webViewLink)"}' --format json` with each query variant. Filter to supported file types (Google Docs, Sheets, PDF, plain text, Markdown). Display progress: "Searching Google Drive..."
4. **Skip Drive silently** when `--sources=notion` or when gws CLI is unavailable and `--sources=all`. Set `drive_status: "unavailable"` internally. Check availability with `which gws`.
5. **Deduplicate**: Remove results that appear in both Notion and Drive (match by title similarity).

## Step 2: Score and Rank

Apply relevance scoring from the knowledge-retrieval skill:

1. Score each unique result on three factors: Keyword Density (0-40), Title Match (0-30), Recency (0-30). Composite score: 0-100.
2. Rank results by composite score descending.
3. Take the top `--limit` results (default 5). These are the sources passed to answer synthesis.
4. If zero results survive after search across all sources, proceed to Step 3 -- the answer-synthesis skill's no-answer pathway will handle it.

Track for logging:
- `total_results`: count of all unique results before limiting.
- `top_score`: the highest composite score among results.
- `sources_searched`: list of sources actually queried (e.g., `["notion"]` or `["notion", "drive"]`).

## Step 3: Synthesize Answer

Apply the answer-synthesis skill's three-phase pipeline:

### Phase 1: Assess

1. Run the relevance check -- discard sources with relevance scores below 0.3 (scaled: below 30 on the 0-100 scale).
2. Run the sufficiency check -- determine if surviving sources contain enough information to answer.
3. Run the freshness check -- flag sources older than 90 days as potentially stale.
4. Run the coverage check -- for multi-part questions, map sources to question components.
5. Route decision:
   - **Answer path**: At least one source directly addresses the question. Continue to Phase 2.
   - **No-answer path**: No source adequately addresses the question. Skip Phase 2 and activate the no-answer pathway.

### Phase 2: Synthesize

1. Identify the primary source (highest relevance score, most direct answer).
2. Extract key facts from each relevant source. Preserve precision -- do not paraphrase loosely.
3. Reconcile conflicts using the skill's decision rules (date precedence, specificity precedence, authority precedence, transparent disagreement).
4. Compose the answer: direct answer (1-3 sentences) + supporting detail (1-5 sentences) + related information (0-3 sentences, optional).
5. Attach inline citations to every factual claim. Maximum 5 unique citations per answer.

### Phase 3: Format

1. Assign confidence level: High, Medium, or Low per the skill's criteria.
2. Build the citation block with source titles and URLs.
3. Generate a one-sentence preview (max 120 characters) for Notion logging.
4. Append staleness warning if any cited source is older than 90 days.
5. Append partial coverage note if any question components lack source coverage.

## Step 4: Notion Logging

Log the query and answer to Notion for tracking and analytics.

1. **Discover database** (try consolidated name first, then fall back to legacy):
   a. Search Notion for a database named "[FOS] Knowledge Base". If found, use it.
   b. If not found, try "Founder OS HQ - Knowledge Base". If found, use it.
   c. If not found, search for "Knowledge Base Q&A - Queries". If found, use it.
   d. If none is found, skip Notion logging entirely (do NOT create the database). Append a note: "Note: No Knowledge Base database found in Notion. Query not logged."
2. **Set Type property**: When writing to the consolidated "[FOS] Knowledge Base" or "Founder OS HQ - Knowledge Base" database, always set the **Type** property to `"Query"` to distinguish query records from source index records.
3. **Record properties**:
   - Query (title) -- the user's original question
   - Type (select) -- "Query" (set when using consolidated DB)
   - Answered (checkbox) -- true if an answer was synthesized, false if no-answer pathway
   - Confidence (select: High, Medium, Low, None) -- confidence level of the answer, "None" for no-answer
   - Sources Used (number) -- count of sources cited in the answer
   - Source Names (rich_text) -- comma-separated titles of cited sources
   - Sources Searched (rich_text) -- comma-separated list of sources queried (e.g., "notion, drive")
   - Top Score (number) -- highest relevance score among results (0-100)
   - Answer Excerpt (rich_text) -- the 120-character preview line from Phase 3
   - Asked At (date) -- timestamp of the query
4. **Idempotent check**: Search for an existing record where Query matches the user's question (case-insensitive) AND Asked At is the same calendar day. Update if found, create if not.
5. **Save**: Write the query record to the Notion database.
6. **Continue on failure**: If Notion logging fails for any reason (permissions, rate limit, connectivity), continue with the chat output and append a note: "Note: Query logging to Notion failed. The answer above is still valid."

## Step 5: Output

Display the formatted answer to the user.

### When answer was found:

```
## Knowledge Base Answer

**Confidence:** [High | Medium | Low]

[Answer text with inline [1] citations]

---
Sources:
[1] "Source Title" - URL or Notion link
[2] "Source Title" - URL or Notion link

[Optional: "Some sources may be outdated. Verify critical details against current documentation."]
[Optional: "This answer covers [covered]. No documentation was found for [uncovered]."]

---
*Searched [N] sources across [source list] · [total_results] results found · Top relevance: [top_score]/100 · [Notion link if logged]*
```

### When no answer was found (no-answer pathway):

```
## Knowledge Base Answer

I could not find a definitive answer to this in the knowledge base.

[If partially relevant sources exist:]
**Closest documents found:**
- "[Source Title]" - [brief description of what it covers] ([URL])

**Try searching for:**
- [alternative term 1]
- [alternative term 2]
- [alternative term 3]

Would you like me to search again with different keywords?

---
*Searched [N] sources across [source list] · [total_results] results found · Top relevance: [top_score]/100*
```

## Graceful Degradation

**Notion MCP unavailable**: Stop execution. Display:
"Notion MCP server is not connected. Knowledge Base Q&A requires Notion as its primary source and for query logging.
Install it per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`:
1. Set your `NOTION_API_KEY` environment variable
2. Ensure the Notion integration has access to your knowledge base pages"

**gws CLI unavailable or not authenticated** (and `--sources=all`): Continue with Notion only. Do not mention Drive absence unless zero results are found -- then append: "Google Drive was not searched. Install the gws CLI and run `gws auth login` for broader coverage."

**gws CLI unavailable or not authenticated** (and `--sources=drive`): Stop execution. Display:
"gws CLI is not available or not authenticated. Use `--sources=notion` or `--sources=all` to search Notion instead.
To configure Google Drive access, install the gws CLI and run `gws auth login`. See `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`."

**No results found across all sources**: Activate the no-answer pathway from the answer-synthesis skill. Suggest connecting additional sources if only Notion was searched.

**Notion DB logging fails**: Continue with chat output. Append: "Note: Query logging to Notion failed. The answer above is still valid."

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/founder-os:kb:ask What is our refund policy?
/founder-os:kb:ask How do I set up a new client project? --sources=notion
/founder-os:kb:ask Where is the brand guidelines document? --sources=drive
/founder-os:kb:ask What are the steps for employee onboarding? --limit=3
/founder-os:kb:ask What is the SLA for enterprise clients? --sources=all --limit=2
```
