---
name: integration-test-plan
description: Integration tests for the Adaptive Intelligence Engine plugin and infrastructure
---

# Integration Test Plan: Adaptive Intelligence Engine

Plugin #32 | Standalone | Claude Code

## Prerequisites

- Intelligence database initialized at `_infrastructure/intelligence/.data/intelligence.db`
- Schema applied from `_infrastructure/intelligence/hooks/schema/intelligence.sql`
- At least one pilot plugin installed (Inbox Zero, Daily Briefing, or Client Health)
- Notion MCP configured (for sync tests only — all other tests work locally)

---

## Suite 1: /intel:status

### Test 1.1: Empty Database

**Command**: `/intel:status`
**Preconditions**: `intelligence.db` does not exist or is freshly initialized with no data
**Expected behavior**:
- Detects missing or empty database
- Displays the "Not initialized" message
- Instructs the user to run a plugin command to begin capturing events
- Does not error or crash

**Pass criteria**: Output contains "Not initialized" and a helpful prompt. No stack trace.

---

### Test 1.2: Database With Events, No Patterns Yet

**Command**: `/intel:status`
**Preconditions**: At least 10 events exist in the `events` table from pilot plugin usage; `patterns` table is empty
**Expected behavior**:
- Shows hooks section with correct event count and distinct plugin count
- Shows learning section with `0 patterns` and breakdown `0 active / 0 candidate / 0 approved`
- Shows self-healing section with 0 recoveries
- Top Active Patterns section displays "No patterns learned yet"
- Recent Healing Events section displays "No healing events"
- Configuration section shows default values from `config` table

**Pass criteria**: All 5 sections rendered. No sections show "unavailable" if queries succeed. Pattern count is 0.

---

### Test 1.3: Database With Events and Patterns

**Command**: `/intel:status`
**Preconditions**: `events` table has 50+ rows across 2+ plugins; `patterns` table has at least 3 active patterns with varying confidence scores
**Expected behavior**:
- Hooks section reflects accurate 30-day event count
- Learning section shows correct totals for active, candidate, approved patterns
- Top Active Patterns lists 3 patterns ordered by confidence (highest first)
- Each pattern line includes plugin, description snippet, confidence, and confirmation ratio
- Configuration section reflects any non-default values

**Pass criteria**: Top 3 patterns listed in descending confidence order. All counts match direct SQL queries.

---

### Test 1.4: Query Failure Resilience

**Command**: `/intel:status`
**Preconditions**: Simulate a corrupted `patterns` table (e.g., drop the table mid-test)
**Expected behavior**:
- Command does not crash
- The failed section shows "unavailable" rather than an error
- Other sections that succeeded are still rendered normally

**Pass criteria**: Partial output rendered. No unhandled exception propagated to the user.

---

## Suite 2: /intel:patterns

### Test 2.1: No Patterns

**Command**: `/intel:patterns`
**Preconditions**: `patterns` table is empty
**Expected behavior**:
- Displays "No patterns learned yet."
- Suggests running plugin commands to start capturing observations

**Pass criteria**: Graceful empty state message. No error.

---

### Test 2.2: All Patterns (No Filter)

**Command**: `/intel:patterns`
**Preconditions**: `patterns` table has 6+ rows with mixed statuses and types
**Expected behavior**:
- Lists all patterns grouped or sorted by confidence (desc)
- Each row shows: ID, plugin, type, description, confidence, status, confirmations/observations
- No filter applied — all statuses shown

**Pass criteria**: Row count matches `SELECT COUNT(*) FROM patterns`. All columns populated.

---

### Test 2.3: Filter by Plugin

**Command**: `/intel:patterns --plugin=inbox-zero`
**Preconditions**: `patterns` table has rows for both `inbox-zero` and `daily-briefing` plugins
**Expected behavior**:
- Only patterns with `plugin = 'inbox-zero'` are returned
- Patterns for other plugins are excluded

**Pass criteria**: All returned rows have `plugin = 'inbox-zero'`. Count matches direct SQL with filter.

---

### Test 2.4: Filter by Type

**Command**: `/intel:patterns --type=taste`
**Preconditions**: `patterns` table has both `taste` and `workflow` type patterns
**Expected behavior**:
- Only patterns with `pattern_type = 'taste'` are returned

**Pass criteria**: All returned rows have `pattern_type = 'taste'`.

---

### Test 2.5: Detail View for Single Pattern

**Command**: `/intel:patterns <id>`
**Preconditions**: A pattern with the given ID exists in the `patterns` table
**Expected behavior**:
- Shows expanded single-pattern view
- Includes all fields: ID, plugin, type, description, instruction, confidence, status, observations, confirmations, rejections, created_at, updated_at
- Shows the full instruction text (not truncated)

**Pass criteria**: All pattern fields displayed. ID matches requested value.

---

### Test 2.6: Invalid ID

**Command**: `/intel:patterns 9999`
**Preconditions**: No pattern with ID 9999 exists
**Expected behavior**:
- Displays: "Pattern #9999 not found."
- Does not error

**Pass criteria**: Friendly not-found message. No crash.

---

## Suite 3: /intel:approve

### Test 3.1: Approve Valid Pattern

**Command**: `/intel:approve <id>`
**Preconditions**: Pattern with the given ID exists and has `status = 'candidate'` or `status = 'active'`
**Expected behavior**:
- Prompts for confirmation before approving
- On confirmation, updates `status` to `'approved'` and sets `confidence` to `1.0`
- Displays: "✓ Pattern #<id> approved. It will now be applied with maximum confidence."

**Pass criteria**: `patterns.status = 'approved'` and `patterns.confidence = 1.0` after command. Confirmation prompt shown.

---

### Test 3.2: Invalid Pattern ID

**Command**: `/intel:approve 9999`
**Preconditions**: No pattern with ID 9999 exists
**Expected behavior**:
- Displays: "Pattern #9999 not found."
- No database writes occur

**Pass criteria**: Friendly error. No SQL update executed.

---

### Test 3.3: Already-Approved Pattern

**Command**: `/intel:approve <id>`
**Preconditions**: Pattern with the given ID already has `status = 'approved'`
**Expected behavior**:
- Informs the user the pattern is already approved
- Displays current status and confidence
- Does not re-run the approval update

**Pass criteria**: Message indicates already-approved state. No redundant DB write.

---

## Suite 4: /intel:reset

### Test 4.1: Reset by Plugin

**Command**: `/intel:reset --plugin=inbox-zero`
**Preconditions**: `patterns` table has rows for `inbox-zero` and other plugins
**Expected behavior**:
- Prompts for confirmation before deleting
- On confirmation, deletes all patterns with `plugin = 'inbox-zero'`
- Patterns for other plugins remain untouched
- Displays count of deleted patterns

**Pass criteria**: Zero rows with `plugin = 'inbox-zero'` remain. Other plugin patterns unchanged.

---

### Test 4.2: Reset by Type

**Command**: `/intel:reset --type=workflow`
**Preconditions**: `patterns` table has both `taste` and `workflow` type patterns
**Expected behavior**:
- After confirmation, deletes all patterns with `pattern_type = 'workflow'`
- Taste patterns remain
- Displays count of deleted patterns

**Pass criteria**: Zero `workflow` patterns remain. Taste patterns intact.

---

### Test 4.3: Reset All

**Command**: `/intel:reset --all`
**Preconditions**: `patterns` and `healing_patterns` tables have rows
**Expected behavior**:
- Shows explicit warning about deleting all patterns and healing data
- Requires confirmation
- Deletes all rows from `patterns` and `healing_patterns`
- Resets `notion.last_sync` config key
- Displays total count of deleted rows

**Pass criteria**: Both tables empty after command. Config keys except defaults remain.

---

### Test 4.4: Confirmation Flow — Cancel

**Command**: `/intel:reset --all`
**Preconditions**: Any patterns exist
**Expected behavior**:
- Confirmation prompt is shown
- User responds with anything other than "confirm"
- Command aborts without any database writes
- Displays: "Reset cancelled."

**Pass criteria**: No rows deleted. Cancellation message shown.

---

## Suite 5: /intel:healing

### Test 5.1: No Healing Events

**Command**: `/intel:healing`
**Preconditions**: `events` table has no rows with `event_type = 'error'`; `healing_patterns` table is empty
**Expected behavior**:
- Recent Events section: "No healing events"
- Error Frequency section: empty or "No errors recorded"
- Fix Effectiveness section: empty or "No healing patterns yet"
- Systemic Issues section: not shown or "None detected"

**Pass criteria**: All sections render with graceful empty states. No error.

---

### Test 5.2: With Healing Events and Patterns

**Command**: `/intel:healing`
**Preconditions**: `events` table has 10+ error events (last 7 days); `healing_patterns` has at least 3 rows with varying success/failure counts
**Expected behavior**:
- Recent Events: up to 20 most recent error events listed with timestamp, plugin, command, error type, and outcome
- Error Frequency: top errors listed by count (last 30 days)
- Fix Effectiveness: top patterns listed with success rate percentage
- Systemic Issues: shown if any error recurs across 3+ sessions; hidden otherwise

**Pass criteria**: Event count matches SQL query. Success rates match `success_count / (success_count + failure_count)`.

---

### Test 5.3: Filter by Plugin

**Command**: `/intel:healing --plugin=client-health`
**Preconditions**: Error events exist for both `client-health` and `inbox-zero` plugins
**Expected behavior**:
- Recent Events filtered to `plugin = 'client-health'` only
- Error Frequency table still includes all plugins (for context)
- Fix Effectiveness filtered to patterns matching `client-health`

**Pass criteria**: No events from other plugins appear in the Recent Events section.

---

## Suite 6: /intel:config

### Test 6.1: Show All Config (No Arguments)

**Command**: `/intel:config`
**Preconditions**: `config` table exists with all 10 default keys
**Expected behavior**:
- All 10 config keys displayed with values and inline comments
- Usage hint shown at the bottom
- Values match those stored in the `config` table

**Pass criteria**: All 10 keys rendered. No "unknown key" or error.

---

### Test 6.2: Show Single Key

**Command**: `/intel:config learning.autonomy.max_level`
**Preconditions**: Key exists in `config` table
**Expected behavior**:
- Displays just that key and its current value
- No other keys shown

**Pass criteria**: Single-key display with correct value.

---

### Test 6.3: Update Boolean Key

**Command**: `/intel:config learning.enabled false`
**Preconditions**: `learning.enabled` currently set to "true"
**Expected behavior**:
- Validates "false" as a valid boolean value
- Updates `config` table
- Displays: "✓ Updated learning.enabled: true → false"
- Subsequent `/intel:config` shows the new value

**Pass criteria**: `config` table row updated. Confirmation message shows old and new values.

---

### Test 6.4: Update Threshold Key

**Command**: `/intel:config learning.taste.threshold 0.7`
**Preconditions**: Key currently set to "0.5"
**Expected behavior**:
- Validates "0.7" as a numeric value
- Updates the row
- Displays: "✓ Updated learning.taste.threshold: 0.5 → 0.7"

**Pass criteria**: Row updated correctly.

---

### Test 6.5: Update Enum Key — Valid Value

**Command**: `/intel:config learning.autonomy.max_level suggest`
**Preconditions**: Key currently set to "notify"
**Expected behavior**:
- Validates "suggest" against allowed enum values: ask, suggest, notify, silent
- Updates the row
- Displays confirmation

**Pass criteria**: Row updated to "suggest".

---

### Test 6.6: Update Enum Key — Invalid Value

**Command**: `/intel:config learning.autonomy.max_level auto`
**Preconditions**: Key currently set to "notify"
**Expected behavior**:
- Validates "auto" — not in allowed set
- Displays: "Invalid value 'auto' for learning.autonomy.max_level. Expected: ask | suggest | notify | silent"
- No database write occurs

**Pass criteria**: Validation error shown. Config unchanged.

---

### Test 6.7: Unknown Key

**Command**: `/intel:config nonexistent.key true`
**Preconditions**: Key "nonexistent.key" does not exist in `config` table
**Expected behavior**:
- Displays: "Unknown config key 'nonexistent.key'. Run /intel:config to see available keys."
- No database write

**Pass criteria**: Error message with helpful suggestion. Config unchanged.

---

### Test 6.8: Reset Config

**Command**: `/intel:config --reset`
**Preconditions**: Some config values have been changed from defaults (e.g., `learning.enabled = false`)
**Expected behavior**:
- Prompts: "Reset all intelligence configuration to defaults? Type 'confirm':"
- On confirmation, all 10 keys restored to default values
- `notion.last_sync` key is preserved (not deleted)
- Displays: "✓ All configuration reset to defaults."

**Pass criteria**: All 10 default key-value pairs present. `notion.last_sync` preserved. Changed values reverted.

---

### Test 6.9: Reset Config — Cancel

**Command**: `/intel:config --reset`
**Preconditions**: Any non-default config values exist
**Expected behavior**:
- Confirmation prompt displayed
- User types anything other than "confirm"
- Displays: "Reset cancelled."
- No config changes made

**Pass criteria**: Config unchanged. Cancellation message shown.

---

## Suite 7: Pilot Plugin Hooks Integration

### Test 7.1: Pre-Command Event Written

**Preconditions**: Inbox Zero plugin installed with hooks integration; `intelligence.db` initialized
**Action**: Run `/inbox:triage`
**Expected behavior**:
- A `pre_command` event is written to the `events` table before the command executes
- Event has correct `plugin`, `command`, `session_id`, `timestamp`, and `event_type = 'pre_command'`

**Pass criteria**: `SELECT COUNT(*) FROM events WHERE event_type='pre_command' AND plugin='inbox-zero'` returns 1+ after running the command.

---

### Test 7.2: Post-Command Event Written

**Preconditions**: Same as 7.1
**Action**: Run `/inbox:triage` to completion
**Expected behavior**:
- A `post_command` event is written after execution with `outcome` in payload (success or failure)
- `session_id` matches the corresponding `pre_command` event

**Pass criteria**: `SELECT COUNT(*) FROM events WHERE event_type='post_command' AND plugin='inbox-zero'` returns 1+. Session IDs match.

---

### Test 7.3: Decision-Point Events (When Enabled)

**Preconditions**: `hooks.decision_points = 'true'` in config; Inbox Zero pilot plugin running
**Action**: Run `/inbox:triage` and make a label decision during the command
**Expected behavior**:
- A `decision_point` event is captured with the decision context in payload
- If `hooks.decision_points = 'false'`, no such event is written

**Pass criteria**: Event count changes based on config flag state.

---

### Test 7.4: Error Event on Failure

**Preconditions**: Daily Briefing plugin installed with hooks; simulate a Notion MCP timeout during `/daily:briefing`
**Expected behavior**:
- An error event is written to `events` with `event_type = 'error'`
- Payload includes `error_type`, `error_message`, and whether recovery was attempted

**Pass criteria**: Error event present in DB after a command failure. No duplicate events.

---

## Suite 8: Pilot Plugin Pattern Injection

### Test 8.1: Active Patterns Injected at Command Start

**Preconditions**: `patterns` table has at least one `approved` pattern for `inbox-zero` plugin
**Action**: Run `/inbox:triage`
**Expected behavior**:
- The command's behavior reflects the active pattern (e.g., if a "prefer bullet list" taste pattern is approved, output is in bullet list format)
- No user prompt required to apply the pattern

**Pass criteria**: Observable behavioral difference in command output consistent with the pattern instruction.

---

### Test 8.2: No Patterns — Default Behavior

**Preconditions**: `patterns` table is empty or has no patterns for the pilot plugin
**Action**: Run a pilot plugin command
**Expected behavior**:
- Command executes with default behavior (no pattern adjustments)
- No error or "pattern not found" message shown to user

**Pass criteria**: Command completes successfully. No pattern-related output shown.

---

### Test 8.3: Cross-Plugin Patterns Applied

**Preconditions**: A pattern with `plugin = NULL` (cross-plugin) and `status = 'approved'` exists
**Action**: Run any pilot plugin command
**Expected behavior**:
- The cross-plugin pattern is included in context injection
- Applied alongside any plugin-specific patterns

**Pass criteria**: Cross-plugin pattern instruction reflected in output.

---

## Suite 9: Pilot Plugin Self-Healing Integration

### Test 9.1: Transient Error Retry

**Preconditions**: Daily Briefing plugin with self-healing blocks; simulate a transient Notion API timeout on first attempt
**Action**: Run `/daily:briefing`
**Expected behavior**:
- First attempt fails with a transient error
- Plugin automatically retries (up to `healing.max_retries` times per config)
- On successful retry, command completes normally
- A healing event is logged to `events` with `recovery_attempted = true` in payload

**Pass criteria**: Command succeeds after retry. Healing event recorded. No error shown to user (unless all retries exhausted).

---

### Test 9.2: Max Retries Exhausted — Graceful Degradation

**Preconditions**: Simulate persistent Notion API failure (all retries fail); `healing.fallback.enabled = 'true'`
**Action**: Run `/daily:briefing`
**Expected behavior**:
- All retries exhausted
- Fallback behavior activates (e.g., Notion skipped, output generated from local data only)
- User notified: "[Fallback mode] Notion unavailable — compiled from local data only"
- A healing event is logged with `outcome = 'fallback'`

**Pass criteria**: Fallback output produced. Fallback event recorded. No unhandled crash.

---

### Test 9.3: Healing Disabled

**Preconditions**: `healing.enabled = 'false'` in config; transient error occurs
**Action**: Run a pilot plugin command that encounters an error
**Expected behavior**:
- No retry attempted
- Error propagated immediately to the user
- No healing event written (or event written with `recovery_attempted = false`)

**Pass criteria**: Command fails on first error. No retry delay. Config state respected.

---

### Test 9.4: Healing Pattern Effectiveness Tracked

**Preconditions**: A healing pattern in `healing_patterns` table for a known `error_signature`
**Action**: Trigger the same error type that matches the healing pattern signature
**Expected behavior**:
- Healing pattern's `fix_action` is applied
- If fix succeeds: `healing_patterns.success_count` incremented by 1
- If fix fails: `healing_patterns.failure_count` incremented by 1

**Pass criteria**: Correct counter incremented after each healing attempt.

---

## Notion Sync Tests

### Test 10.1: Push Patterns to Notion

**Command**: `/memory:sync` (which triggers intelligence sync)
**Preconditions**: Notion MCP configured; `[FOS] Intelligence` DB exists; `patterns` table has 3+ rows; `notion.last_sync` config key absent (first sync)
**Expected behavior**:
- All pattern rows pushed to Notion
- Each row creates or updates a page with correct properties
- `notion.last_sync` config key set to current timestamp

**Pass criteria**: Pattern count in Notion matches local `patterns` table. `notion.last_sync` updated.

---

### Test 10.2: Incremental Push (Changed Since Last Sync)

**Preconditions**: First sync already done; one new pattern added after last sync
**Action**: Trigger sync
**Expected behavior**:
- Only the new pattern is pushed (not all patterns)
- Existing Notion pages are not duplicated
- `notion.last_sync` updated

**Pass criteria**: Exactly 1 new Notion page created. Existing pages unchanged.

---

### Test 10.3: Pull Status Change from Notion

**Preconditions**: A pattern page in Notion has been manually changed to Status = "Rejected"
**Action**: Trigger sync
**Expected behavior**:
- The corresponding row in `patterns` has its `status` updated to `'rejected'`
- No other rows are modified

**Pass criteria**: Local `patterns.status` matches Notion status after pull.

---

### Test 10.4: Notion Unavailable — Silent Skip

**Preconditions**: Notion MCP not configured or API key invalid
**Action**: Run any command that triggers sync
**Expected behavior**:
- Sync silently skipped
- No error shown to user
- Local database unaffected

**Pass criteria**: Command completes normally. No sync error displayed.

---

## Acceptance Criteria Coverage

| Spec Criterion | Covered By |
|----------------|-----------|
| `/intel:status` shows dashboard | Suite 1 |
| `/intel:patterns` lists and filters patterns | Suite 2 |
| `/intel:approve` promotes patterns | Suite 3 |
| `/intel:reset` clears patterns with confirmation | Suite 4 |
| `/intel:healing` shows self-healing log | Suite 5 |
| `/intel:config` view/update/reset config | Suite 6 |
| Hooks write pre/post events | Suite 7 |
| Patterns injected into pilot plugins | Suite 8 |
| Self-healing retries and fallback work | Suite 9 |
| Notion sync bidirectional | Suite 10 |

## Notes

- Run Suite 7–9 with at least one pilot plugin (Inbox Zero, Daily Briefing, or Client Health — Inbox Zero recommended as simplest hooks integration)
- For healing tests, inject failures using a mock/stub rather than real API outages where possible
- Verify `intelligence.db` state directly with `sqlite3` CLI after each write test
- Notion sync tests require a live Notion workspace with the HQ template deployed
- All commands should complete without unhandled exceptions regardless of database state
