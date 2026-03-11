---
description: Load complete client context from all connected sources into a unified dossier
argument-hint: "[name] --team --refresh --hours=90"
allowed-tools: ["Read"]
---

# Load Client Context

Load comprehensive client data by searching across CRM, email, calendar, documents, and notes. Assemble into a structured dossier with profile, relationship history, open items, sentiment, and key documents.

## Parse Arguments

Extract these from `$ARGUMENTS`:
- `[name]` (required) — client or company name to search for
- `--team` (boolean, default: false) — activate full 6-agent parallel-gathering pipeline
- `--refresh` (boolean, default: false) — bypass cache and force fresh data gathering
- `--hours=N` (integer, default: 4320 i.e. 180 days) — lookback window in hours for email and calendar searches

If no client name is provided, ask the user: "Which client would you like to load context for?"

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Mode 1: Default (Single-Agent Summary)

When `--team` is NOT present:

1. Read the client-context skill at `${CLAUDE_PLUGIN_ROOT}/skills/client/client-context/SKILL.md` for CRM schema, lookup strategies, extraction rules, and completeness scoring.
2. Read the relationship-summary skill at `${CLAUDE_PLUGIN_ROOT}/skills/client/relationship-summary/SKILL.md` for health scoring and sentiment analysis.
3. **Check cache first** (unless `--refresh`):
   - Locate the Companies database using the discovery order: search "[FOS] Companies" first, then "Founder OS HQ - Companies", then "Companies" or "CRM - Companies", then fall back to a standalone "Client Dossiers" database.
   - Search the discovered database for a page matching the client name.
   - If found and Dossier Generated At is within the last 24 hours, present the cached dossier from the page's Dossier property and note: "Using cached dossier (generated [time] ago). Run with `--refresh` to force update."
   - If Dossier Stale is true, Dossier Generated At is older than 24 hours, or no Dossier property is populated, proceed with fresh data gathering.
4. **CRM Lookup**: Search Notion for CRM Pro databases (Companies, Contacts, Deals, Communications) using dynamic database discovery (search by title, never hardcode IDs).
5. **Fuzzy match**: Search Companies database for the client name using the matching strategy from the client-context skill (exact → partial → abbreviation).
6. **Gather data**: Pull company profile, linked contacts, active deals, and recent communications from CRM.
7. **Email search**: If the gws CLI is available (`which gws`), search for threads with client contact emails over the lookback window using `gws gmail users messages list` and `gws gmail users messages get` via the Bash tool.
8. **Assemble dossier**: Build the seven-section dossier structure (Profile, Relationship History, Recent Activity, Open Items, Upcoming, Sentiment & Health, Key Documents).
9. **Score completeness**: Calculate the weighted completeness score per the client-context skill.
10. **Cache result**: Update the Companies page with dossier properties (Dossier, Dossier Completeness, Dossier Generated At, Dossier Stale=false). If using fallback "Client Dossiers" database (no Companies DB found), lazy-create it and add a new entry.
11. Present the dossier in clean, readable markdown format.

### Output Format (Default Mode)

```
## Client Context: [Company Name]

**Health Score**: [score]/100 ([label]) | **Completeness**: [score] | **Last Updated**: [date]

### Profile
- **Company**: [Name] | [Industry] | [Size] | [Status]
- **Primary Contact**: [Name] ([Role]) — [Email]
- **Active Deals**: [Count] | Total Value: $[Sum]
- **Relationship Tenure**: [N] months

### Relationship History
- Total interactions: [N] (Email: [N], Meetings: [N], Calls: [N])
- Engagement trend: [Increasing/Stable/Declining]
- Average response time: [N] hours

### Recent Activity
1. [Date] — [Type] — [Summary]
2. ...
(Last 5 interactions across all sources)

### Open Items
- [ ] [Action item] (from [source], [N] days old)
- ...

### Upcoming
- [Date]: [Meeting/milestone description]
- ...

### Sentiment & Risk
- Sentiment: [Positive/Neutral/Negative] ([trend])
- Engagement: [High/Medium/Low] ([trend])
- Risk flags: [List or "None"]

### Key Documents
- [Title] ([category], modified [date])
- ...

---
*Sources: [list] | Completeness: [score] | Generated: [timestamp]*
```

## Mode 2: Team Pipeline (`--team`)

When `--team` IS present:

1. Read the pipeline configuration at `${CLAUDE_PLUGIN_ROOT}/agents/client/config.json`.
2. Execute the full 6-agent parallel-gathering pipeline:
   - **Phase 1 — Parallel Gathering**: Launch all 5 gatherer agents simultaneously:
     - **CRM Agent** — Pull Notion CRM data (required)
     - **Email Agent** — Search Gmail history (required)
     - **Docs Agent** — Search Google Drive (optional)
     - **Calendar Agent** — Search Google Calendar (optional)
     - **Notes Agent** — Search Notion pages and Communications (required)
   - **Phase 2 — Synthesis**: Launch the Context Lead agent to:
     - Merge all gatherer outputs into the unified dossier
     - Calculate completeness score and health metrics
     - Cache the dossier on the Companies page (Dossier properties)
     - Write enrichments to the same Companies page (health score) and related DBs (risk levels, sentiment)
3. Each agent reads its definition from `${CLAUDE_PLUGIN_ROOT}/agents/client/`.
4. Present the final dossier with pipeline execution summary:
   - Which sources succeeded, failed, or were unavailable
   - Timing per agent
   - Completeness score and any data gaps
   - CRM enrichments written (if any)

## Error Handling

- **No client name provided**: Ask the user which client to load.
- **Client not found in CRM**: Search Gmail by name as fallback. Build partial dossier from available data. Suggest creating a CRM record.
- **Multiple CRM matches**: Present top 3 matches with confidence scores. Ask user to confirm which client.
- **Notion MCP not configured**: Halt with message: "Notion MCP is required. See `${CLAUDE_PLUGIN_ROOT}/INSTALL.md` for setup instructions."
- **gws CLI not available**: Warn that email data will be unavailable. Continue with CRM-only dossier.
- **Optional sources unavailable** (Drive, Calendar): Note in completeness breakdown. Continue with available sources.
- **Cache write fails**: Still present the dossier. Note that caching was unsuccessful.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/founder-os:client:load Acme Corp                  # Default: CRM + email summary
/founder-os:client:load Acme Corp --team           # Full 6-agent pipeline
/founder-os:client:load Acme Corp --refresh        # Bypass cache, fresh data
/founder-os:client:load "Acme Corp Inc" --hours=48 # Specific name, 48h lookback
/founder-os:client:load Acme --team --refresh      # Full pipeline, no cache
```
