---
description: Generate multiple variations of a LinkedIn post with different hooks, frameworks, and tones
argument-hint: "[draft-or-topic] [--audience=founder|technical|marketer|cxo] [--count=3]"
allowed-tools: ["Read"]
---

# LinkedIn Variations

Generate multiple variations of a LinkedIn post, each varying the hook style, framework, and tone. This command is ephemeral — no Notion logging, no file output. Results display in chat only.

## Load Skills

Read all three skills before starting:
1. `${CLAUDE_PLUGIN_ROOT}/skills/linkedin-writing/SKILL.md`
2. `${CLAUDE_PLUGIN_ROOT}/skills/hook-creation/SKILL.md`
3. `${CLAUDE_PLUGIN_ROOT}/skills/founder-voice/SKILL.md`

## Parse Input

Determine the source material from `$ARGUMENTS`:
- **Option A — Existing draft in conversation**: If a LinkedIn post was generated earlier in this conversation (via `/linkedin:post` or `/linkedin:from-doc`), use that as the source. The post text and its metadata (topic, framework, audience) should be available from the prior output.
- **Option B — Pasted text**: If `$ARGUMENTS` contains multi-line text or quoted text, treat it as the source draft.
- **Option C — Topic only**: If `$ARGUMENTS` is a short phrase (single line, no post-like formatting), treat it as a new topic.
- **No input**: If no arguments AND no prior post in conversation, prompt: "Paste a LinkedIn post draft, or provide a topic. You can also run `/linkedin:post [topic]` first, then run `/linkedin:variations` to get variations."  Then stop and wait.

Parse flags:
- `--audience=founder|technical|marketer|cxo` (optional) — Default: `founder` or inherit from prior post
- `--count=N` (optional) — Number of variations. Default: 3. Max: 5.

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Generate Variations

For each variation (up to count), change at least TWO of these three elements:

1. **Hook style**: Use a different formula from the hook-creation skill (stat-led, question, story, contrarian, bold claim, pattern interrupt)
2. **Framework**: Use a different framework from the linkedin-writing skill (story, listicle, contrarian take, how-to, personal lesson, industry insight, question-led)
3. **Tone shift**: Adjust within founder voice — bold/assertive, thoughtful/reflective, practical/tactical, provocative/challenging

Rules:
- Each variation must use a DIFFERENT framework than the others
- Each variation must use a DIFFERENT hook formula than the others
- All variations stay within the same audience segment
- All variations should be Medium length (500-1500 characters) unless the source was Short or Long
- Apply founder-voice skill to all variations
- Generate 3-5 hashtags per variation (can vary between variations)

## Output Format

Display all variations with clear labels:

```
## Variation 1: [Framework] + [Hook Formula] — [Tone]

[Complete LinkedIn post]

[hashtags]

**Characters**: [count] | **Framework**: [name] | **Hook**: [formula]

---

## Variation 2: [Framework] + [Hook Formula] — [Tone]

[Complete LinkedIn post]

[hashtags]

**Characters**: [count] | **Framework**: [name] | **Hook**: [formula]

---

## Variation 3: [Framework] + [Hook Formula] — [Tone]
...
```

After all variations:

```
---

## Comparison

| # | Framework | Hook | Tone | Characters |
|---|-----------|------|------|------------|
| 1 | [name] | [formula] | [tone] | [count] |
| 2 | ... | ... | ... | ... |
| 3 | ... | ... | ... | ... |

Pick the one that resonates most, or mix elements from different variations. Copy directly to LinkedIn.
```

## No Persistence

This command is ephemeral by design (like P19 `/slack:catch-up`):
- No file output
- No Notion logging
- Results display in chat only
- Users can copy-paste their preferred variation

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/linkedin:variations
/linkedin:variations "why I stopped using OKRs"
/linkedin:variations --count=5
/linkedin:variations --audience=technical
/linkedin:variations "Paste your draft here\nLine 2\nLine 3" --count=4
```
