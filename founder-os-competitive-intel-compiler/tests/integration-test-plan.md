# Integration Test Plan: Competitive Intel Compiler

Plugin #15 | Standalone | Claude Code

## Prerequisites

- Claude Code with WebSearch tool enabled
- Filesystem MCP configured (pointing to a test directory)
- Node.js 18+ and npx available

## Test Scenarios

### Scenario 1: Single Competitor Research — Basic
**Command**: `/compete:research Notion`
**Preconditions**: Filesystem MCP configured, internet access available
**Expected behavior**:
- Executes 4-6 web searches
- Report contains all required sections: Executive Summary, Pricing, Key Features, Positioning & Messaging, Customer Reviews, Recent News, Strategic Recommendations
- Pricing is normalized (per user/month format)
- Review scores show platform source (G2 or Capterra)
- Report saved to `competitive-intel/notion-[date].md`
- Notion record created in "Founder OS HQ - Research" database with Type="Competitive Analysis" and Company relation linked (if Notion configured)
**Pass criteria**: Complete report in chat + file saved locally

---

### Scenario 2: Single Competitor Research with Self-Comparison
**Command**: `/compete:research Linear --your-product="Project management for agencies, $49/month flat"`
**Preconditions**: Same as Scenario 1
**Expected behavior**:
- Executes full research (same as Scenario 1)
- Report includes a "vs You" section with comparison table
- Table shows where user wins (✅) and where Linear wins
- Differentiation opportunities identified
- Strategic recommendations reference the product context
- vs-You section not present when --your-product is omitted
**Pass criteria**: "vs You" section appears in report with grounded comparison

---

### Scenario 3: Multi-Competitor Matrix
**Command**: `/compete:matrix Asana ClickUp Monday`
**Preconditions**: Filesystem MCP configured, internet access
**Expected behavior**:
- Runs fresh searches for all 3 companies independently
- Matrix contains 7 rows: Pricing, Target Market, Key Features, Positioning, Review Score, Strengths, Weaknesses
- 3 company columns (one per company)
- All cells populated with normalized data
- Matrix saved to `competitive-intel/matrix-[date].md`
- Analysis summary below the matrix (market overview, key differentiators, whitespace opportunities)
**Pass criteria**: Full 7×3 matrix in chat + file saved locally

---

### Scenario 4: Matrix with Self-Comparison ('You' Column)
**Command**: `/compete:matrix Figma Sketch --your-product="Design handoff for non-designers, free tier"`
**Preconditions**: Same as Scenario 3
**Expected behavior**:
- Full matrix for Figma and Sketch
- "You" column added as rightmost column
- Advantage cells marked with ✅
- Whitespace opportunities marked with 💡
- "Positioning Opportunity" row at bottom with recommendation
- Recommendations section tailored to product description
**Pass criteria**: Matrix includes "You" column with advantage/whitespace markers

---

### Scenario 5: Graceful Degradation — Notion Unavailable
**Command**: `/compete:research Salesforce` (with Notion MCP deliberately unavailable)
**Preconditions**: Notion MCP removed from .mcp.json or NOTION_API_KEY unset
**Expected behavior**:
- Research and report generation complete normally
- Report displayed in full in chat
- File saved to local filesystem (competitive-intel/ directory)
- Warning displayed: "Notion unavailable — report displayed in chat and saved to [file path]"
- Command does NOT abort or fail
- No error stack traces
**Pass criteria**: Complete report in chat + local file saved, single graceful warning

---

### Scenario 6: Graceful Degradation — Failed Web Search
**Command**: `/compete:research [obscure company with no web presence]`
**Preconditions**: Standard setup
**Expected behavior**:
- Attempts alternate query variants before declaring no data
- If still no results, marks affected dimension as "Unable to gather data — no search results found"
- Report still generates with available data
- No fabricated pricing, features, or review scores
- Command does NOT abort
**Pass criteria**: Partial report produced with "Unable to gather data" for missing dimensions, no fabricated facts

---

### Scenario 7: Idempotent Notion Writes
**Command**: `/compete:research Notion` (run twice)
**Preconditions**: Notion MCP configured, "Founder OS HQ - Research" database exists
**Expected behavior**:
- First run creates a new record in "Founder OS HQ - Research" with Type="Competitive Analysis" and Company relation linked
- Second run updates the existing record (matched by Company Name + Type="Competitive Analysis", no duplicate created)
- Database remains at 1 record for "Notion" with Type="Competitive Analysis" after both runs
**Pass criteria**: Single Notion record exists after two runs of the same company

---

### Scenario 9: HQ Database Fallback to Legacy Name
**Command**: `/compete:research Notion` (with "Founder OS HQ - Research" absent, "Competitive Intel Compiler - Research" present)
**Preconditions**: Notion MCP configured, legacy database exists, HQ database does not
**Expected behavior**:
- Searches for "Founder OS HQ - Research" first — not found
- Falls back to "Competitive Intel Compiler - Research" — found
- Creates/updates record in the legacy database
- No new database created
**Pass criteria**: Record saved to legacy database, no database creation attempted

---

### Scenario 10: No Research Database Exists
**Command**: `/compete:research Notion` (with neither HQ nor legacy database present)
**Preconditions**: Notion MCP configured, no Research database exists
**Expected behavior**:
- Searches for "Founder OS HQ - Research" — not found
- Falls back to "Competitive Intel Compiler - Research" — not found
- Skips Notion integration
- Warns: "Research database not found — provision from HQ template. Report saved to [file path]."
- Report still displayed in chat and saved to local file
- Does NOT attempt to create a database
**Pass criteria**: Graceful skip with warning, no database creation, report still generated

---

### Scenario 8: Minimum Companies Validation for Matrix
**Command**: `/compete:matrix Notion` (only 1 company)
**Preconditions**: Standard setup
**Expected behavior**:
- Command detects fewer than 2 companies provided
- Prompts: "Please provide at least 2 company names to build a comparison matrix. Example: /compete:matrix Notion Linear Asana"
- Does not execute any web searches
- Does not create any files
**Pass criteria**: Prompt displayed, no searches executed, no files created

---

## Acceptance Criteria Coverage

| Spec Criterion | Covered By |
|----------------|-----------|
| `/compete:research [company]` gathers intel | Scenarios 1, 2 |
| Extracts: pricing, features, positioning, reviews | Scenarios 1, 2 |
| `/compete:matrix [companies...]` creates comparison | Scenarios 3, 4 |
| Identifies strengths/weaknesses vs you | Scenarios 2, 4 |
| Outputs structured report | Scenarios 1, 2, 3, 4 |
| Graceful degradation without Notion | Scenario 5 |
| Handles missing data gracefully | Scenario 6 |
| Idempotent writes | Scenario 7 |
| HQ DB discovery with legacy fallback | Scenarios 9, 10 |
| Input validation | Scenario 8 |

## Notes

- WebSearch is a built-in tool — if it's unavailable, verify Claude Code's internet access setting
- Filesystem path in `.mcp.json` must point to an existing directory; the plugin creates `competitive-intel/` subdirectory automatically
- Pricing data changes frequently — test results may differ from run to run; validate format, not specific values
- Review scores from G2/Capterra may fluctuate; validate presence and format (X.X/5.0), not specific numbers
