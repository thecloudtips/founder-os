# Founder OS HQ — Migration Guide

This guide is for existing Founder OS users who already have plugin-specific Notion databases (e.g., "Inbox Zero - Action Items", "Invoice Processor - Invoices") and want to transition to the consolidated HQ workspace.

---

## Overview

Previously, each Founder OS plugin created its own Notion database on first use. This worked well for individual plugins but resulted in a fragmented workspace — up to 30+ separate databases with no cross-plugin relations.

The Founder OS HQ workspace consolidates these into 18 shared databases. Updated plugins search for `Founder OS HQ - [Name]` databases first, then fall back to the old plugin-specific names if no HQ database is found.

**Key points:**

- Installing the HQ template does **not** delete or modify your existing databases
- Plugins continue to work with old databases if HQ databases are not present
- Migration of historical data is **optional** — new data flows to HQ databases automatically once installed
- You can run old and new databases side-by-side indefinitely

---

## Step 1: Install the HQ Template

Follow the [Installation Guide](INSTALL.md) to duplicate the HQ template into your workspace. This creates the full HQ structure alongside your existing plugin databases.

After installation, your workspace will contain both:

```
Your Workspace
  Founder OS HQ/              <-- NEW consolidated databases
    Founder OS HQ - Tasks
    Founder OS HQ - Meetings
    Founder OS HQ - Finance
    ...
  Inbox Zero - Action Items    <-- OLD plugin-specific databases
  Inbox Zero - Drafts
  Invoice Processor - Invoices
  Daily Briefing Generator - Briefings
  ...
```

No data is lost. Both sets of databases coexist.

---

## Step 2: Automatic Detection

Once the HQ databases are in place and shared with your Notion integration, updated plugins will automatically prefer them. The discovery order is:

1. Search for `Founder OS HQ - [consolidated name]`
2. If not found, fall back to the old `[Plugin Name] - [DB Name]`

**No manual configuration is required for new data.** The next time you run any plugin command, new records will be written to the HQ databases instead of the old plugin-specific ones.

### Database Mapping

The following table shows which old plugin databases map to which HQ database:

| HQ Database | Replaces (old plugin databases) | Type Field Value |
|-------------|--------------------------------|------------------|
| **Tasks** | Inbox Zero - Action Items, Action Item Extractor - Tasks, Follow-Up Tracker - Follow-Ups | inbox-action, extracted-action, follow-up |
| **Meetings** | Meeting Prep Autopilot - Prep Notes, Meeting Intelligence Hub - Analyses | meeting-prep, meeting-intel |
| **Finance** | Invoice Processor - Invoices, Expense Report Builder - Reports, Proposal Automator - Proposals | invoice, expense-report, proposal |
| **Briefings** | Daily Briefing Generator - Briefings, Morning Sync - Briefings, Weekly Review Compiler - Reviews | daily-briefing, morning-sync, weekly-review |
| **Knowledge Base** | Knowledge Base Q&A - Sources, Knowledge Base Q&A - Queries | kb-source, kb-query |
| **Research** | Competitive Intel Compiler - Research, Newsletter Engine - Research | competitive-intel, newsletter-research |
| **Reports** | Report Generator - Reports, Client Health Dashboard - Health Scores, Time Savings Calculator - Reports | report, health-score, time-savings |
| **Content** | LinkedIn Post Generator - Posts, Slack Digest Engine - Digests, Newsletter drafts | linkedin-post, slack-digest, newsletter |
| **Deliverables** | Contract Analyzer - Analyses, SOW outputs, Workflow Documenter - SOPs | contract-analysis, sow, sop |
| **Prompts** | Team Prompt Library - Prompts | prompt |
| **Goals** | Goal Progress Tracker - Goals | goal |
| **Milestones** | Goal Progress Tracker - Milestones | milestone |
| **Learnings** | Learning Log Tracker - Learnings | learning |
| **Weekly Insights** | Learning Log Tracker - Weekly Insights | weekly-insight |
| **Workflows** | Workflow Automator - Executions | workflow-execution |
| **Activity Log** | Google Drive Brain - Activity | drive-activity |

CRM databases (Companies, Contacts, Deals, Communications) retain the same structure as the existing CRM Pro template. If you were already using CRM Pro databases, the HQ versions are identical in schema.

---

## Step 3: Optional — Migrate Historical Data

If you want to consolidate old records into the HQ databases, follow this process for each database you want to migrate. This is entirely optional — plugins work correctly whether old data is migrated or not.

### Migration Process

For each database listed in the mapping table above:

1. **Export from old database**
   - Open the old plugin-specific database in Notion
   - Use Notion's export feature (CSV) or manually review records
   - Note the total record count for verification

2. **Import into HQ database**
   - Create new pages in the corresponding HQ database
   - Set the **Type** property to the correct value from the mapping table (e.g., `invoice` for records from "Invoice Processor - Invoices")
   - Map property values to the HQ schema — most properties carry over directly, but some may have been renamed or consolidated

3. **Verify record count**
   - Compare the number of records in the HQ database (filtered by Type) against the old database
   - Spot-check a few records to confirm data integrity

### Special Cases

**Client Health Dashboard (P10) and Client Context Loader (P20):**

Health scores and client dossiers do not need manual migration. These are computed on demand:

- Run `/client:health-scan --refresh` to regenerate health scores into the HQ Companies database
- Run `/client:load --refresh` to regenerate client dossiers

The data will auto-populate on the corresponding Companies pages on the next scan or load.

**CRM Sync Hub (P21) Communications:**

If you already have a "Communications" database from CRM Pro or P21, the HQ Communications database uses the same schema. You can either:

- Continue using the existing Communications database (plugins will find it by name)
- Move records to `Founder OS HQ - Communications` and archive the old one

**Inbox Zero Drafts:**

The Inbox Zero Drafts database has a unique lifecycle (To Review > Approved > Sent to Gmail) and remains a standalone database. It is not consolidated into the HQ workspace.

---

## Step 4: Archive Old Databases

Once you are satisfied that the HQ databases are working correctly and any desired historical data has been migrated:

1. Open each old plugin-specific database
2. Verify it is no longer receiving new records (check the most recent entry date)
3. Move the database to an "Archived" section in your workspace, or delete it

> **Recommendation:** Keep old databases archived (not deleted) for at least 30 days in case you need to reference historical data.

---

## Step 5: Verify

Run the following command to confirm all plugins are discovering and using the consolidated HQ databases:

```
/savings:quick
```

This command scans all plugin databases and reports task counts. If the HQ databases are being used correctly, you should see activity attributed to the consolidated database names rather than the old plugin-specific names.

You can also run:

```
/notion:query "Show all databases"
```

This lists all databases visible to your integration. HQ databases should appear with the `Founder OS HQ - ` prefix.

---

## Rollback

If you need to revert to plugin-specific databases:

1. Archive or delete the HQ databases (or remove the integration's access to the HQ page)
2. Plugins will automatically fall back to the old plugin-specific database names
3. Any data written to HQ databases during the transition remains there — export it first if needed

---

## FAQ

**Q: Do I have to migrate all plugins at once?**
A: No. The fallback mechanism means each plugin independently checks for HQ databases. You can migrate gradually or leave some plugins on their old databases indefinitely.

**Q: Will old plugin versions work with the HQ databases?**
A: Older plugin versions only search for their original database names. Update plugins to the latest version to get HQ database auto-discovery.

**Q: What happens if both old and HQ databases exist?**
A: Updated plugins prefer the HQ database. Old databases are ignored for new writes but remain accessible in your workspace.

**Q: Can I rename the HQ databases?**
A: No. Plugins discover databases by searching for the exact `Founder OS HQ - [Name]` prefix. Renaming a database will cause plugins to fall back to old names or create a new plugin-specific database.

**Q: How do relations work across the HQ databases?**
A: The HQ template includes pre-built relations (e.g., Milestones linked to Goals, Communications linked to Companies and Contacts). These relations only work within the HQ databases — they do not link to old plugin-specific databases.
