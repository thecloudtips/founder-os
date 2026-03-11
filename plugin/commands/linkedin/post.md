---
description: Generate a LinkedIn post from a topic with framework selection, audience targeting, and founder voice
argument-hint: "[topic] [--audience=founder|technical|marketer|cxo] [--framework=story|listicle|contrarian|howto|lesson|insight|question] [--length=short|medium|long] [--emojis] [--output=PATH]"
allowed-tools: ["Read", "Write"]
---

# LinkedIn Post Generator

Generate a polished LinkedIn post from a topic in one pass. This command executes the full ideation-to-output pipeline without stopping for user input between phases.

## Load All Skills

Read all three skills and the template before starting any phase:

1. `${CLAUDE_PLUGIN_ROOT}/skills/linkedin/linkedin-writing/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/skills/linkedin/hook-creation/SKILL.md`
3. `${CLAUDE_PLUGIN_ROOT}/skills/linkedin/founder-voice/SKILL.md`
4. `${CLAUDE_PLUGIN_ROOT}/templates/linkedin-post-template.md`

Apply linkedin-writing for structure and formatting rules, hook-creation for the opening lines, and founder-voice for tone throughout the post.

## Parse Arguments

Extract the topic and flags from `$ARGUMENTS`:

- **topic** (required) — all text before any `--` flags. This is the post subject. If no topic is provided, prompt the user: "What topic should the LinkedIn post cover?" Then stop and wait for input.
- `--audience=founder|technical|marketer|cxo` (optional) — target reader segment. Default: `founder`.
- `--framework=story|listicle|contrarian|howto|lesson|insight|question` (optional) — post structure framework. Default: `auto` (auto-select based on topic analysis).
- `--length=short|medium|long` (optional) — post length mode. Default: `medium`. Map to character limits per the linkedin-writing skill.
- `--emojis` (optional flag, no value) — enable emoji mode. When present, allow 1-3 strategic emojis per the template's emoji mode rules. When absent, use zero emojis.
- `--output=PATH` (optional) — file path for saving the post. Default: `linkedin-posts/[topic-slug]-[YYYY-MM-DD].md` where `topic-slug` is the topic in lowercase kebab-case with special characters removed.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Phase 1 — Ideation

Display: **"Phase 1/3: Planning post..."**

1. **Framework selection**: If `--framework=auto` or not specified, analyze the topic and select the best framework using the linkedin-writing skill's framework selection logic. Consider topic type, audience, and content shape:
   - Personal experience or journey → `story`
   - Tips, steps, or enumerable items → `listicle`
   - Challenging conventional wisdom → `contrarian`
   - Teaching a process → `howto`
   - Reflection on a mistake or win → `lesson`
   - Industry observation or trend → `insight`
   - Provoking discussion → `question`

   Display the selected framework and the reasoning in one sentence.

2. **Hook generation**: Using the hook-creation skill, generate 3 candidate hooks for the topic and selected framework. Each hook must be distinct in approach (e.g., stat-led, bold claim, question, micro-story). Select the strongest one based on scroll-stopping power and relevance. Show all 3 candidates and mark the selected one.

3. **Key points**: Identify 3-5 key points or beats for the post body based on the topic and framework. Each point should be a single clear idea that supports the hook's promise. List them in the order they will appear.

4. **Audience calibration**: Note specific adjustments for the target audience:
   - **founder**: Practical, ROI-focused, time-saving angle, "fellow builder" tone
   - **technical**: Specific, evidence-based, implementation details, avoid fluff
   - **marketer**: Growth metrics, campaign angles, channel strategy, trend awareness
   - **cxo**: Strategic, high-level impact, decision frameworks, industry positioning

   Display the audience and 2-3 calibration notes that will shape the draft.

### Ideation Output

Display the plan:

```
## Phase 1 Complete: Post Plan

- **Topic**: [topic]
- **Framework**: [selected] — [one-sentence reasoning]
- **Audience**: [segment]
- **Length**: [mode]

### Hook Candidates
1. [hook text] ← selected
2. [hook text]
3. [hook text]

### Key Points
1. [point]
2. [point]
3. [point]
[...]

### Audience Calibration
- [adjustment 1]
- [adjustment 2]
- [adjustment 3]
```

Display: **"Plan ready. Writing draft..."**

## Phase 2 — Draft

Display: **"Phase 2/3: Writing post in founder voice..."**

1. **Write the full LinkedIn post** using the template scaffold from `${CLAUDE_PLUGIN_ROOT}/templates/linkedin-post-template.md`:

   - **Hook**: Open with the selected hook from Phase 1. The hook must be the first 1-3 lines of the post and must work as a standalone scroll-stopper before the "see more" fold.
   - **Body**: Apply the selected framework's structure:
     - `story`: Setup → Tension → Turning point → Resolution → Takeaway
     - `listicle`: Brief intro → Numbered items (each 1-2 sentences) → Wrap-up
     - `contrarian`: Bold claim → Evidence against conventional wisdom → Reframe → New perspective
     - `howto`: Problem statement → Step-by-step → Result/proof
     - `lesson`: Context → What happened → What I learned → Why it matters
     - `insight`: Observation → Supporting evidence → Implication → What to do about it
     - `question`: Provocative question → Context → Multiple angles → Invite responses
   - **Formatting**: Follow linkedin-writing skill rules:
     - Line break after every 1-2 sentences
     - One idea per visual block
     - Short paragraphs (1-3 lines max)
     - Use white space aggressively — LinkedIn rewards scannable posts
     - No markdown rendering (no bold, no headers, no bullet symbols) — write as plain text that LinkedIn will display correctly
   - **Voice**: Apply founder-voice skill throughout:
     - Professional but conversational
     - Opinionated — take a clear stance
     - Short-long sentence alternation for rhythm
     - First person where natural
     - Concrete examples over abstract advice
   - **Closer**: End with one of these matched to audience:
     - **CTA** (marketer/cxo): Direct ask — "DM me if...", "Try this today..."
     - **Engagement prompt** (founder): Question that invites comments — "What's your take?", "Has anyone else experienced this?"
     - **Summary line** (technical): Crisp takeaway that stands alone
   - **Length enforcement**: Stay within the selected length mode character limits from the linkedin-writing skill. Count characters including line breaks but excluding hashtags.
   - **Emoji mode**: If `--emojis` flag is set, add 1-3 strategic emojis per the template's emoji mode rules. Place them at line starts or as visual separators — never mid-sentence. If the flag is not set, use zero emojis.

2. **Generate hashtags**: 3-5 hashtags following linkedin-writing skill rules:
   - 1-2 broad/high-volume hashtags for discoverability
   - 2-3 niche/topic-specific hashtags for targeting
   - CamelCase format (e.g., #SmallBusiness, #FounderLife)
   - Place below the post body separated by a blank line
   - Never place hashtags inline within the post body

## Phase 3 — Validate and Output

Display: **"Phase 3/3: Formatting and validating..."**

1. **Run quality checklist** from the linkedin-writing skill. Check every item against the draft. If any item fails, fix it before outputting. Do not show the checklist to the user — just fix silently and move on.

2. **Character count**: Count total characters including line breaks and hashtags. Confirm:
   - The post is within the selected length mode's character range
   - The post is under 3,000 characters absolute maximum
   - If over limit, trim from the body (never the hook or closer). Re-count after trimming.

3. **Display the post**: Show the complete post in chat, formatted exactly as it would appear on LinkedIn — plain text with line breaks, no markdown rendering. Add a blank line, then the hashtags. Then display the summary block:

```
---

## Post Summary

- **Topic**: [topic]
- **Framework**: [selected framework]
- **Audience**: [target segment]
- **Length**: [mode] ([character count] characters)
- **Hashtags**: [count]
- **Emojis**: [yes/no]

**File**: [output path]

Copy the post above and paste directly into LinkedIn, or edit the file at [output path].
```

4. **Save to file**: Write the post to the output path. Create the parent directory if it does not exist. The saved file must include a YAML frontmatter header:

```yaml
---
topic: "[topic]"
framework: "[selected framework]"
audience: "[target audience]"
length: "[mode]"
character_count: [count]
generated_at: "[YYYY-MM-DDTHH:MM:SS]"
---
```

The post body follows the frontmatter, formatted identically to the chat output (plain text with line breaks, then hashtags).

## Notion Integration

After the file is saved:

1. **Discover database**: Search Notion for **"[FOS] Content"**. If not found, try **"Founder OS HQ - Content"**. If not found, fall back to **"LinkedIn Post Generator - Posts"** (legacy name). If none is found, skip Notion logging silently.
2. **Create or update page**: Upsert by Title + Type="LinkedIn Post" + Framework + same calendar day (idempotent). Populate properties:
   - **Title**: Post topic
   - **Type**: `"LinkedIn Post"`
   - **Content**: The full post text
   - **Status**: `"Draft"`
   - **Framework**: Selected framework
   - **Audience**: Target audience segment
   - **Length**: Length mode
   - **Hashtags**: Generated hashtags
   - **Style Notes**: Style guidance or voice notes
   - **Output File**: Saved file path
   - **Generated At**: Current timestamp

## Graceful Degradation

If Notion MCP is unavailable or any Notion operation fails:
- Complete the full pipeline and display all output in chat
- Save the file to the output path
- Do not warn or error about Notion — chat and file output are fully sufficient

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/founder-os:linkedin:post "why I stopped using OKRs"
/founder-os:linkedin:post "hiring your first engineer" --audience=founder --framework=story
/founder-os:linkedin:post "AI tools for small teams" --length=long --emojis
/founder-os:linkedin:post "cold email tips" --framework=listicle --audience=marketer --output=posts/cold-email.md
/founder-os:linkedin:post "the future of remote work" --audience=cxo --framework=insight --length=long
```
