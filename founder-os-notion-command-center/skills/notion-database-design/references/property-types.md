# Notion Property Types Reference

Complete reference for all Notion database property types, their configuration options, and usage patterns.

---

## Core Property Types

### Title

The primary identifier for database entries. Every database must have exactly one Title property.

- **Default name**: "Name"
- **Stores**: Rich text (supports bold, italic, links, mentions)
- **Searchable**: Yes — Notion search prioritizes title matches
- **Sortable**: Yes — alphabetical sorting
- **Filterable**: Yes — contains, does not contain, is empty, is not empty

**Best practices:**
- Name it after the entity: "Task" for a task tracker, "Contact" for CRM, "Article" for a wiki.
- Keep titles concise — they appear in board cards, relation links, and search results.

### Rich Text

Free-form text field for descriptions, notes, and detailed content.

- **Stores**: Rich text with inline formatting
- **Max length**: No hard limit, but long text is truncated in table views
- **Filterable**: contains, does not contain, is empty, is not empty
- **Sortable**: Yes — alphabetical

**Best practices:**
- Use for fields that need multi-sentence content: "Description", "Notes", "Details".
- For short single-value text, consider URL or Email type instead if the content is always that format.

### Number

Numeric values with optional formatting.

- **Format options**: Number, Number with commas, Percent, Dollar ($), Euro (€), Pound (£), Yen (¥), and more
- **Filterable**: equals, does not equal, greater than, less than, between, is empty
- **Sortable**: Yes — numeric ordering
- **Supports formulas**: Can be used in Formula and Rollup properties

**Configuration:**
```json
{
  "type": "number",
  "number": {
    "format": "dollar"  // or "number", "percent", "euro", etc.
  }
}
```

### Select

Single-choice dropdown. One value per entry.

- **Max options**: No hard limit, but keep under 20 for usability
- **Option colors**: Notion assigns colors automatically; can be specified in API
- **Filterable**: equals, does not equal, is empty
- **Sortable**: Yes — by option order

**Common patterns:**
- Priority: High, Medium, Low
- Type: Bug, Feature, Task, Improvement
- Phase: Planning, In Progress, Review, Complete
- Category: Marketing, Engineering, Sales, Support

**Configuration:**
```json
{
  "type": "select",
  "select": {
    "options": [
      {"name": "High", "color": "red"},
      {"name": "Medium", "color": "yellow"},
      {"name": "Low", "color": "green"}
    ]
  }
}
```

### Multi-Select

Multiple-choice tags. Zero or more values per entry.

- **Same configuration as Select** but allows multiple selections
- **Filterable**: contains, does not contain, is empty
- **Best for**: Tags, skills, departments, labels

**Common patterns:**
- Tags: Marketing, Engineering, Design, Product
- Skills: Python, JavaScript, SQL, React
- Departments: Sales, Support, Engineering, Marketing

### Status

Specialized workflow property with three groups: To Do, In Progress, Done.

- **Groups**: To Do (not started), In Progress (active), Done (complete)
- **Filterable**: equals, does not equal, is empty
- **Sortable**: Yes — by group order
- **Special behavior**: Notion uses Status for kanban board grouping

**Default options:**
- To Do group: "Not started"
- In Progress group: "In progress"
- Done group: "Done"

**Custom options per group:**
```json
{
  "type": "status",
  "status": {
    "options": [
      {"name": "Backlog", "color": "default"},
      {"name": "To Do", "color": "blue"},
      {"name": "In Progress", "color": "yellow"},
      {"name": "In Review", "color": "orange"},
      {"name": "Done", "color": "green"},
      {"name": "Canceled", "color": "red"}
    ],
    "groups": [
      {"name": "To Do", "option_ids": ["backlog_id", "todo_id"]},
      {"name": "In Progress", "option_ids": ["progress_id", "review_id"]},
      {"name": "Done", "option_ids": ["done_id", "canceled_id"]}
    ]
  }
}
```

### Date

Calendar date with optional time and end date.

- **Supports**: Start date, optional end date, optional time
- **Filterable**: is, before, after, between, is empty
- **Sortable**: Yes — chronological
- **Special**: Powers Calendar view

**Configuration:**
```json
{
  "type": "date",
  "date": {
    "start": "2026-03-15",
    "end": "2026-03-20",
    "time_zone": "America/New_York"
  }
}
```

### Checkbox

Boolean true/false toggle.

- **Filterable**: equals (checked/unchecked)
- **Sortable**: Yes — unchecked before checked (or reverse)
- **Best for**: Binary states: Active, Published, Approved, Paid

### URL

Web address field with clickable link.

- **Filterable**: contains, does not contain, is empty
- **Renders as**: Clickable link in Notion
- **Best for**: Website, Resource URL, Documentation Link

### Email

Email address field with mailto: link.

- **Filterable**: contains, does not contain, is empty
- **Renders as**: Clickable mailto: link
- **Best for**: Contact Email, Notification Email

### Phone

Phone number field.

- **Filterable**: contains, does not contain, is empty
- **Stores**: String (accepts any format)
- **Best for**: Phone Number, Mobile, Office Phone

### People

Reference to Notion workspace members.

- **Filterable**: contains, does not contain, is empty
- **Sortable**: Yes — alphabetical by name
- **Best for**: Assignee, Owner, Reviewer, Created By
- **Note**: Only workspace members can be assigned. External contacts should use Rich Text or Email.

### Files

File attachment field.

- **Accepts**: Files uploaded to Notion or external URLs
- **Filterable**: is empty, is not empty
- **Best for**: Attachments, Documents, Images, Deliverables

---

## Advanced Property Types

### Relation

Links entries between two databases.

- **Configuration**: Specify the related database ID
- **Bidirectional**: Creates a corresponding relation property in the target database
- **Best for**: Linking Tasks to Projects, Contacts to Companies, Notes to Meetings

**Important**: Both databases must exist before creating a relation. Create the target database first if it doesn't exist.

### Rollup

Aggregates values from a related database via a Relation property.

- **Requires**: An existing Relation property
- **Aggregation types**: Count, Sum, Average, Min, Max, Percent checked, and more
- **Best for**: Task Count per Project, Total Hours, Average Score

### Formula

Computed value based on other properties.

- **Syntax**: Notion formula language (similar to spreadsheet formulas)
- **Examples**:
  - Days until due: `dateBetween(prop("Due Date"), now(), "days")`
  - Full name: `prop("First Name") + " " + prop("Last Name")`
  - Overdue flag: `if(prop("Due Date") < now() and prop("Status") != "Done", true, false)`

### Created Time / Created By / Last Edited Time / Last Edited By

Auto-populated audit properties. Cannot be manually set.

- **Created Time**: Set once when entry is created
- **Created By**: Person who created the entry
- **Last Edited Time**: Updated on every edit
- **Last Edited By**: Person who last edited

**Best for**: Audit trails, sorting by recency, tracking authorship.

---

## Property Design Patterns

### The Minimal Schema

For simple tracking needs, start with the fewest properties possible:

```
Title + Status = task tracker
Title + Date = event list
Title + Checkbox = checklist
Title + Select = categorized list
```

Add properties only when the user needs them for filtering, sorting, or reporting.

### The Standard Task Tracker

Most task trackers share this core:

```
Task (Title), Status, Priority (Select), Due Date, Assignee (People), Tags (Multi-select), Notes (Rich text)
```

### The Standard CRM

Contact databases typically need:

```
Name (Title), Company (Rich text), Email, Phone, Status (Select), Tags (Multi-select), Last Contact (Date), Notes (Rich text)
```

### Select vs Multi-Select Decision

- **Use Select** when exactly one value applies per entry (Priority: can only be one)
- **Use Multi-select** when entries can have multiple values (Tags: can have many)
- **Rule of thumb**: "Is this X?" → Select. "Which Xs apply?" → Multi-select.
