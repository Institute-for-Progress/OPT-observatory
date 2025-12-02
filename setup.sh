#!/bin/bash
# ==============================================================================
# OPT Observatory - Setup Script
# ==============================================================================
# Installs both R and Python dependencies for the analysis pipeline.
#
# Usage: ./setup.sh
# ==============================================================================

echo "=== OPT Observatory Setup ==="
echo ""

# ==============================================================================
# 1. Check Prerequisites
# ==============================================================================

echo "Checking prerequisites..."
echo ""

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed."
    echo ""
    echo "Please install Python 3 first:"
    echo "  macOS:   brew install python3"
    echo "  Linux:   sudo apt-get install python3 python3-venv python3-pip"
    echo "  Windows: Download from https://www.python.org/downloads/"
    exit 1
fi

echo "✓ Python 3 is installed ($(python3 --version))"

# Check if R is installed
if ! command -v Rscript &> /dev/null; then
    echo "❌ R is not installed."
    echo ""
    echo "Please install R first:"
    echo "  macOS:   brew install r"
    echo "  Linux:   sudo apt-get install r-base"
    echo "  Windows: Download from https://cran.r-project.org/"
    exit 1
fi

echo "✓ R is installed ($(Rscript --version 2>&1 | head -n1))"
echo ""

# ==============================================================================
# 2. Set up Python Virtual Environment
# ==============================================================================

echo "Setting up Python virtual environment..."
echo ""

# Create venv if it doesn't exist
if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
    echo "✓ Virtual environment created"
else
    echo "✓ Virtual environment already exists"
fi

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
echo "Upgrading pip..."
pip install --upgrade pip --quiet

# Install Python dependencies
echo "Installing Python dependencies from requirements.txt..."
pip install -r requirements.txt

echo "✓ Python dependencies installed"
echo ""

# ==============================================================================
# 3. Set up R Environment
# ==============================================================================

echo "Setting up R environment..."
echo ""

# Install renv if needed
echo "Checking for renv..."
Rscript -e "if (!requireNamespace('renv', quietly=TRUE)) install.packages('renv', repos='https://cloud.r-project.org')"

echo "Installing R dependencies (this may take several minutes)..."
echo ""

# Restore packages from renv.lock
Rscript -e "renv::restore()"

echo "✓ R dependencies installed"
echo ""

# ==============================================================================
# 4. Summary
# ==============================================================================

echo "✅ Setup complete!"
echo ""
echo "Your environment is ready. To use it activate the Python environment:"
echo ""
echo "     source venv/bin/activate"
echo ""
echo "Download data from Google Drive and extract to data/ before trying to execute the data cleaning or loading functions."
echo ""
