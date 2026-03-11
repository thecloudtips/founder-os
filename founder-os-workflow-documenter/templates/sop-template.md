---
# <!-- YAML frontmatter: All values are populated by the SOP generation pipeline -->
workflow_name: "{{workflow_name}}"
# <!-- String: Human-readable workflow name, e.g. "Client Onboarding Process" -->
description: "{{description}}"
# <!-- String: 1-2 sentence summary of what this workflow accomplishes, e.g. "End-to-end process for onboarding new clients from signed contract to kickoff meeting." -->
owner: "{{owner}}"
# <!-- String: Person or role responsible for this workflow, e.g. "Operations Manager" or "Jane Smith" -->
complexity: "{{complexity}}"
# <!-- String enum: "Simple" | "Moderate" | "Complex" | "Very Complex" — based on step count, decision points, and handoff count -->
steps_count: {{steps_count}}
# <!-- Integer: Total number of procedural steps, e.g. 8 -->
generated_at: "{{generated_at}}"
# <!-- String ISO 8601 datetime: When this SOP was generated, e.g. "2026-03-05T14:30:00Z" -->
---

# {{workflow_name}} — Standard Operating Procedure
<!-- String: Same as frontmatter workflow_name -->

> **Owner:** {{owner}} | **Last Updated:** {{last_updated}} | **Complexity:** {{complexity}}
<!-- last_updated: String date in YYYY-MM-DD format, e.g. "2026-03-05" -->

---

## 1. Workflow Overview

**Name:** {{workflow_name}}

**Purpose:** {{purpose}}
<!-- String: 2-3 sentence explanation of why this workflow exists and what business outcome it drives. Example: "Ensures every new client receives a consistent onboarding experience, reducing time-to-value and improving retention." -->

**Owner:** {{owner}}

**Last Updated:** {{last_updated}}

**Trigger:** {{trigger}}
<!-- String: What initiates this workflow, e.g. "New contract signed in CRM" or "Client submits intake form" -->

**Frequency:** {{frequency}}
<!-- String: How often this workflow runs, e.g. "Per new client", "Weekly", "On demand" -->

---

## 2. Prerequisites

### Tools Required

<!-- Each tool entry has: name (String), type (String enum: "Software"|"Hardware"|"Service"|"API"|"Template"), access (String describing access requirements) -->

| Tool | Type | Access Required |
|------|------|-----------------|
{{#tools}}
| {{name}} | {{type}} | {{access}} |
{{/tools}}
<!-- Example row: | Notion | Software | Team workspace member | -->
<!-- Example row: | Gmail | Service | Google Workspace account with API access | -->
<!-- Example row: | Invoice Template | Template | Shared Drive > Templates folder | -->

### Knowledge Requirements

{{#knowledge_requirements}}
- {{requirement}}
{{/knowledge_requirements}}
<!-- Each requirement is a String describing prerequisite knowledge. Example entries:
  - "Familiarity with Notion database views and filters"
  - "Understanding of company pricing tiers"
  - "Access to client communication guidelines document"
-->

---

## Workflow Diagram

<!-- Mermaid flowchart: Always use flowchart TD (top-down). Never use graph or flowchart LR. -->

```mermaid
flowchart TD
{{#diagram_nodes}}
    {{node_definition}}
{{/diagram_nodes}}
{{#diagram_edges}}
    {{edge_definition}}
{{/diagram_edges}}
```

<!-- Example diagram content:
    A[Start: Contract Signed] --> B[Send Welcome Email]
    B --> C{Client Type?}
    C -->|Enterprise| D[Assign Account Manager]
    C -->|Standard| E[Assign Support Rep]
    D --> F[Schedule Kickoff]
    E --> F
    F --> G[End: Onboarding Complete]
-->
<!-- diagram_nodes: Array of objects with node_definition (String), e.g. "A[Start: Contract Signed]" -->
<!-- diagram_edges: Array of objects with edge_definition (String), e.g. "A --> B[Send Welcome Email]" -->

---

## 3. Step-by-Step Procedure

<!-- Each step entry has:
     step_number (Integer: sequential step number, e.g. 1),
     actor (String: person or role performing the action, e.g. "Account Manager"),
     action (String: specific instruction for what to do, e.g. "Create new client workspace in Notion using the Client Template"),
     tool (String: tool used for this step, e.g. "Notion", or "Manual" if no tool),
     expected_output (String: what the completed step produces, e.g. "Client workspace with pre-populated project board")
-->

| Step # | Actor | Action | Tool | Expected Output |
|--------|-------|--------|------|-----------------|
{{#steps}}
| {{step_number}} | {{actor}} | {{action}} | {{tool}} | {{expected_output}} |
{{/steps}}
<!-- Example row: | 1 | Operations Manager | Create client folder in shared drive | Google Drive | New folder at Clients/[Client Name]/ with subfolders | -->
<!-- Example row: | 2 | Account Manager | Send welcome email using template | Gmail | Welcome email sent with onboarding timeline | -->

{{#step_notes}}
> **Note on Step {{step_number}}:** {{note}}
{{/step_notes}}
<!-- step_notes: Optional array of objects with step_number (Integer) and note (String) for additional context on specific steps -->

---

## 4. Decision Points

{{#has_decisions}}
<!-- Decision entries have:
     decision_point (String: name/description of the decision, e.g. "Client requires custom integration?"),
     criteria (String: how to evaluate, e.g. "Client contract includes integration add-on OR client requests API access"),
     if_yes (String: action when criteria met, e.g. "Route to Engineering for integration setup — proceed to Step 6a"),
     if_no (String: action when criteria not met, e.g. "Skip integration steps — proceed to Step 7")
-->

| Decision Point | Criteria | If Yes | If No |
|----------------|----------|--------|-------|
{{#decisions}}
| {{decision_point}} | {{criteria}} | {{if_yes}} | {{if_no}} |
{{/decisions}}
<!-- Example row: | Client tier is Enterprise? | Contract value >= $50k/year | Assign dedicated account manager | Use pooled support team | -->
<!-- Example row: | Requires data migration? | Client has existing system with exportable data | Schedule migration sprint before kickoff | Proceed directly to kickoff | -->
{{/has_decisions}}

{{^has_decisions}}
No decision points identified in this workflow. All steps follow a linear sequence.
{{/has_decisions}}

---

## 5. Handoff Protocol

{{#has_handoffs}}
<!-- Handoff entries have:
     from (String: role or person handing off, e.g. "Sales Rep"),
     to (String: role or person receiving, e.g. "Account Manager"),
     trigger (String: what causes the handoff, e.g. "Contract signed and payment received"),
     transferred (String: what artifacts or context are passed, e.g. "Signed contract, client intake form, meeting notes from discovery calls")
-->

| From | To | Trigger | What Gets Transferred |
|------|----|---------|-----------------------|
{{#handoffs}}
| {{from}} | {{to}} | {{trigger}} | {{transferred}} |
{{/handoffs}}
<!-- Example row: | Sales Rep | Account Manager | Contract signed | Signed contract, client profile, discovery call notes, pricing agreement | -->
<!-- Example row: | Account Manager | Support Team | Kickoff complete | Client workspace URL, key contacts list, project timeline, SLA terms | -->
{{/has_handoffs}}

{{^has_handoffs}}
No handoffs identified in this workflow. All steps are performed by a single role.
{{/has_handoffs}}

---

## 6. Troubleshooting

<!-- Troubleshooting entries have:
     symptom (String: observable problem, e.g. "Client never responds to welcome email"),
     likely_cause (String: most common reason, e.g. "Email went to spam or wrong contact address on file"),
     resolution (String: steps to fix, e.g. "Verify email address in CRM, resend from personal address, follow up via phone after 48h")
-->

| Symptom | Likely Cause | Resolution |
|---------|--------------|------------|
{{#troubleshooting}}
| {{symptom}} | {{likely_cause}} | {{resolution}} |
{{/troubleshooting}}
<!-- Example row: | Kickoff meeting keeps getting rescheduled | Client stakeholders not identified early enough | Confirm all required attendees during intake, send calendar holds immediately | -->
<!-- Example row: | Notion workspace template fails to copy | Template page permissions changed | Verify template is shared with workspace, restore from backup in Templates archive | -->

---

## 7. Revision History

<!-- Revision entries have:
     date (String: date of revision in YYYY-MM-DD format, e.g. "2026-03-05"),
     author (String: who made the change, e.g. "Jane Smith"),
     change_summary (String: brief description of what changed, e.g. "Added enterprise tier decision point at Step 3")
-->

| Date | Author | Change Summary |
|------|--------|----------------|
{{#revisions}}
| {{date}} | {{author}} | {{change_summary}} |
{{/revisions}}
| {{generated_at_date}} | {{owner}} | Initial SOP generated by Workflow Documenter |
<!-- generated_at_date: String date in YYYY-MM-DD format extracted from generated_at timestamp -->

---

*Generated by Founder OS Workflow Documenter (P28) on {{generated_at}}*
