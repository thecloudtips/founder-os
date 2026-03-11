---
name: Founder Voice
description: "Applies an authentic founder writing voice to LinkedIn post content. Activates when the user wants content that sounds like a real founder, needs style matching, or asks 'make this sound more like me.' Calibrates tone, sentence rhythm, and opinion strength for professional authenticity on LinkedIn."
globs:
  - "commands/linkedin-*.md"
---

# Founder Voice

Apply a consistent, opinionated writing voice to LinkedIn post content. Used by: `/founder-os:linkedin:post`, `/founder-os:linkedin:variations`, and `/founder-os:linkedin:from-doc` commands when composing or editing LinkedIn posts. This skill defines the tone, rhythm, opinion style, and structural patterns that distinguish a founder-written LinkedIn post from generic content marketing.

## Tone Profile

Write as a founder who has built things, made mistakes, and is sharing lessons with peers -- not as a marketer, influencer, or corporate communications team. The voice sits at the intersection of three qualities:

**Professional**: Demonstrate domain expertise without performing it. Use precise terminology where it matters. Back claims with specifics -- numbers, timelines, named tools, real outcomes. LinkedIn is a professional network. Respect that context.

**Conversational**: Write the way a sharp founder talks to another founder at a conference hallway conversation. Use contractions. Ask rhetorical questions. Let personality come through. Prefer "most founders" over "you" when making generalizations. Keep the warmth of a peer, not the distance of a thought leader.

**Opinionated**: Take a position and own it. Do not hedge with "it depends" unless genuinely explaining a trade-off. State what works, what does not, and why. Followers engage with perspective, not balanced summaries they could get from a search engine.

### Tone Boundaries

Calibrate between two failure modes:

| Too Corporate | Target Zone | Too Casual |
|--------------|-------------|------------|
| "We are pleased to announce our strategic initiative" | "We changed how we hire. Here is what happened." | "lol we totally messed up hiring" |
| "Stakeholders should consider the implications" | "If you run a team under 20, this changes everything" | "honestly idk but seems kinda wild" |
| "I am humbled and honored to share" | "Took me 3 years to figure this out. Sharing so it takes you 3 weeks." | "hot take but whatever" |

The target zone is authoritative without being stiff, direct without being sloppy, personal without being performative.

---

## Sentence Patterns

### Rhythm: Short-Long Alternation

Alternate between short, punchy sentences and supporting detail. Short sentences carry the opinion. Longer sentences carry the evidence. LinkedIn readers scan vertically -- every line must earn attention.

**Pattern**: Statement. Expansion. Statement. Evidence.

Open every post or major shift in thought with a strong declarative sentence. Follow it with context, reasoning, or a specific example that earns the claim.

### Sentence Length Rules

- Lead sentences: 3-8 words. Make them hit.
- Supporting sentences: 10-20 words. Provide context, examples, or reasoning.
- Maximum sentence length: 25 words. If a sentence exceeds 25 words, split it.
- Avoid three consecutive sentences of similar length. Monotone rhythm kills scroll-stopping power.

### Line Break Rules

LinkedIn renders single line breaks as visual separation. Use this to control pacing:

- One idea per line. When a new thought starts, start a new line.
- Short paragraphs: 1-3 sentences maximum. Dense paragraphs get scrolled past.
- Insert a blank line between distinct ideas for visual breathing room.
- Use single-line statements for emphasis -- the equivalent of a one-sentence paragraph in long-form writing.
- Never stack more than 4 consecutive lines without a blank line break.

### Paragraph Structure

- Target 1-3 sentences per paragraph. A LinkedIn post is not an essay.
- One idea per paragraph. When a new idea starts, break.
- Use one-line paragraphs for emphasis -- but no more than two per post.
- The first 2-3 lines must hook before the "see more" fold. Front-load the strongest line.

---

## Opinion Injection

### The Fact-Take-Ground Framework

When introducing a development, trend, or lesson, follow this compressed sequence:

1. **State the fact** (1 sentence): What happened or what exists.
2. **State the take** (1 sentence): Why it matters, who it affects, or what it changes.
3. **Ground it** (1 sentence): Connect the take to a specific scenario, metric, or outcome.

One sentence each. Maximum. LinkedIn rewards directness. Extended buildup loses readers before the take lands.

Trigger phrases for opinion injection:

- "Here is why this matters."
- "The part nobody is talking about."
- "What this actually means in practice."
- "Most people are reading this wrong."
- "I have been saying this for [time]. Now the data backs it up."
- "Stop doing [thing]. Start doing [thing]."

### Opinion Rules

- **One strong opinion per post.** A LinkedIn post is not a newsletter. Pick one hill and stand on it.
- **Earn opinions with specifics.** Pair every opinion with at least one concrete detail -- a number, a company name, a timeframe, a personal experience.
- **Disagree with ideas, not people.** "This approach fails because..." not "People who do this are wrong."
- **Acknowledge trade-offs when they are real.** One sentence naming the strongest counterargument adds credibility.
- **Signal confidence level.** Distinguish between "I am certain" takes and "I am betting on" takes.

---

## Practical Framing

Every post must answer: **"What does this mean for the reader, and what should they do about it?"**

### The Practical Bridge

After presenting an insight or story, insert a practical bridge before closing:

- **"What this means for you"**: Translate the abstract into the specific. "If you are running a B2B SaaS under $5M ARR, this means your onboarding needs to change."
- **"How to use this"**: Give a concrete next step. "Open your CRM right now. Look at your last 10 closed-lost deals. Spot the pattern."
- **"What I am doing about it"**: Share a personal action. "I changed our hiring process last quarter because of exactly this."

### Practical Framing Rules

- Never end a post on a description. End on an action, a question, or a recommendation.
- Quantify whenever possible. "This saves time" is weak. "This cut our onboarding from 3 weeks to 4 days" is strong.
- Name tools and approaches by name. Do not say "a popular CRM" when "HubSpot" or "Notion" is what is meant.
- Default to the small-team lens. Founder OS readers run teams of 1-50. Frame advice for that context, not for enterprise.

### LinkedIn CTA Patterns

Close with one (never more than one) call to action. Match the CTA to the post type:

- **Discussion**: "What has worked for your team? Drop it in the comments."
- **Sharing**: "If this resonates, share it with a founder who needs to hear it."
- **Follow**: "I write about [topic] weekly. Follow for more."
- **Resource**: "Full breakdown linked in the first comment."
- **No CTA**: Sometimes the best close is the final line of the post. Not every post needs an explicit ask.

Avoid generic CTAs that apply to every post. The CTA should feel like a natural extension of the specific content.

---

## Storytelling Patterns

### Pattern 1: Anecdote-Lesson

Open with a brief personal anecdote that illustrates a problem or realization. Transition with a bridge line. Deliver the lesson.

Structure:
- **Anecdote** (2-3 sentences): Specific, grounded, first-person. Include one detail that makes it real -- a date, a dollar amount, a tool name, a reaction.
- **Bridge** (1 line): Connect the personal to the universal. "That is when I realized..." or "Turns out this is not just my problem."
- **Lesson** (1-2 sentences): The generalizable insight. Short and declarative.

Keep anecdotes tight. LinkedIn is not the place for 6-sentence backstory. Get in, make the point, get out.

### Pattern 2: Before-After Comparison

Show the contrast between the old way and the new way. Make the reader feel the pain of "before" and the relief of "after."

Structure:
- **Before** (1-2 sentences): Describe the painful status quo. Use a concrete detail -- hours wasted, money lost, frustration.
- **Pivot** (1 line): Name the change -- a tool, a process, a mindset shift.
- **After** (1-2 sentences): Describe the improved state mirroring the same metrics from "before."

### Pattern 3: Problem-Solution

State a problem the reader likely faces. Validate it. Present a solution with implementation detail.

Structure:
- **Problem** (1 sentence): Name the problem directly. Do not ease into it.
- **Validation** (1 sentence): Show the reader they are not alone. "Every founder I have talked to this quarter has hit this wall."
- **Solution** (2-3 sentences): Specific, actionable, implementable this week.

### Storytelling Rules

- Use one storytelling pattern per post. Mixing patterns in a short-form post creates confusion.
- Anecdotes must be specific. "A founder I know" is weaker than "A B2B SaaS founder running a 12-person team in Austin."
- Never fabricate anecdotes. If no personal story applies, use a before-after or problem-solution pattern instead.

---

## Anti-Patterns

Reject the following patterns in all LinkedIn post content. When encountered in draft text, rewrite to eliminate them.

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
| "thought leadership" | never use -- show expertise through content, do not label it |
| "scalable solution" | name the specific capability and its limit |
| "ecosystem" (unless literally) | name the actual components |
| "robust" | name the specific quality: reliable, fast, handles edge cases |

### Dead Openers

Never open a LinkedIn post with:

- "I am excited to share..." -- Skip the emotion label. Share the thing.
- "Happy [day of week]!" -- Not why someone stops scrolling.
- "Big news!" -- The reader decides what is big. Lead with the substance.
- "Thrilled to announce..." -- Same as "excited to share." Start with what changed.
- "Quick thought:" -- Every LinkedIn post is a thought. This adds nothing.
- "Hot take:" -- Let the take be hot on its own. Labeling it weakens it.
- "PSA:" -- Rarely is a LinkedIn post a public service announcement.

### Passive Voice Overuse

Use active voice by default. Passive voice is acceptable only when the actor is genuinely unknown or irrelevant. If an agent or subject exists, name it.

- Bad: "A decision was made to pivot the product."
- Good: "We pivoted the product in March after losing our third enterprise deal in a row."

Limit passive constructions to no more than one per post.

### Hedging Language

Remove weak qualifiers that undermine authority:

- "I think maybe..." -- State the position or do not.
- "It might be worth considering..." -- State whether it is worth it.
- "Some people say..." -- Name who says it or own the take.
- "In my humble opinion..." -- Drop "humble." Followers follow for opinions.
- "Arguably..." -- Make the argument or skip it.
- "Just my two cents..." -- The reader already knows that. Eliminate the disclaimer.

### LinkedIn-Specific Anti-Patterns

Reject these patterns unique to the LinkedIn format:

**Engagement bait**: Never use hollow engagement prompts that add no value.
- "Like if you agree" / "Repost if this resonates" / "Comment YES if you..." -- These phrases signal that the content cannot earn engagement on its own. If the post is valuable, people will engage without being instructed.

**Humble brags**: Never disguise self-promotion as humility.
- "Humbled to announce..." / "Blessed to share..." / "Never imagined I would..." -- State the achievement plainly and connect it to a lesson the reader can use. Self-deprecation wrapped around self-promotion is still self-promotion.

**Hashtag abuse**: Limit to a maximum of 5 hashtags per post. Place them at the end, not inline. Prefer 3 targeted hashtags over 5 broad ones. Never use a hashtag in the middle of a sentence.

**Emoji overload**: Limit to a maximum of 3 emojis per post. Use them as visual markers (bullet alternatives or section breaks), never as emotional amplifiers. A post that needs emoji to convey tone has a writing problem, not a formatting problem.

**Thread bait**: Never write "Thread" or use thread emojis on a single standalone post. If the content requires a thread/carousel format, the post itself should signal that through structure, not a label.

**Self-congratulation without value**: Never post achievements without connecting them to something the reader can learn or use. "Just hit 10k followers!" is noise. "Hit 10k followers. Here is the one format change that doubled my growth rate" is content.

**Wall of text**: Never publish a post without line breaks. If a post looks like a paragraph from a legal brief, it will be scrolled past regardless of content quality. Break every 1-3 sentences.

---

## Voice Reference Examples

Refer to `${CLAUDE_PLUGIN_ROOT}/skills/linkedin/founder-voice/references/voice-examples.md` for detailed before-and-after rewrite examples demonstrating how to transform generic LinkedIn content into founder voice.
