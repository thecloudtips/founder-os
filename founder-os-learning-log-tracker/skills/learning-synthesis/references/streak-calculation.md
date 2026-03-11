# Streak Calculation

Backwards-scan algorithm for tracking consecutive weeks of learning activity.

## Overview

A "streak" measures how many consecutive weeks the user has logged at least one learning. Recalculate the streak from scratch on every `/learn:weekly` run to ensure accuracy. Never cache or increment a stored value — always derive the streak from the actual database entries.

## Algorithm

### Step 1: Query Weekly Insights

Query the discovered Weekly Insights database (see learning-synthesis SKILL.md for discovery protocol):

- Sort by `Week` (title property) descending.
- Fetch all entries, or up to 52 for a one-year lookback.
- Extract the `Week` value from each entry (format: `YYYY-WNN`).

### Step 2: Include Current Week

If the target week is not yet in the database (i.e., the entry is about to be created by the current run), include it in the list as a virtual entry. This ensures the current synthesis counts toward the streak. Do not wait for the Notion write to complete before calculating — treat the target week as present.

### Step 3: Backwards Scan

Starting from the target week, scan backwards through consecutive ISO weeks:

1. Set `streak = 1` (the target week itself counts).
2. Calculate the previous ISO week from the current position.
3. Check if an entry exists for that previous week in the collected list.
4. If yes: increment `streak` by 1, move the current position to that previous week, and repeat from step 2.
5. If no: stop. The streak has broken at this gap.

### ISO Week Arithmetic

Calculate the previous ISO week using these rules:

- For `YYYY-WNN` where `NN > 1`: set previous to `YYYY-W(NN-1)`, zero-padded to two digits.
- For `YYYY-W01`: set previous to `(YYYY-1)-W52` or `(YYYY-1)-W53`, depending on whether the previous year has 52 or 53 ISO weeks.

Determine whether a year has 53 ISO weeks with this rule:

- A year has 53 ISO weeks if January 1 of that year falls on a Thursday, OR if December 31 of that year falls on a Thursday.
- Otherwise the year has 52 ISO weeks.

Never use calendar month logic for week boundaries. Always use ISO 8601 week numbering.

### Step 4: Store Result

Store the final streak count in the `Streak Days` property of the Weekly Insights entry. The property tracks weeks despite its name — keep the generic property name for future metric evolution. Write the integer value directly (e.g., `3` for a 3-week streak).

## Display Formatting

Format the streak for chat output based on the count:

| Streak | Display |
|--------|---------|
| 0 (no current week data) | Should not occur — only call this when learnings exist |
| 1 (first week ever) | "Starting your streak! 🌱" |
| 2–3 | "N weeks 📚" |
| 4–7 | "N weeks 🔥" |
| 8–12 | "N weeks 🔥🔥" |
| 13+ | "N weeks 🔥🔥🔥" |

Replace `N` with the actual streak count. Include the display string in the weekly summary output, after the insights section.

## Edge Cases

### First-Ever Weekly Summary

When the `Weekly Insights` database is empty or about to receive its first entry:

- Set streak to 1.
- Display: "Starting your streak! 🌱"
- Do not treat an empty database as an error condition.

### Gap Detection

If the user skips a week (no learnings logged during that ISO week), the streak resets. Example:

- Week 10: logged → streak 1
- Week 11: logged → streak 2
- Week 12: no entry → gap
- Week 13: logged → streak 1 (reset)

The backwards scan from Week 13 hits the gap at Week 12 and stops immediately. The earlier entries in Week 10 and 11 do not contribute.

### Re-running for Past Weeks

When running `/learn:weekly --week=YYYY-WNN` for a past week:

- Calculate the streak as of that past week, not as of today.
- Only consider entries at or before the target week in the backwards scan.
- Ignore all entries after the target week. Filter them out before starting the scan.
- This ensures historical accuracy when backfilling missed summaries.

### Multiple Gaps

The backwards scan stops at the FIRST gap encountered. Multiple gaps further back in history do not matter and are never examined. Once the scan encounters a missing week, return the accumulated streak count immediately.

### Year Boundary

Handle year transitions correctly using ISO week arithmetic:

- `2025-W52` → previous is `2025-W51` (normal decrement).
- `2026-W01` → previous is `2025-W52` (or `2025-W53` if 2025 has 53 ISO weeks).
- Never fall back to calendar month logic or naive date subtraction.
- Always zero-pad the week number: `W01` not `W1`, `W09` not `W9`.

### Duplicate Entries

If the database contains duplicate entries for the same week (from idempotent re-runs), treat them as a single entry. Deduplicate the week list before starting the backwards scan. Use the `Week` title string as the deduplication key.

## Complete Example

Database contains entries for: `2026-W07`, `2026-W08`, `2026-W10`.

**Running `/learn:weekly` for `2026-W10`:**

1. Start: streak = 1 (W10 counts).
2. Check W09: no entry found → STOP.
3. Final streak = 1.
4. Display: "1 weeks 📚" — but since streak is 1, display "Starting your streak! 🌱" instead.

Wait — W10 already exists in the database, so this is a re-run. The virtual entry logic does not apply. The streak is still 1 because W09 is missing.

**Running `/learn:weekly` for `2026-W08`:**

1. Start: streak = 1 (W08 counts).
2. Check W07: entry exists → streak = 2.
3. Check W06: no entry found → STOP.
4. Final streak = 2.
5. Display: "2 weeks 📚".

**Running `/learn:weekly` for `2026-W09` (backfill):**

1. Include W09 as virtual entry since it is about to be created.
2. Start: streak = 1 (W09 counts).
3. Check W08: entry exists → streak = 2.
4. Check W07: entry exists → streak = 3.
5. Check W06: no entry found → STOP.
6. Final streak = 3.
7. Display: "3 weeks 📚".

Note that W10 is ignored because it comes after the target week W09. This preserves historical accuracy.
