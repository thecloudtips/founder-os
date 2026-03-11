<!-- Morning Sync Briefing Template — P22 Multi-Tool Morning Sync -->
<!-- INSTRUCTIONS: Replace {{PLACEHOLDERS}} with gathered/synthesized content. -->
<!-- Conditional blocks {{#SECTION}}...{{/SECTION}} render only when that source is available. -->

# Morning Sync — {{DATE}}

**Window**: Last {{OVERNIGHT_WINDOW}} (since {{WINDOW_SINCE}})
**Sources**: {{SOURCES_SUMMARY}}

<!-- DATE: Today's date in YYYY-MM-DD format.
     OVERNIGHT_WINDOW: Human-readable duration, e.g., "14 hours", "10 hours".
     WINDOW_SINCE: Timestamp of window start, e.g., "yesterday 6:00 PM".
     SOURCES_SUMMARY: Comma-separated list of sources that responded,
     e.g., "Gmail, Calendar, Notion, Slack, Drive" or "Gmail, Calendar, Notion". -->

---

## Top Priorities

{{TOP_PRIORITIES}}

<!-- TOP_PRIORITIES: Ranked list from priority-synthesis skill.
     Format per item:
     N. **[Action statement]** — [Source icon] [Time sensitivity]
        _[Context: why this matters]_

     Source icons: 📧 Email, 📅 Calendar, ✅ Notion task, 💬 Slack, 📁 Drive
     Time sensitivity labels: [NOW], [Today], [This week], [FYI]

     Show top 5 by default. Group by urgency window if 8+ items:
       **Needs attention now**
       1. ...
       **Today**
       2. ...
       **This week**
       3. ...

     Ranking factors (from priority-synthesis skill):
     - Deadline proximity (highest weight)
     - Sender/requester importance
     - Cross-source signal reinforcement (same topic in email + task = boost)
     - Explicit priority markers (urgent, P1, high-priority) -->

---

## Schedule Overview

{{SCHEDULE_OVERVIEW}}

<!-- SCHEDULE_OVERVIEW: Today's meetings in chronological order.
     Format per event:
     - **HH:MM - HH:MM** | [Title] ([meeting type]) [PRIORITY if score 4-5]
       Attendees: [count] | [prep note if high-priority]

     Meeting type labels: (external-client), (internal-sync), (one-on-one),
     (recurring), (ad-hoc), (group-meeting)
     Flag conflicts with ⚠️ CONFLICT prefix.
     Flag back-to-back meetings (gap < 15min) with 🔄.
     If no meetings today: "No meetings scheduled. Deep work day." -->

---

## Email Highlights

{{EMAIL_HIGHLIGHTS}}

<!-- EMAIL_HIGHLIGHTS: Top emails requiring attention from overnight window.
     Format:
     **Need response** ([count])
     N. **[Subject]** — [Sender]
        [1-line summary] | Action: [Yes: action phrase / No]

     **FYI / Low priority** ([count])
     N. **[Subject]** — [Sender]
        [1-line summary]

     Quick stats line at top:
     [unread_total] unread, [highlight_count] need attention

     Show max 10 total (up to 7 need-response, up to 3 FYI).
     Sort need-response by sender importance then recency.
     Exclude newsletters, automated notifications, and marketing. -->

---

## Tasks & Deadlines

{{TASKS_DEADLINES}}

<!-- TASKS_DEADLINES: Due today + overdue from Notion task databases.
     Format:

     **Overdue** ([count])
     - [ ] [Task title] — [project] — overdue [N] days

     **Due Today** ([count])
     - [ ] [Task title] — [project] [priority if available]

     **Completed Overnight** ([count])
     - [x] [Task title] — [project] — completed [timestamp]

     Overdue section: sort by days overdue descending (most overdue first).
     Due Today section: sort by priority then alphabetical.
     Completed Overnight: only tasks completed within the overnight window.
     Omit any section with zero items (do not show empty headers).
     If all sections empty: "No tasks due today and nothing overdue. Review your
     weekly plan." -->

{{#SLACK_AVAILABLE}}
---

## Slack Highlights

{{SLACK_HIGHLIGHTS}}

<!-- SLACK_HIGHLIGHTS: High-signal messages and @mentions from Slack overnight window.
     Format:

     **@Mentions** ([count])
     - **#[channel]** — [sender]: "[message preview]"
       [Action needed: yes/no] | [timestamp]

     **Key Discussions** ([count])
     - **#[channel]** — [sender]: "[message preview]"
       Signal: [score]/100 | [thread replies] replies

     Show @mentions first (all of them), then key discussions by signal score descending.
     Signal score uses P19 Slack Digest Engine 4-factor scoring when available.
     Max 8 items total. Exclude bot messages and automated notifications.
     If no highlights: omit entire Slack section (do not render empty). -->
{{/SLACK_AVAILABLE}}

{{#DRIVE_AVAILABLE}}
---

## Drive Updates

{{DRIVE_UPDATES}}

<!-- DRIVE_UPDATES: Recently modified or shared documents from Google Drive overnight window.
     Format per item:
     - **[File name]** ([type: Doc/Sheet/Slides/PDF]) — modified by [modifier] at [HH:MM]
       [Context: Shared with you / New comments / Major edits]

     Sort by modification time, most recent first.
     Type labels: Doc, Sheet, Slides, PDF, Other
     Max 5 items. Exclude auto-save drafts and self-modifications.
     If no updates: omit entire Drive section (do not render empty). -->
{{/DRIVE_AVAILABLE}}

---

## Quick Stats

{{QUICK_STATS}}

<!-- QUICK_STATS: Summary metrics block. One line per source.
     Format:
     - **Emails**: [unread] unread, [highlights] need attention
     - **Meetings**: [count] today ([priority_count] high-priority)
     - **Tasks**: [due] due today, [overdue] overdue
     {{#SLACK_AVAILABLE}}- **Slack**: [highlights] highlights, [mentions] @mentions{{/SLACK_AVAILABLE}}
     {{#DRIVE_AVAILABLE}}- **Drive**: [updates] recent updates{{/DRIVE_AVAILABLE}}
     - **Sources**: [comma-separated list of available sources]
     - **Generated**: [ISO 8601 timestamp] -->

<!-- CONDITIONAL BLOCK REFERENCE:
     {{#SLACK_AVAILABLE}} — Renders when Slack MCP is connected and returned data.
       Set to true when Slack source status is "available" or "partial".
       Omit entirely (do not render empty section) when Slack is unavailable.
     {{/SLACK_AVAILABLE}}

     {{#DRIVE_AVAILABLE}} — Renders when Google gws CLI (Drive) is connected and returned data.
       Set to true when Drive source status is "available" or "partial".
       Omit entirely (do not render empty section) when Drive is unavailable.
     {{/DRIVE_AVAILABLE}}

     Core sources (Gmail, Calendar, Notion) are always required and have no
     conditional blocks — their sections always render. If a core source fails,
     the section renders with an error note: "[Source] unavailable — data may be incomplete." -->

<!-- NOTION COMPATIBILITY NOTES:
     - Use Markdown headers (# ## ###) — Notion renders these as heading blocks.
     - Use **bold** for emphasis — renders as bold text in Notion.
     - Use - [ ] and - [x] for task checkboxes — Notion renders these as to-do blocks.
     - Use --- for horizontal rules — Notion renders these as divider blocks.
     - Use _italic_ for context lines — renders as italic in Notion.
     - Avoid HTML tags, tables, and footnotes — Notion does not render these.
     - Keep lines under 2000 characters for Notion block limits. -->
