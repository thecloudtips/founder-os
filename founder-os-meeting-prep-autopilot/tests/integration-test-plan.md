# Integration Test Plan: Meeting Prep Autopilot

## Overview

This test plan covers end-to-end scenarios for the Meeting Prep Autopilot plugin (#03), mapping to acceptance criteria from the plugin spec. The plugin uses a parallel-gathering pattern: 4 gatherer agents (Calendar, Gmail, Notion, Drive) fetch data simultaneously, then a Prep Lead agent synthesizes everything into a comprehensive meeting prep document with framework-based talking points. Tests require the `gws` CLI for Google services (Calendar required, Gmail required, Drive optional) and Notion MCP (required).

## Acceptance Criteria

| ID | Criterion |
|----|-----------|
| AC-1 | `/meeting:prep [event_id]` generates a prep document |
| AC-2 | Pulls attendee context from CRM/email history |
| AC-3 | Lists open items from previous meetings |
| AC-4 | Suggests talking points based on context |
| AC-5 | Works for both internal and external meetings |

## Test Environment

- Claude Code with plugin installed
- `gws` CLI installed and authenticated (`gws auth login`) with a test account containing diverse calendar events, email threads with meeting attendees, and Drive documents
- Notion MCP configured with workspace access, CRM databases (Companies, Contacts, Deals, Communications), and prior meeting notes
- Test data prepared:
  - Calendar events for today: at least 6 varied events (external client meeting, internal 1:1, recurring sync, ad-hoc, large group meeting, focus block)
  - Notion CRM: at least 4 contacts with roles, companies, active deals, and relationship history
  - Notion meeting notes: at least 3 prior meeting note pages with open/closed action items
  - Gmail threads: at least 5 email threads with attendees spanning various recency and sentiment levels
  - Google Drive: at least 3 documents relevant to meeting topics or attendees

---

## Scenario 1: Basic Single-Agent Prep with All Sources

**Goal**: Verify that `/meeting:prep [event_id]` with all MCP servers available generates a complete prep document with attendee profiles, open items, talking points, and a Notion page.

**Preconditions**:
- `gws` CLI installed and authenticated with a test account
- Test calendar event containing 3 attendees (mix of internal and external)
- Email threads to each attendee within the 90-day default lookback accessible via gws
- Notion MCP configured with CRM contacts matching attendees, prior meeting notes with open action items
- Google Drive accessible via gws with at least 1 relevant document
- No "[FOS] Meetings" database exists yet (first run)

**Steps**:
1. Identify a test event_id from the calendar with 3 attendees (at least 1 external)
2. Run `/meeting:prep [event_id]`
3. Inspect the Notion page created
4. Inspect the "[FOS] Meetings" database row
5. Verify the chat output summary

**Expected Results**:
- Notion page created with title "Meeting Prep: [Event Title] -- [YYYY-MM-DD]"
- Page contains all required sections in order: meeting metadata (time, type, importance, location, RSVP), Attendees table, Agenda, Open Items, Recent Context, Relevant Documents, Discussion Guide
- Attendees section shows a profile for each attendee with: name, RSVP, role/company, relationship status (Active/Cooling/Dormant/New), last contact date and channel, pending items count
- Attendee profiles ordered: external attendees first, then internal, sorted by seniority descending
- Open Items grouped into four categories: "You owe", "Owed to you", "Shared/unclear", "Resolved since last meeting" (if recurring)
- Relevant Documents section shows up to 3 Drive documents with title, type, modified date, link, and relevance note
- Discussion Guide includes: framework name, opener, 3-5 talking points (each starting with an action verb), proposed next steps (2-3 with owner and deadline), and meeting close
- "[FOS] Meetings" database discovered (not lazy-created -- database is shared infrastructure)
- Database row populated with P03-owned fields: Meeting Title (title), Event ID (rich_text), Date, Attendees, Meeting Type, Importance Score, Prep Notes, Talking Points, Sources Used, Generated At
- P07 fields (Summary, Decisions, Follow-Ups, Topics, Source Type, Transcript File, Duration) left empty (not overwritten if already populated by P07)
- Sources status shows: Calendar (check) | Gmail (check) | Notion (check) | Drive (check)
- Chat output displays: Status, Notion Page URL, Sources Used, Generated in time
- Meeting type correctly classified per the meeting-context skill classification table
- Importance score computed using the weighted scoring rubric (1-5)

**Acceptance Criteria Covered**: AC-1 (generates prep doc), AC-2 (attendee context from CRM/email), AC-3 (open items listed), AC-4 (talking points generated)

---

## Scenario 2: Full --team Parallel Pipeline

**Goal**: Verify that `--team` activates the parallel-gathering pipeline with all 5 agents reporting execution details.

**Preconditions**:
- `gws` CLI installed and authenticated (Google Calendar, Gmail, Google Drive)
- Notion MCP configured
- Test event with 3+ attendees having CRM records, email history, and related Drive documents
- teams/config.json accessible with parallel-gathering pattern

**Steps**:
1. Identify a test event_id with rich data across all sources
2. Run `/meeting:prep [event_id] --team`
3. Observe pipeline execution output
4. Inspect the Notion page and database entry

**Expected Results**:
- Phase 1 (Parallel Gathering): All 4 gatherer agents launch simultaneously:
  - Calendar Agent fetches event details, classifies meeting type, computes importance score
  - Gmail Agent searches email threads with each attendee within 90-day window, extracts thread counts, unanswered emails, sentiment indicators
  - Notion Agent pulls CRM contact data (role, company, deals, relationship status), prior meeting notes, open action items
  - Drive Agent searches for relevant documents using title, attendee, and company queries
- Phase 2 (Synthesis): Prep Lead merges all gatherer outputs into the full prep document with framework-based talking points
- Pipeline execution summary table shown with 5 rows:
  - Calendar Agent: status, duration, items found (1 event, N attendees)
  - Gmail Agent: status, duration, items found (N threads)
  - Notion Agent: status, duration, items found (N contacts, N items)
  - Drive Agent: status, duration, items found (N documents)
  - Prep Lead: status, duration
- All 5 agents show "Done" or "Complete" status
- Total pipeline time reported
- Notion page created with the same section structure as default mode
- Database row created with all metrics and sources marked as used
- Full prep document includes attendee profiles, open items, agenda, relevant documents, and discussion guide with talking points
- Output header shows "Generated successfully (team pipeline)"

**Acceptance Criteria Covered**: AC-1 (generates prep doc), AC-2 (attendee context), AC-3 (open items), AC-4 (talking points), AC-5 (works for the meeting type tested)

---

## Scenario 3: No event_id -- Numbered List Selection

**Goal**: Verify that omitting the event_id presents a numbered list of today's meetings for interactive selection.

**Preconditions**:
- `gws` CLI authenticated with at least 4 remaining calendar events today:
  - 1 external client meeting
  - 1 internal 1:1
  - 1 recurring standup
  - 1 focus block (should be filtered out)
- Notion MCP configured

**Steps**:
1. Run `/meeting:prep` with no arguments
2. Observe the numbered list output
3. Select a meeting by entering its number
4. Verify the prep document is generated for the selected meeting

**Expected Results**:
- Today's remaining meetings displayed as a numbered list in the format:
  ```
  Today's remaining meetings:
  1. [HH:MM] - [HH:MM] | [Event Title] ([N] attendees)
  2. [HH:MM] - [HH:MM] | [Event Title] ([N] attendees)
  ...
  Enter a number to select, or provide an event_id directly:
  ```
- Focus block event is NOT listed (filtered by title containing "Focus", per event filtering rules)
- Cancelled events are NOT listed
- Solo events with no attendees are NOT listed
- Events sorted chronologically by start time
- After user selects a number, the full prep document is generated for that event
- Generated prep matches the quality and structure of Scenario 1 (all sections present)
- If user enters an invalid number, error message displayed: "Invalid selection. Please choose a number from the list."

**Acceptance Criteria Covered**: AC-1 (generates prep doc via interactive selection)

---

## Scenario 4: prep-today Bulk Command

**Goal**: Verify that `/meeting:prep-today` preps all qualifying meetings in sequence, reuses the attendee cache, and presents a summary table at the end.

**Preconditions**:
- `gws` CLI authenticated with 4 qualifying calendar meetings today:
  - 09:00 -- External client meeting (2 external attendees + user)
  - 10:30 -- Internal 1:1 (1 internal attendee + user)
  - 13:00 -- Recurring standup (3 internal attendees + user, 1 attendee overlaps with 10:30 meeting)
  - 15:00 -- Ad-hoc meeting (2 attendees, 1 overlaps with 09:00 meeting)
- Notion MCP configured and Gmail accessible via gws with data for all attendees
- At least 1 attendee appears in 2+ meetings (to test cache reuse)

**Steps**:
1. Run `/meeting:prep-today --yes` (auto-proceed)
2. Observe per-meeting progress output
3. Inspect the final summary table
4. Verify all 4 Notion pages and database rows created
5. Verify attendee cache hit count

**Expected Results**:
- Auto-proceed message: "Auto-proceeding with 4 meetings (--yes flag)."
- Per-meeting progress displayed: "Prepping meeting [1/4]: [Title] ([time])..."
- After each meeting, inline summary shown with: title, time, type, importance score, framework, attendee count, open items count, talking points count, Notion URL
- Attendee cache built before individual meeting processing:
  - All unique attendees across 4 meetings resolved once
  - Cache hits reported for shared attendees (at least 2 hits for overlapping attendees)
- Final summary table displayed with columns: #, Time, Meeting, Type, Importance, Framework, Talking Points, Status, Notion
- All 4 meetings show "Generated" status
- Summary includes: total meetings prepped (4/4), total unique attendees profiled, attendee cache hits count
- Back-to-back deduplication applied: overlapping attendee's open items assigned to the more appropriate meeting, later meetings reference earlier ones for shared items
- "[FOS] Meetings" database contains exactly 4 rows
- 4 separate Notion prep pages created
- Total prep time reported at the bottom

**Acceptance Criteria Covered**: AC-1 (generates prep doc), AC-2 (attendee context with cache), AC-3 (open items), AC-4 (talking points), AC-5 (multiple meeting types in one batch)

---

## Scenario 5: External Client Meeting (SPIN Talking Points)

**Goal**: Verify that an external client meeting uses the SPIN framework for talking points and includes deal context in the prep.

**Preconditions**:
- `gws` CLI authenticated; calendar contains an event where at least 1 attendee's email domain differs from the user's org domain
- Notion CRM configured with a Contact record matching the external attendee: role (VP), company (active account), active deal in "Negotiation" stage with value and close date
- Gmail accessible via gws with email threads to the attendee including at least 1 unanswered email and recent topics
- Prior Notion meeting notes exist with open action items involving this attendee

**Steps**:
1. Run `/meeting:prep [event_id]` for the external client meeting
2. Inspect the meeting type classification
3. Inspect the Discussion Guide section
4. Verify deal context integration

**Expected Results**:
- Meeting classified as `external-client`
- Discussion Guide header shows: "Framework: SPIN (external-client)"
- Talking points structured with SPIN elements:
  - At least 1 Situation point referencing known facts (active deal, project milestones, last interaction date)
  - At least 1 Problem point surfacing blockers or open items as open-ended questions
  - At least 1 Implication point connecting problems to business impact using deal value or timeline data
  - At least 1 Need-payoff point proposing solutions the user can offer
- Deal context included in attendee profile: deal name, stage (Negotiation), value, close date
- Deal stage adjustment applied: talking points focus on terms, timeline, and mutual commitments (per Negotiation stage rules); no new scope introduced
- "Do NOT mention" section present with: competitor pricing and internal cost structures excluded (per active negotiation rules)
- Opener acknowledges the client's time and references a recent milestone
- Proposed next steps include owner (specific names) and deadlines
- Unanswered email from attendee surfaced in "Owed to you" open items section
- Importance score reflects external + deal proximity weighting (expected 4 or 5)

**Acceptance Criteria Covered**: AC-1 (generates prep doc), AC-2 (CRM + email context), AC-3 (open items from prior meetings), AC-4 (SPIN talking points), AC-5 (external meeting)

---

## Scenario 6: One-on-One Meeting (GROW Talking Points)

**Goal**: Verify that a two-person meeting uses the GROW framework with relationship-focused prep.

**Preconditions**:
- `gws` CLI authenticated; calendar contains a meeting with exactly 2 attendees (user + 1 internal colleague)
- Notion CRM configured with the colleague's contact record
- Gmail accessible via gws with email threads to the colleague
- Prior Notion meeting notes from a previous 1:1 with this colleague exist, containing 3 open action items (1 assigned to user, 1 assigned to colleague, 1 shared)

**Steps**:
1. Run `/meeting:prep [event_id]` for the one-on-one meeting
2. Inspect the meeting type classification
3. Inspect the Discussion Guide section
4. Verify open items from prior 1:1 are included

**Expected Results**:
- Meeting classified as `one-on-one`
- Enrichment depth is "Maximum -- deep relationship focus" per classification table
- Discussion Guide header shows: "Framework: GROW (one-on-one)"
- Talking points structured with GROW elements:
  - Goal: References the attendee's objectives or previously stated goals
  - Reality: Includes review of action items from the last 1:1 (which are complete, which are blocked)
  - Options: Explores 2-3 alternative approaches as collaborative brainstorming, not directives
  - Way-forward: Commits to specific next steps with owners and deadlines; at least one concrete commitment from each participant
- Open Items section populated with all 3 prior action items:
  - "You owe" includes the item assigned to user
  - "Owed to you" includes the item assigned to the colleague
  - "Shared/unclear" includes the shared item
- Opener is a genuine check-in question, then transitions to first agenda item
- Attendee profile shows deep relationship data: relationship status, thread count, last interaction, prior meeting dates
- If colleague's relationship status is "Cooling" (30-90 days since last interaction), opener leads with value rather than referencing the gap
- Proposed next steps include at least 1 commitment for each participant

**Acceptance Criteria Covered**: AC-1 (generates prep doc), AC-2 (attendee context), AC-3 (open items from prior 1:1), AC-4 (GROW talking points), AC-5 (internal meeting)

---

## Scenario 7: Internal Sync Meeting (SBI Talking Points)

**Goal**: Verify that an all-internal recurring meeting uses the SBI framework with light prep depth.

**Preconditions**:
- `gws` CLI authenticated; calendar contains a recurring event where all attendees share the user's org domain and there are 4+ attendees
- Meeting has RRULE indicating it is recurring and has occurred 2+ times
- Notion MCP configured with notes from the previous occurrence containing 2 open action items and 1 resolved item

**Steps**:
1. Run `/meeting:prep [event_id]` for the internal sync meeting
2. Inspect the meeting type classification
3. Inspect the enrichment depth
4. Inspect the Discussion Guide section

**Expected Results**:
- Meeting classified as `internal-sync` (all attendees share org domain, recurring, 4+ attendees)
- Enrichment depth is "Light -- agenda + open items only" per classification table
- Discussion Guide header shows: "Framework: SBI (internal-sync)"
- Talking points structured with SBI elements:
  - Situation: States the specific project phase, sprint, or deadline with concrete time and scope
  - Behavior: Describes observable actions or outcomes without judgment language (shipped features, completed tasks, missed deadlines)
  - Impact: Connects behavior to team or project outcomes with quantified downstream effects
- 3-5 talking points generated, each starting with an action verb
- Opener states the time box and 2-3 items to cover, invites additions
- Open Items section includes:
  - 2 open action items carried from previous occurrence
  - "Resolved since last meeting" subsection shows the 1 resolved item with resolution summary
- Related Documents section either populated with relevant docs or omitted if Drive is unavailable (no error)
- Importance score lower than external meetings due to all-internal weighting
- Attendee profiles are lighter (no deep relationship analysis, no deal context)

**Acceptance Criteria Covered**: AC-1 (generates prep doc), AC-3 (open items from prior meeting), AC-4 (SBI talking points), AC-5 (internal meeting)

---

## Scenario 8: Gmail Unavailable -- Graceful Degradation

**Goal**: Verify that the prep document still generates with calendar and Notion sources when Gmail is not accessible via gws, with email-related sections explicitly marked as unavailable.

**Preconditions**:
- Gmail access revoked or unavailable via gws (e.g., scope not authorized)
- `gws` CLI installed with Calendar access working
- Notion MCP configured with CRM contacts matching attendees and prior meeting notes with action items
- Google Drive accessible via gws (optional)

**Steps**:
1. Ensure Gmail is not accessible via gws (revoke Gmail scope or simulate unavailability)
2. Run `/meeting:prep [event_id]`
3. Inspect the generated Notion page and chat output
4. Verify which sections are affected and which are intact

**Expected Results**:
- Warning displayed: "Gmail unavailable via gws -- email history, unanswered items, and sentiment indicators will be empty."
- Pipeline does NOT halt -- prep continues with remaining sources
- Notion page created with all required sections present
- Attendee profiles generated using CRM data only:
  - Thread count shows "No recent email history (90d)" instead of a number
  - Unanswered emails section shows "Gmail not connected -- email history unavailable"
  - Sentiment indicators show "None" (no email data to analyze)
  - Role, company, deals, relationship status still populated from CRM
- Open Items section:
  - "Owed to you" and "You owe" from email are empty (no Gmail data)
  - "Owed to you" and "You owe" from Notion action items are populated
- Recent Context section shows Notion-sourced interactions only, with note: "Email interactions unavailable"
- Discussion Guide and talking points generated based on CRM and Notion data (no email-based sentiment or topic adjustments)
- Sources status shows: Calendar (check) | Gmail (unavailable) | Notion (check) | Drive (status)
- Database row records Gmail as not used in "Sources Used" multi-select
- No stack traces or unhandled errors

**Acceptance Criteria Covered**: AC-1 (generates prep doc with partial data), AC-2 (attendee context from CRM only), AC-3 (open items from Notion), AC-4 (talking points still generated)

---

## Scenario 9: Drive Unavailable -- Skip Silently

**Goal**: Verify that Google Drive absence causes no error and the documents section is simply omitted.

**Preconditions**:
- Google Drive not accessible via gws (scope not authorized or gws not installed)
- `gws` CLI working for Calendar and Gmail
- Notion MCP configured with test data

**Steps**:
1. Ensure Google Drive is not accessible via gws
2. Run `/meeting:prep [event_id]`
3. Run `/meeting:prep [event_id] --team`
4. Inspect both outputs for any Drive-related errors

**Expected Results**:
- Default mode:
  - No error or warning message about Google Drive displayed to the user
  - Relevant Documents section omitted entirely from the Notion page (or shows "Drive not connected -- document search skipped")
  - All other sections (attendees, open items, agenda, talking points) populated normally from Calendar, Gmail, and Notion
  - Sources status shows: Calendar (check) | Gmail (check) | Notion (check) | Drive (unavailable)
- Team mode:
  - Drive Agent returns immediately with status "unavailable" in the pipeline execution table
  - Drive Agent does not timeout (returns immediately)
  - Pipeline continues without error -- minimum 2 gatherers satisfied (Calendar + Gmail + Notion)
  - Pipeline summary row for Drive Agent shows status "unavailable", duration near 0, items "0 documents"
  - Prep Lead synthesizes output from the 3 available gatherers without referencing missing Drive data
- Database row does not include "Drive" in Sources Used multi-select
- Prep document quality is unaffected by Drive absence -- all other sections fully populated
- No stack traces, no warnings, no degradation notices for Drive

**Acceptance Criteria Covered**: AC-1 (generates prep doc without Drive)

---

## Scenario 10: Duplicate Prevention -- Re-Run Updates Existing

**Goal**: Verify that running prep twice for the same event updates the existing Notion entry and page instead of creating duplicates.

**Preconditions**:
- All MCP servers configured
- A prep document already generated for a specific event_id (run `/meeting:prep [event_id]` first)
- "[FOS] Meetings" database exists with a row for this event
- Notion page "Meeting Prep: [Event Title] -- [YYYY-MM-DD]" exists

**Steps**:
1. Run `/meeting:prep [event_id]` to generate the initial prep (note the Notion page URL and database row)
2. Wait a few minutes, then run `/meeting:prep [event_id]` again for the same event
3. Check the Notion workspace for the database and prep page
4. Compare the page content and database row between runs

**Expected Results**:
- Second run output includes note: "Updating existing meeting record for [Event Title]."
- The existing Notion page is updated in place (same URL, same page ID)
- No second page titled "Meeting Prep: [Event Title] -- [YYYY-MM-DD]" is created
- The "[FOS] Meetings" database contains exactly one row for this event_id (not two)
- Database row's "Generated At" timestamp is updated to the second run time
- Database row metrics are refreshed (sources used, importance score, meeting type may be recomputed)
- Notion page content reflects the latest data from all sources (any new emails, updated CRM data, or new action items since the first run are included)
- No orphaned pages or database entries

**Acceptance Criteria Covered**: AC-1 (generates prep doc -- no duplicate creation)

---

## Scenario 10b: Cross-Plugin Deduplication -- P07 Record Already Exists

**Goal**: Verify that when P07 Meeting Intelligence Hub has already created a record for a meeting (same Event ID), P03 updates that record with prep fields instead of creating a duplicate.

**Preconditions**:
- "[FOS] Meetings" database exists
- A row already exists for a specific Event ID, created by P07 (has Summary, Decisions, Follow-Ups, Topics, Source Type, Transcript File, Duration populated)
- The P07 row's P03-specific fields (Prep Notes, Talking Points, Importance Score, Sources Used) are empty

**Steps**:
1. Run `/meeting:prep [event_id]` for the event that P07 already processed
2. Inspect the database row
3. Verify both P03 and P07 fields are populated on the same record

**Expected Results**:
- Output includes note: "Updating existing meeting record for [Event Title]."
- Database still contains exactly one row for this Event ID
- P03-owned fields now populated: Prep Notes, Talking Points, Importance Score, Sources Used, Meeting Type, Attendees
- P07-owned fields preserved (not overwritten or cleared): Summary, Decisions, Follow-Ups, Topics, Source Type, Transcript File, Duration
- Company relation set if external attendee matched in CRM
- Generated At timestamp updated to reflect the latest write

**Acceptance Criteria Covered**: AC-1 (cross-plugin merge via shared Event ID)

---

## Scenario 11: Large Meeting -- 10+ Attendees

**Goal**: Verify that meetings with many attendees correctly profile the top 5 and list the rest as "Also attending".

**Preconditions**:
- `gws` CLI authenticated; calendar contains an event with 12 attendees:
  - 2 external client contacts (VP and Manager)
  - 3 internal colleagues with CRM records
  - 7 additional attendees (mix of internal and external, varying data availability)
- Notion CRM configured with contact records for at least 5 of the attendees
- Gmail accessible via gws with email threads to at least 4 attendees

**Steps**:
1. Run `/meeting:prep [event_id]` for the 12-attendee meeting
2. Inspect the Attendees section of the generated prep
3. Verify the profiling prioritization logic
4. Verify open items are still compiled for all 12 attendees

**Expected Results**:
- Attendees section header shows "Attendees (12)"
- Top 5 attendees receive full profile cards with: name, RSVP, role/company, relationship status, last contact, pending items, active deals, prior meetings
- Top 5 selection prioritized per the meeting-context skill: external attendees first, then those with active deals, then most recent interactions, then organizer
  - External VP should be profiled first
  - External Manager should be profiled second
  - Remaining 3 slots filled by internal colleagues with most relevant data
- Remaining 7 attendees listed as: "Also attending: [name1], [name2], [name3], [name4], [name5], [name6], [name7]" with name/email/RSVP only (no full profile)
- Open Items section compiled for ALL 12 attendees (not just the top 5)
- Discussion Guide talking points may reference attendees in the "Also attending" list if they have relevant pending items
- Meeting type classified as `group-meeting` (4+ attendees) or `external-client` (if external attendees in CRM)
- If 50%+ of attendees have no CRM or email context, framework switches to Contribution Mapping per the edge case rule
- Database row records all 12 attendee names in the Attendees property (comma-separated)

**Acceptance Criteria Covered**: AC-1 (generates prep doc), AC-2 (attendee context with prioritized profiling), AC-3 (open items for all attendees), AC-4 (talking points)

---

## Scenario 12: Notion Unavailable -- Halt with Clear Error

**Goal**: Verify that missing Notion MCP causes an immediate halt with a clear error message pointing to INSTALL.md.

**Preconditions**:
- Notion MCP disabled (unset NOTION_API_KEY or remove from mcp.json)
- `gws` CLI authenticated for Calendar and Gmail

**Steps**:
1. Disable Notion MCP
2. Run `/meeting:prep [event_id]`
3. Run `/meeting:prep [event_id] --team`
4. Run `/meeting:prep` (no args, interactive mode)
5. Observe error output for each invocation

**Expected Results**:
- All three invocations halt immediately with clear error message
- Error message: "Notion MCP is required for meeting prep output and CRM context. See `[INSTALL.md path]` for setup instructions."
- The error references the plugin's INSTALL.md file path using `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`
- No data fetched from Calendar or Gmail via gws (no wasted API calls)
- No partial processing attempted -- no event lookup, no attendee resolution, no email search
- No Notion page creation attempted (which would fail anyway)
- No database row creation attempted
- Clean exit with no stack traces or unhandled exceptions
- In `--team` mode, no agents are launched (pipeline halted before agent dispatch)
- In interactive mode, the meeting list is NOT shown (halt before calendar fetch)

**Acceptance Criteria Covered**: AC-1 (error handling -- Notion required for output and CRM context)

---

## Scenario 13: No Meetings Database Found -- Graceful Fallback

**Goal**: Verify that when Notion MCP is available but neither "[FOS] Meetings" nor "Meeting Prep Autopilot - Prep Notes" database exists, the plugin warns and outputs to chat without creating a database.

**Preconditions**:
- Notion MCP configured and connected
- No "[FOS] Meetings" database exists
- No "Meeting Prep Autopilot - Prep Notes" database exists
- `gws` CLI authenticated with a test calendar event

**Steps**:
1. Run `/meeting:prep [event_id]`
2. Observe the output

**Expected Results**:
- Warning: "No Meetings database found in Notion. Prep will be displayed in chat only."
- Full prep document generated and displayed in chat
- No database lazy-created (plugin does not create "[FOS] Meetings")
- CRM context still gathered from Notion (contacts, notes, action items)
- Pipeline completes successfully with chat output only

**Acceptance Criteria Covered**: AC-1 (generates prep doc with graceful DB fallback)

---

## Summary Matrix

| Scenario | Command | Acceptance Criteria | MCP Required |
|----------|---------|---------------------|--------------|
| 1. Basic Single-Agent Prep | `/meeting:prep [event_id]` | AC-1, AC-2, AC-3, AC-4 | gws (Calendar, Gmail, Drive), Notion |
| 2. Full --team Pipeline | `/meeting:prep [event_id] --team` | AC-1, AC-2, AC-3, AC-4, AC-5 | gws (Calendar, Gmail, Drive), Notion |
| 3. No event_id Selection | `/meeting:prep` | AC-1 | gws (Calendar), Notion |
| 4. prep-today Bulk | `/meeting:prep-today --yes` | AC-1, AC-2, AC-3, AC-4, AC-5 | gws (Calendar, Gmail), Notion |
| 5. External Client (SPIN) | `/meeting:prep [event_id]` | AC-1, AC-2, AC-3, AC-4, AC-5 | gws (Calendar, Gmail), Notion |
| 6. One-on-One (GROW) | `/meeting:prep [event_id]` | AC-1, AC-2, AC-3, AC-4, AC-5 | gws (Calendar, Gmail), Notion |
| 7. Internal Sync (SBI) | `/meeting:prep [event_id]` | AC-1, AC-3, AC-4, AC-5 | gws (Calendar), Notion |
| 8. Gmail Unavailable | `/meeting:prep [event_id]` | AC-1, AC-2, AC-3, AC-4 | gws (Calendar), Notion |
| 9. Drive Unavailable | `/meeting:prep [event_id]`, `--team` | AC-1 | gws (Calendar, Gmail), Notion |
| 10. Duplicate Prevention | `/meeting:prep [event_id]` (re-run) | AC-1 | gws (Calendar, Gmail), Notion |
| 10b. Cross-Plugin Dedup | `/meeting:prep [event_id]` (P07 exists) | AC-1 | gws (Calendar, Gmail), Notion |
| 11. Large Meeting (10+) | `/meeting:prep [event_id]` | AC-1, AC-2, AC-3, AC-4 | gws (Calendar, Gmail), Notion |
| 12. Notion Unavailable | `/meeting:prep [event_id]`, `--team` | AC-1 | gws (Calendar, Gmail) |
| 13. No Meetings DB | `/meeting:prep [event_id]` | AC-1 | gws (Calendar, Gmail), Notion |
