# Section Type Templates

Detailed templates and examples for each newsletter section type. Select the appropriate type based on the research content and mix types within a single issue for variety.

---

## News Roundup

Curate 3-5 recent developments into a scannable briefing. Use when the research phase surfaced multiple notable but individually shallow findings that together tell a story.

### Structure

```
## [Trend-Oriented Heading]

[1-2 sentence lead framing why these developments matter together.]

**[Development 1 title].** [2-3 sentences: what happened, why it matters, source link.]

**[Development 2 title].** [2-3 sentences: what happened, why it matters, source link.]

**[Development 3 title].** [2-3 sentences: what happened, why it matters, source link.]

[Optional: Development 4-5 if warranted.]

[1 sentence synthesizing the pattern across all developments.]
```

### Formatting Rules

- Bold the development title as a label, followed by a period and the description in the same paragraph.
- Keep each development to 2-3 sentences. If a development needs more, promote it to a Deep-Dive section instead.
- Order developments from most to least impactful.
- Every development must include at least one inline source link.
- Close with a synthesis sentence that names the pattern: "The through-line: [pattern]."

### Example

```markdown
## The Pricing Model Shakeup Nobody Asked For

Three moves in the past two weeks signal a broader shift away from per-seat SaaS pricing.

**Notion introduces usage-based tiers.** Notion quietly rolled out a [new pricing structure](url) that charges by workspace activity rather than headcount. For teams with part-time collaborators, this could cut costs by 30-40%.

**HubSpot drops its starter seat minimum.** Starting March 1, HubSpot's [Starter CRM plan](url) no longer requires a 2-seat minimum. Solo founders and micro-agencies can now access the full Starter suite for $20/month.

**Cal.com goes fully open-core.** The scheduling tool announced it is [removing all paid feature gates](url) from its self-hosted version, monetizing only through managed hosting and enterprise support.

The through-line: tools are competing on flexibility, not feature count -- and founders with lean teams stand to benefit most.
```

### When to Use

- Research surfaced 3+ developments in the same domain within a recent window (1-2 weeks).
- No single development warrants a full section on its own.
- The developments collectively reveal a trend or pattern worth naming.

---

## Deep-Dive

Explore one topic in analytical depth. Use when the research surfaced a single finding with enough evidence, nuance, and practical implications to sustain 250-350 words.

### Structure

```
## [Insight-Driven Heading]

[1 sentence stating the core insight.]

[2-3 sentences providing context: how we got here, what changed, or why this matters now. Include source links.]

[2-3 sentences presenting supporting evidence: data points, expert quotes, case studies, or comparisons. Include source links.]

[Optional: 1-2 sentences addressing a counterargument or limitation.]

[1 sentence translating the insight into a specific founder action.]
```

### Formatting Rules

- Lead with the insight, not the background. Readers should know the punchline by the second sentence.
- Include at least 2 source links: one for the primary claim, one for supporting evidence.
- Use a blockquote (`>`) for direct quotes from experts, reports, or founders. Limit to one blockquote per deep-dive.
- When presenting data, use bold for the key number: "Teams using async standups reported **34% fewer meetings** per week."
- Close with a concrete action, not a vague reflection.

### Example

```markdown
## Async Standups Are Replacing Morning Syncs (And Output Is Up)

Teams that replaced daily standup meetings with async text updates are shipping faster, not slower.

The shift accelerated during the remote-work era, but [new data from Pulse](url) shows it sticking even in hybrid setups. Among 1,200 surveyed engineering teams, those using async standups reported **34% fewer meetings per week** and a **12% increase in merged PRs** compared to teams running synchronous dailies.

> "The biggest unlock wasn't saving 15 minutes a day -- it was eliminating the context switch. Engineers stopped losing their morning flow state." -- [Sarah Chen, VP Engineering at Lattice](url)

The counterargument is real: async standups can mask blockers that a live conversation would surface in seconds. Teams that make the switch successfully pair async updates with a strict "flag blockers immediately" norm in Slack or Teams.

Audit your team's standup: if more than half the updates are status reports nobody acts on, trial async for two weeks and measure PR throughput before and after.
```

### When to Use

- Research surfaced a single finding with strong evidence (data, expert opinion, case studies).
- The topic has practical implications that warrant explanation, not just mention.
- The finding is surprising, counterintuitive, or challenges a common assumption.

---

## Opinion Piece

Take a clear stance on a debatable topic. Use when the research surfaced a trend or practice where reasonable people disagree and the newsletter can add value by arguing a position.

### Structure

```
## [Stance-Declaring Heading]

[1 sentence stating the opinion clearly and directly.]

[2-3 sentences presenting the strongest argument for this position, grounded in evidence from the research. Include source links.]

[1-2 sentences acknowledging the best counterargument. Do not strawman it.]

[1-2 sentences explaining why the position holds despite the counterargument.]

[1 sentence challenging the reader to form their own view or test the claim.]
```

### Formatting Rules

- The heading must signal a position, not a neutral topic. Good: "Stop Chasing Product-Market Fit -- Chase Problem-Market Fit Instead." Bad: "Thoughts on Product-Market Fit."
- State the opinion in the first sentence. Do not build up to it.
- Acknowledge the counterargument genuinely. A dismissed counterargument weakens the argument; an addressed one strengthens it.
- Ground the opinion in evidence, not personal preference. Link to data, case studies, or expert analysis.
- Close with an invitation to engage, not a declaration of victory. This drives replies and shares.

### Example

```markdown
## Your MVP Doesn't Need a Landing Page

Most pre-revenue founders would ship faster if they skipped the landing page entirely and sold through direct outreach.

[Lenny Rachitsky's analysis of 50 successful B2B startups](url) found that **72% of first customers came through personal networks**, not inbound funnels. The landing page gave founders a feeling of progress without generating the one thing that matters: a paying customer willing to give feedback.

The counterpoint is fair: landing pages build credibility, and some buyers will not take a meeting without one. For enterprise sales with procurement teams, that is absolutely true.

But for the first 10 customers? A Loom video and a direct email outperform a polished site every time. The landing page is a comfort blanket, not a growth lever, at the zero-to-one stage.

Try this: pitch your next 5 prospects with nothing but a personalized email and a 3-minute screen recording. Track your conversion rate against your landing page leads.
```

### When to Use

- The topic is genuinely debatable (not a settled best practice).
- The research provides evidence supporting a non-obvious position.
- The opinion is actionable -- readers can change behavior based on it.

---

## Tool Spotlight

Evaluate a specific tool, framework, or resource. Use when the research surfaced a tool that solves a specific founder problem and warrants more than a passing mention.

### Structure

```
## [Problem-Solving Heading, Not Tool Name]

[1 sentence naming the tool and the specific problem it solves.]

**What it does:** [2-3 sentences describing core functionality. Focus on outcomes, not features.]

**What stands out:** [2-3 sentences on what differentiates this tool from alternatives. Be specific -- name the alternatives.]

**Watch out for:** [1-2 sentences on limitations, pricing concerns, or fit constraints. Honest assessment builds trust.]

**Best for:** [1 sentence defining the ideal user profile.]

[Optional: 1 sentence with a link to try it or learn more.]
```

### Formatting Rules

- Never title the section with just the tool name. Frame it around the problem: "Finally, a CRM That Doesn't Require a Full-Time Admin" not "Attio Review."
- Use bold labels (`**What it does:**`) to make the section scannable.
- Include at least one comparison to a named alternative. Readers evaluate tools relatively, not absolutely.
- The "Watch out for" section is mandatory. Omitting limitations reads as sponsored content and erodes reader trust.
- Do not include pricing details that may become stale. Link to the pricing page instead.
- Disclose any affiliate or sponsorship relationship in a parenthetical if applicable.

### Example

```markdown
## Stop Paying for Project Management Features You Never Use

[Todoist Business](url) is not new, but its recent API overhaul makes it the leanest task manager for solo founders who need structure without overhead.

**What it does:** Manages tasks, projects, and recurring workflows with natural language input and deep calendar integration. Type "Review Q1 financials every Monday at 9am" and it creates the recurring task with the right schedule.

**What stands out:** Where Asana and Monday.com assume team collaboration, Todoist treats the individual as the primary user. The [new REST API](url) connects to Zapier, Make, and n8n without middleware, letting solo operators automate task creation from email, Slack, or form submissions.

**Watch out for:** Todoist's reporting is minimal. If you need time tracking, workload views, or Gantt charts, you will outgrow it quickly. It is a task execution tool, not a project planning tool.

**Best for:** Solo founders or 2-3 person teams who want fast capture and recurring task automation without paying for seats they do not use.
```

### When to Use

- Research identified a specific tool relevant to the newsletter's audience.
- The tool solves a concrete problem, not a vague need.
- There is enough to say beyond "this tool exists" -- differentiation, limitations, and ideal fit.

---

## Tutorial Snippet

Teach one technique in a concise, reproducible walkthrough. Use when the research surfaced a practical method that readers can implement in under 30 minutes.

### Structure

```
## [Outcome-Oriented Heading]

[1 sentence stating what the reader will be able to do after following the steps.]

**You'll need:** [Bulleted list of prerequisites -- tools, accounts, or knowledge required.]

**Step 1: [Action verb phrase]**
[2-3 sentences explaining the step. Include specific values, settings, or inputs.]

**Step 2: [Action verb phrase]**
[2-3 sentences. If a step requires code or configuration, use a code block.]

**Step 3: [Action verb phrase]**
[2-3 sentences.]

[Optional: Steps 4-5 for more involved tutorials.]

**Result:** [1-2 sentences describing what the reader now has and how to verify it works.]
```

### Formatting Rules

- Limit to 3-5 steps. If the tutorial requires more, link to a full guide and summarize the first 3 steps in the newsletter.
- Each step heading must start with an action verb: "Connect," "Configure," "Test," not "The Connection Step."
- Use code blocks (triple backticks) for any commands, configuration snippets, or code. Substack renders these in monospace.
- Include a "You'll need" prerequisites list so readers can self-qualify before investing time.
- Close with a "Result" statement that describes the observable outcome and how to verify success.
- Keep the total tutorial to 200-300 words. Newsletters teach concepts; blog posts teach processes.

### Example

```markdown
## Automate Your Weekly Client Check-Ins in 10 Minutes

Set up an automated workflow that drafts personalized check-in emails for every active client each Monday morning.

**You'll need:**
- An n8n or Make account (free tier works)
- A Notion database with client names and project status
- A Gmail or Outlook account for sending

**Step 1: Create a scheduled trigger**
In n8n, add a Cron node set to fire every Monday at 8:00 AM. In Make, use the "Every week" scheduler module with the same timing.

**Step 2: Pull active clients from Notion**
Connect a Notion node filtered to `Status = Active`. Map the `Client Name`, `Project Name`, and `Last Update` fields to variables.

**Step 3: Draft the email with a template**
Add a text formatter node using this template:

```
Hi {{Client Name}},

Quick check-in on {{Project Name}}. Last update was {{Last Update}}.
Anything you need from me this week?
```

Route the output to a Gmail "Create Draft" node so you review before sending.

**Result:** Every Monday, your drafts folder contains a personalized check-in for each active client. Review and send in under 5 minutes.
```

### When to Use

- The technique is practical and achievable in a single sitting.
- The research identified a workflow, automation, or method that is under-documented.
- The tutorial serves the newsletter's audience (founders, operators, small teams).

---

## Mixing Section Types

A strong newsletter varies its section types to maintain reader interest. Recommended combinations by newsletter length:

| Length | Recommended Mix |
|--------|----------------|
| Quick-hit (3 sections) | 1 Deep-Dive + 1 News Roundup + 1 Tool Spotlight |
| Standard (4 sections) | 1 Deep-Dive + 1 Opinion Piece + 1 News Roundup + 1 Tutorial Snippet |
| Deep-dive issue (5 sections) | 2 Deep-Dive + 1 Opinion Piece + 1 Tool Spotlight + 1 News Roundup |

Rules:
- Never use the same section type for consecutive sections.
- Every issue should include at least one section with actionable advice (Tutorial Snippet, Tool Spotlight, or a Deep-Dive with a strong founder takeaway).
- News Roundup sections work best near the top (hook readers with recent events) or at the end (leave readers informed on broader context).
- Opinion Pieces drive the most replies and shares -- include one when the research supports a defensible position.
