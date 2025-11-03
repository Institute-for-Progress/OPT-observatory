#!/bin/bash
# ==============================================================================
# OPT Observatory - Setup Script
# ==============================================================================
# Installs R dependencies using renv (standard for reproducible R projects).
#
# Usage: ./setup.sh
# ==============================================================================

echo "=== OPT Observatory Setup ==="
echo ""

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

echo "✓ R is installed"
echo ""

# Install renv if needed
echo "Checking for renv..."
Rscript -e "if (!requireNamespace('renv', quietly=TRUE)) install.packages('renv', repos='https://cloud.r-project.org')"

echo ""
echo "Installing R dependencies (this may take several minutes)..."
echo ""

# Restore packages from renv.lock
Rscript -e "renv::restore()"

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Download data from Zenodo: [DOI will be added]"
echo "  2. Extract to: data/"
echo "  3. Run: jupyter notebook notebooks/create_enriched_master.ipynb"
