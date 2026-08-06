/* ============================================================
   HR DATA CLEANING PROJECT — PostgreSQL
   Goal: Clean a messy 1000-row HR dataset containing:
     - Inconsistent whitespace
     - Multiple representations of missing values ('nan', 'NAN', '', etc.)
     - Text-based numeric values (e.g. 'SIXTY THOUSAND', word-form ages)
     - Five different date formats mixed in a single column
   ============================================================ */


/* ------------------------------------------------------------
   STEP 1: Create a staging table
   All "messy" columns are loaded as TEXT on purpose.
   This avoids COPY/import failures caused by non-numeric values
   sitting in what should eventually be numeric/date columns.
   ------------------------------------------------------------ */
CREATE TABLE hr_raw (
    name TEXT,
    age TEXT,
    salary TEXT,
    gender TEXT,
    department TEXT,
    position TEXT,
    joining_date TEXT,
    performance_score TEXT,
    email TEXT,
    phone_number TEXT
);

-- Data loaded via pgAdmin's Import/Export GUI tool (right-click table -> Import/Export)
-- Equivalent psql command-line alternative:
-- \copy hr_raw FROM 'path/to/messy_HR_data.csv' WITH (FORMAT csv, HEADER true);


/* ------------------------------------------------------------
   STEP 2: Investigate the mess
   Used throughout development to decide cleaning rules.
   Kept here for documentation / reproducibility.
   ------------------------------------------------------------ */

-- Whitespace duplicates in name
-- SELECT COUNT(DISTINCT name) FROM hr_raw;           -- higher (fake duplicates)
-- SELECT COUNT(DISTINCT TRIM(name)) FROM hr_raw;      -- true unique count

-- Missing-value variants across columns
-- SELECT DISTINCT age FROM hr_raw WHERE age ~* 'nan' OR TRIM(age) = '';
-- SELECT DISTINCT salary FROM hr_raw WHERE salary ~* 'nan' OR TRIM(salary) = '';
-- SELECT DISTINCT email FROM hr_raw WHERE email IS NULL OR TRIM(email) = '' OR email ~* 'nan';
-- SELECT DISTINCT phone_number FROM hr_raw WHERE phone_number IS NULL OR TRIM(phone_number) = '' OR phone_number ~* 'nan';

-- Non-numeric age/salary values
-- SELECT DISTINCT age FROM hr_raw WHERE age ~ '[a-zA-Z]';
-- SELECT DISTINCT salary FROM hr_raw WHERE salary ~ '[a-zA-Z]';
-- Result: age had no word-forms; salary contained 'SIXTY THOUSAND'

-- Date format survey
-- SELECT DISTINCT joining_date FROM hr_raw ORDER BY joining_date;
-- Five formats identified: YYYY/MM/DD, MM/DD/YYYY, MM-DD-YYYY, YYYY.MM.DD, "Month D, YYYY"

-- Confirmed no unmatched/UNKNOWN date formats remained after building the CASE logic below.

-- Categorical columns (gender, department, position, performance_score)
-- checked via SELECT DISTINCT <col> ORDER BY <col> — all confirmed clean,
-- no whitespace, casing, or typo issues found.


/* ------------------------------------------------------------
   STEP 3: Build the cleaned table
   Converts messy TEXT columns into proper types:
     age               -> INT
     salary            -> NUMERIC
     joining_date      -> DATE
   Standardizes missing-value markers ('nan','NAN','',' NAN ') to NULL.
   ------------------------------------------------------------ */
CREATE TABLE hr_clean AS
SELECT
    TRIM(name) AS name,

    CASE
        WHEN TRIM(UPPER(age)) IN ('NAN', '') THEN NULL
        ELSE TRIM(age)::INT
    END AS age,

    CASE
        WHEN TRIM(UPPER(salary)) IN ('NAN', '') THEN NULL
        WHEN TRIM(UPPER(salary)) = 'SIXTY THOUSAND' THEN 60000
        ELSE TRIM(salary)::NUMERIC
    END AS salary,

    gender,
    department,
    position,

    CASE
        WHEN joining_date ~ '^\d{4}/\d{2}/\d{2}$'          THEN TO_DATE(joining_date, 'YYYY/MM/DD')
        WHEN joining_date ~ '^\d{2}/\d{2}/\d{4}$'          THEN TO_DATE(joining_date, 'MM/DD/YYYY')
        WHEN joining_date ~ '^\d{2}-\d{2}-\d{4}$'          THEN TO_DATE(joining_date, 'MM-DD-YYYY')
        WHEN joining_date ~ '^\d{4}\.\d{2}\.\d{2}$'        THEN TO_DATE(joining_date, 'YYYY.MM.DD')
        WHEN joining_date ~ '^[A-Za-z]+ \d{1,2}, \d{4}$'   THEN TO_DATE(joining_date, 'Month DD, YYYY')
        ELSE NULL
    END AS joining_date,

    performance_score,

    CASE
        WHEN TRIM(UPPER(email)) IN ('NAN', '') THEN NULL
        ELSE TRIM(email)
    END AS email,

    CASE
        WHEN TRIM(UPPER(phone_number)) IN ('NAN', '') THEN NULL
        ELSE TRIM(phone_number)
    END AS phone_number

FROM hr_raw;


/* ------------------------------------------------------------
   STEP 4: Validation
   Sanity checks to confirm the cleaning worked and nothing
   slipped through silently as an unexpected NULL.
   ------------------------------------------------------------ */
SELECT COUNT(*) FROM hr_clean;                      -- should match hr_raw row count

SELECT MIN(age), MAX(age) FROM hr_clean;
SELECT MIN(salary), MAX(salary) FROM hr_clean;
SELECT MIN(joining_date), MAX(joining_date) FROM hr_clean;

-- Confirm no date silently failed to parse
SELECT r.joining_date AS raw_value
FROM hr_raw r
JOIN hr_clean c ON r.name = c.name    -- adjust join if name isn't unique in your data
WHERE r.joining_date IS NOT NULL
  AND c.joining_date IS NULL;
