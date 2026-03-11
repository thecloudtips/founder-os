---
name: calendar-read
description: Read Google Calendar events and check availability using gws CLI. Use this skill when any Founder OS plugin needs to list events, check schedules, or query free/busy status — replaces Google Calendar MCP server read operations.
---

## Overview

Calendar read operations via gws CLI. Covers listing events, getting event details, and checking availability.

## Prerequisites

- gws CLI installed (see gws-common skill)
- Calendar scopes: `calendar.readonly` (minimum), `calendar.events` (for full access)

## Commands

### Today's Agenda (Quick View)

```bash
# Get today's events with smart formatting
gws calendar +agenda --today --format json
```

**Output**: JSON array of today's events with summary, start/end times, attendees, location.

This is the fastest way to get a daily schedule. Use for P02 Daily Briefing, P03 Meeting Prep, P22 Morning Sync.

### List Events (Date Range)

```bash
# Events in a date range
gws calendar events list --params '{
  "calendarId": "primary",
  "timeMin": "2026-03-09T00:00:00Z",
  "timeMax": "2026-03-10T00:00:00Z",
  "singleEvents": true,
  "orderBy": "startTime"
}' --format json
```

**Key parameters**:
- `calendarId`: `"primary"` for default calendar, or specific calendar ID
- `timeMin`/`timeMax`: ISO 8601 datetime (must include timezone or Z)
- `singleEvents`: `true` to expand recurring events into individual instances
- `orderBy`: `"startTime"` (requires `singleEvents: true`) or `"updated"`
- `maxResults`: limit number of events returned

**Output**: JSON with `items[]` array containing event objects.

### Get Single Event

```bash
gws calendar events get --params '{"calendarId":"primary","eventId":"EVENT_ID"}' --format json
```

### Free/Busy Query

```bash
gws calendar freebusy query --json '{
  "timeMin": "2026-03-09T08:00:00Z",
  "timeMax": "2026-03-09T18:00:00Z",
  "items": [{"id": "primary"}]
}' --format json
```

**Output**: JSON with busy time ranges for each calendar.

### List Calendars

```bash
gws calendar calendarList list --format json
```

## Common Patterns

### Get This Week's Events

```bash
gws calendar events list --params '{
  "calendarId": "primary",
  "timeMin": "2026-03-09T00:00:00Z",
  "timeMax": "2026-03-15T23:59:59Z",
  "singleEvents": true,
  "orderBy": "startTime",
  "maxResults": 50
}' --format json
```

### Find Meetings with Specific Attendee

```bash
# List events and filter by attendee using jq
gws calendar events list --params '{
  "calendarId": "primary",
  "timeMin": "2026-03-01T00:00:00Z",
  "timeMax": "2026-03-31T23:59:59Z",
  "singleEvents": true,
  "orderBy": "startTime"
}' --format json | jq '[.items[] | select(.attendees[]?.email == "person@example.com")]'
```

## Error Handling

If Calendar is unavailable, return:
```json
{"source": "calendar", "status": "unavailable", "reason": "gws CLI not found or auth expired"}
```

Continue with other data sources.
