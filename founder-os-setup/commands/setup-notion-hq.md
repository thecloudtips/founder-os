# /setup:notion-hq

Create all Founder OS HQ Notion databases programmatically.

## What It Does

Sets up the complete Notion HQ workspace with 22 interconnected databases, organized into 5 sections (CRM, Operations, Intelligence, Content & Deliverables, Growth & Meta). Uses the `notion-hq-setup` skill for database creation logic.

## Usage

```
/setup:notion-hq
```

No arguments needed. The command reads configuration from `.env` (NOTION_API_KEY) and database schemas from `_infrastructure/notion-db-templates/`.

## Instructions

1. Load the `notion-hq-setup` skill from this plugin for database creation logic and schema reference.

2. Read the manifest file at `_infrastructure/notion-db-templates/founder-os-hq-manifest.json` to get the complete list of databases and their creation order.

3. For each database in the manifest's `creation_order` array:
   a. Search Notion for an existing database named `[FOS] <display_name>` using the Notion MCP search tool.
   b. If found, report "Already exists" and skip to the next database.
   c. If not found, read the template JSON from `_infrastructure/notion-db-templates/<template_filename>.json`.
   d. Create a Notion database using `notion-create-database` with the properties from the template.
   e. Name it `[FOS] <display_name>` (e.g., `[FOS] Companies`, `[FOS] Tasks`).

4. After all databases are created, wire up relations:
   - Read the `relations` section from the manifest.
   - For each relation, use `notion-update-data-source` to add relation properties connecting databases (e.g., Tasks → Companies, Finance → Companies).

5. Create a "Founder OS HQ" top-level page as a dashboard using `notion-create-pages`.

6. Print a summary showing each database with its status (Created / Already Exists / Failed).

## Important Notes

- **Idempotent**: Safe to run multiple times. Skips existing databases.
- **Partial recovery**: If interrupted, re-running creates only missing databases.
- **Prerequisite**: `NOTION_API_KEY` must be set in `.env` and the Notion integration must have full capabilities (Read, Update, Insert content).
- **Rate limits**: Notion API allows ~3 requests/second. The command naturally paces itself but may take 2-3 minutes for a full setup.
