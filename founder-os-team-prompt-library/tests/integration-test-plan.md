# Integration Test Plan: Team Prompt Library

## Overview

This test plan validates the P26 Team Prompt Library plugin against all acceptance criteria. Tests cover all five commands (`/prompt:add`, `/prompt:list`, `/prompt:get`, `/prompt:share`, `/prompt:optimize`), both skills (prompt-management, prompt-optimization), quality scoring behavior, variable detection, usage tracking, visibility controls, Notion DB integration, and resilience paths.

## Prerequisites

- Plugin installed in Claude Code
- Notion MCP configured with a valid API key and accessible workspace
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") Notion database pre-populated (to test read/write operations), or absent (to test discovery failure handling)
- AskUserQuestion capability available for interactive flow tests

---

## /prompt:add Tests

### TC-01

**Category**: /prompt:add — Basic Add

**Test Name**: Add a well-formed prompt with all arguments provided

**Preconditions**:
- Notion MCP connected and accessible
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database exists (or will be created)
- No existing prompt named "Client Intro Email" in the library

**Steps**:
1. Run: `/prompt:add "Client Intro Email" "Write a warm introduction email to {{client_name}} at {{company_name}}. Introduce our agency, mention our work in {{industry}}, and propose a 30-minute call. Keep it under 150 words and end with a soft CTA." --category="Email Templates"`
2. Observe the quality check output
3. Observe the confirmation block after saving

**Expected Result**:
- Quality check runs and score displayed (expected 14–20/25 for this prompt)
- No AskUserQuestion prompt for category (provided inline)
- Notion page created with:
  - Name: "Client Intro Email"
  - Category: "Email Templates"
  - Variables: "client_name, company_name, industry"
  - Visibility: "Personal"
  - Times Used: 0
  - Created At: today's date in ISO 8601 format
  - Last Used: empty
- Confirmation block shows Name, Category, Variables, Visibility, and Quality score
- Suggests `/prompt:get`, `/prompt:share`, and `/prompt:optimize` follow-up commands

**Acceptance Criteria Reference**: Basic add with name and content; auto-detect `{{variables}}` in content; confirmation block output

---

### TC-02

**Category**: /prompt:add — Quality Check (Low Score)

**Test Name**: Low-quality prompt triggers improvement suggestion and user confirmation prompt

**Preconditions**:
- Notion MCP connected
- No existing prompt named "Report" in the library

**Steps**:
1. Run: `/prompt:add "Report" "Help me with the report."`
2. Observe the quality check output
3. Respond to AskUserQuestion with option "1" (save as-is)
4. Verify the prompt is saved

**Expected Result**:
- Quality check scores the prompt 6–10/25 (Poor tier)
- Full quality report displayed with all five dimension scores
- Anti-patterns detected: "Vague Action Verbs" (help me) and "No Audience or Recipient" at minimum
- TOP ISSUES section lists at least 2 concrete fixes
- AskUserQuestion displayed: options to (1) save as-is, (2) edit content now, or (3) cancel and optimize first
- On response "1": prompt saved to Notion with the low-quality content unchanged
- Confirmation block displayed after save
- No crash or silent failure on below-threshold content

**Acceptance Criteria Reference**: Quality check trigger; low-quality prompt gets improvement suggestion; user can still save as-is

---

### TC-03

**Category**: /prompt:add — Quality Check (Fair Score — Edit Path)

**Test Name**: Fair-scoring prompt can be edited inline before saving

**Preconditions**:
- Notion MCP connected
- No existing prompt named "Meeting Recap" in the library

**Steps**:
1. Run: `/prompt:add "Meeting Recap" "Summarize the meeting and list some action items." --category="Meeting Prompts"`
2. Observe the quality check (expected 11–15/25, Fair tier)
3. Respond to AskUserQuestion with option "2" (edit content now)
4. Provide updated content: "Summarize the meeting transcript below into three sections: (1) Key Decisions — numbered list, (2) Action Items — each with owner and deadline, (3) Open Questions — bullet list. Keep the total under 200 words."
5. Observe the re-scored quality check
6. Allow the save to proceed

**Expected Result**:
- Initial score falls in Fair tier (11–15/25)
- AskUserQuestion presented with all three options
- On selecting "2": current content displayed and "Paste the updated prompt content." message shown
- Re-run of Steps 4 and 5 on updated content before proceeding
- Updated content scores higher on second pass
- Final saved content in Notion is the edited version, not the original
- Variables re-detected from updated content

**Acceptance Criteria Reference**: Quality check trigger; edit path; variable re-detection after edit

---

### TC-04

**Category**: /prompt:add — Quality Check (Unusable Score)

**Test Name**: Score-5 prompt blocks save and requires revised content

**Preconditions**:
- Notion MCP connected

**Steps**:
1. Run: `/prompt:add "X" "A."`
2. Observe the quality check output
3. Note that no save occurs
4. Respond with: "cancel"

**Expected Result**:
- Quality check scores 5/25 (Unusable — all dimensions score 1)
- "Quality Check: 5/25 — Unusable" message displayed
- Explanation that content is too vague or missing a task statement
- AskUserQuestion: "Paste the revised prompt content, or type 'cancel' to stop."
- On "cancel": "Add cancelled. Run /prompt:add again when ready." displayed
- No Notion page created
- No error or stack trace

**Acceptance Criteria Reference**: Quality check blocks save on score 5; user must revise before saving

---

### TC-05

**Category**: /prompt:add — Variable Auto-Detection

**Test Name**: Variables in double curly braces are auto-detected and stored

**Preconditions**:
- Notion MCP connected
- No existing prompt named "Competitor Analysis Brief" in the library

**Steps**:
1. Run: `/prompt:add "Competitor Analysis Brief" "{{competitor_name}} analysis: list their top 3 strengths, top 3 weaknesses, and one strategic threat to us. Use bullet points. Base your response only on publicly available information." --category="Research Prompts"`
2. Observe variable detection output in the quality check block

**Expected Result**:
- Variable "competitor_name" is extracted via the regex `\{\{([a-zA-Z_][a-zA-Z0-9_]*)\}\}`
- Variables field displayed in the quality check output block
- Notion page created with Variables property: "competitor_name"
- Confirmation block shows: "Variables: {{competitor_name}}"
- No duplicate variable entries even if `{{competitor_name}}` appears multiple times in the content

**Acceptance Criteria Reference**: Auto-detect `{{variables}}` in content; Variables stored as comma-separated string

---

### TC-06

**Category**: /prompt:add — Variable Override Flag

**Test Name**: `--variables` flag overrides auto-detection; warns on mismatch

**Preconditions**:
- Notion MCP connected
- No existing prompt named "Status Update Template" in the library

**Steps**:
1. Run: `/prompt:add "Status Update Template" "This week we completed {{deliverable}} and are now working on the next phase. Status: on track." --variables=deliverable,owner`
2. Observe warning about mismatched variable

**Expected Result**:
- Variable "deliverable" from the flag is verified present in content — no warning
- Variable "owner" from the flag is NOT found in content — warning displayed: "Listed variable 'owner' was not found in the prompt content."
- Variables stored as "deliverable, owner" (flag takes precedence over auto-detection)
- Save proceeds after warning (no blocking)

**Acceptance Criteria Reference**: `--variables` override; mismatch warning

---

### TC-07

**Category**: /prompt:add — Category Selection via AskUserQuestion

**Test Name**: Category inferred and confirmed via interactive prompt when not provided

**Preconditions**:
- Notion MCP connected
- No existing prompt named "LinkedIn Post Hook" in the library

**Steps**:
1. Run: `/prompt:add "LinkedIn Post Hook" "Write a compelling opening line for a LinkedIn post about {{topic}}. The hook should stop scrolling, be under 25 words, and end with an implicit question or tension."`
2. Observe AskUserQuestion for category confirmation
3. Respond with "Content Creation"

**Expected Result**:
- No `--category` flag was provided
- Plugin infers a category from content (likely "Content Creation" for a LinkedIn post hook)
- AskUserQuestion displayed: "What category should this prompt be filed under? I'd suggest **Content Creation** based on the content. Options: Email Templates, Meeting Prompts, Analysis Prompts, Content Creation, Code Assistance, Research Prompts — or type a custom category."
- User response "Content Creation" accepted
- Notion page created with Category: "Content Creation"
- No second category confirmation asked

**Acceptance Criteria Reference**: Category selection via AskUserQuestion when not provided

---

### TC-08

**Category**: /prompt:add — Database Discovery

**Test Name**: Add command discovers database under HQ name or fallback name

**Preconditions**:
- Notion MCP connected
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database does NOT exist in the workspace
- This is the first run of any /prompt command

**Steps**:
1. Confirm via Notion that "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") does not exist
2. Run: `/prompt:add "Test Prompt" "Write a one-paragraph summary of {{document_title}} for {{audience}}. Keep it under 100 words." --category="Analysis Prompts"`
3. Observe the save output
4. Verify the database was created in Notion

**Expected Result**:
- Plugin searches for "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") — not found
- Database is created automatically with exactly 10 properties:
  - Name (title)
  - Content (rich_text)
  - Category (select)
  - Variables (rich_text)
  - Visibility (select)
  - Times Used (number)
  - Author (rich_text)
  - Tags (multi_select)
  - Created At (date)
  - Last Used (date)
- Prompt page created in the new database
- Completion summary shows "Saved to Notion: Yes"
- No error or "database not found" message

**Acceptance Criteria Reference**: Database discovery with HQ name first, fallback to legacy name

---

### TC-09

**Category**: /prompt:add — Duplicate Name Handling

**Test Name**: Adding a prompt with a name matching an existing record triggers conflict resolution

**Preconditions**:
- Notion MCP connected
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database exists
- A prompt named "Client Intro Email" already exists in the library

**Steps**:
1. Run: `/prompt:add "Client Intro Email" "A completely different intro email for {{recipient_name}}."`
2. Observe the duplicate detection message
3. Respond to AskUserQuestion with option "1" (overwrite)
4. Verify only one record exists for "Client Intro Email" after the operation

**Expected Result**:
- Plugin finds existing "Client Intro Email" page via case-insensitive name match
- Existing prompt content displayed to user
- AskUserQuestion: "A prompt named 'Client Intro Email' already exists. Would you like to (1) overwrite it with this new content, (2) save under a different name, or (3) cancel?"
- On "1": existing page updated with new content and new Variables
- Only one "Client Intro Email" page exists in the database after the operation
- No silent overwrite occurs before the user confirms

**Acceptance Criteria Reference**: Idempotent upsert by Name; no silent overwrite

---

### TC-10

**Category**: /prompt:add — Notion Unavailable

**Test Name**: /prompt:add stops immediately when Notion MCP is not connected

**Preconditions**:
- Notion MCP disconnected or misconfigured

**Steps**:
1. Run: `/prompt:add "Any Prompt" "Some content here that is longer than ten characters." --category="Email Templates"`
2. Observe the error output

**Expected Result**:
- Error displayed at Step 1 (Notion availability check):
  "Error: Notion MCP is required for /prompt:add.\nSee ${CLAUDE_PLUGIN_ROOT}/INSTALL.md for setup instructions."
- Execution stops immediately — no quality check runs
- No local file cache attempted
- No partial state left in the workspace

**Acceptance Criteria Reference**: Graceful error message when Notion unavailable

---

## /prompt:list Tests

### TC-11

**Category**: /prompt:list — Category Filter

**Test Name**: Listing by category returns only prompts in that category

**Preconditions**:
- Notion MCP connected
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database exists
- At least 3 prompts exist with Category "Email Templates"
- At least 2 prompts exist with Category "Research Prompts"
- At least 1 prompt exists with no category

**Steps**:
1. Run: `/prompt:list "Email Templates"`
2. Observe the output table

**Expected Result**:
- Only prompts with Category = "Email Templates" are shown (case-insensitive match)
- Prompts with Category "Research Prompts" and uncategorized prompts are excluded
- Table header: "Team Prompt Library (showing X of Y total)"
- Table columns: Name, Category, Visibility, Times Used
- Results sorted by Times Used descending, then Name ascending as tiebreaker
- Filter line at bottom: "Filter: category=Email Templates"
- No error for prompts that have a blank Category field (displayed with blank column, not omitted)

**Acceptance Criteria Reference**: List by category

---

### TC-12

**Category**: /prompt:list — Keyword Search

**Test Name**: Keyword search matches prompts by name, tags, or content

**Preconditions**:
- Notion MCP connected
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database exists
- At least one prompt has "outreach" in its Name
- At least one different prompt has "outreach" in its Tags
- At least one different prompt has "outreach" in its Content but not in Name or Tags
- Several prompts exist with no reference to "outreach"

**Steps**:
1. Run: `/prompt:list --search=outreach`
2. Observe which prompts appear in results

**Expected Result**:
- Prompts matching "outreach" in Name, Tags, or Content are all returned
- Prompts with no reference to "outreach" are excluded
- Results sorted by Times Used descending
- Filter line at bottom: "Filter: search=outreach"
- Result count shown in header

**Acceptance Criteria Reference**: List by keyword search

---

### TC-13

**Category**: /prompt:list — Empty Library

**Test Name**: Listing when no database exists shows the empty-library message with onboarding hint

**Preconditions**:
- Notion MCP connected
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database does NOT exist in the workspace

**Steps**:
1. Run: `/prompt:list`
2. Observe the output

**Expected Result**:
- Plugin searches for "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") — not found
- Message displayed:
  "Your Team Prompt Library is empty — no prompts have been added yet.\n\nGet started with:\n  /prompt:add \"My First Prompt\" [prompt-text] --category=\"Email Templates\""
- Execution stops cleanly — no error, no stack trace
- No database is created by the list command (database must be pre-provisioned)

**Acceptance Criteria Reference**: Empty library message

---

### TC-14

**Category**: /prompt:list — --limit Flag

**Test Name**: --limit flag caps results at the specified number

**Preconditions**:
- Notion MCP connected
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database exists with at least 10 prompts

**Steps**:
1. Run: `/prompt:list --limit=3`
2. Observe the result count

**Expected Result**:
- Exactly 3 prompts returned regardless of total database size
- Header shows "showing 3 of Y total" where Y is the actual total count
- The 3 results are the top 3 by Times Used descending
- A fourth result is not shown even if it exists
- Filter line: "Filter: limit=3"

**Acceptance Criteria Reference**: --limit flag

---

### TC-15

**Category**: /prompt:list — No Results for Filters

**Test Name**: Filtering by a non-existent category shows helpful no-results message

**Preconditions**:
- Notion MCP connected
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database exists
- No prompts exist with Category "Nonexistent Category"

**Steps**:
1. Run: `/prompt:list "Nonexistent Category"`
2. Observe the output

**Expected Result**:
- No prompts returned
- Message displayed:
  "No prompts found matching your criteria.\n\nTry:\n  /prompt:list                  (show all prompts)\n  /prompt:list --search=email   (search by keyword)"
- Available categories listed from actual DB options (not hardcoded predefined list)
- No error or crash

**Acceptance Criteria Reference**: No-results message with alternative suggestions

---

### TC-16

**Category**: /prompt:list — Times Used Missing on Some Records

**Test Name**: Records with no Times Used value display an em dash, not an error

**Preconditions**:
- Notion MCP connected
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database exists
- At least one prompt has Times Used property set to null or missing

**Steps**:
1. Run: `/prompt:list`
2. Observe the Times Used column for the record with missing data

**Expected Result**:
- Record with null Times Used shows "—" in the Times Used column
- Record is not omitted from results
- Sort order places null-Times-Used records after all records with numeric values (treated as 0)
- No error displayed

**Acceptance Criteria Reference**: Graceful degradation for missing property values

---

## /prompt:get Tests

### TC-17

**Category**: /prompt:get — Basic Retrieve

**Test Name**: Retrieving a prompt by exact name returns content in a fenced code block

**Preconditions**:
- Notion MCP connected
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database exists
- A prompt named "Weekly Status Update" exists with content that contains no `{{variables}}`
- Its Times Used value is currently 5

**Steps**:
1. Run: `/prompt:get "Weekly Status Update"`
2. Observe the metadata block
3. Observe the prompt output block
4. Check the Notion record for updated Times Used

**Expected Result**:
- Metadata block displayed with Name, Category, Visibility, Author, Tags, Times Used, Last Used
- No AskUserQuestion for variable values (no variables detected)
- Prompt content displayed unchanged in a fenced code block under "## Ready-to-Use Prompt"
- Usage summary below the code block: "Variables filled: None"
- Times Used incremented to 6 in Notion
- Last Used set to today's date (YYYY-MM-DD)
- Both updates applied in a single Notion page update call

**Acceptance Criteria Reference**: Basic retrieve; usage counter increment (Times Used)

---

### TC-18

**Category**: /prompt:get — Variable Substitution via AskUserQuestion

**Test Name**: Prompts with variables trigger one-at-a-time interactive collection

**Preconditions**:
- Notion MCP connected
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database exists
- A prompt named "Client Intro Email" exists with content containing `{{client_name}}`, `{{company_name}}`, and `{{industry}}`
- Variables property on the Notion page: "client_name, company_name, industry"

**Steps**:
1. Run: `/prompt:get "Client Intro Email"`
2. Observe variable announcement message
3. Respond to AskUserQuestion for `{{client_name}}` with "Sarah Chen"
4. Respond to AskUserQuestion for `{{company_name}}` with "Acme Corp"
5. Respond to AskUserQuestion for `{{industry}}` with "fintech"
6. Observe the final output

**Expected Result**:
- "This prompt contains 3 variable(s) that need values: {{client_name}}, {{company_name}}, {{industry}}" displayed
- AskUserQuestion asked one variable at a time in order of first appearance in the content
- Each prompt follows format: "Enter value for {{variable_name}}:"
- Final prompt has all three placeholders replaced: "Sarah Chen", "Acme Corp", "fintech"
- No remaining `{{placeholder}}` text in the output
- Variable substitution is case-insensitive ({{Client_Name}} treated same as {{client_name}})
- Usage tracking: Times Used incremented, Last Used updated

**Acceptance Criteria Reference**: Variable substitution with AskUserQuestion

---

### TC-19

**Category**: /prompt:get — Variable Suffix Hints

**Test Name**: Variables with recognized suffixes receive contextual hints in the prompt

**Preconditions**:
- Notion MCP connected
- A prompt named "Report Date Filter" exists with content containing `{{report_date}}` and `{{attendees_list}}`

**Steps**:
1. Run: `/prompt:get "Report Date Filter"`
2. Observe the AskUserQuestion prompts for each variable

**Expected Result**:
- AskUserQuestion for `{{report_date}}` shows hint: "(e.g., 2026-03-05)"
- AskUserQuestion for `{{attendees_list}}` shows hint: "(comma-separated)"
- Hints appear in parentheses after the "Enter value for {{variable_name}}:" prompt
- No hint shown for variables without recognized suffixes

**Acceptance Criteria Reference**: Variable substitution with AskUserQuestion; suffix hint display

---

### TC-20

**Category**: /prompt:get — Prompt Not Found (Fuzzy Suggestions)

**Test Name**: Requesting a non-existent prompt by approximate name shows fuzzy matches

**Preconditions**:
- Notion MCP connected
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database exists
- Prompts exist named: "Client Intro Email", "Cold Outreach Opener", "Weekly Status Update"
- No prompt named "client intro" exists (without "Email")

**Steps**:
1. Run: `/prompt:get "client intro"`
2. Observe the output

**Expected Result**:
- Exact match not found (case-insensitive)
- Partial match search finds "Client Intro Email" (contains the word "client" and "intro")
- Fuzzy suggestion output displayed:
  "Prompt not found: \"client intro\"\n\nDid you mean one of these?\n\n1. Client Intro Email — Email Templates  (used N times)\n...\n\nRun /prompt:list to browse all prompts, or /prompt:get \"[exact name]\" to retry."
- Up to 5 suggestions shown, sorted by Times Used descending
- Execution stops — no usage tracking event, no Notion update

**Acceptance Criteria Reference**: Prompt not found (fuzzy suggestions)

---

### TC-21

**Category**: /prompt:get — Prompt Not Found (No Matches)

**Test Name**: Requesting a prompt with no partial matches shows a clear not-found message

**Preconditions**:
- Notion MCP connected
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database exists with several prompts
- No prompt contains the word "xyzquux" in its name

**Steps**:
1. Run: `/prompt:get "xyzquux analysis"`
2. Observe the output

**Expected Result**:
- Exact match not found
- Partial match search returns zero results
- Message displayed: "Prompt not found: \"xyzquux analysis\"\n\nNo similar prompts were found in your library. Check the name and try again.\n\nRun /prompt:list to browse all available prompts."
- No usage tracking update occurs
- No error or crash

**Acceptance Criteria Reference**: Prompt not found with no fuzzy suggestions

---

### TC-22

**Category**: /prompt:get — Usage Tracking Failure Does Not Block Output

**Test Name**: If the Notion usage update fails, the prompt output is still displayed

**Preconditions**:
- Notion MCP connected (for retrieval) but write permissions revoked or simulated to fail on update
- A prompt named "Status Update" exists in the library with no variables

**Steps**:
1. Configure Notion write to fail (or simulate a write failure)
2. Run: `/prompt:get "Status Update"`
3. Observe whether the prompt is shown and whether the error is surfaced

**Expected Result**:
- Prompt content retrieved and displayed successfully in the fenced code block
- Usage tracking update fails silently — no error message shown to the user
- "Ready-to-Use Prompt" output is the primary outcome and is not blocked
- No "Error: failed to update Times Used" or similar message in the output

**Acceptance Criteria Reference**: Usage tracking failure is silent; output is primary outcome

---

## /prompt:share Tests

### TC-23

**Category**: /prompt:share — Personal to Shared Toggle

**Test Name**: Sharing a Personal prompt updates Visibility to Shared

**Preconditions**:
- Notion MCP connected
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database exists
- A prompt named "Weekly Status Update" exists with Visibility = "Personal"

**Steps**:
1. Run: `/prompt:share "Weekly Status Update"`
2. Observe the confirmation output
3. Verify the Notion record's Visibility property

**Expected Result**:
- Prompt found via case-insensitive name match
- Visibility read as "Personal"
- Visibility updated to "Shared" in Notion
- Confirmation block displayed:
  "Prompt shared successfully.\n\n  Name: Weekly Status Update\n  Visibility: Personal → Shared\n\n  Your team can now find this prompt using /prompt:list or /prompt:get."
- Times Used and Last Used are not modified by this operation

**Acceptance Criteria Reference**: Personal to Shared toggle

---

### TC-24

**Category**: /prompt:share — Already Shared Message

**Test Name**: Sharing an already-Shared prompt shows an informational message and makes no changes

**Preconditions**:
- Notion MCP connected
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database exists
- A prompt named "Cold Outreach Opener" exists with Visibility = "Shared"

**Steps**:
1. Run: `/prompt:share "Cold Outreach Opener"`
2. Observe the output
3. Verify the Notion record is unchanged

**Expected Result**:
- Prompt found via name match
- Visibility read as "Shared"
- Message displayed: "The prompt 'Cold Outreach Opener' is already shared with your team. No changes made."
- Execution stops — no Notion update attempted
- No error

**Acceptance Criteria Reference**: Already shared message

---

### TC-25

**Category**: /prompt:share — Prompt Not Found

**Test Name**: Sharing a non-existent prompt shows fuzzy suggestions

**Preconditions**:
- Notion MCP connected
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database exists
- Prompts exist named "Cold Outreach Opener" and "Client Intro Email"
- No prompt named "cold outreach" exists

**Steps**:
1. Run: `/prompt:share "cold outreach"`
2. Observe the output

**Expected Result**:
- Exact match not found
- Partial matches found: "Cold Outreach Opener" contains words from the query
- Fuzzy suggestion displayed: "Could not find 'cold outreach'. Did you mean one of these? [numbered list, up to 3 matches]"
- If no partial matches at all: "No prompt named 'cold outreach' was found in the library."
- No Notion update attempted
- No crash

**Acceptance Criteria Reference**: Prompt not found on share

---

### TC-26

**Category**: /prompt:share — Notion Unavailable

**Test Name**: /prompt:share stops with a clear error when Notion MCP is not connected

**Preconditions**:
- Notion MCP disconnected or misconfigured

**Steps**:
1. Run: `/prompt:share "Weekly Status Update"`
2. Observe the output

**Expected Result**:
- Error message displayed: Notion MCP is required for this command and cannot proceed without it
- Execution stops immediately
- No partial operation attempted

**Acceptance Criteria Reference**: Graceful error message when Notion unavailable

---

## /prompt:optimize Tests

### TC-27

**Category**: /prompt:optimize — Score and Rewrite Workflow

**Test Name**: Optimizing a Fair-scoring prompt produces a scored report and a rewritten version

**Preconditions**:
- Notion MCP connected
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database exists
- A prompt named "Meeting Recap" exists with content: "Summarize the meeting and list some action items."

**Steps**:
1. Run: `/prompt:optimize "Meeting Recap"`
2. Observe the quality score and dimension breakdown
3. Observe the side-by-side comparison output
4. Respond "1" to AskUserQuestion (Keep Original)

**Expected Result**:
- Prompt retrieved from Notion (Times Used NOT incremented — optimize is not a retrieval for use)
- Quality scored across all five dimensions (expected 11–14/25 for this content)
- Anti-patterns detected: "Vague Action Verbs" and "Unbounded Scope" at minimum
- Full optimization report displayed:
  - Original prompt shown
  - Quality Score block with all five dimension scores
  - ANTI-PATTERNS DETECTED section
  - TOP ISSUES section with at least 2 concrete fixes
  - Improved Prompt shown with full rewrite
  - CHANGES MADE section explaining each change
  - VARIABLES PRESERVED: "None detected"
- AskUserQuestion with three options: Keep Original / Use Improved / Edit Further
- On "1" (Keep Original): "No changes made. The original prompt 'Meeting Recap' is unchanged in the library." displayed
- Notion record unchanged after Keep Original selection

**Acceptance Criteria Reference**: Score + rewrite workflow; accept/reject flow

---

### TC-28

**Category**: /prompt:optimize — Accept Improved Version

**Test Name**: Selecting "Use Improved" saves the rewritten content to Notion

**Preconditions**:
- Notion MCP connected
- A prompt named "Email Help" exists with poor content: "Help me write an email to a client."
- Current Variables property: empty

**Steps**:
1. Run: `/prompt:optimize "Email Help"`
2. Observe the optimization report (expected score 7–9/25)
3. Respond "2" to AskUserQuestion (Use Improved)
4. Verify the Notion record update

**Expected Result**:
- Improved prompt is generated (a specific, constrained email drafting prompt)
- On "2": Step 8 executes
- Notion page updated with:
  - Content: the improved prompt text
  - Variables: re-detected from improved content (may now contain `{{variables}}` added by the rewrite)
  - Name, Category, Visibility, Times Used, Author, Tags, Created At, Last Used: all unchanged
- Confirmation block displayed: Name, Category, Variables (updated), "Saved to: Team Prompt Library - Prompts (Notion)"
- Only two properties modified: Content and Variables

**Acceptance Criteria Reference**: Accept flow (Use Improved); only Content and Variables modified

---

### TC-29

**Category**: /prompt:optimize — Edit Further Path

**Test Name**: Selecting "Edit Further" saves the user's manually edited version

**Preconditions**:
- Notion MCP connected
- A prompt named "Competitor Brief" exists in the library

**Steps**:
1. Run: `/prompt:optimize "Competitor Brief"`
2. Observe the optimization report
3. Respond "3" to AskUserQuestion (Edit Further)
4. Paste custom edited content: "Analyze {{competitor_name}} across three dimensions: (1) pricing model, (2) key features vs. ours, (3) market positioning. Return a structured table. Focus only on publicly available information. Keep the output under 300 words."
5. Verify the save

**Expected Result**:
- On "3": "Paste your edited prompt text." displayed
- User-provided text accepted as final content
- Variable detection re-run on pasted text: "competitor_name" detected
- Notion page updated with:
  - Content: the user's pasted text
  - Variables: "competitor_name"
- Confirmation block displayed
- The plugin does not attempt to save the AI-generated improved version

**Acceptance Criteria Reference**: Edit Further flow; variable re-detection on user-edited content

---

### TC-30

**Category**: /prompt:optimize — Variable Preservation During Rewrite

**Test Name**: Rewriting a prompt with `{{variables}}` preserves all placeholders exactly

**Preconditions**:
- Notion MCP connected
- A prompt named "Client Intro Email" exists with content containing `{{client_name}}`, `{{company_name}}`, and `{{industry}}`
- Prompt content scores Fair or below to trigger optimization

**Steps**:
1. Run: `/prompt:optimize "Client Intro Email"`
2. Observe the improved prompt in the optimization report

**Expected Result**:
- All three original `{{variables}}` preserved in the improved prompt: `{{client_name}}`, `{{company_name}}`, `{{industry}}`
- VARIABLES PRESERVED section lists: "{{client_name}}, {{company_name}}, {{industry}}"
- No variable is renamed (e.g., `{{client_name}}` is not changed to `{{name}}`)
- No new variables added that the user did not intend
- If any `{{variables}}` had been removed or renamed, this is treated as a defect

**Acceptance Criteria Reference**: Variable preservation during rewrite

---

### TC-31

**Category**: /prompt:optimize — Excellent Score Confirmation

**Test Name**: Optimizing an already-excellent prompt prompts user confirmation before rewriting

**Preconditions**:
- Notion MCP connected
- A prompt named "Extraction Prompt" exists with a highly specific, well-structured content that scores 21+ / 25

**Steps**:
1. Run: `/prompt:optimize "Extraction Prompt"`
2. Observe the score output
3. Respond "No" to the confirmation question
4. Verify no rewrite is produced

**Expected Result**:
- Quality score displayed: "Quality Score: [total]/25 — Excellent"
- Message: "This prompt is already high quality. Optimization may offer only minor improvements."
- AskUserQuestion: "Would you like to proceed with a rewrite anyway? (Yes / No)"
- On "No": execution stops, no rewrite produced, no Notion update
- On "Yes" (separate test path): rewrite proceeds normally

**Acceptance Criteria Reference**: Excellent score stops workflow unless user confirms

---

### TC-32

**Category**: /prompt:optimize — No Anti-Patterns Detected

**Test Name**: Optimization report omits the ANTI-PATTERNS section when none are detected

**Preconditions**:
- Notion MCP connected
- A prompt exists that scores well across all dimensions but has no anti-patterns (e.g., a clear, structured, constrained prompt)

**Steps**:
1. Run: `/prompt:optimize "[prompt name]"`
2. Observe the optimization report layout

**Expected Result**:
- ANTI-PATTERNS DETECTED section is entirely absent from the output
- No empty "ANTI-PATTERNS DETECTED:\n(none)" line is shown
- Quality Score, Dimension Scores, TOP ISSUES (if any), and Improved Prompt sections still present normally

**Acceptance Criteria Reference**: Omit ANTI-PATTERNS section when none detected

---

## Cross-Cutting Tests

### TC-33

**Category**: Cross-Cutting — Database Discovery Consistent Across Commands

**Test Name**: /prompt:list and /prompt:get do not create the database if it doesn't exist

**Preconditions**:
- Notion MCP connected
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database does NOT exist

**Steps**:
1. Run: `/prompt:list`
2. Observe that the database is NOT created
3. Run: `/prompt:get "Anything"`
4. Observe that the database is NOT created

**Expected Result**:
- `/prompt:list` shows the empty library message and stops — no database created
- `/prompt:get` shows the empty library message and stops — no database created
- Only `/prompt:add` triggers database creation (on first write)
- Notion workspace has zero "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") databases after both commands

**Acceptance Criteria Reference**: Database discovery (no auto-creation)

---

### TC-34

**Category**: Cross-Cutting — Idempotent Upsert by Name

**Test Name**: Re-running /prompt:add with the same name updates the existing record rather than creating a duplicate

**Preconditions**:
- Notion MCP connected
- "[FOS] Prompts" (or fallback "Founder OS HQ - Prompts" / "Team Prompt Library - Prompts") database exists
- A prompt named "Code Review Checklist" exists with specific content

**Steps**:
1. Note the existing "Code Review Checklist" page ID in Notion
2. Run: `/prompt:add "Code Review Checklist" "New improved content for {{repo_name}} review." --category="Code Assistance"`
3. Respond "1" (overwrite) to the duplicate name prompt
4. Verify the Notion database

**Expected Result**:
- Exactly one record named "Code Review Checklist" in the database after the operation
- The original page is updated (not a new page created)
- Content, Category, and Variables are overwritten with the new values
- Created At date is unchanged (not reset to today)
- Times Used is unchanged (not reset to 0)

**Acceptance Criteria Reference**: Idempotent upsert by Name; no duplicate records

---

### TC-35

**Category**: Cross-Cutting — Skill Loading Verification (/prompt:add)

**Test Name**: Both skills are loaded before any operation when running /prompt:add

**Preconditions**:
- Plugin installed correctly with both SKILL.md files present at expected paths

**Steps**:
1. Run: `/prompt:add "Skill Test Prompt" "Evaluate {{company}} competitive position. List top 3 strengths and top 3 weaknesses. Format as two bullet lists. Focus on publicly available data only." --category="Analysis Prompts"`
2. Observe that both quality scoring (prompt-optimization) and DB operations (prompt-management) function correctly in the same command execution

**Expected Result**:
- Quality scoring runs correctly (prompt-optimization skill active)
- Variable detection runs correctly (prompt-management skill active)
- DB schema lookup and page creation work correctly (prompt-management skill active)
- No "skill not loaded" or "function not found" errors
- Both skills loaded from:
  - `${CLAUDE_PLUGIN_ROOT}/skills/prompt-management/SKILL.md`
  - `${CLAUDE_PLUGIN_ROOT}/skills/prompt-optimization/SKILL.md`

**Acceptance Criteria Reference**: Skill loading verification; both skills used in the same command

---

### TC-36

**Category**: Cross-Cutting — Skill Loading Verification (/prompt:optimize)

**Test Name**: Both skills are loaded before any operation when running /prompt:optimize

**Preconditions**:
- Plugin installed correctly
- A prompt named "Test Optimization Target" exists in the library

**Steps**:
1. Run: `/prompt:optimize "Test Optimization Target"`
2. Observe quality scoring output and DB retrieval

**Expected Result**:
- Prompt retrieved from Notion using prompt-management skill DB discovery logic
- Quality scoring executed using prompt-optimization skill scoring system
- Anti-pattern detection executed using prompt-optimization skill rules
- Rewrite produced using prompt-optimization skill strategies
- No errors attributed to missing skill content

**Acceptance Criteria Reference**: Skill loading verification; both skills used in /prompt:optimize

---

### TC-37

**Category**: Cross-Cutting — Graceful Error When Notion Unavailable (All Commands)

**Test Name**: Every command stops cleanly with a consistent error message when Notion MCP is not connected

**Preconditions**:
- Notion MCP disconnected

**Steps**:
1. Run `/prompt:add "Test" "Some test content here for clarity." --category="Email Templates"` — observe error
2. Run `/prompt:list` — observe error
3. Run `/prompt:get "Anything"` — observe error
4. Run `/prompt:share "Anything"` — observe error
5. Run `/prompt:optimize "Anything"` — observe error

**Expected Result**:
- All five commands produce a clear error message referencing Notion MCP unavailability
- `/prompt:add` and `/prompt:optimize` show: "Error: Notion MCP is required for [command].\nSee ${CLAUDE_PLUGIN_ROOT}/INSTALL.md for setup instructions."
- `/prompt:list`, `/prompt:get`, and `/prompt:share` show their respective Notion-required error messages
- All commands stop at the Notion availability check step — no subsequent logic executes
- No partial operations, no crashes, no stack traces in any case

**Acceptance Criteria Reference**: Graceful error messages when Notion unavailable (all five commands)

---

## Coverage Matrix

| Feature | Test Case(s) |
|---------|--------------|
| `/prompt:add` — basic add, all args provided | TC-01 |
| `/prompt:add` — quality check, poor score (6–10) | TC-02 |
| `/prompt:add` — quality check, fair score (11–15), edit path | TC-03 |
| `/prompt:add` — quality check, unusable score (5), blocks save | TC-04 |
| `/prompt:add` — auto-detect `{{variables}}` | TC-05 |
| `/prompt:add` — `--variables` override flag | TC-06 |
| `/prompt:add` — category via AskUserQuestion | TC-07 |
| `/prompt:add` — database discovery (HQ + fallback) | TC-08 |
| `/prompt:add` — duplicate name conflict resolution | TC-09 |
| `/prompt:add` — Notion unavailable error | TC-10 |
| `/prompt:list` — category filter | TC-11 |
| `/prompt:list` — keyword search (--search) | TC-12 |
| `/prompt:list` — empty library message | TC-13 |
| `/prompt:list` — --limit flag | TC-14 |
| `/prompt:list` — no results for filter | TC-15 |
| `/prompt:list` — Times Used missing on record | TC-16 |
| `/prompt:get` — basic retrieve, no variables | TC-17 |
| `/prompt:get` — variable substitution via AskUserQuestion | TC-18 |
| `/prompt:get` — variable suffix hints (_date, _list) | TC-19 |
| `/prompt:get` — prompt not found, fuzzy suggestions | TC-20 |
| `/prompt:get` — prompt not found, no matches | TC-21 |
| `/prompt:get` — usage tracking failure is silent | TC-22 |
| `/prompt:share` — Personal to Shared toggle | TC-23 |
| `/prompt:share` — already Shared message | TC-24 |
| `/prompt:share` — prompt not found | TC-25 |
| `/prompt:share` — Notion unavailable error | TC-26 |
| `/prompt:optimize` — score + rewrite workflow, Keep Original | TC-27 |
| `/prompt:optimize` — Use Improved saves to Notion | TC-28 |
| `/prompt:optimize` — Edit Further saves user content | TC-29 |
| `/prompt:optimize` — variable preservation during rewrite | TC-30 |
| `/prompt:optimize` — Excellent score asks for confirmation | TC-31 |
| `/prompt:optimize` — no anti-patterns section omitted | TC-32 |
| Database discovery (HQ + fallback, no auto-creation) | TC-08, TC-33 |
| Idempotent upsert by Name | TC-09, TC-34 |
| Skill loading — prompt-management + prompt-optimization | TC-35, TC-36 |
| Graceful error, Notion unavailable (all commands) | TC-10, TC-26, TC-37 |
| Quality scoring tiers (Poor/Fair/Unusable/Excellent) | TC-02, TC-03, TC-04, TC-31 |
| Anti-pattern detection | TC-02, TC-27 |
| Variable detection regex | TC-05, TC-06, TC-18 |
| Variable preservation in rewrite | TC-30 |
| Usage tracking (Times Used + Last Used) | TC-17, TC-18, TC-22 |
| Visibility model (Personal default, Shared toggle) | TC-01, TC-23, TC-24 |
| Fuzzy name matching | TC-20, TC-25 |
| Notion DB schema (10 properties) | TC-08 |

## Acceptance Criteria Mapping

| Criterion | Test Case(s) |
|-----------|--------------|
| `/prompt:add` saves a prompt with name, content, category, variables, and Visibility=Personal | TC-01, TC-05, TC-07 |
| Quality check runs on every add; Poor and Unusable scores trigger user confirmation | TC-02, TC-03, TC-04 |
| `{{variables}}` auto-detected from content and stored as comma-separated string | TC-05, TC-06 |
| Category confirmed via AskUserQuestion when not provided | TC-07 |
| Notion DB created on first add with 10-property schema | TC-08 |
| Idempotent upsert: duplicate name asks user before overwriting | TC-09, TC-34 |
| Notion unavailable stops all commands with a clear error | TC-10, TC-26, TC-37 |
| `/prompt:list` filters by category, keyword, and limit | TC-11, TC-12, TC-14 |
| Empty library shows onboarding message; no DB created by list | TC-13, TC-33 |
| `/prompt:get` retrieves content and increments Times Used + Last Used | TC-17, TC-18 |
| Variable values collected one-at-a-time via AskUserQuestion | TC-18, TC-19 |
| Prompt not found shows fuzzy suggestions (up to 5) | TC-20, TC-21, TC-25 |
| Usage tracking failure is silent; prompt output is primary outcome | TC-22 |
| `/prompt:share` changes Visibility from Personal to Shared | TC-23 |
| Already-Shared prompt shows informational message; no Notion update | TC-24 |
| `/prompt:optimize` scores prompt, produces rewrite, presents three options | TC-27, TC-28, TC-29 |
| All `{{variables}}` preserved verbatim during rewrite | TC-30 |
| Excellent score (21–25) requires user confirmation before rewriting | TC-31 |
| ANTI-PATTERNS section omitted when none detected | TC-32 |
| Both skills loaded and applied correctly in each command | TC-35, TC-36 |
