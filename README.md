# Student and Exchange Visitor Information System (SEVIS): F-1 \& J-1 Study and Employment Data, FY2004-2023 

The Institute for Progress obtained detailed microdata excerpted from the Student and Exchange Visitor Information System (SEVIS), including information on the study and work patterns of all F-1 international students and J-1 exchange visitors in the United States from fiscal years 2004-2023. The data was requested from U.S. Immigration and Customs Enforcement (ICE) under the Freedom of Information Act (FOIA). 

## Background
This data was originally obtained and is available to download from the ICE FOIA library in 13 parts (see release #43657, dated October 1st 2024). In the original release, each year of data contained multiple sub-component files. However our raw data aggregates these to a single file per year (but does not otherwise modify them). While we include the original data's files for both F-1 international students and J-1 exchange visitors, the documentation we provide focuses only on the F-1 data, which underlies the [OPT Observatory](https://optobservatory.org/).

## Get Started
- [Download our raw and cleaned files](https://drive.google.com/file/d/1trvgI1NOojxN6oFB0eRfwvIZ62rNiFpS/view?usp=sharing).
- Read our [data dictionary](data_dictionary.md), which describes the cleaned data to the best of our ability, as it was not accompanied by any official documentation.
- See our [data processing documentation](https://github.com/Institute-for-Progress/OPT-observatory/blob/main/docs/data_processing.md) for detailed information on how we produce both annual raw and cleaned files. 

## Attribution

Please cite the OPT Observatory if you use code or cleaned data from this repository:

``` Violet Buxton-Walsh & Jeremy Neufeld. OPT Observatory. Washington, DC: Institute for Progress, October 2025. https://optobservatory.org/. ```

If you use the raw data, we ask that you acknowledge IFP’s role in obtaining it, for example:

``` U.S. Immigration and Customs Enforcement. Student and Exchange Visitor Information System (SEVIS). Data requested by the Institute for Progress under the Freedom of Information Act, public release #43657, published October 1st 2024. ```

## Repository Structure [to do]

```
OPT-observatory/
├── README.md                     # This file
├── setup.sh                      # Install R dependencies
├── renv.lock                     # R package versions (reproducibility)
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

## Reproducing the Data Cleaning (Optional)

Although our cleaned data is made available [here](https://drive.google.com/file/d/1trvgI1NOojxN6oFB0eRfwvIZ62rNiFpS/view?usp=sharing), users may want to clean the raw data themselves to independently verify or make modifications to our work. To run our analysis:

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/OPT-observatory.git
cd OPT-observatory
```

### 2. Download the Data

Download the [data bundle](https://drive.google.com/file/d/1trvgI1NOojxN6oFB0eRfwvIZ62rNiFpS/view?usp=sharing) from Google Drive and put it in the `data` folder:

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



The data bundle includes both **raw** and **cleaned** files for transparency. To read more about the cleaning process, see [Data Processing](docs/data_processing.md). To run the cleaning script `scripts/load_data_parallel.R` on the raw files use:
   
   ```bash
   Rscript scripts/load_data_parallel.R
   ```

## How to Reach Us
Please contact violet@ifp.org with any questions about the contents of this repository or the OPT Observatory, to note further data issues, or share findings from work using this data.