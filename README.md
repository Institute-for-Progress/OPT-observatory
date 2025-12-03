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

## Repository Structure

```
OPT-observatory/
├── README.md                     # This file
├── setup.sh                      # Install R and Python dependencies
├── renv.lock                     # R package versions (reproducibility)
├── requirements.txt              # Python package requirements
├── data/                         # Downloaded from Google Drive (not in Git)
│   ├── raw/
│   │   ├── USE_corrected_file_names/      # Raw SEVIS files with corrected names (20 CSV files)
│   │   └── AVOID_uncorrected_file_names/  # Original files (do not use)
│   ├── cleaned_corrected_file_names/      # Pre-cleaned files (20 CSV files)
│   ├── data_dictionary.md        # Data dictionary
│   └── data_processing.md        # Processing documentation
└── misc/                         # Internal code and configuration
    ├── code/
    │   ├── load_data_parallel.R  # Data cleaning script
    │   └── data_loader.py        # Python data loading utilities
    ├── supporting_data.zip       # Supporting datasets (crosswalks, etc.)
    └── sevis_data_processing_config.json
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
# This creates the data/ folder with raw/ (corrected and uncorrected versions),
# cleaned_corrected_file_names/, and documentation files
```

### 3. Install Dependencies (R, optionally Python)

```bash
./setup.sh
```

This script:
- Creates a Python virtual environment (`venv/`)
- Installs Python packages 
- Installs R packages using renv (reproducible package management)

The data bundle includes both **raw** and **cleaned** files for transparency. To read more about the cleaning process, see [Data Processing](data/data_processing.md). To run the cleaning script `misc/code/load_data_parallel.R` on the raw files use:

   ```bash
   Rscript misc/code/load_data_parallel.R
   ```

### 4. If Using Python
See `misc/code/data_loader.py` for a pre-written data loading function that may simplify further analyses.

## How to Reach Us
Please contact violet@ifp.org with any questions about the contents of this repository or the OPT Observatory, to note further data issues, or share findings from work using this data.