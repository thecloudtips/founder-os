---
name: Client Health Scoring
description: "Computes composite health scores (0-100) for CRM clients from 5 weighted metrics. Activates when the user wants to check client health, find at-risk clients, score relationships, or asks 'which clients need attention?' Covers Last Contact, Response Time, Open Tasks, Payment Status, and Sentiment with RAG classification and risk flagging."
---

## Overview

Compute a composite health score (0-100) for each client in the Notion CRM by aggregating five weighted metrics: Last Contact, Response Time, Open Tasks, Payment Status, and Sentiment. Classify each client into a RAG tier (Green, Yellow, Red) based on the composite score. Detect risk flags that signal declining engagement or operational issues. Output a ranked dashboard of all scored clients, ordered by composite score ascending (worst-health-first) so the user can prioritize attention on at-risk relationships.

This skill handles the scoring algorithm and data aggregation layer only. Sentiment computation is delegated to the sentiment-analysis skill. Dashboard formatting and report generation are handled by the command layer.

## Scoring Workflow

Process all clients through these steps in order:

1. Retrieve the client list from the Notion CRM Companies database using the DB discovery logic described in the "Database Discovery" section below. Use dynamic database discovery -- never hardcode database IDs.
2. For each client, check the Companies database for a cached health score. If a `Last Scanned` property exists with a timestamp less than 24 hours old and the `--refresh` flag is not set, use the cached score and skip recomputation.
3. For clients requiring fresh scores, gather source data in parallel from all available sources (Gmail, Notion tasks, P20 dossier, P11 invoice DB, Google Calendar).
4. Compute each of the 5 metric scores individually. Normalize all scores to the 0-100 range. Clamp any out-of-range values.
5. Calculate the composite score as the weighted sum of all 5 metric scores.
6. Classify the composite score into a RAG tier.
7. Evaluate risk flag rules against the individual metric scores and source data.
8. Update the client's Company page in the discovered Companies database with health score properties (Overall Score, Health Status, Risk Flags, Last Scanned, Sources Used, Notes, and per-metric scores). In fallback mode only (standalone Health Scores DB), write or update a separate record instead.
9. After all clients are scored, sort by composite score ascending and present the dashboard.

## Metric Weights

| # | Metric | Weight | Source |
|---|--------|--------|--------|
| 1 | Last Contact | 0.25 | Gmail sent/received, Google Calendar meetings |
| 2 | Response Time | 0.20 | Gmail thread response intervals |
| 3 | Open Tasks | 0.20 | Notion CRM tasks, P20 dossier "Open Items" |
| 4 | Payment Status | 0.20 | P11 Invoice Processor DB |
| 5 | Sentiment | 0.15 | sentiment-analysis skill output |

All weights sum to 1.00. For the composite formula, exponential decay curves, quick-reference tables, and per-metric edge case handling, see `${CLAUDE_PLUGIN_ROOT}/skills/health/client-health-scoring/references/scoring-formulas.md`.

## RAG Classification

Classify each client based on their composite score:

| Tier | Range | Label | Meaning |
|------|-------|-------|---------|
| Green | 80-100 | Healthy | Relationship is strong, no action needed |
| Yellow | 50-79 | Needs Attention | One or more metrics declining, monitor closely |
| Red | 0-49 | At Risk | Immediate attention required, risk of churn |

When presenting the dashboard, group clients by tier and display the tier label alongside the composite score. Within each tier, sort by composite score ascending (lowest score first within the tier).

## Data Source Integration

### Notion CRM (Required)

Search for the Companies database by title. For each company record, extract:
- **Name** (title): Client identifier for cross-source correlation.
- **Contacts** (relation): Follow to Contacts database. Extract email addresses for Gmail and Calendar correlation.
- **Status** (select): Only score clients with Status "Active" or "Prospect". Skip "Churned" and "Partner" unless the user explicitly requests `--all`.
- **Communications** (relation): Follow for interaction history and relationship tenure.

Use email addresses from linked Contacts as the key for Gmail and Calendar lookups.

### Gmail (Required)

Search for threads involving the client's contact email addresses over the last 90 days.

- **Last Contact metric**: Identify the most recent email (sent or received) involving any of the client's contact addresses. Calculate `days_since_contact` as the number of calendar days between that email's date and today.
- **Response Time metric**: Across the last 10 email threads, calculate the average time (in hours) between the client sending an email and the user replying. Only count threads where the user replied. Exclude auto-replies and transactional emails.

### P20 Client Dossier (Optional -- Read Cached Data)

Search the "Client Dossiers" Notion DB (from Plugin #20 Client Context Loader) for a matching client name. When a dossier exists:
1. Check the **Stale** property. If `false`, check the **Generated At** timestamp. If within 24 hours, treat the dossier as fresh.
2. From a fresh dossier, extract: open items list (for Open Tasks metric), sentiment summary (for Sentiment metric), recent activity timeline (supplements Last Contact metric).
3. If the dossier is stale or missing, fall back to direct source queries. Do not trigger a P20 dossier refresh from within this skill -- that is the user's responsibility.

### Finance DB (Optional -- Read Invoice Data)

Search for a Notion database named "[FOS] Finance" first, then "Founder OS HQ - Finance", then fall back to "Invoice Processor - Invoices" (legacy). When found:
1. Filter by `Type = "Invoice"` (when using HQ Finance DB) and vendor/client name matching the current client.
2. Count total invoices, invoices paid on time, and currently overdue invoices.
3. Feed these counts into the Payment Status metric formula.

When neither database is found (plugin not installed), assign the Payment Status metric a neutral score of 75 and append the note "Invoice data unavailable -- using neutral default."

### Google Calendar (Optional)

Search for events with client attendees over the last 90 days.
- Supplement the Last Contact metric: if the most recent calendar event with the client is more recent than the most recent email, use the calendar event date instead.
- Detect meeting cancellations: count cancelled events involving the client in the last 30 days. Two or more cancellations trigger the "Meeting Cancellations" risk flag.

When gws CLI is unavailable for Calendar, rely on Gmail data alone for Last Contact. Do not flag the absence as an error.

## Database Discovery

Search for the Companies database using this priority order:

1. **"[FOS] Companies"** — the consolidated HQ database (preferred). Search Notion for a database with this exact title.
2. **"Founder OS HQ - Companies"** — legacy HQ name. Search Notion for a database with this exact title.
3. **"Companies"** or **"CRM - Companies"** — a standalone CRM database. Search by title containing "Companies".
4. **Fallback: "Client Health Dashboard - Health Scores"** — if no Companies database is found, lazy-create a standalone Health Scores database (backward compatibility for non-HQ users). Properties: Client Name (title), Overall Score (number, 0-100), Health Status (select: Green/Yellow/Red), Last Contact Score (number), Response Time Score (number), Open Tasks Score (number), Payment Score (number), Sentiment Score (number), Risk Flags (multi_select), Last Scanned (date), Sources Used (multi_select).

When using the HQ or standalone Companies database (paths 1 or 2), health scores are written directly onto the Company page as property updates — no separate Health Scores database is needed. The Companies database must have (or will be enriched with) these health properties: Health Score (number), Health Status (select), Risk Flags (multi_select), Last Scanned (date), Sources Used (multi_select), Notes (rich_text).

When using the fallback standalone Health Scores DB (path 3), create separate pages per client as before.

## Caching Strategy

### Cache Location

- **HQ / Companies mode**: The `Last Scanned` property on each Company page serves as the cache timestamp. Health scores are read directly from the Company page properties.
- **Fallback mode**: The `Last Scanned` property on the standalone Health Scores DB record serves as the cache timestamp.

### Cache TTL

- Default TTL: 24 hours. Scores older than 24 hours are recomputed on the next scan.
- `--refresh` flag: Bypass cache entirely. Recompute all scores from source data regardless of age.
- On update, overwrite the existing health properties on the Company page (match by the Company page itself). Never create duplicate records.

## Risk Flags

Evaluate these risk conditions after scoring. Attach matching flags to the client's record.

| Flag | Condition |
|------|-----------|
| No Recent Contact | Last Contact score < 20 (roughly 30+ days since contact) |
| Slow Response | Response Time score < 30 (average reply time > 40 hours) |
| Overdue Tasks | Open Tasks score < 50 (more than half of active tasks overdue) |
| Payment Issues | Payment score < 40 (2+ overdue invoices or poor payment history) |
| Negative Sentiment | Sentiment score < 40 |
| Meeting Cancellations | 2+ cancelled meetings with this client in the last 30 days |
| Escalation Language | Detected escalation phrases in recent emails ("disappointed", "concerned about timeline", "need to discuss", "considering alternatives", "not satisfied", "escalating") |
| New Client | Client has been in the CRM for less than 30 days |

A client may have zero, one, or multiple risk flags simultaneously. Display all active flags in the dashboard output.

## Edge Cases

Handle the following situations using the rules outlined below. For detailed scoring formulas, decay curves, and per-metric edge case handling, see `${CLAUDE_PLUGIN_ROOT}/skills/health/client-health-scoring/references/scoring-formulas.md`.

### No Email History
When no Gmail threads exist for a client, set Last Contact score to 0 and Response Time score to 50 (neutral). Add the "No Recent Contact" risk flag.

### New Client
When a client has been in the CRM for less than 30 days, apply a minimum Last Contact score of 40 to avoid penalizing new relationships. Add the "New Client" risk flag for visibility.

### No Invoices
When no invoice records exist in the P11 database for a client, set Payment score to 75 (neutral assumption). Do not add a risk flag -- absence of invoices is not a risk signal.

### No Tasks
When no tasks exist in the CRM or P20 dossier for a client, set Open Tasks score to 100 (no tasks = no overdue tasks).

### All Data Missing
When only the CRM record exists and all other sources return no data, compute the score using available data with neutral defaults for missing metrics. Set the completeness flag to "partial" and warn: "Limited data available -- score based on CRM record only."

### Finance Database Unavailable
When neither the "[FOS] Finance", "Founder OS HQ - Finance", nor the "Invoice Processor - Invoices" database is found, set Payment score to 75 and note "Invoice data unavailable" in Sources Used.

### Sentiment Analysis Unavailable
When the sentiment-analysis skill returns no data for a client, set Sentiment score to 50 (neutral default).

## Graceful Degradation

- **Notion unavailable**: Cannot proceed. Notion is required for both the client list and writing health scores. Report the error and stop.
- **Gmail unavailable**: Set Last Contact and Response Time to neutral defaults (50). Warn: "Gmail unavailable -- contact and response metrics using neutral defaults."
- **Calendar unavailable**: Skip calendar supplementation silently. Rely on Gmail data alone.
- **P20 dossier unavailable**: Fall back to direct Notion task queries and sentiment-analysis skill.
- **P11 database unavailable**: Use neutral Payment score (75).

Never fail the entire health scan because a single optional source is unavailable. Degrade gracefully per source and note which sources contributed in the Sources Used field.

