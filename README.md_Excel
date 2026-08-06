# HR Data Cleaning — Excel

A data cleaning project practicing real-world messy data handling in Excel. Same raw HR dataset used in the [SQL version](../HR_Data_Cleaning_Project) of this project, cleaned entirely with Excel formulas instead of SQL — showing the same problem-solving approach translated to a different tool.

## Files

- `messy_HR_data.xlsx` — original raw dataset
- `HR_Cleaned_Data.xlsx` — cleaned output

## Problems in the raw data

| Column | Issue |
|---|---|
| `Name` | Inconsistent leading/trailing whitespace (`' grace '`) and lowercase casing, causing false duplicates |
| `Age` | Missing values, plus a word-form value (`'thirty'`) mixed into an otherwise numeric column |
| `Salary` | Missing values, plus a word-form value (`'SIXTY THOUSAND'`) mixed into an otherwise numeric column |
| `Joining Date` | Five different date formats mixed in a single column: `YYYY/MM/DD`, `MM/DD/YYYY`, `MM-DD-YYYY`, `YYYY.MM.DD`, and `Month D, YYYY` |
| `Email`, `Phone Number` | Missing values inconsistently marked |
| `Gender`, `Department`, `Position`, `Performance Score` | Checked for casing/whitespace/typo issues — confirmed clean, no changes needed |

## Approach

1. **Name whitespace and casing** — used `=TRIM()` to strip leading/trailing spaces, combined with `=PROPER()` to fix casing, then pasted the results back as values.

2. **Age and Salary word-form values** — since these columns needed to end up numeric, non-numeric entries like `'thirty'` and `'SIXTY THOUSAND'` were manually identified (by filtering for text within an otherwise numeric column) and mapped to their numeric equivalents (`30`, `60000`) before converting the column to a number format.

3. **Multi-format date parsing** — the hardest part. Since `DATEVALUE()` alone doesn't recognize every format present (in particular, it fails on dot-separated dates like `2019.12.01`, returning `#VALUE!`), a nested `IF` formula was used to detect each row's format first, then parse it accordingly:

   ```excel
   =IF(ISNUMBER(SEARCH(".",G2)),
       DATEVALUE(SUBSTITUTE(G2,".","-")),
     IF(ISNUMBER(SEARCH("/",G2)),
       IF(LEN(LEFT(G2,FIND("/",G2)-1))=4,
         DATEVALUE(SUBSTITUTE(G2,"/","-")),
         DATE(VALUE(RIGHT(G2,4)),VALUE(LEFT(G2,2)),VALUE(MID(G2,4,2)))
       ),
     IF(ISNUMBER(SEARCH("-",G2)),
       DATE(VALUE(RIGHT(G2,4)),VALUE(LEFT(G2,2)),VALUE(MID(G2,4,2))),
       DATEVALUE(G2)
     ))
   )
   ```

   - **Dot-separated (`YYYY.MM.DD`)** → dots swapped for dashes via `SUBSTITUTE`, then parsed with `DATEVALUE` (which reliably reads `YYYY-MM-DD` as year-first regardless of regional settings, unlike slash-separated dates)
   - **Slash-separated** → checked whether the first segment is 4 digits long to distinguish `YYYY/MM/DD` from `MM/DD/YYYY`, then parsed accordingly
   - **Dash-separated (`MM-DD-YYYY`)** → rebuilt manually with `DATE()`, `LEFT()`, `MID()`, `RIGHT()`
   - **Text month format (`Month D, YYYY`)** → handled natively by `DATEVALUE()`, which understands this format out of the box

4. **Missing values** — standardized inconsistent blank/placeholder markers (including whitespace-only cells) using Find & Replace with "Match entire cell contents" enabled, to avoid corrupting legitimate text containing spaces elsewhere in the sheet.

5. **Validation** — checked row count preserved (1,000 → 1,000), confirmed numeric ranges for Age and Salary were sane after conversion, and spot-checked that every previously non-numeric Age/Salary value mapped to the correct number.

## Key techniques used

- `TRIM()`, `PROPER()` for whitespace and casing normalization
- Nested `IF()` for conditional format detection, mirroring a SQL `CASE` statement
- `DATEVALUE()`, `SUBSTITUTE()`, `DATE()`, `LEFT()`/`MID()`/`RIGHT()` for parsing inconsistent date formats
- Find & Replace with "Match entire cell contents" for safely standardizing missing-value markers
- Paste Special → Values to lock in formula results as static values

## Notes

This project intentionally mirrors the [SQL version](../HR_Data_Cleaning_Project) of the same dataset, to demonstrate that the same data-cleaning logic (detect the problem, classify by pattern, apply the right transformation, validate) translates across tools — not just syntax in one language.
