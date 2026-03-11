---
name: Founder Voice
description: "Applies a consistent, opinionated founder writing voice to newsletter content. Activates when the user wants to write in founder voice, match their style, rewrite content to sound more authentic, or needs newsletter prose that reads like a real founder — not a marketer. Covers tone calibration, sentence rhythm, opinion injection, practical framing, and anti-patterns."
globs:
  - "commands/newsletter-draft.md"
  - "commands/newsletter.md"
---

# Founder Voice

Apply a consistent, opinionated writing voice to newsletter content. Used by: `/founder-os:newsletter:draft` and `/newsletter` commands when composing or editing newsletter sections. This skill defines the tone, rhythm, opinion style, and structural patterns that distinguish a founder-written newsletter from generic content marketing.

## Tone Profile

Write as a founder who has built things, made mistakes, and is sharing lessons with peers — not as a marketer, journalist, or academic. The voice sits at the intersection of three qualities:

**Professional**: Demonstrate domain expertise. Use precise terminology where it matters. Back claims with specifics — numbers, timelines, named tools, real outcomes. Never dumb down for the sake of accessibility.

**Conversational**: Write the way a smart founder talks to another founder over coffee. Use contractions. Ask rhetorical questions. Interrupt a point to add a sidebar. Let personality show through. Address the reader directly but sparingly — prefer "most founders" over "you" when making generalizations.

**Opinionated**: Take a position and own it. Do not hedge with "it depends" unless genuinely explaining a trade-off. State what works, what does not, and why. Readers subscribe for perspective, not for balanced summaries they could get from a search engine.

### Tone Boundaries

Calibrate between two failure modes:

| Too Corporate | Target Zone | Too Casual |
|--------------|-------------|------------|
| "We are pleased to present our analysis of market trends" | "Three things changed this month that every SaaS founder should know about" | "lol this blew up on Twitter so here we go" |
| "Stakeholders should consider the implications" | "If you are running a team under 20, this changes how you hire" | "honestly idk but it seems kinda wild" |
| "It is worth noting that industry consensus suggests" | "Most founders I talk to are getting this wrong. Here is why." | "hot take but whatever" |

The target zone is authoritative without being stiff, direct without being sloppy.

---

## Sentence Patterns

### Rhythm: Short-Long Alternation

Alternate between short, punchy sentences (4-10 words) and longer explanatory ones (15-25 words). Short sentences carry the opinion. Long sentences carry the evidence.

**Pattern**: Statement. Expansion. Statement. Evidence. Transition.

Open every section or major point with a strong declarative sentence. Follow it with context, reasoning, or a specific example that earns the claim.

### Sentence Length Rules

- Lead sentences of sections: 4-12 words. Make them land.
- Supporting sentences: 15-25 words. Provide context, examples, or reasoning.
- Maximum sentence length: 30 words. If a sentence exceeds 30 words, split it.
- Avoid three consecutive sentences of similar length. Monotone rhythm kills engagement.

### Paragraph Structure

- Target 2-4 sentences per paragraph. A newsletter is not a white paper.
- One idea per paragraph. When a new idea starts, start a new paragraph.
- Use one-sentence paragraphs for emphasis — but no more than one per section.

---

## Opinion Injection

### The "Here Is Why This Matters" Framework

When introducing a development, trend, or tool, follow this sequence:

1. **State the fact** (1 sentence): What happened or what exists.
2. **State the take** (1-2 sentences): Why it matters, who it affects, or what it changes. Lead with "Here is why this matters" or a variant pattern.
3. **Ground it** (1-3 sentences): Connect the take to a specific scenario, metric, or outcome the reader can verify.

Variant trigger phrases for opinion injection:
- "Here is why this matters for [audience]..."
- "The part nobody is talking about..."
- "What this actually means in practice..."
- "This changes one thing..."
- "Most people are reading this wrong. The real signal is..."
- "I have been saying this for [time] — now the data backs it up."

### Opinion Rules

- **One strong opinion per section.** Multiple competing opinions dilute all of them.
- **Earn opinions with specifics.** An unsupported take is just noise. Pair every opinion with at least one concrete detail — a number, a company name, a timeframe, a personal experience.
- **Disagree with ideas, not people.** "This approach fails because..." not "People who do this are wrong."
- **Acknowledge trade-offs when they are real.** Opinions gain credibility when the writer names the strongest counterargument and explains why the take still holds.
- **Signal confidence level.** Distinguish between "I am certain" takes and "I am betting on" takes. Readers respect intellectual honesty.

---

## Practical Framing

Every piece of news, trend, or insight must answer: **"What does this mean for the reader, and what should they do about it?"**

### The Practical Bridge Pattern

After presenting information, insert a practical bridge before moving on:

- **"What this means for you"**: Translate the abstract into the specific. "If you are running a B2B SaaS under $5M ARR, this means your CAC payback window just got 20% longer."
- **"How to use this"**: Give a concrete next step. "Open your analytics dashboard right now and check your last 90 days of trial-to-paid conversion. If it dropped below 8%, this applies to you."
- **"What I am doing about it"**: Share a personal action. "I moved our entire onboarding sequence to async video last month because of exactly this trend."

### Practical Framing Rules

- Never end a section on a description. End on an action, a question, or a recommendation.
- Quantify whenever possible. "This saves time" is weak. "This saves 4 hours per week on a 10-person team" is strong.
- Name tools and approaches by name. Do not say "a popular project management tool" when "Linear" or "Notion" is what is meant.
- Default to the small-team lens. Founder OS readers run teams of 1-50. Frame advice for that context, not for enterprise.

---

## Storytelling Patterns

### Pattern 1: Anecdote-Lesson

Open with a brief personal anecdote (2-4 sentences) that illustrates a problem or realization. Transition with a bridge sentence. Deliver the lesson.

Structure:
- **Anecdote** (2-4 sentences): Specific, grounded, first-person. Include a detail that makes it real — a date, a dollar amount, a tool name, a reaction.
- **Bridge** (1 sentence): Connect the personal experience to the universal lesson. "That is when I realized..." or "Turns out this is not just my problem."
- **Lesson** (2-3 sentences): The generalizable insight.

### Pattern 2: Before-After Comparison

Show the contrast between the old way and the new way. Make the reader feel the pain of "before" and the relief of "after."

Structure:
- **Before** (2-3 sentences): Describe the painful status quo in specific terms. Use concrete details — hours wasted, money lost, frustration points.
- **Pivot** (1 sentence): Name the change — a tool, a process, a mindset shift.
- **After** (2-3 sentences): Describe the improved state with the same level of specificity. Mirror the "before" metrics so the comparison is direct.

### Pattern 3: Problem-Solution

State a problem the reader likely faces. Validate it. Present a solution with implementation detail.

Structure:
- **Problem** (1-2 sentences): Name the problem directly. Do not ease into it.
- **Validation** (1 sentence): Show the reader they are not alone. "Every founder I have talked to this quarter has hit this wall."
- **Solution** (2-4 sentences): Specific, actionable, implementable this week.

### Storytelling Rules

- Use one storytelling pattern per major section. Mixing patterns in a single section creates confusion.
- Anecdotes must be specific. "A founder I know" is weaker than "A B2B SaaS founder running a 12-person team in Austin." Specificity creates trust.
- Never fabricate anecdotes. If no personal story applies, use a before-after or problem-solution pattern instead.

---

## Anti-Patterns

Reject the following patterns in all newsletter content. When encountered in draft text, rewrite to eliminate them.

### Corporate Jargon

Remove or replace these phrases on sight:

| Jargon | Replacement |
|--------|-------------|
| "leverage" (as verb) | "use" |
| "synergize" / "synergies" | name the specific benefit |
| "move the needle" | "increase [specific metric] by [amount]" |
| "at the end of the day" | cut the phrase entirely |
| "circle back" | "revisit" or "follow up on" |
| "deep dive" | "detailed look at" or "breakdown of" |
| "paradigm shift" | describe the actual change |
| "best-in-class" | name what makes it better and than what |
| "thought leadership" | never use — show expertise through content, do not label it |
| "scalable solution" | name the specific capability and its limit |
| "ecosystem" (unless literally) | name the actual components |
| "robust" | name the specific quality: reliable, fast, handles edge cases |

### Dead Openers

Never open a newsletter or section with:

- "In this issue, we will discuss..." -- Start with the most interesting thing, not a table of contents.
- "Welcome to this week's edition of..." -- The reader knows what they opened. Get to the point.
- "Happy [day of week]!" -- Not the reader's reason for opening.
- "It's been a busy week..." -- Irrelevant to the reader. Never open with the writer's schedule.
- "As promised, here is..." -- Skip the meta-commentary. Deliver the content.
- "Before we get started..." -- Then get started.

### Passive Voice Overuse

Use active voice by default. Passive voice is acceptable only when the actor is genuinely unknown or irrelevant (e.g., "The feature was deprecated" when the company has not been named). If an agent or subject exists, name it.

- Bad: "A decision was made to deprecate the API."
- Good: "Stripe deprecated their v1 API last Tuesday."

Limit passive constructions to no more than one per five sentences.

### Listicle-Only Format

Never structure an entire newsletter as a numbered list of items with no connecting narrative. Lists are tools, not structures. A newsletter is a narrative with lists inside it, not a list with narrative dressing.

Rules for list usage:
- Use bulleted or numbered lists for 3+ parallel items (tools, steps, metrics).
- Introduce every list with a lead-in sentence that provides context.
- Follow every list with at least one sentence of synthesis or opinion.
- Maximum list length: 7 items. Beyond 7, group into categories or cut.

### Hedging Language

Remove weak qualifiers that undermine authority:

- "I think maybe..." -- State the position or do not.
- "It might be worth considering..." -- State whether it is worth it.
- "Some people say..." -- Name who says it or own the take.
- "In my humble opinion..." -- Drop "humble." It is a newsletter. The reader subscribed for opinions.
- "Arguably..." -- Make the argument or skip it.

---

## Voice Reference Examples

Refer to `${CLAUDE_PLUGIN_ROOT}/skills/newsletter/founder-voice/references/voice-examples.md` for detailed before-and-after rewrite examples demonstrating how to transform generic content marketing into founder voice.
