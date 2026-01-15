# Data Dictionary
## Overview
This page describes the structure and content of the data underlying the Institute for Progress's OPT Observatory. Obtained via a FOIA request from U.S. Immigration and Customs Enforcement (ICE), the data is an excerpt from the Student and Exchange Visitor Information System (SEVIS). While the OPT Observatory and the remainder of this document only describe the data on F-1 international students, information on J-1 exchange visitors was also included and is available with the downloadable data.

## Data Access
- [Download the cleaned data](https://drive.google.com/drive/folders/1jHyayPqwMN969gPJoEs7t0wAsZcpwzC7?usp=sharing)(~25 GB)
- The raw and cleaned data can be downloaded [here](https://drive.google.com/drive/folders/1RVCzAf6B8QIvd37PESSkKebhoi9psbFY?usp=share_link)(~75 GB). This includes both the cleaned data, and two sets of raw data (both the original from SEVIS and a corrected version—see the Data Mislabeling section below for more information). This is available for transparency and replicability for use with the OPT-Observatory Github repository, but we do not recommend users download this unless they intend to replicate our data cleaning process.

The raw data was originally obtained via the ICE FOIA library in 13 parts (see release #43657, dated October 1st 2024). In the original release, each year of data contained multiple sub-component files. Our raw data aggregates these to a single file per year (but does not otherwise modify them). For more information on data processing, see the [Data Processing Guide](data_processing.md).

## Data Availability by Year

| Fiscal Year | Status | Notes |
|-------------|--------|-------|
| 2004 | ✓ Available | Correctly labeled |
| 2005 | ✗ Missing | Not included in FOIA release |
| 2006-2022 | ✓ Available | Files FY2005-2008 were mislabeled as containing FY2006-2009 data; corrected in `USE_THESE__corrected_file_names` |
| 2023 | ⚠ Incomplete | Severely truncated; excluded from analyses |

**Recommended for analysis:** FY2006-2022 provides reliable, continuous coverage.

## Data Structure
### How Are Records Organized?
**SEVIS as a log of events**


**SEVIS is NOT a person-centric database** and information about a given individual is often distributed across multiple rows. Instead, **each row represents a discrete event**. Most individuals undergo multiple different events related to their education or work, and have multiple corresponding records (rows) in SEVIS. For example, a new record may be created when:

- Someone enters or exits the United States
- Their visa status changes
- They begin or change a course of study or school
- They begin or change work authorization (OPT/CPT)
- They change employers during OPT
- Other administrative events occur (program extensions, major changes, status reinstatements, etc.)

**Example:** Consider an international student who:
1. Arrives in the U.S. for undergraduate studies in 2012 (→ Record 1)

2. Enrolls in a Master's program at a different university in 2016 (→ Record 2)
3. Begins OPT employment at Company A in 2017 (→ Record 3)
4. Changes jobs to Company B during their OPT period in 2018 (→ Record 4)
5. Begins STEM OPT in 2018 with a final authorization date in 2020 (→ Record 5)

**This single student would have at least 5 records, with "new" information found in only a subset of the columns**. Some columns represent unchanging values and are constant across rows/records (e.g. `FIRST_ENTRY_DATE` or `COUNTRY_OF_BIRTH`). Other columns are the reason for the record's creation, and will vary between rows (e.g. `SCHOOL_NAME` or `OPT_AUTHORIZATION_START_DATE`). The Column Definitions section includes detailed notes on whether columns vary across an individual's records.

### How Are Individuals Identified?
**Identifying keys**
There are two unique personal identifiers in the data, `STUDENT_KEY` and `INDIVIDUAL_KEY`. 

**INDIVIDUAL_KEY values are only unique WITHIN each year's file, NOT across years.** I.e. the same number will point to different individuals in different years' files. We use `INDIVIDUAL_KEY` to identify unique individuals within each year.

**A single `INDIVIDUAL_KEY` can have multiple `STUDENT_KEY` values** (e.g., if someone completes a Bachelor's and then a PhD, they would have the same `INDIVIDUAL_KEY` but different `STUDENT_KEY` values for each program). However, each `STUDENT_KEY` corresponds to only one `INDIVIDUAL_KEY`.

Within `cleaned_2015_all.csv`, all records with `INDIVIDUAL_KEY = 12345` will represent the same person. You can trace that person's complete history (all their F-1 SEVIS records) within the 2015 file. However, `INDIVIDUAL_KEY = 12345` in the 2015 file and `INDIVIDUAL_KEY = 12345` in the 2016 file may represent **different people**, meaning you **cannot** link records across different year files.

### How Are Records Organized Into Year Files?
While the data provided is segmented into years, the metric which determines which records from which individuals are included in each year’s file is not given by the FOIA Office. 

We believe that for any given year's file, if a student is active in SEVIS, ALL of their records appear in that year — past, present, and future, up until the date on which the data were generated (some time before the data release). For the student described above, every cleaned file from FY2012-FY2020 (`cleaned_2012_all.csv` ,`cleaned_2013_all.csv`, and so on) will contain their **complete SEVIS history** as of the date the data were generated and not only events which occurred or were relevant to that fiscal year, for example:
- Their initial entry record from 2012
- Their Master's program start record from 2016
- Their OPT employment records from 2017
- Their job change record from 2018
- Their STEM OPT record from 2018.


Our working hypothesis is that each fiscal year includes all F-1 records for anyone who was active in SEVIS within that fiscal year. While we lack affirmative documentation of this, we know that across the respective years of cleaned files, 96-98% of are interpretable as being for someone who is studying or working in that fiscal year. Specifically, they have:
- A PROGRAM_START_DATE before the end of the fiscal year, AND 
- At least one of: an AUTHORIZATION_END_DATE after the start of the fiscal year, a blank or NA AUTHORIZATION_END_DATE, a PROGRAM_END_DATE after the start of the fiscal year. 

The remaining 2-4% of records are for individuals who do not meet the above criterion, but we find it plausible that these are still individuals active in SEVIS. The inclusion criteria for each fiscal year likely depends on columns not included in our data which the condition above happens to approximate.

## Known Data Quality Issues
There is **extensive missing data.** Many fields, especially ones related to employer location, are missing significant amounts of data and left blank. In some cases, it could be possible to backfill these (e.g. with employer addresses).

**Data is often miscoded,** e.g. past events are dated in the future, vice versa. Program end dates may also be earlier than that program's start date. In general, nonsensical entries are nullified and not counted towards totals.
There is no clear indicator of program completion or graduation in the data besides expected program end date, which is listed regardless of whether an enrollee has actually graduated.

**FY2023 data issues.** The file labeled FY2023 is the smallest of any year's data, and produces unbelievable counts for metrics like enrolled international students and OPT participants. It has not been confirmed by the FOIA office, but we believe this data is severely truncated and unusable as a result.

**FY2005 data missing.** The file for FY2005 was not included in the FOIA release. As described in the Data Mislabeling section, our continuous coverage spans FY2006-2022. FY2004 is also available but is separated by the missing FY2005. 

## Column Definitions
Data provided by ICE was not accompanied by documentation. Our best working interpretation of each variable in the data appears below. Please contact the authors if you have further information.

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
|5|**LAST_DEPARTURE_DATE** | Date of most recent departure from U.S. | Date (YYYY-MM-DD) | Variable | May be blank if student hasn't departed; updates with departures|
|6|**CLASS_OF_ADMISSION** | Status type | String (lowercase) | Constant | All records in cleaned data are "f1", generally F-1, M-1, or J-1 in SEVIS |
|7|**VISA_ISSUE_DATE** | Date the student’s visa was issued | Date (YYYY-MM-DD) | Variable | May be blank |
|8|**VISA_EXPIRATION_DATE** | Date the student’s visa expires | Date (YYYY-MM-DD) | Variable | May be blank |

Many dates are entered administratively, users should assume the data contains errors.

### Educational Program Information
| Position | Column Name | Description | Data Type | Variability | Notes |
|----------|------------|-------------|-----------|-------------|-------|
|9|**SCHOOL_NAME** | Name of educational institution | String (lowercase) | Variable | - |
|10|**CAMPUS_CITY** | City of the educational institution’s address | String (lowercase) | Variable | - |
|11|**CAMPUS_STATE** | State of the educational institution’s address | String (lowercase) | Variable | Full state names (not abbreviations) |
|12|**CAMPUS_ZIP_CODE** | ZIP code of the educational institution’s address | String | Variable | - |
|13|**MAJOR_1_CIP_CODE** | Primary major CIP code | Numeric | Variable | Classification of Instructional Programs code; 6-digit with 4 decimal places (e.g., "11.0701") |
|14|**MAJOR_1_DESCRIPTION** | Primary major name | String (lowercase) | Variable | E.g., "computer science", "business administration" |
|15|**MAJOR_2_CIP_CODE** | Secondary major CIP code | Numeric | Variable | 6-digit with 4 decimal places; 0.0 if no second major |
|16|**MAJOR_2_DESCRIPTION** | Secondary major name | String (lowercase) | Variable | Blank if no second major |
|17|**MINOR_CIP_CODE** | Minor CIP code | Numeric | Variable | 6-digit with 4 decimal places; 0.0 if no minor |
|18|**MINOR_DESCRIPTION** | Minor name | String (lowercase) | Variable | Blank if no minor |
|19|**PROGRAM_START_DATE** | The date a student is expected to begin their program | Date (YYYY-MM-DD) | Variable | Different for each program/record |
|20|**PROGRAM_END_DATE** | The date a student is expected to complete their program | Date (YYYY-MM-DD) | Variable | Expected completion date at time of program start; different for each program/record. Does not include any grace periods or future employment authorizations. |
|43|**STUDENT_EDU_LEVEL_DESC** | Educational level | String (lowercase) | Variable | E.g., "bachelor's", "master's", "doctorate"; changes with degree progression |

### Employment Information (OPT/CPT)
| Position | Column Name | Description | Data Type | Variability | Notes |
|----------|------------|-------------|-----------|-------------|-------|
|21|**EMPLOYER_NAME** | Name of employer | String (lowercase) | Variable | Only for students with work authorization |
|22|**EMPLOYER_CITY** | City of employer address | String (lowercase) | Variable | - |
|23|**EMPLOYER_STATE** | State of employer address | String (lowercase) | Variable | Full state names (not abbreviations) |
|24|**EMPLOYER_ZIP_CODE** | ZIP code of employer address | String | Variable | - |
|25|**JOB_TITLE** | Job title | String (lowercase) | Variable | Sparsely populated |
|26|**EMPLOYMENT_DESCRIPTION** | Type of employment authorization | String (lowercase) | Variable | Values: "opt" (Optional Practical Training) or "cpt" (Curricular Practical Training) |
|27|**AUTHORIZATION_START_DATE** | Start date of a CPT or OPT authorization | Date (YYYY-MM-DD) | Variable ||
|28|**AUTHORIZATION_END_DATE** | End date of a CPT or OPT authorization | Date (YYYY-MM-DD) | Variable | Always present if OPT_AUTHORIZATION_END_DATE is present. This is plausibly the USCIS approved date |
|29|**OPT_AUTHORIZATION_START_DATE** | The date an OPT authorization starts | Date (YYYY-MM-DD) | Variable | When present, matches AUTHORIZATION_START_DATE | Plausibly based on the start date from the student’s Employment Authorization Document (EAD)
|30|**OPT_AUTHORIZATION_END_DATE** | The date that OPT authorization ends | Date (YYYY-MM-DD) | Variable | When present, matches AUTHORIZATION_END_DATE | Plausibly based on the end date from the student’s Employment Authorization Document (EAD)
|31|**OPT_EMPLOYER_START_DATE** | Date employment with this employer began or will begin | Date (YYYY-MM-DD) | Variable | If the student will continue to work for the same post-completion OPT employer on a STEM extension, this is the actual start date for the STEM OPT. If a student changed employers mid-OPT, this will differ from the AUTHORIZATION_START_DATE |
|32|**OPT_EMPLOYER_END_DATE** | Date the student will stop working for the employer, if known. Left blank if unknown. | Date (YYYY-MM-DD) | Variable | May differ from other authorization dates |
|33|**EMPLOYMENT_OPT_TYPE** | Type of OPT | String (lowercase) | Variable | Values: "post-completion", "pre-completion", or "stem"; individuals often have multiple types |
|34|**EMPLOYMENT_TIME** | Full-time or part-time employment | String (lowercase) | Variable | Values: "full time" or "part time" |
|35|**UNEMPLOYMENT_DAYS** | Days of unemployment during OPT | Numeric | Variable | Cumulative days; OPT allows max 90 days |

### Financial Information
| Position | Column Name | Description | Data Type | Variability | Notes |
|----------|------------|-------------|-----------|-------------|-------|
|36|**TUITION_FEES** | Annual tuition and fees (USD) | Numeric | Variable | Self-reported or institutional data |
|37|**STUDENTS_PERSONAL_FUNDS** | Student's personal funds for one academic year (USD) | Numeric | Variable | Financial support from student/family |
|38|**FUNDS_FROM_THIS_SCHOOL** | Funding from the institution in one academic year (USD) | Numeric | Variable | Scholarships etc. |
|39|**FUNDS_FROM_OTHER_SOURCES** | Funding from other sources (USD) in one academic year | Numeric | Variable | External scholarships, government funding, etc. |
|40|**ON_CAMPUS_EMPLOYMENT** | Funding earned via on-campus employment, if any (USD) | Numeric | Variable | 0.0 or blank if no on-campus work |

See SEVIS Help Hub → Student Records → Update Student Records → Financial Information for more details about the values entered in these columns.

### Status Information
| Position | Column Name | Description | Data Type | Variability | Notes |
|----------|------------|-------------|-----------|-------------|-------|
|41|**REQUESTED_STATUS** | The visa type (if any) to which someone has requested to change to from their previous F-1 status | String | Variable | see below^*
|42|**STATUS_CODE** | Administrative status of a specific SEVIS record | String (lowercase) | Variable | Values: "completed", "deactivated", "terminated", "active", "canceled" |

*  REQUESTED_STATUS codes are generally self-explanatory (e.g., "o1a" is O-1A). H-1B variants "1b1" and "h1b" are regular H-1Bs, while "1b2" is H-1B2, "1b3" is H-1B3, and "hsc" is H-1B1;

In general, these are technical terms that are often applied in ways unintuitive given their literal meanings. For example, the following are sufficient conditions for a record to have a particular STATUS_CODE:
- Active if the student is maintaining status in SEVIS.
- Completed if the record was closed out normally and was not terminated
- Terminated if the record is closed for one of several possible non-completion reasons, including death, expulsion, failure to report, an approved change of status or adjustment of status, or other reasons. To learn more, see SEVIS Help Hub → Student Records → Completions and Terminations → Termination Reasons. 
- Deactivated if a student begins a new program, e.g. a change in major, school, degree level, or possibly other changes.
- Canceled if the student does not report to the school by the report date and there is no port of entry data, for example, if the offer is withdrawn, the record was created in error, the student never attends the school, or other reasons. 

### Administrative Fields
| Position | Column Name | Description | Data Type | Variability | Notes |
|----------|------------|-------------|-----------|-------------|-------|
|46|**Year** | Federal fiscal year indicator | Integer | - | FY is Oct 1 - Sept 30; indicates which year file contains this record |

## Data Mislabeling
Note that the raw data includes subfolders called `USE_THESE__corrected_file_names` and `AVOID_THESE__uncorrected_file_names`. This is because **we suspect a subset of the data provided by the FOIA office was initially labeled with the incorrect years.** Through cross-validation and analysis of internal dates, we determined that the file labeled as FY2004 is correct, but FY2005 is missing from the release, and the corrected file names adjust years initially labeled as FY 2005-2008 to FY 2006-2009, which we believe they actually represent.

We believe these were labeled in error after observing that:
- The raw files originally labeled as FY 2009 and FY 2010 are identical
- There are significant discontinuities in student enrollments, OPT participation, and change of status request trends between these files
- When the data labeled as FY2005-2008 are analyzed as if they were FY2006-2009 (each one year higher), these discontinuities resolve. The aforementioned trends become internally consistent with the other years' files, and begin to match estimates from other sources for these years.

While this has not been verified with the FOIA office, we strongly suspect that FY2005 data was not included in the release, the data labeled FY2009 was a duplicate of the one labeled FY2010, and those labeled FY2005-2008 were incorrectly titled. Going from the mislabeled → corrected data, this looks like: FY2004 remains FY2004, FY2005 → FY2006, FY2006 → FY2007, FY2007 → FY2008, FY2008 → FY2009, and FY2009 (as a duplicate of FY 2010) can be removed. As a result, FY2005 data is missing, and our continuous coverage spans FY2006-2022.

## Questions or Issues?
If you identify new data quality issues or have questions about the data, please reach out to violet@ifp.org.
