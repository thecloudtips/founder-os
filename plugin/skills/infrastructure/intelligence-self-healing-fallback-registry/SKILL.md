---
name: fallback-registry
description: Seed data of known fallback paths for all 30 Founder OS plugins. Used by the self-healing module when a data source is classified as degradable.
---

## Overview

The fallback registry maps known failure modes to graceful degradation paths. This is seed data — the learning system extends it over time based on which fallbacks users accept vs reject.

## Universal Fallbacks (All Plugins)

| Failure | Fallback | Output Note |
|---|---|---|
| Notion DB not found | Apply 3-step discovery (search "[FOS] Name" → "Founder OS HQ - Name" → legacy name). If all fail, output to local file instead. | "Notion output saved to local file — sync manually when available" |
| Notion API rate limited | Retry with backoff (handled by transient classification). If exhausted, queue output for next run. | "Notion rate limited — output queued for next run" |
| gws CLI not installed | Skip all Google data sources | "Google Workspace data unavailable — install gws CLI" |
| gws auth expired | Prompt user to re-authenticate | "Google auth expired — run 'gws auth login' to reconnect" |

## Pillar 1: Daily Work

| Plugin | Failure | Fallback | Output Note |
|---|---|---|---|
| P01 Inbox Zero | Gmail unavailable | Skip triage, log partial state | "Gmail unreachable — triage skipped" |
| P02 Daily Briefing | Calendar fails | Briefing from Gmail + Notion only | "Calendar data missing from briefing" |
| P02 Daily Briefing | Gmail fails | Briefing from Calendar + Notion only | "Email summary missing from briefing" |
| P03 Meeting Prep | Drive search fails | Prep from Calendar + Notion + Gmail | "No Drive documents found for meeting" |
| P05 Weekly Review | Calendar fails | Review from Gmail + Notion metrics | "Calendar events missing from weekly review" |
| P06 Follow-Up Tracker | Gmail unavailable | Check Notion tasks only | "Email follow-ups not checked — Gmail unavailable" |

## Pillar 2: Code Without Coding

| Plugin | Failure | Fallback | Output Note |
|---|---|---|---|
| P09 Report Generator | Filesystem write fails | Output report as chat message | "Could not save to file — report shown inline" |
| P10 Client Health | One health score source down | Partial score, flag stale metric | "Health score partial — {metric} data unavailable" |
| P11 Invoice Processor | Filesystem read fails | Prompt user for manual file path | "Could not read invoice file — please provide path" |
| P13 Contract Analyzer | Filesystem read fails | Prompt user for manual file path | "Could not read contract file — please provide path" |

## Pillar 3: MCP & Integrations

| Plugin | Failure | Fallback | Output Note |
|---|---|---|---|
| P18 Drive Brain | Drive unavailable | Return cached results from Notion Activity Log | "Drive search unavailable — showing last known results" |
| P19 Slack Digest | Slack unavailable | Skip digest entirely | "Slack unavailable — digest skipped" |
| P20 Client Context | Drive fails | Dossier from Notion + Gmail only | "No Drive documents in client dossier" |
| P21 CRM Sync | Calendar down, Gmail up | Sync emails only | "Calendar sync skipped — email communications synced" |
| P21 CRM Sync | Gmail down, Calendar up | Sync calendar only | "Email sync skipped — calendar events synced" |

## Pillar 4: Meta & Growth

| Plugin | Failure | Fallback | Output Note |
|---|---|---|---|
| P25 Time Savings | Notion query fails | Estimate from local event history | "Time savings estimated from local data — Notion unavailable" |
| P27 Workflow Automator | Filesystem write fails | Output workflow as chat message | "Could not save workflow file — shown inline" |

## Extending the Registry

The self-healing learning system extends this registry by:
1. Tracking which fallbacks users accept (no re-run after degraded output)
2. Tracking which fallbacks users reject (re-run or complaint after degraded output)
3. Promoting successful new recovery paths discovered by user overrides
4. Demoting fallbacks with low acceptance rates
