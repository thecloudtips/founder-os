# founder-os-meeting-prep-autopilot

> **Plugin #03** -- Parallel-gathering plugin that takes a calendar event and generates a deep meeting prep doc with attendee context from CRM and email, open items from past meetings, and framework-based talking points -- saving results to Notion

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | Daily Work |
| **Platform** | Claude Code |
| **Type** | Standalone (with `--team` parallel-gathering mode) |
| **Difficulty** | Intermediate |
| **Week** | 7 |

## What It Does

Meeting Prep Autopilot ensures you never walk into a meeting unprepared. Given a calendar event, it dispatches agents to pull attendee context from your CRM and email history, surface open items from previous meetings, find relevant documents in Drive, and assemble framework-based talking points tailored to the meeting type. The result is a structured prep doc in Notion that gives you full context in under a minute -- no scrambling through inboxes, no forgotten follow-ups, no awkward "what did we discuss last time?" moments.

The plugin classifies each meeting into one of six types (external-client, one-on-one, internal-sync, ad-hoc, recurring, group-meeting) using weighted importance scoring on a 1-5 scale, then selects the appropriate talking points framework automatically. Client meetings get SPIN-based questions designed to uncover needs and build value. One-on-ones use the GROW framework for coaching-oriented conversations. Internal syncs follow SBI for clear, actionable feedback. Ad-hoc meetings use Context-Gathering to quickly establish shared understanding. Recurring meetings apply Delta-Based points focused on what changed since last time. Group meetings use Contribution Mapping to ensure all voices are heard.

In **default mode**, a single agent performs a fast context sweep and generates a lightweight prep doc covering attendees, open items, and key talking points. In **team mode** (`--team`), the full 5-agent parallel pipeline activates: four dedicated gatherer agents fetch data from Calendar, Gmail, Notion, and Drive simultaneously, then the Prep Lead synthesizes everything into a richly formatted Notion page with attendee dossiers, an open items tracker, prioritized talking points, and relevant document links.

The `/meeting:prep-today` command batches all of today's meetings, generating prep docs in sequence so you start the day fully briefed. Re-running prep for a meeting that already has a doc updates it in place rather than creating a duplicate. If any MCP source is temporarily unavailable, the prep doc still generates with the data it has, clearly marking which sections are incomplete.

## Requirements

### MCP Servers

- **Google Calendar** (required) -- Meeting details, attendee lists, schedule and recurrence info
- **Gmail** (required) -- Attendee email history, unanswered threads, recent communications
- **Notion** (required) -- CRM contacts, past meeting notes, action items, prep output storage
- **Google Drive** (optional) -- Relevant documents for meeting topics

### Platform

- **Claude Code**

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/meeting:prep [event_id]` | Generate deep prep doc for a specific meeting (default: single-agent, `--team` for full pipeline) |
| `/meeting:prep-today` | Prep all of today's meetings in sequence |

## Skills

- **meeting-context**: Deep single-meeting context gathering -- event identity and classification, attendee lookup across CRM and email, meeting type detection, Drive document search, and open items extraction from past meeting notes
- **talking-points**: Framework-based talking points generation -- SPIN for external-client meetings, GROW for one-on-ones, SBI for internal syncs, Context-Gathering for ad-hoc meetings, Delta-Based for recurring meetings, and Contribution Mapping for group meetings

## Agent Teams

This plugin uses a **parallel-gathering** Agent Team pattern with 5 agents:
- **calendar-agent** -- Fetches event details, classifies meeting type, and calculates importance scoring
- **gmail-agent** -- Scans attendee email history and surfaces unanswered threads
- **notion-agent** -- Pulls CRM contact data, past meeting notes, and outstanding action items
- **drive-agent** (optional) -- Searches for relevant documents tied to meeting topics
- **prep-lead** -- Synthesizes all gathered data into a final prep doc with framework-based talking points

See `teams/` for agent definitions and configuration.

## Notion Database

Writes to the shared **"[FOS] Meetings"** database (falls back to "Founder OS HQ - Meetings", then legacy "Meeting Prep Autopilot - Prep Notes"). Shares the Event ID as an idempotent key with P07 Meeting Intelligence Hub -- when one plugin creates a record, the other updates it rather than creating a duplicate.

**P03-owned fields**: Prep Notes, Talking Points, Importance Score, Sources Used, Company (relation)

## Dependencies

- **#07 Meeting Intelligence Hub**: Shares "[FOS] Meetings" database via Event ID idempotent key
- **#21 CRM Sync Hub**: Requires -- provides Notion CRM data (contacts, companies) used for attendee context
- **#20 Client Context Loader**: Enhances -- provides deeper meeting-specific context for client meetings

## Blog Post

**Week 7**: "Never Walk Into a Meeting Unprepared Again"

## License

MIT
