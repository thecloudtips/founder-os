# Quick Start: Google Drive Brain

> Searches, summarizes, and answers questions from Google Drive documents with optional Notion activity tracking.

**Plugin #18** | **Pillar**: MCP & Integrations | **Platform**: Claude Code

### What This Plugin Does

- Searches your entire Google Drive with relevance-scored results and preview snippets
- Summarizes documents (Docs, Sheets, PDFs) in concise or detailed mode
- Answers questions with inline citations sourced from Drive documents
- Suggests folder organization improvements without moving any files

### Time Savings

Estimated **10-20 minutes** per lookup session compared to manually navigating Drive folders, opening files, and reading through documents.

## Available Commands

| Command | Description |
|---------|-------------|
| `/drive:search [query]` | Search Drive with preview snippets |
| `/drive:summarize [file]` | Generate a document summary |
| `/drive:ask [question]` | Answer questions with citations |
| `/drive:organize [folder]` | Suggest folder improvements (recommend-only) |

## Usage Examples

### Example 1: Search for Documents

```
/drive:search quarterly report
```

**What happens:** Searches your entire Google Drive for files matching "quarterly report". Returns relevance-scored results with file name, type, location, last modified date, and a preview snippet from each matching file.

### Example 2: Search with Filters

```
/drive:search budget --type=sheets --in="Finance"
```

**What happens:** Searches only Google Sheets within the "Finance" folder for files matching "budget". The `--type` flag filters by file type (docs, sheets, slides, pdf) and `--in` scopes the search to a specific folder. Returns filtered, relevance-scored results.

### Example 3: Summarize a Document

```
/drive:summarize "Q1 Revenue Report"
```

**What happens:** Finds the document titled "Q1 Revenue Report" in Drive, extracts its content, and generates a concise summary highlighting key figures, trends, and takeaways. Outputs the summary to chat.

### Example 4: Detailed Summary Saved to File

```
/drive:summarize "Project SOW" --depth=detailed --output=./summary.md
```

**What happens:** Generates a comprehensive, section-by-section summary of the "Project SOW" document. The `--depth=detailed` flag produces a longer summary covering scope, deliverables, timeline, and pricing. The `--output` flag saves the summary to a local markdown file instead of only displaying it in chat.

### Example 5: Ask a Question

```
/drive:ask What is our refund policy?
```

**What happens:** Searches Drive for documents containing refund policy information, extracts relevant passages from matching files, and synthesizes an answer with inline citations [1][2] pointing back to the source documents. Shows confidence level based on source agreement and match strength.

### Example 6: Ask Scoped to a Folder

```
/drive:ask How much is the Q2 budget? --in="Finance"
```

**What happens:** Restricts the document search to the "Finance" folder, finds budget-related documents, and answers the question with cited sources. Use `--in` when you know which folder contains the relevant files to get faster, more precise answers.

### Example 7: Organize a Folder

```
/drive:organize "Client Projects" --strategy=project
```

**What happens:** Analyzes the structure and contents of the "Client Projects" folder. Identifies organizational issues like inconsistent naming, misplaced files, or missing subfolders. Produces a set of recommendations for improving the folder structure using a project-based strategy. This command is recommend-only -- it never moves, renames, or deletes any files.

## Tips

- Use `--type` to filter search results by file type: `docs`, `sheets`, `slides`, `pdf`
- Use `--in="Folder Name"` to scope searches and questions to a specific folder for faster, more relevant results
- Use `--depth=detailed` with `/drive:summarize` for comprehensive section-by-section summaries instead of the default concise mode
- `/drive:organize` is always recommend-only -- it analyzes and suggests but never moves or modifies files
- All commands work without Notion configured; Notion is used only for optional activity logging
- If you share Google Drive folders with specific Google accounts, make sure you authenticate with the account that has access

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No search results | Check that the authenticated Google account has access to the files. Try broader search terms. |
| "gws CLI (`gws drive`) is not connected" | Verify `GOOGLE_CREDENTIALS_PATH` and `GOOGLE_TOKEN_PATH` environment variables are set correctly. See INSTALL.md. |
| Document summary is empty | The file may be a format the plugin cannot extract content from. Docs, Sheets, and PDFs are supported. |
| Low confidence answers | Try scoping with `--in` to target the right folder, or ask a more specific question. |
| Organize shows no suggestions | The folder structure may already be well-organized, or the folder name may not match exactly. |
| Notion activity log not updating | Notion is optional. Check `NOTION_API_KEY` if you want logging enabled. |

## Next Steps

1. Run `/drive:search` with a term you know exists in your Drive to verify the connection
2. Try `/drive:summarize` on a document you've been meaning to review
3. Use `/drive:ask` to find answers buried in long documents
4. Run `/drive:organize` on a messy folder to get cleanup suggestions
5. Check `INSTALL.md` for advanced configuration options
