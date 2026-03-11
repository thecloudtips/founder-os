# Integration Test Plan: Notion Command Center (P17)

## Test Environment

- Notion workspace with test pages and databases
- Notion integration with full permissions (read, update, insert)
- `NOTION_API_KEY` configured
- Notion MCP server running

---

## Acceptance Criteria Tests

### AC1: `/notion:create [description]` creates page/DB

**Scenario 1.1: Create a page at workspace root**
```
/notion:create A project brief for the mobile app redesign
```
- Expected: Page created titled "Mobile App Redesign Project Brief"
- Verify: Page appears in Notion, accessible via returned URL

**Scenario 1.2: Create a page under a parent**
```
/notion:create Meeting notes for the standup --parent="Team Wiki"
```
- Expected: Page created under "Team Wiki"
- Verify: Page hierarchy correct in Notion

**Scenario 1.3: Create a database with auto-detection**
```
/notion:create A task tracker with status, priority, assignee, and due date
```
- Expected: Auto-detects database intent, presents schema for confirmation
- Verify: Database created with correct properties and types

**Scenario 1.4: Create a database with explicit type**
```
/notion:create --type=database A contact list with name, email, company, and phone
```
- Expected: Database schema presented, creates on confirmation
- Verify: All properties match the description

**Scenario 1.5: Ambiguous intent**
```
/notion:create A list of project milestones
```
- Expected: Asks user to clarify page vs database
- Verify: Creates the chosen type correctly

### AC2: `/notion:query [question]` searches and answers

**Scenario 2.1: Page search**
```
/notion:query Find the onboarding guide
```
- Expected: Returns ranked list of matching pages with previews
- Verify: Results include title, preview, last edited, URL

**Scenario 2.2: Database query with filter**
```
/notion:query What are my overdue tasks? --db="Project Tracker"
```
- Expected: Filters by Due Date < today AND Status != Done
- Verify: Results are formatted cards with relevant properties

**Scenario 2.3: Database query with sort**
```
/notion:query Show me the latest content --db="Content Calendar" --limit=5
```
- Expected: Sorted by date descending, limited to 5 results
- Verify: Results in correct order

**Scenario 2.4: Count/aggregation query**
```
/notion:query How many open tasks do we have? --db="Project Tracker"
```
- Expected: Returns count plus sample results
- Verify: Count matches Notion reality

**Scenario 2.5: Empty results**
```
/notion:query Find pages about quantum computing
```
- Expected: "No results found" with suggestions for broader terms
- Verify: Helpful suggestions provided

### AC3: `/notion:update [page] [changes]` modifies content

**Scenario 3.1: Property update**
```
/notion:update "Project Alpha" set status to Done
```
- Expected: Shows before/after, applies on confirmation
- Verify: Status changed in Notion

**Scenario 3.2: Multi-property update**
```
/notion:update "Q2 Plan" change priority to High and assign to Sarah
```
- Expected: Both properties shown in confirmation table
- Verify: Both properties updated in Notion

**Scenario 3.3: Content append**
```
/notion:update "Meeting Notes" --append ## Action Items\n- Review budget
```
- Expected: Shows content preview, appends on confirmation
- Verify: Content appended with divider in Notion

**Scenario 3.4: Update by URL**
```
/notion:update https://notion.so/abc123 mark as complete
```
- Expected: Fetches page directly, updates status
- Verify: Page updated in Notion

**Scenario 3.5: Disambiguation**
```
/notion:update "Meeting Notes" set status to Done
```
- Expected: If multiple "Meeting Notes" pages exist, presents numbered list
- Verify: User can pick and correct page is updated

### AC4: Natural language to Notion API translation

**Scenario 4.1: Date parsing**
```
/notion:update "Task X" set due date to next Friday
```
- Expected: Correctly parses "next Friday" to ISO date
- Verify: Date property shows correct date in Notion

**Scenario 4.2: Status mapping**
```
/notion:update "Task Y" mark as finished
```
- Expected: Maps "finished" to "Done" status
- Verify: Status property is "Done" in Notion

**Scenario 4.3: NL-to-filter translation**
```
/notion:query Show me high priority items assigned to Sarah --db="Tasks"
```
- Expected: Translates to Priority=High AND Assignee contains Sarah
- Verify: Only matching results returned

**Scenario 4.4: Schema translation**
```
/notion:create A bug tracker with severity, steps to reproduce, assigned developer, and fix date
```
- Expected: Maps to Select (severity), Rich text (steps), People (developer), Date (fix date)
- Verify: Schema types are semantically correct

### AC5: Handles databases, pages, and blocks

**Scenario 5.1: Database operations**
```
/notion:template "Project Tracker" --parent="Workspace"
```
- Expected: Creates database with full schema (10 properties)
- Verify: All properties, types, and options correct

**Scenario 5.2: Page with blocks**
```
/notion:create A weekly report with headings for Summary, Accomplishments, and Next Week
```
- Expected: Page with heading_2 blocks for each section
- Verify: Block types correct in Notion

**Scenario 5.3: Mixed content blocks**
```
/notion:update "Project Brief" --append ## Risks\n- Budget overrun\n- Timeline slip\n\n> Important: Discuss at next meeting
```
- Expected: Creates heading, bulleted list items, and quote blocks
- Verify: Block types render correctly in Notion

---

## Edge Case Tests

### EC1: Notion MCP unavailable

**Test:** Disconnect Notion MCP server, run any command.
- Expected: Clear error message directing to INSTALL.md
- Verify: No partial operations attempted

### EC2: Ambiguous page names

**Test:** Create two pages named "Meeting Notes", then run:
```
/notion:update "Meeting Notes" set status to Done
```
- Expected: Disambiguation list showing both pages with parent and date context
- Verify: User can select the correct one

### EC3: Empty workspace

**Test:** Use an integration with access to an empty workspace.
```
/notion:query What pages do I have?
```
- Expected: "No pages found" with suggestion to share pages with the integration
- Verify: No errors thrown

### EC4: Large database query

**Test:** Query a database with 500+ entries:
```
/notion:query Show all items --db="Large Database" --limit=20
```
- Expected: Returns 20 results with total count noted
- Verify: Results display within reasonable time

### EC5: Template deployment

**Test:** Deploy each of the 5 templates:
```
/notion:template CRM Contacts
/notion:template Project Tracker
/notion:template Content Calendar
/notion:template Meeting Notes
/notion:template Knowledge Wiki
```
- Expected: Each creates a database with the correct property count and types
- Verify: Property names, types, and options match `references/templates.md`

### EC6: Permission errors

**Test:** Try to update a page not shared with the integration.
- Expected: Clear permission error with suggestion to share the page
- Verify: No data corruption

### EC7: Invalid property updates

**Test:** Try to set a date property to a non-date value:
```
/notion:update "Task X" set due date to banana
```
- Expected: Reports that "banana" is not a valid date, suggests correct format
- Verify: No partial update applied

### EC8: Unknown template name

**Test:**
```
/notion:template "Inventory Manager"
```
- Expected: "Unknown template" message with list of available templates
- Verify: No database created

---

## Test Matrix

| Command | Happy Path | No Results | Permission Error | MCP Down |
|---------|-----------|------------|-----------------|----------|
| `/notion:create` | 1.1-1.4 | N/A | EC6 | EC1 |
| `/notion:query` | 2.1-2.4 | 2.5, EC3 | EC6 | EC1 |
| `/notion:update` | 3.1-3.4 | 3.5 | EC6 | EC1 |
| `/notion:template` | 5.1, EC5 | EC8 | EC6 | EC1 |
