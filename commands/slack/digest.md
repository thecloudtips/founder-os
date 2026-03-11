---
description: Scan Slack channels and produce a structured digest with decisions, action items, key threads, and @mentions
argument-hint: "[#channel1 #channel2] [--all] [--since=24h] [--include-dms] [--output=notion|chat|both] [--schedule=EXPR] [--persistent]"
allowed-tools: ["Read"]
---

# Slack Digest

Scan Slack channels to produce a comprehensive digest identifying decisions, action items, key discussion threads, and @mentions. Filter noise from signal using scoring algorithms. Optionally store the digest in Notion.

## Load Skills

Read the slack-analysis skill at `${CLAUDE_PLUGIN_ROOT}/skills/slack/slack-analysis/SKILL.md` for channel scanning, message extraction, thread context resolution, message type classification, and decision detection.

Read the message-prioritization skill at `${CLAUDE_PLUGIN_ROOT}/skills/slack/message-prioritization/SKILL.md` for noise filtering, signal scoring, priority tier assignment, @mention detection, action item extraction, and thread deduplication.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `[#channel1 #channel2 ...]` (optional) — explicit channel names to scan. Strip leading "#" before matching.
- `--all` (optional) — scan all channels the bot has access to. Overrides explicit channel list.
- `--since=TIMEFRAME` (optional) — time window to scan. Accepts `Nh` (hours), `Nd` (days), or `YYYY-MM-DD` (specific date). Default: `24h`.
- `--include-dms` (optional) — include direct messages in the scan. Requires im:history bot scope.
- `--output=notion|chat|both` (optional) — where to deliver the digest. Default: `both`.

### Channel Selection Logic

1. If `--all` is provided: discover all bot-accessible channels via the slack-analysis skill's channel discovery procedure.
2. If explicit channel names are provided: resolve names to Slack channel IDs via the slack-analysis skill's channel ID resolution procedure.
3. If neither `--all` nor channel names are provided: prompt the user — "Which channels should I scan? Provide channel names (e.g., `#general #engineering`) or use `--all` for all accessible channels." Wait for response before proceeding.

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
4. Default suggestion if no expression given: `"0 18 * * 1-5"` (Weekdays 6:00pm)
5. Handle the schedule operation (create/disable/status) per the spec
6. Exit after scheduling — do NOT continue to main command logic

## Step 1: Scan Channels

Apply the slack-analysis skill:

1. Resolve channel names to IDs (skip channels that fail to resolve, warn per channel).
2. Compute the oldest Unix timestamp from the `--since` value.
3. Fetch message history for each channel within the time window. Display progress: "Scanning #channel-name ([N] of [total])..."
4. For messages qualifying for thread context (reply_count >= 3 or contains decision keywords), fetch thread replies.
5. Classify each message into one of 9 message types using the first-match-wins logic.
6. If `--include-dms` is provided, scan DMs using the same extraction and classification logic.

## Step 2: Score and Prioritize

Apply the message-prioritization skill:

1. Run noise filter on all extracted messages. Track noise statistics.
2. Compute signal score (0-100) for each remaining message using the 4-factor algorithm: message type (0-40) + engagement (0-25) + recency (0-20) + channel importance (-5 to +15).
3. Assign priority tiers: P1 (75-100), P2 (50-74), P3 (25-49), P4 (1-24), P5 (0).
4. Detect @mentions of the current user (direct, broadcast, name).
5. Extract explicit action items meeting all three criteria: named assignee + task verb + assignment language.
6. Deduplicate threads (use max score across thread). Deduplicate cross-posts (keep higher-importance channel version).
7. Compute summary statistics.

## Step 3: Assemble Digest

Build the digest from scored data. Include P1, P2, and P3 items. Exclude P4 and P5.

### Section 1: Header

```
## Slack Digest

**Channels scanned**: [count] ([channel names])
**Time window**: Last [N] hours/days (since [date/time])
**Messages analyzed**: [total] | **After noise filter**: [remaining] ([filter_rate]% noise)
**Generated**: [timestamp]
```

### Section 2: Decisions

List all messages classified as `decision` type with high or medium confidence, newest first.

```
### Decisions

1. **#channel** — [author]: "[decision text excerpt]"
   _[timestamp] · [confidence] confidence · [thread_url if available]_

2. ...
```

If no decisions found: "No decisions detected in the scanned time window."

### Section 3: Action Items

Sort with `assignee_is_me` items first, then by due date ascending, then by priority tier.

```
### Action Items

**Assigned to you:**
- [ ] [action_text] — assigned by [author] in #[channel] · [due_date or "no due date"]

**Assigned to others:**
- [ ] [action_text] → [assignee] — by [author] in #[channel] · [due_date or "no due date"]
```

If no action items found: "No explicit action items detected."

### Section 4: @Mentions

Show direct mentions of the current user, newest first.

```
### Your @Mentions

1. **#channel** — [author]: "[message excerpt]"
   _[timestamp] · [context: thread summary if available]_

2. ...
```

If no mentions found: "No direct @mentions found."

### Section 5: Key Threads

Display top 10 P1 and P2 items not already surfaced in Decisions, Action Items, or @Mentions sections. Order by signal score descending.

```
### Key Threads

1. **#channel** — [author]: "[message excerpt]" ([message_type])
   _Score: [score]/100 · [reply_count] replies · [reaction_count] reactions_

2. ...
```

### Section 6: Channel Summaries

Include only when 3 or more channels were scanned. One line per channel.

```
### Channel Summaries

- **#channel-a**: [message_count] messages, [decision_count] decisions, [action_count] action items — [one-line summary]
- **#channel-b**: ...
```

### Section 7: DMs (Conditional)

Include only when `--include-dms` was provided and DM messages were found.

```
### Direct Messages

[Same format as Key Threads section, limited to DM content]
```

### Footer

```
---
*Digest generated by Slack Digest Engine · [Notion link if saved] · Run `/founder-os:slack:catch-up` for a quick personal summary*
```

## Step 4: Notion Integration

Execute only when `--output` is `notion` or `both`.

1. **Check for database**: Search Notion for a database named "[FOS] Briefings". If not found, try "Founder OS HQ - Briefings".
2. **Fallback**: If not found, search for "Slack Digest Engine - Digests".
3. **No database found**: If neither exists, skip Notion recording. Do NOT create a new database. Append to footer: "Notion database not found — digest displayed in chat only."
4. **Idempotent check**: Search for an existing record where the Date (title) matches today's date AND Type = "Slack Digest". Update if found, create if not.
5. **Save**: Write the digest to the Notion record using the consolidated schema:
   - Date (title) — format: "YYYY-MM-DD" (today's date)
   - Type (select) — set to "Slack Digest"
   - Content (rich_text) — full digest markdown (was "Digest Content")
   - Meeting Count (number) — set to 0 (not applicable)
   - Email Count (number) — set to Messages Analyzed count
   - Task Count (number) — set to Action Items Count
   - Sources Used (multi_select) — set to "Slack" (add "Notion" if Notion was used)
   - Generated At (date) — current timestamp

   **Property mapping notes:**
   - Old "Digest Title" is replaced by the Date title field.
   - Old "Channel(s)" and "Time Window" info should be included in the Content body.
   - Old "Decisions Count", "Mentions Count" are tracked in the Content body rather than as separate properties.
6. **Report**: Include the Notion page URL in the digest footer.

## Graceful Degradation

**Slack MCP unavailable**: Stop execution. Display:
"Slack MCP server is not connected. Install it per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`:
1. Create a Slack App at https://api.slack.com/apps
2. Add bot scopes: channels:history, channels:read, chat:write, search:read
3. Install app to workspace and set SLACK_BOT_TOKEN"

**Notion MCP unavailable** (and --output includes notion): Continue with chat output. Append to footer: "Notion unavailable — digest displayed in chat only. Configure Notion MCP per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`."

**Rate limit on all channels**: Stop with: "Slack rate limit hit on all channels. Try again in 60 seconds, reduce scope (fewer channels), or narrow the time window."

**Single channel rate limit**: Skip that channel with warning, continue with remaining channels.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/founder-os:slack:digest #general #engineering
/founder-os:slack:digest --all --since=8h
/founder-os:slack:digest #product #design --since=2d --include-dms
/founder-os:slack:digest --all --since=2026-03-01 --output=notion
/founder-os:slack:digest #engineering --output=chat
```
