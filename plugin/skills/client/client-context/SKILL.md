---
name: Client Context
description: "Aggregates client data from Notion CRM, Gmail, Calendar, and Drive into a comprehensive dossier. Activates when the user wants to load client context, pull client data, build a dossier, or asks 'tell me everything about [client].' Covers multi-source data gathering, deduplication, completeness scoring, and fuzzy matching across data sources."
globs:
  - "teams/agents/crm-agent.md"
  - "teams/agents/email-agent.md"
  - "teams/agents/docs-agent.md"
  - "teams/agents/calendar-agent.md"
  - "teams/agents/notes-agent.md"
  - "teams/agents/context-lead.md"
---

## Overview

Aggregate client data from five independent sources into a unified dossier. Each source provides a distinct data dimension -- CRM provides structured records, email provides communication history, calendar provides meeting patterns, documents provides collaboration artifacts, and notes provides decision history. Treat each source as authoritative for its domain. When sources conflict, apply the data source hierarchy to determine which value takes precedence. Process all sources in parallel, merge results using deduplication rules, and score the resulting dossier for completeness.

## Data Source Hierarchy

When multiple sources provide conflicting information for the same field, resolve conflicts using this priority order (highest to lowest):

1. **CRM (Notion)** -- Authoritative for: company name, contact details, deal status, pipeline stage, relationship owner, industry classification. CRM is the system of record. Always prefer CRM values for structured profile data.
2. **Email (Gmail)** -- Authoritative for: communication tone, response patterns, last contact date, active discussion topics. Email provides the most recent interaction context.
3. **Calendar (Google Calendar)** -- Authoritative for: meeting frequency, engagement cadence, upcoming commitments, attendee patterns. Calendar reveals relationship rhythm.
4. **Documents (Google Drive)** -- Authoritative for: shared deliverables, proposal history, contract status, collaboration intensity. Documents reflect formal relationship artifacts.
5. **Notes (Notion pages)** -- Authoritative for: internal decisions, action items, meeting outcomes, strategic context. Notes capture what happened behind the scenes.

## CRM Pro Notion Schema

The plugin integrates with the CRM Pro Notion template containing four interconnected databases. Use dynamic database discovery -- search by database title, never hardcode database IDs.

### Companies Database (Dossier Target)

The Companies database serves dual duty: it is both the CRM source for company profiles AND the dossier storage target. Instead of a separate "Client Dossiers" database, dossiers are written as properties on the matching Companies page.

**Database Discovery Order:**
1. Search for "[FOS] Companies" (consolidated HQ database)
2. If not found, try "Founder OS HQ - Companies"
3. Search for "Companies" or "CRM - Companies" (standalone CRM Pro template)
4. **Fallback only**: If none is found, lazy-create a standalone "Client Dossiers" database for backward compatibility

Key properties (CRM profile):
- **Name** (title): Company name -- primary lookup field
- **Industry** (select): Industry classification
- **Size** (select): Company size tier (Startup, SMB, Mid-Market, Enterprise)
- **Status** (select): Active, Prospect, Churned, Partner
- **Website** (url): Company website
- **Contacts** (relation → Contacts): Linked contact records
- **Deals** (relation → Deals): Associated deals
- **Communications** (relation → Communications): Interaction log
- **Client Health Score** (number, 0-100): Calculated relationship health (enrichment target)

Dossier properties (written by this plugin on the same Companies page):
- **Dossier** (rich_text): Full serialized dossier content
- **Dossier Completeness** (number, 0.0-1.0): Data completeness score
- **Dossier Generated At** (date): When the dossier was last assembled
- **Dossier Stale** (checkbox): Whether TTL has expired

These dossier properties are created on-demand if they do not already exist on the database schema.

### Contacts Database
Search by title: "Contacts" or "CRM - Contacts". Key properties:
- **Name** (title): Full contact name
- **Email** (email): Primary email address -- cross-reference with Gmail
- **Phone** (phone_number): Contact phone
- **Role** (rich_text): Job title or role
- **Company** (relation → Companies): Parent company
- **Type** (select): Decision Maker, Champion, User, Influencer, Blocker
- **Last Contact** (date): Most recent interaction date
- **Communications** (relation → Communications): Linked communications

### Deals Database
Search by title: "Deals" or "CRM - Deals". Key properties:
- **Name** (title): Deal name
- **Value** (number): Deal monetary value
- **Stage** (select): Lead, Qualified, Proposal, Negotiation, Closed Won, Closed Lost
- **Company** (relation → Companies): Associated company
- **Close Date** (date): Expected or actual close date
- **Probability** (number, 0-100): Win probability percentage
- **Risk Level** (select): Low, Medium, High (enrichment target)

### Communications Database
Search by title: "Communications" or "CRM - Communications". Key properties:
- **Title** (title): Communication summary
- **Type** (select): Email, Call, Meeting, Note
- **Date** (date): When the communication occurred
- **Contact** (relation → Contacts): Associated contact
- **Company** (relation → Companies): Associated company
- **Summary** (rich_text): Brief description of interaction
- **Sentiment** (select): Positive, Neutral, Negative (enrichment target)

## Client Lookup and Fuzzy Matching

Locate the client across all sources using these strategies in order:

### Step 1: CRM Lookup (Primary)
1. Search the Companies database by exact title match on the provided client name.
2. If no exact match, search by case-insensitive partial match (client name contained within company name or vice versa).
3. If still no match, search by common abbreviations and known aliases (e.g., "IBM" ↔ "International Business Machines").
4. When a Companies match is found, follow the Contacts relation to retrieve all associated contact records. Extract email addresses for cross-source correlation.

### Step 2: Cross-Source Correlation
Use email addresses from the CRM Contacts to search other sources:
- **Gmail**: Search by contact email addresses for thread history.
- **Calendar**: Search by attendee email addresses for meeting history.
- **Drive**: Search by client company name for shared documents.
- **Notes**: Search Notion pages by client company name for meeting notes.

### Step 3: Fallback Matching
When no CRM record exists:
- Search Gmail for the client name in sender names, subject lines, and email bodies.
- Search Calendar for the client name in event titles and attendee display names.
- Search Notion for pages containing the client name.
- Aggregate discovered email addresses and use them to enrich other source searches.

Report match confidence: exact match (1.0), partial match (0.8), fuzzy/fallback match (0.5), no match found (0.0). Include match confidence in the dossier metadata.

## Per-Source Extraction Rules

### CRM Extraction
- Pull the full Companies record: all properties listed in the schema above.
- Follow relations: retrieve all linked Contacts, active Deals (exclude Closed Lost), and recent Communications (last 180 days).
- Calculate relationship tenure: days between earliest Communication date and today.
- Count total interactions by type (Email, Call, Meeting, Note) from Communications.

### Email Extraction
- Search for threads with the client's contact emails over the last 180 days.
- Extract: total thread count, total message count, average response time (client → user and user → client), last exchange date.
- Identify the 5 most recent threads by subject and date.
- Collect the last 10 messages for sentiment analysis. Extract raw positive, neutral, and negative indicators. See the relationship-summary skill for the detailed sentiment scoring rubric.
- Calculate communication stats: messages per month, average thread length, response rate.

### Calendar Extraction
- Search for events with client attendees over a bidirectional window: 180 days past, 30 days future.
- Past meetings: count, frequency (meetings per month), last meeting date, recurrence patterns.
- Upcoming meetings: next meeting date, purpose, attendees, preparation needs.
- Identify meeting types: one-on-one, group, recurring sync, ad-hoc.
- Detect engagement trends: increasing, stable, or declining meeting frequency over last 3 months.

### Document Extraction
- Search Google Drive for documents containing the client name in title or content.
- Categorize by type: Proposals, Contracts, Presentations, Reports, Spreadsheets, Other.
- Sort by last modified date (most recent first).
- Extract: document count by category, most recent document, shared vs. private documents.
- Flag active documents (modified in last 30 days) separately.

### Notes Extraction
- Search Notion pages for the client name in page titles and content.
- Also query the Communications database for entries of type "Note" or "Meeting" linked to the client.
- Extract key decisions: scan for decision language ("decided", "agreed", "will proceed with", "chose to").
- Extract open items: scan for action language ("need to", "TODO", "follow up", "pending", "outstanding").
- Compile a master open items list, deduplicated across both sources.
- Sort decisions and open items by date (most recent first).

## Deduplication Rules

When merging data from multiple sources:

- **Contact information**: CRM values take precedence. Only supplement with email-discovered data when CRM fields are empty.
- **Interaction dates**: When the same meeting appears in both Calendar and Communications, keep the Calendar record for time/attendee data and the Communications record for summary/notes.
- **Action items**: Deduplicate by matching verb + noun phrase similarity (same as Inbox Zero's duplicate detection). When the same action appears in both Notes and Email, keep the version with more context.
- **Documents**: Deduplicate by file ID. When the same document appears in both Drive search results and a Notion page link, merge metadata from both.
- **Communication counts**: Do not double-count. When an email thread is logged in both Gmail history and CRM Communications, count it once. Prefer Gmail for raw counts, CRM for annotated summaries.

## Completeness Scoring

Score the assembled dossier on a 0.0 to 1.0 scale based on data availability:

| Component | Weight | Scoring |
|-----------|--------|---------|
| CRM Profile | 0.25 | 1.0 if Companies record found with ≥5 populated properties, 0.5 if found with <5 properties, 0.0 if not found |
| Contacts | 0.15 | 1.0 if ≥1 contact with email, 0.5 if contact found without email, 0.0 if no contacts |
| Deal Status | 0.10 | 1.0 if active deal exists, 0.5 if only closed deals, 0.0 if no deals |
| Email History | 0.20 | 1.0 if ≥10 threads found, 0.5 if 1-9 threads, 0.0 if no email history |
| Calendar Data | 0.10 | 1.0 if ≥3 past meetings, 0.5 if 1-2 meetings, 0.0 if no meetings |
| Documents | 0.10 | 1.0 if ≥3 documents found, 0.5 if 1-2 documents, 0.0 if no documents |
| Notes/Decisions | 0.10 | 1.0 if ≥2 decision records, 0.5 if 1 record, 0.0 if no records |

Calculate weighted sum. Report the total score and per-component breakdown. Flag any component scoring 0.0 as a data gap.

## Dossier Output Structure

Assemble the final dossier into seven standardized sections:

1. **Profile**: Company name, industry, size, status, website, relationship owner, tenure, primary contacts.
2. **Relationship History**: First contact date, total interactions by type, engagement trend (increasing/stable/declining), key milestones.
3. **Recent Activity**: Last 5 interactions across all sources (email, meeting, note), sorted by date.
4. **Open Items**: Master list of pending actions, decisions needed, and follow-ups -- deduplicated across sources.
5. **Upcoming**: Next scheduled meetings, pending deal milestones, approaching deadlines.
6. **Sentiment & Health**: Overall sentiment (positive/neutral/negative), engagement level (high/medium/low), risk flags, health score (0-100).
7. **Key Documents**: Most relevant documents sorted by recency, categorized by type.

Include metadata: completeness score, sources used, match confidence, cache timestamp, generation date. For the formatted executive brief derived from this dossier, see the relationship-summary skill's Executive Brief Template section.

## Graceful Degradation

When a source is unavailable (gws CLI unavailable or authentication not configured or API error):
- Mark the source status as "unavailable" in the dossier metadata.
- Skip all extraction rules for that source.
- Adjust completeness scoring: set unavailable components to 0.0 but note "unavailable" vs. "no data found" in the breakdown.
- Continue synthesis with available sources. The minimum requirement is 1 gatherer returning data (per config.json's minimum_gatherers_required=1).
- Never fail the entire dossier because one optional source is unavailable. CRM and Email are required; Calendar, Documents, and Notes are optional enhancements.

## Edge Cases

### Client Not Found in CRM
When no Companies record matches the client name, proceed with email-first discovery. Search Gmail for the name, extract email addresses from matching threads, and use those addresses to search Calendar and Documents. Build a partial dossier and flag CRM Profile completeness as 0.0. Suggest creating a CRM record in the dossier's recommendations section.

### Multiple CRM Matches
When the fuzzy search returns multiple Companies records, present all matches with their match confidence scores. Select the highest-confidence match automatically if confidence ≥ 0.8. If all matches score below 0.8, present the top 3 matches and ask the user to confirm which client to load.

### Stale CRM Data
When the most recent CRM Communication entry is older than 90 days but email/calendar show recent activity, flag the CRM as potentially stale. Include a recommendation to update CRM records in the dossier.

### New Client (Minimal Data)
When only 1-2 sources return data (e.g., a few emails but no CRM record), still produce the dossier. Focus the output on available data and clearly mark empty sections. Set completeness score accordingly and suggest data enrichment steps.
