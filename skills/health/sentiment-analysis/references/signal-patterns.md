# Signal Patterns

Comprehensive signal dictionaries for email sentiment extraction and meeting pattern analysis. Used by the sentiment-analysis skill to detect, classify, and score communication signals from Gmail and Google Calendar data.

## Email Positive Signals

Each positive signal detected in a thread adds +1 to the email sentiment score. Count each signal type once per thread -- do not double-count multiple instances of the same signal type within a single thread.

### Gratitude Language (+1)

Detect any of the following phrases in client emails (case-insensitive):

- "thank you"
- "thanks so much"
- "many thanks"
- "appreciate"
- "grateful"
- "great work"
- "excellent"
- "well done"
- "fantastic"
- "amazing job"
- "perfect"
- "exactly what I needed"
- "you nailed it"
- "kudos"
- "hats off"

**Detection notes**: Match only in the body or opening line of the email. Ignore gratitude in email signatures (e.g., "Thanks, John" as a standard sign-off). A standalone "Thanks" at the end of an email is a sign-off, not a gratitude signal -- require additional qualifying words or placement in the body.

### Forward-Looking Language (+1)

Detect phrases that signal enthusiasm about future collaboration:

- "excited about"
- "looking forward to"
- "let's proceed"
- "can't wait"
- "eager to"
- "ready to move forward"
- "next steps"
- "let's get started"
- "when can we begin"
- "let's schedule"
- "planning for"
- "looking ahead"
- "future plans"
- "phase 2" / "phase two" / "next phase"

**Detection notes**: Forward-looking language must be in the context of the working relationship. Ignore forward-looking language that refers to external events unrelated to the engagement (e.g., "looking forward to the weekend").

### Endorsement Language (+1)

Detect phrases that indicate satisfaction or advocacy:

- "highly recommend"
- "impressed with"
- "exceeded expectations"
- "above and beyond"
- "outstanding"
- "exceptional"
- "couldn't be happier"
- "top-notch"
- "best decision"
- "referred you to"
- "told [name] about you"
- "would recommend"
- "exactly what we needed"
- "transformed our"
- "game changer"

**Detection notes**: Endorsement from the client to a third party (referral language) is an especially strong signal. Weight referral phrases ("referred you to", "told [name] about you") at +1 same as others, but note them in the output as referral signals.

### Quick Responses (+1)

Behavioral signal based on response timing:

- Calculate the average response time for client replies across all messages in the thread.
- Response time = timestamp of client reply minus timestamp of the message they are replying to.
- Threshold: average response time under 4 hours during business hours (9 AM - 6 PM in the client's timezone, or assume local timezone if unknown).
- Exclude weekends and non-business hours from response time calculation.
- If only one reply exists in the thread, use that single response time.

**Detection notes**: Quick responses indicate engagement and prioritization. This signal is particularly meaningful when the client responds faster than their historical average.

### Expansion Signals (+1)

Detect phrases that indicate the client wants to grow the engagement:

- "additional scope"
- "new project"
- "another opportunity"
- "scale up"
- "expand"
- "increase budget"
- "add more"
- "additional services"
- "grow the team"
- "extend the contract"
- "renew"
- "longer term"
- "second engagement"
- "follow-on"
- "additional work"

**Detection notes**: Expansion signals are among the strongest positive indicators. When detected alongside endorsement language, the combination strongly suggests a healthy relationship. Flag expansion signals specifically in the output.

## Email Negative Signals

Each negative signal detected in a thread adds -1 to the email sentiment score (except where noted). Count each signal type once per thread.

### Frustration Language (-1)

Detect any of the following phrases in client emails (case-insensitive):

- "disappointed"
- "concerned"
- "unacceptable"
- "still waiting"
- "not satisfied"
- "falling behind"
- "missed deadline"
- "dropped the ball"
- "not what I expected"
- "frustrating"
- "unresponsive"
- "lack of progress"
- "repeatedly asked"
- "once again"
- "as I mentioned before"
- "per my last email"
- "following up again"

**Detection notes**: Distinguish between frustration directed at the user/service vs. frustration about external factors. "I'm disappointed with the market conditions" is not a negative signal about the relationship. Focus on phrases where the client expresses dissatisfaction with the user, deliverables, or service quality.

### Escalation Indicators (-1)

Detect phrases that suggest the client is escalating concerns:

- "need to escalate"
- "speak with your manager"
- "not acceptable"
- "formal complaint"
- "legal"
- "contract review"
- "breach"
- "termination"
- "cancel"
- "reconsider our arrangement"
- "bring in leadership"
- "executive review"
- "SLA violation"
- "written notice"
- "putting you on notice"

**Detection notes**: Escalation language is a strong negative signal. Any single escalation phrase should trigger a flag in the output regardless of the net score. When escalation language is detected, add an explicit note: "Escalation language detected -- recommend immediate review."

### Withdrawal Patterns (-1)

Behavioral signal detected by comparing communication patterns across the 10-thread window:

- **Declining response rate**: Client responded to 80%+ of emails in older threads but responds to <50% in recent threads.
- **Shorter replies**: Average reply length in the 3 most recent threads is <50% of the average in the 3 oldest threads.
- **Fewer client-initiated messages**: Client started threads in older period but has not initiated any in the most recent 30 days.
- **Going from paragraphs to one-liners**: Individual reply length dropped from multi-sentence to single-sentence responses.

**Detection notes**: Withdrawal is a gradual pattern, not a single-message indicator. Require at least 5 threads in the window to reliably detect withdrawal. With fewer threads, skip this signal and note: "Insufficient thread history for withdrawal pattern detection."

### Delayed Responses (-1)

Behavioral signal based on response timing:

- Calculate the average response time for client replies across all messages in the thread.
- Threshold: average response time over 48 hours (calendar hours, not business hours -- extended delays indicate disengagement regardless of business hour considerations).
- If only one reply exists in the thread, use that single response time.
- Exclude auto-responders and out-of-office replies from the calculation.

**Detection notes**: Delayed responses may have innocent explanations (vacation, busy period). When this signal fires in combination with withdrawal patterns, the negative indication is stronger. When it fires alone, treat it as a mild signal.

### Complaint Keywords (-1)

Detect these words when used in a negative context (not neutral/positive usage):

- "issue"
- "problem"
- "broken"
- "failed"
- "wrong"
- "error"
- "bug"
- "defect"
- "outage"
- "downtime"
- "regression"
- "blocker"

**Detection notes**: These words are common in technical communication and are not inherently negative. Apply context analysis: "We fixed the issue" is not negative, but "We keep running into the same issue" is. Look for negative modifiers: "still", "again", "another", "keep", "recurring", "persistent", "unresolved". Only count as negative when the keyword appears with a negative modifier or in a sentence expressing dissatisfaction.

### Formality Shift (-1)

Behavioral signal detected by comparing tone across the 10-thread window:

- Compare the 3 most recent threads to the 3 oldest threads in the window.
- Detect shift from casual to formal: client previously used first names, informal greetings ("Hey", "Hi"), casual language, but recently shifted to formal salutations ("Dear", "To whom it may concern"), full titles, and stiff phrasing.
- The reverse shift (formal to casual) is a positive signal -- do not count it as negative.

**Detection notes**: Formality shift indicates emotional distance. It is a subtle signal that is most meaningful when combined with other negative indicators. As a standalone signal, it may simply reflect a change in communication context (e.g., adding new stakeholders to the thread). Require at least 6 threads to detect this pattern reliably.

## Meeting Positive Signals

Detected from Google Calendar event data over the last 90 days. Each signal adds to the meeting positive count.

### Frequency Increasing (+1)

- Current 30-day period has more events than the previous 30-day period by 20%+ (minimum threshold: at least 1 additional meeting).
- Require at least 2 periods with data to assess trend.

### Client Initiates Meetings (+1)

- Client's email address appears as the event organizer for 1 or more meetings in the last 30 days.
- Compare to previous 30 days: if client-initiated meetings increased, this is an especially strong signal.

### Senior Stakeholders Present (+1)

- Attendee list includes individuals with senior titles: CEO, CTO, CFO, COO, VP, SVP, EVP, Director, Managing Director, Partner, Principal, Head of, Chief.
- Title detection: check the attendee's display name for title keywords. When display names do not include titles, this signal cannot be detected -- do not count it.
- Score this signal if senior stakeholders appear in any meeting in the last 30 days.

### Meeting Duration Stable or Increasing (+1)

- Compare average meeting duration in the current 30-day period to the previous period.
- Stable: within 10% of previous average.
- Increasing: >10% longer than previous average.
- Either stable or increasing earns +1.

### Additional Attendees Joining (+1)

- The number of unique attendees in meetings during the current 30-day period exceeds the previous period.
- This indicates expanding engagement -- more people from the client's organization are getting involved.

### Client Shares Agenda Items (+1)

- Event description field is populated and the content was added by the client (client is the organizer or last editor).
- Indicates preparation and engagement.
- When organizer metadata is unavailable, count any populated description as a weak positive (still +1).

## Meeting Negative Signals

Each signal subtracts from the meeting score. No-shows carry extra weight.

### Cancellations (-1)

- 2 or more meetings cancelled in any 30-day period.
- Count events where status is "cancelled" and the client was an attendee.
- Single cancellations are normal and should not trigger this signal.

### No-Shows (-2)

- Any meeting where the client's RSVP was "accepted" or "tentative" but attendance metadata suggests they did not attend, OR a meeting that was neither cancelled nor rescheduled but the client later marked "declined" after the start time.
- No-shows carry double weight (-2) because they indicate stronger disengagement than cancellations.
- Even a single no-show triggers this signal.

### Meetings Shortened (-1)

- Average meeting duration in the current 30-day period is >20% shorter than the previous 30-day period.
- Requires at least 2 meetings per period to calculate averages.
- Shortened meetings may indicate the client is allocating less time to the relationship.

### Senior Stakeholders Dropped Off (-1)

- Senior-titled attendees were present in meetings during the previous 30-60 day period but are absent from meetings in the most recent 30 days.
- This signal requires at least one senior stakeholder to have been previously present.
- Indicates potential de-prioritization at the client's organization.

### Excessive Rescheduling (-1)

- 3 or more meetings rescheduled (date/time changed) in any 30-day period.
- Track rescheduling by detecting events with the same title or event ID that have changed their start time.
- Frequent rescheduling suggests avoidance or deprioritization.

### Client Stops Sharing Agenda Items (-1)

- Client previously populated event descriptions (in the 30-60 day window) but has stopped doing so in the most recent 30 days.
- Requires a baseline of at least 2 events with descriptions in the earlier period.

### Frequency Declining (-1)

- Current 30-day period has fewer events than the previous 30-day period by 20%+ (minimum threshold: at least 1 fewer meeting).
- Require at least 2 periods with data to assess trend.

## Edge Cases

### Mixed Signals

When email classification and meeting classification diverge (e.g., email = Positive, meetings = Negative):

1. Compute the weighted composite as normal.
2. Append "Mixed Sentiment Signals" to the output.
3. Report both per-source classifications and scores.
4. Add an explanatory note: "Email sentiment is [X] but meeting patterns are [Y] -- recommend investigating the discrepancy."

Mixed signals often indicate a transitional state. The relationship may be improving (positive emails + legacy negative meeting patterns) or deteriorating (polite emails + meeting avoidance).

### Low Email Volume

When fewer than 3 email threads are found:

1. Compute the score from available threads as normal.
2. Append: "Low email volume -- sentiment confidence reduced."
3. The low volume does not change the numeric score, but downstream consumers (the health-scoring skill) should note the reduced confidence.

### No Calendar Data

When gws CLI is unavailable for Calendar or no events are found:

1. Use email-only scoring at 100% weight.
2. Append: "Calendar unavailable -- using email-only sentiment."
3. Do not penalize the client for missing calendar data.

### New Client

When the client relationship is less than 30 days old:

1. Fewer data points are expected -- do not flag low volume as concerning.
2. Append: "New client -- limited sentiment data."
3. Use all available data without modification. Even 1-2 email threads provide some signal.

### Auto-Generated Emails

Exclude the following from signal scanning:

- Emails from addresses containing "noreply", "no-reply", "donotreply", "notifications", "alerts", "system", "mailer-daemon".
- Emails with an "Unsubscribe" link in the footer (common pattern for automated newsletters and notifications).
- Calendar invitation emails (these are captured by the meeting analysis, not email analysis).

### Large Threads

For threads with more than 10 messages:

1. Scan only the 5 most recent messages in the thread.
2. Older messages in long threads often contain stale sentiment that no longer reflects the current relationship state.
3. Note in the output: "Thread [subject] truncated to 5 most recent messages."

### Seasonal Patterns

Be aware that certain periods produce systematically different communication patterns:

- End-of-year (December-January): Slower response times and fewer meetings are normal. Consider relaxing the delayed response threshold to 72 hours during this period.
- Fiscal quarter ends: Higher meeting frequency and faster responses may be deal-driven rather than relationship-driven.
- Summer months: Reduced meeting frequency may reflect vacations rather than disengagement.

These seasonal factors do not change the scoring formula, but they should be noted in the output when applicable: "Note: Analysis period overlaps [season] -- some patterns may reflect seasonal norms rather than relationship changes."
