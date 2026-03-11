# Quick Start: founder-os-action-item-extractor

> Extracts structured action items from meeting transcripts, email threads, or documents and auto-creates Notion tasks.

## Overview

**Plugin #04** | **Pillar**: Daily Work | **Platform**: Claude Code

Paste any text content and this plugin will find action items, figure out who owns them, parse deadlines, assign priorities, and create tasks in Notion automatically.

### What This Plugin Does

- Extracts action items from meeting transcripts, emails, and documents
- Identifies owners from @mentions, named delegation, and context clues
- Parses deadlines from explicit dates and urgency language ("ASAP", "by Friday", "EOW")
- Creates structured tasks in Notion with all metadata populated
- Detects and skips duplicates within a 14-day window

### Time Savings

Estimated **15-30 minutes** per meeting compared to manually reviewing notes and creating tasks.

## Available Commands

| Command | Description |
|---------|-------------|
| `/actions:extract [text]` | Extract action items from pasted text |
| `/actions:extract-file [path]` | Extract action items from a file on disk |

## Usage Examples

### Example 1: Extract from Meeting Notes

```
/actions:extract Meeting notes from standup 2/27: John will review the API spec by Friday. Sarah to update the deployment docs by EOD. Next steps: 1. Mike to draft the project charter by March 5 2. Schedule stakeholder interviews - PM, ASAP 3. Set up staging environment - Dev team, this week
```

**What happens:**
The plugin detects this as a meeting transcript, extracts 5 action items with owners (John, Sarah, Mike, PM/user, Dev team/user), parses deadlines (Friday, today, March 5, today, this Friday), assigns priorities, and creates 5 Notion tasks.

### Example 2: Extract from a File

```
/actions:extract-file ~/Documents/meeting-notes-2026-02-25.md
```

**What happens:**
The plugin reads the file, detects the source type, extracts all action items, and creates Notion tasks. The filename is used as the source title if no title is found in the content.

### Example 3: Extract from Email Content

```
/actions:extract From: alice@example.com Subject: Q4 Planning Date: Feb 25, 2026 Hi team, Please review the attached budget proposal by Thursday. Bob, can you prepare the slide deck for Monday's presentation? Also, I need someone to coordinate with the design team on the new branding materials. Thanks, Alice
```

**What happens:**
The plugin detects email format, extracts 3 action items (review budget, prepare slides, coordinate with design team), assigns Bob as owner for the slides task, defaults to "user" for the others, and creates Notion tasks with deadlines.

## Tips

- For best results, paste the complete text including headers, speaker labels, and timestamps
- The plugin handles multiple action items per source — no need to split them up
- If Notion is not configured, results display in chat instead (no data is lost)
- Use `/actions:extract-file` with no path to interactively search for files

## Related Plugins

This plugin connects with:
- **#07 Voice Note Processor**: Transcribes audio recordings that can then be processed for action items

## Troubleshooting

| Issue | Solution |
|-------|----------|
| MCP server not responding | Check `.mcp.json` configuration and Notion API key |
| Command not found | Verify plugin is installed in the correct directory |
| No action items found | Ensure the text contains actionable language (requests, assignments, commitments) |
| Duplicate tasks appearing | Duplicate detection uses a 14-day window — older tasks won't be caught |

## Next Steps

1. Try extracting action items from your latest meeting notes
2. Set up Notion integration for automatic task creation
3. Explore the `skills/action-extraction/` folder for the extraction rules this plugin uses
4. Check `INSTALL.md` for gws CLI setup to read files directly from Google Drive
