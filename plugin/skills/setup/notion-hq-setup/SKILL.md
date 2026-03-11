# Notion HQ Setup Skill

Domain knowledge for creating and managing the Founder OS HQ Notion workspace.

## Database Architecture

The Founder OS HQ consists of 22 databases organized into 5 sections. CRM Companies is the central hub — all client-facing databases relate back to it.

### Sections and Databases

| Section | Databases | Template Files |
|---------|-----------|----------------|
| CRM | Companies, Contacts, Deals, Communications | `hq-companies.json`, `hq-contacts.json`, `hq-deals.json`, `crm-sync-hub-communications.json` |
| Operations | Tasks, Meetings, Finance | `hq-tasks.json`, `hq-meetings.json`, `hq-finance.json` |
| Intelligence | Briefings, Knowledge Base, Research, Reports | `hq-briefings.json`, `hq-knowledge-base.json`, `hq-research.json`, `hq-reports.json` |
| Content & Deliverables | Content, Deliverables, Prompts | `hq-content.json`, `hq-deliverables.json`, `team-prompt-library-prompts.json` |
| Growth & Meta | Goals, Milestones, Learnings, Weekly Insights, Workflows, Activity Log, Memory, Intelligence | `goal-progress-tracker-goals.json`, `goal-progress-tracker-milestones.json`, `learning-log-tracker-learnings.json`, `learning-log-tracker-weekly-insights.json`, `hq-workflows.json`, `google-drive-brain-activity.json`, `hq-memory.json`, `hq-intelligence.json` |

### Database Naming Convention

All databases created by this skill use the `[FOS]` prefix:
- `[FOS] Companies`
- `[FOS] Tasks`
- `[FOS] Briefings`
- etc.

This prefix is used for discovery by all 32 plugins. The 3-step discovery pattern in plugins searches for:
1. `[FOS] <Name>` (primary — created by this skill)
2. `Founder OS HQ - <Name>` (legacy consolidated name)
3. Plugin-specific name (e.g., `Inbox Zero - Action Items`)

### Creation Order

Databases must be created in dependency order because relations reference other databases:

1. **Companies** (hub — no dependencies)
2. **Contacts** (relates to Companies)
3. **Deals** (relates to Companies, Contacts)
4. **Communications** (relates to Companies, Contacts)
5. **Tasks** (relates to Companies, Contacts)
6. **Meetings** (relates to Companies, Contacts)
7. **Finance** (relates to Companies)
8. **Briefings** (no required relations)
9. **Knowledge Base** (no required relations)
10. **Research** (relates to Companies)
11. **Reports** (relates to Companies)
12. **Content** (relates to Companies)
13. **Deliverables** (relates to Companies, Deals)
14. **Prompts** (no required relations)
15. **Goals** (no required relations)
16. **Milestones** (relates to Goals)
17. **Learnings** (no required relations)
18. **Weekly Insights** (no required relations)
19. **Workflows** (no required relations)
20. **Activity Log** (no required relations)
21. **Memory** (no required relations)
22. **Intelligence** (no required relations)

### Consolidated Database Type Values

Several databases merge data from multiple plugins. The `Type` column distinguishes records:

| Database | Type Values |
|----------|-------------|
| Tasks | Email Task, Action Item, Follow-Up |
| Meetings | (no type — shared Event ID distinguishes Prep vs Analysis) |
| Finance | Invoice, Expense |
| Briefings | Daily Briefing, Weekly Review, Slack Digest, Morning Sync |
| Knowledge Base | Source, Query |
| Research | Newsletter Research, Competitive Analysis |
| Reports | Business Report, Expense Report, ROI Report |
| Content | Email Draft, Newsletter, LinkedIn Post |
| Deliverables | Proposal, Contract, SOW |
| Workflows | Execution, SOP |

### Template File Format

Each template JSON in `_infrastructure/notion-db-templates/` follows this structure:

```json
{
  "name": "Display Name",
  "description": "Purpose of this database",
  "properties": {
    "Name": { "title": {} },
    "Status": {
      "select": {
        "options": [
          { "name": "To Do", "color": "gray" },
          { "name": "In Progress", "color": "blue" },
          { "name": "Done", "color": "green" }
        ]
      }
    },
    "Company": {
      "relation": {
        "database_id": "{{companies_db_id}}",
        "single_property": {}
      }
    }
  }
}
```

The `{{companies_db_id}}` placeholder is replaced at runtime with the actual database ID after creation.

### Idempotency Rules

1. Before creating any database, search for `[FOS] <display_name>`.
2. If found, log "Already exists" and record its ID for relation wiring.
3. If not found, create it and record the new ID.
4. After all databases exist, wire relations using the collected IDs.
5. If a relation already exists on a database, skip it.

### Error Handling

- If a database creation fails, log the error and continue with the next database.
- At the end, report all failures so the user can re-run (idempotent recovery).
- Notion rate limit: if receiving 429 responses, wait 1 second and retry up to 3 times.

### Manifest Reference

The source of truth for database names, template filenames, and creation order is:
`_infrastructure/notion-db-templates/founder-os-hq-manifest.json`

Always read this file at runtime rather than hardcoding the database list.
