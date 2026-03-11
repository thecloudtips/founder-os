---
name: SOW Writing
description: "Synthesizes scope definitions and risk assessments into a polished Statement of Work document. Activates when the user wants to write, generate, or format a SOW, or asks 'create the final SOW document.' Produces professional client-facing output with multiple scope options, risk annotations, and clear deliverable specifications."
version: 1.0.0
---

# SOW Writing

Produce professional, client-ready Statement of Work documents in Markdown format. Used by: scope-agent-a, scope-agent-b, and scope-agent-c during Phase 1 (independent hypothesis proposals), and sow-lead during Phase 3 (final synthesis into the three-option deliverable).

## Purpose and Context

Transform a project brief into a structured SOW document a client can read, compare, and sign off on without further clarification. Each option must be self-contained: a reader viewing only Option A should understand the full engagement without cross-referencing other options. All output is Markdown — never produce DOCX directly. The user converts to DOCX, PDF, or other formats as needed.

Scope agents produce one draft SOW per agent (conservative, balanced, or ambitious). The sow-lead combines those three drafts — enriched by risk-agent and pricing-agent evaluations — into a single final document containing all three options with a comparison table and a provider recommendation.

---

## Standard SOW Document Structure

Produce sections in this exact order for every SOW option. Omit a section only when input data provides no basis for it, and note the omission in a `<!-- OMITTED: reason -->` comment.

### 1. Header

```
# Statement of Work: [Project Name]
**Client:** [Client Name]
**Provider:** [Service Provider Name]
**Date:** [ISO date: YYYY-MM-DD]
**Version:** 1.0
```

### 2. Executive Overview

Write 2-3 sentences. Cover: what the engagement is, what the client will have at the end, and the total timeframe. Do not introduce individual deliverables here — save those for Scope of Work.

### 3. Objectives

List 3-5 measurable outcomes the client receives. Frame from the client's perspective, not the provider's activities. Each objective must be testable at project close.

Example:
- A fully deployed e-commerce storefront processing live transactions
- An automated order-to-fulfillment workflow reducing manual processing by 80%
- Staff trained and capable of managing the platform without external support

### 4. Scope of Work

Present a deliverables table. Every row is a discrete, handoff-ready deliverable — never list activities or phases as deliverables.

```
| Deliverable | Description | Milestone | Acceptance Criteria |
|-------------|-------------|-----------|---------------------|
| [Name] | [1-2 sentences: what it is and what problem it solves] | Week [N] | [Measurable test for "done"] |
```

Rules for acceptance criteria: write a test, not a description. "Functional" is not an acceptance criterion. "Processes 100 concurrent transactions without error" is.

### 5. Out of Scope

Present an explicit exclusions table. Include everything a client might reasonably expect that is not included. Missing exclusions create scope disputes.

```
| Excluded Item | Rationale |
|---------------|-----------|
| [Item] | [One sentence: why it is excluded and what to do instead] |
```

### 6. Timeline and Milestones

Present a milestone table. Use a single committed week number per milestone — no ranges.

```
| Milestone | Deliverables | Week | Dependencies |
|-----------|-------------|------|--------------|
| Kickoff | Brief review, environment setup | 1 | Signed SOW, access credentials |
| [Name] | [Deliverable names from Scope of Work] | [N] | [Prerequisite milestones or client actions] |
| Final Delivery | All deliverables accepted | [N] | Client acceptance on all prior milestones |
```

### 7. Investment

Present a pricing table with explicit hours, rates, and subtotals. Round to the nearest whole dollar. Never use ranges in the Investment section.

```
| Component | Hours | Rate (USD/hr) | Subtotal |
|-----------|-------|---------------|----------|
| [Role or phase] | [N] | $[X] | $[Y] |
| **Total** | **[N]** | | **$[Z]** |
```

Follow with a one-sentence payment schedule: e.g., "50% due at contract signing; 50% due on final delivery acceptance."

### 8. Assumptions

Number each assumption. Write testable statements — if an assumption is wrong, it triggers a change order. Include assumptions about: client-provided assets, access, and approvals; third-party integrations; timeline dependencies; and technical environment.

Example:
1. Client provides brand assets (logo, color palette, copy) by end of Week 1.
2. Client has an active AWS account with admin access available at kickoff.
3. Third-party API response times meet published SLA specifications.

### 9. Change Management

Include this section verbatim, adjusting the threshold dollar amount for each option:

> Any change to scope, timeline, or deliverables is handled through a written Change Order. The provider documents the change, its impact on timeline and investment, and presents it to the client for approval before work begins. Changes under $[threshold] with no timeline impact may be absorbed at provider discretion. All other changes require a signed Change Order.

### 10. Terms

Include three standard sub-sections kept brief. Do not expand these into full legal language — this is a commercial SOW, not a contract:

- **Payment**: Reference the payment schedule from the Investment section.
- **Intellectual Property**: "All custom work product becomes client property upon receipt of final payment. Provider retains the right to use anonymized project details as a portfolio reference unless client requests otherwise in writing."
- **Warranties**: "Provider warrants deliverables are fit for the described purpose for 30 days post-delivery. Defects reported within that window are remediated at no additional cost."

---

## The Three-Option Final Document Format

When sow-lead synthesizes the final output, produce a single Markdown document in this structure:

```
# Statement of Work: [Project Name]
[Client Name] x [Provider Name] | [Date]

---

## Executive Summary

[2-3 sentences covering the full engagement context. State what the client wants to achieve and that three scope options follow.]

---

## Option Comparison

| | Option A: [Conservative Name] | Option B: [Balanced Name] | Option C: [Ambitious Name] |
|---|---|---|---|
| Scope | Conservative — core deliverables only | Balanced — core + highest-value additions | Ambitious — full vision |
| Timeline | [N] weeks | [N] weeks | [N] weeks |
| Investment | $[X] | $[X] | $[X] |
| Risk Profile | Low | Medium | Medium-High |
| Best For | Risk-averse clients; tight budget | Most clients; proven ROI | Growth-focused; flexible budget |
| | | ✓ Recommended | |

---

## Option A: [Conservative Name]

[Full Standard SOW Sections 1-10]

---

## Option B: [Balanced Name]

[Full Standard SOW Sections 1-10]

---

## Option C: [Ambitious Name]

[Full Standard SOW Sections 1-10]

---

## Provider Recommendation

[1 paragraph: identify which option is recommended and why. Ground the recommendation in the client's stated priorities from the brief — budget sensitivity, timeline urgency, growth ambitions, or risk tolerance. Do not recommend based on revenue to the provider.]
```

---

## Package Naming Rules

Give each option a memorable name beyond "Option A/B/C". The name must signal value and fit to the client, not internal scope sizing.

Naming patterns that work:
- **Functional scope**: Foundation Package / Growth Package / Transformation Package
- **Outcome-based**: Launch-Ready / Launch + Optimize / Full-Scale Launch
- **Industry-specific**: Core Build / Professional Build / Enterprise Build

Naming patterns to avoid:
- Size-based labels ("Small / Medium / Large", "Basic / Pro / Enterprise") — these anchor clients on price
- Vague labels ("Starter / Plus / Premium") — these say nothing about what the client gets

---

## Writing Style Rules

Apply these rules across all SOW content:

**Voice and tense**: Use active voice and present tense for deliverables. Write "The team delivers a fully tested API integration" not "An API integration will be delivered." Use future tense only in timeline and milestone contexts.

**Numbers**: Use exact figures everywhere. Hours, dollars, and weeks must be single committed values — never ranges. Reserve ranges for the Assumptions section when a dependency is client-controlled.

**Client-first framing**: Open every deliverable description with what the client receives or achieves, not what the provider does. "A mobile-responsive storefront the client's team can manage without developer support" not "We will build a mobile-responsive storefront."

**Sentence length**: Keep sentences under 25 words in the Scope of Work and Deliverables sections. Longer sentences are acceptable in the Executive Overview and Provider Recommendation.

**Specificity**: Every vague word is a scope dispute waiting to happen. Replace "consulting" with the specific advice type. Replace "ongoing support" with a defined ticket volume and response SLA. Replace "and similar activities" with an explicit list or explicit exclusion.

---

## Common SOW Writing Mistakes to Avoid

**Vague deliverables**: "Consulting services" and "ongoing support" are not deliverables. Define the concrete output: "8 hours of technical advisory per month, delivered as written recommendations via email."

**Scope creep language**: "And similar activities," "as needed," and "reasonable requests" open the door to unlimited scope expansion. Every deliverable must have a defined boundary.

**Wishy-washy timelines**: "Approximately 8-10 weeks" is a hedge that clients read as a commitment to 8 weeks. Commit to one number. If a dependency creates genuine uncertainty, name the dependency in the Assumptions section.

**Missing acceptance criteria**: "Deliverable is complete when the client is satisfied" is not a criterion. Every deliverable needs an objective, testable condition.

**Omitting the exclusions section**: Clients assume everything adjacent to the project is included unless explicitly excluded. A missing exclusions section does not protect the provider.

**Price as first differentiator**: Never lead the comparison table with price. Clients choosing on price alone choose the lowest option regardless of fit. Lead with scope and outcomes; price follows as a consequence of scope.

---

## Comparison Table Rules

The Option Comparison table at the top of the final document must follow these rules:

- **Lead with Scope, not Investment**: Place the Scope row first and Investment row fourth or fifth. Clients should understand what they get before they see what it costs.
- **Include Risk Profile**: A "Low / Medium / Medium-High" risk row gives risk-averse clients permission to choose the conservative option without feeling they are being cheap.
- **Include Best For**: Describe specific client archetypes ("risk-averse clients; tight budget") rather than product attributes ("fewer features"). Clients self-identify with archetypes.
- **Mark the recommendation**: Place a "Recommended" indicator (checkmark or text) in the column header row, not in a separate row. This keeps the table scannable.
- **Keep cell text brief**: Each cell should be 3-8 words. Save full explanations for the individual option sections.

---

## Quality Checklist

Before passing a completed SOW draft to the next agent or outputting the final document, confirm:

- [ ] Every deliverable has an acceptance criterion that is testable, not descriptive
- [ ] Every timeline entry is a single week number, not a range
- [ ] Every investment row has hours, rate, and subtotal — no row uses "TBD"
- [ ] The Out of Scope section covers at least 3 items a client might reasonably assume are included
- [ ] The Assumptions section contains at least 3 client-side dependencies
- [ ] Package names convey value, not size
- [ ] The comparison table leads with Scope, not Investment
- [ ] The Provider Recommendation references at least one stated client priority from the brief
- [ ] No placeholder text, TODO markers, or incomplete sections remain in the output

---

## Notion Tracking

On completion, create or update a record in the consolidated **"[FOS] Deliverables"** database with **Type = "SOW"**.

### Database Discovery

1. Search for "[FOS] Deliverables" database first (preferred)
2. If not found, fall back to "Founder OS HQ - Deliverables" database
3. If not found, fall back to legacy "SOW Generator - Outputs" database
4. If none exists, skip Notion tracking (do NOT lazy-create the database)

### Record Fields

When writing to "[FOS] Deliverables" or "Founder OS HQ - Deliverables":
- **Type**: "SOW"
- **Title**: Project name from the SOW header (e.g., "Customer Portal")
- **Status**: "Draft"
- **Amount**: Recommended option's quoted price
- **File Path**: Output file path (e.g., `./sow-output/sow-acme-corp-2026-02-24.md`)
- **Brief File**: Path to the brief file if `/sow:from-brief` was used
- **Sources Used**: Data sources consulted (e.g., "Notion", "Manual")
- **Generated At**: Current date/time

### Source Deliverable Relation

After creating the SOW record, link it to its source Proposal:
- Search the same Deliverables database for a **Proposal** (Type = "Proposal") with the same **Company** relation
- If multiple Proposals match, narrow by matching **Brief File** base name
- Set the SOW's **Source Deliverable** relation to the matched Proposal page
- This creates a bidirectional link: the Proposal's **Derived Deliverables** automatically shows this SOW

### Company + Deal Relations

When writing to "[FOS] Deliverables" or "Founder OS HQ - Deliverables":
- **Company relation**: Look up the client name in the CRM Pro "Companies" database. If a match is found, set the Company relation property to link to that company record.
- **Deal relation**: If the SOW is associated with a specific deal (found during Notion context search or brief metadata), set the Deal relation property to link to that deal record.
- If no Company or Deal match is found, leave the relation properties empty — never create placeholder records.

### Upsert Key

Upsert key: Client Name + Project Title. When upserting in "Founder OS HQ - Deliverables", also filter by Type = "SOW" to avoid collisions with other deliverable types (Proposals, Contracts).

### Legacy Database Fallback

When falling back to legacy "SOW Generator - Outputs" database:
- Write: Client Name, Output Path, Options Count, Recommended Option, Generated At
- Do not set Type, Company, or Deal properties (legacy schema does not have them)
