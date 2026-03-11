# Sync Patterns Reference

Advanced batch processing patterns, flag parsing rules, output format templates, cross-plugin integration notes, and filter rules for the CRM Sync skill.

---

## Advanced Batch Processing Patterns

### Large Batch Handling (>50 Items)

When a batch scan returns more than 50 items, process them in chunks to avoid memory pressure and Notion API rate limits:

1. Sort all items by date ascending (oldest first) so the most recent items are processed last and appear at the top of the CRM timeline.
2. Divide items into chunks of 20.
3. Process each chunk sequentially. Within a chunk, process items one at a time.
4. After each chunk completes, display an interim progress line: `Processed [X] of [total] items...`
5. If a chunk encounters 3 or more consecutive Notion write failures, pause for 30 seconds before starting the next chunk. This signals likely rate limiting.
6. After all chunks complete, display the standard batch status report with aggregate counts.

For batches exceeding 200 items (rare, typically first-time sync of a large mailbox), display a warning before processing: "Large batch detected ([count] items). This may take several minutes. Consider using --since to narrow the time window, or use --dry-run to preview first."

### Rate Limiting for Notion API

Notion enforces rate limits on API requests. Apply these defensive patterns:

- **Baseline pacing**: Insert a 200ms pause between consecutive Notion API write calls. This prevents burst-triggering the rate limiter during normal batch operations.
- **429 response handling**: On receiving an HTTP 429, read the `Retry-After` header if present. If no header, default to a 5-second pause. Retry the failed request once after the pause.
- **Escalating backoff**: If 3 consecutive requests receive 429 responses, escalate the pause to 30 seconds. After the pause, resume with the 200ms baseline pacing.
- **Session abort threshold**: If 10 total 429 responses occur within a single batch run, halt the batch and report: "Notion rate limit exceeded. [X] of [total] items processed. Re-run to continue from where the batch left off (already-synced items will be skipped)."

### Retry Logic for Transient API Failures

Apply retry logic to transient failures (network timeouts, 5xx server errors) from any MCP server:

- **Max retries per request**: 2 (original attempt + 2 retries = 3 total attempts).
- **Retry delay**: 2 seconds for the first retry, 5 seconds for the second retry.
- **Non-retryable errors**: 400 (bad request), 401 (unauthorized), 403 (forbidden), 404 (not found). Fail immediately on these without retry.
- **Timeout handling**: If a request does not respond within 30 seconds, treat it as a transient failure and retry.

---

## --since Flag Parsing Rules

The `--since` flag accepts multiple formats for specifying the batch lookback window start date. Parse in this priority order:

| Format | Example | Interpretation |
|--------|---------|----------------|
| Relative days | `7d` | 7 days ago from today |
| Relative weeks | `2w` | 14 days ago from today |
| Relative months | `1m` | 30 days ago from today (always 30 days, not calendar month) |
| ISO date | `2024-01-15` | Specific start date (YYYY-MM-DD) |
| ISO datetime | `2024-01-15T09:00:00` | Specific start date and time |

Parsing rules:
- Default when `--since` is omitted: `7d` (7 days).
- The end date is always "now" (current date and time). There is no `--until` flag.
- Reject negative values: `--since=-3d` is invalid. Display: "Invalid --since value. Use a positive duration like '7d' or an ISO date."
- Reject future dates: if the parsed date is in the future, display: "The --since date is in the future. Use a past date or relative duration."
- Maximum lookback: 90 days. If the parsed date is more than 90 days ago, warn: "Lookback exceeds 90 days. Processing may be slow. Continue? (y/n)" In non-interactive batch mode, cap at 90 days silently.

---

## CRM Context View Format Template

Use this format for the `/crm:context [client]` command output:

```
## [Company Name] -- CRM Context

**Status**: [Active/Prospect/etc.]
**Industry**: [Industry]
**Owner**: [Owner name]
**In CRM since**: [Creation date]

### Key Contacts
| Name | Role | Email | Last Activity |
|------|------|-------|---------------|
| [name] | [role] | [email] | [date] |

### Recent Communications (Last [N] Days)
| Date | Type | Contact | Summary |
|------|------|---------|---------|
| [date] | Email/Meeting | [name] | [2-line summary] |

### Open Deals
| Deal | Stage | Value | Expected Close |
|------|-------|-------|----------------|
| [name] | [stage] | $[amount] | [date] |

**Total communications**: [count] in last [N] days
**Last contact**: [date] ([X] days ago)
```

Display rules:
- If no contacts exist, show: "No contacts linked to this company."
- If no communications exist in the window, show: "No communications in the last [N] days."
- If no open deals exist, omit the Open Deals section entirely (do not show an empty table).
- Sort communications by date descending (most recent first).
- Sort contacts by last activity date descending.
- Limit communications to the 20 most recent. If more exist, append: "Showing 20 of [total]. Use --days=[larger] to see more."

---

## Cross-Plugin Integration Notes

The CRM Sync Hub (P21) writes to the Communications database, which is read by several other plugins. Understand these dependencies to ensure data quality:

### P20 Client Context Loader

P20's `/client:load` command reads from the Communications DB to build client dossiers. When P21 syncs activities:
- P20 gains access to richer, more complete communication history.
- P20's "Last Contact" data becomes more accurate because P21 captures both email and meeting touchpoints.
- If P21 writes a summary with poor quality or incorrect client matching, P20 will propagate that data into the dossier. Maintain summary quality standards.

### P10 Client Health Dashboard

P10 reads the Communications DB to compute the "Last Contact" health metric:
- P21 sync directly improves P10's Last Contact scoring accuracy by ensuring recent interactions are logged.
- A batch sync backfill can retroactively improve health scores for clients who appeared inactive due to missing communication records.
- P10 uses the Communication record's date field (not the "synced at" timestamp) for scoring, so backdated syncs are correctly handled.

### P06 Follow-Up Tracker

P06 independently scans Gmail for unanswered sent emails:
- Some emails flagged by P06 as "awaiting follow-up" may also be synced by P21 to the CRM.
- There is no conflict -- P06 tracks follow-up status while P21 logs the communication record. They serve different purposes on the same source data.
- When reviewing unmatched items from a P21 batch, check if P06 has already flagged those threads. The follow-up context may help with client identification.

### Data Flow Diagram

```
Gmail/Calendar --> P21 CRM Sync Hub --> Communications DB
                                              |
                   P20 Client Context <-------+
                   P10 Client Health  <-------+
                   P06 Follow-Up (independent Gmail scan)
```

---

## Filter Rules for Batch Mode

Apply these filters during the batch scan phase (Step 1) to exclude items that should not be synced to the CRM. Filter before client matching to save processing time.

### Email Filters

| Rule | Detection | Action |
|------|-----------|--------|
| Internal emails | Sender and all recipients share the same email domain as the user | Skip silently |
| Automated emails | From address matches: `noreply@`, `no-reply@`, `notifications@`, `mailer-daemon@`, `postmaster@`, `auto-`, or contains `noreply` in the local part | Skip silently |
| Mailing lists | Headers contain `List-Unsubscribe` or `Precedence: bulk` or `Precedence: list` | Skip silently |
| Marketing emails | From address matches known marketing platforms: `mailchimp.com`, `sendgrid.net`, `constantcontact.com`, `hubspot.com` (marketing, not CRM), `campaign-` prefix | Skip silently |
| Very short threads | Thread contains only a single auto-generated message with no substantive body (< 50 characters excluding signature) | Skip silently |

To determine the user's email domain for internal email detection, extract it from the authenticated Gmail account. All addresses sharing that domain are considered internal.

### Calendar Event Filters

| Rule | Detection | Action |
|------|-----------|--------|
| Declined events | User's RSVP status is "declined" | Skip silently |
| Cancelled events | Event status is "cancelled" | Skip silently |
| All-day events | Event has no specific start/end time (all-day flag is true) | Skip by default; include with `--include-all-day` |
| Solo events | User is the only attendee (no external participants) | Skip silently |
| Recurring event duplicates | Event is part of a recurring series; only sync the most recent occurrence within the batch window | Sync most recent, skip earlier occurrences |
| Focus time / OOO | Event title or description contains "Focus Time", "Out of Office", "OOO", "Busy", "Block" (case-insensitive) | Skip silently |

### Filter Reporting

In the batch status report, do not count filtered items individually. Instead, add a single line after the counts table:

```
*[X] items filtered (internal emails, automated messages, declined events, etc.)*
```

This keeps the report focused on CRM-relevant items while acknowledging that filtering occurred.
