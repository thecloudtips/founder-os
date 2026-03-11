---
name: gmail-write
description: Send emails, create drafts, trash messages, and modify labels using gws CLI. Use this skill when any Founder OS plugin needs to write or modify Gmail data — replaces Gmail MCP server write operations.
---

## Overview

Gmail write operations via gws CLI. Covers sending, drafting, trashing, and label management.

## Prerequisites

- gws CLI installed (see gws-common skill)
- Gmail scopes: `gmail.send` (for sending), `gmail.modify` (for label/trash), `gmail.insert` (for drafts)

## Commands

### Send Email

```bash
# Quick send
gws gmail +send --to recipient@example.com --subject 'Subject Line' --body 'Email body text'

# Send with CC
gws gmail +send --to recipient@example.com --cc other@example.com --subject 'Subject' --body 'Body'
```

The `+send` helper handles MIME encoding automatically.

### Create Draft

```bash
# Create a draft (requires base64-encoded MIME message)
gws gmail users drafts create --params '{"userId":"me"}' --json '{"message":{"raw":"BASE64_ENCODED_MIME"}}'
```

To create the base64 MIME message:
```bash
# Build MIME message and base64 encode it
raw=$(printf "To: recipient@example.com\r\nSubject: Draft Subject\r\nContent-Type: text/plain\r\n\r\nDraft body text" | base64 -w 0)
gws gmail users drafts create --params '{"userId":"me"}' --json "{\"message\":{\"raw\":\"$raw\"}}"
```

### Trash Message

```bash
gws gmail users messages trash --params '{"userId":"me","id":"MSG_ID"}'
```

### Modify Labels

```bash
# Add and/or remove labels
gws gmail users messages modify --params '{"userId":"me","id":"MSG_ID"}' --json '{"addLabelIds":["STARRED"],"removeLabelIds":["UNREAD"]}'
```

Common label IDs: `INBOX`, `UNREAD`, `STARRED`, `IMPORTANT`, `TRASH`, `SPAM`, `DRAFT`

### Mark as Read

```bash
gws gmail users messages modify --params '{"userId":"me","id":"MSG_ID"}' --json '{"removeLabelIds":["UNREAD"]}'
```

### Archive (Remove from Inbox)

```bash
gws gmail users messages modify --params '{"userId":"me","id":"MSG_ID"}' --json '{"removeLabelIds":["INBOX"]}'
```

## FOS Conventions

- Always confirm send operations in plugin output (log message ID)
- Draft creation is preferred over direct send for review workflows
- When trashing, log the message subject for audit trail
- Batch label modifications where possible to reduce API calls
