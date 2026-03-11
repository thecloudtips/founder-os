# Scoring Formulas Reference

Complete per-metric scoring formulas, exponential decay curves, quick-reference tables, normalization rules, and edge case handling for the Client Health Scoring skill.

## Composite Score Formula

Calculate the overall health score as the weighted sum of all 5 individual metric scores:

```
composite = (last_contact_score × 0.25)
          + (response_time_score × 0.20)
          + (open_tasks_score × 0.20)
          + (payment_score × 0.20)
          + (sentiment_score × 0.15)
```

After computing the weighted sum, clamp the result to the 0-100 range:

```
final_composite = clamp(composite, 0, 100)
```

Apply RAG classification to the clamped composite:

| Tier | Range | Label |
|------|-------|-------|
| Green | 80-100 | Healthy |
| Yellow | 50-79 | Needs Attention |
| Red | 0-49 | At Risk |

---

## 1. Last Contact Score (Weight: 0.25)

Measure how recently the user communicated with the client. Use exponential decay to model the diminishing score as days without contact increase.

### Formula

```
last_contact_score = 100 × e^(-0.05 × days_since_contact)
```

Where `days_since_contact` is the number of calendar days between the most recent communication (email sent/received or calendar meeting) and today.

### Decay Curve

The decay constant of 0.05 produces a half-life of approximately 14 days. Score drops by roughly half every two weeks of silence.

### Quick Reference Table

| Days Since Contact | Score | Interpretation |
|-------------------|-------|----------------|
| 0 | 100 | Contacted today |
| 3 | 86 | Very recent |
| 7 | 70 | Within the week |
| 10 | 61 | Starting to age |
| 14 | 50 | Two weeks -- attention needed |
| 21 | 35 | Three weeks -- at risk |
| 30 | 22 | One month -- significant concern |
| 45 | 11 | Six weeks -- critical |
| 60 | 5 | Two months -- near zero |
| 90 | 1 | Three months -- effectively dormant |

### Data Source Selection

1. Query Gmail for the most recent thread (sent or received) involving any of the client's contact email addresses.
2. Query Google Calendar for the most recent event with client attendees (if gws CLI is available for Calendar).
3. Use whichever date is more recent as the basis for `days_since_contact`.
4. If a fresh P20 dossier exists, cross-reference its "Recent Activity" section to confirm the last contact date.

### Edge Cases

**No email history**: When no Gmail threads exist for any of the client's contact addresses within the search window:
- Set `days_since_contact` to the maximum search window (90 days).
- Resulting score: approximately 1.
- Add the "No Recent Contact" risk flag.
- If Calendar data shows a recent meeting, use that date instead.

**New client (< 30 days in CRM)**: When the client's CRM record creation date is less than 30 days ago:
- Apply a floor of 40 to the Last Contact score: `last_contact_score = max(computed_score, 40)`.
- This prevents new clients from immediately appearing as "At Risk" before a communication pattern is established.
- Add the "New Client" risk flag for visibility, but do not penalize the score.
- Rationale: a newly added client with no email history might be an in-person referral or event contact. The 40-point floor gives 30 days for digital communication to begin.

**Contact made today**: When `days_since_contact = 0`, the score is 100. This is the maximum and requires no special handling.

**Multiple contacts on the same day**: Use the most recent timestamp. Do not average or sum multiple same-day contacts.

---

## 2. Response Time Score (Weight: 0.20)

Measure how quickly the user responds to the client's emails. Fast response times indicate an engaged, attentive relationship.

### Formula

```
response_time_score = 100 × e^(-0.03 × avg_response_hours)
```

Where `avg_response_hours` is the average number of hours between a client's email and the user's reply, calculated across the last 10 threads in the past 30 days.

### Decay Curve

The decay constant of 0.03 produces a half-life of approximately 23 hours. Score drops by roughly half for every 23 hours of average response delay.

### Quick Reference Table

| Avg Response Time | Score | Interpretation |
|-------------------|-------|----------------|
| 0 hours (instant) | 100 | Immediate responder |
| 1 hour | 97 | Excellent |
| 4 hours | 89 | Very responsive |
| 8 hours | 79 | Same-day response |
| 12 hours | 70 | Within half a day |
| 24 hours | 49 | Next-day response |
| 36 hours | 34 | Slow |
| 48 hours | 24 | Two-day response |
| 72 hours | 12 | Three days -- concerning |
| 96 hours | 6 | Four days -- at risk |

### Calculation Method

1. Retrieve the last 10 email threads involving the client's contact addresses over the past 30 days.
2. For each thread, identify pairs where the client sent a message and the user replied. Sort messages by internal date ascending within each thread.
3. For each client-message-to-user-reply pair, calculate the elapsed time in hours.
4. If a thread contains multiple exchanges, use only the most recent pair to avoid over-weighting long threads.
5. Exclude auto-replies (detected by `X-Auto-Reply` header or "out of office" body content).
6. Exclude transactional/notification emails (from no-reply addresses, mailing lists).
7. Compute the arithmetic mean of all qualifying response intervals.

### Edge Cases

**No emails exchanged**: When no threads exist between the user and the client:
- Set Response Time score to 50 (neutral median).
- Do not add a risk flag -- absence of email does not indicate slow responses.

**All threads are outbound-only**: When the user has sent emails to the client but the client has never replied (no inbound messages to measure response time against):
- Set Response Time score to 50 (neutral).
- This scenario measures the user's response time to the client, not vice versa. Without inbound messages, the metric is undefined.

**Single thread only**: When only 1 qualifying thread exists:
- Use that single response time as the average. Do not penalize for low sample size, but note "Based on 1 thread" in the score details.

**Response time exceeds 7 days**: When `avg_response_hours > 168`:
- The formula will produce a score near 0. Clamp to 0. Do not allow negative scores.

---

## 3. Open Tasks Score (Weight: 0.20)

Measure the ratio of overdue tasks to total active tasks for the client. Clients with many overdue tasks indicate neglected obligations.

### Formula

```
open_tasks_score = 100 × (1 - overdue_count / max(total_active, 1))
```

Where:
- `overdue_count` = number of tasks associated with the client that are past their due date and not marked complete.
- `total_active` = total number of tasks associated with the client that are not marked complete (includes both on-time and overdue).

Apply an additional penalty for high absolute overdue counts:

```
if overdue_count >= 5:
    open_tasks_score = 0
```

This absolute cap ensures that clients with many overdue tasks score zero regardless of total task volume.

### Quick Reference Table

| Overdue / Total Active | Score | Interpretation |
|------------------------|-------|----------------|
| 0 / any | 100 | All tasks on track |
| 1 / 10 | 90 | Minor overdue |
| 1 / 5 | 80 | Manageable |
| 2 / 5 | 60 | Needs attention |
| 3 / 5 | 40 | Significant concern |
| 4 / 5 | 20 | Most tasks overdue |
| 5 / 5 | 0 | All overdue (also hits 5+ cap) |
| 5+ / any | 0 | Absolute cap reached |

### Data Sources

Gather task data from two sources in priority order:

1. **P20 Client Dossier** (preferred): If a fresh dossier exists (Stale = false, Generated At < 24 hours), extract the "Open Items" section. Count items marked with deadline language and determine which are past due.
2. **Notion CRM Tasks** (fallback): Search the Notion workspace for task databases linked to the client. Look for tasks with a due date property that is in the past and a status that is not "Done" or "Complete".

When both sources are available, use the P20 dossier data (already deduplicated). When only Notion is available, query directly.

### Edge Cases

**No tasks exist**: When no tasks are found for the client in any source:
- Set Open Tasks score to 100.
- Rationale: no tasks means no overdue tasks. The absence of tracked tasks is not itself a health concern for this metric.
- Do not add a risk flag.

**Tasks with no due date**: Exclude tasks without a due date from both `overdue_count` and `total_active`. Tasks without deadlines cannot be classified as overdue.

**Very high task volume**: When `total_active > 50`, log a note "High task volume for [client]" but apply the formula as normal. The ratio-based approach handles high volumes correctly.

---

## 4. Payment Score (Weight: 0.20)

Measure the client's invoice payment reliability using data from the Plugin #11 Invoice Processor.

### Formula

```
base_payment_score = 100 × (paid_on_time_count / max(total_invoices, 1))
overdue_penalty = currently_overdue_count × 20
payment_score = clamp(base_payment_score - overdue_penalty, 0, 100)
```

Where:
- `paid_on_time_count` = number of invoices with Approval Status "Approved" or payment status indicating timely payment.
- `total_invoices` = total number of invoices for this client in the P11 database.
- `currently_overdue_count` = number of invoices with a Due Date in the past and Approval Status not "Approved" (still outstanding).

The overdue penalty ensures that currently outstanding invoices have an immediate, significant impact beyond the historical ratio.

### Quick Reference Table

| Scenario | Base | Penalty | Final Score |
|----------|------|---------|-------------|
| 5/5 paid on time, 0 overdue | 100 | 0 | 100 |
| 4/5 paid on time, 0 overdue | 80 | 0 | 80 |
| 4/5 paid on time, 1 overdue | 80 | 20 | 60 |
| 3/5 paid on time, 1 overdue | 60 | 20 | 40 |
| 3/5 paid on time, 2 overdue | 60 | 40 | 20 |
| 2/5 paid on time, 2 overdue | 40 | 40 | 0 |
| 0 invoices | N/A | N/A | 75 (default) |

### Data Source

Query the "[FOS] Finance" Notion DB first, then "Founder OS HQ - Finance", filtering by `Type = "Invoice"`. Fall back to "Invoice Processor - Invoices" (legacy) if neither HQ database is found. Filter by vendor name or client name matching the current client. Retrieve:
- **Invoice #** (title): For identification.
- **Amount** (number): Invoice value.
- **Invoice Date** (date): When issued.
- **Due Date** (date): Payment deadline.
- **Approval Status** (select): Current status.

Match invoices to clients by comparing the Vendor property against the client's Company Name from the CRM. Use case-insensitive matching and handle common variations (e.g., "Acme Inc." vs "Acme, Inc." vs "ACME").

### Edge Cases

**No invoices in P11 DB**: When no invoice records match the client name:
- Set Payment score to 75 (neutral assumption).
- Do not add a risk flag. Absence of invoices may mean the client pays through other channels, has a different billing arrangement, or the relationship is non-transactional.

**Finance database unavailable**: When neither the "[FOS] Finance", "Founder OS HQ - Finance", nor the "Invoice Processor - Invoices" database is found in the Notion workspace:
- Set Payment score to 75 (neutral).
- Add note to Sources Used: "Invoice data unavailable."
- Do not add a risk flag.

**All invoices are recent (< 7 days old)**: When all invoices have Due Dates in the future:
- `currently_overdue_count` = 0. Score depends entirely on the historical on-time ratio.
- If all invoices are new and none have been paid yet, `paid_on_time_count` = 0 and `total_invoices` > 0, which would produce a score of 0. To avoid this false negative, exclude invoices whose Due Date is still in the future from the `total_invoices` count.

**Single invoice**: When only 1 invoice exists:
- If paid on time: score = 100.
- If overdue: score = max(100 - 20, 0) = 80 from base, but base would be 0 (0/1), so final = max(0 - 20, 0) = 0.
- Note: a single overdue invoice produces a score of 0. This is intentional -- a 100% overdue rate is a strong signal regardless of sample size.

---

## 5. Sentiment Score (Weight: 0.15)

Measure the overall sentiment of recent communications with the client.

### Delegation to Sentiment Analysis Skill

This metric is computed by the sentiment-analysis skill (sibling skill within this plugin). The client-health-scoring skill does not perform sentiment analysis directly. Instead:

1. Invoke the sentiment-analysis skill with the client's contact email addresses and a 90-day lookback window.
2. Receive a composite sentiment score on a 0-100 scale (0 = extremely negative, 50 = neutral, 100 = extremely positive).
3. Use the returned score directly as this metric's value. No additional transformation or decay is applied.

### Input to Sentiment Analysis

Provide the sentiment-analysis skill with:
- Client contact email addresses (from CRM Contacts).
- Lookback window: 90 days.
- Source priority: Gmail threads first, then Notion Communications if available.

### Edge Cases

**Sentiment analysis returns no data**: When the sentiment-analysis skill cannot compute a score (no qualifying communications found):
- Set Sentiment score to 50 (neutral default).
- Do not add a risk flag for missing sentiment data alone.

**Sentiment analysis skill unavailable**: If the sentiment-analysis skill file is missing or cannot be invoked:
- Set Sentiment score to 50 (neutral default).
- Add note to Sources Used: "Sentiment analysis unavailable."

**Extreme sentiment values**: The sentiment-analysis skill should return values in the 0-100 range. If a value outside this range is returned, clamp to 0-100 before applying the weight.

---

## Normalization Rules

Apply these normalization rules to all metric scores before computing the weighted composite:

1. **Range clamping**: Every metric score must fall within 0-100 inclusive. Clamp any computed value: `score = clamp(score, 0, 100)`.
2. **Integer rounding**: Round all metric scores to the nearest integer for display. Use the unrounded float value for composite calculation to preserve precision.
3. **Null handling**: If a metric cannot be computed at all (source unavailable and no default applies), use the neutral default for that metric (see edge cases above). Never leave a metric as null or undefined.
4. **Floor overrides**: The "New Client" floor of 40 on Last Contact applies after the exponential decay calculation but before the composite calculation.

### Normalization Order

For each metric, apply operations in this order:
1. Compute raw score from formula.
2. Apply edge case adjustments (new client floor, neutral defaults).
3. Clamp to 0-100.
4. Store as the metric score.
5. Multiply by weight for composite calculation.

---

## Edge Cases Summary Table

| Scenario | Last Contact | Response Time | Open Tasks | Payment | Sentiment | Risk Flags |
|----------|-------------|---------------|------------|---------|-----------|------------|
| Normal client, all data | Formula | Formula | Formula | Formula | From skill | Per conditions |
| New client (< 30 days) | max(formula, 40) | Formula | Formula | Formula | From skill | + New Client |
| No email history | 0 | 50 | Formula | Formula | 50 | + No Recent Contact |
| No invoices in P11 | Formula | Formula | Formula | 75 | From skill | None |
| P11 not installed | Formula | Formula | Formula | 75 | From skill | None (note added) |
| No tasks | Formula | Formula | 100 | Formula | From skill | None |
| No sentiment data | Formula | Formula | Formula | Formula | 50 | None |
| All data missing (CRM only) | 0 | 50 | 100 | 75 | 50 | + No Recent Contact |
| Calendar only, no email | Calendar date | 50 | Formula | Formula | 50 | Depends on calendar date |

### Minimum Viable Score

When all data is missing except the CRM record (worst-case neutral defaults):

```
composite = (0 × 0.25) + (50 × 0.20) + (100 × 0.20) + (75 × 0.20) + (50 × 0.15)
         = 0 + 10 + 20 + 15 + 7.5
         = 52.5
```

This places a data-poor client in the Yellow tier, which is the appropriate classification -- the client needs attention (in this case, data enrichment), but is not flagged as At Risk purely due to missing data.

Exception: when `days_since_contact` is known and high (30+ days), the composite can drop below 50 even with neutral defaults on other metrics, correctly placing the client in the Red tier due to confirmed inactivity.
