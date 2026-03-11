---
name: Talking Points
description: "Generates framework-based talking points and discussion guides tailored to meeting type. Activates for talking point requests, discussion guides, meeting agendas, or 'what should I bring up in this meeting?' Selects from SPIN, GROW, SBI, and other frameworks based on meeting classification, with 'Do NOT Mention' guardrails and context-aware customization."
globs:
  - "commands/prep.md"
  - "commands/prep-today.md"
  - "teams/agents/prep-lead.md"
---

## Overview

Generate structured, framework-based talking points and discussion guides for meetings. Select the appropriate conversational framework based on meeting type, produce 3-5 actionable talking points per meeting, build an opener and close structure, and customize output based on CRM deal stage, relationship status, and pending items. Consume meeting context data (attendee profiles, open items, recent communications) produced upstream in the pipeline and transform it into a ready-to-use discussion guide.

## Framework Selection by Meeting Type

Map every meeting to exactly one framework. Use the meeting type classification from the meeting-context skill as input. Never blend frameworks -- pick one and apply it consistently.

| Meeting Type | Framework | Core Structure |
|-------------|-----------|---------------|
| external-client | SPIN | Situation, Problem, Implication, Need-payoff |
| one-on-one | GROW | Goal, Reality, Options, Way-forward |
| internal-sync | SBI | Situation, Behavior, Impact |
| ad-hoc | Context-Gathering | Open questions to establish purpose and alignment |
| recurring | Delta-Based Agenda | What changed, what is blocked, what is next |
| group-meeting | Contribution Mapping | Who owns what, expected inputs, decision points |

When a meeting could match multiple types, defer to the type already classified upstream. Do not reclassify.

## Framework Details

### SPIN (external-client)

Structure talking points to guide client conversations from discovery through actionable outcomes.

**Situation** -- Establish shared context. Reference known facts: active deals, project milestones, contract status, last interaction. Frame as confirmation questions, not assumptions. Example: "Confirm the current timeline for the Q2 launch -- last discussed on [date]."

**Problem** -- Surface pain points or blockers. Reference open items, overdue deliverables, or flagged risks. Frame as open-ended questions. Example: "Ask what the biggest blocker is for [deliverable] this week."

**Implication** -- Quantify the cost of inaction. Connect problems to business impact using deal value, timeline data, or risk flags. Example: "If the [deliverable] delay extends past [date], how does that affect [downstream milestone]?"

**Need-payoff** -- Propose solutions and next steps. Lead with actions the user can offer, not demands of the client. Example: "Propose accelerating the review cycle to recover 1 week on the timeline."

### GROW (one-on-one)

Structure talking points to facilitate coaching or alignment conversations.

**Goal** -- Define the meeting's purpose. Reference the attendee's objectives, project assignments, or previously stated goals. Example: "Check in on progress toward the [quarterly goal] discussed on [date]."

**Reality** -- Assess current state honestly. Surface task completion rates, blockers, feedback received, and items from the last one-on-one. Example: "Review the 3 action items from the last 1:1 -- which are complete, which are blocked?"

**Options** -- Explore 2-3 alternative approaches to current challenges. Frame as collaborative brainstorming, not directives. Example: "Consider whether to prioritize [task A] over [task B] given current constraints."

**Way-forward** -- Commit to specific next steps with owners and deadlines. Every one-on-one must end with at least one concrete commitment from each participant. Example: "Agree on 2 deliverables for next week and set check-in dates."

### SBI (internal-sync)

Structure talking points around observable situations and their impact.

**Situation** -- State the specific context: sprint, project phase, deadline, or event. Be concrete about time and scope. Example: "We are 3 days from the [milestone] deadline with 4 open items remaining."

**Behavior** -- Describe observable actions or outcomes without judgment language. Reference shipped features, completed tasks, or missed deadlines. Example: "The API integration shipped Tuesday and handles [N] requests/day."

**Impact** -- Connect behavior to team or project outcomes. Quantify downstream effects, velocity changes, or risk exposure. Example: "The early delivery unblocked the frontend team -- integration started 2 days ahead of plan."

### Context-Gathering (ad-hoc)

Generate 3-5 open-ended questions in this order:
1. **Purpose**: "What outcome would make this meeting successful for you?"
2. **Background**: "What context should I know that may not be in the invite?"
3. **Constraints**: "Are there deadlines, dependencies, or decisions driving this meeting?"
4. **Stakeholders**: "Who else has a stake in what we discuss?"
5. **Next steps expectation**: "What follow-up do you expect after this meeting?"

When attendee context is available from CRM or email, weave it into the questions -- do not ask for information already known.

### Delta-Based Agenda (recurring)

Generate talking points in three categories:
1. **What changed**: New developments, completed items, status changes since last meeting.
2. **What is blocked**: Items expected to progress but stalled. Reference specific tasks, owners, and blockers.
3. **What is next**: Upcoming deadlines and decisions needed before the next occurrence. Date-bound items only.

Scan notes from the previous occurrence. Carry unresolved items forward. Flag items appearing in 3+ consecutive occurrences as "stale recurring" and recommend resolution or removal.

### Contribution Mapping (group-meeting)

Generate a contribution map for meetings with 4+ attendees:
1. **Decision owner**: Who has final authority. If unknown, flag as a question for the opener.
2. **Input providers**: Each attendee with the specific update they are expected to provide.
3. **Decision points**: 2-3 specific decisions phrased as yes/no or option-A-vs-B choices.
4. **Parking lot**: 1-2 related topics to defer and avoid scope creep in a large group.

## Generation Rules

### Quantity and Structure

- Generate exactly 3-5 talking points per meeting. Fewer than 3 signals insufficient preparation; more than 5 creates cognitive overload.
- Start every talking point with an action verb: Confirm, Review, Discuss, Propose, Ask, Align, Decide, Explore, Surface, Escalate.
- Keep each talking point to 1-2 sentences. First sentence states the action; second provides context.
- Number talking points and order by priority: highest-impact first.

### "Do NOT Mention" Items

Generate a "Do NOT mention" list when any of these conditions are detected:

- **Active negotiation**: Deal in Negotiation stage -- do NOT mention competitor pricing, internal cost structures, or discount thresholds.
- **Unconfirmed information**: Low-confidence data from a single unverified source -- do NOT present as fact.
- **Sensitive personnel matters**: Performance, compensation, or HR items in a 1:1 -- do NOT raise in group settings or with third parties.
- **Premature announcements**: Upcoming changes (reorgs, launches, partnerships) not yet public -- do NOT disclose.
- **Cooling or dormant relationships**: Do NOT reference the communication gap directly. Frame re-engagement positively: "Lead with new value."
- **Lost deals or churned accounts**: Do NOT reference the loss unless the meeting is explicitly a post-mortem.

Place the list after talking points, clearly separated with a warning label. Omit the section entirely when no items apply.

## Open/Close Structure

### Suggested Opener

Generate a 1-2 sentence opener tailored to meeting type:

| Meeting Type | Opener Pattern |
|-------------|---------------|
| external-client | Acknowledge the client's time, reference a recent milestone, state the objective. |
| one-on-one | Genuine check-in question, then transition to first agenda item. |
| internal-sync | State the time box and 2-3 items to cover, invite additions. |
| ad-hoc | State your understanding of the purpose, ask for confirmation. |
| recurring | Summarize the top delta since last meeting in one sentence, transition to agenda. |
| group-meeting | State the objective and expected output, walk through the agenda. |

When relationship status is Dormant or Cooling, open with fresh value (insight, resource, offer) rather than a backward-looking reference.

### Proposed Next Steps

Generate 2-3 concrete next steps for the meeting's close. Each must include:
- **Action**: Verb + object.
- **Owner**: Name (not "someone").
- **Deadline**: Specific date or "by next [meeting cadence]".

### Meeting Close

Generate a 1-sentence close that summarizes the key outcome and confirms the next interaction (meeting date, follow-up email, or deliverable deadline).

## Context-Aware Customization

Apply all applicable adjustments -- they stack.

### Deal Stage Adjustments

| Deal Stage | Adjustment |
|-----------|-----------|
| Lead / Qualified | Focus on discovery and needs assessment. Ask more than you propose. |
| Proposal | Focus on differentiators and value quantification. Reference proposal elements. |
| Negotiation | Focus on terms, timeline, mutual commitments. Avoid introducing new scope. |
| Closed Won | Focus on kickoff logistics, onboarding, expectation setting. |
| Closed Lost | Post-mortem only. Focus on lessons learned and future opportunities. |

### Relationship Status Adjustments

| Status | Adjustment |
|--------|-----------|
| Active (<30 days) | Reference recent interactions. Build continuity: "Following up on our [last interaction]..." |
| Cooling (30-90 days) | Re-establish rapport first. Lead with value. Do NOT reference the time gap. |
| Dormant (>90 days) | Treat as near-fresh. Provide context on who you are. Bring a specific reconnection reason. |

### Unanswered Items

- User owes a response: Add a talking point to address proactively. "Provide the update on [topic] that [attendee] requested on [date]."
- Attendee owes a response: Follow up diplomatically. "Check in on the status of [item] -- last discussed on [date]."
- Items overdue 14+ days: Escalate priority. Place follow-up in position 1 or 2.

## Output Format

```markdown
## Discussion Guide: [Meeting Title]
**Framework**: [Framework Name] ([Meeting Type])
**Date**: [meeting date and time]
**Attendees**: [comma-separated names]

### Opener
[1-2 sentence suggested opener]

### Talking Points
1. **[Action verb] [topic]** -- [1-2 sentence context and rationale]
2. **[Action verb] [topic]** -- [1-2 sentence context and rationale]
3. **[Action verb] [topic]** -- [1-2 sentence context and rationale]

### Do NOT Mention
> The following topics should be avoided in this meeting:
> - [Item with rationale]
> - [Item with rationale]

### Proposed Next Steps
- [ ] [Action] -- Owner: [name] -- By: [date]
- [ ] [Action] -- Owner: [name] -- By: [date]

### Close
[1-sentence summary and next interaction confirmation]
```

## Edge Cases

### No Context Data Available
When upstream data is minimal (no CRM match, no email history, no notes), fall back to the context-gathering framework regardless of detected meeting type. Note in output: "Limited context available -- discussion guide uses context-gathering questions."

### Conflicting Signals
When CRM indicates a healthy relationship but emails show frustration or escalation language, prioritize the negative signal. Lead with a talking point that addresses the concern. Add a "Do NOT mention" item for positive metrics that could seem dismissive.

### Very Short Meetings (15 minutes or less)
Reduce talking points to exactly 2. Drop "Do NOT mention" unless a critical item applies. Compress the opener to one sentence.

### Large Group with Unknown Attendees
When 50%+ of attendees have no CRM or email context, switch to contribution-mapping regardless of original type. Focus on establishing who is present and what they need.

### Recurring Meeting with No Prior Notes
Treat as ad-hoc for talking point purposes. Generate context-gathering questions alongside the delta structure. Recommend establishing a shared notes document.

### Back-to-Back Meetings with Same Attendee
Do not repeat the same items. Assign each item to the more appropriate meeting context and reference the other: "Defer [topic] to the [next meeting title] discussion."
