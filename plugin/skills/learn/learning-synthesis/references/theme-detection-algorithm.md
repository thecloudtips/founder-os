# Theme Detection Algorithm

Analyze the Topics distribution across all learnings in a target week to identify dominant themes and cross-topic connections. Use this algorithm during weekly synthesis to surface patterns the user might not notice individually.

## Overview

Collect every learning entry within the target week's boundaries (Monday 00:00 through Sunday 23:59). Extract the Topics multi-select values from each entry. Run three sequential phases: frequency counting, top themes selection, and cross-learning connection detection. Feed the results into the weekly synthesis report's "Themes" and "Connections" sections.

## Step 1: Frequency Counting

For all learnings in the target week, build a frequency table of topic occurrences.

### Procedure

1. Iterate through every learning entry in the target week.
2. Read the Topics property (multi-select array) from each entry.
3. For each topic value in the array, increment that topic's counter by 1.
4. A single learning with Topics ["Technical", "Process"] adds 1 to Technical and 1 to Process. Never double-count within the same learning, but do count each topic independently.
5. Store the final frequency table as a map of topic string to integer count.

### Example

Assume the week contains 6 learnings:

- Learning 1: Technical, Process
- Learning 2: Business, Strategy
- Learning 3: Technical, Tool
- Learning 4: Technical, Mistake
- Learning 5: Business, People
- Learning 6: Process, Tool

Produce this frequency table:

| Topic | Count |
|---|---|
| Technical | 3 |
| Process | 2 |
| Business | 2 |
| Tool | 2 |
| Strategy | 1 |
| Mistake | 1 |
| People | 1 |

### Validation

Verify the total count across all topics is greater than or equal to the number of learnings (each learning contributes at least one topic). If any learning has an empty Topics field, skip it in the frequency count but still include it in the learnings total for the top themes threshold table.

## Step 2: Top Themes Selection

Select the most prominent topics based on the total number of learnings in the week. Do not use the total topic count — use the total learning entry count.

### Threshold Table

| Learnings Count | Top Themes to Select |
|---|---|
| 1-2 | Top 1-2 topics (all that appear) |
| 3-5 | Top 2-3 topics |
| 6-10 | Top 3-4 topics |
| 11+ | Top 4 topics |

### Selection Rules

1. Rank all topics by frequency in descending order.
2. Select the number of topics indicated by the threshold table.
3. When frequencies tie, prefer the topic that appeared in the most recent learning (compare `Logged At` timestamps). Check the latest learning that contains each tied topic and rank by recency.
4. If still tied after recency comparison, use the canonical taxonomy order as the final tiebreaker: Technical > Process > Business > People > Tool > Strategy > Mistake > Win > Idea > Industry. Lower position in this list means lower priority.

### Most Active Topic

Identify the single topic with the highest frequency. This value populates the `Most Active Topic` field in the synthesis output. Apply the same tiebreaking rules (recency first, then taxonomy order) when two or more topics share the highest count.

### Edge Case: Very Few Topics

When 1-2 learnings exist and only 1 unique topic appears, set Top Themes to that single topic. Do not pad with empty values. When all learnings share the exact same topic set, Top Themes equals that set (capped by the threshold table).

## Step 3: Cross-Learning Connection Detection

Identify 2-3 meaningful connections between learnings that bridge different topic areas. Connections reveal patterns across the week that individual entries cannot show.

### Connection Criteria

A valid connection exists when two learnings satisfy all three conditions:

1. **Share at least one Topic** — the two learnings have at least one common topic value (common ground).
2. **Differ in at least one other Topic** — the two learnings each have at least one topic the other does not (cross-topic bridge).
3. **Have complementary or contrasting content** — the relationship between the two learnings is meaningful, not merely coincidental tag overlap.

### Connection Types

Classify each connection into one of three types:

| Type | Description | Signal |
|---|---|---|
| Reinforcing | Two insights from different domains point to the same conclusion | Similar takeaway or recommendation despite different topic contexts |
| Contrasting | Two insights present opposing perspectives or tensions | One is a Win while the other is a Mistake, or recommendations conflict |
| Building | One insight extends, deepens, or enables another | A Tool discovery that supports a Strategy, or a Process that improves a Technical outcome |

Assign the type that best fits the pair. When multiple types could apply, prefer the type that produces the most actionable insight for the user.

### Connection Scoring

For each candidate pair of learnings that meet criteria 1 and 2 above:

1. Count shared topics between the two learnings. Add +1 per shared topic.
2. Count different topics (topics present in one learning but not the other). Add +0.5 per different topic.
3. Compute the pair score: score = shared_count + (different_count * 0.5).
4. Rank all candidate pairs by score in descending order.
5. Select the top 3 pairs. If fewer than 3 pairs meet the criteria, select all qualifying pairs.

When scores tie, prefer pairs whose learnings are closer together in time (smaller gap between their `Logged At` timestamps). If still tied, prefer the pair containing the more recent learning.

### Connection Prose Generation

For each selected connection, write a single sentence following this template:

- Start with "Your [Topic] insight about [brief reference to learning content]..."
- Connect with one of: "reinforced" (for Reinforcing type), "contrasted with" (for Contrasting type), or "extended" (for Building type).
- End with "your [Topic] learning about [brief reference] — both [shared conclusion or key tension or deeper insight]."

Keep each connection sentence under 40 words. Reference specific content from the learnings rather than restating topic names generically. The sentence must make clear why the connection matters.

### Edge Cases for Connections

Handle these scenarios explicitly in the synthesis output:

- **Fewer than 3 learnings in the week**: Write "Not enough learnings for cross-topic connections this week." Do not attempt pair analysis with fewer than 3 entries.
- **All learnings share identical Topics**: Write "All learnings focused on [Topic(s)] this week — no cross-topic connections detected." List the shared topics.
- **All learnings have completely disjoint Topics (no overlap)**: Write "Diverse week with no overlapping topics — each learning explored a unique area." Do not force artificial connections.
- **Exactly one valid pair exists**: Present that single connection. Do not pad with weaker connections that fail the criteria.

## Complete Example

Given 5 learnings with these topics and content:

- L1: Technical, Process — error handling patterns discovered during code reviews
- L2: Business, Strategy — evaluated a pricing model change for Q2
- L3: Technical, Tool — found a new debugging extension that cuts triage time
- L4: Process, People — tested a delegation framework with the team
- L5: Business, People — refined client communication style after feedback

### Frequency Count

| Topic | Count |
|---|---|
| Technical | 2 |
| Process | 2 |
| Business | 2 |
| People | 2 |
| Strategy | 1 |
| Tool | 1 |

### Top Themes

Apply the threshold table: 5 learnings maps to "Top 2-3 topics." Four topics tie at count 2. Apply recency tiebreaker — L5 (Business, People) is most recent, so Business and People rank first. L4 (Process) is next most recent. Select top 3: Business, People, Process.

**Most Active Topic**: Technical (tiebreak by taxonomy order: Technical > Process > Business > People).

Note: Most Active Topic uses taxonomy order as tiebreaker, while Top Themes uses recency. This is intentional — Most Active Topic reflects the canonical domain hierarchy, while Top Themes reflects what is freshest in the user's mind.

### Connections

Candidate pairs and scores:

| Pair | Shared | Different | Score |
|---|---|---|---|
| L1-L4 | Process (1) | Technical, People (2) | 2.0 |
| L2-L5 | Business (1) | Strategy, People (2) | 2.0 |
| L1-L3 | Technical (1) | Process, Tool (2) | 2.0 |
| L4-L5 | People (1) | Process, Business (2) | 2.0 |
| L1-L5 | 0 shared | — | Does not meet criteria 1 |
| L2-L4 | 0 shared | — | Does not meet criteria 1 |

Four pairs tie at 2.0. Apply time proximity tiebreaker. Select top 3 by smallest time gap:

1. L4-L5 (closest in time) — "Your Process insight about the delegation framework reinforced your Business learning about client communication style — both emphasize adapting your approach to the person receiving the work."
2. L2-L5 (next closest) — "Your Strategy insight about the pricing model change connected with your People learning about client communication — pricing changes require careful stakeholder messaging."
3. L1-L3 (next closest) — "Your Process insight about code review error patterns extended your Tool discovery of the new debugging extension — the tool directly supports the review workflow you identified."

## Integration Notes

Feed the complete output (frequency table, top themes list, most active topic, and connection sentences) into the weekly synthesis template. The synthesis skill consumes these values to populate the Themes section and the Connections section of the final report. Do not store intermediate scoring data in Notion — only persist the final top themes, most active topic, and connection prose.
