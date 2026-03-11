# Query Pattern Templates

Detailed query templates and examples for each source type used by the topic-research skill. Use these patterns when formulating the 5-8 queries per topic.

## General Web Queries

Target broad news sites, analysis publications, and industry media.

### Templates

```
"[topic] [current year]"
"[topic] trends [current year]"
"[topic] news latest"
"why [topic] matters [industry/audience]"
"[topic] vs [competing topic] comparison"
"[topic] impact on [industry/role]"
"best [topic] tools [current year]"
"[topic] statistics data [current year]"
```

### Examples (Topic: "AI code review tools")

```
"AI code review tools 2026"
"AI code review trends 2026"
"AI code review tools comparison developer productivity"
"AI code review impact on software engineering teams"
```

### Tips

- Always include the current year for evergreen topics to surface recent content.
- Add the target audience or industry to narrow results (e.g., "for startups", "for SaaS", "for developers").
- Use "vs" queries to find comparison articles -- these often contain the most balanced analysis.
- Avoid queries that are too broad: "AI tools" returns noise; "AI code review tools for Python" returns signal.

## GitHub Queries

Target trending repositories, new releases, changelogs, and developer tools.

### Templates

```
site:github.com "[topic] tool"
site:github.com "[topic]" stars:>100
site:github.com "[topic] release" OR "changelog"
site:github.com "[topic]" language:[lang]
site:github.com "[topic]" "getting started" OR "quickstart"
site:github.com "[related framework/library]" "[topic]"
```

### Examples (Topic: "AI code review tools")

```
site:github.com "AI code review" tool
site:github.com "code review" "AI" OR "LLM" OR "GPT"
site:github.com "code review" release 2026
site:github.com "automated code review" stars:>50
```

### Result Interpretation

When parsing GitHub results, extract:

- **Repository name**: `owner/repo` format.
- **Stars count**: Indicator of community adoption. Repos with 100+ stars indicate validated interest.
- **Last commit date**: Use as the finding's date. Repos with commits within 30 days are actively maintained.
- **Description**: Use the repository's description field as the summary foundation.
- **Release tag**: If the result links to a release page, extract the version number and release date.

### Quality Signals

- Prefer repos with recent commits (within 30 days) over archived or dormant projects.
- Repos with a README containing usage examples are more newsletter-worthy than stub projects.
- Organization-owned repos (e.g., `microsoft/`, `google/`) carry more authority than personal repos for "official release" categorization.

## Reddit Queries

Target community discussions, sentiment, pain points, and real-world usage feedback.

### Templates

```
site:reddit.com "[topic]" subreddit:[relevant sub]
site:reddit.com "[topic]" "anyone tried" OR "experience with"
site:reddit.com "[topic]" "switched to" OR "migrated from"
site:reddit.com "[topic]" "[current year]"
site:reddit.com "[topic]" "pros and cons" OR "honest review"
```

### Examples (Topic: "AI code review tools")

```
site:reddit.com "AI code review" subreddit:programming
site:reddit.com "AI code review" "anyone tried" OR "experience with"
site:reddit.com "AI code review tools" 2026
```

### Relevant Subreddits by Domain

| Domain | Subreddits |
|--------|------------|
| Software / Dev Tools | r/programming, r/webdev, r/devops, r/machinelearning, r/experienceddevs |
| Business / Startups | r/startups, r/smallbusiness, r/entrepreneur, r/SaaS |
| Marketing | r/marketing, r/digital_marketing, r/content_marketing, r/SEO |
| Design | r/design, r/UI_Design, r/UXDesign, r/web_design |
| AI / ML | r/artificial, r/MachineLearning, r/LocalLLaMA, r/ChatGPT |
| Productivity | r/productivity, r/Notion, r/ObsidianMD, r/automation |
| Finance | r/personalfinance, r/fintech, r/investing |

### Result Interpretation

- Thread titles with "anyone tried" or "experience with" indicate real-world user feedback -- high newsletter value.
- Threads with 50+ upvotes indicate community-validated interest in the topic.
- Sort by "new" to find recent discussions; sort by "top" for validated takes.
- Extract the top 2-3 comments from high-engagement threads as representative community sentiment.

## Official Blog / Changelog Queries

Target authoritative first-party sources for announcements, updates, and roadmap signals.

### Templates

```
"[company/product name] blog [topic]"
"[company/product name] announces [topic]"
"[product name] changelog [current year]"
"[product name] release notes [version/date]"
"[product name] roadmap [current year]"
"[company] introduces [feature related to topic]"
site:[company-domain.com] blog "[topic]"
```

### Examples (Topic: "AI code review tools")

```
"GitHub Copilot code review" blog 2026
"GitLab AI code review" announces
site:blog.github.com "code review"
"Sourcegraph" OR "CodeRabbit" OR "Codacy" announces 2026
```

### Known Blog Domains by Category

| Category | Domains |
|----------|---------|
| Cloud / DevOps | blog.github.com, cloud.google.com/blog, aws.amazon.com/blogs, azure.microsoft.com/blog |
| AI / ML | openai.com/blog, anthropic.com/news, blog.google/technology/ai, huggingface.co/blog |
| SaaS / Business | blog.notion.so, slack.com/blog, monday.com/blog, hubspot.com/blog |
| Dev Tools | blog.jetbrains.com, code.visualstudio.com/blogs, vercel.com/blog, supabase.com/blog |
| Marketing | blog.hubspot.com, contentmarketinginstitute.com, moz.com/blog, ahrefs.com/blog |

### Result Interpretation

- Official announcements from the product maker are the strongest source for "official-release" categorization.
- Changelog entries with specific version numbers and dates provide precise temporal grounding.
- Roadmap posts are valuable for "what's coming" newsletter sections but should be clearly labeled as forward-looking.

## Quora Queries

Target expert Q&A and alternative perspectives that may not surface in standard web or Reddit searches.

### Templates

```
site:quora.com "What is [topic]"
site:quora.com "[topic]" "best" OR "recommended"
site:quora.com "How does [topic] compare to [alternative]"
site:quora.com "[topic]" "worth it" OR "should I"
```

### Examples (Topic: "AI code review tools")

```
site:quora.com "AI code review" "best tool"
site:quora.com "AI code review" "worth it"
site:quora.com "automated code review" vs "manual code review"
```

### Result Interpretation

- Quora answers with 100+ upvotes from credentialed authors carry authority.
- "What is" and "How does" questions often yield explanatory content useful for newsletter readers who are new to a topic.
- Quora results tend to be older -- apply strict recency scoring. Prefer results from the current year.
- Use Quora findings primarily for "reader perspective" or "FAQ" sections of the newsletter, not as primary news sources.

## Query Refinement Workflow

When initial queries return poor results (fewer than 3 findings above 0.5 relevance), refine using this process:

### Step 1: Broaden or Narrow

- If too few results: remove source-type constraints (`site:` prefix), use broader terms, or try synonyms.
- If too many irrelevant results: add qualifier terms, restrict to specific domains, or add exclusion terms (`-tutorial -course` to filter learning content when seeking news).

### Step 2: Synonym Expansion

Generate 2-3 synonym queries:
- "AI code review" -> "automated code analysis", "LLM-powered code review", "AI pair programming"
- "newsletter automation" -> "email content automation", "automated email writing", "newsletter AI tools"

### Step 3: Adjacent Topics

When the core topic is too niche, expand to adjacent areas:
- "AI code review tools" -> "developer productivity tools 2026", "AI-assisted software development"
- This captures findings that mention the core topic within a broader context.

### Step 4: Temporal Adjustment

When recency queries return nothing:
- Remove year constraint and search without temporal qualifier.
- Try "latest" or "new" instead of a specific year.
- Check if the topic is genuinely new (may have limited coverage) or established (year-old content may still be canonical).

## Anti-Patterns

Avoid these common query mistakes:

| Anti-Pattern | Why It Fails | Better Alternative |
|-------------|--------------|-------------------|
| Single keyword ("AI") | Too broad, returns millions of irrelevant results | "AI code review tools for developers" |
| Long natural language ("What are the best AI code review tools available in 2026 for Python developers?") | Search engines parse this poorly | "best AI code review tools Python 2026" |
| Multiple `site:` in one query | Most search engines only support one `site:` per query | Run separate queries per site |
| Quoted sentences from articles | Returns only that exact article | Extract 2-3 key terms instead |
| Negation-heavy queries ("-tutorial -course -beginner -intro") | Over-filtering removes valid results | Use positive terms that describe what you want |
| Same query repeated across sources | Wastes query budget on redundant results | Vary the angle per source type |
