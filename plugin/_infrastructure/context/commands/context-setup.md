---
description: Set up business context files through a guided conversational interview
argument-hint: "[--from-files] [--reset]"
allowed-tools: ["Read", "Write", "AskUserQuestion", "Glob"]
---

# /context:setup

Create or update the 3 business context files that personalize all Founder OS plugins.

## Parse Arguments

- `--from-files` (optional) — Import context from existing documents (business plans, pitch decks, etc.) found in `_infrastructure/context/import/` directory
- `--reset` (optional) — Delete existing context files and start fresh

## Prerequisites

Check if context files already exist at `_infrastructure/context/active/`:
- If they exist and `--reset` is NOT set: inform user that files exist, offer to update specific sections or `--reset` to start over
- If `--reset`: delete existing .md files in active/, proceed with fresh interview

## Workflow

### Step 1: Check for importable documents

If `--from-files` is set:
1. Scan `_infrastructure/context/import/` for any documents (.md, .txt, .pdf, .docx)
2. Read and analyze each document
3. Extract relevant business information to pre-fill the interview
4. Inform user: "Found [N] documents. I'll use these to pre-fill your context. You can correct anything during the interview."

### Step 2: Business Information Interview

Ask the user conversationally about their business. Use AskUserQuestion for each topic, one at a time:

1. "What's your company name and what do you do? (one sentence)"
2. "What's your business model? (SaaS, services, consulting, products, etc.)"
3. "Who are your typical clients? (industry, size, any key names)"
4. "How big is your team? (list key roles if small team)"
5. "What tools do you use daily? (project mgmt, CRM, comms, etc.)"

Generate `_infrastructure/context/active/business-info.md` from the template at `_infrastructure/context/templates/business-info.md`, filled with their answers.

### Step 3: Strategy Interview

1. "What are your top 3 priorities this quarter?"
2. "Any constraints I should know about? (budget, timeline, resources)"
3. "What does success look like for you this quarter?"

Generate `_infrastructure/context/active/strategy.md` from the template.

### Step 4: Current Data Interview

1. "Who are your active clients right now? (name as many as you'd like)"
2. "Any key metrics you track? (revenue, pipeline, projects, etc.)"
3. "Have you set up any Notion databases for Founder OS yet? (I can auto-detect these)"

If user mentions Notion, attempt to query for [FOS] databases and populate Notion DB IDs automatically.

Generate `_infrastructure/context/active/current-data.md` from the template.

### Step 5: Confirmation

Display summary:
```
Context files created:
  _infrastructure/context/active/business-info.md
  _infrastructure/context/active/strategy.md
  _infrastructure/context/active/current-data.md

These files are gitignored (they contain business-sensitive data).
All 30 Founder OS plugins will now use this context to personalize their output.

To update later: edit the files directly, or re-run /context:setup --reset
```

## Graceful Degradation

- If user declines to answer a question: leave that section as "[Not provided]" in the generated file
- If Notion query fails: skip DB ID population, note as "not configured"
- If no import documents found with `--from-files`: proceed with normal interview
