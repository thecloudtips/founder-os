---
description: Extract key points from a document or pasted text and generate a LinkedIn post
argument-hint: "[file-path-or-paste] [--audience=founder|technical|marketer|cxo] [--framework=auto|story|listicle|contrarian|howto|lesson|insight|question] [--length=short|medium|long] [--output=PATH]"
allowed-tools: ["Read", "Write"]
---

# LinkedIn Post from Document

Transform a document, article, or pasted text into a LinkedIn post. Extract the key points, auto-select the best framework for the content type, and generate a post in founder voice.

## Load Skills

Read all three skills and the template before starting:
1. `${CLAUDE_PLUGIN_ROOT}/skills/linkedin-writing/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/skills/hook-creation/SKILL.md`
3. `${CLAUDE_PLUGIN_ROOT}/skills/founder-voice/SKILL.md`
4. `${CLAUDE_PLUGIN_ROOT}/templates/linkedin-post-template.md`

## Parse Arguments

Determine the source from `$ARGUMENTS`:

- **File path**: If `$ARGUMENTS` starts with a path (contains `/` or `.` extension like `.md`, `.txt`, `.pdf`), read the file. Supported formats: `.md`, `.txt`, `.pdf` (via Read tool). If the file does not exist, display: "File not found: [path]. Check the path and try again." Then stop.
- **Pasted text**: If `$ARGUMENTS` contains multi-line text or is longer than 200 characters without a file extension, treat it as pasted content.
- **No input**: If no arguments, prompt: "Paste a document, article, or provide a file path. Supported formats: .md, .txt, .pdf" Then stop and wait.

Parse flags:
- `--audience=founder|technical|marketer|cxo` (optional) — Default: `founder`
- `--framework=auto|story|listicle|contrarian|howto|lesson|insight|question` (optional) — Default: `auto`
- `--length=short|medium|long` (optional) — Default: `medium`
- `--output=PATH` (optional) — Default: `linkedin-posts/[topic-slug]-[YYYY-MM-DD].md`

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Phase 1 — Extract

Display: **"Phase 1/3: Extracting key points from document..."**

1. **Read the source**: Load the file or use the pasted text.
2. **Identify document type**: Classify as one of:
   - Blog post / article
   - Meeting notes / transcript
   - Report / whitepaper
   - Email thread
   - Personal notes / brain dump
   - Other

3. **Extract key points**: Pull out the 3-7 most important insights, takeaways, or ideas from the source. For each:
   - **Point**: One-sentence summary
   - **Supporting detail**: A quote, number, or example from the source
   - **LinkedIn angle**: How this translates to a LinkedIn-worthy insight

4. **Identify the strongest angle**: Select the one point or combination that would make the most engaging LinkedIn post. Consider: surprise factor, relatability, practical value, controversy potential.

5. **Auto-select framework** (if `--framework=auto`): Based on document type and strongest angle:
   - Blog post with personal story → Story or Personal Lesson
   - Report with data → Industry Insight
   - How-to article → How-To
   - Opinion piece → Contrarian Take
   - Notes with multiple insights → Listicle
   - Meeting notes with decisions → Story or How-To
   - Default fallback: Personal Lesson

### Extraction Output

Display:
```
## Phase 1 Complete: Key Points Extracted

**Source**: [filename or "Pasted text"]
**Document type**: [type]
**Key points found**: [count]

### Strongest Angle
[Description of the angle and why it works for LinkedIn]

**Selected framework**: [name]

Proceeding to draft...
```

## Phase 2 — Draft

Display: **"Phase 2/3: Writing LinkedIn post..."**

Follow the same drafting process as `/linkedin:post` Phase 2:
1. Write the post using the template scaffold
2. Apply the selected framework structure
3. Generate a strong hook using the hook-creation skill
4. Write body using extracted key points (not all — select the 2-4 that serve the framework best)
5. Apply founder-voice: professional-but-conversational, opinionated, short-long alternation
6. End with an audience-appropriate closer
7. Stay within character limits for the selected length mode
8. Generate 3-5 hashtags

## Phase 3 — Validate and Output

Display: **"Phase 3/3: Formatting and validating..."**

1. Run quality checklist from linkedin-writing skill.
2. Verify character count is within length mode AND under 3000.
3. Display the complete post in chat.
4. Show summary block:

```
---

## Post Summary

- **Source**: [filename or "Pasted text"] ([word count] words)
- **Topic**: [extracted topic]
- **Framework**: [selected framework]
- **Audience**: [target segment]
- **Length**: [mode] ([character count] characters)
- **Key points used**: [count of total] from source

**File**: [output path]

Copy the post above and paste directly into LinkedIn, or edit the file at [output path].
```

5. Save to file with YAML frontmatter (topic, source, framework, audience, length, character_count, generated_at).

## Notion Integration

Same as `/linkedin:post`:
1. **Discover database**: Search Notion for **"[FOS] Content"**. If not found, try **"Founder OS HQ - Content"**. If not found, fall back to **"LinkedIn Post Generator - Posts"** (legacy name). If none is found, skip Notion logging silently.
2. Create/update page with `Type = "LinkedIn Post"` (idempotent by Title + Type="LinkedIn Post" + Framework + same calendar day)
3. Include source document info in Style Notes property

## Graceful Degradation

If Notion MCP unavailable: complete pipeline, display in chat, save file. No warning about Notion.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/linkedin:from-doc blog-post.md
/linkedin:from-doc ~/Documents/quarterly-report.pdf --framework=insight --audience=cxo
/linkedin:from-doc meeting-notes.txt --length=short
/linkedin:from-doc "Here is a long piece of text I want to turn into a LinkedIn post..."
/linkedin:from-doc article.md --audience=technical --framework=howto --output=posts/dev-tips.md
```
