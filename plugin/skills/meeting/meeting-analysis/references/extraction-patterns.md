# Extraction Pattern Library

Complete detection pattern lists for meeting transcript analysis. Covers decision detection, follow-up commitment extraction, topic identification, and disagreement flagging. These patterns are referenced by the meeting-analysis SKILL.md and are too verbose for inline inclusion.

---

## 1. Decision Detection Patterns

Scan transcript text for language indicating that a choice has been made, a direction has been set, or a group has reached alignment. Patterns are organized by confidence tier.

### 1.1 Explicit Decision Phrases

These phrases signal a resolved decision with high confidence. When detected, set `confidence: "Explicit"` on the decision record.

**Direct resolution statements:**
- "We decided to..."
- "The decision is..."
- "Final decision:..."
- "We agreed on..."
- "We're going to..."
- "The plan is to..."

**Action commitment statements:**
- "Let's go with..."
- "We'll go ahead with..."
- "Going forward, we..."
- "We'll go ahead and..."
- "We'll proceed with..."
- "Let's move forward with..."

**Confirmation statements:**
- "That's settled then."
- "So that's what we'll do."
- "Confirmed -- we're doing [X]."
- "Locked in."
- "That's final."

**Approval gate language:**
- "Approved."
- "Green light on [X]."
- "Signed off on [X]."
- "We're giving the go-ahead for..."

### 1.2 Inferred Consensus Phrases

These phrases suggest a decision was reached through implicit agreement rather than explicit declaration. Set `confidence: "Inferred"` on the decision record. Inferred decisions require additional context validation (see Section 1.4).

**Passive agreement:**
- "So we'll..." (without an explicit vote or confirmation round)
- "I think everyone agrees..."
- "Sounds like we're aligned on..."
- "Looks like we're all on the same page about..."
- "I don't think anyone objects to..."

**Objection-absent closure:**
- "No objections? Okay..."
- "Any pushback? ... Alright."
- "Moving on then..."
- "Unless anyone has concerns, we'll..."
- "If no one objects..."

**Topic-concluding consensus:**
- Context: A participant makes a proposal, no dissent is voiced, and the discussion shifts to a new topic. The proposal is treated as an inferred decision.
- Context: The meeting facilitator restates a position and moves the agenda forward. The restated position is treated as an inferred decision.
- Context: A participant says "Okay" or "Alright" after another participant's proposal and immediately introduces a new subject.

### 1.3 Disagreement Markers

When these phrases appear near a decision statement (within 3 speaker turns before or after), flag the decision with `disputed: true` and capture the dissenting position in the `dissent` field.

**Direct disagreement:**
- "I disagree with..."
- "I disagree."
- "I don't think that's the right approach."
- "That won't work because..."
- "I'm against..."

**Hesitation and concern:**
- "I'm not sure about that..."
- "Can we reconsider..."
- "I have concerns about..."
- "My concern is..."
- "I'd prefer..."
- "I'm not comfortable with..."

**Counter-proposals:**
- "Alternative proposal:..."
- "What if instead we..."
- "I'd suggest a different approach..."
- "Another option would be..."
- "Have we considered..."

**Conditional objections:**
- "That works only if..."
- "I'm okay with that as long as..."
- "My only concern is..."
- "I can live with that, but..."

#### Disagreement Proximity Rule

Only flag a decision as disputed when disagreement markers appear within a 3-turn window of the decision phrase. Disagreement earlier in the meeting (before the decision was proposed) does not count unless it explicitly references the same topic. This prevents stale objections from a brainstorming phase from tagging a later consensus decision.

### 1.4 Context Validation for Inferred Decisions

Inferred decisions carry higher false-positive risk. Apply these validation checks before including an inferred decision in the output.

| Validation Check | Pass Criteria | Fail Action |
|-----------------|---------------|-------------|
| Proposal exists | A specific, actionable proposal precedes the consensus phrase | Drop candidate -- no decision to infer |
| No subsequent contradiction | No speaker reverses the proposal within 5 turns | Drop candidate -- consensus did not hold |
| Topic transition | Discussion moves to a new subject after the consensus phrase | Supports inference -- group treated it as resolved |
| Multiple participants | At least 2 distinct speakers were involved in the topic | Supports inference -- not a monologue |
| Not a question | The consensus phrase is not followed by "?" or "right?" | Drop candidate -- speaker is asking, not deciding |

An inferred decision must pass "Proposal exists" AND "No subsequent contradiction" to be included. The remaining checks are confidence boosters.

### 1.5 Decision Record Schema

For each detected decision, produce a record with these fields:

```
decision:
  decision_text: "Clear, standalone statement of what was decided"
  proposer: "Name of the person who proposed or announced the decision"
  context: "1-2 sentences of surrounding discussion that led to the decision"
  confidence: "Explicit" | "Inferred"
  disputed: true | false
  dissent: "Summary of dissenting position, or null if no disagreement"
```

Field rules:
- **decision_text**: Rewrite the raw transcript into a clean, third-person statement. "Let's go with tiered pricing" becomes "Go with tiered pricing starting Q2." Include temporal context (dates, quarters) when available.
- **proposer**: Use the speaker label from the transcript. When multiple participants co-develop the decision, credit the person who made the final statement. Set to "Group" only when no individual attribution is possible.
- **context**: Summarize the discussion that led to the decision, not the decision itself. Focus on the problem being solved or the alternatives considered.
- **disputed**: Set to `true` when any disagreement marker (Section 1.3) appears within the 3-turn proximity window. Set to `false` otherwise.
- **dissent**: When `disputed` is `true`, capture the dissenting position factually. Do not editorialize on who was right. When `disputed` is `false`, set to `null`.

### 1.6 Common False Positives

These patterns match decision language but are not actual decisions. Exclude them.

| Pattern | Example | Why It Is Not a Decision |
|---------|---------|--------------------------|
| Hypothetical | "If we decide to go with..." | Conditional, not resolved |
| Historical reference | "Last time we decided to..." | Past decision, not new |
| Question | "Should we go with option A?" | Asking, not deciding |
| Reporting another group's decision | "The board decided to..." | Attribution, not this meeting's decision |
| Sarcastic or humorous | "Well, we've clearly decided to never finish this" | Not a genuine resolution |
| Future conditional | "We'll decide on that next week" | Deferred, not current |

---

## 2. Follow-Up Commitment Patterns

Detect actionable commitments where a person accepts or is assigned a task. Each commitment maps to a `promise_type` for compatibility with #06 Follow-Up Tracker.

### 2.1 Self-Assignment Patterns

The speaker commits themselves to a task. Set `promise_type: "Promise Made"` (maps to #06 "Promise Made"). The `who` field is the speaker, and `mentioned_by` is also the speaker.

**Direct self-commitment:**
- "I'll [verb]..."
- "I'm going to [verb]..."
- "I will [verb]..."
- "I can handle [task]..."
- "Let me [verb]..."
- "I'll take care of..."
- "I'll follow up on..."
- "I'll make sure [task] gets done."
- "I'm on it."
- "Consider it done."

**Self-commitment with deadline:**
- "I'll have [task] done by [date]."
- "I'll get [task] to you by [day]."
- "I can do [task] by [timeframe]."
- "Give me until [date] and I'll [verb]."

**Self-commitment with handoff:**
- "I'll [verb] and then send it to [Name]."
- "I'll [verb] and loop you in."
- "I'll draft it and send it over for review."

### 2.2 Delegation Patterns

The speaker assigns a task to another named participant. Set `promise_type: "Promise Received"` (maps to #06 "Promise Received"). The `who` field is the assignee, and `mentioned_by` is the speaker.

**Direct delegation:**
- "[Name] will [verb]..."
- "[Name], can you [verb]..."
- "[Name] is going to..."
- "[Name], please [verb]..."
- "[Name] to [verb]..." (shorthand common in meeting notes)
- "Can [Name] take on [task]..."
- "[Name], would you mind [verb]..."

**Implied delegation:**
- "[Name], that's on your plate."
- "[Name], you're handling [task], right?"
- "[Name], can you own this?"
- "I think [Name] is best positioned to [verb]."

**Delegation with deadline:**
- "[Name], can you have [task] done by [date]?"
- "[Name], I need [task] by [day]."
- "Let's have [Name] deliver [task] by [date]."

### 2.3 Request Patterns (No Named Assignee)

The speaker identifies a task without naming a specific person. Set `promise_type: "Promise Received"` with `who: "Unassigned"`. Flag these for follow-up, as they risk being dropped.

**General requests:**
- "Can someone [verb]..."
- "We need someone to..."
- "Someone should [verb]..."
- "This needs to be done by..."
- "Somebody needs to handle [task]."

**Action item declarations:**
- "Action item: [task]."
- "To-do: [task]."
- "Follow-up item: [task]."
- "We need to [verb] before [date]."

**Group commitments:**
- "We should [verb]..."
- "We need to [verb]..."
- "Let's make sure we [verb]..."
- "As a team, we need to [verb]..."

Note: Group commitments ("We should...") are lower confidence than named commitments. Include them only when the statement is accompanied by a deadline or is made by a person in a leadership/facilitation role. Generic aspirational statements ("We should really get better at testing") are not commitments.

### 2.4 Deadline Parsing

When temporal language accompanies a commitment, parse it to an ISO date relative to the meeting date.

| Temporal Expression | Resolution Rule | Example (meeting date: 2026-03-05) |
|--------------------|-----------------|------------------------------------|
| "by [specific date]" | Parse the date directly | "by March 10" -> `2026-03-10` |
| "by end of day" / "by EOD" | Meeting date | `2026-03-05` |
| "by end of week" / "by EOW" | Friday of the meeting's week | `2026-03-06` |
| "by next [weekday]" | Next occurrence of that weekday after the meeting date | "by next Tuesday" -> `2026-03-10` |
| "ASAP" | Meeting date + 1 day | `2026-03-06` |
| "today" | Meeting date | `2026-03-05` |
| "tomorrow" | Meeting date + 1 day | `2026-03-06` |
| "this week" | Friday of the meeting's week | `2026-03-06` |
| "next week" | Friday of the following week | `2026-03-13` |
| "in [N] days" | Meeting date + N | "in 3 days" -> `2026-03-08` |
| "within [N] weeks" | Meeting date + (N * 7) | "within 2 weeks" -> `2026-03-19` |
| "by end of month" / "by EOM" | Last day of the meeting's month | `2026-03-31` |
| "by end of quarter" / "by EOQ" | Last day of the meeting's quarter | `2026-03-31` |
| "next month" | Last day of the following month | `2026-04-30` |
| No deadline mentioned | `null` | — |

#### Ambiguous Deadline Handling

- When "next [weekday]" is the same day as the meeting date, interpret as the weekday in the following week.
- When "this [weekday]" has already passed in the current week, interpret as next week.
- When a deadline is genuinely ambiguous ("sometime soon", "when you get a chance"), set deadline to `null` and preserve the original phrase in `promise_text` for human interpretation.

### 2.5 Commitment Record Schema

For each detected follow-up, produce a record with these fields:

```
commitment:
  who: "Person responsible for the commitment"
  what: "Clean task description stripped of conversational filler"
  deadline: "YYYY-MM-DD" | null
  mentioned_by: "Person who stated or assigned the commitment"
  promise_type: "Promise Made" | "Promise Received"
  promise_text: "Verbatim commitment phrase from the transcript"
  source: "Meeting Transcript"
```

Field rules:
- **who**: Resolve "I'll" and "I'm going to" to the speaker's name using transcript labels. When the transcript lacks speaker labels, set to "Unknown Speaker".
- **what**: Strip filler words, hedging language, and conversational artifacts. "Yeah so I'll probably, um, send over the updated pricing deck" becomes "Send updated pricing deck." Use imperative voice.
- **deadline**: Apply the parsing rules from Section 2.4. Always produce an ISO date or `null`.
- **mentioned_by**: In self-assignment, this matches `who`. In delegation, this is the person doing the delegating.
- **promise_text**: Preserve the exact words from the transcript for audit trail purposes.

### 2.6 Commitment False Positives

Exclude these patterns that resemble commitments but are not actionable tasks.

| Pattern | Example | Why It Is Not a Commitment |
|---------|---------|----------------------------|
| Past tense | "I sent the report yesterday." | Already completed, not a future commitment |
| Hypothetical | "I would send the report if..." | Conditional, not a commitment |
| Suggestion without ownership | "It would be nice to update the docs." | Aspiration, no assignee or deadline |
| Reporting on others | "The vendor will send the invoice." | External party, not a meeting participant |
| Negation | "I won't be able to handle that this week." | Explicitly declining, not committing |
| Question | "Should I send the pricing deck?" | Asking for permission, not committing |

---

## 3. Topic Extraction Heuristics

Identify 3-7 tags that characterize the meeting's substantive content. Topics describe what was discussed, not how the meeting was conducted.

### 3.1 Noun Phrase Frequency Method

The primary extraction approach uses frequency-weighted noun phrase detection.

**Steps:**

1. **Segment**: Split the transcript into individual sentences (use period, question mark, exclamation mark, and speaker label changes as boundaries).
2. **Extract noun phrases**: Identify 2-4 word noun phrases in each sentence. Look for patterns: [Adjective]* [Noun]+, [Proper Noun] [Noun], and [Noun] [Noun] compounds.
3. **Count frequency**: Tally how many sentences contain each noun phrase. Weight by speaker diversity -- a phrase used by 3 different speakers scores higher than the same frequency from 1 speaker.
4. **Filter**: Remove stop phrases (see Section 3.2) and generic terms.
5. **Consolidate**: Merge similar phrases (see Section 3.3).
6. **Rank**: Sort by weighted frequency. Select the top 3-7.

**Speaker diversity weighting:**

```
weighted_score = raw_frequency * (1 + (0.2 * (unique_speakers - 1)))
```

A phrase mentioned 5 times by 1 speaker scores `5 * 1.0 = 5.0`. The same phrase mentioned 5 times across 3 speakers scores `5 * 1.4 = 7.0`. This prioritizes topics that engaged multiple participants over topics one person repeated.

### 3.2 Stop Phrases

Never use these as topic tags. They describe meeting mechanics, not meeting content.

**Time references:**
- "this week", "next week", "last time", "last week", "this month", "next month"
- "today", "tomorrow", "yesterday", "this morning", "this afternoon"

**Meeting meta-language:**
- "the meeting", "the agenda", "the discussion", "the conversation"
- "next steps", "action items", "follow-ups", "takeaways"
- "meeting notes", "meeting minutes", "the recap"
- "quick update", "status update", "check-in"

**Generic fillers:**
- "a lot", "a few", "a couple", "a bunch"
- "the team", "the group", "the project", "the company"
- "going forward", "moving forward", "at the end of the day"

**Conversational fillers:**
- "you know", "I think", "I mean", "kind of", "sort of"
- "basically", "essentially", "actually", "honestly"
- "right", "okay", "alright", "yeah"

### 3.3 Tag Normalization Rules

Normalize extracted topics into consistent tag format.

**Formatting rules:**
1. Lowercase all tags: "Marketing Strategy" becomes "marketing-strategy".
2. Replace spaces with hyphens for multi-word tags: "Q1 planning" becomes "q1-planning".
3. Remove trailing punctuation: "pricing." becomes "pricing".
4. Strip articles: "the roadmap" becomes "roadmap".

**Merge similar tags:**

When two candidate tags refer to the same concept, merge them into a single tag using the more specific term.

| Candidate A | Candidate B | Merged Tag | Rule |
|------------|------------|------------|------|
| "Q1 planning" | "Q1 plan" | "q1-planning" | Verb form preferred over noun when both exist |
| "pricing" | "pricing model" | "pricing-model" | More specific term preferred |
| "website" | "website redesign" | "website-redesign" | More specific term preferred |
| "marketing" | "marketing strategy" | "marketing-strategy" | More specific term preferred |
| "budget" | "Q2 budget" | "q2-budget" | Qualified term preferred |

**Fuzzy matching threshold:** When comparing two candidates, use Levenshtein distance. Tags with edit distance of 2 or fewer are candidates for merging (e.g., "onboarding" and "onboardng" are merged, keeping the correctly spelled version).

### 3.4 Notion Tag Matching

When writing topics to the Notion database, check the existing `multi_select` options on the Topics property before creating new tags.

**Matching procedure:**

1. Fetch the current tag options from the target database ("[FOS] Meetings" or fallback "Founder OS HQ - Meetings" / "Meeting Intelligence Hub - Analyses") Topics property.
2. For each extracted topic, perform a case-insensitive comparison against existing tags.
3. If an exact match exists (after normalization), use the existing tag.
4. If a fuzzy match exists (Levenshtein distance <= 2), use the existing tag. This handles minor spelling variations across analyses.
5. If no match exists, create a new tag with the normalized extracted term.

**Preference order:** Exact match > Fuzzy match > New tag creation.

This keeps the tag taxonomy tidy and enables meaningful filtering across meeting records.

---

## 4. Example Extractions

Worked examples demonstrating pattern application on realistic transcript snippets.

### 4.1 Multi-Decision Meeting with Disagreement

**Transcript snippet:**

```
Sarah: Okay, let's discuss the pricing change. We've been going back and forth on this.
Mike: I think we should go with the tiered model. It gives us more flexibility.
Sarah: I agree. Let's go with tiered pricing starting Q2.
Mike: Great. I'll draft the pricing page by Friday. Sarah, can you update the billing system?
Sarah: Sure, I'll handle the billing updates by next Wednesday.
Tom: I have concerns about the migration path for existing customers.
Sarah: Good point. Tom, can you write up a migration plan by end of week?
```

**Expected decision extraction:**

```
decision:
  decision_text: "Go with tiered pricing starting Q2"
  proposer: "Mike"
  context: "Team discussed the pricing change after extended deliberation. Mike proposed
            the tiered model for flexibility and Sarah confirmed the direction."
  confidence: "Explicit"
  disputed: true
  dissent: "Tom raised concerns about the migration path for existing customers."
```

Detection reasoning:
- "Let's go with" matches an explicit decision phrase (Section 1.1, action commitment statements).
- Tom's "I have concerns about" matches a disagreement marker (Section 1.3, hesitation and concern) within 3 turns of the decision.
- `disputed: true` because the disagreement is within the proximity window.

**Expected commitment extraction:**

```
commitment_1:
  who: "Mike"
  what: "Draft the pricing page"
  deadline: "2026-03-06"    # "Friday" relative to meeting date 2026-03-05 (Thu)
  mentioned_by: "Mike"
  promise_type: "Promise Made"
  promise_text: "I'll draft the pricing page by Friday."
  source: "Meeting Transcript"

commitment_2:
  who: "Sarah"
  what: "Update the billing system"
  deadline: "2026-03-11"    # "next Wednesday" relative to meeting date
  mentioned_by: "Sarah"
  promise_type: "Promise Made"
  promise_text: "I'll handle the billing updates by next Wednesday."
  source: "Meeting Transcript"

commitment_3:
  who: "Tom"
  what: "Write up a migration plan"
  deadline: "2026-03-06"    # "end of week" = Friday
  mentioned_by: "Sarah"
  promise_type: "Promise Received"
  promise_text: "Tom, can you write up a migration plan by end of week?"
  source: "Meeting Transcript"
```

Detection reasoning:
- Commitment 1: "I'll draft" matches self-assignment (Section 2.1). "by Friday" parsed via deadline rules (Section 2.4).
- Commitment 2: "I'll handle" matches self-assignment. "by next Wednesday" parsed as next occurrence.
- Commitment 3: "Tom, can you" matches delegation (Section 2.2). `mentioned_by` is Sarah (she made the request). `promise_type` is "Promise Received" because Tom was assigned by another person.

**Expected topic extraction:**

Topics: `tiered-pricing`, `billing-system`, `migration-plan`, `q2-launch`

Detection reasoning:
- "tiered pricing" appears in Mike's proposal and Sarah's confirmation (2 speakers, high signal).
- "billing system" appears in Mike's delegation and Sarah's acceptance.
- "migration plan" appears in Tom's concern and Sarah's delegation.
- "Q2" appears as a temporal qualifier on the pricing decision, combined with "starting" to yield "q2-launch".

### 4.2 Inferred Decision Without Explicit Language

**Transcript snippet:**

```
Lisa: I've been looking at the analytics platform options. I think Mixpanel is the best fit for us.
Dan: Yeah, it handles our event volume well and the pricing is reasonable.
Lisa: The integration with our stack looks straightforward too.
Dan: Cool. So next item -- who's presenting at the conference next month?
```

**Expected decision extraction:**

```
decision:
  decision_text: "Use Mixpanel as the analytics platform"
  proposer: "Lisa"
  context: "Lisa evaluated analytics platform options and proposed Mixpanel. Dan agreed
            on event volume handling and pricing. Discussion moved to next agenda item
            without objection."
  confidence: "Inferred"
  disputed: false
  dissent: null
```

Detection reasoning:
- No explicit decision phrase is present.
- Lisa makes a proposal ("I think Mixpanel is the best fit"). Dan agrees ("Yeah, it handles..."). The topic changes ("So next item"), satisfying the topic transition validation check (Section 1.4).
- Two participants involved, proposal exists, no contradiction follows: passes inferred decision validation.

### 4.3 Commitment with No Deadline

**Transcript snippet:**

```
Alex: We also need to look at the security audit findings at some point.
Jordan: Yeah, I can review those. Not sure when I'll get to it though.
```

**Expected commitment extraction:**

```
commitment:
  who: "Jordan"
  what: "Review the security audit findings"
  deadline: null
  mentioned_by: "Jordan"
  promise_type: "Promise Made"
  promise_text: "I can review those. Not sure when I'll get to it though."
  source: "Meeting Transcript"
```

Detection reasoning:
- "I can review those" matches self-assignment (Section 2.1, "I can handle [task]").
- "Not sure when" is an explicit absence of a deadline. Set `deadline: null`.
- The hedging language ("Not sure when I'll get to it") does not disqualify the commitment -- Jordan accepted the task. The hedge affects only the deadline, not the commitment itself.

### 4.4 False Positive Rejection

**Transcript snippet:**

```
Rachel: Last quarter we decided to pause the rebrand. Has anything changed?
Ben: I would send the vendor a new brief if we wanted to restart, but I don't think we're ready.
Rachel: Agreed. Let's revisit next quarter.
```

**Expected extraction:**

Decision:
- "Last quarter we decided to pause the rebrand" is a historical reference, not a new decision. Excluded per Section 1.6.
- "Let's revisit next quarter" is a deferral, not a decision. Excluded per Section 1.6 (future conditional).

Commitment:
- "I would send the vendor a new brief if..." is a hypothetical. Excluded per Section 2.6.
- No actionable commitments detected.

---

## 5. Pattern Interaction Rules

When multiple patterns fire on the same stretch of transcript, apply these precedence rules.

### 5.1 Decision and Commitment Overlap

A single statement can produce both a decision and a commitment. "Let's go with option B, and I'll send the updated specs by Friday" yields:
- One decision: "Go with option B."
- One commitment: speaker commits to sending updated specs by Friday.

Do not deduplicate across pipelines. Decisions and commitments serve different purposes.

### 5.2 Multiple Commitments in One Turn

A speaker may make multiple commitments in a single speaking turn. "I'll update the docs, send the API keys to Dan, and schedule the review meeting" yields three separate commitments:
1. "Update the docs" (no deadline, no delegation target)
2. "Send the API keys to Dan" (no deadline, handoff to Dan)
3. "Schedule the review meeting" (no deadline)

Split on conjunction boundaries ("and", "then", comma-separated verb phrases). Each gets its own commitment record.

### 5.3 Commitment Supersession

When a later statement overrides an earlier commitment by the same person on the same task, keep only the later version. "I'll have the report by Thursday" followed later by "Actually, I'll need until Monday for the report" yields one commitment with deadline set to Monday. Annotate: `promise_text` uses the later statement.

### 5.4 Decision Reversal

When a decision is explicitly reversed later in the same meeting ("Actually, let's NOT go with option B"), record both:
1. The original decision with a note in `dissent`: "Reversed later in meeting."
2. The replacement decision (if one is stated).

If no replacement is stated, record only the reversal as an inferred decision: "Reversed decision on option B -- no replacement agreed upon."

---

## 6. Speaker Label Resolution

Patterns throughout this document reference speaker names. Apply these rules to resolve speaker identity from transcript formatting.

### 6.1 Common Transcript Label Formats

| Format | Example | Speaker Extracted |
|--------|---------|-------------------|
| `Name:` | `Sarah:` | "Sarah" |
| `[Name]:` | `[Sarah]:` | "Sarah" |
| `Name (HH:MM):` | `Sarah (10:15):` | "Sarah" |
| `Speaker N:` | `Speaker 1:` | "Speaker 1" (retain as-is) |
| `SPEAKER_NAME:` | `SARAH:` | "Sarah" (normalize case) |
| `Name (Title):` | `Sarah (PM):` | "Sarah" |

### 6.2 Pronoun Resolution

When a speaker uses "I'll" or "I'm going to", resolve to the speaker name from the current transcript label. When a speaker says "[Name] will...", resolve the name against the attendee list. If the name does not appear in the attendee list, retain the mentioned name as-is (they may be external to the meeting).

### 6.3 No Speaker Labels

When the transcript lacks any speaker labels (raw prose without attribution), set all `proposer`, `who`, and `mentioned_by` fields to "Unknown Speaker". Note this limitation in the analysis output. Decisions and commitments can still be extracted from the content even without attribution.
