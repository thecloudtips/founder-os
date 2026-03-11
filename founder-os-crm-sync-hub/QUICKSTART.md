# Quick Start: founder-os-crm-sync-hub

> Sync email and calendar activities to Notion CRM with intelligent client matching and AI summaries.

## Overview

**Plugin #21** | **Pillar**: MCP & Integrations | **Platform**: Claude Code

CRM Sync Hub automatically logs your email conversations and calendar meetings into the Notion CRM Pro Communications database. Each synced activity gets an AI-generated summary, sentiment classification, and intelligent client matching — so your CRM stays current without manual data entry.

### What This Plugin Does

- Syncs Gmail email threads to CRM with subject, participants, and AI summary
- Syncs Google Calendar meetings to CRM with attendees, duration, and AI summary
- Matches activities to CRM clients using a 5-step progressive matching algorithm
- Prevents duplicates on re-sync with title + date + type deduplication
- Provides a fast CRM-only context view for any client before calls or meetings

## Available Commands

| Command | Description |
|---------|-------------|
| `/crm:sync-email [thread_id]` | Sync email threads to CRM — single or batch |
| `/crm:sync-meeting [event_id]` | Sync calendar meetings to CRM — single or batch |
| `/crm:context [client]` | Load CRM context for a client (read-only) |

## Usage Examples

### Example 1: Sync a Single Email Thread

```
/crm:sync-email thread_abc123
```

**What happens:**
- Fetches the email thread from Gmail
- Runs 5-step client matching on all participants (email domain, contact lookup, fuzzy name)
- Generates a 2-3 sentence AI summary and classifies sentiment
- Creates a Communications record in Notion linked to the matched Company and Contact
- Displays the synced activity with client match confidence

---

### Example 2: Batch Sync Last 7 Days of Emails

```
/crm:sync-email
```

**What happens:**
- Scans your Gmail sent folder for threads from the last 7 days (default window)
- Filters out internal emails (same domain), automated emails (noreply), drafts, and very short threads
- Checks each thread against existing Communications records to skip already-synced items
- Processes each unsynced thread: client matching, AI summary, sentiment, CRM write
- Displays a batch status report showing synced, updated, skipped, unmatched, and failed counts
- Lists any unmatched participants at the end for manual resolution

---

### Example 3: Preview Batch Sync with Dry Run

```
/crm:sync-email --since=14d --dry-run
```

**What happens:**
- Same scanning and matching as Example 2, but covers the last 14 days
- Displays everything that WOULD be synced with `[DRY RUN]` prefix
- Does not write anything to Notion
- Useful for verifying matches and coverage before committing

---

### Example 4: Sync a Single Meeting

```
/crm:sync-meeting event_xyz789
```

**What happens:**
- Fetches the calendar event from Google Calendar
- Extracts title, attendees (with RSVP status), time, duration, and location
- Skips cancelled events automatically
- Runs client matching on external attendee email addresses
- Generates a meeting-focused AI summary (purpose, participants, key topics)
- Creates a Communications record with Type "Meeting Held" (or "Meeting Scheduled" for future events with `--upcoming`)

---

### Example 5: Batch Sync Recent Meetings Including Upcoming

```
/crm:sync-meeting --since=7d --upcoming
```

**What happens:**
- Scans Google Calendar for meetings in the last 7 days plus the next 7 days
- Filters out cancelled events, declined events, all-day events, internal-only meetings, and personal blocks
- Past meetings are logged as "Meeting Held"; future meetings as "Meeting Scheduled"
- Scheduled meetings auto-update to "Meeting Held" on the next sync after the meeting occurs
- Displays a batch status report with counts for all categories

---

### Example 6: Quick CRM Context Before a Call

```
/crm:context Acme Corp
```

**What happens:**
- Searches your CRM for the company (exact match, then fuzzy)
- Pulls the company profile: industry, size, status, website
- Lists key contacts with roles, types, and last contact dates
- Shows recent activities from the last 30 days (type, date, title, sentiment)
- Lists open deals with values, stages, and close dates
- Calculates health indicators: contact recency, engagement level, pipeline value, sentiment trend

---

### Example 7: Full CRM Context with Extended History

```
/crm:context "Tech Solutions Inc" --days=90 --full
```

**What happens:**
- Same as Example 6 but looks back 90 days instead of 30
- With `--full`, shows the complete AI-generated summary for each activity instead of just the title
- Gives a comprehensive view of the entire client relationship over the quarter

---

## Tips

- Start with `/crm:sync-email --dry-run` to preview what would be synced before writing to CRM
- Use `--since=Nd` to control the batch window — `7d`, `2w`, and `1m` formats are all supported
- Use `--client="Client Name"` to skip matching when you know the client (saves time on single syncs)
- Run both sync commands regularly to keep your CRM current — deduplication prevents duplicate records
- Use `/crm:context` before client calls to get a quick relationship overview from CRM data
- Unmatched items are collected at the end of batch runs — you can assign them without re-running the sync
- This plugin writes to "[FOS] Communications" (or falls back to "Founder OS HQ - Communications" / "Communications" / "CRM - Communications") — the same database that Plugin #20 (Client Context Loader) reads from

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Gmail unavailable" | Verify gws CLI is available for Gmail in `.mcp.json` — see [INSTALL.md](INSTALL.md) |
| "Google Calendar unavailable" | Verify Google gws CLI is available for Calendar — see [INSTALL.md](INSTALL.md) |
| "Notion unavailable" | Sync results display in chat but are not saved. Configure Notion MCP in [INSTALL.md](INSTALL.md) |
| "No client found matching..." | Client is not in the Companies DB. Add them in Notion or use `--client` to assign manually |
| Low confidence match warning | Review the suggested match. The plugin asks for confirmation below 0.7 confidence |
| Duplicate records in CRM | Check deduplication — records match on Title + Date + Type. Report if duplicates persist |
| "Event is in the future" | Use `--upcoming` flag to include future meetings in the sync |

## Next Steps

1. Run `/crm:sync-email --dry-run` to preview email sync results
2. Run `/crm:sync-email` to sync your last 7 days of email activity
3. Run `/crm:sync-meeting` to sync your last 7 days of meetings
4. Use `/crm:context [client]` to verify activities appear in the CRM
5. Set up a regular cadence — run both sync commands weekly to keep CRM current
