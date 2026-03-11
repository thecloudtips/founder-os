# founder-os-follow-up-tracker

> **Plugin #06** -- Scans Gmail sent folder for emails awaiting response, detects bidirectional promises, drafts follow-up nudge emails, and creates calendar reminders for pending follow-ups.

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | Daily Work |
| **Platform** | Claude Code |
| **Type** | Chained |
| **Difficulty** | Intermediate |
| **Week** | 10 |

## What It Does

Tracks emails that need follow-up attention. Scans your Gmail sent folder to find emails where you sent the last message and haven't received a reply, detects promises made in both directions (commitments you made to others and commitments others made to you), scores urgency based on age and relationship importance, drafts professionally escalating nudge emails, and creates calendar reminders for pending follow-ups.

## Requirements

### MCP Servers

- **Gmail** (required) -- Scans sent folder, reads threads, creates draft emails
- **Notion** (optional) -- Tracks follow-ups in the shared "[FOS] Tasks" database (falls back to "Founder OS HQ - Tasks", then legacy "Follow-Up Tracker - Follow-Ups")
- **Google Calendar** (optional) -- Creates reminder events for pending follow-ups

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/followup:check` | Scan sent folder for emails awaiting response and track follow-ups |
| `/followup:nudge` | Draft a follow-up nudge email and create a Gmail draft |
| `/followup:remind` | Create Google Calendar reminders for pending follow-ups |

## Skills

- **Follow-Up Detection**: Sent-email scanning, thread reply detection, bidirectional promise pattern matching, age-based priority tiers, exclusion rules, and priority scoring.
- **Nudge Writing**: Escalation-level drafting (gentle/firm/urgent), tone matching by relationship type (client/colleague/vendor), subject line handling, context referencing, and anti-pattern avoidance.

## Agent Teams

This plugin does not use Agent Teams.

## Dependencies

- **#01 Inbox Zero Commander**: Chained plugin. Follow-Up Tracker can leverage Inbox Zero's VIP list and `waiting_on` data for enriched priority scoring. Operates independently when Inbox Zero is not available.

## License

MIT
