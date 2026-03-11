# Quick Start: Weekly Review Compiler

> Generate a structured weekly review from tasks, meetings, and emails

## Overview

**Plugin #05** | **Pillar**: Daily Work | **Platform**: Claude Code

The Weekly Review Compiler auto-discovers your Notion task databases, pulls Google Calendar events, and scans Gmail threads to produce a structured 6-section review page in Notion. One command covers wins, meetings, blockers, carryover items, and next-week priorities.

### What This Plugin Does

- Auto-discovers all Notion databases with task completion tracking (no configuration needed)
- Pulls calendar events and classifies meetings (internal, external, one-on-one)
- Scans Gmail for active email threads and communication volume
- Detects blockers through multi-signal analysis (blocked status, overdue, stagnant, unresolved threads)
- Generates AI-ranked top-5 priorities for the coming week
- Creates a formatted Notion page with all 6 sections

### Time Savings

Estimated **30-45 minutes** per week compared to manually compiling a weekly review.

## Available Commands

| Command | Description |
|---------|-------------|
| `/weekly:review` | Generate a structured weekly review from tasks, meetings, and emails |

## Usage Examples

### Example 1: Standard Weekly Review

```
/weekly:review
```

**What happens:** Reviews the most recently completed week (previous Monday-Sunday). Auto-discovers task databases, pulls calendar events, scans Gmail. Creates a Notion page with all 6 sections.

### Example 2: Specific Week

```
/weekly:review --date=2026-02-24
```

**What happens:** Reviews the week containing February 24th (resolves to Mon Feb 23 - Sun Mar 1). Useful for generating past reviews.

### Example 3: Chat-Only Output

```
/weekly:review --output=chat
```

**What happens:** Displays the review directly in conversation without creating a Notion page. Good for a quick look.

### Example 4: Both Notion and Chat

```
/weekly:review --output=both
```

**What happens:** Creates the Notion page AND displays the review in chat. Best of both worlds.

### Example 5: Specific Week with Notion Output

```
/weekly:review --date=2026-03-03 --output=notion
```

**What happens:** Reviews the week of March 3rd and saves to Notion only.

## Tips

- Run `/weekly:review` every Friday afternoon or Monday morning as a habit
- The plugin auto-discovers task databases -- no configuration needed beyond Notion API key
- Gmail is optional -- the review works fine with just Notion and Calendar
- Re-running for the same week updates the existing review (never duplicates)
- The blocker detection catches stagnant tasks you might not notice manually
- Next-week priorities include a calendar preview showing your best focus days

## Related Plugins

This plugin is standalone but works alongside:
- **#01 Inbox Zero Commander**: Email triage feeds into communication patterns
- **#02 Daily Briefing Generator**: Daily version of the review concept
- **#04 Action Item Extractor**: Extracted action items appear as tasks in the review

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Notion MCP is required" | Set NOTION_API_KEY environment variable |
| "No task databases found" | Ensure databases have Status + Date properties |
| "Calendar unavailable" | Not an error -- meeting section shows placeholder. Check Google gws CLI (Calendar). |
| "Gmail data unavailable" | Not an error -- Gmail is optional. Email section shows placeholder. |

## Next Steps

1. Run `/weekly:review --output=chat` for a quick test
2. Check the Notion page for the full formatted review
3. See `INSTALL.md` for MCP server configuration details
