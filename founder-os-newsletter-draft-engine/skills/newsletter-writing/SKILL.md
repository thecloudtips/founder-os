---
name: Newsletter Writing
description: "Assembles researched topics into structured, publishable newsletter drafts with Substack-compatible formatting. Activates when the user wants to write, draft, or outline a newsletter, format content for Substack, or asks 'turn this research into a newsletter.' Covers the four-part structure (Hook, Main Content, Takeaways, CTA), link attribution, and visual rhythm."
globs:
  - "commands/newsletter-outline.md"
  - "commands/newsletter-draft.md"
  - "commands/newsletter.md"
---

# Newsletter Writing

Assemble researched topics into structured, publishable newsletter drafts with Substack-compatible formatting. Used by: `/newsletter:outline` (structure planning), `/newsletter:draft` (full draft generation), and `/newsletter` (end-to-end research-to-draft pipeline).

## Purpose and Context

Transform raw research findings and topic clusters into a newsletter that a founder can review, lightly edit, and publish directly to Substack. The output must follow a consistent four-part structure (Hook, Main Content, Key Takeaways, CTA), use Substack-compatible Markdown, attribute all sources properly, and land within the 800-1500 word target. Use the output template at `${CLAUDE_PLUGIN_ROOT}/templates/newsletter-template.md` as the formatting scaffold for every draft.

---

## Newsletter Structure

Produce every newsletter in this four-part structure. Each part serves a distinct reader purpose -- do not merge or reorder them.

### 1. Hook (2-3 Sentences)

Open with an attention-grabbing statement that establishes why this issue matters right now. Anchor the hook to a specific event, statistic, trend shift, or provocative question. Avoid generic greetings ("Welcome to this week's issue") and throat-clearing ("In this edition, we'll cover...").

Effective hook patterns:
- **Stat-led**: Open with a surprising number that reframes the reader's assumptions.
- **Contrarian**: Challenge a widely held belief in the reader's industry.
- **Story-led**: Start with a one-sentence anecdote from a real company or founder.
- **Question**: Pose a specific, answerable question the newsletter will address.

Rules:
- Keep the hook under 60 words total.
- Never start with "I" -- center the reader or the topic.
- Include at least one concrete detail (name, number, date, or place).
- The hook must connect logically to the first main content section.

### 2. Main Content (3-5 Sections)

Each section covers one finding cluster from the research phase. Present sections in descending order of reader impact -- lead with the most actionable or surprising finding.

Per-section structure:
1. **Section heading** (H2) -- a benefit-oriented or curiosity-driven phrase, not a label.
2. **Lead sentence** -- state the core insight in one sentence.
3. **Evidence and context** -- 2-4 sentences supporting the insight with data, quotes, or examples.
4. **Founder takeaway** -- one sentence translating the insight into a specific action or decision the reader can make.

Section length: 150-300 words each. Aim for 3 sections in a shorter newsletter (800-1000 words) and 4-5 sections when the research supports it (1000-1500 words).

Rules:
- Each section must be self-contained -- a reader skimming only one section should still get value.
- Attribute every claim that is not common knowledge (see Link Attribution below).
- Do not repeat information across sections. If two findings overlap, merge them into one section.
- Use concrete examples over abstract statements. Name tools, companies, frameworks, or people when the research provides them.

### 3. Key Takeaways (Bullet List)

Distill the newsletter into 3-5 actionable bullet points. Each takeaway must be a complete, standalone instruction -- not a summary of a section heading.

Rules:
- Start each bullet with an action verb (Ship, Test, Replace, Audit, Schedule).
- Keep each bullet to one sentence, 15-25 words.
- Order by implementation ease -- put the quickest win first.
- Never introduce new information here. Every takeaway must trace back to a main content section.

### 4. CTA (Closing Call-to-Action)

Close with a single, clear ask. The CTA drives reader engagement beyond passive consumption.

CTA types:
- **Reply**: Ask a specific question readers can answer by replying ("What's the one tool you couldn't run your business without? Hit reply -- I read every response.")
- **Share**: Request a forward to one specific person ("Know a founder wrestling with pricing? Forward this to them.")
- **Link**: Direct readers to a resource, tool, or deeper-dive article.
- **Action**: Challenge readers to implement one takeaway this week and report back.

Rules:
- Use exactly one CTA. Multiple asks dilute response rates.
- Frame the CTA as a benefit to the reader, not a favor to the sender.
- Keep the CTA to 2-3 sentences maximum.

---

## Substack-Compatible Formatting

Write Markdown that renders correctly in Substack's editor. Substack supports a subset of Markdown with specific rendering behaviors.

### Supported Elements

| Element | Syntax | Substack Notes |
|---------|--------|---------------|
| Headings | `## H2` through `#### H4` | Use H2 for section titles, H3 for subsections. Avoid H1 (Substack uses the post title as H1). |
| Bold | `**text**` | Renders correctly. |
| Italic | `*text*` | Renders correctly. |
| Links | `[text](url)` | Opens in new tab by default. |
| Images | `![alt](url)` | Use full URLs. Substack re-hosts images on upload. |
| Blockquotes | `> text` | Renders as indented quote block. |
| Unordered lists | `- item` | Use `-` not `*` for consistency. |
| Ordered lists | `1. item` | Renders correctly. |
| Horizontal rules | `---` | Use between major sections as visual dividers. |
| Code blocks | Triple backticks | Renders in monospace. Use sparingly in newsletters. |
| Line breaks | Double newline | Single newlines are ignored. Always use blank lines between paragraphs. |

### Elements to Avoid

- HTML tags (`<div>`, `<span>`, `<table>`) -- Substack strips most raw HTML.
- Nested blockquotes (`> > text`) -- renders inconsistently.
- Footnotes (`[^1]`) -- not supported. Use inline links instead.
- Table syntax (`| col |`) -- Substack does not render Markdown tables in published posts. Convert tables to bold-label lists or use images for tabular data.
- Task lists (`- [ ]`) -- not supported.

### Visual Rhythm

- Insert `---` horizontal rules between the Hook and Main Content, between each main section, before Key Takeaways, and before the CTA.
- Keep paragraphs to 2-4 sentences. Substack readers scan on mobile -- dense blocks lose them.
- Use bold sparingly for emphasis on key phrases, not entire sentences.
- Place one image or blockquote per 300-400 words to break visual monotony.

---

## Link Attribution

### Inline References

Attribute sources where the claim appears. Use descriptive link text that tells the reader what they will find -- never use "click here" or bare URLs.

- Good: `According to [Stripe's 2025 developer survey](url), 68% of startups now use usage-based pricing.`
- Good: `The approach mirrors what [Basecamp documented in their Shape Up methodology](url).`
- Bad: `According to this article (url), the trend is growing.`
- Bad: `Source: [click here](url)`

Rules:
- Link the most descriptive noun phrase, not generic verbs.
- Every statistic, direct quote, and non-obvious claim requires an inline link.
- Limit to 5-8 total links per newsletter. Over-linking creates visual noise and decision fatigue.
- Verify every URL resolves (no 404s, no paywalled content without warning).

### Sources Section

Append a "Sources" section at the bottom of every newsletter, below the CTA. List every referenced source with its title and URL. This serves readers who want to explore further and establishes credibility.

Format:
```
---

**Sources:**
- [Source Title](url) -- one-line description of what this source covers
- [Source Title](url) -- one-line description
```

Rules:
- List sources in the order they appear in the newsletter.
- Include sources for claims that use inline links AND for background research that informed the writing but was not directly linked.
- Keep descriptions to one phrase or short sentence.

---

## Length Guidance

Target 800-1500 words for the full newsletter (Hook through CTA, excluding the Sources section).

| Newsletter Type | Word Target | Sections | Use When |
|----------------|-------------|----------|----------|
| Quick-hit | 800-1000 | 3 | Single theme, time-sensitive topic, or thin research |
| Standard | 1000-1300 | 4 | Most issues -- balanced depth and scannability |
| Deep-dive | 1300-1500 | 5 | Complex topic with rich research, or a tutorial-heavy issue |

Rules:
- Never exceed 1500 words. Readers unsubscribe from newsletters that demand too much time. If the content exceeds 1500 words, split into two issues or move a section into a linked deep-dive post.
- The Hook and CTA together should not exceed 150 words. Spend the word budget on Main Content.
- Key Takeaways should be 50-100 words total.

---

## Transition Patterns

Connect sections so the newsletter reads as a cohesive narrative, not a list of unrelated findings.

### Bridge Sentences

Place a one-sentence bridge at the end of each section (before the `---` divider) that links the current topic to the next section.

Patterns:
- **Causal**: "That shift in pricing models is driving a second trend worth watching."
- **Contrast**: "But not every team is moving in the same direction."
- **Deepening**: "The data gets more interesting when you break it down by company size."
- **Practical pivot**: "Understanding the trend is one thing -- acting on it requires a different playbook."
- **Question bridge**: "So what does this look like in practice?"

Rules:
- Bridges must be one sentence. Two sentences dilute the connective force.
- Never use "Speaking of..." or "On a related note..." -- these are filler, not transitions.
- The bridge must reference both the current section's topic and hint at the next section's focus.
- If two sections are genuinely unrelated, omit the bridge and let the `---` divider signal the shift. Forced transitions are worse than no transition.

### Opening Variation

Vary how each main content section opens to avoid rhythmic monotony:

- Section 1: Lead with a stat or finding.
- Section 2: Lead with a company example or quote.
- Section 3: Lead with a question or contrarian take.
- Section 4: Lead with a practical scenario ("Imagine you're...").
- Section 5: Lead with a historical comparison or timeline.

Do not repeat the same opening pattern in consecutive sections.

---

## Section Type Templates

Different newsletter issues call for different section types. Select the appropriate type for each section based on the research content. See `${CLAUDE_PLUGIN_ROOT}/skills/newsletter-writing/references/section-templates.md` for detailed templates, examples, and formatting guidance for each type.

Available section types:
- **News Roundup** -- curate 3-5 recent developments into a scannable briefing
- **Deep-Dive** -- explore one topic in analytical depth with evidence and nuance
- **Opinion Piece** -- take a clear stance on a debatable topic with supporting argument
- **Tool Spotlight** -- evaluate a specific tool, framework, or resource with honest assessment
- **Tutorial Snippet** -- teach one technique in a concise, reproducible walkthrough

Mix section types within a single newsletter for variety. A typical issue might combine one deep-dive, one news roundup, and one tool spotlight.

---

## Quality Checklist

Before outputting a newsletter draft, confirm:

- [ ] Hook is under 60 words and does not start with "I" or a greeting
- [ ] Main content has 3-5 sections in descending order of reader impact
- [ ] Every section has a benefit-oriented H2 heading
- [ ] Every non-obvious claim has an inline source link
- [ ] Total word count is between 800 and 1500 (excluding Sources section)
- [ ] Key Takeaways are 3-5 bullets, each starting with an action verb
- [ ] CTA is a single, clear ask in 2-3 sentences
- [ ] No Markdown tables appear in the body (Substack does not render them)
- [ ] `---` dividers separate all major sections
- [ ] No H1 headings are used (reserved for Substack post title)
- [ ] Transition bridges connect consecutive sections without filler phrases
- [ ] Sources section lists all referenced URLs in order of appearance
- [ ] Draft uses the template scaffold from `${CLAUDE_PLUGIN_ROOT}/templates/newsletter-template.md`
