# Dashboard Table Format

Render goal dashboards as Markdown tables with six columns. Apply consistent alignment, truncation, and sort rules to produce a scannable overview across all tracked goals.

---

## Column Specification

| Column | Alignment | Width / Format | Description |
|:---|:---|:---|:---|
| Goal | Left (`:---`) | Max 30 chars, ellipsis truncation | Goal title from the Title property |
| Category | Left (`:---`) | Display as-is | Category property value, verbatim |
| Progress | Center (`:---:`) | 10-char bar + space + percentage | Visual progress bar with numeric percentage |
| RAG | Center (`:---:`) | Single emoji | Red/Amber/Green/Not Started status indicator |
| Target Date | Center (`:---:`) | `YYYY-MM-DD` or `No deadline` | Goal's Target Date property |
| Status | Left (`:---`) | Full status text | Status property value, verbatim |

---

## Progress Bar Construction

Build the progress bar from two Unicode block characters:

- Filled block: `█` (U+2588)
- Empty block: `░` (U+2591)

Calculate filled segments: `round(progress / 10)`. Fill remaining segments with empty blocks to always total 10 characters.

| Progress | Filled | Bar | Display |
|:---|:---|:---|:---|
| 0% | 0 | `░░░░░░░░░░` | `░░░░░░░░░░ 0%` |
| 25% | 3 | `███░░░░░░░` | `███░░░░░░░ 25%` |
| 50% | 5 | `█████░░░░░` | `█████░░░░░ 50%` |
| 73% | 7 | `███████░░░` | `███████░░░ 73%` |
| 100% | 10 | `██████████` | `██████████ 100%` |

Always display the percentage as an integer (no decimal places). Append `%` with no space between the number and the percent sign. Place one space between the bar and the percentage.

---

## RAG Emoji Mapping

Map the goal's RAG status to a single emoji. Do not include text labels — the emoji stands alone in the column.

| RAG Status | Emoji | Condition |
|:---|:---|:---|
| Red | `🔴` | Goal is at risk or blocked |
| Yellow | `🟡` | Goal needs attention |
| Green | `🟢` | Goal is on track |
| Not Started | `⚪` | Goal has no progress and Status = "Not Started" |

Derive RAG status from the goal's computed health. If the parent skill provides an explicit RAG value, use it. Do not re-derive RAG in the table rendering step.

---

## Sort Order

Sort goals in the table by two keys:

1. **RAG severity** (descending): Red first, then Yellow, then Green, then Not Started.
2. **Within same RAG group**: sort by Target Date ascending (earliest deadline first).

Goals without a Target Date sort last within their RAG group. When two goals in the same RAG group both lack a Target Date, sort alphabetically by Goal name.

This sort order ensures the most at-risk goals with the nearest deadlines appear at the top of the table.

---

## Truncation Rules

Apply truncation only to the Goal column:

- If the goal name is 30 characters or fewer, display it verbatim.
- If the goal name exceeds 30 characters, take the first 27 characters and append `...` (three periods, not an ellipsis character).
- Preserve word boundaries when possible: if character 27 falls mid-word and character 25 or 26 is a space, truncate at the space and append `...`. Do not leave trailing spaces before the ellipsis.
- Do not truncate any other column.

---

## Markdown Table Syntax

Use standard Markdown table syntax with alignment markers in the separator row:

```markdown
| Goal                           | Category   | Progress           | RAG  | Target Date | Status      |
|:-------------------------------|:-----------|:------------------:|:----:|:-----------:|:------------|
| Launch MVP                     | Product    | ███████░░░ 70%     | 🟢   | 2026-04-15  | In Progress |
| Q1 Revenue Target              | Financial  | █████░░░░░ 50%     | 🟡   | 2026-03-31  | In Progress |
| Hire Senior Engineer           | Hiring     | ██░░░░░░░░ 20%     | 🔴   | 2026-03-10  | In Progress |
| Redesign Company Website       | Marketing  | ████████░░ 80%     | 🟢   | 2026-05-01  | In Progress |
| Explore Partnership Opportu... | Business   | ░░░░░░░░░░ 0%      | ⚪   | No deadline | Not Started |
```

Note the alignment markers: `:---` for left-aligned columns, `:---:` for center-aligned columns.

---

## Empty State

When no goals exist in the tracking database, do not render an empty table. Instead, display this exact message:

```
No goals tracked yet. Use /founder-os:goal:create to get started.
```

Do not add any additional formatting, headers, or surrounding text to the empty state message.

---

## Section Header

When rendering the dashboard table in a report or chat output, precede it with a level-2 heading:

```markdown
## Goal Dashboard
```

Do not add additional description between the heading and the table. The table immediately follows the heading with one blank line separating them.

---

## Multiple Category Filtering

When the user provides a `--category` filter, apply it before sorting. Display only goals matching the specified category. If the filter yields zero results, display:

```
No goals found in category "[category_name]".
```

When no filter is applied, display all goals across all categories in a single unified table (do not split by category — the Category column provides that context).
