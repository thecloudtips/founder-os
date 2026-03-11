# founder-os-google-drive-brain

> **Plugin #18** -- Searches, summarizes, and answers questions from Google Drive documents. Navigates folder structures, extracts content from Docs, Sheets, and PDFs, and provides cited answers with optional Notion activity tracking.

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | MCP & Integrations |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Intermediate |
| **Week** | 19 |

## What It Does

Google Drive Brain turns your Google Drive into an intelligent, searchable knowledge base. Instead of manually navigating folders and opening files to find information, this plugin searches across your entire Drive, extracts content from Docs, Sheets, and PDFs, and delivers answers with direct citations back to source documents.

The plugin provides four capabilities:

1. **Search Drive** (`/drive:search`) -- Find files across your Drive with relevance-scored results and preview snippets
2. **Summarize documents** (`/drive:summarize`) -- Generate concise or detailed summaries of any Drive document
3. **Ask questions** (`/drive:ask`) -- Get cited answers synthesized from one or more Drive documents
4. **Organize folders** (`/drive:organize`) -- Get recommend-only suggestions for folder structure improvements

## Requirements

### MCP Servers

- **Google Drive** (`gws` CLI (Drive)) -- File search, folder traversal, and content extraction (Required)
- **Notion** (`@modelcontextprotocol/server-notion`) -- Activity logging and query tracking (Optional)

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/drive:search [query]` | Search Google Drive with relevance scoring and preview snippets |
| `/drive:summarize [file]` | Generate a concise or detailed summary of a Drive document |
| `/drive:ask [question]` | Answer questions with inline citations from Drive documents |
| `/drive:organize [folder]` | Suggest folder structure improvements (recommend-only, never moves files) |

## Skills

- **drive-navigation**: File search with relevance scoring, folder structure traversal, file type filtering, and search result ranking
- **document-qa**: Content extraction from Docs/Sheets/PDFs, answer synthesis from multiple documents, and inline citation generation

## Agent Teams

This plugin does not use Agent Teams.

## Dependencies

This plugin has no dependencies on other Founder OS plugins.

## Blog Post

**Week 19**: "Your Second Brain Lives in Google Drive"

Your Google Drive is full of answers -- proposals, SOWs, meeting notes, financial reports -- but finding them means clicking through folders and scanning documents. Google Drive Brain makes your Drive searchable by meaning, not just filename. Ask a question in plain English and get a cited answer in seconds.

## License

MIT
