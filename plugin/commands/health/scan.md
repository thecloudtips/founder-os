---
description: Scan all CRM clients and compute health scores with RAG dashboard
argument-hint: "[--client=NAME] [--status=red|yellow|green] [--limit=N] [--refresh] [--schedule=EXPR] [--persistent]"
allowed-tools: ["Read"]
---

# Health Scan

Scan the user's CRM in Notion to compute a 5-metric health score for every active client, classify each into a RAG tier (Red / Yellow / Green), cache results in Notion, and present an at-risk-first dashboard.

## Load Skills

Read the client-health-scoring skill at `${CLAUDE_PLUGIN_ROOT}/skills/health/client-health-scoring/SKILL.md` for the 5-metric scoring algorithm, RAG classification thresholds, data source integration, caching strategy, risk flag taxonomy, and scoring formulas.

Read the sentiment-analysis skill at `${CLAUDE_PLUGIN_ROOT}/skills/health/sentiment-analysis/SKILL.md` for email and meeting sentiment extraction needed by the Sentiment metric.

## Parse Arguments

Extract flags from `$ARGUMENTS`:
- `--client=NAME` (optional) — scan only this client. Fuzzy match against CRM Companies database. Default: scan all active clients.
- `--status=red|yellow|green` (optional) — filter dashboard output to show only clients in this RAG tier. Default: show all.
- `--limit=N` (optional) — show only the top N at-risk clients (sorted by score ascending). Default: show all.
- `--refresh` (optional) — bypass 24h cache and recompute all scores from fresh source data.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Observation: Start
Before executing, record a pre_command event to the Intelligence event store (`_infrastructure/intelligence/.data/intelligence.db`):
- Event type: `pre_command`
- Plugin: `client-health`
- Command: `health-scan`
- Generate a session_id (UUID) and reuse it for all subsequent events in this execution
- Payload: record input parameters, context files loaded, and any memories injected
- If the Intelligence database does not exist, skip observation silently and continue execution

## Intelligence: Apply Learned Patterns
Before executing the main logic, check for learned patterns in the Intelligence database (`_infrastructure/intelligence/.data/intelligence.db`):
1. Query: `SELECT instruction, description FROM patterns WHERE (plugin = 'client-health' OR plugin IS NULL) AND (command = 'health-scan' OR command IS NULL) AND status IN ('active', 'approved') ORDER BY confidence DESC`
2. If patterns found, apply each instruction as additional context for this execution
3. Notify: `[Intel] Applying learned preference: "{description}"` for each pattern applied
4. If the Intelligence database does not exist, skip silently and continue execution

## Self-Healing: Error Recovery
If any error occurs during this command:
1. Classify the error using rules from `_infrastructure/intelligence/self-healing/SKILL.md`
2. Check if healing is enabled: query `SELECT value FROM config WHERE key = 'healing.enabled'` from Intelligence DB
3. For transient errors: retry with exponential backoff (2s, 5s, 15s)
4. For recoverable errors: look up fix in healing_patterns table, apply if found
5. For degradable errors: consult fallback registry in `_infrastructure/intelligence/self-healing/fallback-registry/SKILL.md`, execute fallback path
6. For fatal errors: stop and present error with suggested fix
7. Always notify: `[Heal] {description of what happened and what was done}`
8. Record error event to Intelligence DB with recovery_attempted field
9. If Intelligence DB is unavailable, fall back to existing error handling (no self-healing)

## Scheduling Support

If `$ARGUMENTS` contains `--schedule`:
1. Extract the schedule value and any `--persistent` flag
2. Read `_infrastructure/scheduling/SKILL.md` for scheduling bridge logic
3. Read `_infrastructure/scheduling/references/schedule-flag-spec.md` for argument parsing
4. Default suggestion if no expression given: `"30 9 * * 1-5"` (Weekdays 9:30am)
5. Handle the schedule operation (create/disable/status) per the spec
6. Exit after scheduling — do NOT continue to main command logic

## Scanning Process

1. **Discover CRM database**: Search Notion for a database with title containing "Companies" or "CRM". Never hardcode database IDs. If multiple matches, prefer the one containing client-like records (with contact relations, status fields, or deal properties). If no CRM database is found, stop and report: "No CRM Companies database found in Notion. Create one or check MCP access."

2. **Fetch client list**: Retrieve all records from the CRM Companies database. Filter to Active and Prospect status by default. When `--client=NAME` is set, fuzzy-match the name against company titles (case-insensitive substring match) and scan only that client. If `--client` is set and no match is found, stop and report: "No client matching '[NAME]' found. Check the name and try again."

3. **Check cache**: For each client, check the Company page in the discovered Companies database for a `Last Scanned` property:
   - If `Last Scanned` exists and is < 24 hours ago AND `--refresh` is NOT set, use cached health scores from the Company page properties. Skip to step 7.
   - If `Last Scanned` is missing, stale (>= 24 hours ago), or `--refresh` is set, proceed to step 4.
   - In fallback mode (standalone Health Scores DB), search for a matching record by Client Name instead.

4. **Gather source data**: For each client requiring fresh scores, collect data from all available sources:
   - **Gmail**: Search for threads involving the client's contact email addresses (last 90 days). Retrieve thread metadata, timestamps, and message bodies for sentiment analysis.
   - **Notion CRM**: Query for open tasks, deals, and communications related to this client across any linked databases.
   - **P20 dossier**: Check the "Client Dossiers" database for a cached dossier for this client. If fresh (< 24h), reuse its data to avoid redundant gathering.
   - **P11 invoices**: Search the "[FOS] Finance" database first, then "Founder OS HQ - Finance" (filter by `Type = "Invoice"`), falling back to "Invoice Processor - Invoices" (legacy). Match records by this client's name or vendor field. Extract payment dates, due dates, and approval statuses.
   - **Google Calendar**: Search for events in the last 90 days where an attendee email matches the client's known contacts. Extract meeting dates and frequency.

5. **Compute metrics**: Apply the scoring formulas from the client-health-scoring skill to produce five sub-scores (each 0-100):
   - **Last Contact** (weight 0.25): Based on days since the most recent email thread or calendar event involving the client. More recent = higher score.
   - **Response Time** (weight 0.20): Average reply latency across the last 10 email threads with the client. Faster responses = higher score.
   - **Open Tasks** (weight 0.20): Ratio of overdue tasks to total open tasks for the client. Fewer overdue = higher score.
   - **Payment Status** (weight 0.20): Derived from invoice payment history — on-time rate, outstanding amount, days past due. Better payment record = higher score.
   - **Sentiment** (weight 0.15): Run the sentiment-analysis skill on the gathered email and meeting content for this client. Positive sentiment = higher score.

6. **Calculate composite and classify**: Compute the weighted sum of all 5 metrics (0.25 + 0.20 + 0.20 + 0.20 + 0.15 = 1.00). Classify into RAG tier:
   - **Green**: composite score >= 80
   - **Yellow**: composite score 50-79
   - **Red**: composite score < 50

   Detect risk flags per the skill's flag conditions (e.g., "No contact 30+ days", "3+ overdue tasks", "Invoice 60+ days past due", "Negative sentiment trend", "Response time degrading"). Identify the single highest-impact risk flag as the "Top Issue" for at-risk clients.

7. **Cache results**: Update the Company page in the discovered Companies database with health score properties (Health Score, Health Status, Risk Flags, Last Scanned, Sources Used, Notes, and per-metric scores). Set Last Scanned to the current timestamp. Set Sources Used to reflect which data sources actually contributed data for this scan. In fallback mode (standalone Health Scores DB), write or update the record by Client Name as the unique key — never create duplicate records.

8. **Apply filters**: After all clients are scored:
   - If `--status` is set, keep only clients in the specified RAG tier.
   - If `--limit=N` is set, keep only the top N clients sorted by composite score ascending (worst health first).

9. **Sort and present**: Sort all results by composite score ascending (worst first). Present the At-Risk section first, then Needs Attention, then Healthy. Use the output format below.

## Notion Integration

1. **Database discovery**: Follow the priority order from the client-health-scoring skill:
   - First, search for **"[FOS] Companies"** (the consolidated HQ database).
   - If not found, search for **"Founder OS HQ - Companies"** (legacy HQ name).
   - If not found, search for **"Companies"** or **"CRM - Companies"** (standalone CRM).
   - If none found, fall back to lazy-creating a standalone **"Client Health Dashboard - Health Scores"** database with properties: Client Name (title), Overall Score (number), Health Status (select: Green/Yellow/Red), Last Contact Score (number), Response Time Score (number), Open Tasks Score (number), Payment Score (number), Sentiment Score (number), Risk Flags (multi_select), Sources Used (multi_select: Gmail/Notion/Calendar/Invoices/Dossiers), Last Scanned (date), Notes (rich_text).
2. **HQ / Companies mode** (primary path): Update existing Company pages with health properties (Health Score, Health Status, Risk Flags, Last Scanned, Sources Used, Notes). Do NOT create new pages — health data is written onto the Company page that already exists.
3. **Fallback mode**: In the standalone Health Scores DB, use Client Name as the unique key. For clients already in the database, update all score fields. For new clients, create records. Never duplicate entries.
4. **Idempotent updates**: Whether updating Company pages or standalone records, overwrite all health properties on each scan. Never create duplicate entries.

## Graceful Degradation

- **Notion unavailable**: Cannot proceed — Notion is required for CRM discovery and writing health scores. Report error: "Notion MCP is unavailable. This command requires Notion for CRM access and health score storage. Configure Notion MCP per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`." and stop.
- **Gmail unavailable**: Set Last Contact and Response Time sub-scores to neutral defaults (50). Set Sentiment sub-score to neutral (50) unless Calendar data provides meeting notes. Warn in output: "Gmail unavailable — contact, response time, and sentiment scores use neutral defaults."
- **Calendar unavailable**: Skip calendar data silently. Use Gmail-only data for Last Contact and Sentiment metrics. Do not warn unless Gmail is also unavailable.
- **P20 dossier unavailable**: Fall back to direct Notion task and communication queries. Do not warn.
- **P11 invoices database unavailable**: Set Payment Status sub-score to neutral default (75). Note in output source summary as unavailable.

## Output Format

After scanning, display results:

```
## Client Health Dashboard

**Scanned**: [count] clients | **Date**: [today's date]
**Sources**: Gmail [✓|✗] | Notion ✓ | Calendar [✓|✗] | Invoices [✓|✗] | Dossiers [✓|✗]

### At-Risk Clients ([count])

| Client | Score | Status | Risk Flags | Top Issue |
|--------|-------|--------|------------|-----------|
| [name] | [score]/100 | Red | [flags] | [primary risk] |

### Needs Attention ([count])

| Client | Score | Status | Risk Flags |
|--------|-------|--------|------------|
| [name] | [score]/100 | Yellow | [flags] |

### Healthy ([count])

| Client | Score | Status |
|--------|-------|--------|
| [name] | [score]/100 | Green |

---
Last updated: [timestamp] | Cache TTL: 24h | Use --refresh to force recompute
[Notion page links for each scored client if available]
```

If `--status` filter is applied, show only the matching RAG section. Omit the other sections entirely.

If `--limit` is applied, show the heading "Top [N] At-Risk Clients" instead of the full three-section layout. Only display the limited set sorted by score ascending.

If no active clients found in CRM: "No active clients found in CRM database."

If `--client` used and no match: "No client matching '[NAME]' found. Check the name and try again."

## Observation: End
After execution completes, record a post_command event to the Intelligence event store:
- Event type: `post_command`
- Use the same session_id from the start observation
- Outcome: `success` | `failure` | `degraded`
- Payload: { outcome summary, items processed, outputs created }
- Duration: milliseconds elapsed since pre_command event
- If any errors occurred during execution, also record an error event with the error type, message, and whether recovery was attempted

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/founder-os:client:health-scan
/founder-os:client:health-scan --refresh
/founder-os:client:health-scan --client="Acme Corp"
/founder-os:client:health-scan --status=red
/founder-os:client:health-scan --status=red --limit=5
/founder-os:client:health-scan --limit=10 --refresh
```
