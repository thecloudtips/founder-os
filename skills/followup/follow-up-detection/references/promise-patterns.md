# Promise Pattern Library

Complete pattern lists for bidirectional promise detection in email threads.

## Outbound Promise Patterns (User's Sent Messages)

Scan messages sent by the user for commitment language. These represent obligations the user owes.

### Delivery Commitments
- "I will send you [X]", "I'll send over [X]", "I'll forward [X]"
- "I will share [X]", "I'll get [X] to you", "I'll pass along [X]"
- "I will prepare [X]", "I'll put together [X]", "I'll draft [X]"

### Response Commitments
- "I will get back to you", "I'll follow up", "I'll circle back"
- "Let me check on that", "Let me look into it", "Let me find out"
- "I'll confirm [X]", "I'll verify [X]", "I'll double-check [X]"

### Action Commitments
- "I will schedule [X]", "I'll set up [X]", "I'll book [X]"
- "I will review [X]", "I'll take a look", "I'll go through [X]"
- "I will update [X]", "I'll make the changes", "I'll revise [X]"
- "Consider it done", "I'm on it", "I'll handle it", "I'll take care of it"

### Temporal Commitments
- "by [day/date]", "before [deadline]", "within [timeframe]"
- "this week", "next week", "by end of day", "first thing tomorrow"

When a temporal commitment accompanies a promise, extract the implied deadline and factor it into the priority score. A missed deadline elevates priority by +1 (cap at 5).

## Inbound Promise Patterns (Received Messages)

Scan messages from others (sender does not match the user's email) for commitment language directed at the user. These represent obligations others owe.

### Delivery Commitments
- "I will send you [X]", "We will send [X]", "I'll get that to you"
- "I will share [X]", "We'll forward [X]", "I'll pass that along"

### Response Commitments
- "I will get back to you", "We will follow up", "I'll circle back"
- "Let me check on that", "Let me look into this", "I'll find out"
- "I will confirm [X]", "We'll verify [X]"
- "I need to check with [person]", "Let me run this by [person]"

### Action Commitments
- "I will schedule [X]", "We'll set up [X]", "I'll arrange [X]"
- "I will review [X]", "We'll take a look", "I'll go through [X]"
- "I will update [X]", "Working on it", "I'm on it"

### Deferral Language (High Follow-Up Signal)
- "I'll get to this [timeframe]", "I'll handle this [when]"
- "Give me [timeframe]", "I need a few days", "Bear with me"
- "Noted, will action", "Acknowledged", "Got it, will review"
