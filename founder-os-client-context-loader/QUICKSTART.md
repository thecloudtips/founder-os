# Quick Start: Client Context Loader

> Know everything about your client in 30 seconds.

**Plugin #20** | **Pillar**: MCP & Integrations | **Platform**: Claude Code

## What This Plugin Does

- Searches 5 data sources simultaneously for client information
- Assembles a unified dossier with profile, history, open items, and sentiment
- Caches results in Notion for fast repeat access (24h TTL)
- Writes health scores and risk levels back to your CRM
- Generates printable 1-page executive briefs for meetings

### Time Savings

Estimated **15-20 minutes** per client meeting prep compared to manually checking CRM, email, calendar, and documents.

## Available Commands

| Command | Description |
|---------|-------------|
| `/client:load [name]` | Load complete client context from all sources |
| `/client:brief [name]` | Generate a 1-page meeting prep brief |

## Usage Examples

### Example 1: Quick Client Lookup

```
/client:load Acme Corp
```

**What happens:**
Searches your Notion CRM for "Acme Corp", pulls email history from Gmail, and presents a structured dossier with profile, recent activity, open items, and sentiment analysis. Results are cached for 24 hours.

### Example 2: Full Pipeline with All Sources

```
/client:load Acme Corp --team
```

**What happens:**
Launches 5 gatherer agents in parallel — CRM, Email, Docs, Calendar, and Notes — then synthesizes everything through the Context Lead agent. Produces the most complete dossier possible, writes health scores back to CRM, and caches the result.

### Example 3: Meeting Prep Brief

```
/client:brief Acme Corp
```

**What happens:**
Generates a concise 1-page executive brief from the cached dossier. Includes: client profile, key contact, deal status, next meeting, top open items, risk flags, and recent interactions. Designed for quick scanning before a call.

### Example 4: Force Refresh

```
/client:load Acme Corp --refresh
```

**What happens:**
Bypasses the 24h cache and pulls fresh data from all sources. Use this when you know data has changed since the last load.

## Tips

- Run `/client:load` before important meetings to have all context ready
- Use `--team` for the most thorough dossier (requires all MCP servers)
- Use `/client:brief` for a quick printable summary when you're short on time
- The plugin works with just Notion + Gmail — Calendar and Drive are optional enhancements
- Cached dossiers expire after 24 hours; use `--refresh` to force an update

## Related Plugins

- **#03 Meeting Prep Autopilot**: Uses client context to prepare meeting agendas
- **#21 CRM Sync Hub**: Keeps CRM data in sync across email, calendar, and meetings

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Client not found" | Check spelling. The plugin uses fuzzy matching but needs a close match. |
| Partial dossier | Some MCP servers may not be configured. Check completeness score for details. |
| Stale brief | Run `/client:load [name] --refresh` then `/client:brief [name]` |
| MCP server errors | Verify environment variables and credentials. See INSTALL.md. |

## Next Steps

1. Try `/client:load` with one of your existing CRM clients
2. Run the full pipeline with `--team` to see all 6 agents in action
3. Generate a brief before your next client meeting
4. Check `INSTALL.md` for optional enrichment properties that enhance CRM writeback
