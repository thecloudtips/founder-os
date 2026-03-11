---
name: Prompt Optimization
description: "Analyzes and improves prompt quality through scoring, rewriting, and best-practice enforcement. Activates when the user wants to optimize, improve, score, or fix a prompt, or asks 'make this prompt better.' Covers clarity scoring, context injection, specificity improvements, and vague-prompt detection."
globs:
  - "commands/prompt-*.md"
---

## Overview

Evaluate and rewrite prompts to maximize clarity, specificity, and actionability. Apply this skill in two modes: passive quality-check (triggered during `/founder-os:prompt:add` to surface issues before saving) and active rewrite (triggered by `/founder-os:prompt:optimize` to produce an improved version). In both modes, score the prompt on five dimensions, identify anti-patterns, and return structured improvement feedback. In active rewrite mode, produce a complete rewritten prompt alongside the score.

The goal is not to change a prompt's intent -- it is to make that intent unambiguous to any LLM receiving the prompt. A well-optimized prompt produces consistent, predictable output without requiring follow-up clarification.

---

## Quality Scoring System

Score every prompt across five dimensions. Each dimension scores 1 to 5. Compute the total as the sum of all five scores (maximum: 25 points). Classify the total into a quality tier:

| Total Score | Quality Tier | Action |
|-------------|--------------|--------|
| 21–25 | Excellent | Save as-is; no rewrite needed |
| 16–20 | Good | Optional improvements; flag top issue only |
| 11–15 | Fair | Recommend rewrite; surface top 2-3 issues |
| 6–10 | Poor | Strongly recommend rewrite; surface all issues |
| 5 | Unusable | Block save (if all dimensions score 1); require rewrite |

### Dimension 1: Task Clarity (1–5)

Assess how clearly the prompt states what the user wants the AI to do. Look for a specific action verb, a defined subject, and an unambiguous task statement.

- **5**: Single, specific action stated explicitly. Zero ambiguity about what to do. Example: "Write a three-paragraph executive summary of the attached financial report focusing on revenue trends and cash flow."
- **4**: Action is clear but one minor detail is implicit or inferrable. Example: "Summarize this financial report for executives." (format and focus implicit but reasonable to infer)
- **3**: Action is identifiable but requires interpretation. Example: "Do something with this report." (what to do is unclear)
- **2**: Multiple conflicting interpretations possible. Example: "Help me with the report." (help how? which report?)
- **1**: No discernible task. Example: "Report." or "Make this better."

### Dimension 2: Context Provided (1–5)

Assess whether the prompt supplies enough background for the AI to produce a relevant response without asking clarifying questions.

- **5**: All necessary context provided: audience, purpose, domain, constraints, and any relevant background. The AI could produce a high-quality result on the first attempt.
- **4**: Most context present; one minor element is missing but can be reasonably assumed.
- **3**: Some context present but significant gaps exist (e.g., audience unknown, purpose unclear, domain unstated).
- **2**: Minimal context. The AI must make many assumptions to proceed. Output will be generic.
- **1**: No context provided beyond the bare task statement.

### Dimension 3: Output Format Specified (1–5)

Assess whether the prompt defines what the response should look like: length, structure, format, and any constraints on output.

- **5**: Format fully specified: length (word count or number of items), structure (bullet list, table, numbered steps, paragraph), tone, and any exclusions (e.g., "no jargon", "no markdown"). Example: "Provide a bullet list of 5 action items, each under 15 words."
- **4**: Most format details specified; one element (e.g., exact length) is missing.
- **3**: Format partially specified (e.g., "write a list" with no length or "keep it short" with no definition of short).
- **2**: Format only vaguely implied by the task type (e.g., "write an email" implies prose, but no other constraints).
- **1**: No format guidance at all. The AI must decide entirely on its own.

### Dimension 4: Constraints Defined (1–5)

Assess whether the prompt defines what to avoid, what not to include, and what limits apply.

- **5**: Explicit constraints defined: scope limits, exclusions, tone restrictions, length limits, and guardrails. Example: "Do not include pricing information. Keep the tone formal. Avoid first-person voice."
- **4**: One or two key constraints present; minor gaps exist.
- **3**: At least one constraint stated but others missing for a task that requires them.
- **2**: No constraints stated but the task clearly needs them (e.g., a "summarize everything" prompt with no scope limit).
- **1**: No constraints of any kind. The task is unbounded.

### Dimension 5: Example Included (1–5)

Assess whether the prompt provides a worked example, a reference sample, or a few-shot demonstration that anchors the expected output.

- **5**: Concrete example or sample output provided. Example: "Here is an example of the format: [sample text]. Match this format."
- **4**: A reference or analogy provided that anchors the expected style or tone, even if not a full example.
- **3**: Example implied but not written out (e.g., "like the last email I sent" with no actual email quoted).
- **2**: No example, but the task is simple enough that one is optional.
- **1**: No example and the task is complex or stylistic enough that the absence materially hurts output quality.

Note: A score of 2 on Dimension 5 is acceptable for simple factual or procedural prompts. Reserve scores of 1 for cases where the lack of an example is a genuine quality problem.

---

## Anti-Pattern Detection

Before scoring or rewriting, scan the prompt for these anti-patterns. Flag each one found. Anti-patterns reduce quality scores directly and are targeted first during rewrite.

### Anti-Pattern 1: Vague Action Verbs

**Signs**: Uses "help me", "do something about", "work on", "look at", "deal with" instead of specific action verbs.

**Impact**: Reduces Task Clarity (Dimension 1) to 1 or 2.

**Fix**: Replace with a specific verb from the prompt engineering lexicon: write, summarize, extract, classify, compare, translate, evaluate, list, draft, outline, explain, identify, generate, convert.

### Anti-Pattern 2: No Audience or Recipient

**Signs**: The prompt does not state who the output is for, even when the audience would materially affect tone, vocabulary, or depth (e.g., "explain this" without saying to whom).

**Impact**: Reduces Context Provided (Dimension 2) and Output Format Specified (Dimension 3) by 1–2 points.

**Fix**: Add audience: "...for a non-technical founder", "...for the client", "...for an internal team standup".

### Anti-Pattern 3: Unbounded Scope

**Signs**: "Analyze everything", "cover all the main points", "summarize the entire document". No limit on what to include.

**Impact**: Reduces Constraints Defined (Dimension 4) to 1 or 2 and produces bloated, unfocused output.

**Fix**: Add a scope limit: "top 3 themes", "no more than 5 items", "focus only on Q4 data".

### Anti-Pattern 4: Conflicting Instructions

**Signs**: The prompt contains contradictory directives. "Keep it brief but comprehensive." "Be formal but conversational." "Give a summary and also include all the details."

**Impact**: Reduces Task Clarity (Dimension 1) by 2 points. The AI will arbitrarily pick one directive and ignore the other.

**Fix**: Choose one directive or explicitly define how to resolve the conflict: "Keep it brief (under 200 words) by covering the 3 most important points only."

### Anti-Pattern 5: Missing Output Format on Complex Tasks

**Signs**: A complex or multi-step task (analysis, comparison, report) with no stated output format. The task requires a structured response but none is specified.

**Impact**: Reduces Output Format Specified (Dimension 3) to 1 and produces inconsistently structured output.

**Fix**: Add format explicitly: "Return results as a markdown table with columns: [col1], [col2], [col3]."

### Anti-Pattern 6: Passive or Indirect Phrasing

**Signs**: "It would be great if...", "Could you possibly...", "I was wondering if you could...". Overly deferential framing that buries the actual instruction.

**Impact**: Minor clarity reduction. More importantly, it wastes characters and introduces hedging that can dilute the task signal.

**Fix**: Open with the imperative instruction directly: "Write..." / "Extract..." / "Summarize..."

### Anti-Pattern 7: Over-Length Prompts (Instruction Dilution)

**Signs**: The prompt exceeds ~500 words for a single discrete task. More than 5 separate instructions in one prompt. Instructions buried in long paragraphs of context.

**Impact**: Reduces Task Clarity (Dimension 1) because the core instruction is diluted. May also reduce compliance with the most important constraints.

**Fix**: Split into sequential prompts or clearly label sections: "CONTEXT:", "TASK:", "FORMAT:", "CONSTRAINTS:". Move supplementary detail to a structured attachment rather than inline prose.

---

## Rewrite Strategies

Apply these strategies during active rewrite mode (`/founder-os:prompt:optimize`). Select the strategies that address the lowest-scoring dimensions. Apply up to 3 strategies per rewrite to avoid over-engineering.

### Strategy 1: Front-Load the Action

Move the primary action verb to the first word or first sentence. The AI should not have to read multiple sentences before knowing what to do.

Before: "Looking at the attached email thread, I need you to figure out what follow-ups are needed and maybe draft some responses."
After: "Extract all follow-up actions from the email thread below and draft a response for each."

### Strategy 2: Add Audience and Purpose Context

Insert a single sentence naming the audience and the purpose before the task statement.

Template: "The output is for [audience] to [purpose]. [Task instruction]."

Example: "The output is for a client proposal deck. Summarize the three strongest differentiators of our product in 2–3 sentences each."

### Strategy 3: Specify Output Structure

Add an explicit format block after the task instruction.

Template: "Format the response as: [format description]."

Common formats: numbered list, bullet list with headers, markdown table (specify columns), paragraph with H2 sections, JSON object (specify keys), plain text under [N] words.

### Strategy 4: Add Scope Constraints

Add a constraints block that limits the scope to prevent over-generation.

Template: "Constraints: [constraint 1]. [constraint 2]. [constraint 3]."

Example: "Constraints: Focus only on the last 90 days of data. Do not include competitor names. Keep each point under 20 words."

### Strategy 5: Insert a Few-Shot Example

Add a short example output that demonstrates the expected style, format, and depth.

Template: "Example output: [1-3 lines of example]. Match this format and depth."

Use when: the task involves creative writing, style matching, specific formatting, or judgment calls where the correct output is not obvious from the task description alone.

### Strategy 6: Decompose Multi-Task Prompts

Split prompts containing multiple independent tasks into a numbered sequence.

Before: "Summarize the report, extract action items, and write a follow-up email."
After:
```
1. Summarize the report in 3 bullet points (top-level findings only).
2. Extract all explicit action items as a numbered list with owner and deadline.
3. Draft a follow-up email to the team sharing the summary and action list.
```

### Strategy 7: Replace Vague Modifiers

Replace subjective quality words with measurable criteria.

| Vague | Replace with |
|-------|--------------|
| "brief" | "under [N] words" or "[N] sentences max" |
| "detailed" | "cover [N] specific aspects: [list them]" |
| "professional" | "formal tone, no contractions, no slang" |
| "comprehensive" | "include: [list required sections]" |
| "simple" | "assume the reader has no background in [domain]" |

---

## Improvement Suggestions Format

Return improvement suggestions in this structure for both passive quality-check mode and active rewrite mode:

```
QUALITY SCORE: [total] / 25 — [Quality Tier]

DIMENSION SCORES:
- Task Clarity:       [score]/5
- Context Provided:   [score]/5
- Output Format:      [score]/5
- Constraints:        [score]/5
- Example Included:   [score]/5

ANTI-PATTERNS DETECTED:
- [Anti-pattern name]: [one-line explanation of where it appears]

TOP ISSUES:
1. [Highest-impact issue]: [Concrete fix in one sentence]
2. [Second issue]: [Concrete fix]
3. [Third issue, if applicable]: [Concrete fix]

REWRITTEN PROMPT: [Only present in /founder-os:prompt:optimize mode]
[Full rewritten prompt text]

CHANGES MADE:
- [Change 1]: [Why this improves the prompt]
- [Change 2]: [Why this improves the prompt]
```

In passive quality-check mode (called from `/founder-os:prompt:add`):
- Present the score and top issues.
- Do not produce a rewritten prompt unless the user asks.
- If the score is 21+, acknowledge quality and proceed with save without presenting the full report.
- If the score is 10 or below, recommend running `/founder-os:prompt:optimize` before saving and ask whether to proceed.

In active rewrite mode (called from `/founder-os:prompt:optimize`):
- Always produce the full rewritten prompt.
- Preserve the original intent and any `{{variable}}` placeholders.
- Do not add `{{variables}}` the user did not intend.
- Confirm the rewrite with the user before offering to save it back to the library.

---

## Edge Cases

### Very Short Prompts (Under 20 Words)

Do not automatically penalize short prompts. A 10-word prompt can score 25/25 if it is specific, contextual, formatted, constrained, and accompanied by an example. Score each dimension independently of length. Flag length as a concern only when brevity is the cause of a low dimension score.

### Prompts With Many Variables

Prompts containing 5 or more `{{variables}}` are higher risk for under-specification. Each variable represents a decision point the user must fill in. Check that the prompt still makes sense if a variable is left empty or filled incorrectly. Flag prompts where a missing variable would make the entire prompt unusable (vs. merely reducing quality).

### Prompts in Non-English Languages

Apply the same scoring rubric. Do not down-score for language. Identify anti-patterns using the same logic applied to English prompts. Produce rewrites in the same language as the original prompt.

### Prompts That Are Already Instructions to Claude

Some saved prompts are meta-prompts that instruct Claude to behave in a certain way (e.g., "Act as a senior copywriter and review my drafts"). Apply the rubric with modified expectations: Dimension 5 (Example Included) is rarely applicable to role-setting prompts. Penalize vague role definitions (Dimension 2) heavily -- a role prompt without a defined scope is not useful.

### Rewrite Preserves Intent

Never change the meaning or intent of the prompt during rewrite. If the original prompt has a factual error or problematic instruction, flag it as a note but do not silently correct it. Example: If a prompt says "write a 10,000-word summary", flag that this is likely an error ("did you mean 100 words?") rather than silently rewriting to a shorter length.

---

## Reference

For detailed scoring examples showing before/after prompts at each score level (1–5) across all dimensions, and worked rewrite walkthroughs, see `${CLAUDE_PLUGIN_ROOT}/skills/prompt/prompt-optimization/references/scoring-rubric.md`.
