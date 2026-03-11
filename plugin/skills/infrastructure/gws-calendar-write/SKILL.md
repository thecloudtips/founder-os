---
name: calendar-write
description: Create, update, and delete Google Calendar events using gws CLI. Use this skill when any Founder OS plugin needs to modify calendar events — replaces Google Calendar MCP server write operations.
---

## Overview

Calendar write operations via gws CLI. Covers creating, updating, and deleting events.

## Prerequisites

- gws CLI installed (see gws-common skill)
- Calendar scopes: `calendar.events` (required for write operations)

## Commands

### Create Event (Quick)

```bash
# Quick event creation
gws calendar +insert --summary 'Meeting Title' --start '2026-03-10T14:00:00' --end '2026-03-10T15:00:00'
```

The `+insert` helper handles common event creation with minimal parameters.

### Create Event (Full Control)

```bash
gws calendar events insert --params '{"calendarId":"primary"}' --json '{
  "summary": "Team Standup",
  "description": "Weekly sync",
  "location": "Conference Room A",
  "start": {"dateTime": "2026-03-10T09:00:00-07:00", "timeZone": "America/Los_Angeles"},
  "end": {"dateTime": "2026-03-10T09:30:00-07:00", "timeZone": "America/Los_Angeles"},
  "attendees": [
    {"email": "team@example.com"}
  ],
  "reminders": {
    "useDefault": false,
    "overrides": [{"method": "popup", "minutes": 10}]
  }
}'
```

### Update Event

```bash
# Partial update (only changed fields)
gws calendar events patch --params '{"calendarId":"primary","eventId":"EVENT_ID"}' --json '{
  "summary": "Updated Meeting Title",
  "start": {"dateTime": "2026-03-10T15:00:00-07:00"}
}'
```

### Delete Event

```bash
gws calendar events delete --params '{"calendarId":"primary","eventId":"EVENT_ID"}'
```

### Move Event to Another Calendar

```bash
gws calendar events move --params '{"calendarId":"primary","eventId":"EVENT_ID","destination":"other-calendar-id"}'
```

## FOS Conventions

- When creating follow-up events, include reference to the source plugin in the description
- Log created event IDs for audit trail
- Prefer `patch` over full `update` to minimize data sent
- Always include timezone in datetime values
