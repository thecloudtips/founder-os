# founder-os-knowledge-base-qa

> **Plugin #23** -- Turn your Notion workspace and Google Drive into a searchable knowledge base with sourced answers and citations.

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | MCP & Integrations |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Intermediate |
| **Week** | 23 |

## What It Does

Searches Notion pages, databases, and Google Drive documents to answer questions with sourced citations. The plugin provides three capabilities:

1. **Ask questions** (`/kb:ask`) -- Get answers sourced from your knowledge base with inline citations and confidence ratings (logged to Notion with Type="Query")
2. **Find documents** (`/kb:find`) -- Browse and discover relevant documents by topic with preview cards (ephemeral, no logging)
3. **Index sources** (`/kb:index`) -- Catalog all knowledge sources with content classification and freshness tracking (saved to Notion with Type="Source")

All Notion records are stored in the consolidated "[FOS] Knowledge Base" database (falls back to "Founder OS HQ - Knowledge Base", then legacy DB names if not found).

## Requirements

### MCP Servers

- **Notion** (`@modelcontextprotocol/server-notion`) -- Knowledge base search and storage (Required)
- **gws CLI** -- Document search across Google Drive files (Optional)

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/kb:ask [question]` | Answer a question with sourced citations from Notion and Drive |
| `/kb:find [topic]` | List relevant documents with preview cards (ephemeral, no logging) |
| `/kb:index` | Catalog all knowledge sources with classification and freshness tracking |

## Skills

- **knowledge-retrieval**: Multi-source search across Notion and Drive with query formulation, relevance scoring, and content extraction
- **answer-synthesis**: Answer construction with citation system, confidence assessment, and no-answer pathway
- **source-indexing**: Source discovery, 9-type content classification, metadata extraction, and freshness tracking

## Agent Teams

This plugin does not use Agent Teams.

## Dependencies

This plugin has no dependencies on other Founder OS plugins.

## Blog Post

**Week 23**: "Turn Your Notion into a Searchable Knowledge Base"

## License

MIT
