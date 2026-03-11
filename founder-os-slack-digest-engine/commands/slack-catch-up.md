---
description: Quick personal Slack catch-up showing only your @mentions and action items
argument-hint: "[--since=8h]"
allowed-tools: ["Read"]
---

# Slack Catch-Up

Lightweight personal catch-up scan across all bot-accessible Slack channels. Show only messages directly relevant to the current user: @mentions, action items assigned to the user, and critical broadcast mentions. Optimized for speed — skips full classification and fetches threads only where the user is involved.

## Load Skills

Read the slack-analysis skill at `${CLAUDE_PLUGIN_ROOT}/skills/slack-analysis/SKILL.md` for channel scanning and message extraction.

Read the message-prioritization skill at `${CLAUDE_PLUGIN_ROOT}/skills/message-prioritization/SKILL.md` for @mention detection, action item extraction, and the personal relevance filter.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `--since=TIMEFRAME` (optional) — time window to scan. Accepts `Nh` (hours), `Nd` (days), or `YYYY-MM-DD`. Default: `8h`.
- `--all` (optional) — accepted as no-op for syntax compatibility with `/slack:digest`. Catch-up always scans all accessible channels.

No channel selection arguments. Catch-up always scans all channels the bot is a member of.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Lightweight Scanning Mode

This command implements a speed-optimized scan that reduces API calls by approximately 80% compared to `/slack:digest`.

### Step 1: Resolve User Identity

Call Slack's auth.test API once to obtain the current user's Slack user ID, display name, and real name. Cache these values for the session.

### Step 2: Discover Channels

List all channels the bot has access to. Filter out archived channels. Process channels sequentially.

### Step 3: Lightweight Message Scan

For each channel:
1. Fetch message history within the `--since` time window.
2. Perform lightweight scan — do NOT run full message type classification. Instead, only check each message for:
   - **Direct @mention**: message text contains `<@USER_ID>` matching the current user
   - **Broadcast mention**: message text contains `@channel`, `@here`, or `@everyone`
   - **Name mention**: message text contains the user's display name or real name (case-insensitive)
   - **Action assignment**: message matches the action item extraction criteria from the message-prioritization skill (named assignee matching user + task verb + assignment language)
3. Skip messages that do not match any of the above criteria.
4. For matched messages only, fetch thread context to understand the conversation around the mention or assignment.
5. If a channel returns an error (not-a-member, rate limited), skip silently and increment the skipped channel counter.

Display progress: "Scanning... ([N] of [total] channels)"

### Step 4: Apply Personal Relevance Filter

Apply the strict personal relevance filter from the message-prioritization skill:
- Include if `assignee_is_me == true` (explicit action assignment to current user)
- Include if `mention_type == "direct"` (user @mentioned by name/ID)
- Include if `mention_type == "broadcast"` AND message scores P1 (75+ signal score) — for critical @channel/@here only
- Exclude everything else.

For the broadcast filter, compute a quick signal score using only message type and engagement factors (skip recency and channel importance for speed).

## Output Format

### Items Found

```
## Slack Catch-Up

**Scanned**: [channel_count] channels · Last [N] hours
**Found**: [action_count] action items · [mention_count] mentions · [broadcast_count] important broadcasts
[If channels were skipped: "([skipped_count] channels skipped — bot not a member or rate limited)"]

---

### Your Action Items

- [ ] **[action_text]** — assigned by [author] in #[channel] · [due_date or "no due date"]
  _[timestamp] · [thread context summary]_

- [ ] ...

[Sort by due date ascending — soonest first, then by channel importance, then by recency]

---

### Your @Mentions

1. **#channel** — [author]: "[message excerpt]"
   _[timestamp] · [thread context if fetched]_

2. ...

[Sort by recency descending — most recent first]

---

### Important Broadcasts

[Include only if any @channel/@here messages scored P1]

1. **#channel** — [author]: "[message excerpt]"
   _[timestamp] · @channel/here_

---

*Run `/slack:digest [channels]` for full team context and decisions · Slack Digest Engine*
```

### Nothing Found

```
## Slack Catch-Up

**Scanned**: [channel_count] channels · Last [N] hours

All clear! Nothing needs your attention in the last [N] hours.

*Run `/slack:digest --all` for full team context · Slack Digest Engine*
```

## No Notion Storage

This command does NOT save results to Notion. Catch-up answers "what do I need to look at right now" — it is ephemeral by design. For persistent records, use `/slack:digest` with `--output=notion`.

## Graceful Degradation

**Slack MCP unavailable**: Stop execution. Display:
"Slack MCP server is not connected. Install it per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`:
1. Create a Slack App at https://api.slack.com/apps
2. Add bot scopes: channels:history, channels:read, chat:write, search:read
3. Install app to workspace and set SLACK_BOT_TOKEN"

**All channels fail**: Stop with: "Unable to scan any channels. Check that the Slack bot has been invited to channels via `/invite @bot-name`."

**Partial channel failures**: Continue with remaining channels. Note skipped count in the header.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/slack:catch-up
/slack:catch-up --since=4h
/slack:catch-up --since=1d
```
