---
name: Sentiment Analysis
description: "Extracts sentiment signals from Gmail and Calendar data to compute a client sentiment score (0-100). Activates when the user wants to analyze client sentiment, check communication tone, detect sentiment shifts, or asks 'how's my relationship with this client?' Classifies signals as positive/neutral/negative and feeds into the broader health scoring pipeline."
---

## Overview

Extract sentiment signals from Gmail email threads and Google Calendar meeting patterns for a given client. Classify signals as positive, neutral, or negative. Compute a per-source numeric score, then combine into a single composite sentiment score on a 0-100 scale. Expose the composite score, per-source breakdowns, and a human-readable sentiment label (Positive, Neutral, Negative) for use by the Client Health Dashboard scoring pipeline.

This skill operates on raw Gmail and Calendar data -- it does not depend on pre-assembled dossiers. It produces a structured sentiment result that feeds into the broader client health scoring formula.

## Email Sentiment Analysis

Analyze the client's recent email communication to detect sentiment-bearing language and behavioral patterns.

### Data Collection

1. Search Gmail for threads involving the client's known email addresses (primary contact + any CC/BCC addresses from CRM).
2. Retrieve the last 10 email threads (sorted by most recent activity). Include both inbound and outbound messages in each thread.
3. When fewer than 10 threads exist, use all available threads. Record the actual thread count for confidence adjustment.

### Signal Detection

Scan each thread for positive and negative signal indicators. Count each signal once per thread -- do not double-count the same signal type within a single thread.

**Positive signals** (+1 each per thread):
- Gratitude language
- Forward-looking language
- Endorsement language
- Quick responses
- Expansion signals

**Negative signals** (-1 each per thread):
- Frustration language
- Escalation indicators
- Withdrawal patterns
- Delayed responses
- Complaint keywords in negative context
- Formality shift

For signal definitions, keyword lists, and detection criteria per signal type, see `${CLAUDE_PLUGIN_ROOT}/skills/health/sentiment-analysis/references/signal-patterns.md`.

### Net Score Calculation

1. Sum all positive signals across all scanned threads: `positive_count`.
2. Sum all negative signals across all scanned threads: `negative_count`.
3. Compute net email score: `net_email = positive_count - negative_count`.

### Classification and Numeric Mapping

| Net Email Score | Classification | Numeric Value |
|-----------------|----------------|---------------|
| >= +3           | Positive       | 85            |
| -2 to +2        | Neutral        | 50            |
| <= -3           | Negative       | 15            |

Record the classification, numeric value, positive_count, negative_count, and thread count in the sentiment result.

### Confidence Adjustment

When fewer than 3 email threads are available, append a confidence note: "Low email volume -- sentiment confidence reduced." The numeric value remains as calculated, but downstream consumers should weight this score lower or flag it for human review.

## Meeting Pattern Analysis

Analyze Google Calendar data to detect relationship health signals from meeting behavior over the last 90 days.

### Data Collection

1. Query Google Calendar for events where the client's known email addresses appear in the attendee list.
2. Scope the query to the last 90 days from today.
3. Collect: event titles, dates, durations, attendee lists, cancellation status, and organizer.
4. Group events into 30-day periods (current month, previous month, two months ago) for trend analysis.

### Frequency Trend Analysis

Compare meeting counts across 30-day periods:

| Trend | Criteria | Classification |
|-------|----------|----------------|
| Increasing | Current period count > previous period count by 20%+ | Positive |
| Stable | Current period count within 20% of previous period | Neutral |
| Declining | Current period count < previous period count by 20%+ | Negative |

When only one period has data (new client or sparse meetings), classify frequency as Neutral and note "Insufficient history for trend analysis."

### Behavioral Signal Detection

Scan meeting events for positive and negative behavioral signals.

**Positive meeting signals:**
- Client initiates meetings
- Senior stakeholders present
- Meeting duration stable or increasing
- Additional attendees joining
- Client shares agenda items
- Frequency increasing

**Negative meeting signals:**
- Cancellations (2+ in 30 days)
- No-shows (weight as -2)
- Meetings shortened
- Senior stakeholders dropped off
- Excessive rescheduling
- Client stops sharing agenda
- Frequency declining

For the full signal dictionary with detection criteria and thresholds, see `${CLAUDE_PLUGIN_ROOT}/skills/health/sentiment-analysis/references/signal-patterns.md`.

### Net Score Calculation

1. Sum all positive meeting signals: `meeting_positive_count`.
2. Sum all negative meeting signals (no-shows count as -2, all others as -1): `meeting_negative_count`.
3. Compute net meeting score: `net_meeting = meeting_positive_count - meeting_negative_count`.

### Classification and Numeric Mapping

| Net Meeting Score | Classification | Numeric Value |
|-------------------|----------------|---------------|
| >= +2             | Positive       | 85            |
| -1 to +1          | Neutral        | 50            |
| <= -2             | Negative       | 15            |

Note: Meeting signals use a tighter threshold than email (+-2 vs +-3) because meetings produce fewer total signals.

## Composite Scoring

Combine email and meeting sentiment into a single composite score.

### Weighting

| Source | Weight | Rationale |
|--------|--------|-----------|
| Email sentiment | 55% | Higher signal frequency, more granular language analysis |
| Meeting patterns | 45% | Reveals behavioral commitment and relationship trajectory |

### Formula

```
composite_score = (email_numeric * 0.55) + (meeting_numeric * 0.45)
```

Clamp the result to the range 0-100. Round to the nearest integer.

### Composite Classification

| Score Range | Label    |
|-------------|----------|
| >= 70       | Positive |
| 40-69       | Neutral  |
| < 40        | Negative |

### Output Structure

Return a structured sentiment result:

```
Sentiment Score: [composite_score]/100 ([label])
Email Sentiment: [email_classification] ([email_numeric]) -- [positive_count] positive, [negative_count] negative across [thread_count] threads
Meeting Sentiment: [meeting_classification] ([meeting_numeric]) -- [meeting_positive_count] positive, [meeting_negative_count] negative across [event_count] events
Weights Applied: Email 55%, Meeting 45%
Confidence Notes: [any applicable notes]
```

## Graceful Degradation

Handle missing data sources without failing the entire sentiment analysis.

| Scenario | Behavior |
|----------|----------|
| Gmail unavailable (MCP not connected) | Cannot compute sentiment. Return `null` for all sentiment fields. Report: "Gmail unavailable -- sentiment analysis requires email access." |
| Calendar unavailable (MCP not connected) | Use email-only scoring at 100% weight. Note: "Calendar unavailable -- using email-only sentiment." |
| No emails found for client | Return composite score of 50 (Neutral). Note: "No email history found -- defaulting to neutral sentiment." |
| No calendar events found for client | Use email-only scoring at 100% weight. Note: "No calendar events found -- using email-only sentiment." |
| Both sources return no data | Return composite score of 50 (Neutral). Note: "No communication data found -- defaulting to neutral sentiment." |

## Edge Cases

- **Mixed signals** (positive email + negative meetings or vice versa): Compute the weighted average as normal, but append "Mixed Sentiment Signals" to the output. Report both per-source classifications for transparency.
- **Very few emails** (<3 threads): Reduce confidence. Include note: "Low email volume -- sentiment confidence reduced."
- **New client** (<30 days of relationship): Include note: "New client -- limited sentiment data." Use available data without modification.
- **Formality shift detection**: Compare the tone of the 3 most recent emails to the 3 oldest in the 10-thread window. A shift from casual to formal (or vice versa) is a signal, not just the current tone.
- **Auto-generated emails**: Exclude automated messages (unsubscribe links, no-reply addresses, system notifications) from signal counting.
- **Large threads**: In threads with 10+ messages, scan only the 5 most recent messages to avoid over-counting stale signals.

