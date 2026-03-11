# Citation Formats and Drive Document QA Reference

Detailed specifications for citation formatting in Google Drive document answers, including inline placement rules, Drive URL formatting, spreadsheet and section citations, selection criteria, no-citation scenarios, worked examples, and edge cases. Referenced by `${CLAUDE_PLUGIN_ROOT}/skills/drive/document-qa/SKILL.md`.

---

## Inline Citation Placement Rules

### End-of-Sentence Citation

Place the citation marker after the period when the citation supports the entire sentence.

```
The annual revenue target is $12M. [1]
```

### Clause-Only Citation

Place the citation marker before the period when it supports only the final clause of a compound sentence, not the full sentence.

```
While the marketing budget was approved in January [1], the revised
allocation was not finalized until March. [2]
```

### Mid-Sentence Citation

Place the citation marker immediately after the clause it supports when citing a specific clause within a longer sentence.

```
The East region exceeded targets by 15% [1], but the West region
fell short by 8% [2], resulting in a net positive for the quarter. [1]
```

### Multiple Citation Format

When multiple sources support the same claim, place citation brackets adjacent to each other with no separator.

```
All contracts require a minimum 30-day notice period. [1][3]
```

Do not use comma-separated lists inside a single bracket. Use `[1][3]`, never `[1, 3]`.

### Citation Within a List

Place citations at the end of each list item they support.

```
- Q3 revenue: $3.2M [1]
- Active clients: 47 [2]
- Renewal rate: 89% [1][3]
```

### Citation in Tables

When presenting tabular data extracted from a spreadsheet, cite the source once in the introductory sentence rather than on every cell.

```
The staffing plan breaks down as follows [1]:

| Department | Headcount | Budget |
|------------|-----------|--------|
| Engineering | 24 | $2.8M |
| Marketing | 12 | $1.4M |
```

---

## Citation Block Format

Place the citation block after a horizontal rule at the end of every Q&A answer.

```
---
Sources:
[1] "Q3 Financial Report" - https://docs.google.com/document/d/abc123
[2] "Revenue Tracker" - https://docs.google.com/spreadsheets/d/def456
[3] "Annual Plan 2026" - https://drive.google.com/file/d/ghi789
```

### Drive URL Formatting

Use the file's Google Drive link as provided by the Drive API or MCP server. Preserve the full URL including the file ID. Common formats:

| File Type | URL Pattern |
|-----------|-------------|
| Google Doc | `https://docs.google.com/document/d/{file_id}` |
| Google Sheet | `https://docs.google.com/spreadsheets/d/{file_id}` |
| Google Slides | `https://docs.google.com/presentation/d/{file_id}` |
| PDF / other | `https://drive.google.com/file/d/{file_id}` |

Do not fabricate URLs. If the Drive API returns only a file ID without a full URL, construct the URL from the file ID using the appropriate pattern above. If neither a URL nor file ID is available, use: `"Document Title" - Google Drive (link unavailable)`.

### Spreadsheet Tab Citations

When citing data from a specific tab within a Google Sheet, include the tab name after the spreadsheet title, separated by `>`.

```
[1] "Budget Tracker > Q3 Actuals" - https://docs.google.com/spreadsheets/d/abc123
[2] "Budget Tracker > Forecasts" - https://docs.google.com/spreadsheets/d/abc123
```

Both citations point to the same spreadsheet URL but distinguish which tab the data came from. When a spreadsheet has only a single tab (or the tab name is "Sheet1" with no other tabs), omit the tab name.

### Section-Level Citations for Long Documents

When citing a specific section of a long Google Doc, include the section heading after the document title, separated by `>`.

```
[1] "Employee Handbook > Time Off Policy" - https://docs.google.com/document/d/xyz789
[2] "Employee Handbook > Code of Conduct" - https://docs.google.com/document/d/xyz789
```

Use section-level citations when:
- The document is longer than 2000 words.
- The cited information comes from a clearly delineated section under a heading.
- Multiple distinct sections from the same document are cited.

When the section boundary is unclear or the document lacks headings, cite the document as a whole without a section suffix.

### Citation Numbering Rules

1. Number citations sequentially in the order they first appear in the answer text (not by relevance or alphabetical order).
2. Reuse the same number when referencing the same source (same document + same section/tab) again later in the answer.
3. Maximum 5 unique citations per answer. Select the most relevant and authoritative sources when more are available.
4. Never assign a citation number that is not used in the answer text. If only 3 sources are cited, the block lists [1], [2], [3] only.
5. When two different tabs of the same spreadsheet are cited, treat them as separate citations with separate numbers.

---

## Maximum 5 Citations: Selection Criteria

When the search returns more than 5 relevant sources, select the best 3-5 using these criteria in priority order:

1. **Directness**: Prefer sources that explicitly answer the question over sources that require inference.
2. **Recency**: Prefer more recently modified sources when two sources provide equivalent coverage.
3. **Authority**: Prefer shared/published documents over personal drafts, and official templates over ad-hoc notes.
4. **Specificity**: Prefer documents dedicated to the topic over general documents that mention the topic in passing.
5. **Uniqueness**: Avoid citing two sources that say the same thing. Pick the stronger one and drop the redundant source.

When all 5 citation slots are filled and an additional source contains unique information not covered by the existing citations, replace the weakest citation (lowest directness + oldest) with the new source.

---

## No-Citation Scenarios

Do not attach citations to:

- **Common knowledge**: Statements that any business professional would know without documentation (e.g., "Revenue is income from sales" or "Q3 covers July through September").
- **Obvious definitions**: Terms being defined in the answer that are self-evident (e.g., "MRR stands for monthly recurring revenue").
- **User-provided context**: Information the user included in their question (e.g., if the user says "We have 50 employees," do not cite that back to a Drive doc).
- **Inference disclaimers**: When noting that information was not found or that confidence is low, these meta-statements about the answer itself do not need citations.
- **Structural language**: Transition phrases, section headers within the answer, and formatting instructions.

When in doubt, cite. Under-citation is a worse failure than over-citation because it obscures the source of claims.

---

## Worked Examples

### Example 1: Single-Source Answer

**Question**: "What is the approved budget for the new office buildout?"

**Sources found**: One Google Doc, "Office Buildout Plan" (modified 2 weeks ago).

```
**Confidence:** Medium

The approved budget for the new office buildout is $450,000, covering
construction, furniture, and IT infrastructure. [1] The budget was
approved by the leadership team on February 15, 2026, with a
contingency reserve of $45,000 (10%) for unexpected costs. [1]

---
Sources:
[1] "Office Buildout Plan" - https://docs.google.com/document/d/abc123
```

**Why Medium**: Single source, even though it is a strong recent match. A single source caps confidence at Medium unless it is an official policy document.

### Example 2: Multi-Source Answer

**Question**: "How many active enterprise clients do we have and what is the average contract value?"

**Sources found**: A Google Sheet "Client Roster" (modified 1 week ago, tab "Enterprise") and a Google Doc "Q4 Sales Summary" (modified 3 weeks ago).

```
**Confidence:** High

There are currently 23 active enterprise clients. [1] The average
annual contract value across these clients is $185,000. [2] This
represents a 12% increase from Q3, when the average was $165,000. [2]

---
Sources:
[1] "Client Roster > Enterprise" - https://docs.google.com/spreadsheets/d/def456
[2] "Q4 Sales Summary" - https://docs.google.com/document/d/ghi789
```

**Why High**: Two independent sources, strong keyword matches, both recent, no conflicts. The spreadsheet provides the count and the summary doc provides the ACV with trend context.

### Example 3: Conflicting Sources

**Question**: "What is our standard payment term for new clients?"

**Sources found**: A Google Doc "Client Onboarding Guide" (modified 8 months ago) stating "Net 30" and a Google Doc "Updated Billing Policy" (modified 1 month ago) stating "Net 45."

```
**Confidence:** Medium

As of February 2026, the standard payment term for new clients is
Net 45. [1] Note: an earlier onboarding guide specified Net 30. [2]
The billing policy document is more recent and appears to reflect a
policy update, but the onboarding guide has not yet been updated to
match.

---
Sources:
[1] "Updated Billing Policy" - https://docs.google.com/document/d/jkl012
[2] "Client Onboarding Guide" - https://docs.google.com/document/d/mno345

Some sources may be outdated. Verify critical details against current
documents.
```

**Why Medium (not Low)**: The conflict is resolved by date precedence (the newer billing policy supersedes the older onboarding guide by a clear 7-month gap), but the conflict is disclosed transparently. The newer source is specific and authoritative.

### Example 4: Partial Coverage

**Question**: "What are our Q3 revenue targets and who is responsible for the product launch timeline?"

**Sources found**: A Google Sheet "Q3 Targets" with revenue data. No documents found about product launch timeline.

```
**Confidence:** Medium

The Q3 revenue target is $3.6M, broken down as $2.1M from existing
accounts and $1.5M from new business. [1] The East region is
responsible for $1.8M and the West region for $1.8M. [1]

Regarding the product launch timeline, no documentation was found in
the searched Drive documents.

---
Sources:
[1] "Q3 Targets > Revenue" - https://docs.google.com/spreadsheets/d/pqr678

This answer covers Q3 revenue targets. No documentation was found for
product launch timeline ownership.
```

**Why Medium**: The answered portion has a strong single source, but coverage is partial.

### Example 5: Spreadsheet Data Highlights (Summary Mode)

**Document**: "Monthly Expenses 2026" Google Sheet with tabs "January", "February", "March".

```
**Summary of "Monthly Expenses 2026"**
**Source:** https://docs.google.com/spreadsheets/d/stu901
**Last Modified:** 2026-03-02
**Type:** Google Sheet

A three-month expense tracking spreadsheet covering January through
March 2026, with per-category breakdowns across 14 expense categories.

**Data Highlights:**
- Total spend YTD: $127,450 across all categories
- Highest category: Software & SaaS at $34,200 (26.8% of total)
- February spike: $52,100 vs January's $38,200 (36% increase),
  driven by annual license renewals
- Travel expenses trending up: $3,400 → $5,100 → $7,200 over
  the three months
- March data appears incomplete (only 5 days of entries as of
  last modification date)
```

---

## Edge Cases

### Deleted or Inaccessible Files

When a file that appeared in search results is no longer accessible (deleted, permissions changed, or moved to trash), format the citation as:

```
[1] "Document Title" - [file deleted or inaccessible]
```

Do not count inaccessible files toward confidence scoring. If the only relevant source is inaccessible, activate the no-answer pathway and note: "A potentially relevant document ('Document Title') was found but is no longer accessible. Request access or check if the file was moved."

### Very Large Spreadsheets

When a spreadsheet has many tabs or extensive data exceeding the extraction cap:
- Cite the specific tab name where the data was extracted.
- Note in the answer if only a subset of tabs was analyzed: "Based on the [tab name] tab. Other tabs in this spreadsheet were not analyzed."
- Prioritize tabs whose names match query keywords.

### Multiple Versions of the Same Document

When search results return what appear to be multiple versions of the same document (e.g., "Budget v1", "Budget v2", "Budget FINAL"):
- Cite only the most recent version as the primary source.
- Mention the existence of earlier versions only if they contain information absent from the latest version.
- Do not count multiple versions as independent source agreement for confidence scoring.

### Documents with Mixed Content

When a Google Doc contains both text and embedded images/charts:
- Extract and cite the text content.
- Note the presence of visual content that could not be extracted: "This document contains charts/images that may hold additional relevant data not captured in this answer."

### Untitled Documents

When a Google Drive file has no title (shows as "Untitled document"):
- Use the file type and creation date as the citation label: `[1] "[Untitled Google Doc, created 2026-01-15]" - URL`.
- Flag this in the answer: "Note: this source is an untitled document, which may indicate a draft or work in progress."

### Shared vs. Personal Files

When the same content appears in both a shared folder and a personal copy:
- Prefer the shared version as the canonical citation (more likely to be current and authoritative).
- Treat them as one source, not two independent sources. Do not count them as "multiple sources agreeing" for confidence scoring.

---

## Confidence Scoring Dimensions

Evaluate confidence across four dimensions, consistent with the thresholds defined in `${CLAUDE_PLUGIN_ROOT}/skills/drive/document-qa/SKILL.md`.

| Dimension | High Signal | Medium Signal | Low Signal |
|-----------|-------------|---------------|------------|
| **Source agreement** | 2+ documents converge on the same answer | 1 strong source, or 2+ partial sources | Weak matches only, or sources disagree |
| **Keyword match** | Query terms appear in document titles or headings | Query terms appear in document body text | Only synonyms or tangential terms match |
| **Recency** | Primary source modified within 90 days | Primary source modified within 180 days | Primary source older than 180 days |
| **Directness** | Source explicitly answers the question | Source contains the answer but requires extraction | Answer requires inference across sources |

### Single-Source Override

When only one source is available:
- Maximum confidence is **Medium**, even if all other signals are High.
- Exception: A single shared policy or official template document updated within the last 30 days that explicitly and completely answers the question may be rated **High**.

### Confidence with Spreadsheet Data

Spreadsheet data gets a recency boost: treat the "last modified" date as the freshness indicator, even if the data itself covers historical periods. A spreadsheet tracking Q1 data that was last modified yesterday is "fresh" for confidence purposes.

However, note when spreadsheet data appears incomplete (e.g., a monthly tracker with entries for only the first week of the month). Incomplete data caps confidence at **Medium** regardless of other signals.
