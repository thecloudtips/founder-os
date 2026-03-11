---
name: Contract Analysis
description: "Extracts structured terms from legal contracts across 7 categories (Payment, Duration, IP, Confidentiality, Liability, Termination, Warranty). Activates when the user has a contract to analyze, wants to extract terms, review an agreement, or asks 'what does this contract say?' Supports PDF, DOCX, MD, and TXT formats with auto contract-type detection."
---

## Overview

Recognize the structure of legal contracts and extract key terms from them. Accept contract files in PDF, DOCX, MD, or TXT format via the Filesystem MCP server. Detect the contract type from content signals, identify standard sections, extract terms across seven categories, and produce a structured analysis report. Delegate risk-level assessment and detailed clause risk flagging to the legal-risk-detection skill. Store analysis results in the consolidated "Founder OS HQ - Deliverables" Notion database (Type = "Contract") for historical reference and cross-contract comparison.

This skill handles contract parsing, type detection, structure recognition, and term extraction only. Risk scoring, clause-level risk flags, and comparison to standard terms are the responsibility of the legal-risk-detection skill. Output formatting for chat display and Notion storage is handled by the command layer.

## Supported File Formats

Read contract files from the local filesystem using the Filesystem MCP server. Support these formats:

| Format | Read Method | Notes |
|--------|-------------|-------|
| PDF | Claude reads the file content directly | Native text PDFs yield highest accuracy; scanned PDFs rely on Claude's vision capabilities |
| DOCX | Claude reads the file content directly | Extract body text; ignore headers/footers/tracked changes for term extraction |
| MD | Read via Filesystem MCP as plain text | Treat full file content as contract text |
| TXT | Read via Filesystem MCP as plain text | Treat full file content as contract text |

For all formats, treat the entire file content as the contract text. Do not attempt to process ZIP, XLSX, CSV, or image-only files (JPG, PNG). If given an unsupported format, return an error message listing the four supported formats and stop.

When a file path is provided, resolve it relative to the current working directory. Use `${CLAUDE_PLUGIN_ROOT}` as the base for any plugin-internal file references.

## Contract Type Detection

Auto-detect the contract type from content signals present in the document. Scan the full text for the following indicators and assign the best-matching type:

| Type | Primary Signals | Secondary Signals |
|------|----------------|-------------------|
| NDA (Non-Disclosure Agreement) | "non-disclosure", "confidential information", "nondisclosure agreement" | "disclosing party", "receiving party", "proprietary information", "trade secrets" |
| Service Agreement | "scope of work", "scope of services", "service provider", "deliverables" | "service level", "acceptance criteria", "change order", "professional services" |
| Freelance Contract | "freelancer", "independent contractor", "contractor agrees", "1099" | "project-based", "no employment relationship", "own tools and equipment" |
| Agency Agreement | "agency", "principal and agent", "agency of record", "retainer" | "campaign", "media buy", "creative services", "account management" |
| Employment Contract | "employment", "employee", "salary", "benefits", "at-will" | "start date", "probationary period", "non-compete", "offer of employment" |
| Other | None of the above patterns match with sufficient confidence | Default when signals are ambiguous or mixed |

Apply these detection rules in order:

1. Count signal matches for each type across the full document text using case-insensitive matching.
2. If NDA signals appear 3+ times and no other type exceeds 2 matches, classify as NDA.
3. If Employment signals appear 2+ times and the document contains "salary" or "benefits", classify as Employment.
4. Among Service Agreement, Freelance Contract, and Agency Agreement, pick the type with the most signal matches. Break ties by favoring Service Agreement as the most common.
5. If no type accumulates more than 1 signal match, classify as Other and note "Contract type could not be determined with confidence" in the analysis output.

## Contract Structure Recognition

Identify the standard sections present in the contract. Contracts vary in formatting -- handle all of these structural patterns:

- **Numbered clauses**: "1. Definitions", "2. Scope of Work", "Section 3 - Payment"
- **Lettered sub-clauses**: "(a)", "(b)", "(c)" or "a.", "b.", "c." nested under numbered sections
- **Article format**: "ARTICLE I", "ARTICLE II", "Article 1"
- **Un-numbered paragraphs**: Sections separated by bold headings or ALL-CAPS headings without numbering
- **Mixed format**: Some sections numbered, others not

Scan for and tag these standard contract sections when present:

| Section | Common Headings |
|---------|----------------|
| Parties | "Parties", "Between", preamble paragraph identifying signatories |
| Recitals / Background | "Recitals", "Background", "Whereas", "Purpose" |
| Definitions | "Definitions", "Defined Terms", "Interpretation" |
| Scope of Work | "Scope of Work", "Services", "Scope of Services", "Description of Work", "Deliverables" |
| Payment Terms | "Payment", "Compensation", "Fees", "Pricing", "Payment Terms" |
| Intellectual Property | "Intellectual Property", "IP Rights", "Ownership", "Work Product" |
| Confidentiality | "Confidentiality", "Non-Disclosure", "Confidential Information", "Trade Secrets" |
| Liability / Indemnification | "Liability", "Indemnification", "Indemnity", "Limitation of Liability", "Hold Harmless" |
| Termination | "Termination", "Term and Termination", "Cancellation", "Expiration" |
| Dispute Resolution | "Dispute Resolution", "Arbitration", "Governing Law", "Jurisdiction", "Mediation" |
| General / Miscellaneous | "General Provisions", "Miscellaneous", "Entire Agreement", "Severability", "Notices" |

Not all sections will appear in every contract. Report which sections were identified and which standard sections are missing. Missing critical sections (Scope of Work in a Service Agreement, Confidentiality in an NDA) are worth noting in the output.

## Key Term Categories

Extract terms across these seven categories. For each category, capture the specific values, conditions, and notable provisions found in the contract. Below is a summary of what to extract per category -- for detailed phrase patterns, example clause language, and extraction rules, see `${CLAUDE_PLUGIN_ROOT}/skills/contract/contract-analysis/references/clause-patterns.md`.

### 1. Payment

Extract: total amount or rate (hourly, fixed, retainer), payment schedule (milestone, monthly, upon completion), currency, late payment penalties or interest rates, expense reimbursement terms, invoicing requirements. When no explicit amount is stated (common in master agreements), note "Amount to be determined per SOW/Order."

### 2. Duration / Renewal

Extract: effective date (start date), end date or term length, auto-renewal provisions and their period, notice period required to prevent renewal, perpetual vs fixed-term distinction. Calculate the total initial term in months or years for the summary.

### 3. Intellectual Property (IP)

Extract: IP ownership assignment (who owns work product), work-for-hire designation, pre-existing IP carve-outs, license grants (scope, exclusivity, territory, duration), moral rights waivers, open-source restrictions. Note whether IP assignment is full ("all rights, title, and interest") or limited (license only).

### 4. Confidentiality

Extract: definition scope (what constitutes confidential information), confidentiality duration or survival period, permitted disclosures (employees, advisors, legal requirements), exclusions from confidentiality (public knowledge, independently developed, prior possession), obligations upon termination (return or destroy). Note whether obligations are mutual or one-way.

### 5. Liability

Extract: liability caps (aggregate maximum, per-incident caps), consequential damages exclusions, indemnification obligations (mutual vs one-way, scope of covered claims), insurance requirements (types, minimum coverage amounts). Flag uncapped liability or missing liability limitations.

### 6. Termination

Extract: termination for cause triggers (material breach, insolvency, non-payment), termination for convenience provisions, notice periods for each termination type, cure periods (time to fix a breach before termination is effective), post-termination obligations (data return, transition assistance, wind-down), survival clauses (which sections survive termination).

### 7. Warranty

Extract: representations and warranties made by each party, warranty disclaimers ("as is", "no warranty of fitness for a particular purpose"), warranty period or duration, remedies for breach of warranty, sole remedy limitations. Note whether warranties are mutual or one-sided.

## Output Structure

For each analyzed contract, produce a structured report containing these fields:

```
Contract Name:        [filename or document title]
Contract Type:        [detected type from the 6 categories]
Parties:              [list of identified parties with their roles]
Summary:              [2-3 sentence plain-English summary of what the contract does]
Key Terms:
  Payment:            [extracted payment terms or "Not specified"]
  Duration/Renewal:   [extracted duration terms or "Not specified"]
  IP:                 [extracted IP terms or "Not specified"]
  Confidentiality:    [extracted confidentiality terms or "Not specified"]
  Liability:          [extracted liability terms or "Not specified"]
  Termination:        [extracted termination terms or "Not specified"]
  Warranty:           [extracted warranty terms or "Not specified"]
Overall Risk Level:   [from legal-risk-detection skill: Low / Medium / High]
Risk Flags:           [list of flagged items from legal-risk-detection skill]
Recommendations:      [actionable recommendations based on analysis]
Sections Identified:  [list of detected standard sections]
Sections Missing:     [list of expected but absent sections for this contract type]
```

For the Summary field, write in plain English without legal jargon. A non-lawyer founder should understand what the contract covers, who the parties are, and what the core obligation is within 2-3 sentences.

For Recommendations, include up to 5 actionable items. Prioritize recommendations by impact: missing critical clauses first, then unusual terms, then suggestions for improvement. Each recommendation should state what to do, not just what is wrong.

## Notion Integration

### Database Discovery

On completion, create or update a record in the consolidated **"Founder OS HQ - Deliverables"** database with **Type = "Contract"**.

1. Search for "Founder OS HQ - Deliverables" database first.
2. If not found, fall back to legacy "Contract Analyzer - Analyses" database.
3. If neither exists, skip Notion tracking (do NOT lazy-create the database).

### Record Fields

Set these fields on every record:

- **Title** (title): Contract filename or document title (maps from legacy Contract Name).
- **Type**: "Contract" (select).
- **File Path** (rich_text): Original file path of the analyzed contract.
- **Contract Type** (select): Detected contract type. Map legacy values: "Service Agreement" → "SaaS", "Other" → "Vendor". Values "NDA", "Freelance", "Agency", "Employment" remain unchanged.
- **Key Terms** (rich_text): Formatted extraction of all 7 categories, including Summary text.
- **Risk Level** (select: Green, Yellow, Red): Overall RAG risk classification.
- **Risk Flags** (rich_text): List of identified risk flags with severity levels (JSON format).
- **Status**: "Draft" (select) on first creation; leave unchanged on updates.
- **Generated At** (date): Timestamp of analysis.

### Company Relation

When writing to "Founder OS HQ - Deliverables":
- **Company relation**: Extract party names from the contract. Look up each party in the CRM Pro "Companies" database (or "Founder OS HQ - Companies"). If a match is found, set the Company relation property to link to that company record.
- If no Company match is found, leave the relation property empty — never create placeholder records.

When writing to the legacy "Contract Analyzer - Analyses" database, skip the Company relation (property does not exist).

### Idempotent Updates

Upsert key: Title (case-insensitive). When upserting in "Founder OS HQ - Deliverables", also filter by Type = "Contract" to avoid collisions with other deliverable types (Proposal, SOW). When analyzing a contract that has been analyzed before (same filename), update the existing record rather than creating a duplicate.

### Notion Unavailable

When the Notion MCP server is not connected or neither database can be found:
- Output the full structured report directly to chat.
- Do not treat Notion unavailability as an error.
- Append a note: "Notion unavailable -- analysis displayed in chat only. Re-run with Notion connected to save."

## Edge Cases

### Empty or Corrupt Files

When the file content is empty or cannot be read:
- Return an error: "File is empty or could not be read. Verify the file path and format."
- Do not attempt to analyze empty content.

### Non-English Contracts

When the contract text is primarily in a language other than English:
- Warn: "This contract appears to be in [detected language]. Analysis accuracy may be reduced for non-English contracts."
- Attempt best-effort extraction. Many legal terms (IP, NDA, force majeure) appear in English or Latin even in non-English contracts.
- Set a lower confidence indicator in the output notes.

### Very Short Documents (< 500 Words)

When the document is fewer than 500 words:
- Warn: "Document is unusually short ([word count] words). This may be an incomplete contract, a summary, or a term sheet rather than a full agreement."
- Proceed with analysis but flag in Notes that the document may be incomplete.
- Expect fewer sections to be present.

### Contracts with Amendments or Addenda

When the document contains amendment or addendum language ("Amendment No.", "Addendum to", "This amendment modifies"):
- Analyze the complete document including amendments as a unified whole.
- Note in the summary that the contract includes amendments.
- When amendment language conflicts with original terms, extract the amended terms (latest version prevails) and note the conflict.

### Multi-Contract Files

When a single file contains multiple distinct contracts (e.g., a master agreement plus exhibits):
- Treat the entire file as one analysis unit.
- Identify exhibits and attachments as sub-sections in the structure.
- Extract terms from both the main agreement and its exhibits, noting which terms come from which section.

## Graceful Degradation

- **Filesystem unavailable**: Cannot proceed. Filesystem MCP is required to read the contract file. Report the error and stop.
- **Notion unavailable**: Output analysis to chat. Do not error.
- **legal-risk-detection skill unavailable**: Set Overall Risk Level to "Not assessed" and Risk Flags to empty. Note: "Risk assessment unavailable -- install legal-risk-detection skill for risk analysis." Proceed with all other extraction.
- **Ambiguous contract type**: Classify as Other, note the ambiguity, and proceed. Type detection failure does not block term extraction.
