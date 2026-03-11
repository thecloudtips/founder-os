# Integration Test Plan: Newsletter Draft Engine

## Overview

This test plan validates the P08 Newsletter Draft Engine plugin against all acceptance criteria. Tests cover all four commands (`/newsletter:research`, `/newsletter:outline`, `/newsletter:draft`, `/newsletter`), all three skills (topic-research, newsletter-writing, founder-voice), the newsletter template scaffold, Notion integration, Google Drive integration (via gws CLI), file output, and edge cases.

## Prerequisites

- Plugin installed in Claude Code
- WebSearch tool available (built-in, no MCP required)
- Filesystem MCP configured with a valid `ALLOWED_PATH` (for file save tests)
- Notion MCP configured with valid API key (for Notion integration tests)
- gws CLI installed and authenticated via `gws auth login` (for Drive-related tests)

---

## TC-01: Research Produces Structured Findings with Correct Schema

**Priority**: P0
**Command**: `/newsletter:research "Claude MCP plugins"`
**Prerequisites**: WebSearch tool available
**Steps**:
1. Run `/newsletter:research "Claude MCP plugins"`
2. Wait for the research phase to complete
3. Inspect the output for the structured findings table

**Expected Result**:
- Output contains a "Newsletter Research: Claude MCP plugins" header
- Date range, sources searched, and total findings are displayed
- "Findings by Source Type" table shows counts per type
- "Top Findings" table includes columns: #, Score, Title, Source, Type, Date
- Each finding row has:
  - **title**: Non-empty string
  - **source**: Publication or site name
  - **url**: A valid URL rendered as a markdown link on the title
  - **summary**: Present (visible in the finding detail or source context)
  - **date**: A date string or "Unknown"
  - **source_type**: One of `official-release`, `blog-post`, `github-repo`, `community-discussion`, `tutorial`
  - **relevance_score** and **recency_score** combined into a **combined_score** (0.0-1.0) shown in the Score column
- Findings are sorted by combined_score descending
- 3-5 key themes are listed below the findings

**Pass Criteria**: All schema fields present in output; score column populated for every finding; findings sorted descending by score.

---

## TC-02: Multi-Source Queries with site: Prefixes

**Priority**: P0
**Command**: `/newsletter:research "AI code generation"`
**Prerequisites**: WebSearch tool available
**Steps**:
1. Run `/newsletter:research "AI code generation"`
2. Observe the queries formulated during research (visible in tool call output or research summary)
3. Verify the "Sources searched" line in the output

**Expected Result**:
- At least 5 search queries are executed
- At least one query contains `site:github.com`
- At least one query contains `site:reddit.com`
- At least one query contains `site:quora.com`
- At least one general web query (no site: prefix) is included
- At least one query targets official blogs, changelogs, or release notes
- The "Sources searched" line includes web, github, reddit, quora

**Pass Criteria**: All four source types (web, github, reddit, quora) represented in queries; site: prefixes used correctly for github, reddit, and quora queries.

---

## TC-03: Outline Creates Valid Structure from Research

**Priority**: P0
**Command**: `/newsletter:outline`
**Prerequisites**: Run TC-01 or TC-02 first in the same conversation so research findings exist in context
**Steps**:
1. Ensure research findings are present in the conversation from a prior `/newsletter:research` run
2. Run `/newsletter:outline`
3. Inspect the outline output

**Expected Result**:
- Output contains "Newsletter Outline" header
- **Topic** matches the research topic
- **Hook type** is one of: `stat-led`, `contrarian`, `story-led`, `question`
- **Sections** count is 4 (default)
- **Target length** is specified per the newsletter-writing skill
- Hook section has 2-3 sentences describing the hook angle
- Exactly 4 section blocks, each with:
  - A clear, engaging title
  - 2-3 key points with source references in parentheses
  - An "Angle:" note describing the presentation approach
- Key Takeaways section with 3-5 actionable bullets
- CTA Direction section describing the reader engagement goal
- Footer suggests running `/newsletter:draft`

**Pass Criteria**: All outline structural elements present; section count matches default (4); hook type is from the valid set; each section has source references.

---

## TC-04: Draft Writes Complete Substack-Compatible Newsletter

**Priority**: P0
**Command**: `/newsletter:draft`
**Prerequisites**: Run TC-03 first in the same conversation so an outline exists in context. Filesystem MCP configured.
**Steps**:
1. Ensure an outline is present in the conversation from a prior `/newsletter:outline` run
2. Run `/newsletter:draft`
3. Inspect the full newsletter draft displayed in chat
4. Verify the saved file

**Expected Result**:
- Complete newsletter displayed in chat with:
  - Hook paragraph (2-3 sentences, under 60 words, does not start with "I" or a greeting)
  - Main content sections using `##` headings (H2), matching section count from the outline
  - Inline source links using `[text](url)` format (no footnotes, no bare URLs)
  - `---` dividers between major sections
  - Key Takeaways section with 3-5 bullets each starting with an action verb
  - CTA closing paragraph (2-3 sentences, conversational)
  - Sources section listing all referenced URLs with descriptive link text
- Substack-compatible formatting:
  - No raw HTML tags
  - No Markdown tables in the body
  - No H1 headings
  - No footnotes or endnote syntax
  - No nested blockquotes
  - Single-level blockquotes only
- Total word count between 800 and 1500 (excluding Sources section)
- Draft Summary footer shows topic, section count, approximate word count, and saved file path
- File saved to `newsletters/[topic-slug]-[YYYY-MM-DD].md`

**Pass Criteria**: Newsletter is complete and displays in chat; Substack formatting constraints met; word count within 800-1500 range; file saved successfully; Sources section includes all inline-cited URLs.

---

## TC-05: Full Pipeline Runs End-to-End

**Priority**: P0
**Command**: `/newsletter "AI agents for small business"`
**Prerequisites**: WebSearch tool available, Filesystem MCP configured
**Steps**:
1. Run `/newsletter "AI agents for small business"`
2. Observe all three phases executing sequentially without user intervention
3. Verify Phase 1 (Research), Phase 2 (Outline), and Phase 3 (Draft) outputs

**Expected Result**:
- **Phase 1/3**: Research summary displayed with topic, date range, sources searched, query count, findings count, top findings table, and key themes
- Transition message: "Research complete. Proceeding to outline..."
- **Phase 2/3**: Outline displayed with hook type, sections, section details with source references, key takeaways, and CTA direction
- Transition message: "Outline ready. Writing draft..."
- **Phase 3/3**: Complete newsletter draft displayed in chat, saved to file
- **Pipeline Complete** summary displayed with:
  - Research Stats: queries run, findings found, findings after dedup, sources used, themes identified
  - Newsletter Stats: word count (800-1500), section count, sources cited, hook type
  - Output: file path
- No user prompts between phases — pipeline runs uninterrupted
- File saved at `newsletters/ai-agents-for-small-business-[YYYY-MM-DD].md`

**Pass Criteria**: All three phases complete without stopping for user input; phase transition messages displayed; pipeline summary shows all stats; output file created.

---

## TC-06: Output File Naming Convention

**Priority**: P1
**Command**: `/newsletter "React Server Components 2026"`
**Prerequisites**: Filesystem MCP configured
**Steps**:
1. Run the full pipeline: `/newsletter "React Server Components 2026"`
2. Check the saved file path in the Draft Summary or Pipeline Complete output

**Expected Result**:
- File saved to `newsletters/react-server-components-2026-[YYYY-MM-DD].md` where `[YYYY-MM-DD]` is today's date
- Topic slug is lowercase, hyphens replace spaces, special characters removed
- `newsletters/` directory created automatically if it did not exist
- File contains the complete newsletter markdown

**Pass Criteria**: File path matches `newsletters/[topic-slug]-[YYYY-MM-DD].md` pattern; slug correctly derived from topic; directory auto-created.

---

## TC-07: Source Attribution in Final Draft

**Priority**: P1
**Command**: `/newsletter:draft`
**Prerequisites**: Outline with source references in the conversation context
**Steps**:
1. Run `/newsletter:draft` with an outline present
2. Inspect the newsletter body for inline source links
3. Inspect the Sources section at the bottom

**Expected Result**:
- Every non-obvious claim in the body has an inline hyperlink: `[descriptive text](https://url)`
- No bare URLs appear in the body
- No footnote-style or endnote-style references (e.g., `[1]`, `^1`)
- Sources section at the bottom lists all URLs cited inline with descriptive titles
- Sources section formatted as a bulleted list: `- [Title](url)`
- Every URL in the Sources section appears at least once inline in the body

**Pass Criteria**: Inline links present for sourced claims; Sources section matches inline citations; no bare URLs or footnote syntax.

---

## TC-08: Graceful Degradation Without Notion

**Priority**: P1
**Command**: `/newsletter:research "edge computing trends"`
**Prerequisites**: Notion MCP disabled or unavailable (remove API key or stop server)
**Steps**:
1. Disable Notion MCP
2. Run `/newsletter:research "edge computing trends"`
3. Observe output

**Expected Result**:
- Research completes successfully — all findings displayed in chat
- No error messages, warnings, or stack traces related to Notion
- "Tracked in Notion" line is omitted from the output (not shown as "No")
- Research summary is fully rendered with findings table, themes, and counts
- Full pipeline (`/newsletter`) also works: Notion logging skipped silently

**Pass Criteria**: Research output identical in structure to Notion-enabled runs minus the "Tracked in Notion" line; no errors or warnings.

---

## TC-08a: Notion DB Discovery Uses Consolidated DB

**Priority**: P1
**Command**: `/newsletter:research "AI trends"`
**Prerequisites**: Notion MCP available. "[FOS] Research" database exists in Notion.
**Steps**:
1. Ensure the "[FOS] Research" database exists in Notion
2. Run `/newsletter:research "AI trends"`
3. Check Notion for the logged research session

**Expected Result**:
- Research session is logged to "[FOS] Research" (not "Newsletter Engine - Research")
- The page has Type property set to "Newsletter Research"
- All research fields (Topic, Date Range, Total Findings, Sources Searched, Key Themes, Researched At) are populated

**Pass Criteria**: Page appears in "[FOS] Research" with Type="Newsletter Research"; no standalone "Newsletter Engine - Research" DB created.

---

## TC-08b: Notion DB Discovery Falls Back to Legacy Name

**Priority**: P2
**Command**: `/newsletter:research "cloud computing"`
**Prerequisites**: Notion MCP available. "[FOS] Research" does NOT exist. "Newsletter Engine - Research" exists.
**Steps**:
1. Ensure only the legacy "Newsletter Engine - Research" database exists
2. Run `/newsletter:research "cloud computing"`
3. Check Notion for the logged research session

**Expected Result**:
- Research session is logged to "Newsletter Engine - Research" (fallback)
- No new database is created
- Research completes normally

**Pass Criteria**: Page appears in legacy DB; no new DB created; no errors.

---

## TC-08c: Full Pipeline Logs to Consolidated Content DB

**Priority**: P1
**Command**: `/newsletter "AI automation tools"`
**Prerequisites**: Notion MCP available. "[FOS] Content" database exists.
**Steps**:
1. Run `/newsletter "AI automation tools"`
2. Check Notion for entries in "[FOS] Content"

**Expected Result**:
- A page is created in "[FOS] Content" with Type="Newsletter"
- Title contains the newsletter topic
- Content field contains the newsletter draft text
- Status is "Draft"
- Output File contains the saved file path
- Generated At is populated
- Re-running the same topic on the same day updates the existing page (idempotent)

**Pass Criteria**: Newsletter logged to Content DB with Type="Newsletter"; idempotent on re-run.

---

## TC-09: Graceful Degradation Without Google Drive

**Priority**: P1
**Command**: `/newsletter "SaaS metrics benchmarks"`
**Prerequisites**: gws CLI not installed or not authenticated
**Steps**:
1. Ensure gws CLI is unavailable (not installed or not authenticated)
2. Run the full pipeline: `/newsletter "SaaS metrics benchmarks"`
3. Observe all three phases

**Expected Result**:
- Full pipeline completes without errors
- Research uses WebSearch as the primary source (Drive is not a research source for this plugin)
- No warnings about gws CLI or Google Drive being unavailable
- Draft saved to file successfully
- Pipeline summary shows all expected stats

**Pass Criteria**: Pipeline completes end-to-end; no Drive-related errors; output file saved.

---

## TC-10: --sources Flag Filters Research Queries

**Priority**: P2
**Command**: `/newsletter:research "Kubernetes" --sources=web,github`
**Prerequisites**: WebSearch tool available
**Steps**:
1. Run `/newsletter:research "Kubernetes" --sources=web,github`
2. Observe the queries formulated
3. Check the "Sources searched" line in the output

**Expected Result**:
- General web queries included
- `site:github.com` queries included
- No `site:reddit.com` queries executed
- No `site:quora.com` queries executed
- "Sources searched" line shows only `web, github` (not reddit or quora)
- Findings only come from web and GitHub sources

**Pass Criteria**: Only web and github queries executed; reddit and quora sources absent from queries and output.

---

## TC-11: --sections Flag Controls Section Count

**Priority**: P2
**Command**: `/newsletter:outline --sections=3` and `/newsletter:outline --sections=5`
**Prerequisites**: Research findings present in conversation
**Steps**:
1. Run `/newsletter:research` on any topic to populate findings
2. Run `/newsletter:outline --sections=3`
3. Count the main content sections in the outline
4. In a new conversation with research findings, run `/newsletter:outline --sections=5`
5. Count the main content sections

**Expected Result**:
- With `--sections=3`: Exactly 3 section blocks in the outline, each with title, key points, and angle
- With `--sections=5`: Exactly 5 section blocks in the outline
- "Sections" metadata line matches the requested count
- Values outside 3-5 are clamped: `--sections=2` produces 3, `--sections=7` produces 5, with an informational message

**Pass Criteria**: Section count matches the flag value within the 3-5 range; out-of-range values clamped with user notification.

---

## TC-12: --output Flag Overrides Default File Path

**Priority**: P2
**Command**: `/newsletter:draft --output=custom/path/my-newsletter.md`
**Prerequisites**: Outline present in conversation, Filesystem MCP configured
**Steps**:
1. Run `/newsletter:draft --output=custom/path/my-newsletter.md`
2. Check the "Saved to" line in the Draft Summary

**Expected Result**:
- File saved to `custom/path/my-newsletter.md` (not the default `newsletters/` directory)
- Parent directory `custom/path/` created if it did not exist
- Draft Summary footer shows the custom path
- File contents match the draft displayed in chat

**Pass Criteria**: File saved at the exact custom path; default naming convention not used; file content matches chat output.

---

## TC-13: Broad Topic Produces Focused Findings

**Priority**: P2 (Edge Case)
**Command**: `/newsletter:research "technology trends"`
**Prerequisites**: WebSearch tool available
**Steps**:
1. Run `/newsletter:research "technology trends"`
2. Inspect findings and themes

**Expected Result**:
- Research completes without error
- Findings are returned (not empty)
- Key themes are coherent groupings (not a random grab bag)
- Findings have varied source types (not all from one source)
- Combined scores are distributed (not all identical)
- Deduplication occurs (raw count >= deduplicated count)

**Pass Criteria**: Non-empty findings with coherent themes; multiple source types represented; deduplication applied.

---

## TC-14: Niche Topic Handles Sparse Results

**Priority**: P2 (Edge Case)
**Command**: `/newsletter:research "rust async runtime benchmarks"`
**Prerequisites**: WebSearch tool available
**Steps**:
1. Run `/newsletter:research "rust async runtime benchmarks"`
2. Observe how the plugin handles potentially sparse or missing results for some sources

**Expected Result**:
- Research completes without error
- If some queries return no results, they are skipped silently and the pipeline continues
- Findings may be fewer than for a broad topic, but the output structure is still valid
- At least some findings are returned (web results should exist for this topic)
- Key themes are derived from whatever findings are available
- Source type counts may show 0 for some types — this is acceptable

**Pass Criteria**: No errors from empty search results; remaining findings displayed in correct schema; output structure intact.

---

## TC-15: No Recent Results Reports Appropriately

**Priority**: P2 (Edge Case)
**Command**: `/newsletter:research "xyznonexistenttopic12345" --days=1`
**Prerequisites**: WebSearch tool available
**Steps**:
1. Run `/newsletter:research "xyznonexistenttopic12345" --days=1`
2. Observe the output when no findings match

**Expected Result**:
- Displays: "No findings for 'xyznonexistenttopic12345' in the last 1 days. Try broadening the topic or extending the date range with `--days=30`."
- No fabricated or hallucinated findings
- No error or crash
- No findings table displayed (since there are no findings)

**Pass Criteria**: Empty-result message displayed with the exact topic and day count; no hallucinated content; graceful handling.

---

## TC-16: Empty $ARGUMENTS on /newsletter Prompts for Topic

**Priority**: P2 (Edge Case)
**Command**: `/newsletter`
**Prerequisites**: None
**Steps**:
1. Run `/newsletter` with no arguments
2. Observe the response

**Expected Result**:
- Plugin prompts the user: "What topic should the newsletter cover?" (or equivalent prompt asking for a topic)
- Pipeline does not proceed
- No errors or crashes
- No fabricated topic

**Pass Criteria**: User prompted for topic; pipeline halted until input received; no default topic assumed.

---

## Test Summary

| ID | Test Case | Priority | Command | Key Acceptance Criterion |
|----|-----------|----------|---------|--------------------------|
| TC-01 | Structured findings schema | P0 | `/newsletter:research` | All fields present: title, source, url, summary, date, source_type, scores |
| TC-02 | Multi-source site: queries | P0 | `/newsletter:research` | site:github, site:reddit, site:quora queries generated |
| TC-03 | Outline structure from research | P0 | `/newsletter:outline` | Hook, sections, takeaways, CTA all present |
| TC-04 | Substack-compatible draft | P0 | `/newsletter:draft` | Complete newsletter, correct formatting, 800-1500 words |
| TC-05 | Full pipeline end-to-end | P0 | `/newsletter` | Three phases run uninterrupted, file saved |
| TC-06 | Output file naming | P1 | `/newsletter` | `newsletters/[topic-slug]-[YYYY-MM-DD].md` |
| TC-07 | Source attribution | P1 | `/newsletter:draft` | Inline links + Sources section match |
| TC-08 | Graceful degradation (Notion) | P1 | `/newsletter:research` | No errors, output to chat |
| TC-08a | Consolidated DB discovery | P1 | `/newsletter:research` | Logs to HQ - Research with Type=Newsletter Research |
| TC-08b | Legacy DB fallback | P2 | `/newsletter:research` | Falls back to Newsletter Engine - Research |
| TC-08c | Content DB logging | P1 | `/newsletter` | Logs newsletter to HQ - Content with Type=Newsletter |
| TC-09 | Graceful degradation (Drive) | P1 | `/newsletter` | Pipeline completes without Drive |
| TC-10 | --sources flag filtering | P2 | `/newsletter:research` | Only specified sources queried |
| TC-11 | --sections flag | P2 | `/newsletter:outline` | Section count matches flag, clamped to 3-5 |
| TC-12 | --output flag override | P2 | `/newsletter:draft` | File saved at custom path |
| TC-13 | Broad topic handling | P2 | `/newsletter:research` | Focused findings, coherent themes |
| TC-14 | Niche topic sparse results | P2 | `/newsletter:research` | No errors, valid structure |
| TC-15 | No results reporting | P2 | `/newsletter:research` | Empty-result message, no hallucination |
| TC-16 | Empty arguments prompt | P2 | `/newsletter` | Prompts for topic, halts pipeline |
