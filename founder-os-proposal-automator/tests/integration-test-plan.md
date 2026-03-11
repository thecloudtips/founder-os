# Integration Test Plan: Proposal Automator

## Overview

This test plan covers the two commands (`/proposal:create`, `/proposal:from-brief`), CRM context resolution, file output, Notion DB integration, and graceful degradation paths.

## Test Environment

- **Required MCP**: Filesystem
- **Optional MCP**: Notion (with CRM Pro databases)
- **Optional CLI**: gws CLI (for Google Drive storage)
- **Test data**: Sample brief files in various formats (.md, .txt)

---

## Test Scenarios

### Scenario 1: Basic Interactive Proposal Creation

**Command**: `/proposal:create "Test Client"`
**Prerequisites**: Filesystem MCP available, Notion unavailable
**Steps**:
1. Invoke `/proposal:create "Test Client"`
2. Respond to interactive prompts with project details
3. Verify proposal file generated at `proposals/proposal-test-client-[date].md`
4. Verify brief file generated at `proposals/brief-test-client-[date].md`

**Expected**:
- Proposal contains all 7 sections in correct order
- 3 pricing packages present with comparison table
- Professional package marked as recommended
- Brief file follows SOW-compatible format
- No Notion tracking attempted (unavailable)
- Output summary displays package comparison table

---

### Scenario 2: Proposal with CRM Context

**Command**: `/proposal:create "Existing Client"`
**Prerequisites**: Filesystem MCP + Notion MCP with CRM Pro databases containing client data
**Steps**:
1. Ensure CRM Pro "Companies" database has a record for "Existing Client"
2. Invoke `/proposal:create "Existing Client"`
3. Verify CRM context appears in Cover Letter and Understanding sections

**Expected**:
- Cover Letter references relationship history or past projects
- Understanding & Approach section incorporates industry/client context
- Sources Used includes "CRM" in output summary
- Notion DB record created with Sources Used: ["CRM", "Interactive"]

---

### Scenario 3: Proposal from Brief File

**Command**: `/proposal:from-brief test-brief.md`
**Prerequisites**: Filesystem MCP available, brief file exists
**Steps**:
1. Create `test-brief.md` with client name, project overview, deliverables, and constraints
2. Invoke `/proposal:from-brief test-brief.md`
3. Verify client name extracted correctly
4. Verify proposal reflects brief contents

**Expected**:
- Client name extracted from brief (or prompted if not found)
- Deliverables match those listed in brief
- Constraints (budget, timeline) reflected in pricing and timeline sections
- Sources Used includes "Brief File"

---

### Scenario 4: Proposal from Brief with Client Override

**Command**: `/proposal:from-brief notes.md --client="Override Corp"`
**Prerequisites**: Filesystem MCP available
**Steps**:
1. Create `notes.md` with a different client name in the content
2. Invoke with `--client="Override Corp"`
3. Verify "Override Corp" is used throughout, not the name in the file

**Expected**:
- All sections reference "Override Corp"
- File slug uses "override-corp"
- Brief file Client section shows "Override Corp"

---

### Scenario 5: Custom Output Directory

**Command**: `/proposal:create "Dir Test" --output=./custom-output/`
**Prerequisites**: Filesystem MCP available
**Steps**:
1. Invoke with custom output path
2. Verify directory created if it doesn't exist
3. Verify files saved to custom path

**Expected**:
- `custom-output/proposal-dir-test-[date].md` exists
- `custom-output/brief-dir-test-[date].md` exists
- Output summary shows correct paths

---

### Scenario 6: Proposal from Existing Brief with --brief Flag

**Command**: `/proposal:create "Brief Client" --brief=existing-brief.md`
**Prerequisites**: Brief file exists
**Steps**:
1. Create `existing-brief.md` with project details
2. Invoke `/proposal:create "Brief Client" --brief=existing-brief.md`
3. Verify no interactive prompts (brief provides the data)

**Expected**:
- Brief content used instead of interactive collection
- Proposal reflects brief contents
- Sources Used includes "Brief File"

---

### Scenario 7: Notion DB Discovery — HQ Deliverables

**Command**: `/proposal:create "DB Test"`
**Prerequisites**: Notion MCP available, "Founder OS HQ - Deliverables" DB exists
**Steps**:
1. Invoke command with Notion available
2. Verify plugin discovers "Founder OS HQ - Deliverables" database
3. Verify record inserted with Type="Proposal" and Status: "Draft"

**Expected**:
- Plugin writes to "Founder OS HQ - Deliverables" (not legacy DB)
- Record has: Type=Proposal, Project Title, Client Name, Status=Draft, Package Selected=None, Generated At=today
- File paths recorded correctly
- No database creation attempted

---

### Scenario 8: Notion DB Idempotent Upsert with Type Filter

**Command**: `/proposal:create "DB Test"` (run twice)
**Prerequisites**: Notion MCP available, "Founder OS HQ - Deliverables" DB exists with record from Scenario 7
**Steps**:
1. Run `/proposal:create "DB Test"` with same project title as Scenario 7
2. Verify existing record updated, not duplicated
3. Verify upsert filters by Type="Proposal" to avoid collisions with other deliverable types

**Expected**:
- Only one record exists for this Client Name + Project Title + Type=Proposal combination
- Generated At updated to latest run
- File paths updated to latest files
- Other deliverable types with same Client Name + Project Title are not affected

---

### Scenario 8b: Legacy DB Fallback

**Command**: `/proposal:create "Legacy Test"`
**Prerequisites**: Notion MCP available, "Founder OS HQ - Deliverables" does NOT exist, legacy "Proposal Automator - Proposals" DB exists
**Steps**:
1. Invoke command with Notion available
2. Verify plugin falls back to legacy database

**Expected**:
- Plugin searches for "Founder OS HQ - Deliverables" first
- Not found — falls back to "Proposal Automator - Proposals"
- Record created in legacy DB (no Type property set)
- No database creation attempted

---

### Scenario 8c: No DB Exists — Skip Notion

**Command**: `/proposal:create "No DB Test"`
**Prerequisites**: Notion MCP available, neither "Founder OS HQ - Deliverables" nor "Proposal Automator - Proposals" exists
**Steps**:
1. Invoke command with Notion available but no matching databases
2. Verify Notion tracking is skipped gracefully

**Expected**:
- Plugin searches for both databases, finds neither
- No database created (no lazy creation)
- Proposal files still generated successfully
- Output shows "Saved to Notion: No" with note about missing database

---

### Scenario 8d: Company and Deal Relations

**Command**: `/proposal:create "Existing Client"`
**Prerequisites**: Notion MCP available, "Founder OS HQ - Deliverables" DB exists, CRM Pro "Companies" DB has record for "Existing Client", CRM Pro "Deals" DB has a deal for "Existing Client"
**Steps**:
1. Invoke command for a client that exists in CRM Pro
2. Verify Company relation is set on the deliverable record
3. Verify Deal relation is set on the deliverable record

**Expected**:
- Record in "Founder OS HQ - Deliverables" has Company relation linked to the matching Companies record
- Record has Deal relation linked to the matching Deals record
- Type is set to "Proposal"

---

### Scenario 8e: Company Not Found — Empty Relations

**Command**: `/proposal:create "Unknown Client"`
**Prerequisites**: Notion MCP available, "Founder OS HQ - Deliverables" DB exists, no CRM Pro record for "Unknown Client"
**Steps**:
1. Invoke command for a client not in CRM Pro
2. Verify relation properties are left empty

**Expected**:
- Record created in "Founder OS HQ - Deliverables" with Type="Proposal"
- Company relation is empty (not a placeholder)
- Deal relation is empty (not a placeholder)
- No error or warning about missing relations

---

### Scenario 9: Graceful Degradation — Notion Unavailable

**Command**: `/proposal:create "No Notion Client"`
**Prerequisites**: Filesystem MCP available, Notion MCP unavailable
**Steps**:
1. Invoke command without Notion
2. Verify proposal generates successfully
3. Verify warning about Notion in output

**Expected**:
- Full proposal generated (all 7 sections)
- No CRM context in Cover Letter (generic opening)
- Output shows "Saved to Notion: No"
- Warning message about Notion configuration

---

### Scenario 10: Graceful Degradation — Brief File Not Found

**Command**: `/proposal:from-brief nonexistent-file.md`
**Prerequisites**: File does not exist
**Steps**:
1. Invoke with nonexistent file path

**Expected**:
- Clear error message: "File not found: nonexistent-file.md"
- Suggestion to check file path
- No proposal generated

---

### Scenario 11: Graceful Degradation — Brief Lacks Key Info

**Command**: `/proposal:from-brief minimal-brief.md`
**Prerequisites**: Brief file exists with only a project description (no client name, no deliverables)
**Steps**:
1. Create `minimal-brief.md` with just a paragraph of text
2. Invoke command

**Expected**:
- Prompted for client name (not found in brief)
- Proposal generated with available data
- Missing sections marked with `<!-- NEEDS REVIEW -->` comments
- Output summary notes what information was missing

---

### Scenario 12: SOW Brief Compatibility

**Command**: `/proposal:create "SOW Test"` then `/sow:from-brief brief-sow-test-[date].md`
**Prerequisites**: Both P12 and P14 plugins installed
**Steps**:
1. Generate a proposal for "SOW Test"
2. Feed the generated brief file to `/sow:from-brief`
3. Verify SOW generator can parse the brief

**Expected**:
- Brief file has all required sections: Client, Project Overview, Deliverables, Constraints, Selected Package, Additional Context
- SOW generator successfully loads and processes the brief
- No parsing errors

---

### Scenario 13: Pricing Package Quality

**Command**: `/proposal:create "Pricing Test"`
**Steps**:
1. Generate a proposal
2. Examine the Pricing section

**Expected**:
- Comparison table leads with Scope, not Investment
- Professional package marked with ✓ in header
- Package names are outcome-based (not "Basic/Pro/Enterprise")
- Price spacing follows 1.5-2x ratio between tiers
- Each package has "Best for" description
- Payment terms tied to deliverable acceptance, not dates

---

### Scenario 14: Proposal Quality Checklist

**Command**: Any `/proposal:create` invocation
**Steps**:
1. Generate a proposal
2. Verify against the quality checklist from the proposal-writing skill

**Expected**:
- [ ] All 7 sections present in correct order
- [ ] Every deliverable has testable acceptance criteria
- [ ] Exclusions section covers at least 3 items
- [ ] Timeline maps every deliverable to a phase
- [ ] Pricing has exactly 3 packages with comparison table
- [ ] No placeholder text, TODO markers, or `[FILL IN]` remnants
- [ ] SOW-compatible brief file generated alongside proposal
- [ ] Client name appears consistently throughout

---

## Coverage Matrix

| Feature | Scenarios |
|---------|-----------|
| Interactive creation | 1, 2, 5, 6 |
| Brief file input | 3, 4, 6, 11 |
| Notion page input | (via `/proposal:from-brief` with URL) |
| CRM context | 2, 9 |
| Custom output | 5 |
| HQ Deliverables DB | 7, 8, 8d, 8e |
| Legacy DB fallback | 8b |
| No DB skip | 8c |
| Notion DB upsert | 8 |
| Company/Deal relations | 8d, 8e |
| Graceful degradation | 8c, 9, 10, 11 |
| SOW compatibility | 12 |
| Pricing quality | 13 |
| Overall quality | 14 |
