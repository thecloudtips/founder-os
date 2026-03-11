---
description: Create newsletter structure from research findings
argument-hint: "[--sections=N]"
allowed-tools: ["Read"]
---

# Newsletter Outline

Create a structured newsletter outline by clustering research findings into thematic sections with a compelling hook.

## Load Skills

Read the newsletter-writing skill at `${CLAUDE_PLUGIN_ROOT}/skills/newsletter-writing/SKILL.md` for structure guidelines, hook types, section formatting, and target length definitions. Use this skill throughout the outline process.

## Parse Arguments

Extract optional flags from the user's command:

- `--sections=N` — Number of main sections (default: 4, valid range: 3-5). Clamp values outside this range and inform the user.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Check for Research

Look for research findings from a prior `/newsletter:research` run in the current conversation. Research output typically contains source names, key findings, trends, stats, and quotes.

If no research findings are found in the conversation context, prompt the user:

> No research findings in this conversation. Run `/newsletter:research [topic]` first, or paste your research notes here.

Then stop and wait for user input. Do not fabricate research or proceed without source material.

## Cluster Findings

Group the research findings into thematic clusters:

1. Identify recurring themes, related data points, and complementary insights across all findings.
2. Merge closely related findings into a single cluster. Split overly broad clusters.
3. Target exactly N clusters (per the `--sections` flag) — each cluster becomes one main section.
4. Assign a working title to each cluster that captures the theme.
5. Within each cluster, select the 2-3 strongest points supported by sources.

## Choose Hook Angle

Select the most impactful or surprising finding as the newsletter hook:

1. Scan all findings for: unexpected stats, contrarian takes, compelling stories, or provocative questions.
2. Apply hook type selection from the newsletter-writing skill. Choose one of:
   - **stat-led** — Lead with a striking number or data point
   - **contrarian** — Challenge a common assumption
   - **story-led** — Open with a brief narrative or anecdote
   - **question** — Pose a thought-provoking question the reader can't ignore
3. Pick the hook type that best fits the strongest finding. Prioritize surprise and relevance to the target audience.

## Build Outline

Structure the full newsletter outline:

1. **Hook**: Identify which finding to use, why it matters to the reader, and the selected hook type. Write 2-3 sentences describing the hook angle.
2. **Sections 1-N**: For each section, provide:
   - A clear, engaging title
   - 2-3 key points with source references
   - An angle note describing how to present the material
3. **Key Takeaways**: Distill 3-5 actionable bullets the reader can apply immediately. Each takeaway should be concrete and specific, not generic advice.
4. **CTA Direction**: Define what reader engagement to drive (reply, share, try something, visit a link, etc.).

## Display Outline

Present the outline in the following format:

```
## Newsletter Outline

**Topic**: [topic from research]
**Hook type**: [stat-led|contrarian|story-led|question]
**Sections**: [N]
**Target length**: [type from skill]

---

### Hook
[2-3 sentences describing the hook angle]

### Section 1: [Title]
- Key point 1 (source: [name])
- Key point 2 (source: [name])
- Angle: [how to present this]

### Section 2: [Title]
- Key point 1 (source: [name])
- Key point 2 (source: [name])
- Angle: [how to present this]

[...repeat for all sections...]

### Key Takeaways
1. [Actionable insight]
2. [Actionable insight]
3. [Actionable insight]

### CTA Direction
[What to prompt readers to do]

---

Run `/newsletter:draft` to write the full newsletter from this outline.
```

After displaying, wait for user feedback. The user may ask to adjust sections, change the hook type, reorder content, or add/remove points before proceeding to the draft step.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

- `/newsletter:outline` — Build a 4-section outline from research already in the conversation
- `/newsletter:outline --sections=3` — Build a concise 3-section outline
- `/newsletter:outline --sections=5` — Build a detailed 5-section outline
