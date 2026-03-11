# SOP Section Reference

Detailed per-section guidelines for the 7-section SOP structure. This file is the authoritative reference for section content, formatting, minimum requirements, and common mistakes. Read this file in full before writing any SOP.

---

## Section 1: Workflow Overview

### Purpose

Establish the identity and scope of the workflow in a compact metadata block. Any reader should know within 10 seconds what the workflow does, who owns it, and when it was last verified.

### Required Content

| Field | Description | Format |
|-------|-------------|--------|
| Workflow Name | Clear, descriptive name using title case | Plain text, 3-8 words |
| Purpose | One-sentence statement of what the workflow accomplishes | Start with an action verb ("Process...", "Generate...", "Route...") |
| Owner | Person or role responsible for maintaining the SOP | Name and role/title |
| Last Updated | Date the SOP was last reviewed or modified | YYYY-MM-DD format |

### Optional Content

| Field | Description | When to Include |
|-------|-------------|-----------------|
| Version | SOP version number | When the organization tracks document versions |
| Frequency | How often the workflow runs | When it follows a schedule (daily, weekly, per-event) |
| Scope | Boundaries of what the workflow covers and does not cover | When the workflow name is ambiguous or overlaps with another process |
| Related SOPs | Cross-references to upstream or downstream workflows | When this workflow chains with others |

### Formatting Rules

- Present all fields as a definition list or a simple key-value table.
- Keep the entire section to 50-100 words. This is metadata, not narrative.
- Write the purpose statement as a single sentence starting with an action verb.

### Example Content

```
## Workflow Overview

| Field | Value |
|-------|-------|
| Workflow Name | Monthly Expense Report Submission |
| Purpose | Compile, categorize, and submit employee expense reports for finance team approval |
| Owner | Sarah Chen, Operations Manager |
| Last Updated | 2026-03-01 |
| Frequency | Monthly (1st-5th business day) |
```

### Minimum Requirements

- All four required fields must be present.
- Purpose statement must start with a verb and be one sentence.
- Date must be in YYYY-MM-DD format.

### Common Mistakes to Avoid

- Writing a multi-paragraph purpose statement. Keep it to one sentence.
- Using vague workflow names like "Process" or "Handling Things". Be specific.
- Omitting the owner field. Every SOP must have a named owner for accountability.
- Using relative dates ("last month") instead of absolute dates.
- Listing the workflow frequency in the purpose statement instead of as a separate field.

---

## Section 2: Prerequisites

### Purpose

List everything a person needs before starting the first step of the procedure. If a prerequisite is missing, the workflow cannot begin -- this section prevents false starts and mid-workflow blockers.

### Required Content

Organize prerequisites into three categories:

#### Tools and Systems

List every software application, platform, or physical tool required. Include version requirements when relevant.

| Tool | Purpose in Workflow | Access Level Required |
|------|--------------------|-----------------------|

#### Access and Credentials

List every account, permission, role, or credential the actor needs.

| Access Item | How to Obtain | Typical Lead Time |
|-------------|--------------|-------------------|

#### Knowledge and Skills

List any training, certifications, or domain knowledge the actor must have before executing the workflow. Link to training materials when available.

### Optional Content

| Category | When to Include |
|----------|-----------------|
| Input Documents | When the workflow requires specific files, templates, or data sets as starting materials |
| Environment Setup | When the workflow requires a specific machine configuration, environment variables, or network access |
| Definitions and Terminology | When the workflow uses domain-specific terms that may be unfamiliar to new team members |

### Formatting Rules

- Use tables for tools and access items. Tables make scanning fast and highlight gaps.
- Use a bulleted list for knowledge items.
- Sort items by criticality -- list blockers first, nice-to-haves last.
- Include actionable instructions for obtaining each prerequisite (e.g., "Request Jira access from IT via Slack #it-requests").

### Example Content

```
## Prerequisites

### Tools and Systems

| Tool | Purpose in Workflow | Access Level Required |
|------|--------------------|-----------------------|
| Notion | Store and track expense records | Editor access to Finance workspace |
| Gmail | Receive expense receipts from employees | Standard account |
| Google Sheets | Expense calculation template | Viewer access minimum |

### Access and Credentials

| Access Item | How to Obtain | Typical Lead Time |
|-------------|--------------|-------------------|
| Finance Notion workspace | Request from Finance Manager via Slack #finance | 1 business day |
| Expense template (Google Sheets) | Auto-shared on first use via link in Step 1 | Immediate |

### Knowledge and Skills

- Understand the company's 14-category expense taxonomy (see Appendix A).
- Complete the "Expense Processing 101" onboarding module in the LMS.
- Know how to verify receipt authenticity (date, vendor, amount visible).
```

### Minimum Requirements

- At least one entry in the Tools category.
- At least one entry in the Access category (even if access is "none required beyond standard employee account").
- Knowledge section may be omitted only when the workflow requires no specialized knowledge.

### Common Mistakes to Avoid

- Listing tools without specifying the required access level. "Notion" is insufficient -- specify "Editor access to Finance workspace".
- Omitting the "How to Obtain" column for access items. The SOP reader needs to know how to get unblocked.
- Assuming prerequisite knowledge is obvious. State it explicitly even if it seems basic.
- Mixing prerequisites with procedural steps. "Log into Notion" is a step, not a prerequisite. "Have Notion Editor access" is a prerequisite.
- Forgetting to list templates or input files that must exist before the workflow begins.

---

## Section 3: Step-by-Step Procedure

### Purpose

Define the exact sequence of actions that transform inputs into outputs. This is the operational core of the SOP. A person with zero prior context (but all prerequisites met) should be able to execute the workflow by following these steps verbatim.

### Required Content

Present every step in a numbered table with four columns:

| Step # | Actor | Action | Expected Output |
|--------|-------|--------|-----------------|

- **Step #**: Sequential integer. Use sub-steps (3a, 3b, 3c) for granular actions within a logical step.
- **Actor**: The person or role performing the action. Use the same role title consistently throughout. When the actor is the same as the previous step, repeat the actor name -- do not use "Same" or ditto marks.
- **Action**: An imperative instruction starting with an action verb. Maximum 30 words. One action per step -- never combine two distinct actions with "and" or "then" (split into separate steps).
- **Expected Output**: What the actor should see, produce, or verify after completing the action. Be specific: "Confirmation email received" not "Done".

### Optional Content

| Element | When to Include |
|---------|-----------------|
| Notes column | When specific steps have warnings, tips, or exceptions |
| Time estimates | When SLA compliance matters or when steps have timeout constraints |
| Screenshots | When the action involves a complex UI interaction |
| Sub-step grouping | When 3+ sub-steps logically belong to one parent step |

### Formatting Rules

- Number all steps sequentially starting at 1. Do not skip numbers.
- Start every action with an imperative verb: Open, Click, Verify, Send, Create, Update, Review, Approve, Reject, Forward, Copy, Paste, Enter, Select, Navigate, Download, Upload, Save, Delete, Archive, Export, Import, Calculate, Compare, Confirm, Notify.
- Keep each action to one atomic operation. "Open the dashboard, review the metrics, and flag anomalies" is three steps, not one.
- When the actor changes between consecutive steps, this signals a handoff -- document it in Section 5.
- When a step contains a conditional ("if X, then Y"), extract the conditional to Section 4 and reference it: "See Decision Point D1."
- Write expected outputs as observable, verifiable states: "Invoice status changes to 'Approved' in the dashboard" not "Invoice is processed."

### Example Content

```
## Step-by-Step Procedure

| Step # | Actor | Action | Expected Output |
|--------|-------|--------|-----------------|
| 1 | Operations Manager | Open the Expense Tracker Notion database and filter by Status = "Pending" | List of unprocessed expense entries appears |
| 2 | Operations Manager | Select the oldest pending entry and open its detail page | Entry detail page displays with receipt attachment |
| 3 | Operations Manager | Verify the receipt image shows a legible date, vendor name, and total amount | All three fields are readable on the receipt |
| 4 | Operations Manager | Compare the receipt total to the Amount field in the database entry | Amounts match within $0.50 tolerance |
| 4a | Operations Manager | If amounts do not match, see Decision Point D1 | -- |
| 5 | Operations Manager | Assign the expense to one of the 14 categories using the Category dropdown | Category field is populated |
| 6 | Operations Manager | Change the entry Status from "Pending" to "Reviewed" | Status badge updates to "Reviewed" |
| 7 | Operations Manager | Notify the Finance Manager via Slack #finance with the entry link | Slack message sent with Notion page URL |
| 8 | Finance Manager | Open the Notion entry link from the Slack notification | Entry detail page loads in Notion |
| 9 | Finance Manager | Review the category assignment and receipt for accuracy | Review complete, no discrepancies found |
| 10 | Finance Manager | Change the entry Status from "Reviewed" to "Approved" | Status badge updates to "Approved" |
```

### Minimum Requirements

- Every step has all four columns populated (Step #, Actor, Action, Expected Output).
- No action exceeds 30 words.
- Every action starts with an imperative verb.
- No passive voice in any action.
- At least 3 steps (workflows with fewer than 3 steps are too trivial for a formal SOP).

### Common Mistakes to Avoid

- Combining multiple actions into one step with "and" or "then". Split them.
- Writing vague actions: "Handle the expense" -- handle how? Be specific.
- Writing vague outputs: "Done" or "Completed" -- what changed? What does the actor see?
- Using passive voice: "The report is generated" -- who generates it? Write "Generate the report."
- Omitting the actor when it changes. Every step must explicitly name the actor.
- Using different titles for the same role across steps ("Manager" in Step 1, "Ops Lead" in Step 5 for the same person).
- Including decision logic inline instead of extracting it to Section 4.
- Writing steps that assume knowledge not listed in Section 2.
- Numbering gaps (jumping from Step 3 to Step 5).

---

## Section 4: Decision Points

### Purpose

Map every conditional branch in the workflow. Each decision point represents a fork where the workflow takes one of two or more paths based on specific criteria. Extract these from Section 3 and document the criteria, paths, and consequences explicitly.

### Required Content

Document each decision point in a structured format:

| Decision ID | Decision Question | Criteria | Yes/True Path | No/False Path |
|-------------|-------------------|----------|---------------|---------------|

- **Decision ID**: Use the prefix `D` followed by a sequential number (D1, D2, D3).
- **Decision Question**: Frame as a yes/no question when possible. Use specific, measurable criteria -- never subjective ("Is it good enough?").
- **Criteria**: Define the exact threshold, value, or condition that determines the branch. Quantify whenever possible ("Amount > $5,000" not "Amount is large").
- **Yes/True Path**: State the action and the step number it routes to.
- **No/False Path**: State the action and the step number it routes to.

### Optional Content

| Element | When to Include |
|---------|-----------------|
| Multi-branch decisions | When more than two paths exist (use a separate row per branch) |
| Escalation path | When one branch leads to an exception handler outside the normal workflow |
| Decision authority | When different roles have authority over different decision points |

### Formatting Rules

- Reference decision points in Section 3 using the Decision ID: "See Decision Point D1."
- Include the decision point in the Mermaid diagram as a diamond node.
- When a decision has more than two branches, use a separate row for each branch with the same Decision ID.
- Order decision points by their occurrence in the step sequence.

### Example Content

```
## Decision Points

| Decision ID | Decision Question | Criteria | Yes Path | No Path |
|-------------|-------------------|----------|----------|---------|
| D1 | Does the receipt amount match the database entry? | Amounts within $0.50 tolerance | Continue to Step 5 (assign category) | Flag entry as "Discrepancy", notify submitter via email, hold until corrected |
| D2 | Is the expense amount above the VP approval threshold? | Amount > $5,000.00 | Route to VP for approval (Step 11) | Manager approval sufficient (continue to Step 10) |
| D3 | Has the submitter provided a corrected receipt within 5 business days? | Corrected receipt uploaded to entry AND amounts now match | Return to Step 3 (re-verify) | Close entry as "Rejected", notify submitter |
```

### Minimum Requirements

- One entry for every conditional branch identified in Section 3.
- Every decision uses measurable, objective criteria (no "if appropriate" or "if needed").
- Both paths (Yes and No) are documented with specific routing instructions.

### Common Mistakes to Avoid

- Using subjective criteria: "If the expense seems reasonable" -- define "reasonable" with a number or rule.
- Documenting only the "happy path" and ignoring the failure/rejection branch.
- Failing to cross-reference the Decision ID in Section 3.
- Creating decision points that do not appear in the step-by-step procedure.
- Using vague routing: "Handle accordingly" -- specify the exact step or action.
- Forgetting to include the decision in the Mermaid diagram.

---

## Section 5: Handoff Protocol

### Purpose

Document every transfer of responsibility between actors in the workflow. A handoff occurs when the person performing the next step is different from the person who performed the previous step. Incomplete or unclear handoffs are the most common source of workflow failures.

### Required Content

Document each handoff in a structured format:

| Handoff ID | From (Role) | To (Role) | Trigger | Artifact(s) Transferred | Acceptance Criteria |
|------------|-------------|-----------|---------|--------------------------|---------------------|

- **Handoff ID**: Use the prefix `H` followed by a sequential number (H1, H2, H3).
- **From**: The role completing their portion and transferring responsibility.
- **To**: The role receiving the work and continuing the workflow.
- **Trigger**: The specific event or action that initiates the handoff (e.g., "Status changed to 'Reviewed'" or "Slack notification sent").
- **Artifact(s) Transferred**: The specific deliverables, files, links, or data that the receiving actor needs. Be exhaustive -- missing artifacts cause handoff failures.
- **Acceptance Criteria**: The conditions the receiving actor verifies before accepting the handoff. If these criteria are not met, the receiving actor rejects the handoff and sends it back.

### Optional Content

| Element | When to Include |
|---------|-----------------|
| SLA / Time Constraint | When the handoff must occur within a specific timeframe |
| Fallback Contact | When the primary receiving actor may be unavailable |
| Communication Channel | When the handoff notification happens outside the primary tool |

### Formatting Rules

- Identify handoffs by scanning Section 3 for changes in the Actor column between consecutive steps.
- Cross-reference the step numbers where each handoff occurs.
- Include the handoff in the Mermaid diagram (the edge between nodes with different actors).
- Order handoffs by their occurrence in the step sequence.

### Example Content

```
## Handoff Protocol

| Handoff ID | From | To | Trigger | Artifact(s) Transferred | Acceptance Criteria |
|------------|------|-----|---------|--------------------------|---------------------|
| H1 | Operations Manager | Finance Manager | Slack notification sent in Step 7 | Notion entry link with reviewed expense, attached receipt, assigned category | Receipt is legible, category is assigned, amounts match |
| H2 | Finance Manager | VP of Finance | Email notification sent in Step 11 | Notion entry link, approval request with justification, expense amount and category | Entry is complete, amount exceeds $5,000, category is valid |
```

### Minimum Requirements

- One entry for every actor change in Section 3.
- Every handoff specifies the trigger, artifacts, and acceptance criteria.
- Acceptance criteria are specific and verifiable (not "everything looks good").

### Common Mistakes to Avoid

- Assuming the receiving actor knows what to do without explicit artifacts and criteria.
- Omitting the communication channel -- how does the receiver know the handoff happened?
- Writing vague acceptance criteria: "Check that everything is correct" -- correct how? Define it.
- Failing to define the rejection path. What happens when acceptance criteria are not met?
- Missing handoffs that happen outside the primary system (e.g., a verbal approval, a Slack DM).
- Confusing handoffs with decision points. A handoff is a change of actor; a decision point is a change of path.

---

## Section 6: Troubleshooting

### Purpose

Provide a diagnostic reference for common failure modes. When something goes wrong during workflow execution, the actor consults this section before escalating. Every entry maps an observable symptom to its root cause and resolution steps.

### Required Content

Present all entries in a three-column table:

| Symptom | Cause | Resolution |
|---------|-------|------------|

- **Symptom**: Describe what the actor observes. Use specific, visible indicators ("Error 403 appears when opening the dashboard", "Status field is grayed out and unclickable").
- **Cause**: State the root cause in one sentence. Be definitive, not speculative.
- **Resolution**: Provide 1-3 numbered imperative steps to resolve the issue. Follow the same writing style rules as Section 3.

### Required Entry Types

Generate entries from three sources:

1. **Decision point failures** (1 per decision point in Section 4): Cover the scenario where the criteria are ambiguous, data is missing, or the wrong branch was taken.
2. **Handoff failures** (1 per handoff in Section 5): Cover the scenario where the handoff artifact is incomplete, the notification was not received, or the acceptance criteria cannot be verified.
3. **Escalation entry** (always 1, always last): Cover the catch-all scenario when the above resolutions do not work.

### Formatting Rules

- Order entries by likelihood of occurrence (most common first, escalation last).
- Keep symptom descriptions to one sentence. If a symptom has multiple manifestations, list the most common one and note variants in the cause.
- Keep resolutions to 3 steps maximum. If resolution requires more than 3 steps, it belongs in a separate sub-procedure.
- The escalation entry is always the final row.

### Example Content

```
## Troubleshooting

| Symptom | Cause | Resolution |
|---------|-------|------------|
| Receipt image is blurry or unreadable in Step 3 | Submitter uploaded a low-resolution photo or screenshot | 1. Change entry Status to "Needs Correction". 2. Email the submitter requesting a re-scan at 300 DPI minimum. 3. Hold the entry until corrected receipt is uploaded. |
| Slack notification in Step 7 is not received by Finance Manager | Finance Manager has Slack notifications paused or has left the #finance channel | 1. Verify the Finance Manager is a member of #finance. 2. Send a direct Slack message with the entry link. 3. If still unreachable, send an email to their company address with the same information. |
| Category dropdown in Step 5 does not show all 14 categories | Notion database schema was modified or category options were deleted | 1. Open the Expense Tracker database settings. 2. Navigate to the Category property configuration. 3. Compare against the canonical 14-category list in the Prerequisites section and restore missing entries. |
| Issue persists after following all resolution steps above | Root cause falls outside this SOP's scope | 1. Document the symptom, the steps attempted, and the current state of the workflow entry. 2. Contact the Operations Manager via Slack DM. 3. Include "SOP: Monthly Expense Report Submission" and the relevant section reference in the message. |
```

### Minimum Requirements

- Minimum 3 entries, maximum 10 entries.
- Every entry has all three columns populated.
- Resolution steps use imperative verbs and present tense.
- The escalation entry is present and is the final row.
- The escalation entry references the SOP name and the workflow owner from Section 1.

### Common Mistakes to Avoid

- Writing vague symptoms: "Something is wrong with the system" -- describe the observable indicator.
- Writing speculative causes: "Might be a permissions issue" -- state the definitive cause. If multiple causes exist, create separate entries for each.
- Writing resolutions that require expertise not listed in Section 2 prerequisites.
- Omitting the escalation entry. Every SOP must have one.
- Including more than 10 entries. Prioritize by frequency and severity, then truncate.
- Writing resolution steps longer than 3 actions. Break complex resolutions into a sub-procedure referenced by link.
- Listing symptoms that are not actually observable by the workflow actor (e.g., server-side errors the actor cannot see).

---

## Section 7: Revision History

### Purpose

Track all changes to the SOP over time. Every modification -- from typo fixes to structural overhauls -- receives an entry. This section creates an audit trail and helps readers verify they are working with the current version.

### Required Content

Present all entries in a four-column table:

| Date | Version | Author | Change Summary |
|------|---------|--------|----------------|

- **Date**: The date the change was made, in YYYY-MM-DD format.
- **Version**: The version number after the change. Use semantic-style versioning: major.minor (e.g., 1.0, 1.1, 2.0). Increment major for structural changes (adding/removing sections, changing step order). Increment minor for content updates (clarifications, typo fixes, threshold adjustments).
- **Author**: Name and role of the person who made the change.
- **Change Summary**: One sentence describing what changed and why. Be specific enough that a reader can understand the scope without reading the full SOP.

### Optional Content

| Element | When to Include |
|---------|-----------------|
| Approval | When changes require sign-off from a reviewer or process owner |
| Review Schedule | When the SOP has a mandatory periodic review cycle |
| Retirement Date | When the SOP has a known expiration or replacement date |

### Formatting Rules

- Order entries in reverse chronological order (most recent first).
- The initial creation entry is always present and is always the last row.
- Write change summaries in past tense (this is the one exception to the present-tense rule -- revision history describes completed changes).
- Keep change summaries to one sentence.

### Example Content

```
## Revision History

| Date | Version | Author | Change Summary |
|------|---------|--------|----------------|
| 2026-03-01 | 1.1 | Sarah Chen, Operations Manager | Updated VP approval threshold from $3,000 to $5,000 per new finance policy FP-2026-04 |
| 2026-01-15 | 1.0 | Sarah Chen, Operations Manager | Initial SOP creation |
```

### Minimum Requirements

- At least one entry (the initial creation entry).
- All four columns populated for every entry.
- Date in YYYY-MM-DD format.
- Version number present and follows major.minor convention.

### Common Mistakes to Avoid

- Omitting the revision history section entirely. Every SOP must track its own changes.
- Writing vague change summaries: "Updated the document" -- specify what changed.
- Using inconsistent date formats (mixing MM/DD/YYYY with YYYY-MM-DD).
- Forgetting to update the Last Updated field in Section 1 when adding a revision history entry.
- Incrementing the major version for minor changes (typo fixes do not warrant a major version bump).
- Not recording the reason for the change -- always include "why" in addition to "what" when the reason is not self-evident.

---

## Cross-Section Consistency Checks

After completing all sections, run these consistency checks before finalizing the SOP:

1. **Actor consistency**: Verify that every role name in Section 3 appears in Section 2's prerequisites (access/tools) and matches the handoff roles in Section 5.
2. **Decision traceability**: Verify that every Decision ID referenced in Section 3 has a corresponding entry in Section 4 and a corresponding diamond node in the Mermaid diagram.
3. **Handoff traceability**: Verify that every actor change in Section 3 has a corresponding entry in Section 5.
4. **Troubleshooting coverage**: Verify that Section 6 has at least one entry per decision point (Section 4) and one per handoff (Section 5), plus the escalation entry.
5. **Terminology alignment**: Verify that tool names, role titles, and domain terms are identical across all sections. Search for synonyms and standardize.
6. **Date alignment**: Verify that the Last Updated date in Section 1 matches the most recent entry in Section 7.
7. **Prerequisite completeness**: Verify that every tool, system, or access item mentioned in Sections 3-6 appears in Section 2.
8. **Output verifiability**: Verify that every Expected Output in Section 3 describes an observable, verifiable state (not "done" or "completed").
