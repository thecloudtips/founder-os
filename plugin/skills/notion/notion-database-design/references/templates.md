# Notion Database Templates

Complete schema definitions for the 5 pre-built business templates available via `/founder-os:notion:template`.

---

## Template 1: CRM Contacts

**Purpose**: Track business contacts, leads, and client relationships.
**Suggested view**: Table sorted by Name.

| Property | Type | Options/Config |
|----------|------|----------------|
| Name | Title | — |
| Company | Rich text | — |
| Email | Email | — |
| Phone | Phone | — |
| Role | Rich text | — |
| Status | Select | Lead, Active, Inactive, Churned |
| Source | Select | Referral, Website, Cold Outreach, Event, Inbound |
| Tags | Multi-select | Client, Partner, Vendor, Prospect, VIP |
| Last Contact | Date | — |
| Next Follow-Up | Date | — |
| Notes | Rich text | — |
| LinkedIn | URL | — |

**Schema rationale:**
- Status tracks the contact lifecycle from lead to churn.
- Source captures where the contact originated for attribution.
- Tags allow multi-dimensional categorization (a contact can be both Client and VIP).
- Two date fields separate historical (Last Contact) from forward-looking (Next Follow-Up).
- LinkedIn as a URL field for quick profile access.

---

## Template 2: Project Tracker

**Purpose**: Track projects with tasks, deadlines, and ownership.
**Suggested view**: Board grouped by Status.

| Property | Type | Options/Config |
|----------|------|----------------|
| Task | Title | — |
| Status | Status | Backlog, To Do, In Progress, In Review, Done |
| Priority | Select | P1 - Critical, P2 - High, P3 - Medium, P4 - Low |
| Assignee | People | — |
| Due Date | Date | — |
| Start Date | Date | — |
| Tags | Multi-select | Bug, Feature, Improvement, Documentation, Research |
| Estimated Hours | Number | Format: number |
| Project | Select | (user customizes per their projects) |
| Notes | Rich text | — |

**Schema rationale:**
- Status uses Notion's Status type for native kanban board grouping.
- 5 status options cover a standard workflow with a review step.
- Priority uses P1-P4 with labels for clarity in board cards.
- Both Start and Due dates support timeline/Gantt views.
- Estimated Hours enables workload tracking via Rollup on related databases.

---

## Template 3: Content Calendar

**Purpose**: Plan and track content creation across channels.
**Suggested view**: Calendar by Publish Date.

| Property | Type | Options/Config |
|----------|------|----------------|
| Title | Title | — |
| Status | Status | Idea, Drafting, In Review, Scheduled, Published |
| Content Type | Select | Blog Post, Newsletter, Social Post, Video, Podcast, Case Study |
| Channel | Multi-select | Website, LinkedIn, Twitter, Newsletter, YouTube, Instagram |
| Publish Date | Date | — |
| Author | People | — |
| Topic | Select | Product, Industry, Tutorial, Thought Leadership, Company News |
| SEO Keywords | Rich text | — |
| Draft URL | URL | — |
| Published URL | URL | — |
| Notes | Rich text | — |

**Schema rationale:**
- Status tracks the content lifecycle from ideation through publication.
- Content Type is single-select (each piece is one type).
- Channel is multi-select (same content can be cross-posted to multiple channels).
- Separate Draft URL and Published URL fields track pre- and post-publication links.
- Topic categorization enables content mix analysis.

---

## Template 4: Meeting Notes

**Purpose**: Record meeting details, decisions, and action items.
**Suggested view**: Table sorted by Date (descending).

| Property | Type | Options/Config |
|----------|------|----------------|
| Meeting | Title | — |
| Date | Date | Include time |
| Type | Select | One-on-One, Team Standup, Client Call, Planning, Retrospective |
| Attendees | People | — |
| Status | Status | Scheduled, In Progress, Completed, Canceled |
| Action Items | Rich text | — |
| Decisions | Rich text | — |
| Notes | Rich text | — |

**Schema rationale:**
- Minimal property count (8) keeps the schema focused on capture, not overhead.
- Type categorization enables filtering by meeting category.
- Three text fields separate concerns: Notes (raw content), Decisions (agreed outcomes), Action Items (follow-ups).
- Status includes Canceled for meetings that were scheduled but didn't happen.
- Date includes time for calendar alignment.

---

## Template 5: Knowledge Wiki

**Purpose**: Organize team knowledge, documentation, and reference material.
**Suggested view**: Table sorted by Last Edited (descending).

| Property | Type | Options/Config |
|----------|------|----------------|
| Title | Title | — |
| Category | Select | Process, Policy, Technical, Onboarding, FAQ, Reference |
| Tags | Multi-select | Engineering, Marketing, Sales, Operations, HR, Finance |
| Owner | People | — |
| Status | Status | Draft, Published, Needs Update, Archived |
| Last Reviewed | Date | — |
| Audience | Multi-select | All Team, Engineering, Leadership, New Hires |
| Summary | Rich text | — |
| Related Docs | URL | — |

**Schema rationale:**
- Category is single-select for primary classification.
- Tags enables cross-departmental discovery.
- Status tracks document lifecycle with "Needs Update" for stale content flagging.
- Last Reviewed date enables freshness auditing separate from Last Edited.
- Audience enables filtering for role-specific documentation.
- Summary provides a preview without opening the full page.

---

## Template Deployment Protocol

When deploying a template via `/founder-os:notion:template [name]`:

1. **Match template name** — accept exact matches and common variations:
   - "CRM" or "CRM Contacts" or "contacts" → CRM Contacts
   - "Project" or "Project Tracker" or "tasks" → Project Tracker
   - "Content" or "Content Calendar" or "editorial" → Content Calendar
   - "Meeting" or "Meeting Notes" or "meetings" → Meeting Notes
   - "Wiki" or "Knowledge Wiki" or "knowledge base" → Knowledge Wiki

2. **Resolve parent** — if `--parent=NAME` is provided, search for the parent page. Otherwise, create at workspace root.

3. **Present schema** — show the full property table and suggested view. Ask for confirmation.

4. **Create database** — use the `notion-create-database` tool with all properties defined.

5. **Confirm** — report the created database title, URL, and property count.

---

## Template Listing Format

When `/founder-os:notion:template` is called without a name, present:

```
Available Notion Database Templates:

1. CRM Contacts — Track business contacts, leads, and client relationships (12 properties)
2. Project Tracker — Track projects with tasks, deadlines, and ownership (10 properties)
3. Content Calendar — Plan and track content creation across channels (11 properties)
4. Meeting Notes — Record meeting details, decisions, and action items (8 properties)
5. Knowledge Wiki — Organize team knowledge and reference material (9 properties)

Deploy with: /founder-os:notion:template [name]
Example: /founder-os:notion:template "Project Tracker"
```
