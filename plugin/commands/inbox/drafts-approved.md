---
description: Create Gmail drafts from approved Notion entries
allowed-tools: Read, Glob, Grep, Bash, Task
---

# Drafts Approved

Create Gmail drafts from entries approved in the Notion **"[FOS] Content"** database (filtered by `Type = "Email Draft"`). Falls back to "Founder OS HQ - Content", then to the legacy "Inbox Zero - Drafts" database. This command bridges the review step between AI-generated drafts and actual Gmail draft creation.

## Prerequisites Check

1. Verify gws CLI is available by running `which gws`. If not found, halt and inform the user to install gws CLI.
2. Verify Notion MCP is configured (required).
3. If Notion is not available, halt and inform the user to enable Notion connector in Claude Desktop Settings.

## Gmail Access

This command uses the `gws` CLI to create Gmail drafts:
```bash
# Build the raw RFC 2822 message and create a draft
raw=$(printf "To: RECIPIENT\r\nSubject: SUBJECT\r\nContent-Type: text/plain\r\n\r\nBODY" | base64 -w 0)
gws gmail users drafts create --params '{"userId":"me"}' --json "{\"message\":{\"raw\":\"$raw\"}}"
```

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Workflow

1. Search Notion for a database named "[FOS] Content". If not found, try "Founder OS HQ - Content". If not found, fall back to "Inbox Zero - Drafts" (legacy name). If none exists, halt with an error.
2. Query the resolved database for entries where `Status = "Approved"`. When using the HQ Content database, also filter by `Type = "Email Draft"`.
3. For each approved entry, extract:
   - `to`: recipient email address
   - `subject`: email subject (should start with "Re: " for replies)
   - `body`: the draft response text
   - `source_email_id`: original Gmail message ID (for threading)
4. For each approved draft:
   a. Use gws CLI to create a Gmail draft: build an RFC 2822 message with To, Subject, and Body fields, base64-encode it, and call `gws gmail users drafts create`.
   b. On success: update the Notion entry status from "Approved" to "Sent to Gmail".
   c. On failure: update the Notion entry status to "Error" and add an error note.
5. Present a summary report:
   - Total approved entries found
   - Successfully created as Gmail drafts
   - Failed (with error details)
   - Reminder: "Drafts are in your Gmail Drafts folder — review and send manually."

## Output Format

```
## Drafts Approved → Gmail

**Found**: 5 approved drafts in Notion

### Results
| # | To | Subject | Status |
|---|-----|---------|--------|
| 1 | alice@example.com | Re: Q4 Budget Review | Created in Gmail |
| 2 | bob@corp.com | Re: Meeting Follow-up | Created in Gmail |
| 3 | carol@client.com | Re: Proposal Feedback | Error: thread not found |

**Successfully created**: 4/5 drafts
**Action needed**: Review and send drafts from your Gmail Drafts folder.
```

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Error Handling

- **No approved drafts found**: Report "No approved drafts found in Notion. Run /founder-os:inbox:triage --team first, then approve drafts in Notion."
- **Notion database not found**: Report that none of "[FOS] Content", "Founder OS HQ - Content", or "Inbox Zero - Drafts" databases were found. Suggest deploying the HQ template or running the pipeline first.
- **Gmail draft creation fails**: Log the error for that specific draft, continue processing remaining drafts, report failures at the end.
- **Missing required fields**: Skip the entry, report it as incomplete with details on which field is missing.

## Usage Examples

```
/founder-os:inbox:drafts_approved    # Process all approved drafts from Notion to Gmail
```
