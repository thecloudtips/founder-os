---
name: gmail-read
description: Read Gmail messages and threads using gws CLI. Use this skill when any Founder OS plugin needs to search, list, or retrieve email messages — replaces Gmail MCP server read operations.
---

## Overview

Gmail read operations via gws CLI. Covers searching, listing, and retrieving messages and threads.

## Prerequisites

- gws CLI installed (see gws-common skill)
- Gmail scopes: `gmail.readonly` (minimum), `gmail.insert` for triage

## Commands

### Triage (Quick Unread Summary)

```bash
# Get unread messages with smart categorization
gws gmail +triage --max 50 --format json
```

**Output**: JSON array of messages with id, subject, from, date, snippet, labels.

This is the fastest way to get an inbox overview. Use for P01 Inbox Zero, P02 Daily Briefing, P22 Morning Sync.

### Search Messages (Custom Query)

```bash
# Custom Gmail search query
gws gmail users messages list --params '{"userId":"me","q":"QUERY","maxResults":N}' --format json
```

**Query syntax** (same as Gmail search box):
- `is:unread` — unread messages
- `from:user@example.com` — from specific sender
- `after:2026/03/01 before:2026/03/09` — date range
- `subject:invoice` — subject contains word
- `has:attachment` — has attachments
- `label:important` — specific label
- Combine with spaces (AND) or `OR`

**Output**: JSON with `messages` array containing `{id, threadId}` pairs. You need a separate `get` call for full message content.

### Get Full Message

```bash
# Get complete message with headers and body
gws gmail users messages get --params '{"userId":"me","id":"MSG_ID","format":"full"}' --format json
```

**Output**: Full message object with:
- `payload.headers[]` — Subject, From, To, Date, etc.
- `payload.body.data` — Base64-encoded body (for simple messages)
- `payload.parts[]` — MIME parts (for multipart messages)
- `labelIds[]` — Applied labels
- `snippet` — Plain text preview

### Get Thread

```bash
# Get full thread (all messages in conversation)
gws gmail users threads get --params '{"userId":"me","id":"THREAD_ID","format":"full"}' --format json
```

### List Labels

```bash
gws gmail users labels list --params '{"userId":"me"}' --format json
```

## Common Patterns

### Fetch Recent Emails with Full Content

```bash
# Step 1: Get message IDs
ids=$(gws gmail users messages list --params '{"userId":"me","q":"is:unread","maxResults":20}' --format json | jq -r '.messages[].id')

# Step 2: Get each message
for id in $ids; do
  gws gmail users messages get --params "{\"userId\":\"me\",\"id\":\"$id\",\"format\":\"full\"}" --format json
done
```

### Search by Sender and Date

```bash
gws gmail users messages list --params '{"userId":"me","q":"from:client@example.com after:2026/03/01","maxResults":10}' --format json
```

## Error Handling

If Gmail is unavailable, return:
```json
{"source": "gmail", "status": "unavailable", "reason": "gws CLI not found or auth expired"}
```

Continue with other data sources. Never hard-fail a plugin because Gmail is unreachable.
