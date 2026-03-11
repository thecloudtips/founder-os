# Integration Test Plan: Slack Digest Engine

## Test Environment

- Slack workspace with 5+ channels, including mix of active and quiet channels
- Bot invited to at least 3 channels
- Notion integration configured (for Notion-related tests)
- Recent messages (within 24h) in at least 2 channels

## Test Scenarios

### Scenario 1: Basic Single-Channel Digest

**Command**: `/slack:digest #general`

**Expected**:
- Scans only #general
- Produces 6-section digest (Header, Decisions, Action Items, @Mentions, Key Threads, no Channel Summaries for single channel)
- Messages classified into correct types
- Noise filtered with statistics reported
- Signal scores calculated correctly

**Verify**:
- [ ] Channel resolved from name to ID
- [ ] Messages fetched within default 24h window
- [ ] Thread replies fetched for messages with reply_count >= 3
- [ ] Message types assigned using first-match-wins logic
- [ ] Noise filter rate between 20-80%
- [ ] Output sections properly formatted

### Scenario 2: Multi-Channel Digest with --all

**Command**: `/slack:digest --all --since=8h`

**Expected**:
- Discovers all bot-accessible channels
- Scans each sequentially with progress indicator
- Includes Channel Summaries section (3+ channels)
- Cross-channel deduplication applied

**Verify**:
- [ ] All accessible channels discovered
- [ ] Archived channels excluded
- [ ] Progress indicator shown per channel
- [ ] Channel Summaries section present
- [ ] Cross-posted messages deduplicated

### Scenario 3: Personal Catch-Up

**Command**: `/slack:catch-up`

**Expected**:
- Scans all channels (no channel selection)
- Default 8h time window
- Only shows user's @mentions and action items
- No decisions, key threads, or channel summaries
- Faster execution than full digest

**Verify**:
- [ ] User identity resolved via auth.test
- [ ] Lightweight scan (no full classification)
- [ ] Only direct mentions, action assignments, and P1 broadcasts included
- [ ] Thread context fetched only for matched messages
- [ ] No Notion storage attempted
- [ ] Correct "All clear!" message if nothing found

### Scenario 4: Decision Detection

**Setup**: Channel with messages containing decision keywords ("we decided", "approved", "let's go with")

**Command**: `/slack:digest #decisions-channel --since=2d`

**Expected**:
- Decisions correctly identified using keyword + context signal validation
- High-confidence decisions in Decisions section
- Medium-confidence decisions with qualifier
- False positives filtered (questions, hypotheticals)

**Verify**:
- [ ] Decision patterns from reference file applied
- [ ] Context signals validated (thread position, participant count, reactions)
- [ ] False positives excluded (questions ending with "?", hypothetical language)
- [ ] Confidence classification correct (high/medium)

### Scenario 5: Action Item Extraction

**Setup**: Channel with messages containing explicit assignments ("@user please review the PR", "assigned to @user")

**Command**: `/slack:digest #engineering`

**Expected**:
- Only explicit action items extracted (all 3 criteria met)
- Assignee correctly identified
- Due dates parsed when present
- User's own items listed first

**Verify**:
- [ ] Named assignee + task verb + assignment language all present
- [ ] Inferred commitments NOT extracted
- [ ] Due date parsed from temporal patterns (today, tomorrow, EOD, by [date])
- [ ] assignee_is_me items sorted first

### Scenario 6: Notion Integration

**Command**: `/slack:digest #general --output=notion`

**Expected**:
- "[FOS] Briefings" database discovered (falls back to "Founder OS HQ - Briefings", then "Slack Digest Engine - Digests")
- Digest record created with Type = "Slack Digest"
- Idempotent: re-running same day updates existing record matched by Date + Type
- Notion page URL in footer

**Verify**:
- [ ] Database discovered (not created) — "[FOS] Briefings" first, then "Founder OS HQ - Briefings", fallback to legacy
- [ ] Type property set to "Slack Digest"
- [ ] Content property contains full digest markdown
- [ ] Same-day re-run updates existing record matched by Date + Type = "Slack Digest" (not duplicate)
- [ ] Notion page URL displayed in footer
- [ ] If neither database exists, digest output to chat only with no error

### Scenario 7: Graceful Degradation — Notion Unavailable

**Setup**: Remove or misconfigure NOTION_API_KEY

**Command**: `/slack:digest --all --output=both`

**Expected**:
- Digest still displays in chat
- Warning appended: "Notion unavailable"
- No error thrown — execution continues

**Verify**:
- [ ] Full digest displayed in chat output
- [ ] Warning message present in footer
- [ ] No stack trace or error in output
- [ ] Slack scanning unaffected

### Scenario 8: Graceful Degradation — Slack Unavailable

**Setup**: Remove or misconfigure SLACK_BOT_TOKEN

**Command**: `/slack:digest --all`

**Expected**:
- Execution stops immediately
- Clear error message with setup instructions
- References INSTALL.md for configuration steps

**Verify**:
- [ ] Execution halted (no partial output)
- [ ] Error message includes Slack App creation URL
- [ ] Required bot scopes listed
- [ ] INSTALL.md reference provided

### Scenario 9: Rate Limiting

**Setup**: Rapid successive scans to trigger rate limits (or mock 429 responses)

**Command**: `/slack:digest --all`

**Expected**:
- First 429: wait 10 seconds and retry
- Second 429 on same channel: skip channel with warning
- Continue with remaining channels
- If all channels rate limited: stop with retry instructions

**Verify**:
- [ ] Retry logic executes (10-second wait)
- [ ] Skip on second failure per channel
- [ ] Remaining channels continue processing
- [ ] Clear messaging about which channels were skipped

### Scenario 10: Empty Results

**Command**: `/slack:catch-up --since=1h` (in a quiet workspace)

**Expected**:
- "All clear! Nothing needs your attention in the last 1 hours."
- Suggests running /slack:digest for full context

**Verify**:
- [ ] Empty state message displayed
- [ ] No error or empty table
- [ ] Suggestion to use /slack:digest present

## Edge Case Tests

| Case | Expected Behavior |
|------|-------------------|
| Channel name not found | Warn and skip, continue with other channels |
| Bot not in channel | Skip with warning, note in output |
| Very long message (>2000 chars) | Truncate with "[truncated]" |
| Edited message | Use latest version, flag as edited |
| Deleted message | Skip entirely |
| `--since=30d` (large window) | Process in batches, 30-day max clamp |
| Single emoji message | Filtered as noise |
| Cross-posted message | Deduplicated, keep higher-importance channel |
