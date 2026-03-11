---
description: Load a project brief from a local file or Notion page URL, then generate a Statement of Work with 3 scope options. Supports single-agent mode and full --team pipeline.
argument-hint: [file-or-url] --team --output=PATH --client=NAME --budget=AMOUNT --weeks=N
allowed-tools: Read, Glob, Grep, Write, Task
---

# SOW From Brief

Load a pre-written project brief from a local file or Notion page, then generate a Statement of Work with 3 scope options (Conservative, Balanced, Ambitious). This is the "bring your own brief" mode — it skips the interactive discovery interview used by `/founder-os:sow:generate`.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `[file-or-url]` (string, required) — path to a local file OR a Notion page URL. If not provided, ask the user: "Please provide a file path or Notion URL for your project brief."
- `--team` (boolean, default: false) — activate the full 6-agent competing-hypotheses pipeline
- `--client=NAME` (string, optional) — override the client name extracted from the brief
- `--budget=AMOUNT` (string, optional) — override the budget extracted from the brief
- `--weeks=N` (integer, optional) — override the timeline extracted from the brief
- `--output=PATH` (string, default: `./sow-output/`) — directory to write the generated SOW

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Step 1: Load the Brief

Determine the input type by inspecting the first argument.

### Local File

If the value does NOT start with `https://`:

1. Attempt to read the file using the filesystem MCP or Read tool.
2. Accept these formats: `.md`, `.txt`, `.pdf` (text layer only), `.json`.
3. If the file extension is not in this list, halt and report: "Unsupported file format: [ext]. Supported formats are .md, .txt, .pdf, .json."
4. If the file does not exist, halt and report: "File not found: [path]. Please check the path and try again."
5. Read the full file content.

### Notion URL

If the value starts with `https://www.notion.so/` or `https://notion.so/`:

1. Check if the Notion MCP is available. If not, halt with: "Notion MCP is required to load Notion pages. See INSTALL.md for setup instructions."
2. Call `notion-fetch` with the full URL.
3. Extract the page title, body text, and any structured properties from the response.
4. If the page is not found or access is denied, halt and report: "Could not access Notion page: [url]. Check that the page is shared with your Notion integration."

### Brief Content Extraction

After loading, extract these fields from the content. Handle missing fields gracefully — proceed without them if not present.

- `client_name`: Look for lines starting with "Client:", "Company:", "For:", or use the document title as a fallback.
- `project_description`: The main body text describing what needs to be built or done.
- `budget_constraint`: Look for "Budget:", "$", currency symbols, or numeric amounts followed by k/K/m/M.
- `timeline_constraint`: Look for "Timeline:", "Deadline:", "Weeks:", "Duration:", or "By [date]" patterns.
- `key_priorities`: Look for "Priorities:", "Goals:", "Requirements:", "Must-have:", or bulleted/numbered lists.
- `additional_context`: Any remaining relevant content — tech stack mentions, constraints, stakeholders, success criteria.

Apply overrides last:
- If `--client=NAME` is provided, replace `client_name` with NAME.
- If `--budget=AMOUNT` is provided, replace `budget_constraint` with AMOUNT.
- If `--weeks=N` is provided, replace `timeline_constraint` with "N weeks".

## Step 2: Confirm Brief Understanding

After extracting the brief fields, present a summary to the user before generating.

Format:
```
## Brief Loaded

**Client**: [client_name or "Not specified"]
**Source**: [file path or Notion URL]
**Project**: [first 1-2 sentences of project_description]
**Budget**: [budget_constraint or "Not specified"]
**Timeline**: [timeline_constraint or "Not specified"]
**Priorities**: [key_priorities summary, comma-separated, or "Not specified"]

Generating SOW with 3 scope options...
```

Skip this confirmation step and proceed directly when `--team` is present — the pipeline should run without pause.

If `project_description` is empty or could not be extracted, halt and ask: "The brief doesn't contain enough content to generate a SOW. Please describe the project requirements or provide a more detailed brief."

## Step 3: Generate the SOW

### Default Mode (no `--team`)

1. Read all 3 skills:
   - `${CLAUDE_PLUGIN_ROOT}/skills/sow/scope-definition/SKILL.md`
   - `${CLAUDE_PLUGIN_ROOT}/skills/sow/sow-writing/SKILL.md`
   - `${CLAUDE_PLUGIN_ROOT}/skills/sow/risk-assessment/SKILL.md`

2. Using the extracted brief fields as your source material, generate 3 SOW options:
   - **Option A — Conservative**: P90 confidence, 20% scope buffer. Core deliverables only, well-defined boundaries, lowest risk.
   - **Option B — Balanced**: P75 confidence, 10% scope buffer. Core plus high-value extras, moderate risk, recommended for most clients.
   - **Option C — Ambitious**: P60 confidence, no buffer. Full scope with stretch goals, higher risk, maximum client value.

3. Follow the sow-writing skill's three-option format for structure and language.

4. Apply the scope-definition skill's boundary-setting rules to each option.

5. Score risks for each option using the risk-assessment skill framework. Include risk register and mitigation notes inline.

6. Build the output filename: `sow-[client_name_slugified]-[YYYY-MM-DD].md`. If `client_name` is not available, use `sow-[YYYY-MM-DD].md`.

7. If `--output` directory does not exist, create it.

8. Write the SOW to the output directory.

9. Present the output summary:

```
## SOW Generated

**Output**: ./sow-output/sow-acme-corp-2026-02-24.md
**Client**: Acme Corp
**Source Brief**: /path/to/brief.md
**Options Generated**: 3 (Conservative, Balanced, Ambitious)

| Option | Scope | Timeline | Price Range | Risk Level |
|--------|-------|----------|-------------|------------|
| Conservative | [summary] | [N weeks] | [$X–$Y] | Low |
| Balanced | [summary] | [N weeks] | [$X–$Y] | Medium |
| Ambitious | [summary] | [N weeks] | [$X–$Y] | Medium-High |

**Recommended**: Option B (Balanced) — best value-to-risk ratio for this project.
```

10. **Notion tracking** (if Notion MCP is available):

   1. **Database discovery** (ordered):
      - Search for "[FOS] Deliverables" database first (preferred)
      - If not found, fall back to "Founder OS HQ - Deliverables" database
      - If not found, fall back to legacy "SOW Generator - Outputs" database
      - If none exists, skip Notion tracking (do NOT create the database)

   2. **Resolve Company + Deal relations** (only when writing to "[FOS] Deliverables" or "Founder OS HQ - Deliverables"):
      - Look up the client name in the CRM Pro "Companies" database
      - If a matching company is found, set the **Company** relation property
      - If a deal was identified during context search, set the **Deal** relation property
      - If no match is found, leave relation properties empty

   3. **Idempotent upsert**: Check for existing record with same Client Name + Project Title. When using "[FOS] Deliverables" or "Founder OS HQ - Deliverables", also filter by **Type = "SOW"** to avoid collisions with other deliverable types.

   4. Create or update the record:
      - **Type**: "SOW" (when writing to HQ Deliverables)
      - **Title**: Project name
      - **Status**: "Draft"
      - **Amount**: Recommended option's quoted price
      - **File Path**: Output file path
      - **Brief File**: Source brief file path
      - **Sources Used**: Data sources consulted
      - **Generated At**: Current date/time

   5. **Link to Source Proposal** (Source Deliverable relation):
      After creating/updating the SOW record, search the same Deliverables database for an existing **Proposal** that matches this SOW:
      - First, search for a Proposal with the same **Company** relation AND **Type = "Proposal"**
      - If multiple matches, narrow by checking if the Proposal's **Brief File** base name matches the SOW's Brief File (e.g., `brief-greenleaf-crm-2026-01-20.md`)
      - If a single matching Proposal is found, set the SOW's **Source Deliverable** relation to point to that Proposal page
      - If no match is found, leave Source Deliverable empty — do not create placeholder Proposals

### Team Mode (`--team`)

1. Read `${CLAUDE_PLUGIN_ROOT}/agents/sow/config.json`.

2. Pass the fully extracted brief fields (client_name, project_description, budget_constraint, timeline_constraint, key_priorities, additional_context) as structured input to the pipeline.

3. Execute the competing-hypotheses pipeline:

   **Phase 1 — Parallel Hypothesis Generation** (all 3 scope agents run simultaneously):
   - `scope-agent-a` (`${CLAUDE_PLUGIN_ROOT}/agents/sow/scope-agent-a.md`) — interprets the brief conservatively
   - `scope-agent-b` (`${CLAUDE_PLUGIN_ROOT}/agents/sow/scope-agent-b.md`) — interprets the brief for balanced value
   - `scope-agent-c` (`${CLAUDE_PLUGIN_ROOT}/agents/sow/scope-agent-c.md`) — interprets the brief ambitiously

   **Phase 2 — Parallel Analysis** (both agents evaluate all 3 Phase 1 proposals):
   - `risk-agent` (`${CLAUDE_PLUGIN_ROOT}/agents/sow/risk-agent.md`) — scores risks across all three proposals
   - `pricing-agent` (`${CLAUDE_PLUGIN_ROOT}/agents/sow/pricing-agent.md`) — estimates cost and value for all three proposals

   **Phase 3 — Synthesis**:
   - `sow-lead` (`${CLAUDE_PLUGIN_ROOT}/agents/sow/sow-lead.md`) — synthesizes Phase 1 proposals and Phase 2 analysis into a final SOW document with 3 named client packages and a comparison table

4. If fewer than 2 Phase 1 agents complete successfully, halt and report which agents failed. Do not proceed to Phase 2 with only 1 proposal.

5. If `--output` directory does not exist, create it before sow-lead writes the file.

6. Present a pipeline completion summary:

```
## SOW Pipeline Complete

**Output**: ./sow-output/sow-acme-corp-2026-02-24.md
**Client**: Acme Corp
**Source Brief**: /path/to/brief.md

**Pipeline Results**:
| Phase | Agent | Status | Duration |
|-------|-------|--------|----------|
| 1 | scope-agent-a | Complete | 12s |
| 1 | scope-agent-b | Complete | 14s |
| 1 | scope-agent-c | Complete | 11s |
| 2 | risk-agent | Complete | 8s |
| 2 | pricing-agent | Complete | 9s |
| 3 | sow-lead | Complete | 16s |

**Options Generated**: 3 (Conservative, Balanced, Ambitious)
```

## Error Handling

- File path not provided and user does not supply one after being asked: halt without generating.
- File format not supported: report the extension and list the supported formats (`.md`, `.txt`, `.pdf`, `.json`).
- Notion URL provided but Notion gws CLI is unavailable or authentication not configured: halt and reference INSTALL.md.
- Brief loaded but no extractable content (empty file, unreadable PDF): ask the user to provide brief details manually or try a different file.
- Output directory does not exist: create it silently and continue.
- Phase 1 produces only 1 proposal in `--team` mode: halt, report which agents failed, do not synthesize.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/founder-os:sow:from-brief ./briefs/acme-portal-brief.md
/founder-os:sow:from-brief https://www.notion.so/acme/customer-portal-brief-abc123
/founder-os:sow:from-brief ./brief.txt --team --output=./proposals/
/founder-os:sow:from-brief ./brief.md --client="Acme Corp" --budget=75000
/founder-os:sow:from-brief ./brief.json --weeks=12 --output=./client-sows/
/founder-os:sow:from-brief                                   # Interactive: asks for file or URL
```
