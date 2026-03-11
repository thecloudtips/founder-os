# Topic Detection Algorithm

Full algorithm for auto-detecting 1-3 topic categories from the 10-category taxonomy. Apply this algorithm to every learning entry to ensure consistent, accurate tagging without requiring manual topic selection from the user.

## Keyword Signal Table

Define 8-12 keyword signals per topic category. Use these signals as the primary detection mechanism. Match against the combined text of the Insight and Context fields.

| Topic | Keyword Signals |
|---|---|
| Technical | code, API, bug, debug, deploy, architecture, database, backend, frontend, refactor, git, server |
| Process | workflow, sprint, standup, review, approval, pipeline, checklist, SOP, deadline, milestone, agile, kanban |
| Business | revenue, client, pricing, contract, deal, ROI, growth, market, profit, cash flow, retention, churn |
| People | team, leadership, feedback, hire, onboard, culture, conflict, mentor, communication, 1-on-1, morale, delegate |
| Tool | Notion, Slack, GitHub, VS Code, Figma, Zapier, integration, plugin, extension, setup, configuration, platform |
| Strategy | roadmap, vision, positioning, competitive, long-term, OKR, pivot, differentiation, focus, mission, north star, moat |
| Mistake | failed, wrong, broke, shouldn't have, regret, overlooked, missed, forgot, error, lesson learned, never again, avoid |
| Win | shipped, launched, achieved, improved, solved, landed, closed deal, succeeded, milestone hit, 100%, breakthrough, nailed |
| Idea | what if, could we, maybe, brainstorm, concept, experiment, prototype, hypothesis, possibility, imagine, explore, new approach |
| Industry | market trend, competitor, regulation, sector, benchmark, industry standard, disruption, emerging, AI trend, compliance, ecosystem, landscape |

Note that some signals are multi-word phrases (e.g., "cash flow", "lesson learned", "north star", "closed deal", "milestone hit", "what if", "could we", "shouldn't have", "never again", "new approach", "market trend", "industry standard", "AI trend"). Match these as complete phrases before matching single-word signals to avoid double-counting partial matches.

## Scoring System

Apply the following scoring procedure for each of the 10 topic categories:

1. Concatenate the Insight field and Context field into a single input string.
2. Normalize the input to lowercase for matching purposes.
3. Scan the input for each keyword signal in the category row using word boundary matching.
4. Award 1 point for each distinct keyword signal that matches at least once. Do not award additional points for repeated occurrences of the same keyword within the same input.
5. Record the total score for the category.
6. Require a minimum score threshold of 2 points to consider a category as a candidate topic.

Process all 10 categories completely before proceeding to selection. Do not short-circuit after finding the first qualifying category.

## Multi-Topic Selection Rules

After scoring all 10 categories, apply these selection rules in order:

- Collect all categories with scores at or above the 2-point threshold into a candidate set.
- If the candidate set contains 3 or fewer categories, select all of them.
- If the candidate set contains more than 3 categories, sort by score descending and select the top 3.
- Break ties by topic order in the taxonomy table above (Technical is highest priority, Industry is lowest priority). When two categories share the same score, prefer the one that appears earlier in the table.
- Assign a maximum of 3 topics per learning entry. Never assign more than 3 even if additional categories meet the threshold.

## Exclusion Signals

Some keywords appear across multiple domains with different meanings. Apply exclusion signals to disambiguate before finalizing scores. When an exclusion condition is met, remove the point from the default category and award it to the correct category instead.

| Keyword | Default Topic | Exclude When |
|---|---|---|
| "client" | Business | Context mentions "client-side", "HTTP client", "client library", or "client SDK" — reassign the point to Technical |
| "bug" | Technical | Context mentions "feature not a bug" or "bug in the process" — reassign the point to Process |
| "deal" | Business | Context uses "deal with" as a verb phrase meaning to cope or handle — reassign the point to People if about interpersonal coping, or Process if about operational handling |
| "culture" | People | Context mentions "culture fit" in a hiring context — retain the point in People (no reassignment needed, but confirm the category is correct) |
| "review" | Process | Context mentions "code review", "PR review", or "pull request review" — reassign the point to Technical |
| "platform" | Tool | Context discusses "platform strategy" or "platform business model" — reassign the point to Strategy |
| "growth" | Business | Context discusses "personal growth" or "team growth" — reassign the point to People |
| "pipeline" | Process | Context discusses "CI/CD pipeline" or "deployment pipeline" — reassign the point to Technical |
| "experiment" | Idea | Context discusses "A/B experiment" or "growth experiment" with measurable results — reassign the point to Business |
| "milestone" | Process | Context discusses "milestone hit" as a celebration — reassign the point to Win (and also count "milestone hit" as a Win phrase match) |

Apply exclusion signals after initial keyword matching but before threshold evaluation. Scan the surrounding sentence context (the sentence containing the keyword) to determine which exclusion condition applies. When no exclusion condition matches, retain the default assignment.

## Source-Type Fallback

When no category reaches the 2-point threshold after scoring and exclusion processing, apply a fallback based on the Source Type field of the learning entry:

- If Source Type is Reading, default to Industry.
- If Source Type is Conversation, default to People.
- If Source Type is Experiment, default to Technical.
- If Source Type is Experience, default to Process.
- If Source Type is Observation, default to Industry.
- If Source Type is Course, default to Technical.
- If Source Type is Podcast, default to Industry.
- If Source Type is unknown or unset, default to Idea.

Always assign at least 1 topic to every learning entry. The fallback mechanism ensures no learning goes untagged. Apply the fallback only when keyword scoring produces zero qualifying categories. If keyword scoring produces at least one qualifying category, do not apply the fallback.

## Custom Topics

When the user explicitly specifies a topic that does not exist in the 10 predefined categories, handle it as a custom topic:

- Accept the custom topic string as-is and store it as a new multi_select option in the Notion database.
- Reserve one of the 3 available topic slots for the custom topic. The custom topic always occupies the first slot.
- Run keyword detection for the remaining 1-2 available slots using the standard algorithm above.
- If keyword detection produces qualifying categories, fill the remaining slots (up to 2) with the highest-scoring predefined categories.
- If the user specifies multiple custom topics, accept up to 2 custom topics and fill the remaining 1 slot with keyword detection.
- Never exceed 3 total topics regardless of how many custom topics the user provides. If the user specifies 3 or more custom topics, accept only the first 3 and skip keyword detection entirely.

Custom topics take priority over auto-detected topics in all cases. Do not override or replace a user-specified custom topic with an auto-detected predefined category, even if the predefined category scores higher.

## Implementation Notes

Follow these guidelines when implementing the detection algorithm:

- Perform keyword matching on the combined text of the Insight and Context fields. Do not match against the Title field, Source Type field, or other metadata.
- Use word boundary matching to avoid false positives. For example, "API" must not match inside "capital", "code" must not match inside "barcode", and "git" must not match inside "digital". Apply `\b` word boundary anchors or equivalent tokenization.
- Process multi-word phrases before single-word signals. Match "cash flow" as a single signal before matching "cash" or "flow" individually. This prevents inflated scores from phrase components.
- Normalize both keyword signals and input text to lowercase before matching, except for acronyms (API, ROI, OKR, SOP, VS Code) which should match case-insensitively as whole tokens.
- Process all 10 categories completely before selecting the top results. Do not return early after finding 3 qualifying categories.
- Log the scoring breakdown (category name, matched keywords, raw score, adjusted score after exclusions) in debug output for troubleshooting. Do not display scoring details to the user in normal output.
- When the algorithm runs on an update to an existing learning entry, recalculate topics from scratch. Do not carry forward previously assigned topics unless the user explicitly locked them.
