---
name: Hook Creation
description: "Crafts high-impact opening lines for LinkedIn posts designed to stop the scroll. Activates when the user wants a stronger hook, better opening line, or asks 'how should I start this LinkedIn post?' Covers proven hook formulas, curiosity gaps, and pattern-interrupt techniques that drive engagement."
globs:
  - "commands/linkedin-*.md"
---

# Hook Creation

Craft high-impact opening lines for LinkedIn posts that stop the scroll, survive the "see more" fold, and compel readers to expand the full post. Used by: `/founder-os:linkedin:post` (full post generation) and `/founder-os:linkedin:variations` (hook A/B testing and iteration).

## Purpose and Context

The hook is the single highest-leverage element of any LinkedIn post. LinkedIn truncates posts after approximately 210 characters (roughly 1-3 lines depending on line breaks), hiding the rest behind a "see more" link. If the hook fails, the post fails -- regardless of the quality of the body content. Every hook must accomplish three things in that narrow window: interrupt the scroll pattern, create a curiosity gap or emotional response, and establish relevance to the target audience.

For detailed hook examples organized by formula type and audience segment, see `${CLAUDE_PLUGIN_ROOT}/skills/linkedin/hook-creation/references/hook-templates.md`.

---

## Hook Length Rules

Enforce these constraints on every hook before finalizing:

- **Maximum length**: 3 lines as displayed on LinkedIn (desktop and mobile).
- **Character budget**: Keep the first visible portion under 210 characters including spaces. LinkedIn's fold point varies slightly by device, so treat 200 characters as the safe zone and 210 as the absolute ceiling.
- **Line break strategy**: Use intentional line breaks to control pacing. A single punchy line followed by a blank line followed by a second line creates visual weight. Three consecutive lines without breaks read as a paragraph and lose impact.
- **Word count**: Target 15-40 words for the complete hook. Under 15 feels incomplete; over 40 risks burying the tension point below the fold.

Test every hook by counting characters in the first visible block. If the curiosity gap, bold claim, or emotional trigger falls after character 210, restructure so it lands before the fold.

---

## Six Opening Line Formulas

Select the formula that best matches the post's content type, audience, and framework. Each formula creates a different psychological trigger.

### 1. Stat-Led

Lead with a surprising, specific number that challenges the reader's assumptions. The statistic must feel counterintuitive or alarming enough to demand explanation.

Structure: `[Specific number/percentage] + [unexpected context] + [implied "here's why"]`

Rules:
- Use precise numbers, not rounded estimates. "87% of founders" outperforms "most founders."
- The stat must connect directly to the post's core argument. Never bait with an unrelated number.
- Cite or attribute the source within the post body (not required in the hook itself, but the stat must be defensible).
- Pair naturally with Listicle, How-To, and Industry Insight frameworks.

### 2. Question

Pose a specific, provocative question that the reader cannot answer without reading further. The question must target a real tension point in the audience's work.

Structure: `[What if / Have you ever / Why do] + [specific scenario the reader recognizes] + [?]`

Rules:
- Never use questions with obvious yes/no answers. The question must demand nuance.
- Avoid rhetorical questions that feel like engagement bait ("Don't you hate when...?").
- The question should make the reader feel slightly uncomfortable or deeply curious.
- Pair naturally with Contrarian Take, Personal Lesson, and How-To frameworks.

### 3. Story

Open with a specific moment in time that drops the reader into a scene. The moment should be slightly vulnerable, surprising, or high-stakes.

Structure: `[Time marker] + [specific situation] + [unexpected turn or tension]`

Rules:
- Start in the middle of the action, not the setup. "Last Tuesday, I almost fired our best engineer" beats "I want to tell you a story about management."
- Include at least one concrete detail: a day, a place, a name, a number.
- The story hook must create an open loop -- the reader needs to know what happened next.
- Pair naturally with Personal Lesson, Contrarian Take, and Story frameworks.

### 4. Contrarian

Challenge a widely accepted belief, practice, or piece of advice. The contrarian statement must be defensible -- not merely provocative for attention.

Structure: `[Stop/Don't/Forget about] + [accepted practice] + [consequence or alternative]`

Rules:
- The challenged belief must be something the target audience actually holds. Contrarian takes against straw-man positions fall flat.
- Follow the contrarian opener immediately with a hint of the alternative. "Stop doing X" alone is incomplete; "Stop doing X. It's killing your Y" creates the gap.
- Never be contrarian about values or ethics -- challenge tactics, tools, and conventional wisdom.
- Pair naturally with Contrarian Take, Industry Insight, and Personal Lesson frameworks.

### 5. Bold Claim

Make an authoritative statement that positions the author as someone with insider knowledge or pattern recognition. The claim should feel like access to a secret or hard-won insight.

Structure: `[The best/top/most successful] + [audience group] + [specific behavior or belief]`

Rules:
- Back the claim with observable patterns, not opinion. "The best founders I know" implies a sample set, so the post must deliver evidence.
- Avoid superlatives that cannot be substantiated ("the single most important thing ever").
- The claim must feel earned -- it should sound like it comes from direct experience, not armchair analysis.
- Pair naturally with Listicle, How-To, Industry Insight, and Personal Lesson frameworks.

### 6. Pattern Interrupt

Issue an unexpected command, make a jarring declaration, or present an absurd juxtaposition that breaks the reader's mental model of what LinkedIn posts look like.

Structure: `[Short unexpected command or statement] + [line break] + [context that reframes the command]`

Rules:
- Keep the interrupt to 2-6 words. Brevity is the mechanism. "Delete your to-do list." works because it is short and commands action.
- The second line must immediately provide context or tension -- without it, the interrupt is just noise.
- Never use all caps, excessive punctuation, or emoji clusters as the interrupt. The words themselves must be unexpected, not the formatting.
- Pair naturally with Contrarian Take, Personal Lesson, and Question-Led frameworks.

---

## Framework-Specific Hook Guidance

Match hook formula selection to the post framework for maximum coherence.

| Framework | Primary Formulas | Key Rule |
|-----------|-----------------|----------|
| Story | Story, Pattern Interrupt | Open with a scene, not a setup. Create unresolved tension. |
| Listicle | Stat-Led, Bold Claim | Quantify the outcome, not just the count. Avoid "Here are 5 tips..." |
| Contrarian Take | Contrarian, Pattern Interrupt | Lead with the challenged belief, not the alternative. |
| How-To | Question, Stat-Led, Bold Claim | Frame around outcome, not process. Include a measurable result. |
| Personal Lesson | Story, Contrarian, Bold Claim | Vulnerability must be specific. Balance vulnerability with authority. |
| Industry Insight | Stat-Led, Bold Claim, Question | Lead with the data point, not the opinion. Signal timeliness. |
| Question-Led | Question, Pattern Interrupt | The question IS the hook. Follow with a one-sentence tension deepener. |

---

## Audience-Specific Hook Adjustments

Adjust hook language, examples, and value propositions based on the target audience. The same underlying insight often needs a completely different hook for each segment.

### Founder-CEO Audience
- Lead with outcomes they care about: revenue growth, time savings, team efficiency, competitive advantage, margins.
- Reference their daily reality: hiring struggles, cash flow, board expectations, wearing multiple hats, scaling past the founder bottleneck.
- Use metrics they track: MRR, burn rate, CAC, LTV, close rate, churn, NPS.
- Hook language: direct, action-oriented, low patience for theory. Get to the point in the first line.
- Effective triggers: "saved X hours/week", "grew revenue by Y%", "cut costs by Z", "stopped doing [common founder trap]."

### Technical Audience
- Lead with specificity: tool names, architecture decisions, performance metrics, code-level insights.
- Reference their frustrations: technical debt, CI/CD pipeline pain, on-call rotations, legacy system migrations, vendor lock-in.
- Use metrics they respect: latency (ms), uptime (nines), build times, deploy frequency, error rates.
- Hook language: precise, evidence-based, skeptical of hype. Avoid marketing language entirely.
- Effective triggers: "reduced deploy time from X to Y", "replaced [popular tool] with [unexpected alternative]", "the architecture mistake that cost us."

### Marketer Audience
- Lead with conversion, engagement, or growth numbers. Marketers think in funnel metrics.
- Reference their challenges: attribution, content saturation, algorithm changes, proving ROI, creative fatigue.
- Use metrics they optimize: CTR, conversion rate, CAC, ROAS, engagement rate, open rate, subscriber growth.
- Hook language: creative, slightly provocative, comfortable with storytelling. Can handle longer hooks if the narrative is compelling.
- Effective triggers: "X% conversion increase from one change", "the campaign that almost got me fired", "why your best content underperforms."

### Corporate-CXO Audience
- Lead with strategic framing: market positioning, organizational transformation, competitive moats, board-level decisions.
- Reference their world: quarterly planning, stakeholder management, M&A considerations, talent strategy, regulatory landscape.
- Use metrics they report on: market share, revenue growth, profit margins, employee retention, customer satisfaction indices.
- Hook language: authoritative, measured, backed by data or named examples. Avoid casual or overly conversational tone.
- Effective triggers: "the strategic shift that [named company] made", "why [industry trend] changes everything about [business function]", "what boards are asking about [topic] right now."

---

## Engagement Triggers

Embed at least one of these psychological triggers in every hook to drive the reader to tap "see more."

### Curiosity Gap
Create a gap between what the reader knows and what they want to know. Present enough information to establish relevance but withhold the resolution. The gap must be closable within the post -- never create curiosity the post does not satisfy. One gap per hook is sufficient; multiple gaps feel manipulative.

### Emotional Resonance
Trigger one specific emotion: surprise (unexpected stats), recognition ("that's exactly my experience"), mild anxiety about a blind spot, or aspiration toward an achievable outcome. Target one primary emotion per hook. Negative emotions (anxiety, frustration) require a clear promise of resolution within the post.

### Identification
Make the reader see themselves in the hook. Describe a scenario so specific that the right reader thinks "this is about me." Be specific enough to filter -- hooks that try to speak to everyone resonate with no one. Identification works best combined with curiosity gap or emotional resonance.

---

## Anti-Patterns

Reject these hook patterns during generation. If any appear in a draft, rewrite before outputting.

### Generic Openers
- "Excited to share..." / "Thrilled to announce..." / "I'm proud to..." -- Signals the post is about the author, not the reader. Corporate PR language kills engagement.
- "Big news!" -- Empty calorie opener with no specificity.

### I-Statement Leads (Non-Story)
- "I believe that..." / "I think the future of..." / "I've been thinking about..." -- Beliefs and thought processes are not hooks. State the claim directly.
- Exception: "I" is acceptable when opening a specific story ("I lost our biggest client last March" drops into a scene).

### Greetings and Time Markers
- "Happy Monday!" / "Good morning, LinkedIn!" / "Hope everyone is having a great week!" -- Social niceties that push real content below the fold.

### Engagement Bait
- "Like if you agree" / "Comment 'YES' if you..." -- Algorithmic manipulation that erodes trust.
- "Unpopular opinion:" / "Nobody talks about this" -- Overused labels. If the take is contrarian, the content shows it.

### Humblebrags
- "I never expected this post to go viral, but..." / "Honored and humbled to..." -- The hook centers the author's status, not the reader's benefit. Reframe around the lesson.

---

## Hook Quality Checklist

Before finalizing any hook, confirm:

- [ ] Total hook length is 1-3 lines and under 210 characters for the above-fold portion
- [ ] The curiosity gap, bold claim, or emotional trigger lands before the fold
- [ ] At least one engagement trigger is present (curiosity gap, emotional resonance, or identification)
- [ ] The hook matches the selected formula type and post framework
- [ ] No anti-patterns appear (generic openers, non-story I-leads, greetings, engagement bait, humblebrags)
- [ ] Audience-specific language and value framing match the target segment
- [ ] The hook connects directly to the post body -- no bait-and-switch
- [ ] Concrete details are present (numbers, names, timeframes, specific scenarios)
- [ ] The hook works as a standalone fragment -- a reader seeing only these lines should want more
- [ ] Line breaks are intentional and create visual pacing, not accidental wrapping
