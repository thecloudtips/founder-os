# founder-os-linkedin-post-generator

> **Plugin #24** -- Generate LinkedIn posts from topics, documents, or campaigns with multiple frameworks, audience targeting, and hook optimization

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | MCP & Integrations |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Beginner |
| **Week** | 24 |

## What It Does

Turns topics, documents, and campaign ideas into polished LinkedIn posts ready to publish. The LinkedIn Post Generator applies proven content frameworks (story, listicle, contrarian, how-to, and more), targets specific audience segments, and crafts high-engagement opening hooks -- all in founder voice. Generate a single post, create multiple variations for A/B testing, or extract key points from an existing document and reshape them for LinkedIn's format and 3,000-character limit.

## Requirements

### MCP Servers

- **Filesystem** -- Save generated posts to local files (Required)
- **Notion** -- Track generated posts in "[FOS] Content" (Type="LinkedIn Post"), falls back to "Founder OS HQ - Content", then legacy "LinkedIn Post Generator - Posts" (Optional)

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/linkedin:post [topic]` | Generate a LinkedIn post from a topic with framework selection, audience targeting, and founder voice |
| `/linkedin:variations` | Generate multiple variations of a LinkedIn post with different hooks, frameworks, and tones |
| `/linkedin:from-doc [file-or-text]` | Extract key points from a document or pasted text and generate a LinkedIn post |

## Skills

- **LinkedIn Writing**: LinkedIn post frameworks (story, listicle, contrarian, how-to, lesson-learned, data-driven), structure rules, formatting conventions, length modes (short/medium/long), and audience segment targeting
- **Hook Creation**: Opening line formulas (question, bold claim, number, story opener, pattern interrupt), audience-specific hooks, and engagement triggers that stop the scroll
- **Founder Voice**: Professional-but-conversational tone adapted for LinkedIn, opinion injection, practical framing, storytelling patterns, and anti-patterns to avoid

## Agent Teams

This plugin does not use Agent Teams.

## Dependencies

This plugin has no dependencies on other Founder OS plugins.

## Blog Post

**Week 24**: "Write a Week of LinkedIn Posts in 30 Minutes"

## License

MIT
