---
description: Sync email threads to CRM Pro Communications database with client matching and AI summaries
argument-hint: "[thread_id] [--since=7d] [--client=NAME] [--dry-run] [--schedule=EXPR] [--persistent]"
allowed-tools: ["Read"]
---

# Sync Email to CRM

Sync email conversations from Gmail to the CRM Pro Communications database in Notion. Supports single-thread sync and batch mode.

## Load Skills

Read these skills for processing logic:
- `${CLAUDE_PLUGIN_ROOT}/skills/crm-sync/SKILL.md` for the sync orchestration workflow, batch status report format, dry run rules, and error handling patterns
- `${CLAUDE_PLUGIN_ROOT}/skills/activity-logging/SKILL.md` for CRM write logic, AI summary generation guidelines, sentiment classification, activity type mapping, and deduplication strategy
- `${CLAUDE_PLUGIN_ROOT}/skills/client-matching/SKILL.md` for resolving email addresses to CRM clients via the 5-step progressive matching algorithm and confidence tiers

## Parse Arguments

Extract from `$ARGUMENTS`:
- First positional arg: `thread_id` (optional) -- Gmail thread ID for single-thread sync
- `--since=Nd` (optional) -- batch mode lookback window. Default: 7d. Accepted formats: "7d", "2w", "1m", ISO date. For parsing rules see `${CLAUDE_PLUGIN_ROOT}/skills/crm-sync/references/sync-patterns.md`.
- `--client=NAME` (optional) -- skip client matching, assign directly to the named client
- `--dry-run` (optional) -- preview what would be synced without writing to Notion

If no thread_id and no --since flag: default to batch mode with --since=7d.

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
4. Default suggestion if no expression given: `"0 9,14 * * 1-5"` (Weekdays 9am and 2pm)
5. Handle the schedule operation (create/disable/status) per the spec
6. Exit after scheduling — do NOT continue to main command logic

## Mode Detection

- **Single mode**: thread_id provided -- sync one email thread
- **Batch mode**: no thread_id -- scan sent folder for recent threads within the lookback window

## Single Thread Sync

1. **Fetch**: Use gws CLI (Gmail) to retrieve the email thread by `thread_id`. Extract: subject, all participants (from/to/cc), latest message body, sent date, thread message count. If the thread contains more than 10 messages, follow the long-thread handling rules from the activity-logging skill (summarize the 3 most recent messages, note total thread length).

2. **Match client**:
   - If `--client` flag provided: search the Companies DB for the named client directly using dynamic database discovery (never hardcode IDs).
   - Otherwise: run the client-matching skill's 5-step progressive matching algorithm on all non-user email addresses extracted from the thread participants. Use the highest-confidence match result.
   - If no match found (confidence NONE): present extracted email info (subject, participants, date) and ask the user to select a client from the CRM, create a new contact, or skip.

3. **Generate summary**: Create an AI summary following the activity-logging skill guidelines:
   - **Sentence 1**: State what the email was about -- the topic, request, or response being communicated.
   - **Sentence 2**: Highlight key decisions, commitments, or action items mentioned in the body.
   - **Sentence 3** (include only when substantive): Note next steps or follow-up expectations.
   - Classify sentiment (Positive/Neutral/Negative) using the activity-logging skill's sentiment classification rules.
   - For the Title field: use the email subject line. Strip "Re:", "Fwd:", "RE:", "FW:" prefixes (including nested multiples). Truncate at 80 characters. Capitalize the first letter if not already capitalized.

4. **Determine activity type**: Check the email's label metadata per the activity-logging skill's mapping rules:
   - Email with "SENT" label: Type = "Email Sent"
   - All other emails: Type = "Email Received"

5. **Write to CRM**:
   - If `--dry-run`: display what WOULD be written with `[DRY RUN]` prefix on all output lines. Skip the Notion write entirely. Do not create or update any Communications DB records.
   - Otherwise: create or update a Communications DB record via the activity-logging skill's deduplication logic. Before writing, query the Communications DB for existing records matching on Title (subject stripped of prefixes) + Date (same calendar day) + Type ("Email Sent" or "Email Received"). If a match is found, apply the idempotent update rules from the activity-logging skill. If no match, create a new record. Link to matched Company and Contact page IDs.

6. **Confirm**: Display the result to the user showing activity logged, client matched (with confidence tier), and summary preview. If the match confidence is below 0.7 (MEDIUM or lower), display a warning and ask the user to confirm the match before writing.

## Batch Mode

1. **Scan**: Search Gmail sent folder for threads with messages within the lookback window (from `--since` flag or default 7d). Retrieve full thread metadata for each.

2. **Filter**:
   - Skip internal emails (same domain as the user's email address)
   - Skip automated emails (noreply, notification, and distribution list patterns from the client-matching skill's reference file at `${CLAUDE_PLUGIN_ROOT}/skills/client-matching/references/matching-patterns.md`)
   - Skip draft emails (Gmail "DRAFT" label) per the activity-logging skill rules
   - Skip very short threads (single message with fewer than 50 words in the body)

3. **Check already synced**: For each remaining thread, check the Communications DB for existing records using the deduplication logic from the activity-logging skill. Use the batch deduplication optimization: fetch all Communications records within the batch's date range in a single query, then match locally. Skip threads that already have a synced record. Count these as "Skipped (already synced)" in the batch report.

4. **Process each**: Run the single-thread workflow (steps 2-6 above) for each unsynced thread. Process threads sequentially to avoid overwhelming the Notion API. Follow batch size limits from the activity-logging skill (batches of 50, 1-second pause between batches).

5. **Handle unmatched**: Collect threads where client matching returned confidence NONE. Do not halt the batch for unmatched items. Present the full unmatched list at the end for user resolution, formatted per the crm-sync skill: "N unmatched participants found. Review and assign: [list with email, name, and domain for each]."

6. **Report**: Display the batch status report using the format from the crm-sync skill:

```
## CRM Sync Complete

**Source**: Gmail Sent
**Period**: [start_date] to [end_date]
**Duration**: [processing_time]

| Status | Count |
|--------|-------|
| Synced (new) | X |
| Updated (existing) | X |
| Skipped (already synced) | X |
| Unmatched (needs review) | X |
| Failed | X |
| **Total processed** | **X** |

### Unmatched Items (if any)
- [subject] -- [email/attendee] -- No CRM match found
```

When all items are successfully synced with zero unmatched and zero failed, append: "All activities synced successfully."

If `--dry-run` is active, prefix the report header with `[DRY RUN]` and treat all would-be synced items as previews.

## Notion Integration

1. **Find Communications DB**: Search Notion for databases titled "[FOS] Communications", "Founder OS HQ - Communications", "Communications", "CRM - Communications", or "CRM Pro - Communications" (in that priority order). Use dynamic discovery via the Notion search API -- never hardcode database IDs. Cache the discovered ID for the duration of this command execution.
2. **If not found**: Report: "Communications database not found. Ensure the Founder OS HQ workspace template or CRM Pro template is installed in your Notion workspace." Do not create the database automatically.
3. **Companies and Contacts DB**: Use dynamic discovery (search by title, never hardcode IDs). Search for "[FOS] Companies" / "[FOS] Contacts" first, then "Founder OS HQ - Companies" / "Founder OS HQ - Contacts", then fall back to "Companies" / "Contacts" or "CRM - Companies" / "CRM - Contacts" per the client-matching skill's discovery rules.

## Graceful Degradation

- **gws CLI (Gmail) unavailable**: Error -- Gmail is required for this command. Display: "Gmail unavailable -- cannot sync emails. Configure gws CLI (Gmail) per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`." Stop execution.
- **Notion MCP unavailable**: Display sync results in chat with all fields for each item. Warn: "Notion unavailable -- displaying results in chat. Email activities were not saved to the CRM. Configure Notion MCP per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`."
- **Google gws CLI (Calendar) unavailable**: Not needed for this command. No degradation required.

## Output Format (Single Mode)

```
## Email Synced to CRM

**Thread**: [subject]
**Client**: [client_name] (confidence: [tier])
**Type**: Email Sent / Email Received
**Date**: [date]

### Summary
[AI-generated 2-3 sentence summary]

**Sentiment**: [Positive/Neutral/Negative]
**Notion**: [link to Communications record or "Not saved (dry run)"]
```

If no email found for the given thread_id:
- Display: "No email thread found for ID [thread_id]. Verify the thread ID and try again."

## Output Format (Batch Mode)

Use the batch status report format defined in the Batch Mode section above (from the crm-sync skill).

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/crm:sync-email                                    # Batch: sync last 7 days
/crm:sync-email thread_abc123                      # Single: sync specific thread
/crm:sync-email --since=14d                        # Batch: last 14 days
/crm:sync-email --since=2w --dry-run               # Preview batch without writing
/crm:sync-email thread_abc123 --client="Acme Corp" # Single with known client
```
