---
description: Transform a workflow description into a structured 7-section SOP with Mermaid diagram
argument-hint: "[description] [--file=PATH] [--format=notion|file|both] [--output=PATH]"
allowed-tools: ["Read", "Write"]
---

# Workflow Documenter

Transform a workflow description into a complete, structured SOP document with a Mermaid flowchart in one pass. This command executes the full pipeline without stopping for user input between phases.

## Load All Skills and Template

Read both skills and the template before starting any phase:

1. `${CLAUDE_PLUGIN_ROOT}/skills/workflow-documentation/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/skills/sop-writing/SKILL.md`
3. `${CLAUDE_PLUGIN_ROOT}/templates/sop-template.md`

Apply workflow-documentation for structured component extraction and sop-writing for document generation, formatting rules, and Mermaid diagram construction.

## Parse Arguments

Extract the description and flags from `$ARGUMENTS`:

- **description** (optional) — all text before any `--` flags. This is the workflow to document. If no description is provided and no `--file` flag is present, prompt the user via AskUserQuestion: "Describe the workflow you want to document." Then stop and wait for input.
- `--file=PATH` (optional) — read workflow description from a local file. If provided, read the file contents and combine with any inline description text (inline text first, then file contents).
- `--format=notion|file|both` (optional) — where to output the SOP. Default: `both`.
- `--output=PATH` (optional) — file path for saving the SOP. Default: `sops/sop-[workflow-slug]-[YYYY-MM-DD].md` where `workflow-slug` is the workflow name in lowercase kebab-case with special characters removed.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Phase 1 — Input Loading

Display: **"Phase 1/4: Loading inputs..."**

1. If `--file` flag is provided, read the file at the given path. If the file does not exist, display a clear error: "File not found: [PATH]. Please check the path and try again." Then stop.

2. Combine all input sources into a single workflow description:
   - Inline description text (from `$ARGUMENTS` before flags)
   - File contents (from `--file`)
   - If both are present, treat inline text as context/summary and file contents as the detailed description.

3. Apply the workflow-documentation skill to extract structured components from the combined input:
   - **Steps**: Ordered sequence of actions in the workflow
   - **Tools**: Software, systems, or platforms referenced
   - **Decision points**: Conditional branches or approvals
   - **Handoffs**: Points where responsibility transfers between people or teams
   - **Complexity score**: Tier classification based on step count, decision points, and handoff count

4. Display the extraction summary:

```
## Phase 1 Complete: Workflow Parsed

- **Workflow name**: [inferred name]
- **Steps identified**: [N]
- **Decision points**: [N]
- **Handoffs**: [N]
- **Tools detected**: [list]
- **Complexity**: [tier]
```

5. If the workflow exceeds 20 steps, display a warning: "This workflow has [N] steps. SOP will cover the first 20 steps. Consider breaking this into sub-workflows for the remaining steps." Continue with the first 20 steps.

Display: **"Extraction complete. Generating SOP..."**

## Phase 2 — Document Generation

Display: **"Phase 2/4: Generating SOP document..."**

1. Apply the sop-writing skill to produce all 7 sections following the template scaffold from `${CLAUDE_PLUGIN_ROOT}/templates/sop-template.md`. Generate each section using the extracted components from Phase 1:
   - Follow the template's section order and heading structure exactly
   - Fill in all template sections with content derived from the workflow analysis
   - Use clear, imperative language for procedural steps
   - Include role assignments at handoff points
   - Note decision criteria at each decision point

2. Generate a Mermaid flowchart following the sop-writing skill's Mermaid rules:
   - Use `flowchart TD` (top-down) direction
   - Map each step to a node
   - Map each decision point to a diamond (`{}`) node
   - Map each handoff to a labeled edge showing the responsible party transition
   - Keep node labels concise (max 40 characters)
   - Use subgraphs to group related phases when the workflow has clear stages

3. Assemble the complete SOP document:
   - YAML frontmatter (see Phase 3)
   - All 7 sections from the template
   - Mermaid diagram embedded in a fenced code block (```mermaid)
   - Append any warnings or notes at the end

## Phase 3 — File Output

Display: **"Phase 3/4: Saving files..."**

Only execute if `--format` includes "file" or "both" (default: yes):

1. Resolve the output path:
   - If `--output` is provided, use that path
   - Otherwise, default to `sops/sop-[workflow-slug]-[YYYY-MM-DD].md`

2. Create the parent directory if it does not exist.

3. Write the complete SOP to the output path with YAML frontmatter:

```yaml
---
workflow_name: "[inferred or stated name]"
complexity: "[Simple|Moderate|Complex|Very Complex]"
steps_count: [N]
generated_at: "[YYYY-MM-DDTHH:MM:SS]"
---
```

The SOP body follows the frontmatter, containing all 7 sections and the Mermaid diagram.

## Phase 4 — Notion Integration

Display: **"Phase 4/4: Updating Notion..."**

Only execute if `--format` includes "notion" or "both" (default: yes):

1. **Database discovery**: Search Notion for a database titled "[FOS] Workflows". If not found, try "Founder OS HQ - Workflows". If not found, fall back to "Workflow Documenter - SOPs" (legacy DB name). If none exists, skip Notion silently (do NOT create the database).

2. **Create or update page**: Upsert by Title + same calendar day, filtered by Type="SOP" to avoid collisions with Execution records. Populate these properties:

   | Property | Value |
   |----------|-------|
   | Title | title — Workflow/SOP name |
   | Type | select — "SOP" (always) |
   | Status | select — "Published" |
   | Description | rich_text — 1-2 sentence summary |
   | Steps Count | number — Total steps |
   | Tools Used | multi_select — Tools referenced in the procedure |
   | Handoff Points | number — Number of actor handoffs |
   | Complexity | select — Simple, Moderate, Complex, Very Complex |
   | SOP File Path | rich_text — Path to saved SOP file |
   | Diagram Included | checkbox — Whether Mermaid diagram was generated |
   | Generated At | date — Timestamp when SOP was generated |
   | Company | relation — Populate Company relation if the documented workflow is specific to a client engagement |

## Completion Block

Display the summary:

```
---

## SOP Complete

- **Workflow**: [workflow name]
- **Complexity**: [tier]
- **Steps**: [N] | **Decisions**: [N] | **Handoffs**: [N]
- **Tools**: [comma-separated list]
- **Diagram**: Included (Mermaid flowchart)

**File**: [output path or "skipped"]
**Notion**: [saved / skipped / unavailable]

Open [output path] to review or edit the SOP.
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Graceful Degradation

If Notion MCP is unavailable or any Notion operation fails:
- Complete the full pipeline and display all output in chat
- Save the file to the output path
- Do not warn or error about Notion — chat and file output are fully sufficient

If `--format=file`: skip Notion entirely. Do not attempt any Notion operations.

## Error Handling

- **No input**: If no description and no `--file` flag, prompt via AskUserQuestion. Do not proceed until input is received.
- **File not found**: If `--file` path does not exist, display a clear error with the path and stop.
- **Workflow > 20 steps**: Display a warning, then continue with the first 20 steps. Do not stop.
- **Notion unavailable**: Complete file output silently. Skip Notion without warning.

## Usage Examples

```
/workflow:document "New client onboarding: sales hands off signed contract, ops creates account, CS sends welcome email"
/workflow:document --file=processes/invoice-approval.md
/workflow:document "Employee offboarding process" --format=file --output=hr/offboarding-sop.md
/workflow:document --format=notion
```
