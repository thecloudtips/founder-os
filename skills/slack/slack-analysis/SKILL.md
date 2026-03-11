---
name: Slack Analysis
description: "Retrieves and classifies Slack workspace messages for digest generation. Activates when the user wants to scan Slack, catch up on channels, find decisions, or asks 'what happened in Slack while I was away?' Covers channel scanning, message extraction, thread context, message classification, and decision detection."
globs:
  - "commands/slack-digest.md"
  - "commands/slack-catch-up.md"
---

## Overview

Retrieve raw Slack messages from specified channels and DMs, extract structured data from each message, classify messages by type, and detect decisions embedded in conversations. This skill serves as the data retrieval and classification layer that both `/founder-os:slack:digest` and `/founder-os:slack:catch-up` commands depend on. It handles all Slack MCP interaction, temporal filtering, thread resolution, and message type assignment. Downstream consumers (the message-prioritization skill) receive the classified output for scoring, noise filtering, and digest formatting.

## Slack MCP Tool Usage

Interact with the Slack workspace through four core MCP operations via the Slack MCP server configured in `.mcp.json` with the `SLACK_BOT_TOKEN` environment variable.

### 1. List Channels

Call `list_channels` to discover all channels the bot can access. Each record includes `id`, `name`, `is_archived`, `num_members`, `topic`, `purpose`. Cache the channel list for the duration of the scan session to avoid redundant API calls. Filter out archived channels from the working set. When the `--all` flag is active, use this full filtered list as the scan target. When specific channel names are provided, use the list only for ID resolution.

### 2. Fetch Channel History

Retrieve messages from a single channel within a time window. Call `get_channel_history` with the resolved channel ID and computed `oldest` Unix timestamp (epoch seconds). Set `limit` to 200 per request to balance completeness with API efficiency. If the response `has_more` flag is true, paginate using the cursor until complete or the message count exceeds 1000. Cap at 1000 messages per channel to prevent runaway scans on extremely active channels. When the cap is reached, append: "Showing most recent 1000 of [N] messages in time window."

### 3. Fetch Thread Replies

Retrieve reply messages for a specific parent message. Call `get_thread_replies` with the channel ID and parent message `ts` (thread timestamp). The response includes the parent message plus all replies. Apply the selective fetching rules from Thread Context Resolution below to avoid fetching threads unnecessarily. Limit each thread fetch to 20 replies maximum.

### 4. Search DMs

When `--include-dms` is provided, call `list_conversations` with `types: "im"` to discover DM channels, then apply the same `get_channel_history` logic. Requires `im:history` bot scope. If unavailable, skip with warning: "DM scanning unavailable -- bot lacks im:history scope."

## Channel ID Resolution

Translate user-friendly channel names to Slack internal IDs before any history or thread API call.

1. Accept formats: `#general`, `general`, `#my-channel`, `my-channel`.
2. Strip leading `#`, convert to lowercase.
3. Match case-insensitively against the cached channel list `name` field.
4. On match, use the corresponding `id` for all API calls.
5. On no match, warn: "Channel '#[name]' not found or bot lacks access. Skipping." Continue with remaining channels.

When the user provides a channel ID directly (starts with `C` + alphanumeric), accept it as-is.

## Temporal Filtering

Convert the user-provided time window into a Unix timestamp for the `oldest` parameter.

| Input Format | Interpretation | Example |
|-------------|----------------|---------|
| `Nh` | N hours ago | `8h` = 8 hours ago |
| `Nd` | N days ago | `3d` = 72 hours ago |
| `Nw` | N weeks ago | `1w` = 7 days ago |
| `YYYY-MM-DD` | Specific date at 00:00:00 local | `2026-03-01` |
| `YYYY-MM-DD HH:MM` | Specific date and time | `2026-03-01 09:00` |
| (none) | Default: 24 hours ago | Omitted = `24h` |

### Conversion Rules

1. Parse the input string to determine format type (regex: `^\d+[hdw]$` for relative, `^\d{4}-\d{2}-\d{2}` for absolute).
2. Compute the Unix epoch timestamp representing the start of the scan window.
3. Reject future timestamps: "Time window starts in the future. Provide a past date or relative duration."
4. Clamp windows exceeding 30 days with a warning: "Time window exceeds 30 days. Limiting to last 30 days to avoid excessive API usage."
5. Pass the computed timestamp as the `oldest` parameter to all channel history requests.

## Scanning Order

Process channels sequentially to respect Slack API rate limits.

1. Resolve all channel IDs before starting (batch resolution from cache).
2. Scan one channel at a time. Emit progress after each: "Scanned #[channel-name]: [N] messages found ([M] threads)."
3. If specific channels are provided, scan in user-listed order. If `--all` is active, sort by `num_members` descending.

### Rate Limit Handling

On HTTP 429: wait 10 seconds, retry once. If the retry also fails, skip the channel with a warning and continue. Include skipped channels in the final scan summary.

## Message Extraction

Extract a structured record from each raw Slack message with the following fields:

| Field | Type | Description |
|-------|------|-------------|
| `id` | string | `client_msg_id` or fall back to `ts` |
| `channel_id` | string | Channel where the message was posted |
| `channel_name` | string | Human-readable name with `#` prefix |
| `author` | string | Resolved display name (cached per session) |
| `author_id` | string | Slack user ID |
| `text` | string | Full message text, Slack markup preserved |
| `timestamp` | string | Slack `ts` (unique within channel) |
| `thread_ts` | string | Parent thread timestamp; null if not threaded |
| `reply_count` | integer | Thread reply count; 0 if not a parent |
| `reaction_count` | integer | Total reactions (computed) |
| `reactions` | list | Emoji names with counts |
| `is_bot` | boolean | True if from a bot or integration |
| `subtype` | string | Slack subtype or null for normal messages |
| `has_attachments` | boolean | True if files or rich attachments present |
| `permalink` | string | Constructed deep link URL |
| `mentions` | list | User IDs extracted from `<@U...>` patterns |
| `edited` | boolean | True if message was edited |
| `deleted` | boolean | Always false; deleted messages are excluded |

### Author Resolution

Resolve user IDs to display names via the Slack API. Maintain a session-level user cache: on first encounter of a user ID, resolve the display name and store it. Reuse the cached name for all subsequent messages from the same author. When resolution fails (deleted user, deactivated account), use "Unknown ([user_id])".

### Permalink Construction

Construct permalinks using the pattern: `https://[workspace].slack.com/archives/[channel_id]/p[ts_without_dot]`. Replace the dot in the `ts` with nothing (e.g., `1709510400.001234` becomes `p1709510400001234`). Omit permalink when workspace domain is unknown rather than guessing.

## Thread Context Resolution

Fetch thread replies selectively to minimize API calls while capturing important context.

### Selective Fetching Rules

Fetch replies only when a parent message meets at least one criterion:

1. `reply_count >= 3` -- meaningful discussion, not simple acknowledgment.
2. Parent text contains decision keywords from `${CLAUDE_PLUGIN_ROOT}/skills/slack/slack-analysis/references/decision-patterns.md`.
3. Parent contains @mention + task verb (review, update, fix, deploy, create, test, check, send, prepare, schedule).
4. `reaction_count >= 5` -- strong engagement signal.

Skip all other threads. This reduces a 500-message/50-thread channel from 51 API calls to approximately 6-16.

### Fetch Limits

Fetch a maximum of 20 replies per thread. For threads exceeding 20, capture the first 5 and last 15 to preserve opening context and resolution. Include the parent message. Apply the same extraction schema to each reply.

## Message Type Classification

Classify every message into exactly one of 9 types using first-match-wins priority order.

| Priority | Type | Detection Signals |
|----------|------|------------------|
| 1 | `decision` | Matches patterns from `${CLAUDE_PLUGIN_ROOT}/skills/slack/slack-analysis/references/decision-patterns.md` + context signal validation (keyword + 2+ positive signals) |
| 2 | `announcement` | Posted by channel creator or workspace admin, OR contains `@channel`/`@here`/`<!channel>`/`<!here>`, OR starts with "Announcing", "Important:", "Update:", "Notice:", "Reminder:", "Please note", "Attention" |
| 3 | `action_assignment` | @mention (`<@U...>`) within 50 chars of a task verb: review, update, fix, deploy, create, test, check, send, prepare, schedule, write, approve, investigate, resolve, submit, implement |
| 4 | `question` | Ends with `?` after trimming, OR starts with question word (who, what, when, where, why, how, can, could, should, would, is, are, does, do, will, has, have). Match whole words at message start only |
| 5 | `status_update` | Contains progress language: "done", "completed", "shipped", "blocked", "in progress", "WIP", "working on", "finished", "launched", "merged", "deployed", "released", "started", "on track", "behind schedule" (case-insensitive) |
| 6 | `fyi` | Contains "FYI", "heads up", "PSA", "for your information", "just so you know", OR short message (< 100 chars) sharing a link with brief context, OR contains "sharing this", "thought you'd want to see" |
| 7 | `discussion` | Thread with 3+ unique participants, OR alternating authors across 4+ consecutive thread messages |
| 8 | `noise` | Clear-cut noise only: channel join/leave, pure emoji, greeting-only. Full noise filtering belongs to message-prioritization skill |
| 9 | `other` | Default when no type matches |

### Classification Rules

- Evaluate in strict priority order (1-9). Stop at first match. One type per message.
- Decision detection requires keyword match plus context signal validation -- keyword alone is insufficient.
- Bot messages receive any applicable type but always carry `is_bot: true` for downstream filtering.
- Thread replies inherit parent context for classification. A reply saying "approved" in a budget thread classifies as `decision`.

## DM Scanning

Activate only with explicit `--include-dms` opt-in.

1. Verify `im:history` scope by attempting to list IM conversations. On failure, warn and skip.
2. Discover DM channels via `list_conversations` with `types: "im"`.
3. Resolve DM partner display names.
4. Apply identical temporal filtering, extraction, and classification logic.
5. Store DM results separately, keyed by partner name. Present in a distinct "Direct Messages" section after channel results.

Never scan DMs without explicit opt-in. Label all DM content clearly: "DM with [display_name]".

## Channel Discovery

When `--all` is provided, auto-discover and scan all accessible channels.

1. Retrieve full channel list, filter archived channels.
2. Sort by `num_members` descending.
3. Report before scanning: "Discovering channels... Found [N] active channels. Beginning scan."
4. For workspaces with 50+ channels, warn: "Scanning all [N] channels will take approximately [N * 3 seconds]. Consider specifying channels by name."

## Edge Cases

Handle these 6 scenarios without halting the scan:

1. **Empty channels** -- Report "No messages in #[channel-name] for the last [time_window]." Include in summary with count 0.
2. **Bot messages** -- Extract normally with `is_bot: true`. Eligible for type classification. Message-prioritization skill handles final filtering.
3. **Edited messages** -- Use latest version, set `edited: true`. Do not retrieve edit history.
4. **Deleted messages** -- Skip entirely. Exclude from output and counts.
5. **Very long messages** -- Truncate to 2000 characters at nearest word boundary, append "[truncated]". Preserve full text for type classification before truncation.
6. **Missing bot access** -- Warn: "Bot cannot access #[channel-name]. Ensure the bot is invited." Skip and continue. Report under "Skipped (no access)".

## Reference Files

For complete decision detection keyword categories, context signal validation rules, confidence classification criteria, and common false positive patterns, consult:

`${CLAUDE_PLUGIN_ROOT}/skills/slack/slack-analysis/references/decision-patterns.md`
