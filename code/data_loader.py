"""
Modular data loader for OPT Observatory cleaned CSV data using pandas.

This module provides efficient access to large CSV files with options for
chunked reading, parallel loading, and filtering to manage memory usage.

Example usage:
    from data_loader import OPTDataLoader

    # Initialize
    loader = OPTDataLoader()

    # Load a single year (full dataframe)
    df_2020 = loader.load_year(2020)

    # Load specific columns only (faster, less memory)
    df_2020_subset = loader.load_year(2020,
                                      columns=['COUNTRY_OF_CITIZENSHIP',
                                              'STUDENT_EDU_LEVEL_DESC', 'YEAR'])

    # Load multiple years in parallel
    df_recent = loader.load_years([2020, 2021, 2022])

    # Load with row filtering (applied during read for efficiency)
    df_bachelors = loader.load_year(2020,
                                     filter_func=lambda df: df[df['STUDENT_EDU_LEVEL_DESC'] == 'Bachelor'])

    # Process year in chunks (for huge aggregations without loading all into memory)
    for chunk in loader.iter_year_chunks(2020, chunksize=100000):
        # Process each chunk
        result = chunk.groupby('COUNTRY_OF_CITIZENSHIP').size()
"""

import pandas as pd
from pathlib import Path
from typing import Union, List, Optional, Callable
from concurrent.futures import ProcessPoolExecutor, as_completed
import multiprocessing as mp


class OPTDataLoader:
    """
    Efficient loader for OPT Observatory cleaned CSV data using pandas.

    Provides methods for loading single/multiple years with optional
    filtering and parallel processing.
    """

    def __init__(self, data_dir: str = None):
        """
        Initialize the data loader.

        Args:
            data_dir: Path to directory containing cleaned CSV files.
                     Defaults to '../data/cleaned' relative to this script.
        """
        if data_dir is None:
            # Default to data/cleaned directory
            script_dir = Path(__file__).parent
            self.data_dir = script_dir.parent / "data" / "cleaned"
        else:
            self.data_dir = Path(data_dir)

        if not self.data_dir.exists():
            raise FileNotFoundError(f"Data directory not found: {self.data_dir}")

        # Available years
        self.available_years = self._get_available_years()

    def _get_available_years(self) -> List[int]:
        """Get list of available years from CSV files."""
        csv_files = sorted(self.data_dir.glob("cleaned_*_all.csv"))
        years = []
        for f in csv_files:
            try:
                # Extract year from filename like "cleaned_2020_all.csv"
                year = int(f.stem.split('_')[1])
                years.append(year)
            except (IndexError, ValueError):
                continue
        return sorted(years)

    def _get_file_path(self, year: int) -> Path:
        """Get file path for a specific year."""
        file_path = self.data_dir / f"cleaned_{year}_all.csv"
        if not file_path.exists():
            raise FileNotFoundError(
                f"No data file found for year {year}. "
                f"Available years: {self.available_years}"
            )
        return file_path

    def load_year(self,
                  year: int,
                  columns: Optional[List[str]] = None,
                  filter_func: Optional[Callable[[pd.DataFrame], pd.DataFrame]] = None,
                  nrows: Optional[int] = None,
                  dtype: Optional[dict] = None) -> pd.DataFrame:
        """
        Load data for a single year into a pandas DataFrame.

        Args:
            year: Year to load (e.g., 2020)
            columns: List of columns to load (loads all if None)
            filter_func: Function to filter rows. Applied after reading.
                        Example: lambda df: df[df['YEAR'] >= 2020]
            nrows: Number of rows to read (useful for testing)
            dtype: Dictionary of column dtypes to enforce
                   Example: {'CAMPUS_ZIP_CODE': str} to preserve leading zeros

        Returns:
            pandas DataFrame

        Example:
            # Load specific columns
            df = loader.load_year(2020, columns=['COUNTRY_OF_CITIZENSHIP', 'YEAR'])

            # Load with filtering
            df = loader.load_year(2020,
                                 filter_func=lambda df: df[df['CAMPUS_STATE'] == 'CA'])

            # Preserve ZIP codes as strings
            df = loader.load_year(2020, dtype={'CAMPUS_ZIP_CODE': str})
        """
        file_path = self._get_file_path(year)

        print(f"Loading {year} from {file_path.name}...")

        # Read CSV with specified options
        df = pd.read_csv(
            file_path,
            usecols=columns,
            nrows=nrows,
            dtype=dtype,
            low_memory=False  # Avoid dtype warnings for large files
        )

        # Apply filter if provided
        if filter_func is not None:
            df = filter_func(df)

        print(f"  Loaded {len(df):,} rows, {len(df.columns)} columns")

        return df

    def load_years(self,
                   years: List[int],
                   columns: Optional[List[str]] = None,
                   filter_func: Optional[Callable[[pd.DataFrame], pd.DataFrame]] = None,
                   parallel: bool = True,
                   dtype: Optional[dict] = None) -> pd.DataFrame:
        """
        Load data for multiple years and concatenate into a single DataFrame.

        Args:
            years: List of years to load (e.g., [2020, 2021, 2022])
            columns: List of columns to load (loads all if None)
            filter_func: Function to filter rows in each dataframe
            parallel: Whether to load years in parallel (faster for multiple years)
            dtype: Dictionary of column dtypes to enforce

        Returns:
            pandas DataFrame with all years concatenated

        Example:
            # Load multiple years
            df = loader.load_years([2020, 2021, 2022])

            # Load in parallel with filtering
            df = loader.load_years([2018, 2019, 2020],
                                  columns=['COUNTRY_OF_CITIZENSHIP', 'YEAR'],
                                  parallel=True)
        """
        if parallel and len(years) > 1:
            print(f"Loading {len(years)} years in parallel...")
            return self._load_years_parallel(years, columns, filter_func, dtype)
        else:
            print(f"Loading {len(years)} years sequentially...")
            dfs = []
            for year in years:
                df = self.load_year(year, columns=columns, filter_func=filter_func, dtype=dtype)
                dfs.append(df)

            result = pd.concat(dfs, ignore_index=True)
            print(f"Combined total: {len(result):,} rows")
            return result

    def _load_years_parallel(self,
                            years: List[int],
                            columns: Optional[List[str]],
                            filter_func: Optional[Callable],
                            dtype: Optional[dict]) -> pd.DataFrame:
        """Load multiple years in parallel using multiprocessing."""
        # Use a process pool to load years in parallel
        max_workers = min(len(years), mp.cpu_count())

        with ProcessPoolExecutor(max_workers=max_workers) as executor:
            # Submit all load jobs
            future_to_year = {
                executor.submit(_load_year_worker,
                              str(self._get_file_path(year)),
                              year,
                              columns,
                              filter_func,
                              dtype): year
                for year in years
            }

            # Collect results as they complete
            dfs = []
            for future in as_completed(future_to_year):
                year = future_to_year[future]
                try:
                    df = future.result()
                    dfs.append(df)
                except Exception as e:
                    print(f"Error loading year {year}: {e}")
                    raise

        # Concatenate all dataframes
        result = pd.concat(dfs, ignore_index=True)
        print(f"Combined total: {len(result):,} rows")
        return result

    def load_all(self,
                 columns: Optional[List[str]] = None,
                 filter_func: Optional[Callable[[pd.DataFrame], pd.DataFrame]] = None,
                 parallel: bool = True,
                 dtype: Optional[dict] = None) -> pd.DataFrame:
        """
        Load all available years.

        Args:
            columns: List of columns to load
            filter_func: Function to filter rows
            parallel: Whether to load in parallel
            dtype: Dictionary of column dtypes

        Returns:
            pandas DataFrame with all years

        Example:
            df = loader.load_all(columns=['COUNTRY_OF_CITIZENSHIP', 'YEAR'])
        """
        return self.load_years(self.available_years, columns, filter_func, parallel, dtype)

    def iter_year_chunks(self,
                        year: int,
                        chunksize: int = 100000,
                        columns: Optional[List[str]] = None,
                        dtype: Optional[dict] = None):
        """
        Iterate through a year's data in chunks (memory efficient).

        Useful for computing aggregations on large files without loading
        everything into memory at once.

        Args:
            year: Year to iterate through
            chunksize: Number of rows per chunk
            columns: List of columns to load
            dtype: Dictionary of column dtypes

        Yields:
            pandas DataFrame chunks

        Example:
            # Compute aggregation without loading full year
            totals = {}
            for chunk in loader.iter_year_chunks(2020, chunksize=100000):
                counts = chunk['COUNTRY_OF_CITIZENSHIP'].value_counts()
                for country, count in counts.items():
                    totals[country] = totals.get(country, 0) + count
        """
        file_path = self._get_file_path(year)

        print(f"Iterating through {year} in chunks of {chunksize:,} rows...")

        for chunk in pd.read_csv(
            file_path,
            usecols=columns,
            chunksize=chunksize,
            dtype=dtype,
            low_memory=False
        ):
            yield chunk

    def get_column_names(self, year: Optional[int] = None) -> List[str]:
        """
        Get column names from the dataset.

        Args:
            year: Optional year to check. Uses most recent year if None.

        Returns:
            List of column names
        """
        if year is None:
            year = self.available_years[-1]

        file_path = self._get_file_path(year)

        # Read just the header
        df = pd.read_csv(file_path, nrows=0)
        return df.columns.tolist()

    def sample_year(self, year: int, n: int = 1000, columns: Optional[List[str]] = None) -> pd.DataFrame:
        """
        Get a random sample from a year (useful for exploration).

        Args:
            year: Year to sample from
            n: Number of rows to sample
            columns: Optional list of columns to include

        Returns:
            pandas DataFrame with sampled rows

        Example:
            # Get 1000 random rows from 2020
            sample = loader.sample_year(2020, n=1000)
        """
        # For large files, we'll read in chunks and sample
        file_path = self._get_file_path(year)

        # Get total rows (by reading file)
        print(f"Sampling {n} rows from {year}...")

        # Read with skiprows to get random sample
        # Simple approach: read the whole file and sample (not perfect but works)
        df = pd.read_csv(file_path, usecols=columns, low_memory=False)

        if len(df) > n:
            sample = df.sample(n=n, random_state=42)
        else:
            sample = df

        print(f"  Sampled {len(sample):,} rows")
        return sample

    def get_year_info(self, year: int) -> dict:
        """
        Get information about a specific year's file.

        Args:
            year: Year to get info for

        Returns:
            Dictionary with file info
        """
        file_path = self._get_file_path(year)

        # Get file size
        file_size_mb = file_path.stat().st_size / (1024 * 1024)

        # Count rows (read with no data to get length quickly)
        nrows = sum(1 for _ in open(file_path)) - 1  # -1 for header

        return {
            'year': year,
            'file_path': str(file_path),
            'file_size_mb': round(file_size_mb, 2),
            'estimated_rows': nrows,
            'columns': len(self.get_column_names(year))
        }

    def __repr__(self):
        return f"OPTDataLoader(data_dir='{self.data_dir}', available_years={self.available_years})"


# Helper function for parallel loading (must be top-level for pickling)
def _load_year_worker(file_path: str,
                     year: int,
                     columns: Optional[List[str]],
                     filter_func: Optional[Callable],
                     dtype: Optional[dict]) -> pd.DataFrame:
    """Worker function for parallel year loading."""
    print(f"Loading {year}...")

    df = pd.read_csv(
        file_path,
        usecols=columns,
        dtype=dtype,
        low_memory=False
    )

    if filter_func is not None:
        df = filter_func(df)

    print(f"  Loaded {year}: {len(df):,} rows")
    return df


# Convenience functions
def quick_load(years: Union[int, List[int], str] = 'all',
               columns: Optional[List[str]] = None,
               filter_func: Optional[Callable] = None,
               data_dir: str = None) -> pd.DataFrame:
    """
    Quick load function for one-off analyses.

    Args:
        years: Year(s) to load. Can be:
               - Single int (e.g., 2020)
               - List of ints (e.g., [2020, 2021])
               - 'all' for all available years
        columns: Optional list of columns to load
        filter_func: Optional filter function
        data_dir: Optional path to data directory

    Returns:
        pandas DataFrame

    Example:
        from data_loader import quick_load

        # Load single year
        df = quick_load(2020)

        # Load multiple years with specific columns
        df = quick_load([2020, 2021], columns=['COUNTRY_OF_CITIZENSHIP', 'YEAR'])
    """
    loader = OPTDataLoader(data_dir)

    if years == 'all':
        return loader.load_all(columns=columns, filter_func=filter_func)
    elif isinstance(years, int):
        return loader.load_year(years, columns=columns, filter_func=filter_func)
    elif isinstance(years, list):
        return loader.load_years(years, columns=columns, filter_func=filter_func)
    else:
        raise ValueError("years must be an int, list of ints, or 'all'")


if __name__ == "__main__":
    # Example usage / testing
    print("OPT Observatory Data Loader")
    print("=" * 60)

    loader = OPTDataLoader()
    print(f"\nAvailable years: {loader.available_years}")
    print(f"Data directory: {loader.data_dir}")

    # Show column names
    print(f"\nColumns ({len(loader.get_column_names())} total):")
    for i, col in enumerate(loader.get_column_names()[:10], 1):
        print(f"  {i}. {col}")
    print("  ...")

    # Example: Load a single year with specific columns
    print("\n" + "=" * 60)
    print("Example 1: Load single year with specific columns")
    print("=" * 60)
    df_2021 = loader.load_year(
        2021,
        columns=['COUNTRY_OF_CITIZENSHIP', 'STUDENT_EDU_LEVEL_DESC', 'YEAR'],
        nrows=5  # Just load 5 rows for demo
    )
    print(df_2021.head())

    print("\n" + "=" * 60)
    print("Example 2: Get sample from a year")
    print("=" * 60)
    sample = loader.sample_year(2021, n=100)
    print(f"Sample shape: {sample.shape}")
    print(f"Countries in sample: {sample['COUNTRY_OF_CITIZENSHIP'].nunique()}")
