---
name: Scope Definition
description: "Defines project scope and work breakdown structures for Statement of Work documents. Activates when the user wants to scope a project, define deliverables, break down requirements, or asks 'what should be in the SOW scope?' Generates conservative, balanced, and ambitious scope interpretations for the competing-hypotheses pipeline."
version: 1.0.0
---

# Scope Definition

Translate a project brief into a structured scope definition with deliverables, effort estimates, and timeline milestones. Used by Scope Agent A (conservative), Scope Agent B (balanced), and Scope Agent C (ambitious) — all three agents run this skill in parallel during Phase 1 of the competing-hypotheses pipeline.

## Scope Elements

Every scope proposal must define exactly six elements. Never omit one; use "N/A" only for constraints when there are genuinely none.

| Element | What to define |
|---------|---------------|
| Deliverables | Named outputs the client receives, each with acceptance criteria |
| Effort hours | Numeric estimate per task area, summed to a project total |
| Timeline milestones | Named checkpoints with week numbers from project start |
| Exclusions | Items explicitly out of scope with rationale |
| Assumptions | Conditions that must hold for the estimate to remain valid |
| Constraints | Fixed limits (budget cap, regulatory, team size, deadline) |

## Scope Levels

Each scope agent applies a different lens to the same brief.

### Conservative (Scope Agent A)
- Include core requirements only — the minimum viable deliverable set that solves the stated problem
- Apply a **20% timeline buffer** on top of the raw effort estimate
- Write strict exclusions — anything beyond the explicit brief is out
- Limit integrations to those the client already named; add no new ones
- Estimation percentile: **P90** (90th percentile of likely effort — err on the side of over-estimating)
- Change control posture: formal request required for any addition

### Balanced (Scope Agent B)
- Include core requirements plus 1–2 high-value additions that materially improve the outcome
- Apply a **10% timeline buffer** on top of the raw effort estimate
- Write moderate exclusions — explicitly cut lower-priority items to keep scope manageable
- Add one integration if it directly eliminates a manual handoff the brief implies
- Estimation percentile: **P75** (75th percentile — realistic with a reasonable cushion)
- Change control posture: small changes absorbed within the change budget; large changes formal

### Ambitious (Scope Agent C)
- Include the full vision implied by the brief, including stretch deliverables
- Apply **no timeline buffer** — use the raw effort estimate (optimistic but achievable)
- Write inclusive exclusions — only exclude items that are clearly a separate project
- Add integrations that unlock significant automation or data flow
- Estimation percentile: **P60** (60th percentile — optimistic, contingent on smooth execution)
- Change control posture: a change budget is built into the timeline; items can swap without a formal process

## Scope Boundary Rule

Every item encountered during scope definition must be explicitly classified. Ambiguity in scope is the primary cause of SOW disputes.

- "Included" items appear in the deliverables list with acceptance criteria
- "Excluded" items appear in the exclusions list with a rationale and a recommended path (Phase 2, separate engagement, client-side responsibility)
- **There is no middle ground.** "We will try to include X" is not a valid scope statement.

## Effort Estimation

### Task Breakdown

Break total project work into discrete task areas before summing:

| Task area | Typical share of effort |
|-----------|------------------------|
| Discovery and requirements | 5–10% |
| Design and architecture | 10–20% |
| Implementation | 40–55% |
| Testing and QA | 15–20% |
| Documentation | 5–10% |
| Project management overhead | 10–15% |

Never estimate the project as a single number. Break it down first, then sum.

### T-Shirt Sizing Sanity Check

Use T-shirt sizes as a cross-check before committing to hour estimates:

| Size | Hours | Typical scope |
|------|-------|--------------|
| S | 8 h | Single feature or screen, clear requirements |
| M | 20 h | Small module, 2–4 deliverables |
| L | 40 h | Full feature set, cross-functional dependencies |
| XL | 80 h | Complex system, multiple integrations |
| XXL | 160 h+ | Multi-phase program; break into phases |

If a single deliverable sizes as XXL, recommend splitting it into phases rather than estimating it as one line item.

### Overhead Rules

- Add **10–15% of total effort** for project management (communications, status reporting, scope change processing)
- Add **15–20% of implementation effort** for QA and testing (not the full project effort — implementation only)
- Apply the percentile adjustment for the scope level last, after summing all task areas and overhead

### Percentile Adjustment

Apply percentile adjustments to the summed estimate, not to individual task areas:

- Conservative (P90): multiply the summed estimate by **1.20**
- Balanced (P75): multiply the summed estimate by **1.10**
- Ambitious (P60): multiply the summed estimate by **1.00** (no adjustment)

## Deliverable Definition Rules

Format every deliverable as a four-part entry:

**[Name]** — [Description of what is produced] — [Acceptance criteria] — [Milestone week]

Example: **User Authentication Module** — Login, registration, and password reset flows with JWT session management — All flows pass QA checklist; 0 critical bugs in staging — Week 3

Rules:
- Make the name a proper noun (capitalize it); it will appear in the final SOW document
- Descriptions must specify what is delivered, not what activity will occur ("3 documented API endpoints" not "API development work")
- Acceptance criteria must be binary — either the criterion is met or it is not
- Every deliverable must be tied to a milestone week
- Include documentation as a first-class deliverable. Never bury it in a footnote or fold it into another deliverable. Documentation stands on its own line with its own acceptance criteria

Avoid vague deliverable names:
- "Consulting" — replace with the specific output (e.g., "Architecture Decision Record with 3 evaluated options")
- "Support" — replace with the time-bounded artifact (e.g., "Post-launch support runbook and 2-week hypercare period")
- "Optimization" — replace with the measurable target (e.g., "Database query optimization reducing average response time below 200ms")

## Exclusion Rationale Patterns

Apply standard exclusions as a starting checklist. Not all will apply to every project — use judgment.

| Exclusion | Recommended path |
|-----------|-----------------|
| Features scoped to a future phase | "Phase 2 — revisit after [milestone]" |
| Nice-to-have features not in the brief | "Phase 2 if budget allows" |
| Infrastructure provisioning (if not stated) | "Client-side responsibility — provide credentials and access" |
| Third-party vendor dependencies | "Client to own vendor relationship; SOW covers integration only" |
| Training and change management (if not requested) | "Separate engagement upon request" |
| Performance optimization beyond baseline | "Post-launch optimization sprint — separate engagement" |
| Ongoing maintenance | "Maintenance retainer — separate agreement" |
| Data migration (if not stated) | "Requires separate data migration assessment" |

State the exclusion precisely: name the exact feature or activity being excluded, not a category. "All future enhancements" is not a valid exclusion. "Push notification system" is.

## Assumptions and Constraints Framework

### Assumptions

Assumptions are conditions that, if false, invalidate the estimate. Only include testable assumptions — ones the client can confirm or deny before signing.

**Client assumptions:**
- Feedback turnaround within N business days (state the number)
- A named point of contact is available for weekly check-ins
- Access to required systems, APIs, and credentials provided by start date
- Requirements are stable after the discovery phase; changes after that date trigger change control

**Technical assumptions:**
- The client's existing tech stack (name the versions if known)
- Integration endpoints are available and documented
- Existing infrastructure meets the stated performance baseline
- Third-party APIs used are in a stable release (not beta)

**Constraints** (things that cannot change):
- Budget ceiling (if stated in the brief)
- Hard delivery deadline (if stated)
- Team size or named resource constraints
- Regulatory or compliance requirements (GDPR, HIPAA, SOC 2, etc.)

### Invalidation Rule

If an assumption is wrong, state explicitly what changes. Example: "If the client cannot provide API access by Week 1, the implementation phase shifts by the number of days delayed — timeline and cost adjust accordingly." This language protects the vendor and sets clear expectations.

## Change Management by Scope Level

Build the change management language into the scope proposal. The synthesis lead will carry this language into the final SOW packages.

### Conservative
- All scope additions require a formal Change Request signed by both parties before work begins
- Pricing for changes is calculated at the agreed hourly rate
- Timeline extends by the hours required; no acceleration implied

### Balanced
- Changes under N hours (recommend 8h as the threshold) are absorbed into the project without a formal change request, up to a cumulative cap of 2 changes per milestone
- Changes exceeding the threshold follow the formal Change Request process
- Timeline is extended only for changes that affect the critical path

### Ambitious
- A **change budget** (recommend 10% of total hours) is included in the project timeline
- Items within the original scope can be swapped for items of equivalent effort without a formal process
- Net-new additions beyond the change budget follow the formal Change Request process

## Scope Proposal Output Structure

Each scope agent must produce a proposal with exactly these sections in order:

1. **Scope Summary** — 2–3 sentence plain-language description of what this option covers and why
2. **Deliverables** — numbered list using the four-part format
3. **Effort Estimate** — task area breakdown table, then total hours, then percentile-adjusted total
4. **Timeline** — milestone table with week numbers and deliverables attached
5. **Exclusions** — numbered list with rationale for each
6. **Assumptions** — bulleted list, client and technical separated
7. **Constraints** — bulleted list
8. **Change Management** — one paragraph matching the scope level's posture

Do not add sections. Do not omit sections. The synthesis lead and risk/pricing agents depend on this consistent structure.
