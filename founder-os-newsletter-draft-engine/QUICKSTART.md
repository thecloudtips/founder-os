# Quick Start: founder-os-newsletter-draft-engine

> Researches topics across web, GitHub, Reddit, and Quora, then generates structured newsletter drafts in founder voice.

## Overview

**Plugin #08** | **Pillar**: Daily Work | **Platform**: Claude Code

Turn any topic into a publish-ready newsletter draft. Research, outline, and write in minutes instead of hours.

### What This Plugin Does

- Performs deep multi-source research across web, GitHub, Reddit, and Quora
- Extracts and deduplicates findings with recency scoring
- Builds a structured newsletter outline with configurable sections
- Writes full newsletter drafts in professional-but-conversational founder voice
- Outputs Substack-compatible markdown ready for publishing

### Time Savings

Estimated **2-3 hours** per newsletter compared to manually researching, outlining, and drafting.

## Available Commands

| Command | Description |
|---------|-------------|
| `/newsletter [topic]` | Full pipeline: research, outline, and draft in one run |
| `/newsletter:research [topic]` | Deep multi-source research on a topic |
| `/newsletter:outline` | Create newsletter structure from gathered research |
| `/newsletter:draft` | Write full newsletter from outline |

### Key Flags

| Flag | Applies To | Description |
|------|-----------|-------------|
| `--sources=web,github,reddit,quora` | `research`, `newsletter` | Choose which sources to query (default: all) |
| `--days=N` | `research`, `newsletter` | Limit research to the last N days (default: 30) |
| `--sections=N` | `outline`, `newsletter` | Number of main sections in the newsletter (default: 5) |
| `--output=PATH` | `draft`, `newsletter` | Custom output file path (default: `newsletters/[topic-slug]-[YYYY-MM-DD].md`) |

## Usage Examples

### Example 1: Full Pipeline

```
/newsletter "what's new in AI"
```

**What happens:** Researches "what's new in AI" across all sources (web, GitHub, Reddit, Quora), builds a 5-section outline, writes the full newsletter in founder voice, and saves it to `newsletters/whats-new-in-ai-2026-02-28.md`.

### Example 2: Research Only

```
/newsletter:research "react server components" --days=7
```

**What happens:** Searches for "react server components" across all sources, limited to the last 7 days. Returns a structured research summary with findings scored by recency and relevance, deduplicated across sources. Use this to review raw material before committing to an outline.

### Example 3: Filtered Sources

```
/newsletter:research "devops tools" --sources=web,github
```

**What happens:** Researches "devops tools" using only web search and GitHub, skipping Reddit and Quora. Useful when you want technical results without community discussion noise.

### Example 4: Custom Outline

```
/newsletter:outline --sections=3
```

**What happens:** Creates a newsletter outline from the most recent research session with 3 main sections instead of the default 5. The outline follows the Hook, Main, Takeaways, CTA structure. Review and adjust the outline before running `/newsletter:draft`.

### Example 5: Draft with Custom Output Path

```
/newsletter:draft --output=drafts/my-newsletter.md
```

**What happens:** Writes the full newsletter draft from the current outline and saves it to `drafts/my-newsletter.md` instead of the default `newsletters/` directory. The draft is Substack-compatible markdown.

### Example 6: Full Pipeline with All Flags

```
/newsletter "founder productivity hacks" --sources=web,reddit --days=14 --sections=4 --output=newsletters/productivity-special.md
```

**What happens:** Runs the complete pipeline -- researches "founder productivity hacks" on web and Reddit from the last 14 days, builds a 4-section outline, writes the full draft in founder voice, and saves to the specified output path.

## Tips

- **Run research first to review sources.** Use `/newsletter:research` before the full pipeline to verify the topic has enough material. If results are thin, try broadening the topic or extending the `--days` window.
- **Iterate on the outline before drafting.** Run `/newsletter:outline` and review the proposed structure. Adjust sections or reorder before running `/newsletter:draft` to avoid rewriting the entire draft.
- **Use `--sources` to control tone.** Web and GitHub sources produce more technical content. Reddit and Quora add community perspectives and real-world experiences. Mix based on your newsletter audience.
- **Check the output file.** Drafts are saved as Substack-compatible markdown. Open the file, review formatting, and copy-paste directly into your Substack editor.
- **Re-runs update, not duplicate.** Running the same topic on the same day updates the existing newsletter file rather than creating a duplicate.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No research results found | Broaden the topic or extend the lookback window with `--days=60`. Check that the topic is specific enough to produce results. |
| Output file not created | Ensure the `newsletters/` directory exists. Create it with `mkdir -p newsletters` in the plugin root. |
| Notion tracking not working | Notion MCP is optional. Verify your integration token and workspace access. The plugin will work without it, showing results in chat only. |
| Draft tone feels off | The founder-voice skill targets professional-but-conversational tone. Review the draft and adjust specific sections manually, or re-run with different source filters to change the input material. |
| Sources flag not filtering | Use comma-separated values without spaces: `--sources=web,github` not `--sources=web, github`. Valid sources are `web`, `github`, `reddit`, and `quora`. |

## Next Steps

1. Run `/newsletter:research "your topic"` to test the research pipeline
2. Review the findings and run `/newsletter:outline` to structure your newsletter
3. Run `/newsletter:draft` to generate the full draft
4. Open the output file and copy into your Substack editor
5. Check `INSTALL.md` for optional Notion tracking setup
