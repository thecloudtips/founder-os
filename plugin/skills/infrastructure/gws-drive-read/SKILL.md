---
name: drive-read
description: Search, list, and retrieve Google Drive files using gws CLI. Use this skill when any Founder OS plugin needs to find, read, or export Drive files — replaces Google Drive MCP server read operations.
---

## Overview

Drive read operations via gws CLI. Covers searching, listing, retrieving metadata, and exporting file content.

## Prerequisites

- gws CLI installed (see gws-common skill)
- Drive scopes: `drive.readonly` (minimum), `drive` (for full access)

## Commands

### Search Files

```bash
# Search by name
gws drive files list --params '{
  "q": "name contains '\''report'\''",
  "pageSize": 20,
  "fields": "files(id,name,mimeType,modifiedTime,webViewLink)"
}' --format json
```

**Query syntax** (Drive search operators):
- `name contains 'term'` — filename contains word
- `mimeType = 'application/vnd.google-apps.document'` — Google Docs only
- `mimeType = 'application/vnd.google-apps.spreadsheet'` — Sheets only
- `mimeType = 'application/pdf'` — PDFs only
- `'FOLDER_ID' in parents` — files in specific folder
- `modifiedTime > '2026-03-01T00:00:00'` — modified after date
- `trashed = false` — exclude trashed files
- Combine with `and` / `or`

**Common MIME types**:
- `application/vnd.google-apps.document` — Google Doc
- `application/vnd.google-apps.spreadsheet` — Google Sheet
- `application/vnd.google-apps.presentation` — Google Slides
- `application/vnd.google-apps.folder` — Folder
- `application/pdf` — PDF

### Get File Metadata

```bash
gws drive files get --params '{
  "fileId": "FILE_ID",
  "fields": "id,name,mimeType,modifiedTime,size,webViewLink,parents"
}' --format json
```

### Export Google Doc as Plain Text

```bash
gws drive files export --params '{"fileId":"FILE_ID","mimeType":"text/plain"}' --output /tmp/doc.txt
```

**Export MIME types**:
- `text/plain` — plain text
- `application/pdf` — PDF
- `text/csv` — CSV (for Sheets)
- `application/vnd.openxmlformats-officedocument.wordprocessingml.document` — DOCX
- `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` — XLSX

### Download Binary File

```bash
gws drive files get --params '{"fileId":"FILE_ID","alt":"media"}' --output /tmp/downloaded-file.pdf
```

### List Files in Folder

```bash
gws drive files list --params '{
  "q": "'\''FOLDER_ID'\'' in parents and trashed = false",
  "pageSize": 50,
  "fields": "files(id,name,mimeType,modifiedTime)"
}' --format json
```

## Common Patterns

### Search Recent Documents

```bash
gws drive files list --params '{
  "q": "mimeType = '\''application/vnd.google-apps.document'\'' and modifiedTime > '\''2026-03-01T00:00:00'\'' and trashed = false",
  "pageSize": 10,
  "orderBy": "modifiedTime desc",
  "fields": "files(id,name,modifiedTime,webViewLink)"
}' --format json
```

### Get File Content for Analysis

```bash
# Step 1: Export to temp file
gws drive files export --params '{"fileId":"FILE_ID","mimeType":"text/plain"}' --output /tmp/doc-content.txt

# Step 2: Read content
cat /tmp/doc-content.txt
```

## Error Handling

If Drive is unavailable, return:
```json
{"source": "drive", "status": "unavailable", "reason": "gws CLI not found or auth expired"}
```
