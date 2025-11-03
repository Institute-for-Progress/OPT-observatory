# SEVIS F-1 Data Dictionary

## Overview

This document describes the structure and content of the SEVIS (Student and Exchange Visitor Information System) F-1 visa data obtained through FOIA requests from U.S. Immigration and Customs Enforcement (ICE).

## Important: Data Structure

### Record-Level vs Person-Level Data

**This is NOT a person-centric database.** Key points:

- Each **row represents a record** (authorization period, status change, or employment authorization)
- The **same person appears multiple times** across different records
- Records can represent:
  - Different time periods for the same person
  - Different authorization periods (e.g., initial study period vs OPT)
  - Different employers during OPT
  - Status changes or program changes

**Example:** A single student who completed a Master's degree and then worked on OPT at two different companies would have **at least 3 separate records**:
1. Their academic program record
2. Their first OPT employment period
3. Their second OPT employment period

### Identifying Individuals

- **INDIVIDUAL_KEY** and **STUDENT_KEY**: These appear to be person-level identifiers
- Multiple records with the same INDIVIDUAL_KEY/STUDENT_KEY represent the same person at different points in time
- **NOTE**: Research and validate these identifiers before using for longitudinal analysis

### Temporal Organization

**Coverage:** 2004-2023 (data from 2010-2022 is most reliable; see data_processing.md for details)

**File structure after processing:**
- One file per year: `cleaned_YYYY_all.csv`
- Year assignment is based on [NEED TO CLARIFY: authorization date? entry date? status date?]
- The same person may appear in multiple year files if their authorizations span multiple years

## Data Source and FOIA Redactions

This data was obtained through Freedom of Information Act (FOIA) requests to ICE. **Important caveats:**

1. **Pre-redacted data**: Personally identifiable information was removed/replaced by ICE before release
2. **Placeholder values**: Some columns (e.g., Date_of_Birth) contain nonsense placeholder values, not real data
3. **Redacted columns**: Certain fields were entirely removed by the FOIA office
4. **Data quality varies by year**: Completeness and consistency improved over time (post-2010 data is more reliable)

## Column Definitions

### Student Demographics

| Column Name | Description | Data Type | Notes |
|------------|-------------|-----------|-------|
| **COUNTRY_OF_BIRTH** | Student's country of birth | String (lowercase) | Standardized to lowercase by cleaning script |
| **COUNTRY_OF_CITIZENSHIP** | Student's country of citizenship | String (lowercase) | May differ from country of birth |
| **INDIVIDUAL_KEY** | Person-level identifier | Integer | Multiple records can share the same key; use for tracking individuals across records |
| **STUDENT_KEY** | Alternative person-level identifier | Integer | Relationship to INDIVIDUAL_KEY needs verification |

### Entry and Visa Information

| Column Name | Description | Data Type | Notes |
|------------|-------------|-----------|-------|
| **FIRST_ENTRY_DATE** | Date of first entry to the U.S. | Date (YYYY-MM-DD) | May be blank; dates after 2024-01-01 nullified by cleaning script |
| **LAST_ENTRY_DATE** | Date of most recent entry to the U.S. | Date (YYYY-MM-DD) | May be blank for students who haven't left/re-entered |
| **LAST_DEPARTURE_DATE** | Date of most recent departure from U.S. | Date (YYYY-MM-DD) | May be blank if student hasn't departed |
| **CLASS_OF_ADMISSION** | Visa class at entry | String (lowercase) | Typically "f1" for F-1 students |
| **VISA_ISSUE_DATE** | Date visa was issued | Date (YYYY-MM-DD) | May be blank |
| **VISA_EXPIRATION_DATE** | Date visa expires | Date (YYYY-MM-DD) | May be blank |

### Educational Program Information

| Column Name | Description | Data Type | Notes |
|------------|-------------|-----------|-------|
| **SCHOOL_NAME** | Name of educational institution | String (lowercase) | Cleaned/standardized by script |
| **CAMPUS_CITY** | City where campus is located | String (lowercase) | Cleaned/standardized |
| **CAMPUS_STATE** | State where campus is located | String (lowercase) | Full state names (not abbreviations) after cleaning |
| **CAMPUS_ZIP_CODE** | ZIP code of campus | String | May be 5-digit or 9-digit format |
| **MAJOR_1_CIP_CODE** | Primary major CIP code | Numeric | Classification of Instructional Programs code |
| **MAJOR_1_DESCRIPTION** | Primary major description | String (lowercase) | Human-readable major name |
| **MAJOR_2_CIP_CODE** | Secondary major CIP code | Numeric | 0.0 if no second major |
| **MAJOR_2_DESCRIPTION** | Secondary major description | String (lowercase) | Blank if no second major |
| **MINOR_CIP_CODE** | Minor CIP code | Numeric | 0.0 if no minor |
| **MINOR_DESCRIPTION** | Minor description | String (lowercase) | Blank if no minor |
| **PROGRAM_START_DATE** | Start date of academic program | Date (YYYY-MM-DD) | |
| **PROGRAM_END_DATE** | End date of academic program | Date (YYYY-MM-DD) | Expected or actual completion date |
| **STUDENT_EDU_LEVEL_DESC** | Educational level | String (lowercase) | E.g., "bachelor's", "master's", "doctorate" |

### Employment Information (OPT/CPT)

| Column Name | Description | Data Type | Notes |
|------------|-------------|-----------|-------|
| **EMPLOYER_NAME** | Name of employer | String (lowercase) | Only for students with work authorization |
| **EMPLOYER_CITY** | City where employer is located | String (lowercase) | Cleaned/standardized |
| **EMPLOYER_STATE** | State where employer is located | String (lowercase) | Full state names after cleaning |
| **EMPLOYER_ZIP_CODE** | ZIP code of employer | String | |
| **JOB_TITLE** | Job title or position | String (lowercase) | |
| **EMPLOYMENT_DESCRIPTION** | Type of employment authorization | String (lowercase) | "opt" = Optional Practical Training; "cpt" = Curricular Practical Training |
| **AUTHORIZATION_START_DATE** | Start date of work authorization | Date (YYYY-MM-DD) | |
| **AUTHORIZATION_END_DATE** | End date of work authorization | Date (YYYY-MM-DD) | |
| **OPT_AUTHORIZATION_START_DATE** | OPT-specific authorization start | Date (YYYY-MM-DD) | May overlap with AUTHORIZATION_START_DATE |
| **OPT_AUTHORIZATION_END_DATE** | OPT-specific authorization end | Date (YYYY-MM-DD) | May overlap with AUTHORIZATION_END_DATE |
| **OPT_EMPLOYER_START_DATE** | Date employment with this employer began | Date (YYYY-MM-DD) | Can differ from authorization dates if student changed employers mid-OPT |
| **OPT_EMPLOYER_END_DATE** | Date employment with this employer ended | Date (YYYY-MM-DD) | Blank if still employed or authorization ended |
| **EMPLOYMENT_OPT_TYPE** | Type of OPT | String (lowercase) | E.g., "post-completion" (after graduation) vs pre-completion |
| **EMPLOYMENT_TIME** | Full-time or part-time employment | String (lowercase) | "full time" or "part time" |
| **UNEMPLOYMENT_DAYS** | Days of unemployment during OPT | Numeric | Cumulative unemployment days; OPT allows max 90 days |

### Financial Information

| Column Name | Description | Data Type | Notes |
|------------|-------------|-----------|-------|
| **TUITION_FEES** | Annual tuition and fees (USD) | Numeric | Self-reported or institutional data |
| **STUDENTS_PERSONAL_FUNDS** | Student's personal funds (USD) | Numeric | Financial support from student/family |
| **FUNDS_FROM_THIS_SCHOOL** | Funding from the institution (USD) | Numeric | Scholarships, assistantships, etc. |
| **FUNDS_FROM_OTHER_SOURCES** | Funding from other sources (USD) | Numeric | External scholarships, government funding, etc. |
| **ON_CAMPUS_EMPLOYMENT** | On-campus employment income (USD) | Numeric | May be 0.0 or blank if no on-campus work |

### Status Information

| Column Name | Description | Data Type | Notes |
|------------|-------------|-----------|-------|
| **REQUESTED_STATUS** | Status change requested | String | May be blank if no status change requested |
| **STATUS_CODE** | Current status of the record | String (lowercase) | E.g., "completed", "deactivated", "active" |

### Administrative Fields

| Column Name | Description | Data Type | Notes |
|------------|-------------|-----------|-------|
| **YEAR** | Year indicator (uppercase) | Integer | Added during initial file combining |
| **Year** | Year indicator (capitalized) | Integer | May be duplicate of YEAR; verify which to use |

## Understanding OPT vs CPT

**OPT (Optional Practical Training):**
- Work authorization for F-1 students to work in their field of study
- Typically **after graduation** ("post-completion OPT")
- Can be granted before graduation ("pre-completion OPT") but less common
- Standard OPT: 12 months
- STEM Extension: Additional 24 months for STEM degree holders (total 36 months)
- Strict unemployment limits (90 days maximum)

**CPT (Curricular Practical Training):**
- Work authorization **during studies**
- Must be part of the academic curriculum
- Can be full-time or part-time
- Does not count toward OPT eligibility (if part-time)
- Full-time CPT for 12+ months may disqualify student from OPT

**In this dataset:**
- `EMPLOYMENT_DESCRIPTION` = "opt" indicates OPT records
- `EMPLOYMENT_DESCRIPTION` = "cpt" indicates CPT records
- Many records have no employment information (study-only records)

## Common Analysis Scenarios

### Counting Unique Individuals

❌ **Incorrect:** `nrow(data)` - This counts records, not people

✅ **Correct:** Use INDIVIDUAL_KEY or STUDENT_KEY to identify unique persons
```r
unique_students <- data %>% distinct(INDIVIDUAL_KEY, .keep_all = TRUE)
```

**Note:** Validate these identifiers before use - check for duplicates, missing values, and consistency across years.

### Tracking Students Over Time

Multiple records for the same person can show:
1. Progression through degree programs (Bachelor's → Master's → PhD)
2. School transfers or program changes
3. Transition from study to OPT employment
4. Multiple OPT employers

**Example query:** Find all records for a specific student
```r
student_history <- data %>%
  filter(INDIVIDUAL_KEY == 12345) %>%
  arrange(PROGRAM_START_DATE, OPT_AUTHORIZATION_START_DATE)
```

### OPT Employment Analysis

To analyze OPT employment patterns:
- Filter to `EMPLOYMENT_DESCRIPTION == "opt"`
- Use `OPT_EMPLOYER_START_DATE` and `OPT_EMPLOYER_END_DATE` for employment periods
- Use `EMPLOYER_NAME`, `EMPLOYER_CITY`, `EMPLOYER_STATE` for location analysis
- Use `MAJOR_1_DESCRIPTION` to link to field of study

### Understanding Year Assignment

[TO BE COMPLETED: Clarify how records are assigned to years]
- Is it based on authorization start date?
- Program end date?
- Status change date?
- This affects how you count students "in" a given year

## Data Quality Notes

### Known Issues

1. **Inconsistent date completeness**: Earlier years (2004-2009) have more missing dates
2. **Varying column structures**: Column names and availability changed over time; cleaning script standardizes this
3. **Duplicate records**: Same authorization may appear multiple times if status was updated
4. **Geographic standardization**: City/state names needed cleaning (handled by script)
5. **Zero vs blank values**: Some numeric fields use 0.0 to indicate "none", others use blank/NA

### Data Reliability by Year

- **2004-2009**: Less reliable, incomplete records, use with caution
- **2010-2022**: Most reliable period, consistent data collection
- **2023**: Most recent year, may be incomplete or preliminary

### FOIA-Redacted Fields

The following fields were **removed or redacted** by ICE before data release:
- **Date_of_Birth** / **Birth_Date**: Replaced with placeholder values
- **School_Fund_Type**: Removed or replaced
- [Add other redacted fields as identified]

These fields are automatically excluded by the cleaning script (`exclude_cols` parameter).

## Data Processing Pipeline

This data dictionary describes the **cleaned** data after running `load_data_parallel.R`. For information on how the data is processed, see [Data Processing Documentation](data_processing.md).

**Processing stages:**
1. **Raw FOIA data**: Original government files, organized by year/month in subdirectories
2. **Combined by year**: One CSV per year with all months combined (e.g., `2020_all.csv`)
3. **Cleaned data**: This data dictionary describes this stage (e.g., `cleaned_2020_all.csv`)
   - Standardized column names (UPPERCASE)
   - Parsed and validated dates
   - Cleaned geographic fields (lowercase, standardized)
   - Removed duplicates
   - Excluded redacted/irrelevant columns

## Questions or Issues?

If you find data quality issues, inconsistencies, or have questions about variable definitions, please open an issue in the repository.

## Related Documentation

- [Data Processing Guide](data_processing.md) - How to run the cleaning script
- [README](../README.md) - Project overview and getting started
