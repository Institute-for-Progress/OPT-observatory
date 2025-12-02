# OPT Observatory

Analysis pipeline for F-1 student OPT (Optional Practical Training) participation patterns using SEVIS data.

## Overview

Reproducible analysis pipeline for studying F-1 international student transitions to Optional Practical Training (OPT) employment in the United States. The analysis uses SEVIS (Student and Exchange Visitor Information System) data obtained through FOIA requests.

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/OPT-observatory.git
cd OPT-observatory
```

### 2. Download Data

Download the data bundle from Google Drive:

- **Link:** https://drive.google.com/file/d/1trvgI1NOojxN6oFB0eRfwvIZ62rNiFpS/view?usp=sharing
- **Size:** ~50 GB (compressed)
- **Contents:**
  - Raw SEVIS F-1 data (2004-2023)
  - Pre-cleaned SEVIS data (2004-2023)
  - Supporting data files (HUD, BLS LAUS, DHS, NSF)

Extract the data:
```bash
# Download data.zip from link above
unzip data.zip
# This creates the data/ folder with raw/, cleaned/, and supporting/ subdirectories
```

### 3. Install Dependencies (Python + R)

```bash
./setup.sh
```

This script:
- Creates a Python virtual environment (`venv/`)
- Installs Python packages 
- Installs R packages using renv (reproducible package management)


## Repository Structure

```
OPT-observatory/
├── README.md                     # This file
├── setup.sh                      # Install R dependencies
├── renv.lock                     # R package versions (reproducibility)
├── .gitignore                    # Excludes large data files
├── data/                         # Downloaded from Zenodo (not in Git)
│   ├── raw/                      # Raw SEVIS FOIA files (20 CSV files, ~25 GB)
│   ├── cleaned/                  # Pre-cleaned files (20 CSV files, ~24 GB)
│   ├── supporting/               # Supporting datasets (~500 MB)
│   │   ├── dhs_stem_cip_code_list_July2024.csv
│   │   ├── cip_code_to_nsf_subject_field_mapping.csv
│   │   ├── working_pop_by_county_fips_2004-2023.csv
│   │   ├── HUD_zip_code_to_county_crosswalk_2010-2024.csv
│   │   └── zip_county_lma_quarterly.csv
└── scripts/
    └── load_data_parallel.R      # Data cleaning script (for transparency)
```

## Prerequisites

### Required Software

- **Python 3.8+** - To run pre-written data loading functions
- **R 4.5+** - To execute the data cleaning scripts locally (not reccomended)
- **Git** - Version control

### R Packages

All R packages are managed by **renv** and installed automatically by `setup.sh`:
- tidyverse - Data manipulation
- data.table - Fast data processing
- lubridate - Date handling
- fs - File system operations
- future/future.apply - Parallel processing

## Data

### SEVIS F-1 Data

FOIA request to U.S. Department of Homeland Security / Student and Exchange Visitor Program (SEVP)
- **Coverage:** 2004-2023
- **Records:** ~XX million F-1 student records
- **Includes:** Demographics, program information, OPT employment details

### Supporting Data

1. **DHS STEM CIP Code List** (July 2024)
   - Official list of STEM-designated degree programs
   - Source: Department of Homeland Security

2. **CIP to NSF Field Mapping**
   - Maps CIP codes to NSF broad/major/fine subject fields
   - Generated from NSF 7-field taxonomy

3. **HUD ZIP-County Crosswalk** (2010-2024)
   - Quarterly ZIP code to county FIPS mappings
   - Source: U.S. Department of Housing and Urban Development

4. **BLS LAUS Working Population** (2004-2023)
   - Annual civilian working population by county
   - Labor Market Area (LMA) designations
   - Source: Bureau of Labor Statistics Local Area Unemployment Statistics

5. **ZIP-LMA Mapping** (Quarterly, 2010-2024)
   - Joins HUD crosswalk with LMA data
   - Time-aware mapping for accurate geographic attribution

## Reproducing the Data Cleaning (Optional)

The data bundle includes both **raw** and **cleaned** files for transparency. To read more about the cleaning process, see [Data Processing](docs/data_processing.md). To verify by generating the clean files yourself, run the cleaning script `scripts/load_data_parallel.R` on the raw files:
   
   ```bash
   Rscript scripts/load_data_parallel.R
   ```

## Citation

If you use this data or code, please cite:

```
Buxton-Walsh, Violet. OPT Observatory GitHub repository. Washington, DC: Institute for Progress, December 2025. https://github.com/institute-for-progress/opt-observatory.
```

And cite the original SEVIS data source:
```
U.S. Immigration and Customs Enforcement. Student and Exchange Visitor Information System (SEVIS). Data requested by the Institute for Progress under the Freedom of Information Act, public release #43657, published October 1st 2024. --> 
<!-- ```

Please contact violet@ifp.org with questions or to note further data issues.
