---
description: Generate a concise 1-page client brief for meeting preparation
argument-hint: "[name]"
allowed-tools: ["Read"]
---

# Client Brief

Generate a concise, printable 1-page executive brief for a client. Designed for quick pre-meeting preparation or portfolio review. Always operates in single-agent mode (no --team flag).

## Parse Arguments

Extract from `$ARGUMENTS`:
- `[name]` (required) — client or company name

If no client name is provided, ask the user: "Which client do you need a brief for?"

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Process

1. Read the relationship-summary skill at `${CLAUDE_PLUGIN_ROOT}/skills/client/relationship-summary/SKILL.md` for the executive brief template, sentiment scoring, engagement metrics, risk flags, and health score formula.
2. Read the client-context skill at `${CLAUDE_PLUGIN_ROOT}/skills/client/client-context/SKILL.md` for CRM schema and data source hierarchy.
3. **Check dossier cache**:
   - Locate the Companies database using the discovery order: search "[FOS] Companies" first, then "Founder OS HQ - Companies", then "Companies" or "CRM - Companies", then fall back to a standalone "Client Dossiers" database.
   - Search the discovered database for a page matching the client name.
   - If found and Dossier Generated At is within the last 24 hours: use the page's Dossier property to generate the brief.
   - If Dossier Stale is true or Dossier Generated At is older than 24 hours: warn the user and suggest running `/founder-os:client:load [name]` first to refresh data. Still generate a brief from stale data with a staleness warning.
   - If no Dossier property is populated or no matching page found: inform the user that no dossier exists for this client. Suggest running `/founder-os:client:load [name]` first. If the user wants to proceed anyway, perform a lightweight CRM-only lookup and generate a partial brief.
4. **Generate brief** from dossier data following the executive brief template in the relationship-summary skill.
5. Calculate health score using the health score formula if not already in the cached dossier.
6. Identify risk flags per the risk flag criteria.
7. Present the brief in clean, printable markdown format.

## Output Format

```
# Client Brief: [Company Name]

**Generated**: [date] | **Health**: [score]/100 ([label]) | **Data**: [completeness score]

---

## Profile
**[Company Name]** | [Industry] | [Size] | [Status]
**Primary Contact**: [Name] ([Role]) — [Email]
**Relationship Owner**: [User] | **Tenure**: [N] months
**Active Deals**: [Count] | **Value**: $[Total]

## Recent Activity (Last 30 Days)
- [Relative date]: [Type] — [Summary]
- [Relative date]: [Type] — [Summary]
- [Relative date]: [Type] — [Summary]
- [Relative date]: [Type] — [Summary]
- [Relative date]: [Type] — [Summary]

## Open Items
- [ ] [Action item 1] *(from [source])*
- [ ] [Action item 2] *(from [source])*
- [ ] [Action item 3] *(from [source])*

## Upcoming
- [Date]: [Meeting/milestone/deadline]
- [Date]: [Meeting/milestone/deadline]

## Sentiment & Risk
**Sentiment**: [Positive/Neutral/Negative] ([trend direction])
**Engagement**: [High/Medium/Low] ([trend direction])
**Risk Flags**:
- [Flag description] ([severity])

## Key Documents
- [Title] ([category], [relative date])
- [Title] ([category], [relative date])
- [Title] ([category], [relative date])

---
*Brief generated from [source description]. Run `/founder-os:client:load [name]` to refresh.*
```

### Formatting Rules

- Use relative dates for items < 14 days old ("2 days ago", "last week"). Use absolute dates for older items.
- Lead with the most actionable information: risk flags and open items matter most.
- Use bullet points, not paragraphs — executives scan, not read.
- Keep the entire brief under 500 words.
- If completeness < 0.5, add a warning at the top: "Low data confidence — some sections may be incomplete."
- Empty sections: include the header with "No data available" rather than omitting.
- Maximum 5 recent activities, 10 open items, 3 key documents.

## Error Handling

- **No client name provided**: Ask the user which client they need a brief for.
- **No cached dossier found**: Inform user and suggest `/founder-os:client:load [name]`. Offer to generate a partial brief from CRM-only data.
- **Notion MCP not configured**: Halt with message: "Notion MCP is required. See `${CLAUDE_PLUGIN_ROOT}/INSTALL.md` for setup instructions."
- **Client not found in CRM or cache**: Report that no data exists for this client. Suggest checking the spelling or running `/founder-os:client:load [name]` with the correct name.
- **Stale data (>24h)**: Generate the brief but include a staleness warning with the age of the data.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/founder-os:client:brief Acme Corp          # Generate 1-page brief from cached dossier
/founder-os:client:brief "Acme Corp Inc"    # Quoted name for exact match
```
