# Data Processing Documentation

## Overview

The `load_data_parallel.R` script transforms large-scale SEVIS F-1 visa microdata from raw CSV dumps (~25 GB) into cleaned, analysis-ready files. The script is designed to handle government microdata efficiently using parallel processing and sophisticated data validation.

## Table of Contents

1. [Background: SEVIS F-1 Data](#background-sevis-f-1-data)
2. [Main Function: `combine_and_clean_data_optimized()`](#main-function-combine_and_clean_data_optimized)
   - [Function Signature](#function-signature)
3. [Processing Modes](#processing-modes)
   - [Mode 1: Raw File Combination](#mode-1-raw-file-combination-write_raw_files--true)
   - [Mode 2: Data Cleaning](#mode-2-data-cleaning-write_clean_files--true)
   - [Mode 3: Full Pipeline](#mode-3-full-pipeline-both-flags--true)
4. [Parameter Definitions](#parameter-definitions)
5. [Important Processing Details](#important-processing-details)
   - [Column Name Standardization](#1-column-name-standardization)
   - [Duplicate Column Handling](#2-sophisticated-duplicate-column-handling)
   - [Header Consistency Validation](#3-header-consistency-validation)
   - [Date Standardization](#4-date-standardization-and-validation)
   - [Text Cleaning](#5-text-cleaning-and-standardization)
   - [Parallel Processing](#6-parallel-processing)
   - [CPT Filtering](#7-cpt-filtering-keep_cpt-parameter)
6. [Usage Examples](#usage-examples)
7. [Output Statistics](#output-statistics)
8. [Common Issues and Troubleshooting](#common-issues-and-troubleshooting)
9. [Performance Notes](#performance-notes)
10. [Cross-Platform Compatibility](#cross-platform-compatibility)
    - [Windows-Specific Issues](#windows-specific-issues)
    - [Linux-Specific Considerations](#linux-specific-considerations)
    - [General Recommendations](#general-recommendations-for-all-platforms)
11. [Privacy and Security Considerations](#privacy-and-security-considerations)
12. [Related Functions](#related-functions)

---

## Background: SEVIS F-1 Data

**SEVIS (Student and Exchange Visitor Information System)** tracks international students on F-1 visas in the United States. This data, obtained via FOIA from ICE, covers 2004-2023 (~25GB) with record-level data where each row represents an authorization period, not a unique person.

⚠️ **Data Quality Note**: Only data from 2010-2022 is considered reliable for analysis.

📖 **For detailed information** about data structure, column definitions, and how records are organized, see the **[Data Dictionary](data_dictionary.md)**.

## Main Function: `combine_and_clean_data_optimized()`

This is the primary entry point for data processing. The function operates in **two distinct modes** controlled by flags, which determine what processing steps are executed.

### Function Signature

```r
combine_and_clean_data_optimized(
  root_dir,               # Path to raw data (organized by year in subdirectories)
  raw_output_dir,         # Where to write combined raw files
  clean_output_dir,       # Where to write cleaned files
  write_raw_files = FALSE,   # Flag: combine raw files?
  write_clean_files = FALSE, # Flag: clean and process files?
  exclude_cols = DEFAULT_EXCLUDE_COLS,  # Columns to exclude (irrelevant/redacted placeholder data)
  verbose = TRUE,         # Print detailed progress information?
  year_range = NULL,      # Filter to specific years (e.g., 2010:2020)
  keep_cpt = TRUE         # Keep CPT (Curricular Practical Training) records?
)
```

## Processing Modes

### Mode 1: Raw File Combination (`write_raw_files = TRUE`)

**What it does:**
- Scans `root_dir` for year-based subdirectories
- Combines multiple CSV files within each year into a single file per year
- Validates header consistency across files
- Removes excluded columns (irrelevant fields and FOIA-redacted placeholder data)
- Handles duplicate columns intelligently
- Writes output to `raw_output_dir` as `YYYY_all.csv`

**When to use:**
- Initial data ingestion from raw government dumps
- When source files have been updated and you need to rebuild combined files

**Requirements:**
- `root_dir` must contain subdirectories (typically named by year: 2010/, 2011/, etc.)
- Each subdirectory must contain CSV files with consistent structure
- `raw_output_dir` must be specified

### Mode 2: Data Cleaning (`write_clean_files = TRUE`)

**What it does:**
- Reads combined raw files from `raw_output_dir`
- Removes duplicate records
- Optionally filters out CPT records (if `keep_cpt = FALSE`)
- Standardizes date columns (13 different date fields)
- Nullifies future dates (data quality check)
- Cleans and standardizes text fields (cities, states, school names)
- Converts state abbreviations to full names
- Writes output to `clean_output_dir` as `cleaned_YYYY_all.csv`

**When to use:**
- After raw files have been combined
- When you need analysis-ready, standardized data
- When you want to update data cleaning logic without re-reading source files

**Requirements:**
- `raw_output_dir` must contain combined raw CSV files
- `clean_output_dir` must be specified

### Mode 3: Full Pipeline (Both Flags = TRUE)

Run both modes sequentially to go directly from raw source files to cleaned output.

## Parameter Definitions

### `root_dir`
- **Type**: String (file path)
- **Purpose**: Location of raw SEVIS data files
- **Expected structure**: Subdirectories named by year, each containing CSV files
  ```
  root_dir/
    ├── 2010/
    │   ├── F1_Records_Jan.csv
    │   ├── F1_Records_Feb.csv
    │   └── ...
    ├── 2011/
    │   └── ...
  ```

### `raw_output_dir` and `clean_output_dir`
- **Type**: String (file path)
- **Purpose**: Output directories for different processing stages
- **Note**: Can be NULL if corresponding flag is FALSE
- **Output naming convention**:
  - Raw: `YYYY_all.csv`
  - Clean: `cleaned_YYYY_all.csv`

### `write_raw_files` and `write_clean_files`
- **Type**: Boolean
- **Purpose**: Control which processing stages to execute
- **Important**: These flags make the function behave completely differently
  - `write_raw_files = TRUE`: Reads from `root_dir`, writes to `raw_output_dir`
  - `write_clean_files = TRUE`: Reads from `raw_output_dir`, writes to `clean_output_dir`
  - Both TRUE: Full pipeline from source to cleaned data

### `exclude_cols`
- **Type**: Character vector
- **Default**: `DEFAULT_EXCLUDE_COLS` (see below)
- **Purpose**: Excludes columns that are irrelevant, duplicated, or contain redacted/placeholder data from the FOIA office
- **Default exclusions**:
  - `Date_of_Birth` / `Birth_Date` (already redacted to placeholder values by FOIA office)
  - `School_Fund_Type` (irrelevant for most analyses)
  - Various naming variations of these fields

### `year_range`
- **Type**: Character vector or NULL
- **Example**: `as.character(2010:2022)` or `c("2015", "2016", "2017")`
- **Purpose**: Process only specific years
- **Useful for**: Testing, incremental updates, targeted analyses
- **Recommended range**: `as.character(2010:2022)` for reliable data (see Data Quality Note above)

### `keep_cpt`
- **Type**: Boolean
- **Default**: TRUE
- **Purpose**: Include or exclude CPT (Curricular Practical Training) records
- **Background**: CPT is work authorization during studies; OPT is post-graduation. Set to FALSE if you want to analyze only post-graduation employment (OPT).

### `verbose`
- **Type**: Boolean
- **Default**: TRUE
- **Purpose**: Print detailed processing information
- **Output includes**: File counts, memory usage, data cleaning statistics, warnings

## Important Processing Details

### 1. Column Name Standardization

**Why this matters:** Raw SEVIS data has inconsistent column naming (spaces, punctuation, mixed case). Standardization ensures consistent references across files and analyses.

**How it works** (lines 235-242 in load_data_parallel.R):
1. Trims whitespace
2. Removes ampersands (&) and apostrophes (')
3. Converts periods (.) and hyphens (-) to underscores (_)
4. Converts spaces to underscores
5. **Converts all column names to UPPERCASE**

**Example transformations:**
- `Employer City` → `EMPLOYER_CITY`
- `Student's Edu. Level` → `STUDENTS_EDU_LEVEL`
- `Program-Start-Date` → `PROGRAM_START_DATE`

**Important:** All column names in the output files will be in UPPERCASE with underscores.

### 2. Sophisticated Duplicate Column Handling

**Why this matters:** Government data exports sometimes contain duplicate columns with slight variations (e.g., `Employer_City` and `Employer_City...23`).

**How it works** (lines 344-420 in load_data_parallel.R):
1. Identifies columns with the same base name (ignoring `.{3}NN` suffixes)
2. Compares data in duplicate columns:
   - If **100% identical**: keeps first column, removes duplicates
   - If **>95% similar**: keeps the column with fewer missing (NA) values
   - If **<95% similar**: keeps both columns and warns for manual review

**Example scenario:**
- `Employer_City` has 10,000 non-missing values
- `Employer_City...23` has 9,500 non-missing values
- Data is 98% similar
- **Result**: Keeps `Employer_City`, removes `Employer_City...23`

### 3. Header Consistency Validation

**Why this matters:** Files within a year directory must have identical column structures, or data combining will fail.

**When it runs:**
- Before combining files within each year (Mode 1)
- Before cleaning combined files (Mode 2)

**What happens on failure:**
- Script stops with detailed error message
- Shows which columns are missing or extra
- Lists all mismatched files

**Example error output:**
```
*** FATAL ERROR: Column structure mismatch in files in year 2015 ***
Reference file (2015_Jan.csv) has 47 columns:
SEVIS_ID, FIRST_NAME, LAST_NAME, ...

File: 2015_Dec.csv (has 45 columns)
  Missing columns: EMPLOYER_START_DATE, EMPLOYER_END_DATE
```

### 4. Date Standardization and Validation

**Date columns processed** (13 total):
- Entry/exit dates: `First_Entry_Date`, `Last_Entry_Date`, `Last_Departure_Date`
- Visa dates: `Visa_Issue_Date`, `Visa_Expiration_Date`
- Program dates: `Program_Start_Date`, `Program_End_Date`
- Authorization dates: `Authorization_Start_Date`, `Authorization_End_Date`, `OPT_Authorization_Start_Date`, `OPT_Authorization_End_Date`, `OPT_Employer_Start_Date`, `OPT_Employer_End_Date`

**Processing steps:**
1. Removes timezone information
2. Tries multiple date formats (ymd, mdy, dmy, etc.)
3. Validates parsing success rate (warns if <99% successful)
4. **Special handling for `First_Entry_Date`**: Nullifies dates after 2024-01-01 (data quality check for impossible future dates given data publication in fall 2023)

### 5. Text Cleaning and Standardization

**Columns cleaned:**
- Geographic: `Employer_City`, `Employer_State`, `Campus_City`, `Campus_State`
- Educational: `Student_Edu_Level_Desc`, `School_Name`

**Cleaning operations:**
1. Convert to lowercase
2. Remove leading/trailing whitespace
3. Collapse multiple spaces to single space
4. Remove punctuation
5. **For state columns specifically**: Convert abbreviations to full names
   - Example: `CA` → `california`, `NY` → `new york`

**Why lowercase?** Ensures consistent matching and grouping in analyses (e.g., "New York" vs "new york" vs "NEW YORK" all become "new york").

### 6. Parallel Processing

**Configuration (line 34 in load_data_parallel.R):**
```r
plan(multisession, workers = min(4, parallel::detectCores() - 1))
```

**How it works:**
- Automatically detects available CPU cores
- Reserves 1 core for system operations
- **Capped at maximum 4 workers** (optimized for M3 Mac with 16GB RAM)
- Processes different years simultaneously
- Each year is self-contained (no data sharing between parallel processes)

**Performance impact:**
- Can reduce processing time from hours to minutes for full dataset
- Memory usage scales with number of workers (~2-3 GB per worker at peak)

**Hardware-specific considerations:**

⚠️ **You may need to adjust the worker count:** The default cap of 4 workers is optimized for 16GB RAM. Edit line 34 in `scripts/load_data_parallel.R` and change `min(4, ...)` to:
- **More powerful machines** (64GB+ RAM): increase to 6-8 workers
- **Less powerful machines** (8GB RAM): decrease to 2 workers
- **Memory errors**: reduce workers or limit `year_range` to fewer years

### 7. CPT Filtering (`keep_cpt` parameter)

**Background:**
- **CPT (Curricular Practical Training)**: Work authorization during studies
- **OPT (Optional Practical Training)**: Work authorization after graduation

**When `keep_cpt = TRUE` (default):**
- Retains all employment records including CPT
- Necessary for comprehensive student employment analyses
- Required for studying work patterns during studies

**When `keep_cpt = FALSE`:**
- Removes all records where `Employment_Description == "CPT"`
- Reduces data volume significantly
- Appropriate for analyses focused exclusively on post-graduation employment (OPT only)

## Usage Examples

### Example 1: Full Pipeline with Default Settings

Process reliable years (2010-2022) with default settings (includes both OPT and CPT):

```r
result <- combine_and_clean_data_optimized(
  root_dir = "/path/to/sevis/raw_data",
  raw_output_dir = "/path/to/output/raw",
  clean_output_dir = "/path/to/output/clean",
  write_raw_files = TRUE,
  write_clean_files = TRUE,
  verbose = TRUE,
  year_range = as.character(2010:2022)  # Recommended reliable years
  # keep_cpt defaults to TRUE, so both CPT and OPT records are included
)
```

### Example 2: Full Pipeline (Raw → Clean) - OPT Only

Process reliable years (2010-2022), explicitly excluding CPT records for OPT-only analysis:

```r
result <- combine_and_clean_data_optimized(
  root_dir = "/path/to/sevis/raw_data",
  raw_output_dir = "/path/to/output/raw",
  clean_output_dir = "/path/to/output/clean_opt_only",
  write_raw_files = TRUE,
  write_clean_files = TRUE,
  keep_cpt = FALSE,  # Override default: exclude CPT to focus on post-graduation employment
  verbose = TRUE,
  year_range = as.character(2010:2022)  # Recommended reliable years
)
```

### Example 3: Only Combine Raw Files

Useful when you just need to consolidate source files:

```r
result <- combine_and_clean_data_optimized(
  root_dir = "/path/to/sevis/raw_data",
  raw_output_dir = "/path/to/output/raw",
  clean_output_dir = NULL,  # Not needed
  write_raw_files = TRUE,
  write_clean_files = FALSE,
  year_range = as.character(2020:2022)  # Just recent reliable years
)
```

### Example 4: Only Clean Existing Raw Files

Useful when re-running cleaning with different parameters:

```r
result <- combine_and_clean_data_optimized(
  root_dir = NULL,  # Not needed
  raw_output_dir = "/path/to/output/raw",  # Input for cleaning
  clean_output_dir = "/path/to/output/clean_with_cpt",
  write_raw_files = FALSE,
  write_clean_files = TRUE,
  # keep_cpt = TRUE by default, so CPT records will be included
  year_range = as.character(2010:2022)
)
```

### Example 5: Testing with Single Year

Test the pipeline on just one year (OPT-only):

```r
result <- combine_and_clean_data_optimized(
  root_dir = "/path/to/sevis/raw_data",
  raw_output_dir = "/path/to/output/test_raw",
  clean_output_dir = "/path/to/output/test_clean",
  write_raw_files = TRUE,
  write_clean_files = TRUE,
  keep_cpt = FALSE,  # Exclude CPT for testing
  verbose = TRUE,
  year_range = c("2020")  # Single year
)
```

## Output Statistics

When cleaning is complete, the function returns summary statistics:

```r
$cleaning_summary
  $2020
    $initial_rows: 1234567
    $duplicates_removed: 1523
    $cpt_rows_removed: 45678  # Only if keep_cpt = FALSE
    $future_dates_nullified: 234
```

## Common Issues and Troubleshooting

### Issue: "Column structure mismatch"

**Cause:** Files within a year have different columns
**Solution:**
1. Check which columns are mismatched (error message shows details)
2. Verify source data integrity
3. Check if some files are from different data releases

### Issue: "No valid CSV files found"

**Cause:** Directory structure doesn't match expected format
**Solution:**
1. Verify `root_dir` contains year subdirectories
2. Check that subdirectories contain CSV files
3. Ensure CSV files are readable (not corrupted)

### Issue: Low date parsing success rate

**Cause:** Unusual date formats in source data
**Solution:**
1. Check verbose output for examples of unparseable dates
2. May need to add additional date formats to `parse_dates_safely()` function
3. Review data source documentation for date format specifications

### Issue: Memory errors during parallel processing

**Cause:** Insufficient RAM for number of workers
**Solution:**
1. Reduce number of workers (modify line 34 in script)
2. Process fewer years at once (use `year_range` parameter)
3. Process on machine with more RAM

## Performance Notes

- **Processing time**: Full pipeline for 2004-2023 (~25 GB) typically takes 30-60 minutes on 4-core machine
- **Memory usage**: Peak usage ~8-12 GB for parallel processing of 4 years
- **Disk I/O**: Main bottleneck; SSD strongly recommended
- **Parallelization efficiency**: Near-linear speedup up to 4 workers; diminishing returns beyond that

## Cross-Platform Compatibility

This script was developed on **macOS (M3 Mac with 16GB RAM)** but should work on Windows and Linux with the following considerations:

### Windows-Specific Issues

**1. Parallel Processing Differences**
- Windows doesn't support forking, so `multisession` uses socket connections
- **Result**: Slightly slower and more memory overhead than on Mac/Linux
- **Recommendation**: Windows users may want to reduce worker count by 1 (e.g., use 3 instead of 4)

**2. Package Installation**
- Some R packages may require **Rtools** (a collection of build tools for Windows)
- **Required packages**: `tidyverse`, `lubridate`, `fs`, `readr`, `dplyr`, `data.table`, `parallel`, `future`, `future.apply`
- **Installation**: If packages fail to install, download and install Rtools from: https://cran.r-project.org/bin/windows/Rtools/

**3. File Paths**
- The script uses the `fs` package which handles cross-platform paths automatically
- ⚠️ **Important**: The example code at the bottom of the script (lines 976-985) contains Mac-specific paths
- **Windows users**: Replace with Windows paths using forward slashes or escaped backslashes:
  ```r
  # Option 1: Forward slashes (recommended)
  root_dir = "C:/Users/YourName/Data/sevis_raw"

  # Option 2: Escaped backslashes
  root_dir = "C:\\Users\\YourName\\Data\\sevis_raw"
  ```

**4. Memory Management**
- Windows tends to be less efficient with memory than Mac/Linux
- **Recommendation**: If you have 16GB RAM on Windows, consider using 2-3 workers instead of 4

**5. Character Encoding**
- The script specifies UTF-8 encoding, which should work correctly
- If you encounter encoding errors with special characters, ensure your R session is using UTF-8:
  ```r
  Sys.setlocale("LC_ALL", "English_United States.utf8")
  ```

### Linux-Specific Considerations

**1. Parallel Processing**
- Linux supports forking, so `multisession` will be efficient (similar to Mac)
- Generally performs well with the default configuration

**2. File System**
- Linux file systems are case-sensitive (unlike Mac/Windows by default)
- Ensure file and directory names match exactly as expected

**3. Package Installation**
- Most packages install smoothly, but may require system dependencies
- If installation fails, you may need to install system libraries:
  ```bash
  # Ubuntu/Debian
  sudo apt-get install libcurl4-openssl-dev libssl-dev libxml2-dev

  # CentOS/RHEL
  sudo yum install libcurl-devel openssl-devel libxml2-devel
  ```

### General Recommendations for All Platforms

1. **Test first**: Run the script on a single year (`year_range = c("2020")`) before processing the full dataset
2. **Monitor resources**: Watch memory usage during the first run to ensure your system can handle the workload
3. **Adjust workers**: Modify line 34 based on your system's performance
4. **Comment out example code**: The example at lines 976-985 will run automatically when you source the script. Comment it out or modify paths before running:
   ```r
   # result <- combine_and_clean_data_optimized(
   #   root_dir = "YOUR_PATH_HERE",
   #   ...
   # )
   ```

## Data Handling Considerations

1. **Default column exclusions**: The script automatically excludes columns that contain FOIA-redacted placeholder data (e.g., birth dates already replaced with nonsense values) and irrelevant fields
2. **Data source**: This data has already been processed by ICE's FOIA office, so actual personally identifiable information has been removed/redacted at the source
3. **Custom exclusions**: Use `exclude_cols` parameter to exclude additional irrelevant or problematic columns
4. **Output file permissions**: Ensure output directories have appropriate access controls
5. **Data retention**: Be aware of institutional policies on retaining government microdata

## Related Functions

While `combine_and_clean_data_optimized()` is the main entry point, the script contains several modular functions that can be used independently:

- `process_yearly_data_parallel()`: Raw file combination only
- `clean_yearly_data_optimized()`: Data cleaning only
- `check_directory_headers()`: Validate header consistency
- `clean_sevis_columns()`: Text cleaning for specific columns
- `parse_dates_safely()`: Date standardization

These can be useful for custom workflows or debugging specific issues.
