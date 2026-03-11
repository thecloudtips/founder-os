# Command Center Dashboard Specification

**Date:** 2026-03-07
**Parent Page:** Founder OS HQ > Command Center
**Type:** Notion Dashboard page with 8 linked database views
**Reference:** `docs/plans/2026-03-07-notion-hq-consolidation-design.md` Section 6

---

## Overview

The Command Center is the landing page of the Founder OS HQ workspace. It surfaces the most actionable data from across all 30 plugins through 8 linked database views arranged in a 2-column grid. Every widget is a standard Notion linked database view -- no custom code, no embeds, no external dependencies.

All database names use the `Founder OS HQ - {Name}` prefix established in the consolidation design.

---

## Widget 1: Today's Priorities

**Purpose:** Surface overdue and due-today tasks so the founder starts each day with a clear action list.

| Field | Value |
|-------|-------|
| **Title** | Today's Priorities |
| **Source Database** | Founder OS HQ - Tasks |
| **View Type** | Table |

### Filter (Notion API syntax)

```json
{
  "and": [
    {
      "or": [
        {
          "property": "Deadline",
          "date": {
            "equals": "{{today}}"
          }
        },
        {
          "property": "Deadline",
          "date": {
            "before": "{{today}}"
          }
        }
      ]
    },
    {
      "property": "Status",
      "select": {
        "does_not_equal": "Done"
      }
    }
  ]
}
```

### Sort

```json
[
  {
    "property": "Priority",
    "direction": "ascending"
  }
]
```

### Visible Columns

| Column | Property Type | Notes |
|--------|--------------|-------|
| Title | title | Task name, linked to full page |
| Type | select | Action Item, Follow-Up, Email Task |
| Priority | number | 1 (highest) to 5 (lowest) |
| Deadline | date | Overdue dates render in red by default |
| Owner | rich_text | Person or team responsible |
| Status | select | To Do, In Progress, Waiting |

### Implementation Notes

- `{{today}}` is a Notion dynamic date filter, not a literal string. In the Notion UI this maps to the "Date is on or before > Today" relative filter.
- Priority ascending puts the most urgent (1) at the top.
- The filter intentionally includes all task Types (Action Item, Follow-Up, Email Task) to give a unified view. The Type column lets the user visually distinguish source.
- Overdue items (Deadline < today) appear alongside today's items so nothing slips through.
- Rows with no Deadline set are excluded by this filter. This is intentional -- undated tasks belong in a separate backlog view, not the daily priorities widget.

---

## Widget 2: Client Health

**Purpose:** Flag at-risk client relationships so the founder can intervene before churn.

| Field | Value |
|-------|-------|
| **Title** | Client Health |
| **Source Database** | Founder OS HQ - Companies |
| **View Type** | Table |

### Filter (Notion API syntax)

```json
{
  "or": [
    {
      "property": "Health Status",
      "select": {
        "equals": "Yellow"
      }
    },
    {
      "property": "Health Status",
      "select": {
        "equals": "Red"
      }
    }
  ]
}
```

### Sort

```json
[
  {
    "property": "Health Score",
    "direction": "ascending"
  }
]
```

### Visible Columns

| Column | Property Type | Notes |
|--------|--------------|-------|
| Name | title | Company name, linked to full page |
| Health Score | number | 0-100 composite score from P10 |
| Health Status | select | Yellow or Red (Green excluded by filter) |
| Risk Flags | multi_select | e.g., stale_contact, overdue_invoice, negative_sentiment |
| Last Scanned | date | Cache TTL indicator; stale = needs refresh |

### Implementation Notes

- Sorting by Health Score ascending puts the worst-scoring clients at the top.
- Green-status companies are excluded to keep the widget focused on action items.
- Companies with no Health Status set (never scanned by P10) are excluded by this filter. The founder should run `/client:health-scan --refresh` periodically.
- The Risk Flags multi_select provides at-a-glance context without opening the Company page.
- Last Scanned enables the founder to spot stale scores (24h TTL per P10 spec).

---

## Widget 3: Upcoming Meetings

**Purpose:** Show the next 48 hours of meetings with prep status so the founder is never caught off guard.

| Field | Value |
|-------|-------|
| **Title** | Upcoming Meetings |
| **Source Database** | Founder OS HQ - Meetings |
| **View Type** | Table |

### Filter (Notion API syntax)

```json
{
  "and": [
    {
      "property": "Date",
      "date": {
        "on_or_after": "{{today}}"
      }
    },
    {
      "property": "Date",
      "date": {
        "on_or_before": "{{two_days_from_now}}"
      }
    }
  ]
}
```

### Sort

```json
[
  {
    "property": "Date",
    "direction": "ascending"
  }
]
```

### Visible Columns

| Column | Property Type | Notes |
|--------|--------------|-------|
| Meeting Title | title | Meeting name, linked to full page |
| Date | date | Date and time of the meeting |
| Meeting Type | select | External Client, One-on-One, Internal Sync, etc. |
| Attendees | rich_text | Comma-separated attendee names |
| Company | relation | Linked Company record (if client meeting) |

### Implementation Notes

- Notion does not natively support a "next 48 hours" relative filter in the UI. The closest native option is "Date is within the next 1 week" or a manually set date range. For the API-based template creation, use `on_or_after: today` and `on_or_before: today + 2 days` calculated at template deploy time, then instruct users to switch to "Next week" in the Notion UI for a dynamic equivalent.
- Alternative approach: use "Date is within next 1 week" as the Notion UI filter and rely on ascending sort to put the soonest meetings at the top. The 48-hour intent is achieved visually since only the top rows matter.
- The Company relation column enables one-click navigation to the client record for pre-meeting context.
- Prep Notes and Talking Points (from P03) are accessible by clicking into the meeting page, not shown in the table to keep the widget compact.

---

## Widget 4: Recent Activity

**Purpose:** Show a feed of recent communications across all channels so the founder stays aware of client interactions.

| Field | Value |
|-------|-------|
| **Title** | Recent Activity |
| **Source Database** | Founder OS HQ - Communications |
| **View Type** | Table |

### Filter (Notion API syntax)

```json
{
  "property": "Date",
  "date": {
    "past_week": {}
  }
}
```

### Sort

```json
[
  {
    "property": "Date",
    "direction": "descending"
  }
]
```

### Visible Columns

| Column | Property Type | Notes |
|--------|--------------|-------|
| Title | title | Communication summary title |
| Type | select | Email, Meeting, Call |
| Date | date | When the communication occurred |
| Company | relation | Linked Company record |
| Sentiment | select | Positive, Neutral, Negative |

### Implementation Notes

- `past_week` is a Notion native relative date filter that dynamically shows the last 7 days.
- Descending sort puts the most recent activity at the top.
- Sentiment provides at-a-glance emotional context. Negative sentiment entries stand out and may warrant immediate attention.
- The Communications DB is populated by P21 CRM Sync Hub. If CRM sync has not been run recently, this widget will appear sparse. The Morning Sync (P22) or a `/crm:sync-email --since=7d` run fills it.
- Thread ID, Participants, Direction, and Summary are omitted from the view to keep it scannable; they are accessible on the full page.

---

## Widget 5: Pipeline

**Purpose:** Visualize the sales pipeline as a Kanban board so the founder can track deal progression at a glance.

| Field | Value |
|-------|-------|
| **Title** | Pipeline |
| **Source Database** | Founder OS HQ - Deals |
| **View Type** | Board (grouped by Stage) |

### Filter (Notion API syntax)

```json
{
  "and": [
    {
      "property": "Stage",
      "select": {
        "does_not_equal": "Closed Won"
      }
    },
    {
      "property": "Stage",
      "select": {
        "does_not_equal": "Closed Lost"
      }
    }
  ]
}
```

### Sort

```json
[
  {
    "property": "Close Date",
    "direction": "ascending"
  }
]
```

### Board Group Property

```json
{
  "property": "Stage",
  "type": "select"
}
```

Board columns appear in the select option order defined in the Deals DB: Lead, Qualified, Proposal, Negotiation.

### Visible Columns (Card Properties)

| Column | Property Type | Notes |
|--------|--------------|-------|
| Name | title | Deal name (card title) |
| Value | number | Deal amount in dollars |
| Company | relation | Client company |
| Probability | number | 0-100 win probability |
| Close Date | date | Expected close date |

### Implementation Notes

- Board view is the only non-table view in the dashboard. It provides the spatial representation founders expect for pipeline management.
- Closed Won and Closed Lost are both excluded to show only active pipeline.
- Cards are sorted by Close Date ascending within each column so the nearest-closing deals appear at the top of each stage.
- The Value property on the card enables quick mental pipeline math without opening each deal.
- Drag-and-drop between stages updates the Stage property directly.
- The Deliverables relation (Proposals, SOWs, Contracts linked to this deal) is accessible from the deal page, not the board card.

---

## Widget 6: Open Follow-Ups

**Purpose:** Surface stale follow-ups that need nudging so commitments do not fall through the cracks.

| Field | Value |
|-------|-------|
| **Title** | Open Follow-Ups |
| **Source Database** | Founder OS HQ - Tasks |
| **View Type** | Table |

### Filter (Notion API syntax)

```json
{
  "and": [
    {
      "property": "Type",
      "select": {
        "equals": "Follow-Up"
      }
    },
    {
      "property": "Status",
      "select": {
        "equals": "Waiting"
      }
    }
  ]
}
```

### Sort

```json
[
  {
    "property": "Days Waiting",
    "direction": "descending"
  }
]
```

### Visible Columns

| Column | Property Type | Notes |
|--------|--------------|-------|
| Title | title | Follow-up subject line or description |
| Days Waiting | number | Days since original email was sent |
| Priority | number | 1-5, derived from P06 age-based tiers |
| Nudge Count | number | How many nudges have been sent |
| Company | relation | Client or vendor being followed up |

### Implementation Notes

- This widget uses the same Tasks DB as Widget 1 (Today's Priorities) but with a different linked view and filter. Notion linked database views are independent -- changes to one view do not affect the other.
- Days Waiting descending puts the longest-waiting follow-ups at the top, highlighting items most likely to need a nudge.
- The Nudge Count column helps the founder decide escalation level (P06 uses gentle/firm/urgent based on count).
- Promise Type (Outbound vs Inbound) and Thread ID are omitted from the view but available on the page for context when composing a nudge.
- This widget pairs with `/followup:nudge [email_id]` -- the founder identifies stale items here, then runs the command.

---

## Widget 7: Active Goals

**Purpose:** Track progress on active goals so strategic objectives stay visible alongside daily operations.

| Field | Value |
|-------|-------|
| **Title** | Active Goals |
| **Source Database** | Founder OS HQ - Goals |
| **View Type** | Table |

### Filter (Notion API syntax)

```json
{
  "property": "Status",
  "select": {
    "equals": "In Progress"
  }
}
```

### Sort

```json
[
  {
    "property": "Target Date",
    "direction": "ascending"
  }
]
```

### Visible Columns

| Column | Property Type | Notes |
|--------|--------------|-------|
| Title | title | Goal name |
| Progress | number | 0-100 percentage based on milestone completion |
| RAG Status | select | Green, Yellow, Red based on gap analysis |
| Target Date | date | Goal deadline |
| Category | select | Revenue, Product, Hiring, Operations, etc. |

### Implementation Notes

- Only "In Progress" goals are shown. Not Started, On Hold, Completed, and Archived are excluded to keep the widget focused on active work.
- Target Date ascending puts the nearest deadline at the top, creating urgency.
- RAG Status is computed by P30 using the gap between actual and expected progress (Green >= -10, Yellow -25 to -10, Red < -25 or past deadline).
- Progress is displayed as a number (0-100). Notion does not natively render progress bars in linked database views, but the number combined with RAG Status provides equivalent information.
- Milestones are accessible via the Goal page (relation to Milestones DB), not shown in this summary view.
- This widget pairs with `/goal:check [name]` for detailed status and `/goal:update [name]` for progress updates.

---

## Widget 8: Latest Briefing

**Purpose:** Display the most recent briefing so the founder can quickly review their last generated summary without navigating to the Intelligence section.

| Field | Value |
|-------|-------|
| **Title** | Latest Briefing |
| **Source Database** | Founder OS HQ - Briefings |
| **View Type** | Table |

### Filter (Notion API syntax)

```json
{}
```

No filter applied. The limit + sort combination surfaces only the most recent entry.

### Sort

```json
[
  {
    "property": "Generated At",
    "direction": "descending"
  }
]
```

### Pagination / Limit

Notion linked database views do not have a native "limit to N rows" setting in the UI. To achieve a single-row effect:

1. **API approach:** When creating the view programmatically, set `page_size: 1` in the linked database view configuration (if supported by the Notion API at deploy time).
2. **UI approach:** Use a Gallery view with a single visible card, or instruct the user to collapse the view to show only 1 row via Notion's "Load more" behavior.
3. **Practical approach:** Accept that the table will show multiple rows but the descending sort ensures the latest briefing is always the first row. Keep the view collapsed (default Notion behavior for linked DBs) so only 3-5 rows are visible.

### Visible Columns

| Column | Property Type | Notes |
|--------|--------------|-------|
| Title | title | Briefing title (auto-generated by plugin) |
| Type | select | Daily Briefing, Weekly Review, Slack Digest, Morning Sync |
| Date | date | The date the briefing covers |
| Content | rich_text | The briefing body (truncated in table view) |

### Implementation Notes

- No filter is applied because the founder should see the latest briefing regardless of type. A Morning Sync from today is just as relevant as a Weekly Review from yesterday.
- The Content column will show a truncated preview in table view. Clicking the row opens the full briefing page.
- Generated At is used for sorting (not Date) because Date represents the covered period while Generated At represents when the briefing was actually created. A Weekly Review generated on Monday covers the prior week's Date but should still appear as the latest entry.
- If the founder wants to see only a specific type, they can duplicate this view and add a Type filter -- but the default dashboard view is type-agnostic.

---

## Layout Recommendations

### 2-Column Grid Arrangement

The Command Center page uses a Notion 2-column layout. Widgets are arranged to balance information density with visual weight. The left column is the "action" column (what to do), the right column is the "awareness" column (what to know).

```
+-------------------------------+-------------------------------+
|                               |                               |
|   1. Today's Priorities       |   2. Client Health            |
|   (Tasks - Table)             |   (Companies - Table)         |
|   ~8-10 rows                  |   ~3-5 rows                   |
|                               |                               |
+-------------------------------+-------------------------------+
|                               |                               |
|   3. Upcoming Meetings        |   4. Recent Activity          |
|   (Meetings - Table)          |   (Communications - Table)    |
|   ~4-6 rows                   |   ~6-8 rows                   |
|                               |                               |
+-------------------------------+-------------------------------+
|                                                               |
|   5. Pipeline                                                 |
|   (Deals - Board, grouped by Stage)                           |
|   Full width - 4 columns: Lead | Qualified | Proposal | Neg  |
|                                                               |
+---------------------------------------------------------------+
|                               |                               |
|   6. Open Follow-Ups          |   7. Active Goals             |
|   (Tasks - Table)             |   (Goals - Table)             |
|   ~5-7 rows                   |   ~3-5 rows                   |
|                               |                               |
+-------------------------------+-------------------------------+
|                                                               |
|   8. Latest Briefing                                          |
|   (Briefings - Table, 1 row)                                  |
|   Full width                                                  |
|                                                               |
+---------------------------------------------------------------+
```

### Sizing and Placement Rationale

| Row | Left Column | Right Column | Rationale |
|-----|-------------|--------------|-----------|
| 1 | Today's Priorities | Client Health | Action items first. Client health is the most critical awareness signal -- at-risk clients need immediate intervention. |
| 2 | Upcoming Meetings | Recent Activity | Time-sensitive calendar alongside recent communication context. Together they answer "what is happening today and what just happened." |
| 3 | Pipeline (full width) | -- | Board views need horizontal space for 4 stage columns. Full width prevents cramped cards. |
| 4 | Open Follow-Ups | Active Goals | Tactical follow-ups paired with strategic goals. Both are "things in progress" at different time horizons. |
| 5 | Latest Briefing (full width) | -- | Full width gives the briefing content room to display a meaningful preview. Placed last because it is read-once (the founder checks it, then focuses on the actionable widgets above). |

### Widget Sizing Guidelines

- **Table widgets:** Let Notion auto-size. Default collapsed view (showing ~6 rows with "Load more") works well for all table widgets.
- **Pipeline board:** Set to full width. Each stage column should be ~25% of the available width with 4 active stages visible.
- **Latest Briefing:** Full width, collapsed to show 1-3 rows maximum.
- **Column widths within tables:** Hide the row number column. Set Title/Name columns to ~35% width, other columns to auto-distribute.

### Visual Hierarchy

1. **Headers:** Each linked database view has its own title (the widget name). Use Notion's H2 heading for each widget title, placed directly above the linked DB view.
2. **Dividers:** Place a Notion divider (`---`) between row pairs (after row 1, after row 2, after row 3, after row 4) to create visual separation.
3. **Callout block:** Add a single callout block at the top of the page with a brief description: "Your daily command center. Overdue tasks, at-risk clients, upcoming meetings, and pipeline status -- all in one view."
4. **Empty state:** When a widget has no matching records (e.g., no Red/Yellow clients), Notion displays "No results" natively. No custom empty state handling is needed.

### Interaction Patterns

- **Click-through:** Every row/card links to the full database page. The dashboard is a summary layer, not a data entry layer.
- **Inline editing:** Notion allows inline property editing in linked views. The founder can update Status, Priority, or Stage directly from the dashboard without opening the page.
- **View switching:** Each linked database view can be switched between Table/Board/Calendar/Gallery by the user. The spec defines defaults, not constraints.
- **Filtering:** Users can add additional temporary filters to any widget. These filters persist per-user and do not affect the base view definition.

---

## Template Creation Sequence

When building this dashboard via the Notion API:

1. Create the "Command Center" page as a child of "Founder OS HQ"
2. Add the callout block with overview text
3. For each widget (in layout order):
   a. Add an H2 heading with the widget title
   b. Create a linked database view pointing to the source database
   c. Apply the filter configuration
   d. Apply the sort configuration
   e. Set visible columns and column order
   f. Set the view type (table or board)
4. Apply the 2-column layout by grouping widgets into Notion column blocks
5. Add dividers between row pairs

Note: Notion API column layout support may require creating column_list and column blocks. If the API does not support column layout at deploy time, create all widgets in a single column (stacked vertically) and document the manual column arrangement step for the user.
