# Quick Start: founder-os-contract-analyzer

> Analyze contracts, extract key terms, and flag legal risks in minutes.

## Overview

**Plugin #13** | **Pillar**: Code Without Coding | **Platform**: Claude Code

Contract Analyzer reads legal documents, extracts structured data across 7 key term categories, evaluates clauses for risk using Red-Amber-Green classification, and compares terms against standard freelancer/agency benchmarks.

### What This Plugin Does

- Extracts key terms from contracts (Payment, Duration, IP, Confidentiality, Liability, Termination, Warranty)
- Flags risky clauses with Red/Yellow/Green severity and plain-English explanations
- Compares contract terms against standard benchmarks with counter-proposals
- Saves analysis results to Notion for tracking (optional)

## Available Commands

| Command | Description |
|---------|-------------|
| `/contract:analyze [file-path]` | Analyze a contract and produce a structured risk report |
| `/contract:compare [file-path]` | Analyze and compare against standard terms with counter-proposals |

## Usage Examples

### Example 1: Analyze a Service Agreement

```
/contract:analyze ~/Documents/contracts/acme-service-agreement.pdf
```

**What happens:**
- Reads the PDF file
- Detects contract type (Service Agreement)
- Extracts key terms across 7 categories
- Flags risky clauses with RAG severity
- Produces a structured report with recommendations
- Saves to Notion (if configured)

### Example 2: Compare an NDA Against Standards

```
/contract:compare ~/contracts/nda-draft.docx
```

**What happens:**
- Performs full contract analysis (same as `/contract:analyze`)
- Loads the standard terms reference
- Compares each term against standard freelancer benchmarks
- Flags deviations with severity and counter-proposals
- Produces a comparison report showing where the contract differs

### Example 3: Compare with Custom Standards

```
/contract:compare ~/contracts/agency-agreement.md --standards=~/my-standards.md
```

**What happens:**
- Uses your custom standards file instead of the built-in defaults
- Flags deviations based on your specific risk tolerance

### Example 4: Analyze a Simple Text Contract

```
/contract:analyze agreement.txt
```

**What happens:**
- Works with plain text files (.txt, .md) just as well as PDFs

## Tips

- Start with `/contract:analyze` to understand the contract before using `/contract:compare`
- Red flags always mean "consult a lawyer before signing"
- Yellow flags are negotiation opportunities — use the counter-proposals provided
- Customize `templates/standard-terms.md` to match your business requirements
- Results are saved to Notion automatically when configured — review past analyses anytime

## Supported File Formats

| Format | Extension | Notes |
|--------|-----------|-------|
| PDF | `.pdf` | Native text PDFs work best; scanned PDFs use vision |
| Word | `.docx` | Standard Word documents |
| Markdown | `.md` | Plain text contracts in Markdown format |
| Text | `.txt` | Plain text files |

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "File not found" | Check the file path is correct and the Filesystem MCP has access |
| "Unsupported format" | Use PDF, DOCX, MD, or TXT files |
| "Notion unavailable" | Analysis still works — results shown in chat instead |
| Risk flags seem wrong | Review the clause text cited — context matters. Always verify with a lawyer for Red flags |

## Next Steps

1. Try analyzing a contract you're currently reviewing
2. Use `/contract:compare` to see how it stacks up against standards
3. Customize `templates/standard-terms.md` for your specific business needs
4. Check `INSTALL.md` for advanced configuration options
