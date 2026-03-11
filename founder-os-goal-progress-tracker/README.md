# Goal Progress Tracker

Plugin #30 in the Founder OS ecosystem. Manage goals with milestones, auto-calculated progress, RAG health scoring, velocity projections, blocker detection, and Mermaid Gantt timeline visualization. Backed by Notion for persistent storage.

**Platform:** Claude Code | **Pillar:** Meta & Growth | **Difficulty:** Intermediate | **Week:** 30

## What It Does

- Create goals with optional milestones and deadlines
- Auto-calculate progress from milestone completion (with partial credit for in-progress work)
- Classify goals as Green/Yellow/Red using time-based expected vs actual progress
- Project completion dates from multi-window velocity averaging
- Detect blockers automatically (overdue milestones, stale progress, deadline overruns, velocity collapse)
- Generate dashboard reports with ASCII progress bars, RAG indicators, and Mermaid Gantt charts

## MCP Requirements

| Server | Package | Required |
|--------|---------|----------|
| Notion | @modelcontextprotocol/server-notion | Yes |

## Commands

| Command | Description | Writes to Notion |
|---------|-------------|:---:|
| /goal:create [name] | Create a goal with optional milestones and deadline | Yes |
| /goal:update [name] | Update progress, complete milestones, change status | Yes |
| /goal:report | Generate full dashboard with table, RAG breakdown, and Gantt | Yes |
| /goal:check [name] | Quick read-only status check (ephemeral) | No |
| /goal:close [name] | Close or archive a goal | Yes |

## Skills

| Skill | Purpose |
|-------|---------|
| goal-tracking | Goal/milestone CRUD, progress formula, lifecycle management |
| progress-analysis | RAG scoring, velocity projection, blocker detection |
| goal-reporting | Dashboard tables, Gantt charts, report formatting |

## Notion Databases

### [FOS] Goals (preferred) or Founder OS HQ - Goals or Goal Progress Tracker - Goals (fallbacks) — 14 properties
Title, Description, Status, Progress, Target Date, Start Date, Category, RAG Status, Projected Completion, Milestone Count, Completed Milestones, Progress Snapshots, Notes, Created At

### [FOS] Milestones (preferred) or Founder OS HQ - Milestones or Goal Progress Tracker - Milestones (fallbacks) — 8 properties
Title, Goal (relation), Status, Due Date, Completed At, Order, Notes, Created At

## Key Features

- **RAG Health Scoring**: Green (on track, gap >= -10), Yellow (at risk, -25 to -10), Red (behind, < -25 or past deadline)
- **Velocity Projection**: Multi-window averaging (7d/14d/30d) with recency bias for accurate completion forecasts
- **Milestone Progress**: Auto-calculated with 0.5 partial credit for in-progress milestones
- **Blocker Detection**: 4 types (milestone_blocked, stale_progress, deadline_overrun, velocity_collapse)
- **Gantt Timeline**: Mermaid charts grouped by category with RAG color coding
- **Ephemeral Check**: /goal:check is fully read-only for quick status without side effects

## Blog Angle

Week 30: "OKRs That Track Themselves: AI-Powered Goal Management"
