---
description: Quick morning check-in showing top priorities, today's schedule, and urgent counts across all sources
argument-hint: "[--since=12h]"
allowed-tools: ["Read"]
---

# Morning Quick

Lightweight morning check-in across all configured sources. Produce a concise chat-only summary — no Notion page creation, no detailed section assembly. Optimized for speed over completeness.

## Load Skills

Read the morning-briefing skill at `${CLAUDE_PLUGIN_ROOT}/skills/morning/morning-briefing/SKILL.md` for multi-source gathering patterns and overnight window calculation.

Read the priority-synthesis skill at `${CLAUDE_PLUGIN_ROOT}/skills/morning/priority-synthesis/SKILL.md` for cross-source priority scoring and the Quick Summary Format.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `--since=TIMEFRAME` (optional) — overnight window. Accepts `Nh` (hours) or ISO datetime. Default: `12h`.

No `--date`, `--output`, or other flags. This command is always today, always chat-only.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Gather Phase (Lightweight)

Follow the morning-briefing skill's five-source gathering pipeline but with reduced depth:
1. Gmail: Fetch unread count and Q1 highlights only (skip Q2-Q4 classification detail)
2. Calendar: Fetch today's events, classify types and score importance
3. Notion: Count tasks due today + overdue count
4. Slack (if available): Count @mentions and P1 messages only
5. Drive (if available): Count recently modified docs only

Skip detailed extraction for each source — collect counts and top items only.

Track source availability (available/unavailable). Apply graceful degradation per morning-briefing skill rules.

## Synthesize Phase (Quick)

Apply the priority-synthesis skill's cross-source scoring to produce a Top 5 priority list. Use the Quick Summary Format defined in the skill.

Skip section assembly, urgency windowing detail, and Notion page formatting.

## Output Format

Present results in chat using this compact format:

```
## Morning Quick — [YYYY-MM-DD]

### Top 5 Priorities
1. [imperative action] — [source icon] [time sensitivity]
2. [imperative action] — [source icon] [time sensitivity]
3. [imperative action] — [source icon] [time sensitivity]
4. [imperative action] — [source icon] [time sensitivity]
5. [imperative action] — [source icon] [time sensitivity]

### Today at a Glance
- [N] meetings ([N] high-priority) | Next: [title] at [time]
- [N] emails need attention | [N] total unread
- [N] tasks due today | [N] overdue
[if Slack available] - [N] Slack @mentions | [N] highlights
[if Drive available] - [N] Drive updates

**Sources**: [list] | **Window**: Last [N]h
```

### Zero-Item Handling
- Zero priorities: "All clear — no urgent items this morning."
- Single source: Still produce output with available data
- All sources unavailable: Report which MCP servers to configure

### No Notion Storage

Do NOT search for, create, or update any Notion database. This command is ephemeral by design — like P19's /founder-os:slack:catch-up.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.
