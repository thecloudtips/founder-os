# Integration Test Plan: SOW Generator

## Test Strategy

This plan maps all 6 acceptance criteria for Plugin #14 (SOW Generator) to concrete, runnable test scenarios. The plugin uses the Competing Hypotheses agent pattern: three scope agents propose options in parallel, two analysis agents score them, and a lead synthesizes the final document.

Tests are organized into four sections:

1. **Core Command Tests (1–4)** — Validate the fundamental output contract: 3 options, required sections, risk assessment, and comparison table.
2. **Command Argument Tests (5–7)** — Validate that `--budget`, `--client`, `--output`, `--team`, and file-based input work correctly.
3. **Context and Memory Tests (8–10)** — Validate Notion historical context loading, graceful degradation, and Notion URL brief loading.
4. **Output Quality Tests (11–12)** — Validate file naming, path correctness, and Markdown formatting standards.

Each test includes a checklist of pass/fail criteria. A test passes only when all checklist items are confirmed. Run tests in order within each section; tests in Section 1 establish the baseline used by later sections.

---

## Section 1: Core Command Tests

### Test 1: Basic `/sow:generate` produces 3 options

**Acceptance Criterion Covered**: #1 — `/sow:generate [brief]` creates 3 options

**Setup**:
- No MCP servers required
- Default (single-agent) mode — no `--team` flag

**Command**:
```
/sow:generate "Build a customer portal for Acme Corp with login, dashboard, and reporting. Budget: $50k, 12 weeks."
```

**Expected Behavior**:
- Command reads all 3 skill files (`scope-definition`, `sow-writing`, `risk-assessment`) before generating
- Response contains exactly 3 named scope options (package names such as "Foundation Package", "Growth Package", "Transformation Package" — not generic "Option A/B/C")
- A comparison table is included spanning all three options
- A recommendation is stated explicitly, identifying one option as recommended
- An output summary block is shown (Client, Output path, Options, Recommended)
- A `.md` file is written to `./sow-output/`

**Pass Criteria**:
- [ ] Response contains 3 distinct named scope options
- [ ] Each option has a scope summary, timeline value, price value, and risk level
- [ ] A comparison table is present in the output
- [ ] One option is marked as the recommended option
- [ ] Output summary block is shown with client name "Acme Corp"
- [ ] SOW file created at `./sow-output/sow-acme-corp-[YYYY-MM-DD].md`

---

### Test 2: Each option contains all required document sections

**Acceptance Criterion Covered**: #2 — Each option contains scope, timeline, deliverables, price

**Setup**:
- Same as Test 1 — no MCP required, default mode

**Command**:
```
/sow:generate "Build a customer portal for Acme Corp with login, dashboard, and reporting. Budget: $50k, 12 weeks."
```

**Expected Behavior**:
- Each of the 3 options in the generated SOW file contains all 7 required sections as defined by the sow-writing skill:
  1. Objectives
  2. Scope of Work (with deliverables table)
  3. Out of Scope
  4. Timeline and Milestones
  5. Investment (with pricing breakdown)
  6. Assumptions
  7. Change Management
- The document also includes a cover page, executive summary, comparison table, terms and conditions, and signature block

**Pass Criteria**:
- [ ] Option A section contains all 7 subsections listed above
- [ ] Option B section contains all 7 subsections listed above
- [ ] Option C section contains all 7 subsections listed above
- [ ] Each Investment section includes a numeric price (not a placeholder)
- [ ] Each Timeline section includes a week count (e.g., "8 weeks", "12 weeks")
- [ ] Each Scope of Work section contains a deliverables table with at least 2 rows
- [ ] Cover page is present with client name, project name, and date
- [ ] Signature block is present at end of document

---

### Test 3: Risk assessment is present per option

**Acceptance Criterion Covered**: #3 — Risk assessment per option

**Setup**:
- Same as Test 1 — no MCP required, default mode

**Command**:
```
/sow:generate "Build a customer portal for Acme Corp with login, dashboard, and reporting. Budget: $50k, 12 weeks."
```

**Expected Behavior**:
- Each of the 3 options includes a risk profile scored by the risk-assessment skill
- Each option has a named risk level (Low, Medium, or High)
- Each option includes at least 1 specific risk item with a mitigation note
- The comparison table includes a "Risk Profile" row showing the risk level for each option
- Conservative option (Option A) typically scores Low or Medium risk
- Ambitious option (Option C) typically scores Medium-High or High risk

**Pass Criteria**:
- [ ] Option A includes a risk level label (Low, Medium, or High)
- [ ] Option B includes a risk level label
- [ ] Option C includes a risk level label
- [ ] Each option includes at least 1 named risk with a mitigation note
- [ ] The comparison table contains a "Risk Profile" row (or equivalent)
- [ ] Risk levels across the 3 options are differentiated (not all identical)

---

### Test 4: Comparison table spans all three options

**Acceptance Criterion Covered**: #4 — Comparison table across options

**Setup**:
- Same as Test 1 — no MCP required, default mode

**Command**:
```
/sow:generate "Build a customer portal for Acme Corp with login, dashboard, and reporting. Budget: $50k, 12 weeks."
```

**Expected Behavior**:
- The SOW document contains a side-by-side comparison table
- The table has 3 data columns, one per option
- The table includes at least 5 comparison rows (e.g., Scope, Timeline, Investment, Risk Profile, Buffer Time, Best For)
- One option is marked as Recommended in the table or immediately adjacent to it
- The comparison table is present in both the inline output summary and the written `.md` file

**Pass Criteria**:
- [ ] Comparison table is present in the generated `.md` file
- [ ] Table has exactly 3 data columns (one per option)
- [ ] Table has at least 5 row labels
- [ ] "Scope" or equivalent row is present
- [ ] "Timeline" or equivalent row is present
- [ ] "Investment" or "Price" row is present
- [ ] "Risk" or "Risk Profile" row is present
- [ ] One option is identified as Recommended within or adjacent to the table

---

## Section 2: Command Argument Tests

### Test 5: `--budget` flag constrains pricing across options

**Acceptance Criterion Covered**: #2 (pricing), #6 (client-ready output)

**Setup**:
- No MCP servers required
- Default (single-agent) mode

**Command**:
```
/sow:generate "Build a mobile app" --budget=25000 --client="StartupXYZ"
```

**Expected Behavior**:
- The client name "StartupXYZ" appears in the SOW header and cover page
- Pricing in all three options reflects budget awareness
- Conservative option (Option A) is priced at or below $25,000
- Balanced option (Option B) is at or near $25,000
- Ambitious option (Option C) may exceed $25,000 but notes the budget constraint explicitly if it does
- No option silently ignores the budget constraint

**Pass Criteria**:
- [ ] "StartupXYZ" appears in the SOW cover page or header
- [ ] Each option contains a pricing table with numeric values
- [ ] Option A price is at or below $25,000
- [ ] If Option C exceeds $25,000, a note acknowledges the budget constraint
- [ ] Output filename contains "startupxyz" as the client slug

---

### Test 6: `/sow:from-brief [file]` loads brief from a local file

**Acceptance Criterion Covered**: #1 (command variant), #2 (required sections), #6 (client-ready output)

**Setup**:
1. Create a brief file at `/tmp/test-brief.md` with the following content:

```markdown
# Project Brief

**Client**: Meridian Financial
**Project**: Internal expense approval workflow
**Description**: Build an internal tool for submitting, routing, and approving employee expense reports. Must integrate with our existing Notion workspace.
**Budget**: $35,000
**Timeline**: 10 weeks
**Priorities**: Ease of use, auditability, Notion integration
```

2. No MCP servers required for the file load itself

**Command**:
```
/sow:from-brief /tmp/test-brief.md
```

**Expected Behavior**:
- Brief confirmation summary is shown before generation begins, with:
  - Client: Meridian Financial
  - Source: /tmp/test-brief.md
  - Budget: $35,000
  - Timeline: 10 weeks
- SOW is generated using data from the file (not asking for interactive input)
- All 3 options are generated
- Output file uses "meridian-financial" as the client slug

**Pass Criteria**:
- [ ] "Brief Loaded" confirmation block is displayed before generation
- [ ] Confirmation block shows "Meridian Financial" as the client name
- [ ] Confirmation block shows $35,000 as the budget
- [ ] Confirmation block shows 10 weeks as the timeline
- [ ] SOW is generated with 3 options without asking the user for additional input
- [ ] Output file named `sow-meridian-financial-[YYYY-MM-DD].md`
- [ ] "Meridian Financial" appears in the generated SOW document

---

### Test 7: `--team` flag activates the 6-agent competing-hypotheses pipeline

**Acceptance Criterion Covered**: #5 — Agent Teams learn from historical SOWs and process pipeline

**Setup**:
- Filesystem MCP configured (for `Write` tool access)
- `--team` flag present

**Command**:
```
/sow:generate --team "Design a data pipeline for a fintech company that processes daily transaction files and loads them into a data warehouse"
```

**Expected Behavior**:
- Phase 1: All three scope agents (`scope-agent-a`, `scope-agent-b`, `scope-agent-c`) execute in parallel
- Phase 2: `risk-agent` and `pricing-agent` execute in parallel after Phase 1 completes
- Phase 3: `sow-lead` synthesizes all inputs and writes the final SOW file
- Pipeline completion summary is shown at the end, with:
  - Agent timing table (6 rows: one per agent)
  - Scoring matrix showing scope/risk/pricing scores per option
  - Recommended option identified
- SOW file written to `./sow-output/`

**Pass Criteria**:
- [ ] Pipeline completion summary is displayed (not the single-agent output summary)
- [ ] Agent timing table contains 6 rows (scope-agent-a, scope-agent-b, scope-agent-c, risk-agent, pricing-agent, sow-lead)
- [ ] All 6 agents show "Done" or "Complete" status
- [ ] Scoring matrix is shown with 3 option columns
- [ ] Final SOW file written to `./sow-output/` directory
- [ ] SOW contains 3 named options (not 3 generic "Option A/B/C" labels)
- [ ] Recommended option is identified in the summary

---

## Section 3: Context and Memory Tests

### Test 8: Notion historical SOW context loading (Notion available)

**Acceptance Criterion Covered**: #5 — Agent Teams learn from historical SOWs (context / Notion)

**Setup**:
- Notion MCP configured with a valid `NOTION_API_KEY`
- Notion workspace contains at least 1 page with "SOW" in the title (any page — the test validates that the search runs, not that specific data is found)

**Command**:
```
/sow:generate "Build an e-commerce integration" --client="RetailCo"
```

**Expected Behavior**:
- Command attempts a Notion search for historical SOWs using the `notion-search` tool with query "SOW"
- If historical SOWs are found: output notes "calibrating from historical data" or equivalent, and describes what context was loaded
- If no SOWs are found in Notion: output notes that no historical SOWs were found and proceeds without calibration
- In both cases, the SOW is generated successfully — historical context is optional, not required

**Pass Criteria**:
- [ ] No Notion authentication error or MCP connection error is thrown
- [ ] Output includes a note about the Notion historical context search (found or not found)
- [ ] Full 3-option SOW is generated regardless of whether historical data was found
- [ ] "RetailCo" appears in the SOW output

---

### Test 8b: Notion output writes to "Founder OS HQ - Deliverables" with Type="SOW"

**Acceptance Criterion Covered**: #5 — Notion output tracking, HQ consolidation

**Setup**:
- Notion MCP configured with a valid `NOTION_API_KEY`
- "Founder OS HQ - Deliverables" database exists in the Notion workspace and is shared with the integration
- CRM Pro "Companies" database exists with at least one company record

**Command**:
```
/sow:generate "Build a customer portal for Acme Corp with login, dashboard, and reporting. Budget: $50k, 12 weeks." --client="Acme Corp"
```

**Expected Behavior**:
- After generating the SOW, the command searches for "Founder OS HQ - Deliverables" database
- A record is created (or updated if one already exists for "Acme Corp" + project title with Type="SOW")
- The record has Type = "SOW", Status = "Draft", and Amount set to the recommended option's quoted price
- Company relation is resolved by looking up "Acme Corp" in the CRM Pro "Companies" database
- If no matching company is found, the Company relation is left empty (no placeholder created)

**Pass Criteria**:
- [ ] Command searches for "Founder OS HQ - Deliverables" database (not "SOW Generator - Outputs")
- [ ] Record created with Type = "SOW"
- [ ] Record has Status = "Draft"
- [ ] Record has Amount set to a numeric value (the recommended option's price)
- [ ] Record has File Path set to the output `.md` file path
- [ ] Company relation is attempted (lookup in CRM Pro "Companies")
- [ ] Upsert filters by Type = "SOW" to avoid collisions with Proposal or Contract records
- [ ] If "Founder OS HQ - Deliverables" does not exist, falls back to "SOW Generator - Outputs"
- [ ] If neither database exists, Notion tracking is skipped silently (no error, no lazy creation)

---

### Test 9: Graceful degradation when Notion is not configured

**Acceptance Criterion Covered**: #5 (graceful degradation path), #1, #2

**Setup**:
- Notion MCP is NOT configured (remove or omit `NOTION_API_KEY`)
- No `.sow-history` file in the output directory

**Command**:
```
/sow:generate "Build a reporting dashboard for a logistics company"
```

**Expected Behavior**:
- Command detects that Notion MCP is unavailable
- Outputs the message "Notion unavailable — proceeding without historical SOW context." (or equivalent — not an error, just a note)
- Proceeds to generate all 3 SOW options without any Notion dependency
- No error is thrown; generation completes successfully

**Pass Criteria**:
- [ ] No error thrown for missing Notion MCP
- [ ] A note is displayed indicating Notion is unavailable and generation will proceed
- [ ] Full 3-option SOW is generated and written to `./sow-output/`
- [ ] Comparison table is present in the output
- [ ] Recommended option is identified

---

### Test 10: `/sow:from-brief` with a Notion page URL

**Acceptance Criterion Covered**: #5 (Notion integration), #1, #2

**Setup**:
- Notion MCP configured with a valid `NOTION_API_KEY`
- A valid Notion page exists that contains a project brief (client name, description, budget, or timeline text)
- Replace `[notion-page-url]` below with the actual URL of that page

**Command**:
```
/sow:from-brief https://www.notion.so/[workspace]/[page-id]
```

**Expected Behavior**:
- Command uses `notion-fetch` to load the page content
- Brief confirmation block is displayed showing data extracted from the Notion page:
  - Client name (from page title or "Client:" field)
  - Source URL
  - Project description summary
  - Budget and timeline if present in the page
- SOW is generated from the Notion page content

**Pass Criteria**:
- [ ] "Brief Loaded" confirmation block is displayed
- [ ] Confirmation block shows the Notion URL as the source
- [ ] Client name is extracted from the page (not empty or "Not specified" if the page contains a client name)
- [ ] SOW is generated with 3 options
- [ ] Output file is written to `./sow-output/`

**Failure Conditions** (test these as sub-cases if possible):
- [ ] If Notion gws CLI is unavailable or authentication not configured and a Notion URL is provided: command halts with message referencing INSTALL.md (not a generic error)
- [ ] If the page URL is inaccessible: command halts with message "Could not access Notion page: [url]"

---

## Section 4: Output Quality Tests

### Test 11: Output file written to correct path with correct filename pattern

**Acceptance Criterion Covered**: #6 — Outputs DOCX-ready Markdown file

**Setup**:
1. Create a directory at `./sow-test-output/` (or let the command create it)
2. Note today's date in YYYY-MM-DD format for filename verification

**Command**:
```
/sow:generate "Build an internal HR tool for employee onboarding and offboarding" --output=./sow-test-output/ --client="Acme"
```

**Expected Behavior**:
- Output directory `./sow-test-output/` is created if it does not exist
- SOW file is written at `./sow-test-output/sow-acme-[YYYY-MM-DD].md`
- Date in the filename matches today's date
- Output summary block confirms the correct file path

**Pass Criteria**:
- [ ] File exists at `./sow-test-output/sow-acme-[YYYY-MM-DD].md`
- [ ] Filename uses format `sow-[client-slug]-[YYYY-MM-DD].md` exactly
- [ ] Client slug is "acme" (lowercase, spaces replaced with hyphens)
- [ ] Date matches today's date in YYYY-MM-DD format
- [ ] File is non-empty (greater than 500 characters)
- [ ] Output summary block shows the correct file path

---

### Test 12: Markdown output is client-ready and structurally valid

**Acceptance Criterion Covered**: #6 — Outputs DOCX-ready Markdown (correct structure for Pandoc conversion)

**Setup**:
- Run Test 11 first to produce the output file
- Open the generated `.md` file in any Markdown viewer (VS Code preview, Typora, GitHub, etc.)

**Command**:
```
/sow:generate "Build an internal HR tool for employee onboarding and offboarding" --output=./sow-test-output/ --client="Acme"
```

**Expected Behavior**:
- All Markdown tables render without broken columns or misaligned pipes
- Section headings use proper heading hierarchy (`#`, `##`, `###`)
- Option names in the document use professional package names (e.g., "Foundation Package", "Growth Package", "Transformation Package") — not generic labels like "Option A — Conservative"
- Pricing tables are internally consistent: line item totals add up to the subtotal; subtotal plus tax/margin equals the stated total
- The document can be converted to DOCX via Pandoc without structural errors: `pandoc sow-acme-[date].md -o sow-acme-[date].docx`

**Pass Criteria**:
- [ ] All tables in the document render without broken formatting in a Markdown viewer
- [ ] Document uses heading hierarchy consistently (`#` for document title, `##` for major sections, `###` for option sections)
- [ ] Option names are professional package names, not "conservative/balanced/ambitious" or "Option A/B/C"
- [ ] Each pricing table's line item totals are internally consistent (no math errors)
- [ ] Comparison table renders correctly (3 data columns, all cells populated)
- [ ] Pandoc conversion produces a `.docx` file without fatal errors (warnings acceptable)
- [ ] Generated DOCX contains at least 3 section headings corresponding to the 3 options

---

## Known Limitations

The following behaviors are by design and are not defects:

- **Both modes write to Notion when available.** In both single-agent and `--team` mode, the plugin writes to the consolidated "Founder OS HQ - Deliverables" database with Type="SOW" if the database exists. Falls back to legacy "SOW Generator - Outputs" database if HQ DB not found. If neither exists, Notion tracking is skipped silently. The plugin does NOT lazy-create either database.

- **DOCX export requires Pandoc.** The plugin outputs Markdown (`.md`). To produce a true DOCX file for clients, convert using: `pandoc sow-[client]-[date].md -o sow-[client]-[date].docx`. This is intentional — no external binary dependencies are bundled with the plugin.

- **Historical SOW context improves quality but is not required.** If Notion is unavailable or contains no SOW pages, the plugin proceeds without calibration. Output quality may be lower for edge-case pricing or novel project types.

- **Minimum 2 of 3 scope proposals required in team mode.** If all 3 Phase 1 scope agents run but only 1 succeeds, the pipeline halts rather than synthesizing from a single proposal. 2 of 3 succeeding is acceptable — sow-lead will note the missing proposal in its output.

- **`/sow:from-brief` with a Notion URL requires Notion MCP.** If Notion gws CLI is unavailable or authentication not configured, the command halts immediately and references INSTALL.md. There is no fallback for Notion URL inputs.

- **Interactive mode (no brief argument) is not covered in this test plan.** When `/sow:generate` is run without a brief argument and without `--team`, the plugin asks the user a series of discovery questions. This interactive flow is validated manually during user acceptance testing, not via automated integration tests.

---

## Acceptance Criteria Coverage

| Criterion | Test Scenario(s) |
|-----------|-----------------|
| 1. `/sow:generate [brief]` creates 3 options | Tests 1, 5, 6, 7 |
| 2. Each option: scope, timeline, deliverables, price | Tests 2, 5, 6 |
| 3. Risk assessment per option | Test 3 |
| 4. Comparison table across options | Test 4 |
| 5. Agent Teams: learn from historical SOWs (Notion / context) | Tests 7, 8, 8b, 9, 10 |
| 6. Outputs DOCX-ready Markdown | Tests 11, 12 |
