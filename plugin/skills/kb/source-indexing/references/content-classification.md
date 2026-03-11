# Content Classification Reference

Complete 9-type classification taxonomy with definitions, detection signals, title patterns, content structure indicators, parent location heuristics, keyword extraction methodology, freshness calculation details, edge case handling, Notion DB schema, and example index outputs for the source-indexing skill.

## Classification Taxonomy

### 1. wiki

**Definition**: Long-form knowledge articles, documentation hubs, and team wiki pages. These are reference-grade documents maintained as living knowledge that the team consults regularly.

**Title Patterns** (case-insensitive):
- Contains "wiki" anywhere in the title
- Starts with "Guide to", "Guide:", "Overview of", "Introduction to", "About "
- Contains "documentation", "docs", "knowledge base", "handbook", "playbook"
- Ends with "Guide", "Overview", "Manual"

**Content Structure Signals**:
- Multiple H2 or H3 headings (3+ sections)
- Table of contents or linked sub-pages
- Long-form prose paragraphs (average paragraph > 50 words)
- Internal links to other wiki pages
- Word count > 500

**Parent Location Heuristics**:
- Parent page title contains "Wiki", "Knowledge Base", "Documentation", "Docs", "Handbook"

---

### 2. meeting-notes

**Definition**: Records of meetings, standups, retrospectives, or any synchronous conversation. Captures who attended, what was discussed, and what was decided.

**Title Patterns** (case-insensitive):
- Starts with "Meeting Notes:", "Meeting:", "Notes:", "Minutes:", "Standup:", "Standup -", "Retro:", "Retrospective:", "Sync:", "Check-in:", "1:1:", "1-on-1:"
- Contains "meeting notes", "standup notes", "weekly sync", "daily standup", "team meeting", "all-hands"
- Matches date-prefixed pattern: `YYYY-MM-DD` followed by meeting-related words
- Contains "attendees" or "participants" within the first 500 characters

**Content Structure Signals**:
- Contains an "Attendees" or "Participants" section
- Contains an "Agenda" section
- Contains "Action Items" or "Next Steps" section
- Bullet-point-heavy format with speaker attributions ("Name:", "[Name]")
- Date stamp near the top of the document

**Parent Location Heuristics**:
- Parent page title contains "Meetings", "Meeting Notes", "Standups", "Syncs", "1:1s"

---

### 3. project-docs

**Definition**: Project plans, briefs, specifications, roadmaps, PRDs, and other documents that define the scope, timeline, and deliverables of a specific project or initiative.

**Title Patterns** (case-insensitive):
- Starts with "Project:", "PRD:", "Spec:", "RFC:", "Brief:", "Roadmap:", "Proposal:"
- Contains "project plan", "project brief", "product requirements", "technical spec", "feature spec", "design doc", "architecture", "roadmap"
- Contains "sprint", "milestone", "epic", "initiative"
- Ends with "Plan", "Brief", "Spec", "Specification", "PRD"

**Content Structure Signals**:
- Contains sections named "Objectives", "Goals", "Requirements", "Scope", "Timeline", "Milestones", "Deliverables", "Success Criteria", "Dependencies"
- Contains Gantt chart or timeline references
- References sprint numbers, release versions, or milestone dates
- Contains status indicators ("In Progress", "Completed", "Blocked", "Not Started")

**Parent Location Heuristics**:
- Parent page title contains "Projects", "Roadmap", "Planning", "Product", "Engineering", "Specs"

---

### 4. process

**Definition**: Standard operating procedures, how-to guides, step-by-step workflows, runbooks, and checklists that describe how to accomplish a specific task or follow a specific procedure.

**Title Patterns** (case-insensitive):
- Starts with "How to", "Process:", "SOP:", "Procedure:", "Workflow:", "Runbook:", "Checklist:"
- Contains "step-by-step", "how-to", "instructions", "procedure", "workflow", "onboarding", "setup guide", "getting started", "tutorial"
- Ends with "Process", "Procedure", "Workflow", "Runbook", "Checklist", "SOP"

**Content Structure Signals**:
- Numbered steps (1., 2., 3. or Step 1, Step 2, Step 3)
- Imperative verb openings ("Open the...", "Navigate to...", "Click on...", "Run the...")
- Sequential structure with clear ordering
- Contains "Prerequisites" or "Before you begin" section
- Checkbox lists or task completion markers
- Contains "Note:" or "Warning:" or "Important:" callouts within procedural steps

**Parent Location Heuristics**:
- Parent page title contains "Processes", "SOPs", "How-To", "Guides", "Runbooks", "Onboarding", "Workflows"

---

### 5. reference

**Definition**: Lookup tables, glossaries, FAQs, configuration references, API documentation, and other content designed for quick lookups rather than sequential reading.

**Title Patterns** (case-insensitive):
- Starts with "FAQ:", "Glossary:", "Reference:", "Config:", "API:", "Cheat Sheet:"
- Contains "FAQ", "glossary", "reference guide", "lookup", "cheat sheet", "quick reference", "configuration", "settings", "API reference", "endpoints"
- Ends with "Reference", "FAQ", "Glossary", "Cheat Sheet"

**Content Structure Signals**:
- Q&A format (lines starting with "Q:" or ending with "?" followed by "A:" or an answer paragraph)
- Definition list format (term followed by description)
- Dense tables with 3+ columns
- Alphabetically ordered entries
- Short entries per item (average < 100 words per section)
- Code blocks with configuration examples

**Parent Location Heuristics**:
- Parent page title contains "Reference", "Resources", "FAQs", "Glossary", "API", "Config"

---

### 6. template

**Definition**: Reusable document scaffolds, form templates, starter documents, and boilerplate content designed to be duplicated and filled in for new instances.

**Title Patterns** (case-insensitive):
- Starts with "Template:", "[Template]", "Template -"
- Contains "template", "boilerplate", "scaffold", "starter"
- Ends with "Template", "Boilerplate"
- Surrounded by brackets: "[Project Name]", "[Client Name]" -- placeholder indicators

**Content Structure Signals**:
- Contains placeholder text in brackets: `[Your Name]`, `[Date]`, `[Project Name]`, `[Description]`
- Contains "Instructions:" or "How to use this template" section
- Sparse content with structural headings but minimal body text
- Contains "Delete this section" or "Replace with" instructions
- Toggle blocks with instructions for the template user

**Parent Location Heuristics**:
- Parent page title contains "Templates", "Starters", "Boilerplate"

---

### 7. database

**Definition**: Notion databases and structured data collections. This classification applies to Notion database objects (not pages), regardless of their content or title.

**Classification Rule**: Any source with Source Type = "Notion Database" receives this classification automatically. Do not apply title matching, content analysis, or parent heuristics -- the object type is sufficient.

**Metadata Notes**:
- Word Count: always 0 (databases contain structured records, not prose)
- Keywords: extracted from the database title and property names
- Item count appended to keywords when available

---

### 8. archive

**Definition**: Deprecated, outdated, or explicitly archived content that is preserved for historical reference but no longer actively maintained.

**Title Patterns** (case-insensitive):
- Starts with "[Archived]", "[Deprecated]", "[Old]", "[Legacy]", "Archive:", "ARCHIVED:"
- Contains "archived", "deprecated", "legacy", "old version", "superseded by", "replaced by", "no longer in use"
- Ends with "(archived)", "(deprecated)", "(old)"

**Content Structure Signals**:
- Contains a banner or callout at the top: "This document is archived", "This page is no longer maintained", "See [newer version] instead"
- Notion page has `archived: true` property
- Last edited more than 365 days ago AND parent is an archive section

**Parent Location Heuristics**:
- Parent page title contains "Archive", "Archived", "Old", "Legacy", "Deprecated"
- Page is in the Notion trash (accessible via search but marked as trashed)

**Special Rule**: When a page matches `archive` by title or parent location, classify as `archive` even if content structure matches another type. Archival status takes priority over content type.

---

### 9. other

**Definition**: Default classification for sources that do not match any of the above 8 types. This is the fallback when all detection layers (title, content, parent) are inconclusive.

**No detection signals** -- this classification is applied only when no other type matches after evaluating all three layers.

---

## Classification Decision Flow

Evaluate classifications using first-match-wins in this exact order:

```
1. Is Source Type = "Notion Database"?  --> database
2. Does title or content match "archive" signals?  --> archive
3. Does title match any type 1-6 pattern?  --> that type (stop)
4. Does content structure match any type 1-6 signals?  --> that type (stop)
5. Does parent location match any type 1-6 heuristic?  --> that type (stop)
6. No match found  --> other
```

Archive is checked at priority 2 (before other content types) because archived content should retain its archival status regardless of its original content type. A page titled "[Archived] Sprint 14 Standup Notes" is `archive`, not `meeting-notes`.

Database is checked at priority 1 because the object type alone is definitive.

## Keyword Extraction Methodology

### Tokenization and Filtering

1. **Input**: First 3000 characters of source content. For databases, use the title and property names concatenated.

2. **Tokenize**: Split on whitespace and punctuation. Lowercase all tokens. Remove tokens shorter than 3 characters.

3. **Stop word removal**: Remove all words from the stop word list defined in SKILL.md. Additionally remove these domain-specific stop words that are common in Notion workspaces but carry low information value:
   - "page", "section", "note", "notes", "item", "items", "list", "link", "links", "click", "open", "view", "see", "add", "new", "edit", "delete", "create", "update"

4. **Heading boost**: Words appearing in H1, H2, or H3 headings receive 2x weight in frequency counting. This surfaces topical words that the author chose as section titles.

5. **Frequency counting**: Count occurrences of each remaining token. Multiply heading occurrences by 2.

6. **Noun preference**: When two tokens have equal weighted frequency, prefer the one that is more likely a noun. Heuristic: words ending in -tion, -ment, -ness, -ity, -ence, -ance, -ing (gerunds used as nouns), -er (agent nouns) are likely nouns.

7. **Selection**: Take the top 5-8 tokens by weighted frequency. If fewer than 5 tokens remain after filtering, include all available tokens.

8. **Output format**: Join selected keywords with ", " (comma-space separator). Example: "budget, timeline, deliverables, milestone, Q3, launch".

### Keyword Quality Rules

- Never include the classification type itself as a keyword (e.g., do not include "wiki" as a keyword for a wiki-classified page).
- Never include generic words that describe the document format rather than its topic ("document", "file", "table", "paragraph").
- Preserve proper nouns and acronyms in their original casing: "API", "OAuth", "Slack", "CRM".
- For multi-word concepts that frequently co-occur ("project management", "code review"), include them as separate tokens -- the comma-separated format does not support phrases.

### Edge Cases for Keywords

- **Pages with < 50 words**: Extract keywords from the title only. Split title into tokens, apply stop word removal, return all qualifying tokens (may be fewer than 5).
- **Pages with only images/embeds**: Set keywords to the title-derived keywords. Note that embedded content is not analyzed for keywords.
- **Database sources**: Concatenate the database title + all property names. Apply standard extraction. Append ", [N] items" if item count is known.

## Freshness Calculation Details

### Date Math

Compute `days_since_edit` as the integer number of calendar days between the source's `Last Edited` timestamp and the current date at midnight UTC:

```
days_since_edit = floor((current_utc_midnight - last_edited_utc) / 86400)
```

When `last_edited_time` includes a timezone offset, convert to UTC before computing the difference. When no timezone is provided, assume UTC.

### Tier Boundaries

| Tier | Range (inclusive) | Typical Interpretation |
|------|-------------------|----------------------|
| Fresh | 0-29 days | Actively maintained, high confidence |
| Current | 30-89 days | Reasonably reliable, check for updates |
| Aging | 90-179 days | May be outdated, cross-reference recommended |
| Stale | 180+ days | Likely outdated, cite with caution |

Boundary values: 29 days = Fresh, 30 days = Current, 89 days = Current, 90 days = Aging, 179 days = Aging, 180 days = Stale.

### Freshness Recalculation

Freshness is always computed relative to the current date, never carried forward from a previous index run. A source indexed as "Fresh" 60 days ago is now "Current" -- the new freshness tier is written on re-index.

When re-indexing a source and the `Last Edited` date has not changed since the last index run, the freshness tier may still change because the current date has advanced.

## Notion DB Schema: Sources DB

Full property definitions for source records in the "[FOS] Knowledge Base" database (with Type="Source"), or the "Founder OS HQ - Knowledge Base" / legacy "Knowledge Base Q&A - Sources" database. Template at `_infrastructure/notion-db-templates/knowledge-base-qa-sources.json`.

| Property | Notion Type | Constraints | Description |
|----------|-------------|-------------|-------------|
| Source Title | title | Max 200 chars | Name of the source document or page |
| URL | url | Unique key for idempotent updates | Notion page URL or Google Drive file URL |
| Source Type | select | Options: "Notion Page", "Notion Database", "Google Drive" | Platform where the source is stored |
| Classification | select | Options: "wiki", "meeting-notes", "project-docs", "process", "reference", "template", "database", "archive", "other" | Content classification from the 9-type taxonomy |
| Topic Keywords | rich_text | Comma-separated, 5-8 terms | Topic keywords extracted from content |
| Word Count | number | Integer >= 0 | Approximate word count. 0 for databases |
| Last Edited | date | ISO 8601 | When the source was last modified in its original platform |
| Freshness | select | Options: "Fresh", "Current", "Aging", "Stale" | Freshness tier computed from Last Edited vs current date |
| Parent Location | rich_text | Breadcrumb path | Parent page/folder path for organizational context |
| Status | select | Options: "Active", "Archived", "Error" | Accessibility status of the source |
| Indexed At | date | ISO 8601 | Timestamp when this source was last indexed |

### Property Usage Notes

- **URL** is the idempotent key. Before creating a new record, always search for an existing record with the same URL. Update if found.
- **Status** defaults to "Active" on first index. Set to "Archived" when a previously indexed source is no longer accessible. Set to "Error" when metadata extraction fails.
- **Indexed At** is always set to the current timestamp, even on updates. This tracks when the index was last refreshed, independent of when the source was last edited.
- **Freshness** is always recomputed, never preserved from the previous record.

## Example Index Outputs

### Example 1: Wiki Page

**Source**: A Notion page titled "Engineering Onboarding Guide" under a "Wiki" parent page.

```
Source Title:     Engineering Onboarding Guide
URL:              https://www.notion.so/abc123def456
Source Type:      Notion Page
Classification:   wiki
Topic Keywords:   onboarding, engineering, setup, development, environment, tools, access
Word Count:       2340
Last Edited:      2026-02-15T10:30:00Z
Freshness:        Fresh
Parent Location:  Workspace > Wiki > Engineering
Status:           Active
Indexed At:       2026-03-04T14:00:00Z
```

**Classification rationale**: Title contains "Guide" (wiki pattern) + parent page is "Wiki" (parent heuristic). Title match at priority 3, confirmed by parent at priority 5.

---

### Example 2: Meeting Notes

**Source**: A Notion page titled "2026-02-28 Product Sync - Sprint 22 Review" under a "Meeting Notes" parent.

```
Source Title:     2026-02-28 Product Sync - Sprint 22 Review
URL:              https://www.notion.so/789xyz012abc
Source Type:      Notion Page
Classification:   meeting-notes
Topic Keywords:   sprint, review, product, roadmap, backlog, velocity
Word Count:       890
Last Edited:      2026-02-28T16:45:00Z
Freshness:        Fresh
Parent Location:  Workspace > Meeting Notes > Product Syncs
Status:           Active
Indexed At:       2026-03-04T14:00:00Z
```

**Classification rationale**: Title matches date-prefixed pattern with "Sync" and "Review" meeting words. Confirmed by "Meeting Notes" parent.

---

### Example 3: Google Drive Document

**Source**: A Google Doc titled "Client Proposal Template v3" in a "Templates" Drive folder.

```
Source Title:     Client Proposal Template v3
URL:              https://docs.google.com/document/d/1a2b3c4d5e
Source Type:      Google Drive
Classification:   template
Topic Keywords:   proposal, client, scope, pricing, timeline
Word Count:       0
Last Edited:      2025-08-12T09:20:00Z
Freshness:        Aging
Parent Location:  Templates > Client Documents
Status:           Active
Indexed At:       2026-03-04T14:00:00Z
```

**Classification rationale**: Title contains "Template" (template title pattern). Confirmed by "Templates" parent folder. Word Count is 0 because full content is not retrieved from Drive during indexing.

---

### Example 4: Notion Database

**Source**: A Notion database titled "Bug Tracker" with 234 items under an "Engineering" parent.

```
Source Title:     Bug Tracker
URL:              https://www.notion.so/def456ghi789
Source Type:      Notion Database
Classification:   database
Topic Keywords:   bug, tracker, status, priority, assignee, 234 items
Word Count:       0
Last Edited:      2026-03-01T12:00:00Z
Freshness:        Fresh
Parent Location:  Workspace > Engineering
Status:           Active
Indexed At:       2026-03-04T14:00:00Z
```

**Classification rationale**: Source Type is "Notion Database" -- automatic `database` classification at priority 1. No title or content analysis needed.

---

### Example 5: Archived Page

**Source**: A Notion page titled "[Archived] Old Deployment Process" under an "Archive" parent.

```
Source Title:     [Archived] Old Deployment Process
URL:              https://www.notion.so/old123deploy
Source Type:      Notion Page
Classification:   archive
Topic Keywords:   deployment, process, CI, pipeline, staging
Word Count:       1560
Last Edited:      2025-04-10T08:00:00Z
Freshness:        Stale
Parent Location:  Workspace > Archive > Engineering
Status:           Active
Indexed At:       2026-03-04T14:00:00Z
```

**Classification rationale**: Title starts with "[Archived]" (archive title pattern) -- matched at priority 2 before content analysis could classify it as `process`. Status remains "Active" because the page is still accessible; `archive` is the content classification, not the accessibility status.
