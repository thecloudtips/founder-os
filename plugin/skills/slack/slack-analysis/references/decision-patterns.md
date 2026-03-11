# Decision Pattern Library

Complete pattern lists for detecting decisions, agreements, and outcomes in Slack messages and threads.

## Decision Keyword Categories

### 1. Explicit Agreement

Keywords and phrases indicating a group has reached consensus or given approval.

**Strong Signals (high confidence):**
- "we decided", "we agreed", "we're going with", "we'll go with"
- "decision made", "final decision", "approved", "signed off"
- "green light", "go-ahead", "thumbs up on this", "let's proceed"
- "confirmed", "locked in", "finalized", "settled on"

**Moderate Signals (needs context validation):**
- "sounds good", "works for me", "I'm fine with that"
- "let's do it", "let's go ahead", "makes sense"
- "+1", "agreed", "LGTM", "ship it"

### 2. Outcome Statements

Keywords indicating a conclusion, result, or resolution has been reached.

**Strong Signals:**
- "the outcome is", "we concluded", "the result is"
- "moving forward with", "we're switching to", "we chose"
- "after discussion", "based on the feedback", "consensus is"
- "the plan is to", "here's what we'll do", "action plan"

**Moderate Signals:**
- "so the next step is", "to summarize", "TL;DR"
- "wrapping up", "to close the loop", "final answer"

### 3. Process Completion

Keywords indicating a workflow step or approval gate has been passed.

**Strong Signals:**
- "merged", "deployed", "shipped", "released", "launched"
- "PR approved", "review complete", "signed off on"
- "budget approved", "contract signed", "deal closed"
- "milestone hit", "sprint complete", "phase done"

**Moderate Signals:**
- "done", "completed", "finished", "wrapped up"
- "ready for", "handed off", "submitted"

### 4. Voting and Consensus

Keywords indicating a vote, poll, or consensus-building exercise.

**Strong Signals:**
- "vote", "poll results", "majority says", "consensus reached"
- "everyone agrees", "unanimous", "all in favor"
- "the group decided", "team consensus", "alignment reached"

**Moderate Signals:**
- "most people prefer", "leaning toward", "trending toward"
- "show of hands", "what does everyone think" (question, not decision — see validation)

---

## Context Signal Validation

Keyword matches alone produce false positives. Validate each candidate decision against these context signals. A message must match keywords AND at least 2 context signals to classify as a decision.

### Positive Context Signals (increase confidence)

| Signal | What to Check | Weight |
|--------|---------------|--------|
| Thread resolution | Message appears late in a thread (reply position > 50% of total replies) | High |
| Participant breadth | Thread has 3+ unique participants | Medium |
| Reaction confirmation | Message has checkmark, thumbs-up, or party emoji reactions | Medium |
| Recency in thread | Message is within last 3 replies of a thread | High |
| Author authority | Message author started the thread or is a channel admin | Medium |
| Follow-up action | A subsequent message references this as a decision ("as we decided", "per the decision") | High |

### Negative Context Signals (decrease confidence)

| Signal | What to Check | Weight |
|--------|---------------|--------|
| Question context | Message ends with "?" or starts with "should we", "what if", "can we" | High |
| Hypothetical language | Contains "if we", "we could", "maybe", "potentially", "we might" | High |
| Single participant | Only one person in the thread (no consensus possible) | High |
| Disagreement follows | A subsequent reply contains "actually", "I disagree", "not sure about", "wait" | Medium |
| Low ambiguity | Decision keyword appears in a code snippet, link preview, or bot message | Medium |
| Sarcasm indicators | Contains "lol", "jk", "/s", "obviously not" near the keyword | Low |

### Confidence Classification

After keyword match + context signal validation:

| Confidence | Criteria | Action |
|------------|----------|--------|
| High | Strong keyword + 3+ positive signals + 0 negative signals | Include in digest as confirmed decision |
| Medium | Any keyword + 2 positive signals + 0-1 negative signals | Include in digest with "likely decision" qualifier |
| Low | Moderate keyword + <2 positive signals OR 2+ negative signals | Exclude from decisions section, may appear in Key Threads |

---

## Decision Data Structure

For each detected decision, extract:

```
decision:
  text: "The verbatim message text (or relevant excerpt if very long)"
  channel: "#channel-name"
  author: "display_name"
  timestamp: "ISO 8601"
  thread_url: "Slack permalink if available"
  confidence: "high | medium"
  context: "Brief one-line summary of what was decided"
  participants: ["list", "of", "thread", "participants"]
  reactions: ["emoji1", "emoji2"]
```

---

## Common False Positive Patterns

These patterns frequently match decision keywords but are NOT decisions. Exclude them:

1. **Bot status messages**: "Deploy completed" from CI/CD bots — process completion keyword, but not a human decision
2. **Casual agreement**: "sounds good, see you at lunch" — agreement keyword in social context
3. **Code review comments**: "LGTM" on a code snippet posted in chat — not a business decision
4. **Historical references**: "Last week we decided..." — references a past decision, not a new one
5. **Conditional statements**: "If the client approves, we'll go with option A" — not yet decided
6. **Question threads**: Thread starts with "Should we switch to X?" with only responses like "sounds good" from 1 person — insufficient consensus
