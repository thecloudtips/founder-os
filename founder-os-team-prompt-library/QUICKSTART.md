# Quickstart: Team Prompt Library (#26)

Build and share a reusable AI prompt library with variable substitution, usage tracking, and quality scoring — all stored in Notion.

---

## Commands

| Command | What It Does |
|---------|-------------|
| `/prompt:add [name]` | Add a new prompt to the library |
| `/prompt:list [category]` | Browse prompts, optionally filtered by category |
| `/prompt:get [name]` | Retrieve a prompt with variable substitution applied |
| `/prompt:share [name]` | Generate a shareable Notion block for your team |
| `/prompt:optimize [name]` | Score a prompt and get improvement suggestions |

---

## Usage Examples

### 1. Add a Prompt with Variables

Store a reusable prompt with `{{variable}}` placeholders for the parts that change each time.

```
/prompt:add "Client Onboarding Email"
  --category="Email Templates"
  --tags="onboarding, client, email"
  --use-case="Send to new clients after signing"
  --text="Write a warm onboarding email to {{client_name}} at {{company_name}}.
  They have just signed up for {{service_name}}. Key milestones in week one: {{week_one_milestones}}.
  Tone: professional but friendly. Length: 150-200 words."
```

Claude will save the prompt to Notion and confirm the variables detected: `client_name`, `company_name`, `service_name`, `week_one_milestones`.

---

### 2. List Prompts by Category

Browse your library to see what is available. Filter by category to narrow results.

```
/prompt:list "Email Templates"
```

Claude will return a formatted list of all prompts in that category, sorted by usage count (most used first), with their tags, author, and quality score if available.

To see everything in the library:

```
/prompt:list
```

---

### 3. Get a Prompt with Variable Substitution

Retrieve a stored prompt and fill in the variables interactively.

```
/prompt:get "Client Onboarding Email"
```

Claude will detect the `{{variable}}` placeholders in the prompt and ask you to supply values:

- `client_name` → Sarah Chen
- `company_name` → Bright Horizon Co
- `service_name` → Monthly Strategy Retainer
- `week_one_milestones` → Kickoff call, Notion workspace setup, shared Slack channel

Claude returns the fully substituted prompt, ready to paste into any AI tool. Usage count is incremented automatically in Notion.

---

### 4. Share a Prompt with Your Team

Generate a shareable Notion block so teammates can find and use the prompt.

```
/prompt:share "Client Onboarding Email"
```

Claude will format the prompt as a clean Notion page block — including the full prompt text, variable list, use case description, and usage tips — and update the Notion record with a share timestamp. You can copy the Notion page link and send it directly to your team.

---

### 5. Optimize a Prompt

Run the quality scoring rubric against a stored prompt and get concrete improvement suggestions.

```
/prompt:optimize "Client Onboarding Email"
```

Claude will score the prompt across dimensions such as clarity, specificity, output constraints, tone guidance, and variable coverage — returning a score out of 100 with a prioritized list of improvements. Optionally, it generates an A/B variant applying the top suggestions so you can compare before updating the library.

---

## Tips

**Variable syntax:** Use double curly braces — `{{variable_name}}` — anywhere in your prompt text. Variable names should be lowercase with underscores (e.g., `{{client_name}}`, `{{project_deadline}}`). Claude detects them automatically when you add or retrieve a prompt.

**Quality checks:** Run `/prompt:optimize` after adding any new prompt to catch ambiguous instructions, missing output constraints, or prompts that are too vague to produce consistent results. A score of 80+ indicates a production-ready prompt.

**Categories to start with:** Email Templates, Meeting Prep, Proposals, Weekly Reviews, Client Communication, Research, Social Media. Consistent category names make `/prompt:list` far more useful as your library grows.

**Database setup:** The plugin stores prompts in the **[FOS] Prompts** database (or falls back to **Founder OS HQ - Prompts**, then **Team Prompt Library - Prompts**). Use the Founder OS HQ workspace template to provision the database before first use.

**Idempotent adds:** Running `/prompt:add` with the same prompt name updates the existing record rather than creating a duplicate. Use this to iterate on prompt text without cluttering your library.

---

## Time Savings

Each well-crafted shared prompt saves roughly **15 minutes per reuse session** — the time it typically takes to redraft, refine, and test a prompt from scratch. A library of 20 active prompts used weekly across a team of three compounds into hours saved every month.

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "No prompts found" on first `/prompt:list` | Database not yet created | Run `/prompt:add` to create your first prompt and initialize the DB |
| Variables not detected on `/prompt:get` | Placeholder not using `{{double_braces}}` | Edit the prompt text to use `{{variable_name}}` format |
| `/prompt:share` link not working | Integration not shared with the page | See INSTALL.md Step 3 — share integration access with the parent page |
| Quality score seems low | Prompt is too vague or missing output constraints | Follow the suggestions from `/prompt:optimize` and re-run to verify improvement |
| Notion API errors | Token expired or wrong key | Verify `NOTION_API_KEY` env var matches your integration token |
