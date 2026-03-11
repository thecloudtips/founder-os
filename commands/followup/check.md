---
description: Scan Gmail sent folder for emails awaiting response and track follow-ups
argument-hint: "[--days=N] [--priority=high|all] [--limit=N] [--schedule=EXPR] [--persistent]"
allowed-tools: ["Read"]
---

# Check Follow-Ups

Scan the user's Gmail sent folder to identify emails awaiting a response, detect bidirectional promises, score urgency, and optionally track results in Notion.

## Load Skill

Read the follow-up-detection skill at `${CLAUDE_PLUGIN_ROOT}/skills/followup/follow-up-detection/SKILL.md` for sent-email scanning logic, thread reply detection, promise pattern matching, age-based priority tiers, exclusion rules, and priority scoring.

## Parse Arguments

Extract flags from `$ARGUMENTS`:
- `--days=N` (optional) — number of days to look back in the sent folder. Default: 30.
- `--priority=high|all` (optional) — filter results. `high` shows only priority 3-5. `all` shows everything including priority 1-2. Default: `all`.
- `--limit=N` (optional) — maximum number of follow-ups to display. Default: 20.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Scheduling Support

If `$ARGUMENTS` contains `--schedule`:
1. Extract the schedule value and any `--persistent` flag
2. Read `_infrastructure/scheduling/SKILL.md` for scheduling bridge logic
3. Read `_infrastructure/scheduling/references/schedule-flag-spec.md` for argument parsing
4. Default suggestion if no expression given: `"0 10 * * 1-5"` (Weekdays 10:00am)
5. Handle the schedule operation (create/disable/status) per the spec
6. Exit after scheduling — do NOT continue to main command logic

## Scanning Process

1. **Scan sent folder**: Search Gmail for messages sent by the user within the lookback window (default 30 days). Retrieve full threads for each sent message.

2. **Identify awaiting-reply threads**: For each thread, determine whether the user sent the last message. If the user sent the last message and no reply has been received, flag the thread as "Awaiting Reply." Apply the thread reply detection logic from the skill.

3. **Detect promises**: Scan flagged threads for bidirectional promise patterns. For outbound promises (user's sent messages), check for delivery, response, action, and temporal commitment language. For inbound promises (received messages), check the same categories plus deferral language. Consult `${CLAUDE_PLUGIN_ROOT}/skills/followup/follow-up-detection/references/promise-patterns.md` for the complete pattern library. Classify each promise as "Promise Made", "Promise Received", or "Awaiting Response."

4. **Apply exclusion rules**: Filter out threads matching exclusion criteria from the skill: no-reply addresses, automated senders, service addresses, newsletters, auto-replies, transactional confirmations, mailing list messages, and calendar invitations.

5. **Score priority**: Calculate priority 1-5 for each follow-up candidate using the skill's scoring formula: age-based tier + relationship importance modifier + promise urgency modifier + thread activity modifier. Clamp to 1-5 range.

6. **Sort results**: Order by priority descending, then by days_waiting descending.

7. **Apply filters**: If `--priority=high`, keep only items with priority >= 3. Apply `--limit` to cap the displayed count.

## Notion Integration

1. **Discover database**: Search Notion for the consolidated **"[FOS] Tasks"** database. If not found, try **"Founder OS HQ - Tasks"**. If not found, fall back to the legacy "Follow-Up Tracker - Follow-Ups" database. If none exists, degrade gracefully (see below). Do **not** lazy-create any database.
2. **Type filter**: All reads and queries against the HQ database **must** include a filter `Type = "Follow-Up"` to scope results to this plugin's records only.
3. **Write fields**: Set `Type = "Follow-Up"` and `Source Plugin = "Follow-Up Tracker"` on every created or updated record. Map Subject → Title, Recipient → Contact relation (with Company relation when domain matches CRM), and use HQ status values (Waiting / Done). See the follow-up-detection skill for the full field mapping.
4. **Idempotent updates**: Use Thread ID as the unique key. For threads already in the database (filtered by `Type = "Follow-Up"`), update Days Waiting, Priority, and Status. For new threads, create records. Never duplicate entries.
5. **Resolve threads**: If a previously tracked thread now has a reply, update Status to "Done."
6. **Expire threads**: Mark items as "Done" with note "[Expired — no reply after 30 days]" when days_waiting exceeds 30 and no nudge has been sent.

## Graceful Degradation

If Notion MCP is unavailable or any Notion operation fails:
- Output the follow-up list as structured text in chat
- Include all fields for each item
- Warn: "Notion unavailable — displaying results in chat. Follow-ups were not saved to the tracker database. Configure Notion MCP per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md` and ensure the [FOS] Tasks database exists."

## Output Format

After scanning, display results:

```
## Follow-Up Check

**Scanned**: Last [N] days of sent mail
**Found**: [count] emails awaiting response
**Promises detected**: [count] (Made: [n], Received: [n])
**Tracked in Notion**: [count] new | [count] updated | [count] resolved

---

| # | Subject | Recipient | Days | Priority | Promise Type | Suggested Action |
|---|---------|-----------|------|----------|--------------|------------------|
| 1 | [subject] | [recipient] | [days] | [score]/5 [label] | [type] | [action] |
| 2 | ... | ... | ... | ... | ... | ... |

[For each tracked item, include the Notion page link if available]
```

Suggested Action values:
- Priority 5: "Follow up immediately"
- Priority 4: "Follow up today — use `/founder-os:followup:nudge [thread_id]`"
- Priority 3: "Follow up this week — use `/founder-os:followup:nudge [thread_id]`"
- Priority 2: "Set a reminder — use `/founder-os:followup:remind [thread_id]`"
- Priority 1: "Monitor — no action needed yet"

If no follow-ups found:
- Display: "No emails awaiting response in the last [N] days. Inbox is clear!"

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/founder-os:followup:check
/founder-os:followup:check --days=7
/founder-os:followup:check --priority=high
/founder-os:followup:check --days=14 --limit=10
/founder-os:followup:check --priority=high --limit=5
```
