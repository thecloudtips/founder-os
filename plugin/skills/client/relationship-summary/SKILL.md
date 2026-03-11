---
name: Relationship Summary
description: "Produces executive relationship summaries with health scores, sentiment analysis, and engagement metrics. Activates when the user wants a client brief, relationship assessment, engagement check, or asks 'how's our relationship with [client]?' Covers sentiment scoring, risk flagging, health formula calculation, and executive brief formatting."
globs:
  - "teams/agents/context-lead.md"
  - "commands/client-brief.md"
---

## Overview

Assess client relationship health and generate structured executive summaries from aggregated client data. Transform raw dossier data into actionable intelligence: sentiment scores, engagement levels, risk flags, and a composite health score. Produce concise 1-page briefs suitable for pre-meeting preparation or portfolio review. This skill operates on the output of the client-context skill -- it consumes assembled dossier data, not raw source data.

## Sentiment Scoring

Evaluate overall client sentiment on a 3-level scale (Positive, Neutral, Negative) by analyzing signals from multiple data dimensions.

### Email Sentiment Signals

Scan the last 10 email exchanges for these indicators:

**Positive signals** (+1 each):
- Gratitude language: "thank you", "appreciate", "great work", "excellent"
- Forward momentum: "excited about", "looking forward to", "let's proceed"
- Endorsement: "highly recommend", "impressed with", "exceeded expectations"
- Responsiveness: average response time under 4 hours

**Negative signals** (-1 each):
- Frustration language: "disappointed", "concerned", "unacceptable", "still waiting"
- Escalation indicators: "need to escalate", "speak with your manager", "not acceptable"
- Withdrawal: declining response rate, shorter replies, fewer initiations from client
- Delayed responses: average response time over 48 hours

**Neutral**: Absence of both strong positive and negative signals. Professional, transactional tone.

Calculate net sentiment score: sum of positive signals minus sum of negative signals.
- Net score ≥ +3: **Positive**
- Net score between -2 and +2: **Neutral**
- Net score ≤ -3: **Negative**

### Meeting Sentiment Signals

Analyze calendar and notes data for relationship tone:

**Positive**: Meeting frequency increasing or stable, client initiates meetings, meetings include senior stakeholders, meeting notes record enthusiasm or expansion discussions.

**Negative**: Meeting frequency declining, cancellations or no-shows, meetings shortened, escalation meetings scheduled, meeting notes record friction or complaints.

### Deal Sentiment Signals

Analyze deal pipeline data:

**Positive**: Deal advancing through stages, close date holding or moving closer, deal value increasing, multiple active deals.

**Negative**: Deal stalled in same stage >30 days, close date pushed back repeatedly, deal value reduced, deals moved to Closed Lost.

### Combined Sentiment

Weight the three dimensions:
- Email sentiment: 40% (most frequent signal source)
- Meeting sentiment: 35% (reveals relationship quality)
- Deal sentiment: 25% (reflects commercial health)

Calculate weighted average. Report both the combined sentiment level and the individual dimension sentiments for transparency.

## Engagement Level Metrics

Classify engagement as High, Medium, or Low based on contact frequency and interaction quality.

### Contact Frequency Scoring

Measure interactions per month across all channels (email threads + meetings + logged calls) over the last 90 days:

| Interactions/Month | Score |
|-------------------|-------|
| ≥ 8 | High |
| 3-7 | Medium |
| 0-2 | Low |

### Interaction Quality Indicators

Adjust engagement level based on quality signals:

**Upgrade by one level** when any of the following hold:
- Client initiates ≥50% of interactions
- Meetings include C-level or VP-level attendees
- Active deal in Proposal or Negotiation stage
- Client shares documents proactively

**Downgrade by one level** when any of the following hold:
- User initiates ≥80% of interactions (one-sided relationship)
- No meeting in the last 60 days
- All deals are stalled or in early stages only
- No response to last 2+ outreach attempts

### Engagement Trend

Compare current 30-day interaction count to previous 30-day count:
- Current > Previous × 1.2: **Increasing**
- Current between Previous × 0.8 and Previous × 1.2: **Stable**
- Current < Previous × 0.8: **Declining**

Report both the current engagement level and the trend direction.

## Risk Flag Criteria

Scan for risk indicators that warrant attention. Each flag includes a severity level (Critical, Warning, Info) and recommended action.

### Critical Risks (Immediate Attention)

- **No contact in 60+ days**: Last interaction across all channels exceeds 60 days. Action: Schedule outreach immediately.
- **Deal lost or churned**: A deal moved to Closed Lost or company status changed to Churned in the last 30 days. Action: Conduct loss review and determine win-back strategy.
- **Negative sentiment trend**: Sentiment dropped from Positive or Neutral to Negative in the last 30 days. Action: Schedule relationship review meeting.
- **Escalation detected**: Email or notes contain escalation language in the last 14 days. Action: Address escalation source directly.

### Warning Risks (Monitor Closely)

- **Declining engagement**: Engagement trend is Declining for 2+ consecutive months. Action: Increase touchpoint frequency.
- **Overdue action items**: 3+ open items past their implied deadline. Action: Prioritize and resolve or communicate delays.
- **Deal stall**: Active deal has not changed stage in 30+ days. Action: Review deal strategy and identify blockers.
- **Single-threaded relationship**: Only 1 contact at the client company. Action: Expand stakeholder map.
- **Stale CRM data**: Most recent CRM Communication entry is 90+ days old while other sources show activity. Action: Update CRM records.

### Info Flags (Awareness)

- **New stakeholder**: A new email address or calendar attendee appeared in the last 30 days. Action: Research and add to CRM.
- **Contract approaching renewal**: Deal close date or contract end date within 60 days. Action: Begin renewal preparation.
- **High document activity**: 3+ documents modified in the last 14 days. Action: Review for deliverable deadlines.

## Health Score Formula

Calculate a composite Client Health Score on a 0-100 scale. This score is written back to the Companies database's "Client Health Score" property.

### Component Scores (each 0-100)

| Component | Weight | Calculation |
|-----------|--------|-------------|
| Contact Recency | 0.25 | 100 if last contact ≤7 days, 75 if ≤14 days, 50 if ≤30 days, 25 if ≤60 days, 0 if >60 days |
| Response Quality | 0.20 | 100 if avg response <4h, 75 if <12h, 50 if <24h, 25 if <48h, 0 if >48h |
| Engagement Level | 0.20 | High=100, Medium=60, Low=20 |
| Deal Progress | 0.15 | 100 if deal advancing, 60 if stable, 20 if stalled, 0 if lost/no deal |
| Task Completion | 0.10 | 100 if 0 overdue items, 75 if 1 overdue, 50 if 2 overdue, 25 if 3+, 0 if 5+ overdue |
| Sentiment | 0.10 | Positive=100, Neutral=60, Negative=20 |

**Formula**: Health Score = Σ (Component Score × Weight)

### Score Interpretation

| Score Range | Label | Color | Meaning |
|-------------|-------|-------|---------|
| 80-100 | Excellent | Green | Strong, active relationship |
| 60-79 | Good | Blue | Healthy with minor attention areas |
| 40-59 | Fair | Yellow | Needs proactive engagement |
| 20-39 | At Risk | Orange | Significant issues, intervention needed |
| 0-19 | Critical | Red | Relationship in danger, immediate action required |

## Executive Brief Template

Generate 1-page executive summaries using this standardized structure. Keep each section concise -- the entire brief should fit in approximately 500 words.

### Brief Structure

```
# Client Brief: [Company Name]
Generated: [date] | Health Score: [score]/100 ([label]) | Completeness: [score]

## Profile
[Company name] | [Industry] | [Size] | [Status]
Primary Contact: [Name] ([Role]) | [Email]
Relationship Owner: [User name] | Tenure: [N] months
Active Deals: [Count] | Total Value: [Sum]

## Recent Activity (Last 30 Days)
- [Date]: [Interaction type] - [Brief summary]
- [Date]: [Interaction type] - [Brief summary]
- [Date]: [Interaction type] - [Brief summary]
(Show up to 5 most recent interactions)

## Open Items
- [ ] [Action item 1] (Source: [email/notes/CRM])
- [ ] [Action item 2] (Source: [email/notes/CRM])
(Show all open items, max 10)

## Upcoming
- [Date]: [Meeting/milestone description]
- [Date]: [Deal deadline or renewal date]
(Show next 30 days of scheduled events and deadlines)

## Sentiment & Risk
Sentiment: [Positive/Neutral/Negative] ([trend direction])
Engagement: [High/Medium/Low] ([trend direction])
Risk Flags: [List any active flags with severity]

## Key Documents
- [Doc title] ([type], modified [date])
- [Doc title] ([type], modified [date])
(Show 3 most recent relevant documents)
```

### Brief Generation Rules

- Populate every section from the assembled dossier data. When a section has no data, include the section header with "No data available" rather than omitting it.
- Lead with the most actionable information: risk flags and open items are more important than historical data.
- Use bullet points, not paragraphs. Executives scan, they do not read.
- Include the completeness score to signal data confidence. A brief with completeness < 0.5 should include a warning: "Low data confidence -- some sections may be incomplete."
- Date format: use relative dates for recent items ("2 days ago", "last week") and absolute dates for items > 14 days old.

## CRM Enrichment Writeback

After generating the dossier and calculating health metrics, write calculated values back to the Companies page that holds the dossier. Because the dossier now lives on the Companies page itself (see client-context skill's Database Discovery Order), enrichment writeback targets the SAME page -- no separate lookup needed.

- **Companies → Client Health Score**: Write the composite health score (0-100) on the same Companies page where the dossier was stored.
- **Companies → Dossier, Dossier Completeness, Dossier Generated At, Dossier Stale**: Updated as part of dossier caching (see client-context skill).
- **Deals → Risk Level**: Set to "High" if deal is stalled + engagement declining, "Medium" if either condition, "Low" otherwise.
- **Communications → Sentiment**: For the most recent Communication entry, update sentiment based on email sentiment analysis (Positive/Neutral/Negative).

Only write enrichments when match confidence is ≥ 0.8. Never overwrite manually-entered CRM data -- only update fields that are empty or were previously set by this plugin (track by adding "[Auto]" prefix to sentiment values).

## Edge Cases

### No Prior Relationship Data
When assembling a brief for a new prospect with minimal data (completeness < 0.3), adapt the template: replace "Recent Activity" with "Discovery Notes", replace "Open Items" with "Recommended Next Steps", and include onboarding suggestions.

### Conflicting Sentiment Signals
When email sentiment is Positive but deal sentiment is Negative (or vice versa), report the conflict explicitly. Do not average away the discrepancy. Present both signals and flag for human review: "Mixed signals detected -- email tone is positive but deal has stalled."

### Multiple Active Deals
When a client has 3+ active deals, calculate Deal Progress as the weighted average (by deal value) of individual deal scores. Report the health of each deal separately in the brief's Profile section.

### Recently Churned Client
When company status is "Churned" but recent email/calendar activity exists, flag as potential re-engagement opportunity. Adjust the brief template to include a "Re-engagement Opportunity" section with the trigger signals.
