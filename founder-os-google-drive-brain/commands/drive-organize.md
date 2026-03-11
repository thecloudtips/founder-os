---
description: Suggest folder structure and organizational improvements (recommend-only)
argument-hint: "[folder-id-or-name] [--strategy=project|date|type]"
allowed-tools: ["Read"]
---

# Drive Organize

Analyze a Google Drive folder's contents and suggest organizational improvements. CRITICAL: This command is recommend-only. Never execute file moves, renames, or folder creation. Only present suggestions for the user to act on manually.

## Load Skills

Read the drive-navigation skill at `${CLAUDE_PLUGIN_ROOT}/skills/drive-navigation/SKILL.md` for folder traversal, file type detection, and breadcrumb path generation.

## Parse Arguments

Extract from `$ARGUMENTS`:
- `[folder-id-or-name]` (required) -- Drive folder ID or name. If a name, search for matching folders. If multiple matches, present disambiguation list with breadcrumb paths. If missing, prompt: "Which Drive folder would you like to organize? Provide a folder name or ID." and stop.
- `--strategy=STRATEGY` (optional) -- organization strategy. Accepts: `project`, `date`, `type`. Default: `project`.
  - `project` -- group files by topic/project (analyze filenames and content for natural groupings).
  - `date` -- group files by year/month based on last modified dates.
  - `type` -- group files by file type (Documents, Spreadsheets, Presentations, PDFs, Other).

## Business Context (Optional)
Check if context files exist at `_infrastructure/context/active/`. If the directory contains `.md` files, read `business-info.md`, `strategy.md`, and `current-data.md`. Use this context to personalize output (e.g., prioritize known clients, use correct terminology, align with current strategy). If files don't exist, skip silently.

## Step 0: Memory Context
Read the context-injection skill at `_infrastructure/memory/context-injection/SKILL.md`.
Query for memories relevant to the current input (company, contacts, topics detected in arguments).
If memories are returned, incorporate them into your working context for this execution.

## Step 1: Resolve Folder

1. If input is a folder ID (alphanumeric string without spaces): fetch folder metadata (name, path, file count).
2. If input is a name: search Drive for folders with that name. If multiple matches, show a numbered disambiguation list with parent breadcrumb path and item count for each. Wait for user selection.
3. Verify the resolved item is a folder, not a file. If it is a file, report: "'[name]' is a file, not a folder. Provide a folder name or ID." and stop.

## Step 2: Scan Folder Contents

1. List all files in the folder (first level only, not recursive).
2. List any subfolders and their file counts.
3. For each file, capture: filename, file type (MIME type), last modified date, size if available.
4. If the folder contains more than 50 items, note the total count and analyze only the first 50 for pattern detection. Report: "Analyzing first 50 of [N] items."
5. Record the current folder structure (existing subfolders and their names).

## Step 3: Analyze Patterns

Apply the analysis strategy based on `--strategy`:

### Project Strategy (default)

1. Extract topic signals from filenames: company names, project names, common prefixes, shared keywords, date patterns.
2. Group files that share topic signals. A file belongs to the group whose signal it matches most strongly. A file can belong to only one group.
3. Name each suggested folder after the detected topic (e.g., "Project Phoenix", "Client - Acme Corp", "Marketing Assets").
4. Place ungrouped files (those matching no detected topic) in a "Miscellaneous" suggestion.

### Date Strategy

1. Group files by year, then by month within each year.
2. Suggested folder structure: `YYYY/` -> `MM-MonthName/` (e.g., `2026/` -> `01-January/`, `02-February/`).
3. Files with unknown or unavailable modified dates go to an "Unsorted" suggestion.

### Type Strategy

1. Group files by Google Drive file type.
2. Suggested folders: "Documents", "Spreadsheets", "Presentations", "PDFs", "Images", "Other".
3. Map MIME types to folder names: Google Docs -> "Documents", Google Sheets -> "Spreadsheets", Google Slides -> "Presentations", PDF -> "PDFs", image/* -> "Images", everything else -> "Other".
4. If any single type folder would contain more than 10 files, sub-group within that folder by topic signal (same approach as project strategy).

## Step 4: Generate Recommendations

For each suggested group, produce:
1. **Suggested folder name** -- clear, descriptive name.
2. **Files to move** -- list of filenames with their current location.
3. **Brief rationale** -- why these files belong together (e.g., "3 files share the 'Phoenix' project name").

Also generate these cross-cutting observations:

**Naming Consistency Suggestions**: Detect inconsistent naming patterns across files in the folder (e.g., "report_Q1" vs "Q1-Report" vs "q1 report"). Suggest a consistent convention.

**Duplicate Detection**: Flag files with very similar names (Levenshtein distance <= 3) or identical file sizes within the same type. Report as potential duplicates, not confirmed duplicates.

**Stale File Flags**: Flag files not modified in more than 180 days. Include the last modified date for each.

## SAFETY: Recommend-Only

**NEVER execute any of the following actions:**
- Move files
- Rename files
- Create folders
- Delete files
- Modify file permissions

Present all suggestions as a recommended structure. The user will manually implement the changes they agree with. This constraint is non-negotiable.

## Step 5: Notion Logging (Optional)

If Notion MCP is available:
1. Search for a database titled "[FOS] Activity Log". If not found, try "Founder OS HQ - Activity Log". If not found, fall back to "Google Drive Brain - Activity".
2. If none is found, skip Notion logging silently and proceed with user-facing output. Do not create the database. If found, log with these properties:
   - Query (title) -- the folder name
   - Command Type (select: search, summarize, ask, organize) -- set to "organize"
   - Files Found (number) -- file count in the folder
   - Top Result (rich_text) -- empty for organize commands
   - File IDs (rich_text) -- empty for organize commands
   - Folder Context (rich_text) -- folder breadcrumb path
   - Sources Used (multi_select: Google Drive, Notion) -- set to "Google Drive"
   - Company (relation) -- if the folder path or name matches a known client from [FOS] Companies, set the Company relation to that record. See drive-navigation skill's Company Detection rules.
   - Generated At (date) -- current timestamp
3. Log: Command Type=organize, Query=folder name, Files Found=file count, Folder Context=folder breadcrumb path, Generated At=now.
4. If any step fails, continue silently. Notion logging must never block the user-facing output.

If Notion MCP is not available, skip this step entirely without any message.

## Step 6: Output

Display the results in this exact format:

```
## Drive Organize: [Folder Name]

**Strategy**: [project|date|type] | **Files analyzed**: [count] | **Subfolders found**: [count]

**Current structure:**
```
[Folder Name]/
├── file1.docx
├── file2.pdf
├── Subfolder A/
│   └── file3.xlsx
└── ...
```

---

### Recommended Structure

```
[Folder Name]/
├── [Suggested Folder 1]/          <- 4 files
│   ├── file-a.docx
│   ├── file-b.pdf
│   ├── file-c.docx
│   └── file-d.xlsx
├── [Suggested Folder 2]/          <- 3 files
│   ├── file-e.pdf
│   └── ...
└── Miscellaneous/                 <- 2 files
    └── ...
```

### Move Suggestions

| File | Current Location | Suggested Location | Reason |
|------|-----------------|-------------------|--------|
| file-a.docx | / | [Suggested Folder 1]/ | Shares "Phoenix" project name |
| ... | ... | ... | ... |

### Additional Observations

**Naming Inconsistencies:**
- [observation with suggested convention]

**Potential Duplicates:**
- [file1] and [file2] may be duplicates (similar names, identical size)

**Stale Files (>180 days):**
- [file] -- last modified [YYYY-MM-DD]

---

> These are recommendations only. No files have been moved or modified.

*Organized by Google Drive Brain*
```

If there are no observations for a subsection (e.g., no naming inconsistencies), omit that subsection entirely. Do not show empty sections.

## Graceful Degradation

**Google gws CLI (Drive) unavailable**: Stop execution immediately. Display:
"gws CLI (`gws drive`) is not connected. Install it per `${CLAUDE_PLUGIN_ROOT}/INSTALL.md`:
1. Set `GOOGLE_CREDENTIALS_PATH` and `GOOGLE_TOKEN_PATH` environment variables
2. Restart Claude Code and run `/drive:organize` again"

**Folder not found**: "No folder found matching '[input]'. Check the folder name or use a folder ID."

**Empty folder**: "The folder '[name]' is empty. Nothing to organize."

**Permission denied**: "Unable to list contents of '[name]'. Check sharing permissions."

**Notion MCP unavailable**: Skip logging silently. Do not mention Notion in the output.

**Partial failures**: If folder metadata loads but some file metadata fails, continue with the files that were successfully retrieved. Do not stop for individual file errors.

## Final: Memory Update
Read the pattern-detection skill at `_infrastructure/memory/pattern-detection/SKILL.md`.
Log this execution as an observation with: plugin name, primary action performed, key entities (companies, contacts), and output summary.
Check for emerging patterns per the detection rules. If a memory reaches the adaptation threshold, append the notification to the output.

## Usage Examples

```
/drive:organize "Client Projects"
/drive:organize "Shared Documents" --strategy=date
/drive:organize 1abc2def3ghi --strategy=type
/drive:organize "Marketing" --strategy=project
```
