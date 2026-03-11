# Quick Start: founder-os-client-health-dashboard

> Scans Notion CRM clients, computes 5 health metrics, and outputs a color-coded RAG dashboard with risk flags and recommended actions.

## Overview

**Plugin #10** | **Pillar**: Code Without Coding | **Platform**: Claude Code

Monitor the health of every client relationship at a glance. Never let an at-risk client slip through the cracks.

### What This Plugin Does

- Scores every CRM client on 5 health metrics (0-100 scale)
- Classifies clients as Green (healthy), Yellow (needs attention), or Red (at risk)
- Detects risk flags like payment issues, escalation language, and meeting cancellations
- Generates detailed single-client health reports with recommended actions
- Caches results for 24 hours to avoid redundant API calls

### Time Savings

Estimated **15-20 minutes** per week compared to manually reviewing client health across email, CRM, calendar, and invoices.

## Available Commands

| Command | Description |
|---------|-------------|
| `/client:health-scan` | Scan all CRM clients and compute health scores |
| `/client:health-report` | Detailed health report for a single client |

## Usage Examples

### Example 1: Full Client Health Scan

```
/client:health-scan
```

**What happens:** Scans all active clients in your Notion CRM, computes 5-metric health scores, classifies into RAG tiers, and displays a dashboard sorted by at-risk clients first. Results cached in Notion.

### Example 2: Show Only At-Risk Clients

```
/client:health-scan --status=red
```

**What happens:** Shows only clients with Red status (score < 50). Use for a quick morning check on clients needing immediate attention.

### Example 3: Top 5 At-Risk Clients

```
/client:health-scan --limit=5
```

**What happens:** Shows the 5 clients with the lowest health scores, regardless of tier. Useful for weekly priority review.

### Example 4: Force Fresh Scores

```
/client:health-scan --refresh
```

**What happens:** Bypasses the 24-hour cache and recomputes all scores from fresh data. Use when you know recent activity has changed (e.g., after sending several emails or resolving invoices).

### Example 5: Single Client Scan

```
/client:health-scan --client="Acme Corp"
```

**What happens:** Scans only "Acme Corp" and displays its health score with full metric breakdown.

### Example 6: Detailed Client Health Report

```
/client:health-report Acme Corp
```

**What happens:** Generates a deep-dive report for Acme Corp showing: overall score with RAG badge, per-metric breakdown with scoring details, active risk flags, recommended actions, and recent activity timeline (last 5 emails + last 3 meetings).

## Tips

- Run `/client:health-scan --status=red` as part of your weekly client review
- Use `/client:health-report` before client meetings for quick context
- Install Plugin #20 (Client Context Loader) and #11 (Invoice Processor) for richer scoring data
- Google Calendar is optional but improves sentiment analysis with meeting pattern detection
- The `--refresh` flag forces fresh computation — useful after major client interactions

## Related Plugins

This plugin integrates with:
- **#20 Client Context Loader**: Reads cached dossier data for enriched scoring. Works independently when not installed.
- **#11 Invoice Processor**: Reads invoice payment history for the Payment Status metric. Uses neutral defaults when not installed.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Notion MCP not responding | Check API key and workspace sharing. Run `/mcp` to verify. |
| No clients found | Ensure CRM Companies database has "Active" or "Prospect" status entries |
| Gmail errors | Check credentials paths and OAuth token |
| Scores seem stale | Use `--refresh` to bypass 24h cache |
| Payment metric always 75 | Plugin #11 Invoice Processor may not be installed |
| Sentiment always 50 | Check Gmail access — sentiment requires email data |

## Next Steps

1. Run `/client:health-scan` to see your full client health dashboard
2. Review any Red/Yellow clients with `/client:health-report [name]`
3. Set up a weekly habit of checking `--status=red`
4. Install optional plugins (#20, #11) for richer scoring
5. Check `INSTALL.md` for advanced configuration
