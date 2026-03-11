---
name: LinkedIn Writing
description: "Generates LinkedIn posts optimized for platform engagement and formatting best practices. Activates when the user wants to write, draft, or create LinkedIn content, or asks 'help me post about [topic] on LinkedIn.' Covers post structure, formatting rules, hashtag strategy, and engagement-driven writing patterns."
globs:
  - "commands/linkedin-*.md"
---

# LinkedIn Writing

Generate structured, engaging LinkedIn posts that follow platform best practices and maximize engagement. Used by: `/founder-os:linkedin:post` (single post generation), `/founder-os:linkedin:variations` (multiple variations from one topic), and `/founder-os:linkedin:from-doc` (post extraction from long-form content).

## Purpose and Context

Transform raw ideas, topics, documents, or briefs into LinkedIn posts that a founder can review, lightly edit, and publish directly. Every post must follow one of seven proven frameworks, respect LinkedIn's formatting constraints, target a specific audience segment, and land within the selected length mode. Use the framework templates at `${CLAUDE_PLUGIN_ROOT}/skills/linkedin/linkedin-writing/references/post-frameworks.md` as the structural scaffold for every post.

---

## Post Frameworks

Select the framework that best matches the topic, audience, and intent. Each framework has a distinct structure, rhythm, and engagement profile.

| Framework | Best When | Default Length |
|-----------|-----------|---------------|
| Story | Sharing a personal narrative with a business lesson | Medium |
| Listicle | Delivering multiple tips, insights, or observations | Medium-Long |
| Contrarian Take | Challenging conventional wisdom or popular opinion | Short-Medium |
| How-To | Teaching a step-by-step practical process | Medium-Long |
| Personal Lesson | Showing vulnerability paired with insight | Medium |
| Industry Insight | Analyzing a trend with data or evidence | Medium-Long |
| Question-Led | Opening discussion with a provocative question | Short-Medium |

### Framework Selection Logic

When no framework is specified, select based on these signals:

1. **Topic contains a personal experience or anecdote** -- use Story or Personal Lesson.
2. **Topic involves numbered items, tips, or a collection of insights** -- use Listicle.
3. **Topic challenges a widely held belief** -- use Contrarian Take.
4. **Topic teaches a specific process or method** -- use How-To.
5. **Topic references data, research, or industry trends** -- use Industry Insight.
6. **Topic is best explored through discussion** -- use Question-Led.

When two frameworks fit equally, prefer the one that matches the target audience segment. See `${CLAUDE_PLUGIN_ROOT}/skills/linkedin/linkedin-writing/references/post-frameworks.md` for detailed templates, examples, and engagement tips for each framework.

---

## Post Structure Rules

Every LinkedIn post, regardless of framework, follows a three-part architecture:

### 1. Hook (Lines 1-2)

The first two lines appear above the "see more" fold. They determine whether a reader expands the post. Treat them as a headline.

Hook rules:
- Deliver the hook in 1-2 lines (under 150 characters visible before the fold).
- Open with a bold statement, surprising number, provocative question, or counterintuitive claim.
- Never open with "I'm excited to share..." or "Happy to announce..." or "Big news!" -- these are low-signal openers that LinkedIn audiences scroll past.
- Never open with a hashtag or emoji.
- The hook must create a knowledge gap -- the reader needs to click "see more" to resolve it.

Effective hook patterns:
- **Number-led**: "I lost $47,000 in revenue last quarter. Here is exactly why."
- **Contrarian**: "Networking events are a waste of time. Fight me."
- **Question**: "What would you do with 10 extra hours every week?"
- **Story-entry**: "Two years ago, I almost shut down my company."
- **Pattern-interrupt**: "Stop writing LinkedIn posts. Seriously."

### 2. Body (Lines 3-N)

The body delivers on the hook's promise. Structure varies by framework, but universal rules apply:

- Add a line break after every 1-2 sentences. Dense paragraphs kill engagement on LinkedIn.
- Use whitespace aggressively for visual scanning -- LinkedIn is a mobile-first platform.
- One idea per visual block (the text between two blank lines).
- Use bold sparingly and only when it adds scannability -- LinkedIn supports limited formatting.
- Numbered or bulleted lists are acceptable but keep items to one sentence each.
- Embed one personal opinion or experience per post. Pure information without perspective underperforms.

### 3. Closer (Final 2-3 Lines)

End with a CTA, summary, or invitation to engage:

- **Engagement CTA**: Ask a specific question that invites comments. "What is the one tool you could not live without?" outperforms "Thoughts?"
- **Summary line**: Restate the core takeaway in one sentence.
- **Tag-forward**: "Tag someone who needs to hear this." -- use sparingly, not on every post.
- **Soft CTA**: "If this was helpful, save it for later." -- leverages LinkedIn's save/bookmark feature for algorithmic boost.

---

## Length Modes

Select the length mode based on topic complexity, framework, and audience attention expectations.

### Short (Under 500 Characters)

Best for: Contrarian Take, Question-Led, quick observations.

- 3-6 lines total.
- Hook is the post. No body section -- the hook IS the content.
- One idea, one angle, zero filler.
- End with a question or a single-sentence opinion.
- Maximum impact per character. Every word must earn its place.

### Medium (500-1500 Characters)

Best for: Story, Personal Lesson, most general posts.

- 8-15 lines total.
- Hook (2 lines) + Body (6-10 lines) + Closer (2-3 lines).
- Enough room for one story or one structured argument.
- Default length mode when no preference is specified.

### Long (1500-3000 Characters)

Best for: Listicle, How-To, Industry Insight, detailed frameworks.

- 15-25 lines total.
- Hook (2 lines) + Body (12-20 lines) + Closer (2-3 lines).
- Requires a strong hook to justify the length. Long posts with weak hooks get abandoned.
- Use visual structure (line breaks, numbered items, bold labels) to maintain scannability.
- Approach the 3000 character hard limit carefully -- leave room for hashtags.

### Hard Limit

LinkedIn enforces a 3000 character limit on standard posts. This includes all text, line breaks, and hashtags. Never exceed 3000 characters. When approaching the limit, cut from the body (never the hook or closer) and reduce hashtag count.

---

## LinkedIn Formatting Rules

### Line Breaks and Whitespace

LinkedIn collapses single line breaks in some clients. Follow these rules for consistent rendering:

- Insert a blank line between every 1-2 sentences.
- Use blank lines to create visual "paragraphs" of 1-2 sentences each.
- A line break after every sentence is acceptable and often preferred for readability.
- Do not use more than one consecutive blank line -- LinkedIn collapses them.
- Short lines (under 60 characters) create a faster reading rhythm. Mix short and medium-length lines.

### Supported Formatting

| Element | How to Use | Notes |
|---------|-----------|-------|
| Line breaks | Blank line between blocks | Primary readability tool |
| Bold | Not supported in standard posts | Available only in LinkedIn articles, not posts |
| Italic | Not supported in standard posts | Available only in LinkedIn articles |
| Emojis | Sparingly for visual markers | 0-3 per post max; never as first character |
| Bullet points | Unicode bullets or hyphens | Keep items to one line each |
| Numbered lists | "1." at start of line | Natural for listicles and how-tos |
| ALL CAPS | Single word for emphasis | Use max once per post; never for full sentences |
| Mentions | @Name for real people/companies | Only mention relevant parties; never mass-tag |

### Elements to Avoid

- Markdown formatting (not rendered on LinkedIn -- appears as raw characters).
- Links in the post body (LinkedIn suppresses reach on posts with external links; place links in the first comment instead and reference them: "Link in comments").
- More than 3 emojis total.
- Emoji bullets for every list item (reads as spam to the algorithm and to humans).
- Unicode special characters or decorative symbols.
- All-caps sentences.

---

## Hashtag Generation Rules

Append 3-5 hashtags at the end of every post, separated from the closer by one blank line.

### Selection Strategy

Generate a mix of broad and niche hashtags:

- **1-2 broad hashtags** (100K+ followers): Provide discoverability. Examples: #Leadership, #Startups, #Entrepreneurship, #Marketing, #Technology.
- **2-3 niche hashtags** (1K-100K followers): Reach targeted audiences. Examples: #SaaSFounder, #BootstrappedStartup, #RemoteTeam, #SoloFounder, #B2BMarketing.

### Hashtag Rules

- Place all hashtags on the final line(s) of the post.
- Use CamelCase for multi-word hashtags (#ContentMarketing not #contentmarketing) for readability and accessibility.
- Never embed hashtags within the body text. They disrupt reading flow.
- Never use more than 5 hashtags. LinkedIn's algorithm does not reward hashtag volume and over-tagging signals low-quality content.
- Avoid overly generic hashtags (#Business, #Success, #Motivation) -- they attract bots and low-engagement impressions.
- Match hashtags to the post's actual content. A post about hiring should not include #AI just for reach.
- Include the character count of hashtags in the 3000 character budget.

---

## Audience Segments

Adjust tone, vocabulary, examples, and CTA style based on the target audience segment. Default to Founder-CEO when no segment is specified.

### Founder-CEO

- **Tone**: Peer-to-peer. Write as one founder to another. Direct, practical, experienced.
- **Vocabulary**: Business outcomes, revenue, team size, product decisions, time savings, cash flow, runway, margins.
- **Examples**: Reference sub-50-person companies, bootstrapping, first hires, pivots, customer conversations.
- **CTA style**: Challenge-based ("Try this tomorrow and report back") or experience-sharing ("What was your version of this?").
- **Avoid**: Enterprise jargon, theoretical frameworks without practical application, VC-centric metrics unless relevant.

### Technical

- **Tone**: Knowledgeable peer. Demonstrate technical credibility without talking down.
- **Vocabulary**: Stack-specific terms, tool names, architectural decisions, performance metrics, developer experience.
- **Examples**: Reference specific technologies, code decisions, debugging stories, build-vs-buy trade-offs.
- **CTA style**: Technical challenge ("What is your go-to solution for this?") or tool recommendation ("Drop your favorite tool for this in the comments").
- **Avoid**: Buzzword-heavy descriptions of technology ("leveraging AI to synergize"), oversimplification that loses technical readers.

### Marketer

- **Tone**: Results-oriented practitioner. Focus on what works and what does not, with numbers.
- **Vocabulary**: Conversion rates, CAC, LTV, content performance, channels, campaigns, attribution, engagement metrics.
- **Examples**: Reference campaign results, A/B tests, channel strategies, content experiments, growth tactics.
- **CTA style**: Results-sharing ("What conversion rate are you seeing?") or tactic exchange ("Share your best-performing channel this quarter").
- **Avoid**: Platitudes about "creating value" or "building community" without specifics.

### Corporate-CXO

- **Tone**: Strategic and credibility-forward. Demonstrate business impact and cross-functional thinking.
- **Vocabulary**: Board-level metrics, organizational change, competitive positioning, market dynamics, risk management, talent strategy.
- **Examples**: Reference industry shifts, competitive moves, organizational design decisions, leadership challenges.
- **CTA style**: Perspective-seeking ("How is your organization handling this?") or insight-sharing ("What signals are you watching?").
- **Avoid**: Tactical details that belong at the IC level, overly casual tone, startup-centric assumptions about team size or budget.

---

## Quality Checklist

Before outputting a LinkedIn post, confirm every item:

- [ ] Hook occupies lines 1-2 and creates a knowledge gap or curiosity pull
- [ ] Hook does not start with "I'm excited", "Happy to announce", "Big news", or a hashtag
- [ ] Post follows one of the 7 frameworks and maintains its structure throughout
- [ ] Line breaks appear after every 1-2 sentences for readability
- [ ] Total character count is within the selected length mode AND under 3000 characters
- [ ] Hashtags are 3-5, placed at the end, mixing broad and niche, using CamelCase
- [ ] No external links appear in the post body (placed in first comment instead)
- [ ] No Markdown formatting syntax appears (not rendered on LinkedIn)
- [ ] No more than 3 emojis in the entire post
- [ ] Closer includes an engagement CTA, summary, or save prompt
- [ ] Tone matches the target audience segment
- [ ] Post contains at least one personal opinion, experience, or perspective
- [ ] No corporate jargon or hedging language ("I think maybe", "It might be worth considering")
- [ ] Every sentence earns its place -- no filler, no throat-clearing, no preamble
