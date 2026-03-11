# Founder OS #29: Learning Log Tracker

> Never forget what you learn — capture daily insights with auto-tagging, find connections across your knowledge, and track your learning streak.

| Field | Value |
|-------|-------|
| Pillar | Meta & Growth |
| Platform | Claude Code |
| Type | Standalone |
| Difficulty | Beginner |
| Week | 29 |

---

## What It Does

Learning Log Tracker captures your daily learnings, insights, and observations in a searchable Notion database. Instead of letting valuable knowledge slip away, every insight is auto-tagged by topic, linked to related past learnings, and synthesized into weekly summaries.

- **Captures** daily learnings with auto-generated titles and topic detection across 10 categories
- **Connects** new insights to related past learnings using topic overlap scoring
- **Searches** your knowledge base by topic, keyword, date range, or source type
- **Synthesizes** weekly themes, identifies cross-topic connections, and tracks your learning streak
- **Tracks** consistency with consecutive-week streak metrics and trend comparisons

---

## MCP Servers

| Server | Package | Required |
|--------|---------|----------|
| Notion | `@modelcontextprotocol/server-notion` | Yes |

---

## Commands

| Command | Description |
|---------|-------------|
| `/learn:log [insight]` | Capture a learning with auto-tagging and related insights |
| `/learn:search [topic-or-keyword]` | Search past learnings by topic, keyword, or date |
| `/learn:weekly` | Generate weekly synthesis with themes, connections, and streak |

---

## Skills

- **learning-capture** — Topic detection (10-category taxonomy), source classification, title generation, related insight matching, duplicate detection
- **learning-search** — Multi-filter pipeline (topic → date → keyword), composite relevance scoring, emoji-tagged display formatting
- **learning-synthesis** — Theme detection, cross-topic connection identification, streak calculation, trend comparison, weekly narrative generation

---

## Agent Teams

None. This plugin runs as a standalone command — no multi-agent pipeline required.

---

## Dependencies

None. Learning Log Tracker operates independently with Notion as the only required MCP server.

---

## Topic Taxonomy

| Topic | Focus Area | Emoji |
|-------|-----------|-------|
| Technical | Code, architecture, APIs, debugging | 📘 |
| Process | Workflows, methodologies, project management | ⚙️ |
| Business | Revenue, clients, pricing, growth | 💼 |
| People | Team dynamics, leadership, communication | 👥 |
| Tool | Software tools, platforms, integrations | 🔧 |
| Strategy | Long-term planning, positioning, vision | 🎯 |
| Mistake | Errors, failures, lessons from going wrong | ⚠️ |
| Win | Successes, achievements, things that worked | 🏆 |
| Idea | New concepts, possibilities, creative solutions | 💡 |
| Industry | Market trends, competitor moves, sector news | 🌐 |

---

## Blog Angle

**"Never Forget What You Learn: AI-Powered Learning Logs"**

Every founder has those "aha" moments — a debugging technique, a client insight, a process improvement. But without a system, these learnings vanish. This plugin captures your insights as they happen, automatically tags and connects them, and shows you patterns in your growth over time. The result: a compound knowledge asset that gets smarter every week.

---

## Output

All learnings are stored in two Notion databases:

### [FOS] Learnings (preferred) or Founder OS HQ - Learnings or Learning Log Tracker - Learnings (fallbacks)

| Property | Type | Description |
|----------|------|-------------|
| Title | Title | Auto-generated 5-8 word summary |
| Insight | Rich text | Full learning text |
| Topics | Multi-select | 1-3 auto-detected topic categories |
| Source Type | Select | Experience, Reading, Conversation, Experiment, or Observation |
| Context | Rich text | Optional additional context |
| Related IDs | Rich text | Page IDs of related past learnings |
| Related Titles | Rich text | Titles of related past learnings |
| Week | Rich text | ISO week identifier (YYYY-WNN) |
| Logged At | Date | Capture timestamp |

### [FOS] Weekly Insights (preferred) or Founder OS HQ - Weekly Insights or Learning Log Tracker - Weekly Insights (fallbacks)

| Property | Type | Description |
|----------|------|-------------|
| Week | Title | ISO week identifier (YYYY-WNN) |
| Summary | Rich text | 3-5 sentence narrative synthesis |
| Top Themes | Multi-select | 2-4 most frequent topics |
| Learning Count | Number | Total learnings for the week |
| Most Active Topic | Select | Highest-frequency topic |
| Key Connections | Rich text | Cross-topic pattern descriptions |
| Learnings List | Rich text | Bulleted index of all titles |
| Streak Days | Number | Consecutive weeks with learnings |
| Vs Last Week | Select | More active, Same pace, or Less active |
| Source Mix | Rich text | Source type breakdown |
| Generated At | Date | Synthesis timestamp |
