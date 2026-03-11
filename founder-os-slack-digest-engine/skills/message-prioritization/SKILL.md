---
name: Message Prioritization
description: "Ranks and filters Slack messages by relevance, separating signal from noise. Activates when the user wants to prioritize Slack messages, find important discussions, extract action items from Slack, or asks 'what's important in Slack?' Covers noise filtering, signal scoring, @mention detection, action item extraction, and thread deduplication."
globs:
  - "commands/slack-digest.md"
  - "commands/slack-catch-up.md"
---

## Overview

Filter, score, and prioritize Slack messages to surface what matters and discard noise. This skill operates on structured message data produced by the slack-analysis skill -- it does not fetch messages from Slack directly. Apply noise filtering to eliminate low-value content, compute a 4-factor signal score (0-100) for each surviving message, assign priority tiers (P1-P5), detect @mentions, extract explicit action items, and deduplicate threads and cross-posts. Output a prioritized message list consumed by the digest and catch-up commands.

This skill handles the relevance and filtering layer only. Channel scanning, thread fetching, and message type classification are responsibilities of the slack-analysis skill. Digest formatting and output rendering belong to the command layer.

## Noise Filtering

Apply noise filters BEFORE any scoring to reduce the working set and prevent low-value messages from inflating results. Load the complete noise pattern library from `${CLAUDE_PLUGIN_ROOT}/skills/message-prioritization/references/noise-patterns.md` for detailed detection methods, regex patterns, and exception rules.

### Filter Application Order

Apply filters in this specific sequence (most aggressive first, most nuanced last):

1. **Channel management messages** -- join/leave/topic/pin notifications. Always noise, no exceptions.
2. **Automated bot messages** -- CI/CD, deployment, monitoring, sync. Check exceptions for @mentions of the current user.
3. **Social and off-topic content** -- emoji-only, GIF-only, greetings, food coordination. Check channel context exceptions.
4. **Repeated and duplicate messages** -- cross-posts, edited duplicates, bumps. Keep the highest-value version.
5. **Link dumps without context** -- URL-only shares with no meaningful commentary. Check engagement exceptions.
6. **Low-signal acknowledgments** -- "ok", "got it", "will do" with no additional content. Check assignment context exceptions.

### Noise Statistics

Track filter results per category throughout processing. After filtering completes, compile statistics for inclusion in the output:

```
noise_stats:
  total_messages_scanned: N
  messages_filtered: N
  filter_rate: "XX%"
  breakdown:
    channel_management: N
    bot_messages: N
    social_content: N
    duplicates: N
    link_dumps: N
    low_signal_acks: N
  messages_remaining: N
```

Target filter rate: 30-60% for typical Slack workspaces. If the filter rate exceeds 80%, note in the digest header that the scanned channels are predominantly bot or social traffic. If the filter rate falls below 20%, the workspace is unusually high-signal -- no adjustment needed.

## Signal Scoring Algorithm

Compute a signal score from 0 to 100 for every message that survives noise filtering. The score is a weighted sum of four factors: message type, engagement, recency, and channel importance.

### Factor 1: Message Type Score (0-40 points)

Assign base points according to the message type classified by the slack-analysis skill:

| Message Type | Base Points |
|---|---|
| decision | 40 |
| action_assignment | 35 |
| announcement | 30 |
| question | 20 |
| status_update | 15 |
| fyi | 10 |
| discussion | 10 |
| other | 5 |
| noise | 0 |

Messages classified as `noise` by the slack-analysis skill but not yet filtered by the noise filter receive 0 points here, effectively ensuring removal at the tier assignment stage.

### Factor 2: Engagement Score (0-25 points)

Measure community signal by counting replies and reactions on the message:

- Reply count multiplied by 3, capped at 15 points.
- Reaction count multiplied by 2, capped at 10 points.
- Sum both sub-scores for the engagement total. Maximum: 25 points.

When reply or reaction counts are unavailable (e.g., message metadata incomplete), default to 0 for that sub-score.

### Factor 3: Recency Score (0-20 points)

Award points based on message age relative to the current time:

| Age | Points |
|---|---|
| < 2 hours | 20 |
| 2-6 hours | 16 |
| 6-12 hours | 12 |
| 12-24 hours | 8 |
| 1-3 days | 4 |
| > 3 days | 0 |

Calculate age from the message timestamp to the moment of scoring. Use the Slack message `ts` field converted to a datetime for precision.

### Factor 4: Channel Importance Modifier (-5 to +15 points)

Adjust the score based on the channel where the message appeared. Match channel names using substring containment (case-insensitive):

- **+15**: Channel name contains "leadership", "exec", "board", "strategy", or "decisions".
- **+10**: Channel name contains "engineering", "product", "design", or "sales".
- **+5**: Channel name contains "general", "announcements", or "important".
- **+0**: Default for channels matching none of the above patterns.
- **-5**: Channel name contains "random", "social", "off-topic", "fun", or "watercooler".

When a channel name matches multiple patterns, apply the highest modifier only. Do not stack modifiers.

### Score Calculation

```
signal_score = clamp(type_score + engagement_score + recency_score + channel_modifier, 0, 100)
```

Always clamp the final score to the 0-100 range.

## Priority Tier Assignment

Map each message's signal score to one of five priority tiers:

| Tier | Score Range | Label | Included In |
|---|---|---|---|
| P1 | 75-100 | Must Read | digest + catch-up |
| P2 | 50-74 | Important | digest + catch-up |
| P3 | 25-49 | Useful Context | digest only |
| P4 | 1-24 | Low Signal | excluded from output |
| P5 | 0 | Noise | excluded from output |

P4 and P5 messages do not appear in any user-facing output. Track their counts in summary statistics for transparency, but omit them from the prioritized message list.

Within each tier, sort messages by signal score descending, then by recency (newest first) as a tiebreaker.

## @Mention Detection

Detect three types of mentions for the current user across all messages (including those filtered as noise -- mentions override noise filtering).

### Detection Types

1. **Direct mention**: Message text contains `<@USER_ID>` where USER_ID matches the current user's Slack member ID.
2. **Broadcast mention**: Message text contains `@channel`, `@here`, or `@everyone`.
3. **Name mention**: Message text contains the user's display name or real name as a whole word (case-insensitive regex: `\b{name}\b`).

### User Identity Resolution

Resolve the current user's identity by calling the Slack `auth.test` API endpoint once at the start of each scan. Cache the response for the duration of the session. Extract:
- `user_id`: Slack member ID for direct mention matching.
- `user`: Username for fallback matching.
- Display name and real name from the user profile for name mention detection.

### Mention Output Structure

Produce one record per mention detected:

```
mention:
  mention_type: "direct" | "broadcast" | "name"
  message_id: [Slack message ts]
  channel: [channel name]
  author: [sender display name]
  text: [full message text]
  timestamp: [ISO datetime]
  assignee_is_me: [boolean]
```

Set `assignee_is_me` to `true` when the mention occurs within an action assignment context -- specifically when the mention is accompanied by a task verb and assignment language (see Action Item Extraction below). Set to `false` for informational mentions.

### Mention Priority Override

When a direct mention is detected in a message that would otherwise be filtered as noise or scored below P2, promote the message to at minimum P2 (Important). Broadcast mentions in noise-filtered messages promote to P3 at minimum. Name mentions do not override noise filtering.

## Action Item Extraction

Extract only explicit action items from messages. Never infer commitments from vague language or context.

### Three Criteria (ALL Must Be Met)

1. **Named assignee** -- An @mention or a person's name appears in the text identifying who should act.
2. **Explicit task verb** -- One of the following verbs appears in the message: review, update, fix, deploy, create, test, check, send, prepare, schedule, write, merge, approve, investigate, document, implement.
3. **Assignment language pattern** -- The message matches one of these structures:
   - `@name please [verb]...`
   - `@name can you [verb]...`
   - `@name [verb] the...`
   - `[name] to [verb]...`
   - `assigned to @name`
   - `[verb] this @name`

Reject extractions that meet only one or two criteria. Partial matches are not action items.

### Due Date Parsing

When temporal language accompanies an action item, parse the due date from these seven patterns:

| Pattern | Resolves To |
|---|---|
| today | Current date |
| tomorrow | Current date + 1 day |
| EOD | Current date, end of business |
| EOW | Friday of the current week |
| next Monday (or any weekday) | Next occurrence of that weekday |
| by [date] | Parsed calendar date |
| ASAP | Current date (treat as immediate) |

When no temporal language is present, set `due_date` to `null`.

### Action Item Output Structure

Produce one record per action item:

```
action_item:
  action_text: [the full extracted task description]
  assignee: [display name of the assigned person]
  assignee_id: [Slack user ID if resolvable, else null]
  assignee_is_me: [boolean]
  task_verb: [the matched verb]
  channel: [channel name]
  author: [person who assigned the task]
  timestamp: [ISO datetime]
  thread_url: [Slack permalink to the message]
  due_date: [ISO date or null]
  priority_tier: [inherited from parent message signal score]
```

The `priority_tier` field inherits directly from the parent message's tier assignment. Do not re-score action items independently.

## Thread Deduplication

Treat each Slack thread (parent message plus all replies) as an atomic unit. Do not present both a parent message and its replies as separate entries in the prioritized list.

### Scoring Rule

Compute the signal score for every message in the thread (parent and replies). Assign the thread the **maximum score** found across all its messages. This prevents a low-scoring parent from hiding a high-value decision or action item buried in a reply.

### Output Representation

In the prioritized message list, represent each thread as a single entry anchored by the parent message. Include the thread reply count and a one-line thread context summary (produced by the slack-analysis skill) to indicate what the thread contains.

### Reply Promotion

When a reply scores higher than the parent, inherit the reply's message type for the thread entry. For example, if the parent is a `question` (20 points) but a reply is a `decision` (40 points), label the thread entry as `decision` and use the reply's score as the thread score.

## Cross-Channel Deduplication

Detect messages posted to multiple channels by the same sender.

### Detection Criteria

Flag a cross-post when all three conditions are met:
1. Same sender (matching Slack user ID).
2. Posted within a 10-minute window.
3. Text similarity exceeds 90% (Jaccard similarity computed on word sets after lowercasing and removing punctuation).

### Resolution

Keep only the version from the higher-importance channel (based on the channel importance modifier). Discard the duplicate. Append metadata to the kept version: `"cross-posted from #other-channel"`.

When both channels have equal importance, keep the earlier-posted version.

## Personal Relevance Filter (Catch-Up Mode)

For the `/slack:catch-up` command, apply an additional strict personal relevance filter AFTER scoring and tier assignment. This filter reduces the output to only items that directly concern the current user.

### Inclusion Criteria

Include a message in catch-up output ONLY if at least one of these conditions is true:
- `assignee_is_me == true` (an action item is assigned to the current user).
- `mention_type == "direct"` (the user was directly @mentioned).
- `mention_type == "broadcast"` AND `priority_tier == "P1"` (a high-priority broadcast mention).

### Exclusion

Discard everything else from the catch-up output -- no channel summaries, no other people's action items, no decisions that do not mention the user, no general context. The catch-up mode is strictly personal.

## Output Data Structure

Produce a structured output consumed by the command layer:

```
prioritized_messages:
  - message_id: [Slack message ts]
    channel: [channel name]
    author: [sender display name]
    text: [message text or parent text for threads]
    timestamp: [ISO datetime]
    message_type: [classified type from slack-analysis]
    signal_score: [0-100]
    priority_tier: [P1 | P2 | P3 | P4 | P5]
    mentions:
      - mention_type: [direct | broadcast | name]
        assignee_is_me: [boolean]
    action_items:
      - action_text: [task description]
        assignee: [display name]
        assignee_is_me: [boolean]
        due_date: [ISO date or null]
    thread_context: [one-line summary of thread if applicable, else null]
    thread_reply_count: [integer or null]
    cross_post_note: [string or null]
```

Order the list by priority tier ascending (P1 first), then by signal score descending within each tier, then by timestamp descending as a final tiebreaker.

## Summary Statistics

After all processing completes, compute and include these summary metrics:

```
summary:
  total_messages_scanned: N
  messages_after_noise_filter: N
  filter_rate: "XX%"
  priority_counts:
    P1: N
    P2: N
    P3: N
    P4: N
    P5: N
  total_decisions: N
  total_action_items: N
  total_mentions: N
  my_action_items: N
  my_direct_mentions: N
  channels_scanned: N
  time_window: "[start] to [end]"
```

Include `my_action_items` and `my_direct_mentions` as separate counts so the command layer can surface personal relevance summaries without reprocessing.

## Reference Files

For detailed noise filtering rules including 6 categories, regex detection patterns, exception conditions, and channel-level adjustments, consult:
`${CLAUDE_PLUGIN_ROOT}/skills/message-prioritization/references/noise-patterns.md`
