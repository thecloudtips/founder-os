# Founder OS #26: Team Prompt Library

> Build and share a reusable AI prompt library across your team — with variable substitution, usage tracking, and quality scoring.

| Field | Value |
|-------|-------|
| Pillar | Meta & Growth |
| Platform | Claude Code |
| Type | Standalone |
| Difficulty | Beginner |
| Week | 26 |

---

## What It Does

Team Prompt Library gives your team a central, searchable repository of high-quality AI prompts. Instead of everyone reinventing the same prompts, your team stores, retrieves, and refines prompts in Notion — with variable substitution so any prompt can be instantly personalized.

- **Stores** reusable prompts with metadata (category, tags, author, use case)
- **Retrieves** prompts by name or category with `{{variable}}` substitution filled in at retrieval time
- **Shares** prompts to teammates via Notion with a formatted shareable block
- **Tracks** usage across the team so popular prompts surface first
- **Optimizes** prompts using quality scoring and improvement suggestions

---

## MCP Servers

| Server | Package | Required |
|--------|---------|----------|
| Notion | `@modelcontextprotocol/server-notion` | Yes |

---

## Commands

| Command | Description |
|---------|-------------|
| `/prompt:list [category]` | Browse all prompts or filter by category |
| `/prompt:get [name]` | Retrieve a prompt by name with variable substitution |
| `/prompt:add [name]` | Add a new prompt to the library |
| `/prompt:share [name]` | Share a prompt with your team via Notion |
| `/prompt:optimize [name]` | Analyze and improve a prompt using quality scoring |

---

## Skills

- **prompt-management** — Prompt storage, retrieval, categorization, variable substitution, and usage tracking
- **prompt-optimization** — Quality scoring rubric, improvement suggestions, A/B variant generation, anti-pattern detection

---

## Agent Teams

None. This plugin runs as a standalone command — no multi-agent pipeline required.

---

## Dependencies

None. Team Prompt Library operates independently.

---

## Blog Angle

**"Build Your Team's AI Prompt Library: Shared Knowledge, Better Results"**

Every founder rewrites the same prompts from scratch — onboarding emails, proposal drafts, weekly updates. This plugin shows you how to capture your best prompts once, share them across your team, and keep improving them with quality scoring. The result: fewer wasted minutes, more consistent AI output, and a compound knowledge asset that grows with your business.

---

## Output

All prompts are stored in a Notion database: **[FOS] Prompts** (preferred) or **Founder OS HQ - Prompts** or **Team Prompt Library - Prompts** (fallbacks).

| Property | Type | Description |
|----------|------|-------------|
| Prompt Name | Title | Unique identifier |
| Category | Select | e.g., Email, Proposals, Meetings |
| Tags | Multi-select | Searchable keywords |
| Prompt Text | Rich text | The full prompt with `{{variable}}` placeholders |
| Variables | Rich text | Comma-separated variable names |
| Author | Rich text | Who created it |
| Use Case | Rich text | When and how to use it |
| Usage Count | Number | Times retrieved by the team |
| Quality Score | Number | 0-100 score from `/prompt:optimize` |
| Last Used | Date | Most recent retrieval timestamp |
| Added At | Date | Creation timestamp |
