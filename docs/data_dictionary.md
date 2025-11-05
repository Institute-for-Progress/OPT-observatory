# Data Dictionary

## Overview

This page describes the structure and content of the data underlying the the Institute for Progress' OPT Observatory. Obtained via a FOIA request from U.S. Immigration and Customs Enforcement (ICE), the data is an excerpt from the Student and Exchange Visitor Information System (SEVIS), accessible in the ICE FOIA Library under #43657, with a release date of October 1st 2024. While the OPT Observatory and the remainder of this document only describe the data on F-1 international students, a small amount of information on J-1 exchange visitors was also included.

## Data Processing Pipeline

### Accessing the Raw FOIA Data

To find the original raw data from ICE:
- Visit the ICE FOIA Library: https://www.ice.gov/foia/library
- Search for: **43657**
- Expect to see 13 files dated October 1, 2024 available for download. These should include one folder for each year of F-1 data from 2004-2023, as well as J-1 data

Our processing pipeline for the data is as follows:

1. **Raw FOIA data**: Original Excel files, multiple per year
2. **Combined by year**: All Excel files for a given year combined into a single CSV by standardizing their headers (e.g., `2004_all.csv`)
3. **Cleaned data**: An extensively cleaned single CSV file for each year (e.g., `cleaned_2004_all.csv`)

Unless there is a compelling reason not to, we strongly encourage data users to work off the cleaned files. For detailed information on the cleaning process, see the [Data Processing Documentation](data_processing.md).

## Data Structure

### How Are Records Organized?

**SEVIS as a log of events**

**SEVIS is NOT a person-centric database** and information about a given individual is often distributed across multiple rows. Instead, **each row represents a discrete event or status change for a person**. Most people undergo many different events related to their education and work logged in SEVIS, and have multiple rows with information about them. As is typical of administrative data, SEVIS record keeping is imperfect. However, a new record is usually created when:

- Someone enters or exits the United States
- Their visa status changes
- They change educational programs or institutions
- They begin or end work authorization (OPT/CPT)
- They change employers during OPT
- Other administrative events occur (program extensions, status reinstatements, etc.)

**Example:** Consider an international student who: 
1. Arrives in the U.S. for undergraduate studies in 2012 (→ Record 1)
2. Completes their Bachelor's degree in 2016 (→ Record 2)
3. Enrolls in a Master's program at a different university in 2016 (→ Record 3)
4. Begins OPT employment at Company A in 2017 (→ Record 4)
5. Changes jobs to Company B during their OPT period in 2018 (→ Record 5)
6. Leaves the U.S. at the end of their OPT authorization in 2019 (→ Record 6)

**This single student would have at least 6 records, with "new" information found only a subset of the columns**. Some columns represent unchanging values and are constant across rows/records (e.g. `FIRST_ENTRY_DATE` or `COUNTRY_OF_BIRTH`). Other columns are the reason for the record's creation, and will vary between rows (e.g. `SCHOOL_NAME`, (OPT) `AUTHORIZATION_START_DATE`). See the Column Definitions section below for detailed notes on how we think columns do or do not vary across an individual's records.

We have not verified whether information that ought to persist across rows always does, and avoid analyses where this would be a confounding factor. 

### How Are Individuals Identified?

**Identifying keys**

There are two unique personal identifiers in the data, `STUDENT_KEY` and `INDIVIDUAL_KEY`. **INDIVIDUAL_KEY values are only unique WITHIN each year's file, NOT across years.** I.e. the same number may point to different individuals in different year's files. We use `INDIVIDUAL_KEY` to identify unique individuals within each year. 

This means:

- Within `cleaned_2015_all.csv`, all records with `INDIVIDUAL_KEY = 12345` represent the same person
- You can trace that person's complete history (all their records) within the 2015 file
- Across different year files, `INDIVIDUAL_KEY = 12345` in the 2015 file and `INDIVIDUAL_KEY = 12345` in the 2016 file may represent **different people**
- You **cannot** link records across different year files

### How Are Records Organized Into Year Files?

While the data provided is segmented into years, the metric which breaks it up is not described. That is, **we do not definitively know why any given record might appear in one year and not another**. 

We act on the **assumption that:** for any given year's file, **if a student has any record in that year, ALL of their records appear in that year** — past, present, and future. Note that most data presented in the OPT Observatory only relies on the (more conservative) assumption that all of a student's records appear in their year of graduation.

**Example:** If the student described above graduates in 2016, then the `cleaned_2016_all.csv` file would include:
- Their initial entry record from 2012
- Their Bachelor's completion record from 2016
- Their Master's program start record from 2016
- Their OPT employment records from 2017
- Their job change record from 2018
- Their departure record from 2019

**In other words:** The 2016 file contains their **complete SEVIS history**, not just events that occurred in 2016.

## Known Data Quality Issues

1. Extensive **missing data.** Many fields, especially ones related to employer location, are missing data.
2. **Miscoded data,** e.g. first entry dates in the year 3000, or program end dates that are earlier than that program's start date. In general these are nullified, and not counted towards totals.
3. **Suspected mislabeling of files,** we suspect that the data labeled 2005-2008 was incorrectly titled, and should be one fiscal year higher (2005 → FY 2006, 2006 → FY 2007, 2007 → FY 2008, 2008 → FY 2009), and that the FY2009 data is missing. The FY2009 and FY2010 files provided are identical, and discontinuities in enrollments and changes of status between 2008 and 2009 resolve when this assumption is implemented. This has not been verified with the FOIA office, and the OPT Observatory does not analyze data for these years.
4. **Unclear STATUS_CODE interpretation.** The STATUS_CODE field is not reliable and we cannot definitively determine whether students graduated based on available fields. There is no clear indicator of program completion or graduation.

## Column Definitions

The following is our interpretation of the meaning of each variable in the data.

### Table Column Meanings

- **Position**: The column number in the original data files (1-46)
- **Column Name**: The variable name as it appears in the cleaned CSV files
- **Description**: Our best interpretation of what the variable represents
- **Data Type**: The format of the data (String, Integer, Numeric, Date)
- **Variability**: Whether the value is **Constant** (same across all of an individual's records) or **Variable** (can change across an individual's records). A dash (-) indicates the field doesn't apply to individual-level variability.
- **Notes**: Additional details about data quality, transformations, or interpretation

### Student Demographics

| Position | Column Name | Description | Data Type | Variability | Notes |
|----------|------------|-------------|-----------|-------------|-------|
|1|**COUNTRY_OF_BIRTH** | Student's country of birth | String (lowercase) | Constant | - |
|2|**COUNTRY_OF_CITIZENSHIP** | Student's country of citizenship | String (lowercase) | Constant | May differ from country of birth |
|44|**INDIVIDUAL_KEY** | Person-level identifier | Integer | - | Multiple records can share the same key; use for tracking individuals across records |
|45|**STUDENT_KEY** | Program-level identifier | Integer | - | Tracks individual programs of study; one person (INDIVIDUAL_KEY) can have multiple STUDENT_KEYs (e.g., BA then PhD) |

### Entry and Visa Information

| Position | Column Name | Description | Data Type | Variability | Notes |
|----------|------------|-------------|-----------|-------------|-------|
|3|**FIRST_ENTRY_DATE** | Date of first entry to the U.S. | Date (YYYY-MM-DD) | Constant | May be blank; dates after 2024-01-01 are nullified |
|4|**LAST_ENTRY_DATE** | Date of most recent entry to the U.S. | Date (YYYY-MM-DD) | Variable | May be blank for students who haven't left/re-entered; updates with new entries |
|5|**LAST_DEPARTURE_DATE** | Date of most recent departure from U.S. | Date (YYYY-MM-DD) | Variable | May be blank if student hasn't departed; updates with departures |
|6|**CLASS_OF_ADMISSION** | Visa class at entry | String (lowercase) | Constant | All records in cleaned data are "f1" |
|7|**VISA_ISSUE_DATE** | Date visa was issued | Date (YYYY-MM-DD) | Variable | May be blank; can change if visa is reissued |
|8|**VISA_EXPIRATION_DATE** | Date visa expires | Date (YYYY-MM-DD) | Variable | May be blank; changes with visa renewals |

### Educational Program Information

| Position | Column Name | Description | Data Type | Variability | Notes |
|----------|------------|-------------|-----------|-------------|-------|
|9|**SCHOOL_NAME** | Name of educational institution | String (lowercase) | Variable | - |
|10|**CAMPUS_CITY** | City of school address | String (lowercase) | Variable | - |
|11|**CAMPUS_STATE** | State of school address | String (lowercase) | Variable | Full state names (not abbreviations) |
|12|**CAMPUS_ZIP_CODE** | ZIP code of school address | String | Variable | - |
|13|**MAJOR_1_CIP_CODE** | Primary major CIP code | Numeric | Variable | Classification of Instructional Programs code; 6-digit with 4 decimal places (e.g., "11.0701") |
|14|**MAJOR_1_DESCRIPTION** | Primary major name | String (lowercase) | Variable | E.g., "computer science", "business administration" |
|15|**MAJOR_2_CIP_CODE** | Secondary major CIP code | Numeric | Variable | 6-digit with 4 decimal places; 0.0 if no second major |
|16|**MAJOR_2_DESCRIPTION** | Secondary major name | String (lowercase) | Variable | Blank if no second major |
|17|**MINOR_CIP_CODE** | Minor CIP code | Numeric | Variable | 6-digit with 4 decimal places; 0.0 if no minor |
|18|**MINOR_DESCRIPTION** | Minor name | String (lowercase) | Variable | Blank if no minor |
|19|**PROGRAM_START_DATE** | Start date of academic program | Date (YYYY-MM-DD) | Variable | Different for each program/record |
|20|**PROGRAM_END_DATE** | End date of academic program | Date (YYYY-MM-DD) | Variable | Expected completion date at time of program start; different for each program/record |
|43|**STUDENT_EDU_LEVEL_DESC** | Educational level | String (lowercase) | Variable | E.g., "bachelor's", "master's", "doctorate"; changes with degree progression |

### Employment Information (OPT/CPT)

| Position | Column Name | Description | Data Type | Variability | Notes |
|----------|------------|-------------|-----------|-------------|-------|
|21|**EMPLOYER_NAME** | Name of employer | String (lowercase) | Variable | Only for students with work authorization |
|22|**EMPLOYER_CITY** | City of employer address | String (lowercase) | Variable | - |
|23|**EMPLOYER_STATE** | State of employer address | String (lowercase) | Variable | Full state names (not abbreviations) |
|24|**EMPLOYER_ZIP_CODE** | ZIP code of employer address | String | Variable | - |
|25|**JOB_TITLE** | Job title or position | String (lowercase) | Variable | Sparsely populated |
|26|**EMPLOYMENT_DESCRIPTION** | Type of employment authorization | String (lowercase) | Variable | Values: "opt" (Optional Practical Training) or "cpt" (Curricular Practical Training) |
|27|**AUTHORIZATION_START_DATE** | Start date of work authorization | Date (YYYY-MM-DD) | Variable | Always present if OPT_AUTHORIZATION_START_DATE is present |
|28|**AUTHORIZATION_END_DATE** | End date of work authorization | Date (YYYY-MM-DD) | Variable | Always present if OPT_AUTHORIZATION_END_DATE is present |
|29|**OPT_AUTHORIZATION_START_DATE** | OPT-specific authorization start | Date (YYYY-MM-DD) | Variable | Less comprehensive; when present, matches AUTHORIZATION_START_DATE |
|30|**OPT_AUTHORIZATION_END_DATE** | OPT-specific authorization end | Date (YYYY-MM-DD) | Variable | Less comprehensive; when present, matches AUTHORIZATION_END_DATE |
|31|**OPT_EMPLOYER_START_DATE** | Date employment with this employer began | Date (YYYY-MM-DD) | Variable | Can differ from authorization dates if student changed employers mid-OPT |
|32|**OPT_EMPLOYER_END_DATE** | Date employment with this employer ended | Date (YYYY-MM-DD) | Variable | May differ from authorization dates |
|33|**EMPLOYMENT_OPT_TYPE** | Type of OPT | String (lowercase) | Variable | Values: "post-completion", "pre-completion", or "stem"; individuals often have multiple types |
|34|**EMPLOYMENT_TIME** | Full-time or part-time employment | String (lowercase) | Variable | Values: "full time" or "part time" |
|35|**UNEMPLOYMENT_DAYS** | Days of unemployment during OPT | Numeric | Variable | Cumulative days; OPT allows max 90 days |

### Financial Information

| Position | Column Name | Description | Data Type | Variability | Notes |
|----------|------------|-------------|-----------|-------------|-------|
|36|**TUITION_FEES** | Annual tuition and fees (USD) | Numeric | Variable | Self-reported or institutional data |
|37|**STUDENTS_PERSONAL_FUNDS** | Student's personal funds (USD) | Numeric | Variable | Financial support from student/family |
|38|**FUNDS_FROM_THIS_SCHOOL** | Funding from the institution (USD) | Numeric | Variable | Scholarships, assistantships, etc. |
|39|**FUNDS_FROM_OTHER_SOURCES** | Funding from other sources (USD) | Numeric | Variable | External scholarships, government funding, etc. |
|40|**ON_CAMPUS_EMPLOYMENT** | Likely earnings from on-campus employment (USD) | Numeric | Variable | Interpretation uncertain; may be 0.0 or blank if no on-campus work |

### Status Information

| Position | Column Name | Description | Data Type | Variability | Notes |
|----------|------------|-------------|-----------|-------------|-------|
|41|**REQUESTED_STATUS** | Requested change of visa status | String | Variable | Change of status from F-1 to another visa type; codes are generally self-explanatory (e.g., "h1b", "o1a"); "1b1" and "1b3" are part of H-1B series; typically constant across individual's rows |
|42|**STATUS_CODE** | Not reliable; interpretation unclear | String (lowercase) | Variable | Values: "completed", "deactivated", "terminated", "active", "canceled" |

### Administrative Fields

| Position | Column Name | Description | Data Type | Variability | Notes |
|----------|------------|-------------|-----------|-------------|-------|
|46|**Year** | Fiscal year indicator | Integer | - | FY is Oct 1 - Sept 30; indicates which year file contains this record |

<!-- ## Understanding OPT vs CPT

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
- Many records have no employment information (study-only records) -->



## Questions or Issues?

If you identify new data quality issues or have questions about the data, please reach out to violet@ifp.org.

## Related Documentation

- [Data Processing Guide](data_processing.md) - How to run the cleaning script
- [README](../README.md) - Project overview and getting started
