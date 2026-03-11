# Quick Start: founder-os-meeting-intelligence-hub

> Multi-source transcript aggregator with intelligence extraction

## Overview

**Plugin #07** | **Pillar**: Daily Work | **Platform**: Claude Code

Gathers meeting transcripts from Fireflies.ai, Notion, Otter.ai, Gemini, and local files, then extracts summaries, decisions, follow-up commitments, and topic tags.

### What This Plugin Does

- Gathers and normalizes transcripts from 5 different sources
- Extracts meeting intelligence through 4 independent analysis pipelines
- Saves structured results to Notion and/or displays in chat
- Suggests cross-plugin integrations with Action Item Extractor (#04) and Follow-Up Tracker (#06)

## Available Commands

| Command | Description |
|---------|-------------|
| `/meeting:intel [source]` | Full pipeline: gather + analyze + save |
| `/meeting:analyze [text-or-file]` | Analysis only on provided transcript |

## Usage Examples

### Example 1: Analyze a Local Transcript

```
/meeting:intel meeting-notes.txt
```

**What happens:**
Auto-detects the source format (Fireflies, Otter, etc.), extracts intelligence, saves to Notion, displays report in chat, and saves the normalized transcript locally.

### Example 2: Process a Fireflies Export

```
/meeting:intel recording.json --source=fireflies
```

**What happens:**
Parses the Fireflies JSON export, runs all 4 extraction pipelines, and saves results to Notion.

### Example 3: Search Notion for Meeting Notes

```
/meeting:intel --notion --date=2026-03-05
```

**What happens:**
Searches your Notion workspace for meeting notes from March 5, lets you select which one to analyze, and processes it.

### Example 4: Quick Analysis Without Saving

```
/meeting:analyze transcript.txt
```

**What happens:**
Analyzes the transcript and displays results in chat only (no Notion save by default). Lighter and faster than `/meeting:intel`.

### Example 5: Analyze with Email Context

```
/meeting:intel notes.md --with-email --output=both
```

**What happens:**
Analyzes the transcript, searches Gmail for related email threads to enrich context, saves to Notion, and displays in chat.

### Example 6: Paste Transcript Directly

```
/meeting:analyze
```
Then paste your meeting notes in the conversation.

**What happens:**
Analyzes the pasted text and displays extracted intelligence in chat.

## Tips

- Start with `/meeting:analyze` for quick analysis -- it defaults to chat output and skips source gathering
- Use `--source=auto` (the default) to let the plugin detect the transcript format automatically
- Add `--with-email` to `/meeting:intel` to enrich analysis with related email context
- Follow-up commitments are formatted for #06 Follow-Up Tracker compatibility

## Related Plugins

This plugin connects with:
- **#04 Action Item Extractor**: Run `/actions:extract-file` on saved transcripts for deeper extraction
- **#06 Follow-Up Tracker**: Follow-ups use compatible promise format for import

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Notion MCP unavailable" | Check Notion API key in `.mcp.json` |
| "File not found" | Verify the file path is correct and accessible |
| "gws CLI not available for Drive" | Install gws CLI and authenticate for Drive access (optional) |
| No decisions/follow-ups found | Normal for short or informal meetings |

## Next Steps

1. Try analyzing a recent meeting transcript with `/meeting:analyze`
2. Run the full pipeline with `/meeting:intel` for auto-detection + Notion save
3. Check your "[FOS] Meetings" database in Notion (or fallback "Founder OS HQ - Meetings" / "Meeting Intelligence Hub - Analyses")
4. Try `/actions:extract-file` on saved transcripts for additional action items
