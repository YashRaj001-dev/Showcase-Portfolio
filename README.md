# HR Data Cleaning — SQL (PostgreSQL)

A data cleaning project practicing real-world messy data handling in PostgreSQL. Starts from a raw 1,000-row HR CSV full of common data-quality issues and produces a fully typed, cleaned table.

## Files

- `messy_HR_data.xlsx` — original raw dataset
- `hr_clean.xlsx` — cleaned output
- `cleaning_script.sql` — full SQL pipeline, from staging table to final cleaned table, with validation checks

## Problems in the raw data

| Column | Issue |
|---|---|
| `name` | Inconsistent leading/trailing whitespace (`grace` vs ` grace `) causing false duplicates |
| `age` | Missing values represented as `'nan'`, `'NAN'`, `' NAN '`, or empty strings |
| `salary` | Same missing-value inconsistency, plus a word-form value (`'SIXTY THOUSAND'`) mixed into an otherwise numeric column |
| `joining_date` | Five different date formats mixed in a single column: `YYYY/MM/DD`, `MM/DD/YYYY`, `MM-DD-YYYY`, `YYYY.MM.DD`, and `Month D, YYYY` |
| `email`, `phone_number` | Missing values inconsistently marked as `'nan'`, blank, or whitespace-only strings |
| `gender`, `department`, `position`, `performance_score` | Checked for casing/whitespace/typo issues — confirmed clean, no changes needed |

## Approach

1. **Staging table** — loaded every column as `TEXT`, even ones that should eventually be numeric or date types. This avoids import failures caused by messy values that don't fit a strict type (e.g. loading `age` directly as `INT` would fail on the word-form values).
2. **Investigation before transformation** — used `SELECT DISTINCT` and regex filters (`~`, `!~`) to catalog every distinct "bad" value before deciding how to fix it, rather than guessing.
3. **Missing-value standardization** — collapsed all variants (`'nan'`, `'NAN'`, `' NAN '`, empty string) into real SQL `NULL` using `TRIM(UPPER(...))` comparisons.
4. **Type coercion with `CASE`** — converted `age` and `salary` to numeric types, mapping the one identified word-form value (`'SIXTY THOUSAND'` → `60000`) explicitly rather than dropping it.
5. **Multi-format date parsing** — since no single `TO_DATE` format string could parse the whole column, used a `CASE` block with regex pattern-matching to detect each row's format first, then applied the matching `TO_DATE(..., format)` call.
6. **Validation** — after building the cleaned table, ran sanity checks (`MIN`/`MAX` on age, salary, and dates; a join-based check for any row where cleaning silently produced an unexpected `NULL`) to confirm nothing broke silently.

## Key techniques used

- `TRIM()`, `UPPER()`, `INITCAP()` for whitespace/casing normalization
- `CASE WHEN` for conditional value mapping and missing-value standardization
- Regex operators `~` / `!~` for pattern detection and validation
- `TO_DATE()` with format strings for parsing mixed date formats
- Type casting (`::INT`, `::NUMERIC`) after cleaning text-based numeric columns
- `CREATE TABLE ... AS SELECT` to materialize the cleaned dataset

## Notes

This was built as a hands-on SQL practice exercise — every transformation was verified with a `SELECT` preview before being applied in the final `CREATE TABLE hr_clean AS SELECT ...` statement, to avoid silently corrupting data.
