# Quick Start: LinkedIn Post Generator

> Generate LinkedIn posts from topics, documents, or campaigns with multiple frameworks, audience targeting, and hook optimization

## Overview

**Plugin #24** | **Pillar**: MCP & Integrations | **Platform**: Claude Code

The LinkedIn Post Generator turns topics, documents, and ideas into polished LinkedIn posts using proven content frameworks, audience targeting, and optimized hooks -- all in founder voice.

### What This Plugin Does

- Generates LinkedIn posts from a topic using selectable frameworks (story, listicle, contrarian, how-to, lesson-learned, data-driven)
- Creates multiple post variations with different hooks, frameworks, and tones for A/B testing
- Extracts key points from documents or pasted text and reshapes them into LinkedIn-ready posts

### Time Savings

Estimated **2 hours per week** compared to writing and iterating on LinkedIn posts manually.

## Available Commands

| Command | Description |
|---------|-------------|
| `/linkedin:post [topic]` | Generate a LinkedIn post from a topic with framework selection and audience targeting |
| `/linkedin:variations` | Generate multiple variations of a post with different hooks, frameworks, and tones |
| `/linkedin:from-doc [file-or-text]` | Extract key points from a document or pasted text and generate a LinkedIn post |

## Usage Examples

### Example 1: Generate a Post from a Topic

```
/linkedin:post "why I stopped using OKRs" --framework=story
```

**What happens:** Generates a single LinkedIn post using the story framework. The plugin crafts an engaging hook, structures the narrative with line breaks and white space for readability, and closes with a call-to-action. The post is saved to `linkedin-posts/` and logged to Notion if configured.

### Example 2: Create Variations for A/B Testing

```
/linkedin:variations --count=3
```

**What happens:** Takes the most recently generated post topic and produces 3 distinct variations, each with a different hook formula, framework, and tone. Useful for testing which angle resonates most with your audience before publishing.

### Example 3: Convert a Document into a LinkedIn Post

```
/linkedin:from-doc blog-post.md --audience=technical
```

**What happens:** Reads the document, extracts the key points, and generates a LinkedIn post targeted at a technical audience. Works with blog posts, meeting notes, project updates, or any text content. Adapts language and depth to the specified audience segment.

### Example 4: Quick Post with Auto Framework

```
/linkedin:post "3 mistakes I made hiring my first employee"
```

**What happens:** Uses the default `--framework=auto` mode, which analyzes the topic and selects the best-fit framework automatically. In this case, it would likely choose the lesson-learned or story framework based on the topic structure.

### Example 5: Post from Pasted Text

```
/linkedin:from-doc "We just hit $1M ARR after 18 months. Here's what nobody tells you about the journey from $0 to $1M..."
```

**What happens:** Accepts inline text instead of a file path. Extracts the core message and generates a structured LinkedIn post with an optimized hook and formatting.

## Tips

- Use `--framework=auto` (the default) to let the plugin pick the best framework for your topic
- `/linkedin:variations` is great for A/B testing different angles on the same idea
- Posts are saved to `linkedin-posts/` by default
- LinkedIn's character limit is 3,000 -- the plugin enforces this automatically
- The founder voice skill keeps posts professional but conversational -- no corporate jargon, no engagement bait
- Pair with `/newsletter` (Plugin #08) to repurpose newsletter content into LinkedIn posts

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Filesystem MCP server is not connected" | Check `.mcp.json` and verify npx is in your PATH |
| Post exceeds 3,000 characters | Re-run with `--length=short` or edit the saved file manually |
| Notion unavailable | Not an error -- posts display in chat and save locally. Configure Notion per INSTALL.md |
| Framework doesn't fit the topic | Use `--framework=auto` or try a different framework explicitly |

## Next Steps

1. Try `/linkedin:post "your topic here"` to generate your first post
2. Run `/linkedin:variations --count=3` to create multiple angles
3. Check `INSTALL.md` for Notion configuration to enable post history tracking
