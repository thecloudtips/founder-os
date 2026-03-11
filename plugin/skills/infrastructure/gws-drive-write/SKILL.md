---
name: drive-write
description: Upload, create, and update Google Drive files using gws CLI. Use this skill when any Founder OS plugin needs to write files to Drive — replaces Google Drive MCP server write operations.
---

## Overview

Drive write operations via gws CLI. Covers uploading, creating, and updating files.

## Prerequisites

- gws CLI installed (see gws-common skill)
- Drive scopes: `drive` (required for write operations)

## Commands

### Upload File (Quick)

```bash
# Upload a file to Drive
gws drive +upload ./report.pdf --parent FOLDER_ID
```

The `+upload` helper handles multipart upload with automatic MIME type detection.

### Upload with Metadata

```bash
gws drive files create --params '{}' --json '{
  "name": "Q1 Report.pdf",
  "parents": ["FOLDER_ID"],
  "mimeType": "application/pdf"
}' --upload ./report.pdf --format json
```

### Create Google Doc

```bash
gws drive files create --params '{}' --json '{
  "name": "Meeting Notes",
  "mimeType": "application/vnd.google-apps.document",
  "parents": ["FOLDER_ID"]
}' --format json
```

### Update File Content

```bash
gws drive files update --params '{"fileId":"FILE_ID"}' --upload ./updated-report.pdf --format json
```

### Update File Metadata

```bash
gws drive files update --params '{"fileId":"FILE_ID"}' --json '{
  "name": "Renamed Document"
}' --format json
```

### Create Folder

```bash
gws drive files create --params '{}' --json '{
  "name": "New Folder",
  "mimeType": "application/vnd.google-apps.folder",
  "parents": ["PARENT_FOLDER_ID"]
}' --format json
```

## FOS Conventions

- Always specify `parents` to organize files into the correct Drive folder
- Log uploaded file IDs and webViewLinks in plugin output
- Use descriptive filenames that include date or client reference
- Prefer updating existing files over creating duplicates (idempotent re-runs)
