# Data Dictionary

## Overview

This page describes the structure and content of the data underlying the Institute for Progress's OPT Observatory. Obtained via a FOIA request from U.S. Immigration and Customs Enforcement (ICE), the data is an excerpt from the Student and Exchange Visitor Information System (SEVIS).. While the OPT Observatory and the remainder of this document only describe the data on F-1 international students, information on J-1 exchange visitors was also included.

## Data Access
We strongly encourage data users to work off the cleaned files. They are available for download here. For detailed information on the cleaning process, see the [Data Processing Documentation](data_processing.md).

Note: there are important data quality issues in FY2004-2009 and in FY2023. We do not recommend using these files at all. If you do use these files, please thoroughly read our description of known problems and independently verify them.

The original raw data from ICE is available to download [gDrive placeholder](https://www.ice.gov/foia/library). It is also available from ICE FOIA Library under #43657 in 13 parts, dated October 1, 2024. 

## Data Structure

### How Are Records Organized?

**SEVIS as a log of events**

**SEVIS is NOT a person-centric database** and information about a given individual is often distributed across multiple rows. Instead, **each row represents a discrete event**. Most individuals undergo multiple different events related to their education or work, and have multiple corresponding records (rows) in SEVIS. For example, a new record may be created when:

- Someone enters or exits the United States
- Their visa status changes
- They begin or change a course of study or school
- They begin or change work authorization (OPT/CPT)
- They change employers during OPT
- Other administrative events occur (program extensions, status reinstatements, etc.)

**Example:** Consider an international student who: 
1. Arrives in the U.S. for undergraduate studies in 2012 (→ Record 1)
2. Completes their Bachelor's degree in 2016 (→ Record 2)
3. Enrolls in a Master's program at a different university in 2016 (→ Record 3)
4. Begins OPT employment at Company A in 2017 (→ Record 4)
5. Changes jobs to Company B during their OPT period in 2018 (→ Record 5)

**This single student would have at least 5 records, with "new" information found in only a subset of the columns**. Some columns represent unchanging values and are constant across rows/records (e.g. `FIRST_ENTRY_DATE` or `COUNTRY_OF_BIRTH`). Other columns are the reason for the record's creation, and will vary between rows (e.g. `SCHOOL_NAME`, (OPT) `AUTHORIZATION_START_DATE`). See the Column Definitions section below for detailed notes on how we think columns do or do not vary across an individual's records.

We have not verified whether information that ought to persist across rows always does, and avoid analyses where this would be a confounding factor. 

### How Are Individuals Identified?

**Identifying keys**

There are two unique personal identifiers in the data, `STUDENT_KEY` and `INDIVIDUAL_KEY`. **INDIVIDUAL_KEY values are only unique WITHIN each year's file, NOT across years.** I.e. the same number will point to different individuals in different years' files. We use `INDIVIDUAL_KEY` to identify unique individuals within each year.

**Note:** A single `INDIVIDUAL_KEY` can have multiple `STUDENT_KEY` values (e.g., if someone completes a Bachelor's and then a PhD, they would have the same `INDIVIDUAL_KEY` but different `STUDENT_KEY` values for each program). However, each `STUDENT_KEY` corresponds to only one `INDIVIDUAL_KEY`. 

This means:

- Within `cleaned_2015_all.csv`, all records with `INDIVIDUAL_KEY = 12345` represent the same person
- You can trace that person's complete history (all their records) within the 2015 file
- Across different year files, `INDIVIDUAL_KEY = 12345` in the 2015 file and `INDIVIDUAL_KEY = 12345` in the 2016 file may represent **different people**
- You **cannot** link records across different year files

### How Are Records Organized Into Year Files?

While the data provided is segmented into years, the metric which breaks it up is not described. That is, **we do not definitively know why any given record might appear in one year and not another**. 

We act on the **assumption that:** for any given year's file, **if a student has any record in that year, ALL of their records appear in that year** — past, present, and future, up until October 5th, 2023. Note that most data presented in the OPT Observatory only relies on the (more conservative) assumption that all of a student's records appear in their year of graduation.

**Example:** If the student described above graduates in 2016, then the `cleaned_2016_all.csv` file would include:
- Their initial entry record from 2012
- Their Bachelor's completion record from 2016
- Their Master's program start record from 2016
- Their OPT employment records from 2017
- Their job change record from 2018

**In other words:** We assume the 2016 file contains the **complete SEVIS history**, not just events that occurred in 2016, for people who were present in 2016.

## Known Data Quality Issues

1. There are **important data quality issues in FY2004-2009 and in FY2023.** We do not recommend using these files at all. 

**Suspected mislabeling of FY2004-2009:**
Files labeled FY2009 and FY2010 files are identical. There are also significant discontinuities in student enrollment and change of status request trends. However, when the data labeled as FY2004-2008 are analyzed, respectively, as if they were FY2005-2009 (each one year higher), these discontinuities resolve and trends become internally consistent, plus begin to match estimates from other sources. 

Based on this, we suspect that the data labeled FY2005-2008 was incorrectly titled, and should be one fiscal year higher (FY2005 → FY2006, FY2006 → FY2007, FY2007 → FY2008, FY2008 → FY2009). This has not been verified with the FOIA office, and the OPT Observatory avoids this concern by not analyzing data from these years.

**Truncation of FY2023:**
The file labeled FY2023 is the smallest of any year's data, and produces unbelievable counts for metrics like enrolled international students and OPT participants. It has not been confirmed by the FOIA office, but we believe this data is severely truncated, and unusable for our purposes as a result. It is not analyzed by the OPT Observatory.

2. There is **extensive missing data.** Many fields, especially ones related to employer location, are missing significant amounts of data and left blank. In some cases, it could be possible to backfill these (e.g. with employer addresses).
3. **Data is often miscoded,** e.g. past events are dated in the future, vice versa. Program end dates may also be earlier than that program's start date. In general, nonsensical entries are nullified and not counted towards totals.
4. Variables are **not necessarily meaningful.** The STATUS_CODE field is unreliable and difficult to interpret, and we cannot definitively determine whether students actually graduated based on it despite the field sometimes containing values like "completed". There is no clear indicator of program completion or graduation in the data besides expected program end date, which is listed regardless of whether an enrollee has actually graduated.

## Column Definitions

This data is provided by ICE without documentation. The following gives our best interpretation of the meaning of each variable in the cleaned data.

### Table Column Meanings

- **Position**: The column number in the original data files (1-46)
- **Column Name**: The variable name as it appears in the cleaned CSV files
- **Description**: Our best interpretation of what the variable represents
- **Data Type**: The format of the data (String, Integer, Numeric, Date)
- **Variability**: Whether the value is **Constant** (same across all of an individual's records) or **Variable** (can change across an individual's records). A dash (-) indicates the field doesn't apply to individual-level variability.
- **Notes**: Additional details about data quality, transformations, or interpretation

### Student Demographics

<table>
<thead>
  <tr>
    <th style="width: 5%;">Position</th>
    <th style="width: 15%;">Column Name</th>
    <th style="width: 18%;">Description</th>
    <th style="width: 10%;">Data Type</th>
    <th style="width: 10%;">Variability</th>
    <th style="width: 42%;">Notes</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>1</td>
    <td><strong>COUNTRY_OF_BIRTH</strong></td>
    <td>Student's country of birth</td>
    <td>String (lowercase)</td>
    <td>Constant</td>
    <td>-</td>
  </tr>
  <tr>
    <td>2</td>
    <td><strong>COUNTRY_OF_CITIZENSHIP</strong></td>
    <td>Student's country of citizenship</td>
    <td>String (lowercase)</td>
    <td>Constant</td>
    <td>May differ from country of birth</td>
  </tr>
  <tr>
    <td>44</td>
    <td><strong>INDIVIDUAL_KEY</strong></td>
    <td>Person-level identifier</td>
    <td>Integer</td>
    <td>-</td>
    <td>Multiple records can share the same key; use for tracking individuals across records</td>
  </tr>
  <tr>
    <td>45</td>
    <td><strong>STUDENT_KEY</strong></td>
    <td>Program-level identifier</td>
    <td>Integer</td>
    <td>-</td>
    <td>Tracks individual programs of study; one person (INDIVIDUAL_KEY) can have multiple STUDENT_KEYs (e.g., BA then PhD)</td>
  </tr>
</tbody>
</table>

### Entry and Visa Information

<table>
<thead>
  <tr>
    <th style="width: 5%;">Position</th>
    <th style="width: 15%;">Column Name</th>
    <th style="width: 18%;">Description</th>
    <th style="width: 10%;">Data Type</th>
    <th style="width: 10%;">Variability</th>
    <th style="width: 42%;">Notes</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>3</td>
    <td><strong>FIRST_ENTRY_DATE</strong></td>
    <td>Date of first entry to the U.S.</td>
    <td>Date (YYYY-MM-DD)</td>
    <td>Constant</td>
    <td>May be blank; dates after 2024-01-01 are nullified</td>
  </tr>
  <tr>
    <td>4</td>
    <td><strong>LAST_ENTRY_DATE</strong></td>
    <td>Date of most recent entry to the U.S.</td>
    <td>Date (YYYY-MM-DD)</td>
    <td>Variable</td>
    <td>May be blank for students who haven't left/re-entered; updates with new entries</td>
  </tr>
  <tr>
    <td>5</td>
    <td><strong>LAST_DEPARTURE_DATE</strong></td>
    <td>Date of most recent departure from U.S.</td>
    <td>Date (YYYY-MM-DD)</td>
    <td>Variable</td>
    <td>May be blank if student hasn't departed; updates with departures</td>
  </tr>
  <tr>
    <td>6</td>
    <td><strong>CLASS_OF_ADMISSION</strong></td>
    <td>Visa class at entry</td>
    <td>String (lowercase)</td>
    <td>Constant</td>
    <td>All records in cleaned data are "f1"</td>
  </tr>
  <tr>
    <td>7</td>
    <td><strong>VISA_ISSUE_DATE</strong></td>
    <td>Date visa was issued</td>
    <td>Date (YYYY-MM-DD)</td>
    <td>Variable</td>
    <td>May be blank; can change if visa is reissued</td>
  </tr>
  <tr>
    <td>8</td>
    <td><strong>VISA_EXPIRATION_DATE</strong></td>
    <td>Date visa expires</td>
    <td>Date (YYYY-MM-DD)</td>
    <td>Variable</td>
    <td>May be blank; changes with visa renewals</td>
  </tr>
</tbody>
</table>

### Educational Program Information

<table>
<thead>
  <tr>
    <th style="width: 5%;">Position</th>
    <th style="width: 15%;">Column Name</th>
    <th style="width: 18%;">Description</th>
    <th style="width: 10%;">Data Type</th>
    <th style="width: 10%;">Variability</th>
    <th style="width: 42%;">Notes</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>9</td>
    <td><strong>SCHOOL_NAME</strong></td>
    <td>Name of educational institution</td>
    <td>String (lowercase)</td>
    <td>Variable</td>
    <td>Standardized in raw data</td>
  </tr>
  <tr>
    <td>10</td>
    <td><strong>CAMPUS_CITY</strong></td>
    <td>City of school address</td>
    <td>String (lowercase)</td>
    <td>Variable</td>
    <td>-</td>
  </tr>
  <tr>
    <td>11</td>
    <td><strong>CAMPUS_STATE</strong></td>
    <td>State of school address</td>
    <td>String (lowercase)</td>
    <td>Variable</td>
    <td>Standardized during cleaning: abbreviations converted to full state names (e.g., "MA" → "massachusetts")</td>
  </tr>
  <tr>
    <td>12</td>
    <td><strong>CAMPUS_ZIP_CODE</strong></td>
    <td>ZIP code of school address</td>
    <td>String</td>
    <td>Variable</td>
    <td>Standardized during cleaning: leading zeros restored via padding for states/territories with ZIP codes starting with 0 (MA, RI, CT, NH, ME, VT, NJ, PR, VI) where raw data ZIP codes were 4 digits instead of 5</td>
  </tr>
  <tr>
    <td>13</td>
    <td><strong>MAJOR_1_CIP_CODE</strong></td>
    <td>Primary major CIP code</td>
    <td>Numeric</td>
    <td>Variable</td>
    <td>Classification of Instructional Programs code; 6-digit with 4 decimal places (e.g., "11.0701")</td>
  </tr>
  <tr>
    <td>14</td>
    <td><strong>MAJOR_1_DESCRIPTION</strong></td>
    <td>Primary major name</td>
    <td>String (lowercase)</td>
    <td>Variable</td>
    <td>Standardized in raw data; e.g., "computer science", "business administration"</td>
  </tr>
  <tr>
    <td>15</td>
    <td><strong>MAJOR_2_CIP_CODE</strong></td>
    <td>Secondary major CIP code</td>
    <td>Numeric</td>
    <td>Variable</td>
    <td>6-digit with 4 decimal places; 0.0 if no second major</td>
  </tr>
  <tr>
    <td>16</td>
    <td><strong>MAJOR_2_DESCRIPTION</strong></td>
    <td>Secondary major name</td>
    <td>String (lowercase)</td>
    <td>Variable</td>
    <td>Standardized in raw data; blank if no second major</td>
  </tr>
  <tr>
    <td>17</td>
    <td><strong>MINOR_CIP_CODE</strong></td>
    <td>Minor CIP code</td>
    <td>Numeric</td>
    <td>Variable</td>
    <td>6-digit with 4 decimal places; 0.0 if no minor</td>
  </tr>
  <tr>
    <td>18</td>
    <td><strong>MINOR_DESCRIPTION</strong></td>
    <td>Minor name</td>
    <td>String (lowercase)</td>
    <td>Variable</td>
    <td>Standardized in raw data; blank if no minor</td>
  </tr>
  <tr>
    <td>19</td>
    <td><strong>PROGRAM_START_DATE</strong></td>
    <td>Start date of academic program</td>
    <td>Date (YYYY-MM-DD)</td>
    <td>Variable</td>
    <td>Refers to the start date of the student's academic program; different for each program/record</td>
  </tr>
  <tr>
    <td>20</td>
    <td><strong>PROGRAM_END_DATE</strong></td>
    <td>End date of academic program</td>
    <td>Date (YYYY-MM-DD)</td>
    <td>Variable</td>
    <td>Expected completion date at time of program start; different for each program/record. Refers to the academic program completion date. Post-completion and STEM OPT starts after this date (graduation), while pre-completion OPT occurs before. OPT authorization start dates may be slightly before the program end date</td>
  </tr>
  <tr>
    <td>43</td>
    <td><strong>STUDENT_EDU_LEVEL_DESC</strong></td>
    <td>Educational level</td>
    <td>String (lowercase)</td>
    <td>Variable</td>
    <td>E.g., "bachelor's", "master's", "doctorate"; changes with degree progression</td>
  </tr>
</tbody>
</table>

### Employment Information (OPT/CPT)

<table>
<thead>
  <tr>
    <th style="width: 5%;">Position</th>
    <th style="width: 15%;">Column Name</th>
    <th style="width: 18%;">Description</th>
    <th style="width: 10%;">Data Type</th>
    <th style="width: 10%;">Variability</th>
    <th style="width: 42%;">Notes</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>21</td>
    <td><strong>EMPLOYER_NAME</strong></td>
    <td>Name of employer</td>
    <td>String (lowercase)</td>
    <td>Variable</td>
    <td>Not standardized in raw data; only present for students with work authorization</td>
  </tr>
  <tr>
    <td>22</td>
    <td><strong>EMPLOYER_CITY</strong></td>
    <td>City of employer address</td>
    <td>String (lowercase)</td>
    <td>Variable</td>
    <td>-</td>
  </tr>
  <tr>
    <td>23</td>
    <td><strong>EMPLOYER_STATE</strong></td>
    <td>State of employer address</td>
    <td>String (lowercase)</td>
    <td>Variable</td>
    <td>Standardized during cleaning: abbreviations converted to full state names (e.g., "MA" → "massachusetts")</td>
  </tr>
  <tr>
    <td>24</td>
    <td><strong>EMPLOYER_ZIP_CODE</strong></td>
    <td>ZIP code of employer address</td>
    <td>String</td>
    <td>Variable</td>
    <td>Standardized during cleaning: leading zeros restored via padding for states/territories with ZIP codes starting with 0 (MA, RI, CT, NH, ME, VT, NJ, PR, VI) where raw data ZIP codes were 4 digits instead of 5</td>
  </tr>
  <tr>
    <td>25</td>
    <td><strong>JOB_TITLE</strong></td>
    <td>Job title or position</td>
    <td>String (lowercase)</td>
    <td>Variable</td>
    <td>Sparsely populated</td>
  </tr>
  <tr>
    <td>26</td>
    <td><strong>EMPLOYMENT_DESCRIPTION</strong></td>
    <td>Type of employment authorization</td>
    <td>String (lowercase)</td>
    <td>Variable</td>
    <td>Values: "opt" (Optional Practical Training) or "cpt" (Curricular Practical Training)</td>
  </tr>
  <tr>
    <td>27</td>
    <td><strong>AUTHORIZATION_START_DATE</strong></td>
    <td>Start date of work authorization</td>
    <td>Date (YYYY-MM-DD)</td>
    <td>Variable</td>
    <td>Always present if OPT_AUTHORIZATION_START_DATE is present</td>
  </tr>
  <tr>
    <td>28</td>
    <td><strong>AUTHORIZATION_END_DATE</strong></td>
    <td>End date of work authorization</td>
    <td>Date (YYYY-MM-DD)</td>
    <td>Variable</td>
    <td>Always present if OPT_AUTHORIZATION_END_DATE is present</td>
  </tr>
  <tr>
    <td>29</td>
    <td><strong>OPT_AUTHORIZATION_START_DATE</strong></td>
    <td>OPT-specific authorization start</td>
    <td>Date (YYYY-MM-DD)</td>
    <td>Variable</td>
    <td>Less comprehensive; when present, matches AUTHORIZATION_START_DATE</td>
  </tr>
  <tr>
    <td>30</td>
    <td><strong>OPT_AUTHORIZATION_END_DATE</strong></td>
    <td>OPT-specific authorization end</td>
    <td>Date (YYYY-MM-DD)</td>
    <td>Variable</td>
    <td>Less comprehensive; when present, matches AUTHORIZATION_END_DATE</td>
  </tr>
  <tr>
    <td>31</td>
    <td><strong>OPT_EMPLOYER_START_DATE</strong></td>
    <td>Date employment with this employer began</td>
    <td>Date (YYYY-MM-DD)</td>
    <td>Variable</td>
    <td>Can differ from authorization dates if student changed employers mid-OPT</td>
  </tr>
  <tr>
    <td>32</td>
    <td><strong>OPT_EMPLOYER_END_DATE</strong></td>
    <td>Date employment with this employer ended</td>
    <td>Date (YYYY-MM-DD)</td>
    <td>Variable</td>
    <td>May differ from authorization dates</td>
  </tr>
  <tr>
    <td>33</td>
    <td><strong>EMPLOYMENT_OPT_TYPE</strong></td>
    <td>Type of OPT</td>
    <td>String (lowercase)</td>
    <td>Variable</td>
    <td>Post-completion: Standard 12-month OPT available to all F-1 graduates after degree completion. STEM: Additional 24-month extension for STEM degree holders (total 36 months possible). Pre-completion: OPT used before graduation, comprising a small fraction of total OPT use, largely utilized by graduate students. Individuals often have multiple types across their records</td>
  </tr>
  <tr>
    <td>34</td>
    <td><strong>EMPLOYMENT_TIME</strong></td>
    <td>Full-time or part-time employment</td>
    <td>String (lowercase)</td>
    <td>Variable</td>
    <td>Values: "full time" or "part time"</td>
  </tr>
  <tr>
    <td>35</td>
    <td><strong>UNEMPLOYMENT_DAYS</strong></td>
    <td>Days of unemployment during OPT</td>
    <td>Numeric</td>
    <td>Variable</td>
    <td>Cumulative days; OPT allows max 90 days</td>
  </tr>
</tbody>
</table>

### Financial Information

<table>
<thead>
  <tr>
    <th style="width: 5%;">Position</th>
    <th style="width: 15%;">Column Name</th>
    <th style="width: 18%;">Description</th>
    <th style="width: 10%;">Data Type</th>
    <th style="width: 10%;">Variability</th>
    <th style="width: 42%;">Notes</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>36</td>
    <td><strong>TUITION_FEES</strong></td>
    <td>Annual tuition and fees (USD)</td>
    <td>Numeric</td>
    <td>Constant</td>
    <td>Constant for a given STUDENT_KEY (program of study). Amounts suggest this is an annual quantity, but the specific year it applies to is unknown. Values typically vary when the same individual (INDIVIDUAL_KEY) pursues multiple programs. Self-reported or institutional data</td>
  </tr>
  <tr>
    <td>37</td>
    <td><strong>STUDENTS_PERSONAL_FUNDS</strong></td>
    <td>Student's personal funds (USD)</td>
    <td>Numeric</td>
    <td>Constant</td>
    <td>Constant for a given STUDENT_KEY (program of study). Values may vary when the same individual (INDIVIDUAL_KEY) pursues multiple programs. Financial support from student/family</td>
  </tr>
  <tr>
    <td>38</td>
    <td><strong>FUNDS_FROM_THIS_SCHOOL</strong></td>
    <td>Funding from the institution (USD)</td>
    <td>Numeric</td>
    <td>Constant</td>
    <td>Constant for a given STUDENT_KEY (program of study). Values may vary when the same individual (INDIVIDUAL_KEY) pursues multiple programs. Scholarships, assistantships, etc.</td>
  </tr>
  <tr>
    <td>39</td>
    <td><strong>FUNDS_FROM_OTHER_SOURCES</strong></td>
    <td>Funding from other sources (USD)</td>
    <td>Numeric</td>
    <td>Constant</td>
    <td>Constant for a given STUDENT_KEY (program of study). Values may vary when the same individual (INDIVIDUAL_KEY) pursues multiple programs. External scholarships, government funding, etc.</td>
  </tr>
  <tr>
    <td>40</td>
    <td><strong>ON_CAMPUS_EMPLOYMENT</strong></td>
    <td>Likely earnings from on-campus employment (USD)</td>
    <td>Numeric</td>
    <td>Constant</td>
    <td>Constant for a given STUDENT_KEY (program of study). Interpretation uncertain; may be 0.0 or blank if no on-campus work</td>
  </tr>
</tbody>
</table>

### Status Information

<table>
<thead>
  <tr>
    <th style="width: 5%;">Position</th>
    <th style="width: 15%;">Column Name</th>
    <th style="width: 18%;">Description</th>
    <th style="width: 10%;">Data Type</th>
    <th style="width: 10%;">Variability</th>
    <th style="width: 42%;">Notes</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>41</td>
    <td><strong>REQUESTED_STATUS</strong></td>
    <td>Requested change of visa status</td>
    <td>String</td>
    <td>Variable</td>
    <td>Change of status from F-1 to another visa type; codes are generally self-explanatory (e.g., "o1a"). H-1B variants: "1b1" and "h1b" are regular H-1Bs, "1b2" is H-1B2, "1b3" is H-1B3, "hsc" is H-1B1; constant across all rows for a unique INDIVIDUAL_KEY in 99.8% of cases</td>
  </tr>
  <tr>
    <td>42</td>
    <td><strong>STATUS_CODE</strong></td>
    <td>Not reliable; interpretation unclear</td>
    <td>String (lowercase)</td>
    <td>Variable</td>
    <td>Values: "completed", "deactivated", "terminated", "active", "canceled"; constant across all rows for a unique INDIVIDUAL_KEY in 96% of cases</td>
  </tr>
</tbody>
</table>

### Administrative Fields

<table>
<thead>
  <tr>
    <th style="width: 5%;">Position</th>
    <th style="width: 15%;">Column Name</th>
    <th style="width: 18%;">Description</th>
    <th style="width: 10%;">Data Type</th>
    <th style="width: 10%;">Variability</th>
    <th style="width: 42%;">Notes</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>46</td>
    <td><strong>Year</strong></td>
    <td>Fiscal year indicator</td>
    <td>Integer</td>
    <td>-</td>
    <td><strong>Constructed variable:</strong> Created by extracting the fiscal year from each file's name and adding it to every row in that year's file. This allows all years to be combined while retaining the data source for each record. FY is Oct 1 - Sept 30; indicates which year file contains this record</td>
  </tr>
</tbody>
</table>

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
