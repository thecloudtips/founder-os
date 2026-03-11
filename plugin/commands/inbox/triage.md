---
description: Triage your inbox with AI categorization and prioritization
argument-hint: --team --hours=24 --max=100
allowed-tools: Read, Glob, Grep, Bash, Task
---

# Inbox Triage

Triage the user's Gmail inbox by categorizing and prioritizing emails. Operate in one of two modes depending on arguments.

## Gmail Access Method

This plugin accesses Gmail via the `gws` CLI tool:

1. Verify `gws` is available by running `which gws`. If not found, halt and inform the user to install gws CLI.
2. Use `gws gmail +triage --max N --format json` for a quick unread email summary.
3. Use `gws gmail users messages list --params '{"userId":"me","q":"QUERY","maxResults":N}' --format json` for filtered searches.
4. Use `gws gmail users messages get --params '{"userId":"me","id":"MSG_ID","format":"full"}' --format json` to fetch full message details.

**Important**: Use `gws` CLI commands via the Bash tool for all Gmail operations. Do NOT look for a gws CLI (`gws gmail`) or Chrome browser automation.

## Parse Arguments

Extract these flags from `$ARGUMENTS`:
- `--team` (boolean, default: false) — activate full 4-agent pipeline mode
- `--hours=N` (integer, default: 24) — hours to look back for unread emails
- `--max=N` (integer, default: 100) — maximum number of emails to process

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Observation: Start
Before executing, record a pre_command event to the Intelligence event store (`_infrastructure/intelligence/.data/intelligence.db`):
- Event type: `pre_command`
- Plugin: `inbox-zero`
- Command: `inbox-triage`
- Generate a session_id (UUID) and reuse it for all subsequent events in this execution
- Payload: record input parameters, context files loaded, and any memories injected
- If the Intelligence database does not exist, skip observation silently and continue execution

## Intelligence: Apply Learned Patterns
Before executing the main logic, check for learned patterns in the Intelligence database (`_infrastructure/intelligence/.data/intelligence.db`):
1. Query: `SELECT instruction, description FROM patterns WHERE (plugin = 'inbox-zero' OR plugin IS NULL) AND (command = 'inbox-triage' OR command IS NULL) AND status IN ('active', 'approved') ORDER BY confidence DESC`
2. If patterns found, apply each instruction as additional context for this execution
3. Notify: `[Intel] Applying learned preference: "{description}"` for each pattern applied
4. If the Intelligence database does not exist, skip silently and continue execution

## Self-Healing: Error Recovery
If any error occurs during this command:
1. Classify the error using rules from `_infrastructure/intelligence/self-healing/SKILL.md`
2. Check if healing is enabled: query `SELECT value FROM config WHERE key = 'healing.enabled'` from Intelligence DB
3. For transient errors: retry with exponential backoff (2s, 5s, 15s)
4. For recoverable errors: look up fix in healing_patterns table, apply if found
5. For degradable errors: consult fallback registry in `_infrastructure/intelligence/self-healing/fallback-registry/SKILL.md`, execute fallback path
6. For fatal errors: stop and present error with suggested fix
7. Always notify: `[Heal] {description of what happened and what was done}`
8. Record error event to Intelligence DB with recovery_attempted field
9. If Intelligence DB is unavailable, fall back to existing error handling (no self-healing)

## Mode 1: Default (Single-Agent Summary)

When `--team` is NOT present:

1. Read the email-triage skill at `${CLAUDE_PLUGIN_ROOT}/skills/inbox/email-triage/SKILL.md` for categorization rules.
2. Read the priority-scoring skill at `${CLAUDE_PLUGIN_ROOT}/skills/inbox/priority-scoring/SKILL.md` for the Eisenhower matrix rubric.
3. Use `gws gmail users messages list --params '{"userId":"me","q":"is:unread newer_than:Nd","maxResults":MAX}' --format json` to fetch unread emails from the last `--hours` hours (convert hours to days for the query), up to `--max` emails. For the default 24-hour window, use `gws gmail +triage --max MAX --format json` as a shortcut.
4. For each email, assign:
   - **Category**: one of `action_required`, `waiting_on`, `fyi`, `newsletter`, `promotions` (per email-triage skill rules)
   - **Priority**: 1-5 score using Eisenhower matrix (per priority-scoring skill rules)
   - **needs_response**: boolean
   - **archivable**: boolean
5. Use email snippets (first 200 chars) for all categories. Fetch full body only for `action_required` emails.

## Observation: Decision
Record this classification to the Intelligence event store:
- Event type: `decision_point`
- Payload: { decision: "email_priority_classification", options: ["urgent", "normal", "low"], choice: [selected priority for each email], reasoning: [why this priority was assigned] }

6. Present results as a structured summary:
   - Category counts (e.g., "action_required: 12, waiting_on: 8, fyi: 23, newsletter: 15, promotions: 29")
   - Top 5 most urgent emails (priority 4-5) with subject, sender, and recommended action
   - Archive candidates count
   - Quick stats: total processed, needs response count

### Output Format (Default Mode)

```
## Inbox Triage Summary

**Processed**: 87 emails (last 24 hours)

### Categories
| Category | Count |
|----------|-------|
| Action Required | 12 |
| Waiting On | 8 |
| FYI | 23 |
| Newsletter | 15 |
| Promotions | 29 |

### Needs Attention (Top 5)
1. **[Subject]** from [Sender] — Priority 5 — [Recommended action]
2. ...

### Quick Actions
- **Archive candidates**: 44 emails ready to archive
- **Needs response**: 10 emails awaiting your reply
```

## Mode 2: Team Pipeline (`--team`)

When `--team` IS present:

1. Read the pipeline configuration at `${CLAUDE_PLUGIN_ROOT}/agents/inbox/config.json`.
2. Execute the full 4-agent pipeline sequentially:
   - **Triage Agent** → categorize and prioritize all emails
   - **Action Agent** → extract action items, create tasks in "[FOS] Tasks" (Type="Email Task", Source Plugin="Inbox Zero"); falls back to "Founder OS HQ - Tasks", then legacy "Inbox Zero - Action Items" DB
   - **Response Agent** → draft replies for emails needing response, save to "[FOS] Content" (Type="Email Draft"); falls back to "Founder OS HQ - Content", then legacy "Inbox Zero - Drafts" DB

## Observation: Decision
Record the draft tone selection to the Intelligence event store:
- Event type: `decision_point`
- Payload: { decision: "draft_tone_selection", options: ["formal", "casual", "technical"], choice: [selected tone], reasoning: [based on sender relationship and context] }

   - **Archive Agent** → recommend archiving for low-priority processed emails (recommend-only, no auto-archive)
3. Each agent reads its corresponding agent definition from `${CLAUDE_PLUGIN_ROOT}/agents/inbox/`.
4. Pass output from each agent as input to the next (pipeline pattern).
5. Present the final pipeline report with:
   - Triage summary (category counts)
   - Action items created (count + list)
   - Drafts generated (count + confidence scores)
   - Archive recommendations (count, NOT auto-archived)
   - Emails needing manual attention (high priority, low-confidence drafts)

## Observation: End
After execution completes, record a post_command event to the Intelligence event store:
- Event type: `post_command`
- Use the same session_id from the start observation
- Outcome: `success` | `failure` | `degraded`
- Payload: { outcome summary, items processed, outputs created }
- Duration: milliseconds elapsed since pre_command event
- If any errors occurred during execution, also record an error event with the error type, message, and whether recovery was attempted

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Error Handling

- If gws CLI is not available (`which gws` fails): halt and inform the user to install gws CLI per INSTALL.md.
- If gws Gmail commands fail with auth errors: inform the user to run `gws auth login` to authenticate.
- If Notion gws CLI is unavailable or authentication not configured in `--team` mode: warn that action items and drafts will not be persisted to Notion, but continue pipeline.
- If none of "[FOS] Tasks", "Founder OS HQ - Tasks", or "Inbox Zero - Action Items" DB is found: warn and continue without Notion task storage.
- If none of "[FOS] Content", "Founder OS HQ - Content", or "Inbox Zero - Drafts" DB is found: warn and continue without Notion draft storage.
- If no unread emails found: report "Inbox Zero already achieved!" with zero counts.

## Usage Examples

```
/founder-os:inbox:triage                    # Default: summarize last 24h, up to 100 emails
/founder-os:inbox:triage --hours=8          # Summarize last 8 hours
/founder-os:inbox:triage --max=50           # Limit to 50 emails
/founder-os:inbox:triage --team             # Full pipeline with all 4 agents
/founder-os:inbox:triage --team --hours=48  # Full pipeline, last 48 hours
```
