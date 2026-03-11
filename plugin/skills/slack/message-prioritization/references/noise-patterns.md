# Noise Pattern Library

Complete pattern lists for filtering low-value Slack messages before signal scoring. Apply these filters first to reduce the working set.

## Noise Categories

### 1. Automated Bot Messages

Messages from bots and integrations that carry no actionable content for humans.

**Always Filter (remove entirely):**
- CI/CD status messages: build started, build passed, build failed (unless user is explicitly mentioned)
- Deployment notifications: "Deployed to staging", "Release v1.2.3 published"
- Monitoring alerts: uptime checks, health checks, scheduled job completions
- Integration sync messages: "Synced 15 contacts", "Backup completed", "Cron job finished"
- Calendar bot reminders: "Meeting starting in 15 minutes", "Daily standup reminder"
- Welcome bot messages: "Welcome to #channel!", auto-generated onboarding messages

**Detect via:**
- `is_bot: true` field in Slack message metadata
- `subtype: "bot_message"` in message data
- Known bot user IDs (resolve once per scan via channel members list)
- Message text starts with common bot prefixes: "[BOT]", "[AUTO]", "[ALERT]"

**Exception — Keep bot messages if:**
- The bot message contains an @mention of the current user
- The bot message is a poll or survey (contains "vote", "poll", radio button emoji)
- The message is in a channel specifically created for alerts AND user opted into alert channels

### 2. Social and Off-Topic Content

Messages that are social interaction rather than work communication.

**Filter Patterns:**
- Pure emoji reactions with no text (message body is only emoji characters)
- GIF-only messages (message contains only a GIPHY/Tenor URL with no accompanying text)
- "Good morning" / "Good night" / greeting-only messages
- Birthday, anniversary, and celebration messages without work content
- Food and lunch coordination: "anyone want coffee?", "ordering lunch", "pizza in the kitchen"
- Weekend/holiday small talk with no work references

**Detect via:**
- Message length < 20 characters AND contains only emoji or simple greetings
- URL-only messages where the URL domain is giphy.com, tenor.com, or imgur.com
- Greeting pattern: message matches `/^(good\s)?(morning|afternoon|evening|night|hey|hi|hello|bye|cheers|thanks|thx)[\s!.]*$/i`
- Channel name contains "social", "random", "watercooler", "off-topic", "fun"

**Exception — Keep social messages if:**
- They appear in a work channel (not a social/random channel)
- They are part of a thread that contains work content
- They contain @mentions

### 3. Link Dumps Without Context

Messages that share URLs without meaningful commentary.

**Filter Patterns:**
- Messages containing only a URL with no additional text
- Messages with a URL and only "FYI", "interesting", "check this out", "sharing this"
- Auto-unfurled link previews where the human-written text is < 10 words

**Detect via:**
- Message text after removing URLs is empty or < 10 words
- Message text matches `/^(fyi|check this out|interesting|sharing|link|see this|look at this)[\s:]*$/i` followed by URL

**Exception — Keep link messages if:**
- The accompanying text is > 30 words (indicates meaningful commentary)
- The link is to an internal tool (Notion, Google Docs, Jira, GitHub) — these are often work references
- The message has 3+ reactions or 2+ replies (community found it valuable)

### 4. Repeated and Duplicate Messages

Messages that duplicate content already captured.

**Filter Patterns:**
- Cross-posted messages: same sender, same text (>90% similarity), different channel, within 10 minutes
- Edited message duplicates: keep only the latest version of edited messages
- Thread echo: when someone copies their thread reply into the main channel verbatim
- "Bump" messages: "bump", "following up on this", "any update?" with no new content

**Detect via:**
- Text similarity > 90% (Jaccard similarity on word sets) between messages from same sender within 10-minute window
- `edited` field present in message metadata — use latest version only
- Message text matches `/^(bump|following up|any update|ping|reminder)[\s?!.]*$/i`

### 5. Channel Management Messages

System messages about channel operations.

**Always Filter:**
- "X joined #channel", "X left #channel"
- "X set the channel topic to...", "X set the channel purpose to..."
- "X pinned a message", "X unpinned a message"
- "X has been added to the channel by Y"
- Channel archived/unarchived notifications

**Detect via:**
- `subtype` field: "channel_join", "channel_leave", "channel_topic", "channel_purpose", "pinned_item", "channel_archive"

### 6. Low-Signal Acknowledgments

Short replies that acknowledge but add no information.

**Filter when standalone (not part of a longer message):**
- Single-word acknowledgments: "ok", "okay", "k", "sure", "yep", "yup", "yeah", "np", "ty", "thx"
- Single emoji responses posted as messages (not reactions)
- "Got it", "Will do", "On it", "Noted" — unless followed by additional text

**Detect via:**
- Message length < 15 characters after trimming
- Message text matches `/^(ok(ay)?|k|sure|yep|yup|yeah|np|ty|thx|got it|will do|on it|noted|ack|roger|copy)[\s!.]*$/i`

**Exception — Keep acknowledgments if:**
- They are in response to an action item assignment (context matters)
- The acknowledger is the current user (personal relevance)
- The message has additional text beyond the acknowledgment

---

## Channel-Level Noise Classification

Some channels are inherently higher or lower noise. Apply channel-level adjustments:

### High-Noise Channels (apply stricter filtering)
- Channels matching: "random", "social", "watercooler", "off-topic", "fun", "memes", "pets"
- Auto-created integration channels: "github-notifications", "jira-updates", "deploy-alerts"
- Channels with > 80% bot messages in the scan window

### Low-Noise Channels (apply lenient filtering)
- Channels matching: "leadership", "exec", "board", "strategy", "decisions", "important"
- Channels with < 5 messages per day (low traffic = higher signal per message)
- Channels the user has starred or set to "All new messages" notification level

