---
name: Proposal Writing
description: "Generates professional client proposals with 7 structured sections and 3 pricing packages. Activates when the user wants to create, write, or draft a proposal for a client, or asks 'help me put together a proposal.' Produces Markdown output plus a SOW-compatible brief for handoff to the SOW Generator."
version: 1.0.0
---

# Proposal Writing

Generate professional client proposals in Markdown format with 7 structured sections and 3 pricing packages. Produces a complete proposal document plus a SOW-compatible brief file for handoff to #14 SOW Generator via `/sow:from-brief`.

## Proposal Structure

Every proposal contains exactly 7 sections in this order. Never omit a section — if input data is insufficient for a section, note what is missing and produce a reasonable draft with `<!-- NEEDS REVIEW: reason -->` comments.

| # | Section | Purpose | Target Length |
|---|---------|---------|---------------|
| 1 | Cover Letter | Personalized introduction, establish rapport | 3-4 paragraphs |
| 2 | Executive Summary | Problem-solution-value at a glance | 1 page max |
| 3 | Understanding & Approach | Demonstrate client understanding | 1-2 pages |
| 4 | Scope of Work | Deliverables, milestones, exclusions | 2-3 pages |
| 5 | Timeline & Milestones | Phase breakdown with week numbers | 1 page |
| 6 | Pricing | 3 packages with comparison table | 1-2 pages |
| 7 | Terms & Conditions | Payment, IP, change control, confidentiality | 1 page |

## Section Rules

### 1. Cover Letter

Open with a specific reference to the client's situation — never a generic greeting. Structure:

- **Paragraph 1**: Reference recent conversation, meeting, or RFP. Name the client's core challenge.
- **Paragraph 2**: Summarize the proposed approach and its primary benefit.
- **Paragraph 3**: Highlight relevant experience or a comparable past project (if CRM data is available).
- **Paragraph 4**: Close with a clear next step and contact information.

Anti-patterns: Do not open with "Dear Sir/Madam" or "We are pleased to submit." Do not describe the provider's company history. The cover letter is about the client, not the provider.

### 2. Executive Summary

Follow the problem-solution-value framework in exactly three parts:

- **Problem**: State the client's challenge in their language, not technical jargon.
- **Solution**: Describe the proposed approach in 2-3 sentences. Name the key deliverables.
- **Value**: Quantify the expected impact — time saved, revenue enabled, risk mitigated. If quantification is not possible, describe the qualitative business outcome.

Keep under 300 words. A decision-maker should understand the entire engagement from this section alone.

### 3. Understanding & Approach

Demonstrate comprehension of the client's situation before prescribing a solution:

- Restate the client's goals, challenges, and constraints in original language (not copied from the brief).
- Identify 2-3 underlying problems the client may not have articulated.
- Present the methodology or approach with rationale for key choices.
- Explain why this approach fits this specific client, not why it works in general.

### 4. Scope of Work

Present deliverables in a table with four columns:

```
| Deliverable | Description | Acceptance Criteria | Milestone |
|-------------|-------------|---------------------|-----------|
```

Rules:
- Each deliverable is a noun (an output), not a verb (an activity). "API Integration Module" not "Integrate APIs."
- Acceptance criteria must be binary and testable. "Passes 95% of test suite" not "Works correctly."
- Include an explicit **Exclusions** subsection listing items a client might reasonably expect. Every exclusion needs a rationale.
- Include an **Assumptions** subsection listing conditions that must hold for the proposal to remain valid.

### 5. Timeline & Milestones

Present a phase-based timeline table:

```
| Phase | Deliverables | Weeks | Dependencies |
|-------|-------------|-------|--------------|
```

Rules:
- Use single week numbers, not ranges. "Week 4" not "Weeks 3-5."
- Include a Kickoff phase (Week 1) and Final Delivery phase.
- Map every deliverable from the Scope section to a phase.
- Note client-side dependencies (approvals, assets, access) explicitly.

### 6. Pricing

Present 3 packages in a comparison table. Read `${CLAUDE_PLUGIN_ROOT}/skills/pricing-strategy/SKILL.md` for the full pricing methodology. Follow these layout rules:

- Lead with scope, not price. The first differentiator row must describe what is included.
- Mark the recommended package with a "Recommended" indicator.
- Include a "What's Included" breakdown below the comparison table showing each package's deliverables.
- Follow with individual package detail sections.

### 7. Terms & Conditions

Include four standard subsections:

- **Payment Terms**: Reference the payment schedule (milestone-based, monthly, or upfront with discount). Tie payments to deliverable acceptance, not dates.
- **Change Control**: Changes to scope require a written Change Order with impact assessment before work begins.
- **Intellectual Property**: All custom work product transfers to client upon final payment. Provider retains anonymized portfolio rights.
- **Confidentiality**: Both parties maintain confidentiality of proprietary information disclosed during the engagement.

Keep terms concise and commercial — this is a proposal, not a legal contract.

## Writing Style

- **Active voice, present tense** for deliverables: "The team delivers" not "will be delivered."
- **Client-first framing**: Lead every deliverable with what the client receives. "A dashboard your team manages independently" not "We build a dashboard."
- **Specific language**: Replace every instance of "various", "ongoing", "as needed", "and similar" with explicit lists or boundaries.
- **Sentence length**: Under 25 words in Scope and Deliverables sections. Longer sentences acceptable in Cover Letter and Executive Summary.
- **Professional markdown**: H2 for sections, H3 for subsections, tables for structured data, bold for emphasis. No emojis.

## Output Files

Generate two files per proposal:

### Proposal File
`proposals/proposal-[client-slug]-[YYYY-MM-DD].md` — The complete 7-section proposal document.

### SOW-Compatible Brief File
`proposals/brief-[client-slug]-[YYYY-MM-DD].md` — A structured brief file consumable by `/sow:from-brief`. Contains: Client info, Project Overview, Deliverables list, Constraints (budget, timeline, priorities), Selected Package (defaults to Professional), and Additional Context from CRM.

## CRM Context Integration

When Notion CRM is available, search CRM Pro databases (Companies, Contacts, Deals) for the client name. Use found context to:

- Personalize the cover letter with relationship history
- Reference past projects or engagements in Understanding & Approach
- Tailor pricing to historical budget ranges
- Note the client's industry and known priorities

When Notion is unavailable, proceed without CRM data — all CRM-enriched sections degrade gracefully to input-only content.

## Notion Tracking

On completion, create or update a record in the consolidated **"Founder OS HQ - Deliverables"** database with **Type = "Proposal"**.

### Database Discovery

1. Search for **"[FOS] Deliverables"** database first (preferred)
2. If not found, fall back to "Founder OS HQ - Deliverables" database
3. If not found, fall back to legacy "Proposal Automator - Proposals" database
4. If none exists, skip Notion tracking (do NOT lazy-create the database)

### Record Fields

Set these fields on every record:
- **Type**: "Proposal" (select)
- **Status**: "Draft"
- **Package Selected**: "None"
- Record both proposal and brief file paths

### Company + Deal Relations

When writing to "Founder OS HQ - Deliverables":
- **Company relation**: Look up the client name in the CRM Pro "Companies" database. If a match is found, set the Company relation property to link to that company record.
- **Deal relation**: If the proposal is associated with a specific deal (found during CRM context resolution in Step 1), set the Deal relation property to link to that deal record.
- If no Company or Deal match is found, leave the relation properties empty — never create placeholder records.

### Upsert Key

Upsert key: Client Name + Project Title (same as before). When upserting in "Founder OS HQ - Deliverables", also filter by Type = "Proposal" to avoid collisions with other deliverable types.

## Quality Checklist

Before outputting a proposal, verify:

- [ ] All 7 sections present in correct order
- [ ] Every deliverable has testable acceptance criteria
- [ ] Exclusions section covers at least 3 items
- [ ] Timeline maps every deliverable to a phase
- [ ] Pricing has exactly 3 packages with comparison table
- [ ] No placeholder text, TODO markers, or `[FILL IN]` remnants
- [ ] SOW-compatible brief file generated alongside proposal
- [ ] Client name appears consistently throughout (no mismatches)

## Additional Resources

### Reference Files

For detailed section templates with worked examples:
- **`${CLAUDE_PLUGIN_ROOT}/skills/proposal-writing/references/section-templates.md`** — Complete example content for each of the 7 proposal sections with annotations
