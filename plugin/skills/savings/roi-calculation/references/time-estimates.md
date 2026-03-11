# Time Estimate Reference

Detailed breakdown of all 24 plugin task categories used by the ROI Calculation skill. Each estimate represents the time differential between manual execution and AI-assisted execution via a Founder OS plugin.

---

## Category Estimates Table

| Category Key | Plugin | Manual Min | AI Min | Savings/Task | Unit | ROI Multiplier |
|-------------|--------|-----------|--------|-------------|------|---------------|
| `email_triage` | P01 Inbox Zero Commander | 120 | 15 | 105 min | per batch | 8.0x |
| `meeting_prep` | P03 Meeting Prep Autopilot | 30 | 5 | 25 min | per meeting | 6.0x |
| `action_extraction` | P04 Action Item Extractor | 20 | 3 | 17 min | per source | 6.7x |
| `weekly_review` | P05 Weekly Review Compiler | 60 | 10 | 50 min | per review | 6.0x |
| `follow_up_tracking` | P06 Smart Follow-Up Tracker | 15 | 2 | 13 min | per follow-up | 7.5x |
| `meeting_analysis` | P07 Meeting Intelligence Hub | 45 | 8 | 37 min | per meeting | 5.6x |
| `newsletter_drafting` | P08 Newsletter Draft Engine | 180 | 30 | 150 min | per newsletter | 6.0x |
| `report_generation` | P09 Report Generator Factory | 240 | 30 | 210 min | per report | 8.0x |
| `client_health_check` | P10 Client Health Dashboard | 30 | 5 | 25 min | per client | 6.0x |
| `invoice_processing` | P11 Invoice Processor | 15 | 2 | 13 min | per invoice | 7.5x |
| `proposal_writing` | P12 Proposal Automator | 180 | 25 | 155 min | per proposal | 7.2x |
| `contract_analysis` | P13 Contract Analyzer | 60 | 10 | 50 min | per contract | 6.0x |
| `sow_generation` | P14 SOW Generator | 240 | 35 | 205 min | per SOW | 6.9x |
| `competitive_research` | P15 Competitive Intel Compiler | 180 | 20 | 160 min | per competitor | 9.0x |
| `expense_reporting` | P16 Expense Report Builder | 90 | 10 | 80 min | per report | 9.0x |
| `drive_search` | P18 Google Drive Brain | 15 | 2 | 13 min | per search | 7.5x |
| `slack_digest` | P19 Slack Digest Engine | 30 | 5 | 25 min | per digest | 6.0x |
| `client_context` | P20 Client Context Loader | 45 | 8 | 37 min | per dossier | 5.6x |
| `crm_sync` | P21 CRM Sync Hub | 10 | 1 | 9 min | per activity | 10.0x |
| `morning_sync` | P22 Multi-Tool Morning Sync | 30 | 5 | 25 min | per briefing | 6.0x |
| `kb_query` | P23 Knowledge Base Q&A | 20 | 3 | 17 min | per query | 6.7x |
| `linkedin_post` | P24 LinkedIn Post Generator | 45 | 8 | 37 min | per post | 5.6x |
| `prompt_management` | P26 Team Prompt Library | 10 | 2 | 8 min | per prompt use | 5.0x |
| `workflow_documentation` | P28 Workflow Documenter | 120 | 15 | 105 min | per SOP | 8.0x |

---

## Methodology

### Manual Time Estimates

Manual times represent the typical duration for an SMB founder performing the task without AI assistance. Assumptions:

- **Single-person operation** — no dedicated assistant, operations manager, or admin support
- **Familiar with tools** — not a first-time user, but not a power user either
- **Includes context switching** — time to open applications, locate files, recall prior context
- **Does not include deep expertise** — e.g., contract analysis assumes the founder reads the contract themselves, not that they have legal training

### AI Time Estimates

AI times represent the end-to-end duration when using the corresponding Founder OS plugin, including:

- **Command invocation** — time to type the slash command and any flags
- **Plugin execution** — wait time while the plugin processes
- **Human review** — time for the founder to read, approve, or edit the output
- **Corrections** — a small buffer for occasional re-runs or adjustments

AI times do not include initial plugin setup or MCP server configuration (one-time costs).

### Batch vs Per-Item Categories

Some categories measure batch operations while others measure per-item work:

| Measurement Type | Categories | Explanation |
|-----------------|------------|-------------|
| **Batch** | `email_triage` | Manual: 120 min to triage an entire inbox. AI: 15 min for the full batch. One run covers many emails. |
| **Per-item** | `invoice_processing`, `follow_up_tracking`, `crm_sync`, `drive_search` | Manual and AI times apply to a single item. Multiply by count for period totals. |
| **Per-session** | `meeting_prep`, `meeting_analysis`, `weekly_review`, `morning_sync`, `slack_digest` | One session per meeting, review, or briefing. Each session is an independent unit. |
| **Per-document** | `report_generation`, `proposal_writing`, `sow_generation`, `contract_analysis`, `newsletter_drafting`, `expense_reporting`, `workflow_documentation`, `linkedin_post` | One document produced per run. |
| **Per-query** | `kb_query`, `action_extraction`, `client_health_check`, `client_context`, `competitive_research`, `prompt_management` | One lookup or analysis per invocation. |

The `unit` field in task-estimates.json encodes the measurement type for display purposes (e.g., "per batch", "per invoice", "per meeting").

---

## ROI Multiplier Interpretation

The ROI multiplier represents how many times faster the AI-assisted workflow is compared to the manual workflow:

| ROI Range | Interpretation |
|-----------|---------------|
| 5.0x - 6.0x | Moderate acceleration — tasks that still require significant human review |
| 6.0x - 8.0x | Strong acceleration — AI handles most of the work, human reviews output |
| 8.0x - 10.0x | High acceleration — AI replaces nearly all manual effort |

The highest-ROI categories (`crm_sync` at 10.0x, `competitive_research` and `expense_reporting` at 9.0x) involve highly repetitive data entry or research tasks where AI excels. The lowest-ROI categories (`prompt_management` at 5.0x, `client_context` and `linkedin_post` at 5.6x) involve tasks requiring more creative judgment or nuanced human input.

---

## Customization

Override any estimate via the user config file at `${CLAUDE_PLUGIN_ROOT}/config/user-config.json`.

### Override Format

```json
{
  "overrides": {
    "email_triage": { "manual_minutes": 90, "ai_minutes": 10 },
    "report_generation": { "manual_minutes": 300 }
  }
}
```

- Specify `manual_minutes`, `ai_minutes`, or both per category.
- Unspecified fields retain the default value from task-estimates.json.
- Overrides apply before any calculations.

### When to Override

- The founder's manual workflow is significantly faster or slower than the default estimate (e.g., they have a streamlined email process that takes 60 min instead of 120 min)
- The AI review step takes longer due to domain complexity (e.g., contract analysis in a regulated industry requires 20 min review instead of 10 min)
- A plugin is used in a non-standard way that changes the time profile

### Validation Rules

Every resolved category must satisfy:

1. `manual_minutes > 0` — manual time must be positive
2. `ai_minutes > 0` — AI time must be positive
3. `manual_minutes > ai_minutes` — AI must be faster than manual (otherwise no savings to report)

Categories that fail validation after applying overrides are skipped with a warning message. Fix the override values to restore the category to calculations.
