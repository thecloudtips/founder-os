# Quick Start: founder-os-competitive-intel-compiler

> Research competitors and compile structured intelligence reports in minutes.

## Overview

**Plugin #15** | **Pillar**: Code Without Coding | **Platform**: Claude Code

Competitive Intel Compiler executes live web searches to gather intelligence on any competitor: pricing, features, customer reviews, positioning, and recent news. Generate single-competitor reports or multi-competitor comparison matrices. Add `--your-product` to see how you stack up.

### What This Plugin Does

- Researches competitors via 4-6 targeted web searches per company
- Normalizes pricing, aggregates review scores, and classifies positioning
- Produces structured reports with strategic recommendations
- Builds comparison matrices for multiple competitors side-by-side
- Compares against your own product when you provide context (optional)

## Available Commands

| Command | Description |
|---------|-------------|
| `/compete:research [company]` | Deep research on one competitor |
| `/compete:matrix [company1] [company2] ...` | Comparison matrix for 2+ competitors |

## Usage Examples

### Example 1: Research a Single Competitor

```
/compete:research Notion
```

**What happens:**
- Runs 4-6 web searches covering pricing, features, G2/Capterra reviews, homepage positioning, and recent news
- Extracts and normalizes all findings
- Produces a structured report with executive summary, pricing table, features breakdown, review analysis, and 3-5 strategic recommendations
- Saves to `competitive-intel/notion-[date].md`
- Logs to Notion "Founder OS HQ - Research" database with Type="Competitive Analysis" (if configured; falls back to legacy "Competitive Intel Compiler - Research")

---

### Example 2: Research with Self-Comparison

```
/compete:research Linear --your-product="Project management tool for agencies, $49/month flat, strong client portal, no mobile app yet"
```

**What happens:**
- Same research as Example 1
- Adds a "vs You" section showing:
  - Feature-by-feature comparison table (where you win ✅, where they win)
  - Your pricing position relative to Linear
  - Differentiation opportunities and positioning recommendation
- Strategic recommendations tailored to your competitive position

---

### Example 3: Build a Comparison Matrix

```
/compete:matrix Asana ClickUp Monday Trello
```

**What happens:**
- Runs fresh searches for all 4 companies (always fresh — no caching)
- Researches each across all 5 dimensions
- Builds a 7-row comparison matrix (Pricing, Target Market, Key Features, Positioning, Review Score, Strengths, Weaknesses)
- Saves to `competitive-intel/matrix-[date].md`

---

### Example 4: Matrix with Your Product

```
/compete:matrix Figma Sketch --your-product="Design handoff tool for non-designers, free tier, Notion-native"
```

**What happens:**
- Researches Figma and Sketch
- Adds a "You" column to the matrix
- Marks cells where you have an advantage with ✅
- Marks underserved market positions with 💡
- Adds a "Positioning Opportunity" row at the bottom
- Includes differentiation recommendations

---

### Example 5: Custom Output Path

```
/compete:research Notion --output=~/reports/notion-competitor-analysis.md
```

**What happens:**
- Same as Example 1 but saves the report to your specified path

---

## Tips

- Start with `/compete:research` for deep analysis of your top competitor
- Use `/compete:matrix` when you want to survey the whole competitive landscape
- Always add `--your-product` to get positioning recommendations tailored to your situation
- Research is always fresh — run the command again to update with current data
- Reports are saved locally even without Notion — check `competitive-intel/` in your working directory
- Review scores come from G2, Capterra, and ProductHunt — check for recency if industry is fast-moving

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "No web search results" | Verify Claude Code has internet access and WebSearch tool is enabled |
| "Unable to save file" | Check Filesystem MCP is configured with the correct directory path |
| "Notion unavailable" | Report still works — results shown in chat and saved to local file |
| Pricing looks wrong | Pricing changes frequently — check the source directly for confirmation |
| Company not found | Try with the full domain (e.g., `notion.so`) instead of just the name |

## Next Steps

1. Research your top 2-3 competitors with `/compete:research`
2. Build a comparison matrix with `/compete:matrix`
3. Add `--your-product` to get your positioning recommendations
4. Save key insights to Notion for team sharing (configure Notion MCP in INSTALL.md)
