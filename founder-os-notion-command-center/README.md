# founder-os-notion-command-center

> **Plugin #17** -- Control your Notion workspace with plain English. Create pages and databases, search and query content, update properties and blocks, and deploy pre-built database templates.

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | MCP & Integrations |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Intermediate |
| **Week** | 18 |

## What It Does

Translates natural language into Notion API operations. Instead of navigating the Notion UI or learning the API, describe what you want in plain English and the plugin handles the rest -- creating pages, designing database schemas, querying records, updating properties, and deploying pre-built templates.

## Requirements

### MCP Servers

- **Notion** (`@modelcontextprotocol/server-notion`) -- Full Notion API access (required)

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/notion:create [description]` | Create a Notion page or database from a natural language description |
| `/notion:query [question]` | Search Notion and query databases using natural language questions |
| `/notion:update [page] [changes]` | Update a page's properties or append content using natural language |
| `/notion:template [name]` | Deploy a pre-built Notion database template or list available templates |

## Skills

- **notion-operations**: Notion MCP tool usage, workspace discovery, page and database operations, search strategies, content block formatting
- **notion-database-design**: Natural language to schema translation, property type selection, schema design best practices, 5 pre-built business templates

## Agent Teams

This plugin does not use Agent Teams.

## Dependencies

This plugin has no dependencies on other Founder OS plugins. It enhances all Notion-based plugins by providing direct workspace manipulation capabilities.

## Blog Post

**Week 18**: "Control Your Entire Notion Workspace with Plain English"

## License

MIT
