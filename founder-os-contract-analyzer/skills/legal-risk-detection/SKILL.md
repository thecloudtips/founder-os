---
name: Legal Risk Detection
description: "Evaluates contracts for harmful, unusual, or one-sided clauses using Red/Yellow/Green risk classification. Activates when the user wants to find contract red flags, assess legal risks, check for unfair terms, or asks 'is this contract safe to sign?' Provides plain-English explanations and concrete mitigation suggestions for freelancers and agency founders."
---

## Overview

Evaluate contracts for legal risks using a 3-tier RAG (Red/Yellow/Green) classification system. Identify clauses that are potentially harmful, unusual, or one-sided. Assign each flagged clause a severity level with a plain-English explanation and a concrete mitigation suggestion. The target audience is freelancers and small agency founders -- not lawyers. Provide actionable guidance that helps the user negotiate better terms or decide when to seek legal counsel.

This skill handles risk detection and classification only. Contract term extraction (payment, IP, termination, liability, scope, confidentiality) is handled by the contract-analysis skill. When both skills are invoked, contract-analysis runs first to produce structured term data, and legal-risk-detection consumes that data to evaluate risk.

Always include the following disclaimer at the top of every risk report output:

> **Disclaimer**: This analysis is for informational purposes only and does not constitute legal advice. Consult a qualified attorney for legal guidance.

## RAG Classification System

Classify every flagged clause into exactly one of three severity tiers:

### Red (High Risk)

Clauses that could cause significant financial or legal harm. Recommend consulting a lawyer before signing. Red flags indicate terms that materially disadvantage the contractor with no offsetting benefit or protection.

Characteristics of Red clauses:
- Create unlimited or disproportionate financial exposure
- Transfer risk entirely to the contractor
- Remove standard legal protections or rights
- Lock the contractor into obligations that survive well beyond the engagement
- Contain language that is enforceable and actively harmful, not merely unusual

Examples: unlimited liability, one-sided indemnification where only the contractor indemnifies the client, perpetual IP assignment with no reversion clause, unilateral termination without payment for completed work, non-compete exceeding 2 years or covering unreasonably broad territory.

### Yellow (Medium Risk)

Clauses that deviate from standard practice or contain ambiguity. May be acceptable depending on the specific engagement, client relationship, or contract value, but warrant careful review before signing.

Characteristics of Yellow clauses:
- Use vague or undefined language that creates interpretation risk
- Deviate from industry norms without clear justification
- Create moderate exposure that is manageable but not ideal
- Contain terms that could become problematic under certain circumstances

Examples: vague confidentiality scope covering "all information shared", ambiguous payment terms with no specific due date, broad non-solicitation lasting more than 1 year, auto-renewal without a clear opt-out mechanism.

### Green (Low Risk)

Standard, balanced clauses following common industry practice. Acceptable as-is with no modification needed. Green classification means the clause is within normal range for freelance and agency contracts.

Characteristics of Green clauses:
- Use clear, specific language with defined terms
- Distribute risk proportionally between both parties
- Follow standard contract conventions in the freelance/agency space
- Include reasonable limits on scope, duration, and liability

Examples: mutual indemnification, standard auto-renewal with 30-day notice, boilerplate warranty disclaimers, clear net-30 payment terms, balanced termination with notice requirements for both parties.

## Risk Categories

Evaluate every contract against seven risk dimensions. Each flagged clause maps to exactly one category.

### 1. Payment Risk

Detect clauses that expose the contractor to late payment, non-payment, or compensation disputes. Look for:
- Absence of specific payment due dates or milestones
- Pay-when-paid structures where payment depends on the client's own client paying
- No late payment penalties or interest provisions
- Scope creep language allowing additional work without corresponding compensation adjustments
- Payment terms exceeding net-60 without justification
- Retainer structures with unclear drawdown rules

### 2. IP Risk

Detect clauses that transfer intellectual property rights beyond what is standard for the engagement. Look for:
- Over-broad IP assignment covering all work product regardless of relevance to the project
- No carve-out for pre-existing IP, tools, frameworks, or methodologies the contractor brings to the engagement
- Moral rights waiver (significant in jurisdictions that recognize moral rights)
- Retroactive IP assignment covering work performed before the contract start date
- IP assignment that includes derivative works created after the contract ends
- No license-back provision allowing the contractor to use general knowledge and techniques

### 3. Liability Risk

Detect clauses that expose the contractor to disproportionate financial liability. Look for:
- Unlimited liability with no cap on damages
- One-sided indemnification where only the contractor indemnifies the client
- Indemnification scope extending to third-party claims arising from the client's own actions
- No limitation to direct damages (exposure to consequential, incidental, or punitive damages)
- Liability cap set unreasonably high relative to contract value (e.g., 10x the total contract fee)

### 4. Termination Risk

Detect clauses that allow the client to exit the contract on unfavorable terms for the contractor. Look for:
- Unilateral termination for convenience with no payment for work completed to date
- No cure period for alleged breach (immediate termination without opportunity to fix)
- Termination clauses that trigger forfeiture of unpaid invoices
- No mutual termination rights (only the client can terminate)
- Kill fee absence when termination for convenience is permitted

### 5. Scope Risk

Detect clauses that leave deliverables vague or allow unbounded work obligations. Look for:
- Undefined or vague deliverable descriptions ("all necessary work", "as needed")
- Unlimited revisions or change cycles with no additional compensation
- Satisfaction standard defined subjectively ("to client's satisfaction") with no objective criteria
- Automatic scope expansion language ("and any other tasks as requested")
- Absence of a formal change order or change request process

### 6. Non-Compete Risk

Detect clauses that restrict the contractor's ability to work after the engagement ends. Look for:
- Duration exceeding 1 year for freelancers (or 2 years for agencies in specialized fields)
- Geographic scope that is unreasonably broad relative to the work performed
- Industry definition that covers the contractor's entire professional domain
- Non-compete that applies even if the client terminates for convenience
- No compensation during the non-compete restriction period

### 7. Confidentiality Risk

Detect clauses that impose disproportionate secrecy obligations. Look for:
- Perpetual confidentiality with no sunset clause
- Overly broad definition of confidential information ("all information shared in any form")
- No carve-outs for publicly available information, independently developed knowledge, or information received from third parties
- Confidentiality obligations that survive indefinitely after contract termination
- No provision for compelled disclosure (court orders, regulatory requirements)

## Risk Flag Structure

For each flagged clause, produce a structured flag object containing these fields:

| Field | Type | Description |
|-------|------|-------------|
| `flag_name` | string | Short descriptive name (e.g., "Unlimited Liability") |
| `severity` | enum | Red, Yellow, or Green |
| `category` | enum | One of the 7 risk categories above |
| `clause_text` | string | The specific clause or language triggering the flag, quoted from the contract |
| `explanation` | string | Why this clause is risky, written in plain English for a non-lawyer audience |
| `mitigation` | string | Suggested change, counter-proposal, or negotiation point |

When quoting `clause_text`, extract the exact language from the contract. Do not paraphrase. If the risky language spans multiple sentences, include the full passage. When a clause is long (more than 3 sentences), quote the critical portion and add "[...]" to indicate omitted surrounding text.

## Comparison Logic vs Standard Terms

When the `/contract:compare` command invokes this skill, compare each extracted term against the standard-terms template at `${CLAUDE_PLUGIN_ROOT}/templates/standard-terms.md`. Perform the comparison as follows:

1. Load the standard-terms template. If the template file does not exist, warn the user: "Standard terms template not found at templates/standard-terms.md -- comparison unavailable. Run /contract:analyze for standalone risk detection." Fall back to standalone risk detection.

2. For each term extracted by the contract-analysis skill (payment, IP, termination, liability, scope, confidentiality, non-compete), compare the contract's clause against the corresponding standard-terms clause.

3. For each deviation detected, produce a comparison entry:

| Field | Description |
|-------|-------------|
| `term_category` | Which contract area (payment, IP, termination, etc.) |
| `standard_term` | What the standard template specifies |
| `contract_term` | What the analyzed contract specifies |
| `deviation` | What differs, in plain English |
| `severity` | Red, Yellow, or Green classification of the deviation |
| `impact` | What the deviation means for the contractor in practice |
| `counter_proposal` | Suggested language to negotiate back toward the standard |

4. Terms that match the standard template receive a Green classification with the note "Matches standard terms."

5. Terms present in the contract but absent from the standard template receive a Yellow flag with the note "Non-standard clause -- review for appropriateness."

6. Terms present in the standard template but absent from the contract receive a Yellow flag with the note "Expected clause missing from contract -- consider requesting addition."

## Overall Risk Level Calculation

Compute the overall risk level for the entire contract based on the aggregate of all flags:

| Condition | Overall Level |
|-----------|---------------|
| ANY Red flag exists | **Red** -- "This contract contains high-risk clauses. Consult a lawyer before signing." |
| ANY Yellow flag exists AND no Red flags | **Yellow** -- "This contract contains clauses that deviate from standard practice. Review flagged items carefully." |
| All flags are Green OR no flags exist | **Green** -- "This contract follows standard practice. No significant risk issues detected." |

In addition to the overall level, produce a `risk_summary` sentence (1-2 sentences) that names the most critical finding. Examples:
- Red: "One-sided indemnification clause exposes you to unlimited liability for client's third-party claims. Consult a lawyer before signing."
- Yellow: "Payment terms lack a specific due date, creating ambiguity around when you will be paid. Clarify net-30 or net-45 terms."
- Green: "All terms are balanced and within standard range for freelance engagements."

## Output Structure

For each analyzed contract, produce the following structured output:

```
overall_risk_level: Red | Yellow | Green
risk_summary: [1-2 sentence summary of most critical finding]
flags_count:
  red: [N]
  yellow: [N]
  green: [N]
flags: [array of flag objects per the Risk Flag Structure above]
recommendations: [prioritized list of negotiation points, Red items first, then Yellow]
```

Order the `recommendations` list by severity descending (all Red items grouped first, then Yellow). Within the same severity, order by potential financial impact. Each recommendation should be a concrete negotiation point the user can bring to the other party, not a vague suggestion.

## Edge Cases

### Contract With No Identifiable Risks

When no risky clauses are detected, still produce a complete Green assessment. Output all terms as Green-classified with a note confirming they match standard practice. Set overall_risk_level to Green and risk_summary to: "No significant risk issues detected. All reviewed clauses follow standard practice."

### Entirely Boilerplate Contracts

When a contract consists almost entirely of boilerplate language with minimal customization, flag this as an observation: "This contract appears to be a standard template with minimal customization. While boilerplate terms are generally balanced, verify that project-specific details (scope, deliverables, timeline, payment amounts) are adequately defined."

### Conflicting Clauses

When two clauses within the same contract contradict each other (e.g., one section grants IP ownership to the contractor while another assigns it to the client), flag the conflict itself as a Yellow risk: "Conflicting clauses detected in [sections]. Section [X] states [A] while Section [Y] states [B]. This ambiguity creates interpretation risk. Request clarification to resolve the conflict before signing."

### Incomplete Contracts

When a contract is missing standard sections entirely (no termination clause, no IP clause, no liability cap), flag each missing section as Yellow: "No [section] clause found. Standard contracts include [what the section covers]. Request addition of this clause to protect both parties."

### Multi-Party Contracts

When a contract involves more than two parties, evaluate risk from the perspective of the contractor (the user). Note which obligations bind the user specifically vs. other parties. Flag any joint-and-several liability clauses as Red.

### Short Contracts (Under 2 Pages)

When analyzing very short contracts or informal agreements (letters of engagement, email confirmations), flag the lack of standard protections: "This is a brief agreement that omits several standard contract protections. Consider requesting a more comprehensive contract that includes [missing critical sections]."

## Reference

For comprehensive risk pattern detection including specific phrases to look for, example clause text, and detailed mitigation language for all severity tiers, see `${CLAUDE_PLUGIN_ROOT}/skills/legal-risk-detection/references/risk-patterns.md`.
