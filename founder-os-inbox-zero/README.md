# founder-os-inbox-zero

> **Plugin #01** -- AI-powered email triage that categorizes, prioritizes, extracts actions, drafts responses, and archives — achieving Inbox Zero with a 4-agent pipeline.

Part of the [Founder OS](https://github.com/founderOS) plugin ecosystem.

| Detail | Value |
|--------|-------|
| **Pillar** | Daily Work |
| **Platform** | Claude Code |
| **Type** | Standalone |
| **Difficulty** | Beginner |
| **Week** | 1 |

## What It Does

Inbox Zero Commander processes your Gmail inbox using AI to categorize emails, score priorities, extract action items, draft responses, and recommend archiving. It operates in two modes:

- **Default mode**: Quick single-agent triage that categorizes and prioritizes your emails, presenting a summary with counts, top urgent items, and archive candidates.
- **Team mode** (`--team`): Full 4-agent pipeline that runs Triage, Action Extraction, Response Drafting, and Archive Recommendation sequentially — extracting tasks to the HQ Tasks database (Type="Email Task"), drafting replies to the HQ Content database (Type="Email Draft"), and recommending cleanup.

## Requirements

### MCP Servers

| Tool | Required | Purpose |
|------|----------|---------|
| **gws CLI** | Yes | Gmail access for triage, labeling, and draft creation (via `gws gmail` commands) |
| **Notion** | Optional | Task extraction and draft review workflow. Uses consolidated "[FOS] Tasks" and "[FOS] Content" databases (falls back to "Founder OS HQ - " prefixed names, then legacy per-plugin DBs). |

### Platform

- **Claude Code** with `gws` CLI installed and authenticated

## Quick Start

See [QUICKSTART.md](QUICKSTART.md) for usage examples.

## Installation

See [INSTALL.md](INSTALL.md) for full setup instructions.

## Commands

| Command | Description |
|---------|-------------|
| `/inbox:triage` | Triage your inbox with AI categorization and prioritization |
| `/inbox:triage --team` | Run the full 4-agent pipeline (triage, actions, drafts, archive) |
| `/inbox:drafts_approved` | Create Gmail drafts from approved Notion entries |

## Skills

- **email-triage**: 5-category email classification system (action_required, waiting_on, fyi, newsletter, promotions) with VIP handling and archivable/needs_response flags.
- **priority-scoring**: Eisenhower matrix scoring rubric (1-5) with VIP boost, keyword detection, and consistency rules.
- **action-extraction**: Verb detection patterns, owner inference, deadline parsing, and duplicate detection for extracting structured action items.
- **response-drafting**: Email response structure (greeting, acknowledgment, core response, closing), length matching, confidence scoring, and commitment boundaries.
- **tone-matching**: Formality detection across 4 levels (Formal, Professional, Casual, Internal) with mirroring patterns and cultural sensitivity.

## Agent Teams

This plugin uses a **Pipeline** Agent Team pattern with 4 agents:

| Step | Agent | Role |
|------|-------|------|
| 1 | **Triage Agent** | Categorizes and prioritizes emails using Eisenhower matrix |
| 2 | **Action Agent** | Extracts action items and creates Notion tasks |
| 3 | **Response Agent** | Drafts replies and saves to Notion for review |
| 4 | **Archive Agent** | Recommends archiving (recommend-only, no auto-archive) |

See `teams/` for agent definitions and configuration.

## Dependencies

This plugin has no dependencies on other Founder OS plugins. It enhances **#06 Follow-Up Tracker** when both are installed.

## Blog Post

**Week 1**: "Inbox Zero in 10 Minutes: How I Built an AI Email Assistant"

A founder's journey from 200+ daily emails to a clean inbox using a 4-agent AI pipeline, with real before/after metrics and the decision framework behind categorization.

## License

MIT
