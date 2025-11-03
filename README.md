# OPT Observatory GitHub Repository README

This repository contains code and analysis tools for F-1 student and J-1 research scholar data analysis. The repository keeps **code in GitHub** and **large data in Google Drive** (for macOS users) or local directories (for other platforms).

## 🚀 Quick Start

### Prerequisites

Before setting up the repository, ensure you have the following installed:

- **Git** - for cloning the repository
- **Python 3.12+** - for data analysis scripts
- **R 4.5.1+** - for statistical analysis
- **direnv** - for automatic environment management
- **Node.js 18+** (optional) - for frontend components

### Installation Instructions

#### macOS Users (Recommended)

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd stem-opt
   ```

2. **Run the unified setup script**:
   ```bash
   ./setup.sh
   ```
   
   This will:
   - Set up Python and R environments
   - Install all dependencies
   - Configure data access via Google Drive symlinks (GUI dialog will appear)
   - Set up direnv for automatic environment activation
   
   **When the data setup dialog appears:**
   - Pick `sevis_dta` at `Shared drives/DataDrive/repository_data/sevis_dta`
   - Pick `sevis_data` at `Shared drives/DataDrive/raw/sevis_data`

3. **Alternative: Use the original macOS setup**:
   - Double-click `scripts/setup_mac.command`
   - In the dialog:
     - Pick `sevis_dta` at `Shared drives/DataDrive/repository_data/sevis_dta`
     - Pick `sevis_data` at `Shared drives/DataDrive/raw/sevis_data`
   - Done. In your editor (Cursor/VS Code), you'll now see files under `dta/` and `data/`.

#### Windows/Linux Users

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd stem-opt
   ```

2. **Run the unified setup script**:
   ```bash
   ./setup.sh
   ```

3. **Manually set up data access**:
   - Replace the placeholder `data/` folder with your actual data directory
   - Replace the placeholder `dta/` folder with your actual dta directory
   - See the README files in these folders for more information

### Setup Options

The setup script supports several options:

```bash
./setup.sh [options]

Options:
  --no-python      Skip Python environment setup
  --no-r           Skip R environment setup
  --no-data        Skip data setup
  --recreate-venv  Delete and recreate Python virtual environment
  --force          Skip confirmation prompts
  --help           Show help message
```

---

## 📁 Repository Structure

```
stem-opt/
├── setup.sh                    # Unified setup script
├── requirements.txt            # Python dependencies
├── renv.lock                   # R package lockfile
├── .envrc                      # direnv configuration
├── data/                       # Data directory (symlinked on macOS)
├── dta/                        # Analysis output directory (symlinked on macOS)
├── scripts/                    # Analysis scripts
│   ├── production/             # Current F-1/J-1 analysis scripts
│   └── setup_mac.command       # macOS-specific data setup
├── notebooks/                  # Jupyter notebooks for analysis
├── website_testing/            # Web application components
└── ai-moonshots-master/        # Landing page project
```

## 🧠 What the Setup Does

### Environment Management
- **Python**: Creates a virtual environment (`.venv/`) and installs dependencies from `requirements.txt`
- **R**: Sets up renv environment and restores packages from `renv.lock`
- **direnv**: Configures automatic environment activation when entering the directory

### Data Access (macOS)
- Creates **symlinks**: `dta/` and `data/` point to your Google Drive folders
- **Protects** placeholder files with `git update-index --skip-worktree` so local replacements don't show as deletions
- Installs a **pre-commit hook** that blocks commits touching `data/` or `dta/`
- Backs up any existing directories before replacing them

### Data Access (Windows/Linux)
- Provides instructions for manually replacing placeholder folders with actual data directories
- Maintains the same folder structure for code compatibility

## 🔧 System Requirements

### Required Software
- **Git** - Version control
- **Python 3.12+** - Data analysis and processing
- **R 4.5.1+** - Statistical analysis
- **direnv** - Environment management
- **Homebrew** (macOS) - For installing system dependencies for R packages

### Python Dependencies
- pandas, numpy, pyarrow - Data manipulation
- google-cloud-bigquery - BigQuery integration
- fastapi, uvicorn - Web API framework
- ipykernel, jupyter - Notebook support
- polars - High-performance data processing

### R Dependencies
- tidyverse - Data manipulation and visualization
- lubridate - Date/time handling
- data.table - High-performance data processing
- fs, readr, purrr - File system and data I/O
- parallel, future - Parallel processing

## 📊 Analysis Workflows

### F-1/J-1 Analysis (Production)
The main analysis scripts are located in `scripts/production/`:

```bash
cd scripts/production/
python run_multi_state_analysis.py
```

This runs comprehensive F-1 student and J-1 research scholar analysis for all configured states/universities.

### R Analysis
For R-based analysis, see the `notebooks/` directory:

```bash
# Start R and load the environment
R
> renv::activate()
> library(tidyverse)  # Now you can use all packages
```

Or use Rscript directly:
```bash
Rscript -e "renv::activate(); library(tidyverse); # your R code here"
```

### Web Application
The `website_testing/` directory contains a web application for data visualization:

```bash
cd website_testing/
# Backend (Python)
uvicorn backend.app:app --reload

# Frontend (Node.js)
cd frontend_new/
npm install
npm run dev
```

## ⚠️ Troubleshooting

### Common Issues

1. **"direnv not found"**
   - Install direnv: https://direnv.net/docs/installation.html
   - Add hook to your shell: `eval "$(direnv hook zsh)"` (or bash)

2. **"Python not found"**
   - Install Python 3.12+: https://python.org/downloads/
   - On Windows, use `py` command instead of `python3`

3. **"R not found"**
   - Install R 4.5.1+: https://cran.r-project.org/
   - Ensure Rscript is in your PATH

4. **R package installation failures**
   - On macOS: Install Homebrew from https://brew.sh/
   - Run: `brew install harfbuzz fribidi freetype pkg-config`
   - On Linux: `sudo apt-get install libharfbuzz-dev libfribidi-dev libfreetype6-dev pkg-config`
   - On Windows: Install Rtools from https://cran.r-project.org/bin/windows/Rtools/

5. **Data access issues (macOS)**
   - Ensure Google Drive for Desktop is installed and signed in
   - Check that you have access to the shared drive
   - Run `scripts/setup_mac.command` manually if needed

6. **Environment not activating**
   - Restart your shell after adding direnv hook
   - Run `direnv allow .` in the repository directory

### Getting Help

- Check the `scripts/production/README.md` for detailed analysis workflow documentation
- Review the `notebooks/` directory for example analyses
- See individual script documentation in the `scripts/` directory

## 🔒 Security Notes

- The repository uses pre-commit hooks to prevent accidental commits of large data files
- Sensitive data columns (DOB, etc.) are automatically excluded from processing
- Google Drive access is required only for macOS users with shared drive access
