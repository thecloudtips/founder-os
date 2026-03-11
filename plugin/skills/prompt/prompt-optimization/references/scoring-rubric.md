# Prompt Optimization Scoring Rubric — Reference

Detailed examples for each dimension score (1–5), before/after rewrite walkthroughs, and calibration guidance. Consult this file when a dimension score is unclear or when the main SKILL.md summary is not sufficient for a particular case.

---

## Dimension 1: Task Clarity — Score Examples

### Score 5 — Excellent Clarity

The task is stated with a specific action verb, a specific object, and no ambiguity about what to produce.

**Example A (report summary)**
> "Write a three-paragraph executive summary of the financial report below. Paragraph 1: revenue performance vs. target. Paragraph 2: cash flow position. Paragraph 3: top three risks for the quarter."

**Example B (email)**
> "Draft a follow-up email to a prospective client who attended our webinar two days ago. The email should reference the webinar topic, offer a 30-minute discovery call, and include a specific time slot."

**Example C (extraction)**
> "Extract every action item from the meeting transcript below. For each action item, identify: the responsible person, the deadline (if stated), and the priority level (High/Medium/Low)."

---

### Score 4 — Clear With Minor Implicit Details

The core action is unambiguous. One supporting detail (e.g., length, tone, recipient) is implicit but reasonably inferrable.

**Example A**
> "Summarize this meeting transcript into key decisions and action items."
(Action is clear; format for decisions vs. items is implicit but standard.)

**Example B**
> "Translate the following paragraph into Spanish."
(Task is clear; dialect and formality level are unstated but can be assumed neutral.)

---

### Score 3 — Identifiable But Requires Interpretation

The general intent is visible but the specific task requires interpretation. Multiple valid approaches exist.

**Example A**
> "Do something with this transcript."
(Summarize? Extract? Analyze? All are plausible. The AI must guess.)

**Example B**
> "Make the proposal better."
(Improve how? Tone? Structure? Length? Persuasiveness? Not defined.)

**Example C**
> "Help with the report."
(Help produce it? Edit it? Review it? Unclear.)

---

### Score 2 — Multiple Conflicting Interpretations

Two or more substantially different tasks could be inferred from the prompt. A user or AI reading it would disagree on what to do.

**Example A**
> "Review and fix the contract."
(Review = read and comment. Fix = rewrite. These require different outputs. Which is intended?)

**Example B**
> "Client email and proposal."
(Are these two separate tasks? One combined document? Context-dependent?)

---

### Score 1 — No Discernible Task

No action is implied. The prompt is a noun phrase, a fragment, or a meaningless instruction.

**Examples**
- "Report."
- "The meeting yesterday."
- "Make this better." (with no object provided)
- "Yes."

---

## Dimension 2: Context Provided — Score Examples

### Score 5 — Complete Context

Audience, purpose, domain, background, and constraints are all present.

**Example**
> "You are writing for a non-technical founder who has never used an API before. The goal is to explain what an API is and why it matters for connecting business tools, in the context of a blog post about no-code automation. Assume the reader is familiar with tools like Zapier but not with code."

Everything the AI needs to calibrate depth, vocabulary, and relevance is provided.

---

### Score 4 — Most Context Present

One context element is missing but the rest is sufficient.

**Example**
> "Write an explanation of API integrations for non-technical founders. The context is a blog post about automation tools."
(Audience and purpose present; background depth assumption is missing but inferrable.)

---

### Score 3 — Some Context, Significant Gaps

Enough context to attempt the task, but meaningful assumptions are required that could send output in the wrong direction.

**Example**
> "Explain API integrations simply."
(Who is the audience? What level of "simple"? What domain? What format? All are undefined.)

---

### Score 2 — Minimal Context

The AI must make foundational assumptions that a small variation in would produce completely different output.

**Example**
> "Explain APIs."
(Domain: unknown. Audience: unknown. Purpose: unknown. Output could be a textbook chapter or a tweet.)

---

### Score 1 — No Context

Only the bare subject is present. The AI has zero anchors for producing a useful response.

**Examples**
- "API."
- "The meeting."
- "Our product."

---

## Dimension 3: Output Format Specified — Score Examples

### Score 5 — Fully Specified Format

Length, structure, format type, and tone are all explicitly stated.

**Example**
> "Return a bullet list of exactly 5 action items. Each bullet should follow this format: '[Owner]: [Action] by [Deadline]'. Use past tense for completed items and future tense for pending items. No preamble or summary — just the 5 bullets."

---

### Score 4 — Most Format Specified

Core structure is defined; one element (typically exact length) is implicit.

**Example**
> "Write a professional email declining the meeting request. Keep it short and polite."
(Prose format is implied by "email"; "short" is vague but appropriate for the context.)

---

### Score 3 — Partial Format

One format dimension is stated but others critical to the task are absent.

**Example**
> "Give me a list of risks."
(List format stated; but how many? What structure per item? Severity-ordered or random? Undefined.)

---

### Score 2 — Format Only Vaguely Implied

No explicit format, but the task type implies a default format. The AI will use that default, which may or may not match the user's intent.

**Example**
> "Summarize the report."
(Summaries are typically prose; but could be a structured list, an executive table, or a single sentence.)

---

### Score 1 — No Format Guidance

No format cues at all. The task is open-ended and the AI will produce whatever default it considers appropriate.

**Example**
> "Tell me about the risks in this project."
(Free-form; no length, structure, or format implied.)

---

## Dimension 4: Constraints Defined — Score Examples

### Score 5 — Explicit Constraints

Multiple constraints are stated covering scope, exclusions, tone, and limits.

**Example**
> "Summarize only the revenue section of the report. Do not include headcount, operational costs, or projections. Keep the summary under 150 words. Use formal language. Do not include bullet points — prose only."

---

### Score 4 — Key Constraints Present

One or two key constraints defined; minor gaps exist.

**Example**
> "Summarize the revenue section only. Keep it under 200 words."
(Scope limited, length limited; tone and format unspecified but not critical for this task.)

---

### Score 3 — At Least One Constraint Stated

One meaningful constraint is present but the task needs more.

**Example**
> "Summarize the report. Keep it professional."
(Tone constrained; scope, length, and format are all unbounded.)

---

### Score 2 — Constraints Needed But Absent

The task clearly requires scope limits to be useful, but none are provided.

**Example**
> "Analyze the entire dataset and give me all the insights."
(No scope limit, no depth specification, no output cap. This will produce an unusably broad response.)

---

### Score 1 — Completely Unconstrained

No constraints of any kind. The task is entirely open-ended.

**Examples**
- "Tell me everything about the project."
- "Analyze this."

---

## Dimension 5: Example Included — Score Examples

### Score 5 — Concrete Example Provided

A worked example, sample output, or reference text anchors the expected result.

**Example (with example embedded)**
> "Write a one-sentence value proposition for each product feature. Format: '[Feature name]: Helps [target user] [achieve outcome] without [pain point].' Example: 'AI Triage: Helps founders process 50+ daily emails in under 10 minutes without missing high-priority messages.' Write one for each of the five features listed below."

---

### Score 4 — Reference or Analogy Provided

A reference or style anchor is given even though it is not a full worked example.

**Example**
> "Write in the same tone as the Y Combinator application questions — direct, specific, no fluff."
(Points to a known reference rather than writing out a sample.)

---

### Score 3 — Example Implied But Not Written

The user gestures at an example without providing it.

**Example**
> "Write it like the last email I sent."
(No email is provided. The AI cannot access this reference.)

---

### Score 2 — No Example, But Task Is Simple Enough

The task is factual or procedural and a missing example does not significantly hurt output quality.

**Example**
> "List the 10 largest economies by GDP in 2024."
(Factual lookup. No example needed — the expected format is obvious.)

---

### Score 1 — No Example, Absence Materially Hurts Quality

The task requires stylistic judgment, custom formatting, or complex structure, and the absence of an example will produce inconsistent or wrong output.

**Example**
> "Write a cold outreach email in our company voice."
(Company voice is undefined. Without an example of past emails, the AI cannot match the intended tone, style, or structure.)

---

## Before/After Rewrite Walkthroughs

### Walkthrough 1: Vague Email Prompt

**Original prompt**
> "Help me with an email to a client."

**Score before**
- Task Clarity: 2 (help = vague; email type undefined)
- Context Provided: 1 (no client info, no purpose, no situation)
- Output Format: 2 (email implies prose, but length/tone/subject undefined)
- Constraints: 1 (nothing excluded or bounded)
- Example Included: 1 (no reference)
- **Total: 7/25 — Poor**

**Anti-patterns detected**
- Vague action verb ("help me")
- No audience or recipient context
- Missing output format on a complex task

**Rewritten prompt**
> "Draft a follow-up email to {{client_name}} after our discovery call on {{call_date}}. The email should: (1) thank them for their time, (2) recap the two problems they mentioned — {{problem_1}} and {{problem_2}} — and (3) propose a next step of scheduling a 45-minute solution walkthrough. Tone: professional and warm, not salesy. Length: under 200 words. Subject line included."

**Score after**
- Task Clarity: 5 (draft + follow-up email, defined purpose)
- Context Provided: 4 (client name, call context, problems — one element left as variable)
- Output Format: 5 (length, tone, structure, subject line specified)
- Constraints: 4 (tone and length constrained; not exhaustive but sufficient)
- Example Included: 2 (no sample, but task is clear enough without one)
- **Total: 20/25 — Good**

**Changes made**
- Replaced "help me" with "draft" (Strategy 1: front-load the action)
- Added client name, call date, and problem variables for user to fill (Strategy 2: add audience and purpose context)
- Specified three concrete content requirements as a numbered list (Strategy 6: decompose multi-task prompts)
- Added tone and length constraints (Strategy 4: add scope constraints)

---

### Walkthrough 2: Over-Long Rambling Prompt

**Original prompt**
> "I need you to look at this competitor research I've been doing and I was thinking it would be really useful to get some kind of overview of what they're doing differently from us, and also maybe think about what we could do in response, and I guess also any interesting things you notice about their pricing and positioning and stuff like that. Also if there's anything about their marketing messaging that stands out, that would be great to include too. I want to be able to share this with my co-founder so it should be readable."

**Score before**
- Task Clarity: 2 (four separate tasks buried in hedging prose)
- Context Provided: 3 (implicit competitive context; audience mentioned at end)
- Output Format: 2 (vague "readable" format; no structure specified)
- Constraints: 1 (nothing bounded — "also", "also", "also")
- Example Included: 1 (none)
- **Total: 9/25 — Poor**

**Anti-patterns detected**
- Over-length prompt with instruction dilution
- Passive/indirect phrasing throughout
- Unbounded scope ("and also any interesting things")
- Vague modifiers ("readable")
- Missing output format on complex task

**Rewritten prompt**
> "Analyze the competitor research below and produce a structured competitive brief for sharing with a co-founder. Structure the output as follows:
>
> **1. Key Differences (3–5 bullets)**
> How they differ from us in product, positioning, or approach.
>
> **2. Pricing & Positioning Summary (2–3 sentences)**
> Their pricing model and core positioning message.
>
> **3. Marketing Messaging Highlights (2–3 bullets)**
> The most notable aspects of their messaging or copy.
>
> **4. Recommended Response (2–3 bullets)**
> Specific actions we could take in response to what you found.
>
> Constraints: Focus only on the competitor data provided. Do not speculate beyond the research. Keep the full brief under 400 words."

**Score after**
- Task Clarity: 5 (analyze + produce competitive brief, each section defined)
- Context Provided: 4 (audience named, purpose clear, domain implicit)
- Output Format: 5 (four sections with length limits per section and a total word cap)
- Constraints: 4 (scope limited to provided data, speculation excluded, total length capped)
- Example Included: 2 (no example, but structure is now explicit enough)
- **Total: 20/25 — Good**

**Changes made**
- Replaced all hedging phrases with direct section headers (Strategy 1: front-load the action)
- Decomposed four tasks into four labeled sections with per-section length limits (Strategy 6: decompose multi-task prompts)
- Replaced "readable" with "under 400 words" and "for sharing with co-founder" (Strategy 7: replace vague modifiers)
- Added explicit scope constraints at the end (Strategy 4: add scope constraints)

---

### Walkthrough 3: Simple Prompt That Scores High Without Modification

**Original prompt**
> "List the top 5 reasons a SaaS startup should invest in content marketing. One sentence per reason. Numbered list."

**Score**
- Task Clarity: 5 (list + top 5 reasons, specific topic)
- Context Provided: 4 (SaaS startup audience; purpose implicit from context)
- Output Format: 5 (numbered list, one sentence per reason, count specified)
- Constraints: 4 (count limited; no other constraints needed for this task)
- Example Included: 2 (not needed for a factual list task)
- **Total: 20/25 — Good**

**Action**: No rewrite recommended. Flag to user that this prompt is well-formed. The only improvement opportunity would be adding industry context (B2B vs B2C, early-stage vs growth) to reach 23+/25, but this is optional.

---

## Calibration Notes

### When to Accept Lower Dimension 5 Scores

Dimension 5 (Example Included) is the most context-dependent dimension. Accept a score of 2 without penalizing when:
- The task is purely factual (retrieval, listing, calculation)
- The output format is universally understood (e.g., "write a haiku" does not need a haiku example)
- The task is extremely simple and the format is explicit

Require a score of 4–5 when:
- The task involves style matching ("write in the voice of...")
- The task involves custom formatting not described by standard formats
- The prompt is for a recurring workflow where consistency across runs matters

### When to Block vs. Warn on Quality Save

Block the save (score <= 5) when all five dimensions score 1. This indicates the prompt has zero usable content and would produce meaningless output. Present this as an error, not a warning.

Warn and ask for confirmation (score 6–10) when the prompt is poor but has some identifiable intent. The user may know they want a rough draft or are saving a placeholder.

Proceed without interruption (score 21–25) to keep the `/founder-os:prompt:add` flow fast for high-quality prompts. Surface the score briefly in a confirmation message ("Quality check: 23/25 — Excellent. Saving...") rather than presenting the full report.
