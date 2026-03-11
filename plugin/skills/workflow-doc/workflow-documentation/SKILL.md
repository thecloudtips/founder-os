---
name: Workflow Documentation
description: "Parses and structures business processes into standardized workflow documentation with actors, tools, and handoffs. Activates when the user wants to document a workflow, map a process, create a runbook, or asks 'capture how this process works.' Decomposes operational workflows into multi-step documents with complexity assessment."
globs:
  - "commands/workflow-*.md"
---

# Workflow Documentation

Parse workflow descriptions from any input format into structured, standardized process documents with discrete steps, identified tools, detected handoffs, and scored complexity. Used by: `/founder-os:workflow:document` (full SOP generation) and `/founder-os:workflow:diagram` (visual workflow rendering).

## Purpose and Context

Transform unstructured workflow descriptions -- whether pasted prose, bullet lists, file contents, or conversational explanations -- into a normalized workflow data structure that downstream commands can render as SOPs, runbooks, Mermaid diagrams, or Notion pages. Every workflow produced by this skill follows a consistent schema: numbered steps with actor-action-tool-output tuples, a deduplicated tool inventory, explicit handoff points, and a complexity score. The goal is capture, not invention -- extract what the user describes, never fabricate steps or actors that are not present in the source material.

---

## Workflow Decomposition

Break raw workflow input into structured components regardless of how the user provides it. Handle these input shapes:

### Prose Paragraphs

Scan for sequential action signals: temporal markers ("first", "then", "next", "after that", "finally", "once X is done"), causal connectors ("so that", "which triggers", "resulting in"), and imperative verbs ("send", "review", "approve", "upload", "create"). Split on these boundaries to identify discrete steps. When prose is ambiguous about step boundaries, prefer more granular splitting -- it is easier to merge steps than to split them later.

### Bullet and Numbered Lists

Treat each top-level bullet or numbered item as one candidate step. Nested sub-bullets represent sub-actions within that step -- collapse them into the parent step's action description rather than promoting them to separate steps. If a single bullet contains multiple distinct actions joined by "and" or semicolons, split into separate steps only when the actions involve different actors or tools.

### Mixed Format

When input combines prose and lists (common in pasted Notion pages or Google Docs), process each format block independently, then merge into a single sequential step list. Maintain the order as presented in the source.

### Table Format

When input arrives as a table (markdown or pasted), map columns to step fields directly. Common column headers and their mappings: "Step" or "#" maps to step number, "Action" or "Task" or "Description" maps to action, "Owner" or "Who" or "Responsible" maps to actor, "Tool" or "System" maps to tool, "Output" or "Result" or "Deliverable" maps to output.

---

## Step Extraction

Extract each workflow step as a four-field tuple: actor, action, tool, and output. Enforce a maximum of 20 steps per workflow.

### Step Fields

| Field | Description | Default When Missing |
|-------|-------------|---------------------|
| actor | The person, role, or team performing the action | "Unspecified" |
| action | The verb-led description of what happens | Required -- skip the step if no action can be identified |
| tool | The software, hardware, document, or human resource used | "None" |
| output | The artifact, state change, or deliverable produced | "None" |

### Actor Extraction

Identify actors from explicit naming ("the designer", "John", "sales team", "the client"), pronoun resolution (resolve "they", "she", "he" to the most recently named actor), role-based references ("the reviewer", "the approver", "whoever receives the form"), and positional inference (the first actor mentioned in a workflow is often the initiator of subsequent unattributed steps).

When the same actor is described differently across steps ("the designer", "the design team", "design"), normalize to a single canonical name using the most specific version found.

### Action Extraction

Write every action in verb-first imperative form. Transform passive constructions into active ones:
- "The report is reviewed by the manager" becomes actor: Manager, action: "Review the report"
- "An email gets sent" becomes actor: Unspecified, action: "Send an email"
- "Approval happens" becomes actor: Unspecified, action: "Approve the deliverable"

Keep actions concise -- one sentence, under 120 characters. If a source step contains multiple sequential sub-actions, preserve them as a single action description joined by "then" only when they share the same actor and tool. Otherwise, split into separate steps.

### Tool Extraction

Identify tools mentioned explicitly ("in Slack", "using Figma", "via the CRM", "on the shared drive") or implied by the action context ("send an email" implies an email client, "update the spreadsheet" implies a spreadsheet application). When a tool is implied but not named, use the generic category name (e.g., "Email client", "Spreadsheet application") rather than guessing a specific product.

### Output Extraction

Identify outputs from result language ("produces a report", "generates an invoice", "results in an approved design"), state changes ("status changes to Approved", "ticket moves to Done"), deliverable references ("the signed contract", "the final PDF"), and handoff artifacts ("passes the brief to engineering").

### Step Limit Enforcement

Enforce a hard maximum of 20 steps per workflow. When the decomposed workflow exceeds 20 steps:

1. Warn the user: "This workflow contains [N] steps. The maximum is 20. Capturing the first 20 steps. Consider splitting this into sub-workflows for steps 21+."
2. Capture only the first 20 steps in sequence order.
3. Note the truncation in the workflow metadata with the total step count before truncation.

Do not silently drop steps. Do not attempt to merge steps to fit the limit -- that risks losing fidelity.

---

## Tool Identification

Classify every tool referenced across all steps into one of four types:

| Type | Definition | Examples |
|------|-----------|----------|
| Software | Digital application, platform, or service | Slack, Notion, Gmail, Figma, Jira, Google Sheets, CRM |
| Hardware | Physical device or equipment | Scanner, printer, label maker, POS terminal, camera |
| Document | Template, form, checklist, or reference material | Intake form, checklist template, contract template, style guide |
| Human | Person or team acting as a resource (not the step actor) | Legal counsel, external vendor, client, subject matter expert |

### Classification Rules

- A tool is Software when it refers to a named application, SaaS product, or digital system.
- A tool is Hardware when it refers to a physical device required to complete the step.
- A tool is Document when it refers to a template, form, or reference material consumed or produced during the step -- but only when the document is a tool used to perform the action, not the output of the action.
- A tool is Human when the step requires input, approval, or expertise from a specific person or role who is not the step's primary actor. The distinction: the actor performs the step; a Human tool is consulted or required during the step.

### Deduplication

Build a single deduplicated tool inventory across all steps. Normalize tool names before comparison:
- Case-insensitive matching ("Slack" and "slack" are the same tool).
- Remove articles and prepositions ("the CRM", "in Notion", "via Slack" all normalize to the tool name alone).
- Merge synonyms only when clearly the same tool ("Google Docs" and "Docs" are the same; "Google Docs" and "Word" are not).
- Preserve the most specific name encountered ("Google Sheets" over "spreadsheet" when both appear).

The final tool inventory lists each unique tool once with its type and the step numbers where it appears.

---

## Handoff Detection

Detect handoffs wherever responsibility transfers between actors across consecutive steps.

### Handoff Rules

1. **Actor change**: When step N has actor A and step N+1 has actor B (and A != B), mark a handoff between steps N and N+1.
2. **Approval/review gates**: Any step whose action contains "approve", "review", "sign off", "authorize", "validate", or "confirm" constitutes a handoff point, even when the actor does not change. These are decision gates where work may be returned or rejected.
3. **External handoffs**: When an actor transitions from an internal role to an external party (client, vendor, regulatory body) or vice versa, flag this as an external handoff. External handoffs carry higher process risk.
4. **Unspecified actor transitions**: When a step has actor "Unspecified" and the adjacent step has a named actor, do not count this as a handoff. Only count handoffs between two identified, distinct actors.

### Handoff Data

For each detected handoff, capture:
- `from_step`: The step number where the handoff originates.
- `to_step`: The step number receiving the handoff.
- `from_actor`: The actor handing off.
- `to_actor`: The actor receiving.
- `type`: "actor_change", "approval_gate", or "external".
- `artifact`: The deliverable or information passed across the boundary (from the output of `from_step` or the action context).

---

## Complexity Assessment

Score the workflow complexity on a 1-4 scale derived from three dimensions: step count, decision points, and handoff count.

### Decision Point Detection

Count decision points by scanning step actions for conditional language: "if", "whether", "decide", "choose", "either...or", "depending on", "based on", "evaluate", "assess options", "determine which". Each unique decision point counts once regardless of how many branches it produces.

### Scoring Tiers

| Score | Label | Steps | Decisions | Handoffs |
|-------|-------|-------|-----------|----------|
| 1 | Simple | 1-5 | 0-1 | 0 |
| 2 | Moderate | 6-10 | 2-3 | 1-2 |
| 3 | Complex | 11-15 | 4-5 | 3-4 |
| 4 | Very Complex | 16-20 | 6+ | 5+ |

### Scoring Rules

1. Calculate the raw tier for each dimension independently (steps tier, decisions tier, handoffs tier).
2. Take the highest tier among the three dimensions as the base score. A workflow with 4 steps, 0 decisions, but 3 handoffs scores 3 (Complex), not 1 (Simple).
3. Never score below 1 or above 4.

Include the raw counts (steps, decisions, handoffs) alongside the final score so the user can see the scoring inputs.

---

## Input Source Handling

Accept workflow descriptions from three input channels. The command layer determines which channel applies based on user input.

### Inline Text

When the user provides workflow text directly in the command invocation or chat message:
- Accept the text as-is.
- Process immediately with no file I/O.
- Handle text of any length up to the model's context limit.

### File Input (--file Flag)

When the user provides a `--file` flag with a path:
- Read the file from the local filesystem using the Filesystem MCP server.
- Support these formats: `.md`, `.txt`, `.doc`, `.docx`, `.pdf`.
- Resolve relative paths from the current working directory.
- Use `${CLAUDE_PLUGIN_ROOT}` as the base for any plugin-internal file references.
- If the file cannot be read or does not exist, return an error: "File not found or cannot be read: [path]. Verify the file path and format."

### No Input (Interactive Prompt)

When neither inline text nor a `--file` flag is provided:
- Prompt the user via AskUserQuestion: "Describe the workflow you want to document. You can paste the full process description, or provide a file path with --file."
- Accept the response as inline text and proceed.
- Do not prompt more than once. If the user's response is empty or unclear, work with whatever was provided and note gaps in the output.

---

## Output Schema

Produce a structured workflow object with these fields for consumption by the command layer (commands render the final output format -- SOP, diagram, or Notion page):

```
workflow:
  title:              [Descriptive title derived from the workflow content]
  description:        [1-2 sentence summary of what the workflow accomplishes]
  source_type:        [inline | file | interactive]
  source_path:        [file path if source_type is file, else null]
  total_steps:        [integer, max 20]
  truncated:          [boolean, true if original exceeded 20 steps]
  original_step_count: [integer, only present when truncated is true]
  complexity:
    score:            [1-4]
    label:            [Simple | Moderate | Complex | Very Complex]
    steps_count:      [integer]
    decisions_count:  [integer]
    handoffs_count:   [integer]
  steps:
    - number:         [integer]
      actor:          [string]
      action:         [string, verb-first imperative]
      tool:           [string or "None"]
      tool_type:      [Software | Hardware | Document | Human | null]
      output:         [string or "None"]
      is_decision:    [boolean]
      is_approval:    [boolean]
  tools:
    - name:           [string, deduplicated canonical name]
      type:           [Software | Hardware | Document | Human]
      used_in_steps:  [list of step numbers]
  handoffs:
    - from_step:      [integer]
      to_step:        [integer]
      from_actor:     [string]
      to_actor:       [string]
      type:           [actor_change | approval_gate | external]
      artifact:       [string describing what is passed]
  actors:
    - name:           [string, canonical name]
      steps:          [list of step numbers where this actor appears]
```

The command layer consumes this schema to render the appropriate output: `/founder-os:workflow:document` produces a formatted SOP markdown document; `/founder-os:workflow:diagram` produces a Mermaid flowchart. This skill produces the data; the commands produce the presentation.

### Company Association

Populate Company relation for client-specific SOPs. When the workflow description references a specific client, company, or engagement, capture the company name so the command layer can set the Company relation when writing to Notion.

---

## Edge Cases

### Empty or Minimal Input

When the input contains fewer than 2 identifiable actions:
- Warn: "Input contains too few identifiable actions to document as a workflow. Provide a more detailed description of the process."
- Attempt extraction of whatever is available. A single-step workflow is valid (score: Simple).

### Circular or Looping Workflows

When a workflow loops back to a previous step ("repeat from step 3", "return to the beginning if rejected"):
- Capture the loop as a note on the relevant step rather than duplicating steps.
- Count the approval/rejection gate as a decision point and a handoff (if actors differ).
- Do not unroll loops into additional steps.

### Ambiguous Actors

When the same action could be attributed to multiple actors:
- Default to the most recently named actor in the workflow sequence.
- When genuinely ambiguous (no actor context at all), use "Unspecified" and note it.
- Never invent actor names. Use role descriptions from the source material.

### Duplicate Steps

When two steps describe the same action with the same actor and tool:
- Deduplicate by keeping the first occurrence.
- Note the deduplication in the output metadata.

### Overly Technical or Domain-Specific Language

Preserve domain-specific terminology in step actions and tool names. Do not simplify "Run the ETL pipeline" to "Process data" or "Deploy to staging via CI/CD" to "Launch the application." The user describes their actual workflow -- capture it in their language.
