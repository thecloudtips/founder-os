---
name: Risk Assessment
description: "Evaluates project risks for each SOW scope option in the competing-hypotheses pipeline. Activates when the user wants to assess risks, identify project red flags, or asks 'what could go wrong with this scope?' Scores risks by likelihood and impact, flags scope-specific concerns, and provides mitigation recommendations."
version: 1.0.0
---

# Risk Assessment

Evaluate each of the three scope proposals (conservative, balanced, ambitious) against a consistent seven-dimension risk framework and produce scored risk assessments for the SOW Lead. Used by the **risk-agent** as part of Phase 2 of the Competing Hypotheses pipeline — the risk-agent and pricing-agent run in parallel after Phase 1 scope agents complete, before the sow-lead synthesizes the final document.

## Purpose and Context

The risk-agent operates on the three scope proposals produced independently by scope-agent-a (conservative), scope-agent-b (balanced), and scope-agent-c (ambitious). Its sole output is a structured JSON array — one risk assessment per hypothesis — that the sow-lead uses to annotate the comparison table and inform package positioning.

Do not generate prose SOW content. Do not rewrite scope proposals. Do not approve or reject hypotheses. Assess only. Output structured JSON conforming to the schema defined in this skill.

Apply the framework consistently across all three proposals. Scoring bias toward "ambitious = bad" is a common failure mode — resist it. An ambitious proposal with strong change control, defined acceptance criteria, and phased delivery gates can score higher than a conservative proposal with vague deliverables.

## The Seven-Dimension Risk Framework

Score each dimension on a 0–10 scale where **0 = highest risk** and **10 = lowest risk (safest)**. Apply the scoring independently per hypothesis. Never copy a score from one proposal to another without justification — even structurally similar proposals differ in the details.

| Dimension | Code | Weight | What to Evaluate |
|-----------|------|--------|-----------------|
| Scope Clarity | `scope_clarity` | 0.25 | Are all deliverables unambiguous? Is the scope boundary explicit? Are acceptance criteria defined per deliverable? |
| Timeline Realism | `timeline_realism` | 0.20 | Are milestones achievable given team size? Is buffer adequate (target ≥ 10%)? Are dependencies between phases identified? |
| Budget Risk | `budget_risk` | 0.15 | Does pricing leave margin for overruns? Is there a contingency line? Does utilization leave headroom below 95%? |
| Technical Complexity | `technical_complexity` | 0.15 | How many unknowns exist? Is novel or untested technology involved? What is the integration complexity with third-party systems? |
| Client Risk | `client_risk` | 0.10 | How dependent is delivery on client feedback speed, resource availability, or decision-making authority? Are client obligations documented? |
| Delivery Confidence | `delivery_confidence` | 0.10 | Does the team have capacity and skill match? Is there evidence of similar project history? Are sub-contractor dependencies identified? |
| Scope Creep Exposure | `scope_creep_exposure` | 0.05 | How vulnerable is this proposal to expansion requests? Are exclusions explicit? Is a change request process defined? |

Compute the overall risk score as a weighted average:

```
overall_risk_score = (scope_clarity × 0.25)
                   + (timeline_realism × 0.20)
                   + (budget_risk × 0.15)
                   + (technical_complexity × 0.15)
                   + (client_risk × 0.10)
                   + (delivery_confidence × 0.10)
                   + (scope_creep_exposure × 0.05)
```

Round `overall_risk_score` to one decimal place. A score of 8.0 or above represents a well-controlled proposal. A score below 6.0 warrants explicit advisory language in the SOW summary.

## Starting Score Adjustments by Hypothesis Type

Apply these starting values before detailed analysis. They represent the structural risk bias inherent to each hypothesis archetype. Always adjust from these baselines based on the actual proposal content — these are starting points, not fixed values.

| Dimension | Conservative Start | Balanced Start | Ambitious Start |
|-----------|-------------------|----------------|-----------------|
| `scope_clarity` | 9.0 | 8.0 | 6.0 |
| `timeline_realism` | 9.0 | 8.0 | 6.0 |
| `budget_risk` | 8.5 | 7.5 | 6.0 |
| `technical_complexity` | 8.0 | 7.0 | 5.5 |
| `client_risk` | 8.0 | 7.5 | 6.5 |
| `delivery_confidence` | 8.5 | 7.5 | 6.0 |
| `scope_creep_exposure` | 9.0 | 7.0 | 5.0 |

Adjust upward when the proposal includes explicit mitigations (change control, phased gates, acceptance criteria). Adjust downward when the proposal is vague, includes client-dependent milestones without SLAs, or introduces first-time technology.

## Risk Flag Taxonomy

Identify specific flags at the proposal level after computing dimension scores. Assign each flag to one of three severity tiers.

### Red Flags — Score Impact ≥ 2.0

Red flags represent structural deficiencies that meaningfully lower overall safety. Always accompany a red flag with a specific mitigation suggestion.

- Undefined or absent acceptance criteria for any major deliverable
- Timeline buffer below 10% of total project duration
- First-time integration with an untested third-party system with no discovery sprint planned
- Budget utilization above 95% with no stated contingency
- Critical path milestone dependent on a client resource with no documented availability commitment
- Scope includes deliverables in two or more unrelated technical domains without phase boundaries

### Yellow Flags — Score Impact 0.5–2.0

Yellow flags represent elevated risk areas that warrant attention but do not disqualify the proposal.

- Assumptions that could materially change scope (e.g., client system access not yet confirmed, API documentation not yet reviewed)
- Timeline that is ambitious relative to team size or stated sprint velocity
- Novel technology stack or framework with limited documented team experience
- Scope includes client training components, which carry high time variability
- Milestone sign-off relies on a named client stakeholder whose availability is not confirmed
- Fixed-fee pricing with cost-plus components that are capped but not clearly bounded

### Green Notes — Positive Risk Mitigations Already in Place

Green notes identify risk controls already embedded in the proposal. Surface them so the sow-lead can highlight them as selling points in the comparison table.

- Strict formal change request (CR) process defined with cost-impact template
- Phased delivery with explicit go/no-go gates between phases
- Acceptance criteria defined per deliverable
- Explicit exclusions list with clear callouts of what is out of scope
- Buffer weeks built in above 15% of total project duration
- Technical discovery sprint scoped in Week 1 before committing downstream timeline
- SLA clause for client feedback turnaround (e.g., 3 business days)
- Escalation path documented for delayed client responses

## Risk Output Schema

Produce exactly this JSON structure for each of the three hypotheses. Wrap all three in a top-level array.

```json
[
  {
    "hypothesis_id": "conservative",
    "risk_scores": {
      "scope_clarity": 8.5,
      "timeline_realism": 9.0,
      "budget_risk": 8.0,
      "technical_complexity": 7.5,
      "client_risk": 7.0,
      "delivery_confidence": 8.5,
      "scope_creep_exposure": 8.0
    },
    "overall_risk_score": 8.2,
    "red_flags": [],
    "yellow_flags": [
      "Timeline assumes 3-day client feedback turnaround with no SLA clause"
    ],
    "green_notes": [
      "20% timeline buffer built in",
      "Strict change control process defined with CR template"
    ],
    "mitigation_suggestions": [
      "Add SLA clause requiring client feedback within 3 business days",
      "Define escalation path if feedback delays exceed 1 week"
    ],
    "summary": "Low-risk proposal. Strong scope clarity and realistic timeline with adequate buffer. Main exposure is client feedback latency, which is contractually addressable."
  }
]
```

Field rules:

- `hypothesis_id`: must be exactly `"conservative"`, `"balanced"`, or `"ambitious"` — match the originating scope agent
- `risk_scores`: all seven dimensions required; numeric values to one decimal place
- `overall_risk_score`: weighted average computed per formula above; one decimal place
- `red_flags`: array of strings; empty array if none — never omit the field
- `yellow_flags`: array of strings; empty array if none — never omit the field
- `green_notes`: array of strings; empty array if none — never omit the field
- `mitigation_suggestions`: one entry per red flag at minimum; address yellow flags when practical
- `summary`: 1–3 sentences; lead with the risk tier (Low / Moderate / Elevated / High), name the top risk, name the primary mitigation path

## Mitigation Strategy Library

Match mitigations to the specific flags identified. Draw from this library first; augment with project-specific language as needed.

| Risk Type | Standard Mitigation |
|-----------|---------------------|
| Scope ambiguity — deliverable level | "Define acceptance criteria for [deliverable] before kickoff; acceptance criteria become contractually binding" |
| Scope ambiguity — project boundary | "Add an explicit exclusions section listing [out-of-scope items] with a statement that anything not listed is excluded" |
| Timeline buffer insufficient | "Add [N] buffer days to [milestone]; current buffer is [X]% against a recommended minimum of 10%" |
| Client feedback dependency | "Insert SLA clause: client feedback required within 3 business days; delays pause the project clock" |
| Technical unknowns | "Schedule a 1-week technical discovery sprint before committing to the downstream timeline; convert unknowns to estimates with confidence ranges" |
| First-time third-party integration | "Require vendor API documentation review and sandbox access in Week 1; build a contingency day for integration issues" |
| Scope creep exposure | "Define a formal change request process with a cost-impact template; include one sample CR form as an appendix to the SOW" |
| Budget overrun risk | "Negotiate a 10% contingency line item billed only if consumed, or tie payment milestones to phase sign-offs rather than calendar dates" |
| Client resource unavailability | "Document client obligations explicitly: named stakeholder, meeting attendance, and asset delivery dates with hard dependencies on project timeline" |
| Novel technology | "Add team experience qualifier to proposal; consider sub-contracting specialist for [technology] or adjust timeline to reflect learning curve" |
| Training time variability | "Cap training at [N] hours in contract; define what constitutes completed training (e.g., attendee sign-off form)" |

Always phrase mitigation suggestions as concrete actions. Never write "consider reducing scope" without specifying which component and why.

## Comparative Analysis Rules

After scoring all three hypotheses, produce a comparative section appended as a fourth element in the output array under `hypothesis_id: "comparison"`.

```json
{
  "hypothesis_id": "comparison",
  "best_overall_risk_profile": "conservative",
  "risk_ranking": ["conservative", "balanced", "ambitious"],
  "trade_off_summary": "Conservative offers the lowest risk profile but limits deliverables to core functionality. Balanced optimizes risk-to-value with one yellow flag addressable by a client SLA clause. Ambitious requires strong change management and a discovery sprint but can be de-risked to a Moderate tier with the stated mitigations.",
  "recommendation_note": "All three options are viable. Ambitious is not inherently inadvisable — apply the listed mitigations and re-score to confirm it reaches 7.0 or above before presenting to client."
}
```

Rules for comparative analysis:

- Identify which proposal has the best overall risk profile based on `overall_risk_score`
- Rank all three proposals from lowest-risk to highest-risk
- Identify the specific risk trade-offs between options (do not simply rank by score; explain what the score difference means in practice)
- Never state "Ambitious = bad" or imply the highest-risk option should be excluded without checking whether its mitigations bring it above the 7.0 threshold
- When two proposals have scores within 0.5 of each other, declare them tied and note both options as equivalent from a risk standpoint
- Surface at least one case where the higher-risk proposal has a meaningful upside that justifies the additional controls

## Scoring Integrity Rules

Apply these rules throughout the assessment to ensure scores reflect reality rather than assumption:

- Read every deliverable in each proposal before assigning `scope_clarity` — a single vague deliverable in an otherwise clear proposal warrants a deduction of at least 1.0 point
- Do not assume buffer exists unless it is stated in the timeline; absence of stated buffer means `timeline_realism` starts at 6.0 regardless of hypothesis type
- Do not inflate `delivery_confidence` based on the client brief alone — base it only on what the scope proposal itself states about team structure, capacity, and experience
- Apply the same scoring rubric to all three proposals in sequence during a single assessment pass to minimize inter-proposal bias
- When a flag is identified, lower the relevant dimension score immediately; never flag a risk while leaving the score at a high level

## Quality Standard

- Produce valid JSON that parses without error; validate bracket and comma structure before output
- Include all four elements in the output array: conservative, balanced, ambitious, comparison
- All seven dimension scores must be present in each hypothesis object
- Every red flag must have at least one corresponding entry in `mitigation_suggestions`
- Summaries must begin with a risk tier label: Low (8.0+), Moderate (6.5–7.9), Elevated (5.0–6.4), or High (below 5.0)
- Do not include prose outside the JSON structure — the sow-lead consumes this output programmatically
