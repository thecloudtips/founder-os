# Integration Test Plan: Contract Analyzer

## Overview

This test plan validates the P13 Contract Analyzer plugin against all acceptance criteria. Tests cover both commands (`/contract:analyze`, `/contract:compare`), both skills (contract-analysis, legal-risk-detection), all supported file formats, Notion integration, and edge cases.

## Prerequisites

- Plugin installed in Claude Code
- Filesystem MCP configured with access to test contract files
- Notion MCP configured (for Notion integration tests)
- Sample contracts available in supported formats (PDF, DOCX, MD, TXT)

---

## Test 1: Basic Contract Analysis

**Priority**: P0
**Command**: `/contract:analyze sample-service-agreement.pdf`
**Expected**:
- File read successfully
- Contract type detected (Service Agreement)
- Parties identified
- Key terms extracted for all 7 categories
- Risk flags generated with RAG severity
- Overall risk level calculated
- Structured report displayed

---

## Test 2: Contract Type Detection

**Priority**: P0
**Setup**: Prepare sample contracts for each type
**Commands**:
- `/contract:analyze nda-sample.pdf` → detects "NDA"
- `/contract:analyze freelance-contract.md` → detects "Freelance"
- `/contract:analyze agency-agreement.docx` → detects "Agency"
- `/contract:analyze employment-offer.txt` → detects "Employment"
**Expected**: Each contract correctly classified by type

---

## Test 3: File Format Support

**Priority**: P0
**Commands**:
- `/contract:analyze contract.pdf` → PDF processed
- `/contract:analyze contract.docx` → DOCX processed
- `/contract:analyze contract.md` → Markdown processed
- `/contract:analyze contract.txt` → Text processed
**Expected**: All 4 formats read and analyzed without errors

---

## Test 4: Unsupported File Format

**Priority**: P1
**Command**: `/contract:analyze spreadsheet.xlsx`
**Expected**: Clear error: "Unsupported file format. Supported: PDF, DOCX, MD, TXT."

---

## Test 5: File Not Found

**Priority**: P1
**Command**: `/contract:analyze /nonexistent/path/contract.pdf`
**Expected**: Clear error: "File not found at [path]."

---

## Test 6: Risk Detection - Red Flags

**Priority**: P0
**Setup**: Contract with known Red-flag clauses (unlimited liability, one-sided indemnification, perpetual IP assignment)
**Command**: `/contract:analyze risky-contract.pdf`
**Expected**:
- Overall risk level = Red
- Red flags detected for unlimited liability, one-sided indemnification, perpetual IP
- Each flag includes: flag name, severity, category, clause excerpt, mitigation
- Disclaimer present at top of report
- Recommendations prioritize Red items

---

## Test 7: Risk Detection - Clean Contract

**Priority**: P1
**Setup**: Contract with balanced, standard terms
**Command**: `/contract:analyze balanced-contract.md`
**Expected**:
- Overall risk level = Green
- Few or no flags
- Report states: "No significant risk flags detected"

---

## Test 8: Contract Comparison - Standard Terms

**Priority**: P0
**Command**: `/contract:compare sample-contract.pdf`
**Expected**:
- Full analysis performed (same as /contract:analyze)
- Standard terms loaded from built-in template
- Term-by-term comparison table displayed
- Deviations flagged with severity
- Counter-proposals provided for Yellow and Red deviations
- "Compared Against: Built-in standard terms" in header

---

## Test 9: Contract Comparison - Custom Standards

**Priority**: P1
**Command**: `/contract:compare contract.pdf --standards=my-standards.md`
**Expected**:
- Custom standards file loaded
- Comparison uses custom thresholds
- "Compared Against: Custom: my-standards.md" in header

---

## Test 10: Custom Standards File Not Found

**Priority**: P1
**Command**: `/contract:compare contract.pdf --standards=/nonexistent/standards.md`
**Expected**:
- Warning: "Custom standards file not found. Using built-in standard terms."
- Analysis proceeds with built-in defaults

---

## Test 11: Checklist Coverage

**Priority**: P1
**Command**: `/contract:analyze incomplete-contract.md`
**Setup**: Contract missing Dispute Resolution, Non-Compete, and Warranty sections
**Expected**:
- Checklist Gaps section lists: Dispute Resolution, Non-Compete, Warranty
- Terms for missing categories show "Not found in contract"

---

## Test 12: Notion Database Discovery (HQ Deliverables)

**Priority**: P0
**Setup**: Ensure "Founder OS HQ - Deliverables" database exists in Notion
**Command**: `/contract:analyze sample-contract.pdf`
**Expected**:
- Plugin searches for "Founder OS HQ - Deliverables" first
- Database found
- Analysis record created with Type = "Contract"
- Contract Type mapped correctly (e.g., "Service Agreement" → "SaaS")
- Company relation set if contract party matches CRM
- "Saved to Notion: Yes" in report header

---

## Test 13: Notion Idempotent Updates

**Priority**: P1
**Command**: `/contract:analyze sample-contract.pdf` (run twice)
**Expected**:
- First run: Creates record in Notion with Type = "Contract"
- Second run: Updates existing record (same Title, filtered by Type = "Contract")
- No duplicate records created

---

## Test 14: Graceful Degradation - Without Notion

**Priority**: P0
**Setup**: Notion MCP disconnected
**Command**: `/contract:analyze sample-contract.pdf`
**Expected**:
- Full analysis displayed in chat
- Warning: "Notion unavailable — displaying results in chat"
- "Saved to Notion: No" in report header
- No error or crash

---

## Test 14b: Fallback to Legacy Database

**Priority**: P1
**Setup**: "Founder OS HQ - Deliverables" does NOT exist, but legacy "Contract Analyzer - Analyses" does
**Command**: `/contract:analyze sample-contract.pdf`
**Expected**:
- Plugin searches for "Founder OS HQ - Deliverables" — not found
- Plugin falls back to "Contract Analyzer - Analyses"
- Record saved to legacy database (no Type or Company relation fields)
- "Saved to Notion: Yes" in report header

---

## Test 15: Graceful Degradation - Without Filesystem

**Priority**: P0
**Setup**: Filesystem MCP disconnected
**Command**: `/contract:analyze contract.pdf`
**Expected**:
- Error: Cannot read file without Filesystem MCP
- Clear guidance to configure Filesystem MCP

---

## Test 16: Compare Sets Notion Fields Correctly

**Priority**: P1
**Command**: `/contract:compare sample-contract.pdf`
**Expected**:
- Notion record created in "Founder OS HQ - Deliverables" with Type = "Contract"
- Key Terms field includes deviation summary (appended after 7 categories)
- Risk Level reflects merged analysis (standalone + comparison)
- Company relation set if contract party matches CRM

---

## Test 17: Key Term Extraction Accuracy

**Priority**: P0
**Setup**: Contract with known terms (payment: net 30, $50,000; term: 12 months with auto-renewal; IP: work-for-hire)
**Command**: `/contract:analyze known-terms-contract.md`
**Expected**:
- Payment row shows: "$50,000, net 30"
- Duration row shows: "12 months, auto-renewal"
- IP row shows: "work-for-hire, client owns deliverables"
- All 7 categories have extracted data

---

## Test 18: Empty File

**Priority**: P2
**Command**: `/contract:analyze empty-file.txt`
**Expected**: Error: "File is empty or contains no readable content."

---

## Test 19: Very Short Document

**Priority**: P2
**Setup**: Contract under 500 words
**Command**: `/contract:analyze short-agreement.md`
**Expected**:
- Warning: "Document is unusually short — analysis may be incomplete"
- Analysis proceeds with available content
- Missing categories noted

---

## Test 20: Non-English Contract

**Priority**: P2
**Command**: `/contract:analyze german-contract.pdf`
**Expected**:
- Warning: "Contract appears to be in a non-English language. Analysis is best-effort."
- Attempts extraction (reduced accuracy expected)

---

## Test 21: Contract with Amendments

**Priority**: P2
**Setup**: Contract with attached amendment/addendum
**Command**: `/contract:analyze contract-with-amendment.md`
**Expected**:
- Amendment detected and analyzed as part of the whole
- Terms from amendment override base contract where applicable

---

## Test 22: No Argument Provided

**Priority**: P1
**Command**: `/contract:analyze`
**Expected**: Prompt: "Provide the path to the contract file to analyze. Supported formats: PDF, DOCX, MD, TXT."

---

## Test Summary

| # | Test Case | Priority | Acceptance Criterion |
|---|-----------|----------|---------------------|
| 1 | Basic analysis | P0 | Core analysis pipeline works |
| 2 | Type detection | P0 | All 5 contract types detected |
| 3 | File formats | P0 | PDF, DOCX, MD, TXT all work |
| 4 | Unsupported format | P1 | Clear error message |
| 5 | File not found | P1 | Clear error message |
| 6 | Red flag detection | P0 | Risky clauses flagged correctly |
| 7 | Clean contract | P1 | Green assessment for balanced terms |
| 8 | Standard comparison | P0 | Term-by-term comparison works |
| 9 | Custom standards | P1 | --standards flag works |
| 10 | Missing standards file | P1 | Graceful fallback to built-in |
| 11 | Checklist coverage | P1 | Missing sections detected |
| 12 | HQ DB discovery | P0 | Finds HQ Deliverables, writes Type=Contract |
| 13 | Idempotent updates | P1 | No duplicates on re-run (Title + Type filter) |
| 14 | No Notion | P0 | Works without Notion |
| 14b | Legacy DB fallback | P1 | Falls back to Contract Analyzer - Analyses |
| 15 | No Filesystem | P0 | Clear error |
| 16 | Compare Notion fields | P1 | Compared To Standard = true |
| 17 | Extraction accuracy | P0 | Known terms correctly extracted |
| 18 | Empty file | P2 | Error message |
| 19 | Short document | P2 | Warning + best-effort |
| 20 | Non-English | P2 | Warning + best-effort |
| 21 | Amendments | P2 | Analyzed as whole |
| 22 | No argument | P1 | User prompted |
