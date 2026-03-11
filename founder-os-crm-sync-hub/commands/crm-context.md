---
description: Load CRM context for a client - company profile, contacts, recent activities, and deals
argument-hint: "[client] [--days=30] [--full]"
allowed-tools: ["Read"]
---

# CRM Context

Load a lightweight, CRM-focused view of a client's data. This is a READ-ONLY command — no writes to CRM. Complements Plugin #20's /client:load (which does full multi-source dossier) by providing a fast CRM-only view.

## Load Skills

Read these skills for lookup logic:
- `${CLAUDE_PLUGIN_ROOT}/skills/crm-sync/SKILL.md` for the context command workflow
- `${CLAUDE_PLUGIN_ROOT}/skills/client-matching/SKILL.md` for resolving client name to CRM records

## Parse Arguments

Extract from `$ARGUMENTS`:
- First positional arg: `client` (required) — client or company name to look up
- `--days=N` (optional) — activity lookback period. Default: 30
- `--full` (optional) — show all activity details instead of summaries

If no client name provided, ask the user: "Which client would you like to look up?"

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Lookup Process

1. **Match client**: Use client-matching skill to find the client in Companies DB.
   - Search by company name (exact then fuzzy)
   - If multiple matches: present top matches and ask user to select
   - If no match: report "No client found matching '[name]' in CRM" and suggest checking the name

2. **Fetch company profile**: From Companies DB, pull: Name, Industry, Size, Status, Website, and any custom properties.

3. **Fetch contacts**: Follow the Contacts relation from the Companies record. For each contact: Name, Email, Role, Type (Decision Maker/Champion/etc.), Last Contact date.

4. **Fetch recent activities**: Search Communications DB for records linked to this company within the --days window (default 30 days). Sort by Date descending.
   - Default view: show Type, Date, Title, Sentiment for each activity
   - With --full flag: also show full Summary text for each activity

5. **Fetch open deals**: Search Deals DB for records linked to this company where Stage is NOT "Closed Lost" or "Closed Won". Show: Deal Name, Value, Stage, Close Date, Probability.

6. **Quick health indicators**: Calculate from the fetched data:
   - Days since last contact (from most recent Communication)
   - Total activities in period
   - Active deals count and total pipeline value
   - Dominant sentiment across recent activities

## Notion Integration

- All 4 CRM Pro databases are accessed via Notion MCP
- Use dynamic discovery: search by title "[FOS] Companies"/"[FOS] Contacts"/"[FOS] Communications"/"[FOS] Deals" first, then "Founder OS HQ - Companies"/"Founder OS HQ - Contacts"/"Founder OS HQ - Communications"/"Founder OS HQ - Deals", then fall back to "Companies"/"Contacts"/"Communications"/"Deals"
- Never hardcode database IDs

## Graceful Degradation

- If Notion MCP unavailable: error — Notion is required for this command. Reference `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`.
- If Communications DB empty or doesn't exist: show company profile and contacts, note "No synced activities yet. Use `/crm:sync-email` or `/crm:sync-meeting` to populate."
- If Deals DB empty: show "No active deals" section

## Output Format

```
## CRM Context: [Company Name]

**Industry**: [industry] | **Size**: [size] | **Status**: [status]
**Website**: [url]

---

### Key Contacts
| Name | Role | Type | Email | Last Contact |
|------|------|------|-------|-------------|
| [name] | [role] | [type] | [email] | [date] |

---

### Recent Activity ([N] days)
| Date | Type | Summary | Sentiment |
|------|------|---------|-----------|
| [date] | [type] | [title or full summary if --full] | [sentiment] |

**Total activities**: [count] | **Last contact**: [N] days ago

---

### Open Deals
| Deal | Value | Stage | Close Date | Probability |
|------|-------|-------|------------|-------------|
| [name] | $[value] | [stage] | [date] | [pct]% |

**Pipeline value**: $[total]

---

### Health Indicators
- **Contact recency**: [N] days since last activity — [Good/Warning/Alert]
- **Engagement**: [count] activities in last [days] days — [Active/Moderate/Low]
- **Pipeline**: [count] open deals worth $[value]
- **Sentiment trend**: [Mostly positive/Mixed/Concerning]
```

Health indicator thresholds:
- Contact recency: Good (<=7 days), Warning (8-21 days), Alert (>21 days)
- Engagement: Active (>5 activities), Moderate (2-5), Low (0-1)

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/crm:context Acme Corp              # Quick CRM view for Acme Corp
/crm:context "Tech Solutions Inc"   # Name with spaces
/crm:context Acme --days=60         # Look back 60 days
/crm:context Acme --full            # Show full activity summaries
/crm:context Acme --days=90 --full  # Extended view with full details
```
