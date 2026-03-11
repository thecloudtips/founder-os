# Integration Test Plan: Workflow Documenter (P28)

## /workflow:document Tests

### Input Handling

1. **Inline description**: `/workflow:document "step 1, step 2, step 3"` -- produces SOP with 3 steps
2. **File input**: `/workflow:document --file=test-workflow.md` -- reads file, produces SOP
3. **Combined input**: `/workflow:document "context" --file=details.md` -- merges both sources
4. **No input**: `/workflow:document` -- prompts via AskUserQuestion
5. **File not found**: `/workflow:document --file=nonexistent.md` -- displays clear error, stops

### Extraction Accuracy

6. **Step extraction**: Verify each step has actor, action, tool, expected output
7. **Tool identification**: Verify tools are classified (Software/Hardware/Document/Human) and deduplicated
8. **Decision detection**: Verify conditional language triggers decision point extraction
9. **Handoff detection**: Verify actor changes between steps are flagged as handoffs
10. **Complexity scoring**: Simple workflow (3 steps, 0 decisions, 0 handoffs) = Simple tier

### Document Generation

11. **7-section structure**: Output contains all 7 numbered sections
12. **Mermaid diagram**: Output contains valid `flowchart TD` diagram
13. **Section omission (no decisions)**: Section 4 shows placeholder note when no decision points
14. **Section omission (no handoffs)**: Section 5 shows placeholder note when single actor
15. **20-step limit**: Workflow with 25 steps produces warning, SOP covers first 20

### Output Routing

16. **Default (both)**: File saved to `sops/` AND Notion page created
17. **File only**: `--format=file` saves file, skips Notion
18. **Notion only**: `--format=notion` creates Notion page, skips file
19. **Custom output path**: `--output=custom/path.md` saves to specified location
20. **YAML frontmatter**: Saved file includes workflow_name, complexity, steps_count, generated_at

## /workflow:diagram Tests

### Input Modes

21. **Fresh description (long)**: 50+ char input generates diagram directly
22. **Notion lookup (short)**: <50 char input searches "[FOS] Workflows" (Type="SOP") first, falls back to "Founder OS HQ - Workflows", then "Workflow Documenter - SOPs"
23. **Notion not found**: Short input with no Notion match treats as fresh description
24. **No input**: Prompts via AskUserQuestion

### Diagram Output

25. **Valid Mermaid**: Output is valid `flowchart TD` syntax
26. **Node shapes**: Start/end use rounded, steps use rectangles, decisions use diamonds
27. **Max 25 nodes**: Large workflow consolidates to fit limit
28. **Summary line**: Displays step count, decision count, handoff count, complexity tier

### File Output

29. **Default (no file)**: Diagram shown in chat only
30. **With --output**: Saves minimal .md with frontmatter + diagram only

## Cross-Cutting Tests

### Notion Integration

31. **HQ DB discovery**: Plugin finds "[FOS] Workflows" and writes with Type="SOP"
32. **Legacy DB fallback**: When [FOS] DB not found, tries "Founder OS HQ - Workflows", then falls back to "Workflow Documenter - SOPs"
33. **No DB found**: When none of the DB names exists, skips Notion silently (no DB creation)
34. **Idempotent upsert**: Re-running same workflow on same day updates existing page (filtered by Type="SOP")
35. **Graceful degradation**: Notion unavailable completes file output silently

### Consistency

36. **Complexity tiers match**: Values in skill, command, and Notion DB are identical (Simple/Moderate/Complex/Very Complex)
37. **Mermaid directive**: All generated diagrams use `flowchart TD`, never `graph TD`
38. **Skill loading**: Both commands read both skills before execution

### Edge Cases

39. **Empty workflow**: Minimal input ("do X") still produces valid SOP
40. **Special characters**: Workflow with quotes, parentheses renders valid Mermaid
41. **Directory creation**: Output to non-existent directory creates parent dirs (workflow:document only)
