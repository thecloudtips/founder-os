# Quick Start: Meeting Prep Autopilot

> Your AI research assistant that builds deep meeting prep docs with attendee profiles, open items, relevant documents, and framework-based talking points (SPIN/GROW/SBI) -- all saved to Notion, ready 15 minutes before you walk in.

## Overview

**Plugin #03** | **Pillar**: Daily Work | **Platform**: Claude Code

Meeting Prep Autopilot takes a single calendar event and fans out across Google Calendar, Gmail, Notion CRM, and optionally Google Drive (all via the `gws` CLI for Google services, Notion MCP for CRM) to assemble everything you need to walk into a meeting prepared. Instead of spending 10-15 minutes per meeting opening tabs, scanning threads, and reviewing notes, run one command and get a complete prep document with attendee context, open items, and a tailored discussion guide.

### What This Plugin Does

- Pulls a calendar event (via `gws` CLI) and enriches it with attendee profiles from Notion CRM, email history from Gmail (via `gws` CLI), and relevant documents from Google Drive (via `gws` CLI)
- Classifies each meeting by type (external-client, one-on-one, ad-hoc, recurring, group-meeting, internal-sync) and scores importance on a 1-5 scale
- Compiles open items across sources into four categories: you owe, owed to you, shared/unclear, and resolved since last meeting
- Generates framework-based talking points (SPIN for client calls, GROW for 1:1s, SBI for syncs, and more), a suggested opener, proposed next steps, and a meeting close
- Saves everything to a Notion page and tracks all preps in the shared "[FOS] Meetings" database (falls back to "Founder OS HQ - Meetings", then "Meeting Prep Autopilot - Prep Notes")

### Time Savings

Estimated **10-15 minutes per meeting** compared to manually reviewing email threads, CRM records, notes, and documents before each meeting.

## Available Commands

| Command | Description |
|---------|-------------|
| `/meeting:prep` | Generate a deep prep document for a specific meeting or pick from today's list |
| `/meeting:prep-today` | Batch-prep all of today's qualifying meetings in sequence |

## Usage Examples

### Example 1: Quick Single-Meeting Prep by Event ID

```
/meeting:prep abc123
```

**What happens:**
A single agent fetches the calendar event `abc123` via the `gws` CLI, resolves attendee identities against Notion CRM, searches Gmail via `gws` for recent threads with each attendee (default 90-day lookback), checks Google Drive via `gws` for related documents, compiles open items, and generates a discussion guide using the appropriate framework for the meeting type. The full prep document is saved to a Notion page and displayed in chat. Takes about 20-30 seconds for a typical 3-attendee meeting.

### Example 2: No Event ID -- Pick from Today's List

```
/meeting:prep
```

**What happens:**
When you omit the event ID, the plugin fetches all remaining meetings for today via the `gws` CLI, filters out focus blocks, OOO holds, cancelled events, and solo events, then presents a numbered list:

```
Today's remaining meetings:
1. 10:00 - 10:30 | Q2 Planning with Acme Corp (3 attendees)
2. 11:00 - 11:30 | 1:1 with Sarah (2 attendees)
3. 14:00 - 15:00 | Sprint Review (6 attendees)

Enter a number to select, or provide an event_id directly:
```

Pick a number and the full prep runs for that meeting.

### Example 3: Full Team Pipeline Mode

```
/meeting:prep abc123 --team
```

**What happens:**
Launches 5 agents in a parallel-gathering pipeline. Four gatherer agents run simultaneously -- Calendar Agent resolves the event and classifies it, Gmail Agent searches attendee email threads, Notion Agent pulls CRM contacts and past meeting notes, and Drive Agent finds related documents. Once all gatherers complete (or timeout after 30 seconds), the Prep Lead agent synthesizes everything into attendee profiles, open items, and a framework-based discussion guide, then saves the full prep to Notion. The pipeline continues as long as at least 2 agents return data. A pipeline execution table shows each agent's status, duration, and items found.

### Example 4: Batch All Today's Meetings

```
/meeting:prep-today
```

**What happens:**
Fetches all of today's calendar events, filters out non-meetings (focus blocks, solo events, cancelled/declined), and shows a confirmation list with meeting times, titles, types, and attendee counts. After you confirm, each meeting is prepped in chronological order. An attendee cache is built upfront so overlapping contacts across meetings are only looked up once. A summary table at the end shows all generated preps with Notion links.

### Example 5: Skip Internal Meetings

```
/meeting:prep-today --skip-internal
```

**What happens:**
Same as the batch flow, but meetings classified as `internal-sync` or `group-meeting` (where all attendees share your org domain) are excluded from the prep list. Useful when your calendar is packed with standups and syncs but you only need deep prep for external or cross-functional meetings. Skipped meetings are listed in the summary with the reason.

### Example 6: Custom Email Lookback

```
/meeting:prep abc123 --hours=720
```

**What happens:**
Runs the full prep but expands the Gmail search window to 720 hours (30 days) instead of the default 2160 hours (90 days). Use a shorter window to focus on recent correspondence, or extend it when dealing with a client you have not spoken to in a while. This flag works with both `/meeting:prep` and `/meeting:prep-today`.

### Example 7: Output to Chat Only

```
/meeting:prep abc123 --output=chat
```

**What happens:**
Generates the full prep document and displays it directly in chat without saving to Notion. Useful for a quick glance before a meeting when you do not need a permanent record, or when testing the plugin before Notion is fully configured. Other options: `--output=notion` (save to Notion only, no chat display) or `--output=both` (default behavior).

## Flags Reference

| Flag | Default | Applies To | Description |
|------|---------|------------|-------------|
| `--team` | off | both commands | Activate full 5-agent parallel-gathering pipeline |
| `--hours=N` | 2160 (90 days) | both commands | Email lookback window in hours for attendee correspondence |
| `--output=VALUE` | both | `/meeting:prep` | Where to deliver the prep: `notion`, `chat`, or `both` |
| `--skip-internal` | off | `/meeting:prep-today` | Exclude internal syncs and group meetings from batch |
| `--yes` | off | `/meeting:prep-today` | Auto-proceed without showing the confirmation prompt |

## Tips

- Run `/meeting:prep-today` each morning to batch-prep your entire day, then use `/meeting:prep [event_id]` 15 minutes before any meeting added later for a fresh prep with the latest context
- Pair with Daily Briefing Generator: run `/daily:briefing` in the morning for a high-level overview of your day, then `/meeting:prep` before each specific meeting for deep attendee context and tailored talking points
- Google Drive is optional and silently skipped if not accessible via `gws` -- the prep document still includes attendee profiles, open items, and talking points from Calendar, Gmail, and Notion
- Talking point frameworks are auto-selected based on meeting type: SPIN for external client calls, GROW for one-on-ones, SBI for internal syncs, Delta-Based Agenda for recurring meetings, Context-Gathering for ad-hoc meetings, and Contribution Mapping for large group meetings
- If you run `/meeting:prep` again for the same event on the same day, the existing Notion page and database entry are updated in place rather than duplicated
- For back-to-back meetings with overlapping attendees, `/meeting:prep-today` deduplicates open items and talking points across consecutive preps so you do not repeat yourself

## Related Plugins

This plugin connects with:
- **#02 Daily Briefing Generator**: Provides a high-level morning overview; Meeting Prep Autopilot goes deeper on individual meetings with full attendee profiles and discussion guides
- **#21 CRM Sync Hub**: Supplies the Notion CRM data (Companies, Contacts, Deals) that Meeting Prep Autopilot uses for attendee context and relationship history
- **#20 Client Context Loader**: Builds comprehensive client dossiers; Meeting Prep Autopilot provides meeting-specific context that complements the broader client picture

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Notion MCP not configured" | Notion is required for CRM context and prep output. Check `.mcp.json` and ensure `NOTION_API_KEY` is set in your environment. See `INSTALL.md` for setup. |
| No meetings shown | Verify the `gws` CLI is installed (`which gws`) and authenticated (`gws auth login`). Check that events exist for today and are not all filtered out (cancelled, declined, focus blocks). |
| Missing attendee context | Ensure the `gws` CLI has Gmail access. Without Gmail, attendee profiles will lack email thread counts, unanswered items, and sentiment indicators. Run `gws auth login` if needed. |
| No documents found | Google Drive is optional. Ensure `gws` has Drive scope authorized if you want related documents surfaced in your prep. The plugin works fully without it. |
| Talking points seem generic | Check if your Notion CRM has data for the meeting's attendees. The plugin tailors talking points based on deal stage, relationship status, and communication history -- without CRM data, it falls back to a context-gathering framework. |
| Event not found | Double-check the event ID. Run `/meeting:prep` with no arguments to browse today's meetings and select interactively. |
| "Pipeline requires at least 2 data sources" | In `--team` mode, at least 2 gatherer agents must return data. Check that `gws` CLI is working for Calendar/Gmail and Notion MCP is responding. |
| Prep takes too long in `--team` mode | Individual agents timeout after 30 seconds. If the pipeline is slow, check `gws` CLI and Notion MCP connectivity. The pipeline continues with partial results from agents that complete in time. |

## Next Steps

1. Run `/meeting:prep` to see today's meetings and prep one interactively
2. Review the generated Notion page and explore the attendee profiles and discussion guide
3. Try `/meeting:prep-today` to batch-prep your entire day
4. Run `/meeting:prep [event_id] --team` to see the full parallel pipeline in action
5. Check `INSTALL.md` for MCP server configuration and optional gws CLI (Drive) setup
