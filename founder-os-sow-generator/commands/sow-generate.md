---
description: Generate a Statement of Work with 3 scope options (conservative, balanced, ambitious) from a project brief. Supports interactive single-agent mode and full 6-agent competing-hypotheses pipeline via --team flag.
argument-hint: [brief] --team --client=NAME --budget=AMOUNT --weeks=N --output=PATH
allowed-tools: Read, Glob, Grep, Write, Task
---

# SOW Generate

Generate a client-ready Statement of Work with three named scope packages. Operate in one of two modes depending on arguments.

## Parse Arguments

Extract these values from `$ARGUMENTS`:
- `[brief]` (string, optional) — inline project brief text. If not provided, ask the user interactively.
- `--team` (boolean, default: false) — activate full 6-agent competing-hypotheses pipeline mode.
- `--client=NAME` (string, optional) — client name for the SOW header. If not provided, infer from the brief or ask the user.
- `--budget=AMOUNT` (string, optional) — maximum budget constraint (e.g., `$50,000` or `50000`). If not provided, pricing agent uses market rates.
- `--weeks=N` (integer, optional) — maximum timeline in weeks. If not provided, derive from scope.
- `--output=PATH` (string, default: `./sow-output/`) — output directory for the generated SOW file.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Context Loading

Before generating in either mode:

1. Check if Notion MCP is available. If yes, search Notion for historical SOWs matching the client name, industry, or project type using `notion-search` with the query "SOW". Summarize any relevant historical scope, pricing, or risk patterns found. Note to the user if historical context was found and what it informed.
2. Check if a `.sow-history` file exists in the output directory. If it exists, read it and use its contents as additional calibration context for scope and pricing.
3. If neither Notion nor `.sow-history` is available, proceed without historical context and note this to the user.

## Mode 1: Default (Single-Agent Quick SOW)

When `--team` is NOT present:

1. Read ALL 3 skills:
   - `${CLAUDE_PLUGIN_ROOT}/skills/scope-definition/SKILL.md`
   - `${CLAUDE_PLUGIN_ROOT}/skills/sow-writing/SKILL.md`
   - `${CLAUDE_PLUGIN_ROOT}/skills/risk-assessment/SKILL.md`

2. Collect the project brief:
   - If a `[brief]` argument was provided, use it as the project description.
   - If no brief was provided, ask the user for all of the following:
     - Client name and industry
     - Project description and goals
     - Key deliverables or features required
     - Budget constraint (or confirm none)
     - Timeline constraint in weeks (or confirm none)
     - Key priorities (e.g., speed, quality, cost, flexibility)
   - Do not proceed until at least a project description and client name are available.

3. Run context loading (see Context Loading section above).

4. Generate three SOW options internally applying the rules from all three skills:

   **Option A — Conservative (Foundation Package)**
   - Apply scope-definition skill: P90 confidence level, 20% scope buffer, include only explicitly stated requirements
   - Apply risk-assessment skill: score all risk dimensions, flag high-risk items, recommend mitigations
   - Apply pricing: 30% margin on estimated effort; derive from skills pricing tables

   **Option B — Balanced (Growth Package)**
   - Apply scope-definition skill: P75 confidence level, 10% scope buffer, include stated requirements plus one logical adjacent deliverable
   - Apply risk-assessment skill: score all risk dimensions, moderate risk tolerance
   - Apply pricing: 25% margin on estimated effort

   **Option C — Ambitious (Transformation Package)**
   - Apply scope-definition skill: P60 confidence level, 0% scope buffer, include full vision with stretch deliverables
   - Apply risk-assessment skill: score all risk dimensions, note elevated risk areas clearly
   - Apply pricing: 20% margin on estimated effort

   Respect `--budget` and `--weeks` constraints: if an option exceeds the constraint, adjust scope downward and note the change.

5. Determine the recommended option: the option whose risk score is Medium or below with the highest value delivery. Typically Option B unless budget or timeline constraints make Option A the only viable choice.

6. Create the output directory if it does not exist.

7. Derive the output filename as `sow-[client-slug]-[YYYY-MM-DD].md` where `[client-slug]` is the client name lowercased with spaces replaced by hyphens and `[YYYY-MM-DD]` is today's date.

8. Write the full SOW to `${output}/sow-[client-slug]-[YYYY-MM-DD].md` using the three-option document format from the sow-writing skill. The document must include:
   - Cover page (client name, project name, date, prepared by)
   - Executive summary
   - All three option sections with deliverables, timeline, pricing, and risk summary
   - Comparison table across all three options
   - Terms and conditions section
   - Signature block

9. Present the output summary to the user:

```
## SOW Generated

**Client**: [Client Name]
**Output**: [output path]
**Options**: 3 ([Option A name] · [Option B name] · [Option C name])
**Recommended**: [Option B name] (Option B)

### Option Summary
| Option | Timeline | Price | Risk |
|--------|----------|-------|------|
| [Option A name] | N weeks | $XX,XXX | Low |
| **[Option B name] ✓** | N weeks | $XX,XXX | Medium |
| [Option C name] | N weeks | $XX,XXX | High |

_View the full SOW at [output path]_
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
      - **Sources Used**: Data sources consulted
      - **Generated At**: Current date/time

## Mode 2: Team Pipeline (`--team`)

When `--team` IS present:

1. Read `${CLAUDE_PLUGIN_ROOT}/teams/config.json`.

2. Collect the project brief:
   - If a `[brief]` argument was provided, use it.
   - If no brief was provided, ask the user for: client name, project description and goals, key deliverables, budget constraint, timeline constraint, and key priorities.
   - Do not proceed until at least a project description and client name are available.

3. Run context loading (see Context Loading section above).

4. Assemble a structured context object to pass to all Phase 1 agents:
   ```json
   {
     "brief": "[project brief text]",
     "client": "[client name]",
     "budget_constraint": "[budget or null]",
     "weeks_constraint": "[weeks or null]",
     "historical_context": "[summary from Notion/.sow-history or null]",
     "skills_paths": {
       "scope_definition": "${CLAUDE_PLUGIN_ROOT}/skills/scope-definition/SKILL.md",
       "sow_writing": "${CLAUDE_PLUGIN_ROOT}/skills/sow-writing/SKILL.md",
       "risk_assessment": "${CLAUDE_PLUGIN_ROOT}/skills/risk-assessment/SKILL.md"
     }
   }
   ```

5. Execute Phase 1 — spawn all three scope agents in parallel using the Task tool. Each agent reads its definition from its `file` path in `teams/config.json` and receives the structured context object. The agents are independent and must not communicate with each other.
   - `scope-agent-a` — conservative interpretation, P90 confidence, 20% buffer
   - `scope-agent-b` — balanced interpretation, P75 confidence, 10% buffer
   - `scope-agent-c` — ambitious interpretation, P60 confidence, 0% buffer

   Wait for all Phase 1 agents to complete before proceeding. If fewer than 2 agents succeed (per `minimum_hypotheses_required` in config), halt and report the failure. If exactly 2 of 3 succeed, proceed and note which agent failed.

6. Collect Phase 1 outputs (three scope proposals). Structure them as a combined proposals object.

7. Execute Phase 2 — spawn `risk-agent` and `pricing-agent` in parallel using the Task tool. Each agent reads its definition from its `file` path and receives the structured context object plus all Phase 1 proposals.
   - `risk-agent` — scores risk dimensions for each proposal
   - `pricing-agent` — estimates cost and validates value-for-money for each proposal

   Wait for both Phase 2 agents to complete before proceeding.

8. Execute Phase 3 — invoke `sow-lead` with the structured context object plus all Phase 1 and Phase 2 outputs. The lead agent reads its definition from `${CLAUDE_PLUGIN_ROOT}/teams/agents/sow-lead.md` and synthesizes all inputs into the final SOW document. The lead writes the output file to the `--output` directory.

9. Present the pipeline completion summary:

```
## SOW Pipeline Complete

**Client**: [Client Name]
**Output**: [output path]
**Pipeline**: 6 agents (3 scope · 1 risk · 1 pricing · 1 lead)

### Agent Timing
| Agent | Duration | Status |
|-------|----------|--------|
| scope-agent-a | Xs | Done |
| scope-agent-b | Xs | Done |
| scope-agent-c | Xs | Done |
| risk-agent | Xs | Done |
| pricing-agent | Xs | Done |
| sow-lead | Xs | Done |

### Scoring Matrix
| Option | Scope Score | Risk Score | Pricing Score | Total |
|--------|-------------|------------|---------------|-------|
| [Option A name] | X/10 | X/10 | X/10 | X/30 |
| [Option B name] | X/10 | X/10 | X/10 | X/30 |
| [Option C name] | X/10 | X/10 | X/10 | X/30 |

**Recommended**: [Recommended option name]

_View the full SOW at [output path]_
```

## Error Handling

- If no brief is provided and the user declines to provide one: halt with the message "A project brief is required to generate a SOW. Please provide a description of the project, goals, and any constraints."
- If Notion MCP is unavailable: skip historical context lookup, proceed with filesystem-only, note "Notion unavailable — proceeding without historical SOW context."
- If the output directory does not exist: create it with `Write` before writing the SOW file.
- If `--budget` is not provided: generate all three SOW options without a budget ceiling; the pricing agent uses market rates derived from the sow-writing skill pricing tables.
- If `--weeks` is not provided: derive timeline from scope estimates in each option; do not artificially constrain.
- In team mode, if a Phase 1 agent fails: log the failure, continue with remaining agents if at least 2 succeed.
- In team mode, if a Phase 2 agent fails: log the failure, have sow-lead note the missing analysis and complete synthesis with available data.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/sow:generate "Build a customer portal for Acme Corp with dashboard, auth, and reporting"
/sow:generate --client="TechCo" --budget=75000 --weeks=16
/sow:generate --team "Redesign the onboarding flow for a SaaS product"
/sow:generate --team --client="StartupXYZ" --output=./proposals/
/sow:generate                                  # Interactive: asks for brief
```
