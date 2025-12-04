# ------------------------------------------------------------------------------
#  SEVIS F-1 Annual Cleaner - OPTIMIZED VERSION (FULL FUNCTIONALITY)
#  Purpose  : Transform raw CSV dumps (≈25 GB) into cleaned yearly CSV files
#  Inputs   : Raw SEVIS FOIA files (organized by year in subdirectories)
#  Outputs  :
#    - ../data/raw/*.csv (combined raw yearly files)
#    - ../data/cleaned/*.csv (cleaned yearly files, ready for analysis)
#  Author   : Violet Buxton-Walsh | IFP
#  Updated  : 2025-10-31
#
#  Performance optimizations:
#  - Parallel processing of years (preserving all original functionality)
#  - Chunked file reading for large files
#  - Optimized memory management
#  - Reduced redundant operations
# ------------------------------------------------------------------------------

# ---- load-packages -----------------------------------------------------------
library(tidyverse)
library(lubridate)
library(fs)
library(readr)
library(dplyr)
library(data.table)
library(parallel)
library(future)
library(future.apply)
library(jsonlite)

# ---- logging setup -----------------------------------------------------------
cat("=== SEVIS F-1 Annual Cleaner (OPTIMIZED) Starting ===\n")
cat("Time:", as.character(Sys.time()), "\n")
cat("Working directory:", getwd(), "\n")
cat("Available cores:", parallel::detectCores(), "\n")

# Set up parallel processing
plan(multisession, workers = min(4, parallel::detectCores() - 1))
cat("Using", nbrOfWorkers(), "workers for parallel processing\n")

# ---- load-configuration ------------------------------------------------------
# Load configuration from external JSON file for consistency across projects
CONFIG_PATH <- "misc/sevis_data_processing_config.json"

if (!file.exists(CONFIG_PATH)) {
  stop("Configuration file not found: ", CONFIG_PATH)
}

cat("Loading configuration from:", CONFIG_PATH, "\n")
CONFIG <- jsonlite::fromJSON(CONFIG_PATH)

# Extract configuration values
DEFAULT_EXCLUDE_COLS <- CONFIG$exclude_columns
STATE_ABBREVIATIONS <- unlist(CONFIG$state_abbreviations)
ZIP_FIX_STATES <- CONFIG$zip_fix_states
DATE_COLUMNS <- CONFIG$date_columns
TEXT_CLEANING_COLUMNS <- CONFIG$text_cleaning_columns
ZIP_COLUMNS <- CONFIG$zip_columns
STATE_COLUMNS <- CONFIG$state_columns
FUTURE_CUTOFF <- CONFIG$date_cutoffs$future_cutoff
HISTORIC_CUTOFF <- CONFIG$date_cutoffs$historic_cutoff

cat("Configuration loaded successfully\n")

# Function to check if a column should be excluded
should_exclude_column <- function(col_name, exclude_cols) {
  if (is.null(exclude_cols) || length(exclude_cols) == 0) {
    return(FALSE)
  }

  base_name <- gsub("\\.{3}\\d+$", "", col_name)
  
  clean_col <- trimws(col_name) |>
    gsub("&", "", x = _) |>
    gsub("'", "", x = _) |>
    gsub("\\.", "_", x = _)
  
  clean_base <- trimws(base_name) |>
    gsub("&", "", x = _) |>
    gsub("'", "", x = _) |>
    gsub("\\.", "_", x = _)
  
  clean_excludes <- trimws(exclude_cols) |>
    gsub("&", "", x = _) |>
    gsub("'", "", x = _) |>
    gsub("\\.", "_", x = _)
  
  return(col_name %in% exclude_cols ||
         base_name %in% exclude_cols ||
         clean_col %in% clean_excludes ||
         clean_base %in% clean_excludes)
}

# Optimized text cleaning function (FIXED regex)
clean_text_data <- function(text_vector) {
  if (is.null(text_vector) || length(text_vector) == 0) {
    return(text_vector)
  }
  
  # Convert to character if not already
  text_vector <- as.character(text_vector)
  
  # Clean the text with optimized operations
  cleaned_text <- text_vector |>
    tolower() |>
    trimws() |>
    gsub("\\s+", " ", x = _) |>
    gsub("[[:punct:]]", "", x = _) |>
    gsub("\\s+", " ", x = _) |>
    trimws()
  
  return(cleaned_text)
}

# Optimized state abbreviation conversion
convert_state_abbreviations <- function(state_vector) {
  if (is.null(state_vector) || length(state_vector) == 0) {
    return(state_vector)
  }
  
  state_vector <- as.character(state_vector)
  state_lower <- tolower(state_vector)
  
  # Create a mapping for lowercase state names
  state_mapping <- tolower(STATE_ABBREVIATIONS)
  names(state_mapping) <- tolower(names(STATE_ABBREVIATIONS))
  
  # Use vectorized replacement for better performance
  for (abbr in names(state_mapping)) {
    state_lower[state_lower == abbr] <- state_mapping[abbr]
  }
  
  return(state_lower)
}

# Optimized SEVIS column cleaning
clean_sevis_columns <- function(df, verbose = FALSE) {
  # Use columns from configuration
  columns_to_clean <- TEXT_CLEANING_COLUMNS
  
  existing_columns <- intersect(columns_to_clean, colnames(df))
  
  if (verbose) {
    cat(sprintf("Cleaning %d columns: %s\n", length(existing_columns), 
                paste(existing_columns, collapse = ", ")))
  }
  
  # Clean each existing column
  for (col in existing_columns) {
    if (verbose) {
      cat(sprintf("  Cleaning column: %s\n", col))
    }
    
    original_values <- df[[col]]
    non_na_count <- sum(!is.na(original_values))
    
    if (non_na_count == 0) {
      if (verbose) {
        cat(sprintf("    Column %s has no non-NA values, skipping\n", col))
      }
      next
    }
    
    # Clean the text
    cleaned_values <- clean_text_data(original_values)
    
    # For state columns, convert abbreviations to full names
    if (grepl("_STATE$", col)) {
      cleaned_values <- convert_state_abbreviations(cleaned_values)
      if (verbose) {
        cat(sprintf("    Converted state abbreviations in %s\n", col))
      }
    }
    
    # Update the dataframe
    df[[col]] <- cleaned_values
    
    # Report changes
    if (verbose) {
      changed_count <- sum(original_values != cleaned_values, na.rm = TRUE)
      cat(sprintf("    Modified %d of %d non-NA values in %s\n", changed_count, non_na_count, col))
    }
  }
  
  return(df)
}

# Function to restore leading zeros to ZIP codes (fix DHS/ICE source data issue)
# Optimized for large datasets using vectorized operations
fix_zip_leading_zeros <- function(df, verbose = FALSE) {
  # Use configuration values
  zero_states <- ZIP_FIX_STATES
  zip_columns <- ZIP_COLUMNS
  state_columns <- STATE_COLUMNS

  if (verbose) {
    cat("Restoring leading zeros to ZIP codes for Northeast states...\n")
  }

  # Convert to data.table if not already (for efficient in-place modification)
  is_dt <- data.table::is.data.table(df)
  if (!is_dt) {
    df <- data.table::as.data.table(df)
  }

  # Process each ZIP/State pair
  for (i in seq_along(zip_columns)) {
    zip_col <- zip_columns[i]
    state_col <- state_columns[i]

    # Check if both columns exist
    if (zip_col %in% colnames(df) && state_col %in% colnames(df)) {

      # Convert ZIP to character if not already (in-place for data.table)
      if (!is.character(df[[zip_col]])) {
        df[, (zip_col) := as.character(get(zip_col))]
      }

      # Pre-compute lowercase state for efficiency (avoids repeated tolower calls)
      # Only for rows where state is not NA
      state_lower <- rep(NA_character_, nrow(df))
      state_not_na <- !is.na(df[[state_col]])
      state_lower[state_not_na] <- tolower(trimws(df[[state_col]][state_not_na]))

      # Create vectorized mask for records that need padding
      # Conditions: ZIP exists, is less than 5 digits, and is in an affected state
      needs_padding <- !is.na(df[[zip_col]]) &
                       nchar(df[[zip_col]]) < 5 &
                       !is.na(state_lower) &
                       state_lower %in% zero_states

      n_affected <- sum(needs_padding, na.rm = TRUE)

      if (verbose && n_affected > 0) {
        cat(sprintf("  %s: Found %d truncated ZIPs in affected states\n",
                    zip_col, n_affected))
      }

      # Pad with leading zeros using sprintf (faster than str_pad for this use case)
      if (n_affected > 0) {
        # Use sprintf with %05s to pad strings with leading zeros
        df[needs_padding, (zip_col) := sprintf("%05s", get(zip_col))]

        if (verbose) {
          cat(sprintf("  %s: Restored leading zeros for %d ZIPs\n",
                      zip_col, n_affected))
        }
      }
    } else {
      if (verbose) {
        if (!(zip_col %in% colnames(df))) {
          cat(sprintf("  Column %s not found, skipping\n", zip_col))
        }
        if (!(state_col %in% colnames(df))) {
          cat(sprintf("  Column %s not found, skipping\n", state_col))
        }
      }
    }
  }

  if (verbose) {
    cat("ZIP code leading zero restoration complete\n")
  }

  # Convert back to data.frame if input was data.frame
  if (!is_dt) {
    df <- as.data.frame(df)
  }

  return(df)
}

# Enhanced error handling wrapper for file operations (PRESERVED)
safe_file_operation <- function(operation, file_path, operation_name = "file operation") {
  tryCatch({
    result <- operation()
    return(result)
  }, error = function(e) {
    error_msg <- sprintf("Error in %s for file '%s': %s", operation_name, basename(file_path), e$message)
    cat(error_msg, "\n")
    stop(error_msg)
  }, warning = function(w) {
    warning_msg <- sprintf("Warning in %s for file '%s': %s", operation_name, basename(file_path), w$message)
    cat(warning_msg, "\n")
    warning(warning_msg)
  })
}

# Function to validate that a file is a readable CSV file
validate_csv_file <- function(file_path) {
  tryCatch({
    # Try to read just the first few lines to validate it's a CSV
    test_read <- fread(file_path, nrows = 5, showProgress = FALSE, encoding = "UTF-8")
    if (ncol(test_read) < 2) {
      return(FALSE)  # Not enough columns to be a valid CSV
    }
    return(TRUE)
  }, error = function(e) {
    cat(sprintf("Warning: File '%s' appears to be a CSV but is not readable: %s\n", 
                basename(file_path), e$message))
    return(FALSE)
  })
}

# Fast column name reading using data.table with enhanced error handling (PRESERVED)
read_column_names <- function(file) {
  safe_file_operation(
    operation = function() {
      names(fread(file, nrows = 0, showProgress = FALSE, encoding = "UTF-8"))
    },
    file_path = file,
    operation_name = "reading column names"
  )
}

# Optimized file structure function (PRESERVED)
get_file_structure <- function(file, exclude_cols = DEFAULT_EXCLUDE_COLS) {
  all_cols <- read_column_names(file)
  
  kept_cols <- all_cols[!vapply(all_cols, should_exclude_column, logical(1), exclude_cols)]
  
  base_names <- gsub("\\.{3}\\d+$", "", kept_cols)
  unique_positions <- !duplicated(base_names)
  final_cols <- kept_cols[unique_positions]
  
  clean_names <- trimws(final_cols) |>
    gsub("&", "", x = _) |>
    gsub("'", "", x = _) |>
    gsub("\\.", "_", x = _) |>
    gsub("-", "_", x = _) |>
    gsub("\\s+", " ", x = _) |>
    gsub(" ", "_", x = _) |>
    toupper()
  
  return(clean_names)
}

# Enhanced date parsing with validation (PRESERVED)
parse_dates_safely <- function(date_vector, column_name, verbose = FALSE) {
  if (all(is.na(date_vector))) {
    if (verbose) {
      message(sprintf("  Warning: All values in column '%s' are NA", column_name))
    }
    return(as.Date(rep(NA, length(date_vector))))
  }
  
  # Pre-process dates to remove timezone information and standardize format
  cleaned_dates <- date_vector
  
  # Remove timezone information (e.g., "2014-06-02 00:00:00" -> "2014-06-02")
  cleaned_dates <- gsub("\\s+\\d{2}:\\d{2}:\\d{2}(\\s+\\d{2}:\\d{2})?$", "", cleaned_dates)
  
  # Remove any remaining time components
  cleaned_dates <- gsub("\\s+\\d{2}:\\d{2}(:\\d{2})?$", "", cleaned_dates)
  
  # Try multiple date formats
  parsed_dates <- parse_date_time(cleaned_dates, 
                                orders = c("ymd", "mdy", "dmy", "y-m-d", "m/d/y"),
                                quiet = TRUE)
  
  # Check parsing success rate
  success_rate <- sum(!is.na(parsed_dates)) / length(cleaned_dates[!is.na(cleaned_dates)])
  
  if (success_rate < 0.99 && verbose) {
    message(sprintf("  Warning: Only %.1f%% of dates in column '%s' parsed successfully", 
                   success_rate * 100, column_name))
    
    # Show some examples of unparseable dates
    unparseable <- cleaned_dates[is.na(parsed_dates) & !is.na(cleaned_dates)]
    if (length(unparseable) > 0) {
      examples <- head(unique(unparseable), 5)
      message(sprintf("  Examples of unparseable dates: %s", paste(examples, collapse = ", ")))
    }
  }
  
  return(as.Date(parsed_dates))
}

# FULL FUNCTIONALITY CSV reading with sophisticated duplicate handling (PRESERVED)
read_csv_exclude <- function(file, exclude_cols = DEFAULT_EXCLUDE_COLS, n_max = Inf, 
                            verbose = FALSE, ...) {
  if (is.null(exclude_cols)) {
    exclude_cols <- DEFAULT_EXCLUDE_COLS
  }
  
  # Read all columns with data.table and enhanced error handling
  df_all <- safe_file_operation(
    operation = function() {
      fread(file, 
           na.strings = c("", "NA", "N/A", "NULL", "null"),
           showProgress = FALSE,
           nrows = n_max,
           colClasses = "character",
           encoding = "UTF-8",
           ...)
    },
    file_path = file,
    operation_name = "reading CSV file"
  )
  
  all_cols <- names(df_all)
  
  # Print detailed column information for debugging
  if (verbose) {
    message(sprintf("\nFile: %s", basename(file)))
    message(sprintf("Total columns before exclusions: %d", length(all_cols)))
    message("All columns:")
    message(paste(all_cols, collapse = ", "))
    
    mem_usage <- object.size(df_all) / 1024^2
    message(sprintf("Memory usage: %.1f MB", mem_usage))
  }
  
  # Remove excluded columns using vectorized operations
  kept_cols <- all_cols[!vapply(all_cols, should_exclude_column, logical(1), exclude_cols)]
  base_names_full <- gsub("\\.{3}\\d+$", "", kept_cols)
  kept_cols_dedup <- kept_cols[!duplicated(base_names_full)]
  
  if (verbose) {
    message(sprintf("\nColumns after exclusions: %d", length(kept_cols)))
    message("Kept columns:")
    message(paste(kept_cols, collapse = ", "))
  }

  col_mapping <- setNames(
    get_file_structure(file, exclude_cols),
    kept_cols_dedup
  )
  
  if (length(col_mapping) != length(kept_cols_dedup))
      stop("Column-mapping length mismatch – investigate duplicates.")
  
  df_filtered <- df_all[, kept_cols, with = FALSE]
  
  # Handle duplicates with FULL SOPHISTICATED LOGIC (PRESERVED)
  cols_to_keep_indices <- rep(TRUE, length(kept_cols))
  duplicate_base_names <- unique(base_names_full[duplicated(base_names_full)])

  if (length(duplicate_base_names) > 0 && nrow(df_filtered) > 0) {
    for (base_name in duplicate_base_names) {
      matching_indices <- which(base_names_full == base_name)
      matching_cols <- kept_cols[matching_indices]
      
      if (length(matching_cols) > 1) {
        # Check if columns are identical
        first_col_data <- df_filtered[[matching_cols[1]]]
        
        identical_to_first <- sapply(matching_cols[-1], function(col) {
          col_data <- df_filtered[[col]]
          all(is.na(first_col_data) == is.na(col_data)) && 
          all(first_col_data[!is.na(first_col_data)] == col_data[!is.na(col_data)])
        })
        
        if (all(identical_to_first)) {
          cols_to_keep_indices[matching_indices[-1]] <- FALSE
          if (verbose) {
            message(sprintf("  Note: Keeping first occurrence of identical columns for %s", base_name))
          }
        } else {
          # Check each duplicate column individually for 95% similarity
          first_col_data <- df_filtered[[matching_cols[1]]]
          columns_to_remove <- c()
          
          for (i in 2:length(matching_cols)) {
            col <- matching_cols[i]
            col_data <- df_filtered[[col]]
            
            # Calculate similarity (ignoring NA positions)
            valid_positions <- !is.na(first_col_data) | !is.na(col_data)
            if (sum(valid_positions) == 0) {
              similarity <- 1
            } else {
              matching_positions <- first_col_data[valid_positions] == col_data[valid_positions]
              matching_positions[is.na(matching_positions)] <- FALSE
              similarity <- sum(matching_positions) / sum(valid_positions)
            }
            
            if (similarity > 0.95) {
              first_na_count <- sum(is.na(first_col_data))
              col_na_count <- sum(is.na(col_data))
              
              if (col_na_count < first_na_count) {
                cols_to_keep_indices[matching_indices[1]] <- FALSE
                first_col_data <- col_data
                matching_indices[1] <- matching_indices[i]
                if (verbose) {
                  message(sprintf("  Note: %s columns are %.1f%% similar. Replacing first with '%s' (fewer NAs: %d vs %d)", 
                                base_name, similarity * 100, col, col_na_count, first_na_count))
                }
              } else {
                columns_to_remove <- c(columns_to_remove, i)
                if (verbose) {
                  message(sprintf("  Note: %s columns are %.1f%% similar. Removing '%s' (more NAs: %d vs %d)", 
                                base_name, similarity * 100, col, col_na_count, first_na_count))
                }
              }
            } else {
              if (verbose) {
                message(sprintf("  Warning: %s columns are only %.1f%% similar - keeping both for manual review", 
                              base_name, similarity * 100))
              }
            }
          }
          
          if (length(columns_to_remove) > 0) {
            cols_to_keep_indices[matching_indices[columns_to_remove]] <- FALSE
          }
        }
      }
    }
  }
  
  # Apply the filtering
  final_cols <- kept_cols[cols_to_keep_indices]
  df_final <- df_filtered[, final_cols, with = FALSE]
  
  # Apply clean names
  setnames(df_final, final_cols, col_mapping[final_cols])
  
  return(df_final)
}

# Helper function to check if headers are consistent across files (PRESERVED)
check_headers_consistent <- function(files, exclude_cols = DEFAULT_EXCLUDE_COLS, 
                                   verbose = TRUE, context = "files") {
  file_structures <- lapply(files, function(file) {
    get_file_structure(file, exclude_cols)
  })
  names(file_structures) <- basename(files)
  
  reference_structure <- file_structures[[1]]
  reference_file <- names(file_structures)[1]
  
  if (verbose) {
    message(sprintf("\nHeader information for %s:", context))
    message(sprintf("Reference file (%s) has %d columns after exclusions:", 
                   reference_file, length(reference_structure)))
    message(paste(reference_structure, collapse = ", "))
  }
  
  mismatched_files <- list()
  for (file_name in names(file_structures)) {
    current_structure <- file_structures[[file_name]]
    
    if (!identical(current_structure, reference_structure)) {
      missing_cols <- setdiff(reference_structure, current_structure)
      extra_cols <- setdiff(current_structure, reference_structure)
      
      mismatched_files[[file_name]] <- list(
        missing = missing_cols,
        extra = extra_cols,
        total_columns = length(current_structure)
      )
      
      if (verbose) {
        message(sprintf("\nFile %s has %d columns after exclusions:", 
                       file_name, length(current_structure)))
        message(paste(current_structure, collapse = ", "))
      }
    }
  }
  
  if (length(mismatched_files) > 0) {
    error_msg <- sprintf("\n*** FATAL ERROR: Column structure mismatch in %s ***\n", context)
    error_msg <- paste0(error_msg, 
                       sprintf("Reference file (%s) has %d columns:\n", 
                              reference_file, length(reference_structure)))
    error_msg <- paste0(error_msg, paste(reference_structure, collapse = ", "), "\n\n")
    
    for (file_name in names(mismatched_files)) {
      diffs <- mismatched_files[[file_name]]
      error_msg <- paste0(error_msg, 
                         sprintf("File: %s (has %d columns)\n", 
                                file_name, diffs$total_columns))
      
      if (length(diffs$missing) > 0) {
        error_msg <- paste0(error_msg, 
                           sprintf("  Missing columns: %s\n", 
                                 paste(diffs$missing, collapse = ", ")))
      }
      if (length(diffs$extra) > 0) {
        error_msg <- paste0(error_msg, 
                           sprintf("  Extra columns: %s\n", 
                                 paste(diffs$extra, collapse = ", ")))
      }
      error_msg <- paste0(error_msg, "\n")
    }
    
    error_msg <- paste0(error_msg, 
                       sprintf("All %s must have identical column structures after exclusions.\n",
                              context),
                       "Please investigate and fix the source data before proceeding.")
    
    stop(error_msg)
  }
  
  if (verbose) {
    message(sprintf("\n✓ All %s have identical structure (%d columns)", 
                   context, length(reference_structure)))
  }
  
  return(TRUE)
}

# Optimized yearly data processing with parallel execution (PRESERVING ALL FUNCTIONALITY)
process_yearly_data_parallel <- function(root_dir, pattern = ".csv", exclude_cols = DEFAULT_EXCLUDE_COLS, 
                                        verbose = TRUE, output_dir = NULL, year_range = NULL) {
  cat("=== Starting process_yearly_data_parallel ===\n")
  cat("root_dir:", root_dir, "\n")
  cat("pattern:", pattern, "\n")
  cat("year_range:", if(is.null(year_range)) "NULL" else paste(year_range, collapse=", "), "\n")
  
  if (!dir.exists(root_dir)) {
    stop(sprintf("Directory does not exist: %s", root_dir))
  }
  
  if (!file.access(root_dir, mode = 4) == 0) {
    stop(sprintf("Directory is not readable: %s", root_dir))
  }
  
  cat("Scanning for year directories...\n")
  year_dirs <- fs::dir_ls(root_dir, type = "directory") |> sort()
  cat("Found", length(year_dirs), "year directories\n")
  
  if (length(year_dirs) == 0) {
    stop(sprintf("No subdirectories found in: %s", root_dir))
  }
  
  if (!is.null(output_dir)) {
    tryCatch({
      fs::dir_create(output_dir, recurse = TRUE)
    }, error = function(e) {
      stop(sprintf("Failed to create output directory '%s': %s", output_dir, e$message))
    })
    
    if (!file.access(output_dir, mode = 2) == 0) {
      stop(sprintf("Output directory is not writable: %s", output_dir))
    }
  }
  
  # Filter years if specified
  if (!is.null(year_range)) {
    year_dirs <- year_dirs[sapply(year_dirs, function(dir) {
      year <- fs::path_file(dir)
      year %in% year_range
    })]
  }
  
  cat("Processing", length(year_dirs), "years in parallel\n")
  
  # Process years in parallel
  results <- future_lapply(year_dirs, function(year_dir) {
    year <- fs::path_file(year_dir)
    
    cat(sprintf("\n=== Processing year %s ===\n", year))
    
    # Get all files in the directory
    all_files <- fs::dir_ls(year_dir, type = "file")
    
    # Filter for CSV files more robustly
    potential_csv_files <- all_files[grepl("\\.csv$", all_files, ignore.case = TRUE)]
    
    # Also check for files matching the pattern if it's not just ".csv"
    if (pattern != ".csv") {
      pattern_files <- all_files[grepl(pattern, all_files, ignore.case = TRUE)]
      potential_csv_files <- unique(c(potential_csv_files, pattern_files))
    }
    
    # Validate that the files are actually readable CSV files
    cat("Validating CSV files...\n")
    valid_csv_files <- c()
    for (file in potential_csv_files) {
      if (validate_csv_file(file)) {
        valid_csv_files <- c(valid_csv_files, file)
      }
    }
    
    csv_files <- valid_csv_files
    
    cat("Found", length(csv_files), "valid CSV files out of", length(all_files), "total files\n")
    
    if (length(csv_files) == 0) {
      warning(sprintf("No valid CSV files found in %s (total files: %d)", year_dir, length(all_files)))
      return(NULL)
    }
    
    # Extract year from first file name and check if we should process this year
    first_file <- basename(csv_files[1])
    file_year <- sub(".*FY(\\d{4}).*", "\\1", first_file)
    
    if (!is.null(year_range) && !file_year %in% year_range) {
      message(sprintf("Skipping year %s (not in specified range)", file_year))
      return(NULL)
    }
    
    # Check headers are consistent across all files in this year (PRESERVED)
    cat("Checking header consistency across", length(csv_files), "files...\n")
    check_headers_consistent(csv_files, exclude_cols, verbose, 
                           context = sprintf("files in year %s", year))
    cat("Header consistency check completed\n")
    
    # Process files
    output_path <- fs::path(output_dir, sprintf("%s_all.csv", year))
    all_data <- list()
    cat("Starting file processing for", length(csv_files), "files...\n")
    
    for (i in seq_along(csv_files)) {
      file <- csv_files[i]
      is_first_file <- (i == 1)
      
      cat("Processing file", i, "of", length(csv_files), ":", basename(file), "\n")
      message(sprintf("  %s file: %s", 
                     if (is_first_file) "Reading first" else "Appending", 
                     basename(file)))
      
      # Read and process file with enhanced error handling (PRESERVED)
      cat("  Reading file...\n")
      df <- safe_file_operation(
        operation = function() {
          read_csv_exclude(file, exclude_cols, verbose = verbose && is_first_file)
        },
        file_path = file,
        operation_name = "processing CSV file"
      )
      
      cat("  File read complete, rows:", nrow(df), "columns:", ncol(df), "\n")
      
      df$Year <- year
      all_data[[i]] <- df
      
      rm(df)
      gc()
      cat("  Memory cleanup complete\n")
    }
    
    # Combine all data and write with enhanced error handling (PRESERVED)
    cat("Combining all data from", length(all_data), "files...\n")
    cat("Using data.table rbindlist...\n")
    
    combined_data <- safe_file_operation(
      operation = function() {
        rbindlist(all_data, ignore.attr = TRUE)
      },
      file_path = "combined data",
      operation_name = "combining data files"
    )
    
    cat("Writing combined data with data.table fwrite...\n")
    safe_file_operation(
      operation = function() {
        fwrite(combined_data, output_path)
      },
      file_path = output_path,
      operation_name = "writing combined file"
    )
    
    final_rows <- nrow(combined_data)
    cat("Data combination complete. Final rows:", final_rows, "\n")
    cat("Output written to:", output_path, "\n")
    
    if (verbose) {
      message(sprintf("✓ Combined %d files for year %s", length(csv_files), year))
    }
    
    cat("Cleaning up memory for year", year, "...\n")
    rm(all_data, combined_data)
    gc()
    
    return(list(year = year, rows = final_rows, output_path = output_path))
  }, future.seed = TRUE)
  
  return(results)
}

# Optimized cleaning function (PRESERVING ALL FUNCTIONALITY)
clean_yearly_data_optimized <- function(input_dir, output_dir, date_cols,
                                       exclude_cols = DEFAULT_EXCLUDE_COLS,
                                       future_cutoff = NULL,
                                       historic_cutoff = NULL,
                                       year_range = NULL,
                                       keep_cpt = FALSE) {
  cat("=== Starting clean_yearly_data_optimized ===\n")
  cat("input_dir:", input_dir, "\n")
  cat("output_dir:", output_dir, "\n")
  cat("keep_cpt:", keep_cpt, "\n")
  cat("year_range:", if(is.null(year_range)) "NULL" else paste(year_range, collapse=", "), "\n")

  if (is.null(future_cutoff)) {
    future_cutoff <- "2024-01-01"
  }

  if (is.null(historic_cutoff)) {
    historic_cutoff <- "1980-01-01"
  }
  
  if (is.null(output_dir)) {
    message("Skipping processing from raw combined files to cleaned combined files as output_dir is NULL")
    return(NULL)
  }
  
  tryCatch({
    fs::dir_create(output_dir, recurse = TRUE)
  }, error = function(e) {
    stop(sprintf("Failed to create output directory '%s': %s", output_dir, e$message))
  })
  
  cat("Looking for CSV files in input directory...\n")
  # Get all files and filter for CSV files more robustly
  all_files <- fs::dir_ls(input_dir, type = "file")
  potential_csv_files <- all_files[grepl("\\.csv$", all_files, ignore.case = TRUE)]
  
  # Validate that the files are actually readable CSV files
  cat("Validating CSV files...\n")
  valid_csv_files <- c()
  for (file in potential_csv_files) {
    if (validate_csv_file(file)) {
      valid_csv_files <- c(valid_csv_files, file)
    }
  }
  
  csv_files <- valid_csv_files
  cat("Found", length(csv_files), "valid CSV files out of", length(all_files), "total files\n")

  if (length(csv_files) == 0) {
    stop(sprintf("No valid CSV files found in: %s (total files: %d)", input_dir, length(all_files)))
  }

  if (!is.null(year_range)) {
    cat("Filtering files by year_range...\n")
    yr <- sub(".*?(\\d{4}).*", "\\1", basename(csv_files))
    csv_files <- csv_files[yr %in% year_range]
    cat("After filtering:", length(csv_files), "files remain\n")
  }

  summary_stats <- list()
  
  cat("Processing", length(csv_files), "files in parallel\n")
  
  # Process files in parallel
  results <- future_lapply(csv_files, function(file) {
    year <- sub(".*?(\\d{4}).*", "\\1", basename(file))
    
    cat(sprintf("\n=== Processing file for year %s ===\n", year))
    cat("File:", basename(file), "\n")
    message(sprintf("\nProcessing file for year %s", year))
    
    # Read file with enhanced error handling (PRESERVED)
    cat("Reading CSV file...\n")
    df <- safe_file_operation(
      operation = function() {
        read_csv_exclude(file, exclude_cols = exclude_cols)
      },
      file_path = file,
      operation_name = "reading CSV file"
    )
    
    cat("File read complete. Rows:", nrow(df), "Columns:", ncol(df), "\n")
    
    # Initialize statistics
    stats <- list(
      initial_rows = nrow(df),
      duplicates_removed = 0,
      cpt_rows_removed = 0,
      future_dates_nullified = 0,
      historic_dates_nullified = 0,
      date_parsing_errors = 0
    )
    
    # Remove duplicates
    cat("Removing duplicates...\n")
    df <- unique(setDT(df))
    stats$duplicates_removed <- stats$initial_rows - nrow(df)
    cat("Duplicates removed:", stats$duplicates_removed, "Remaining rows:", nrow(df), "\n")
    
    # Remove CPT entries (only if keep_cpt is FALSE)
    if (!keep_cpt && "EMPLOYMENT_DESCRIPTION" %in% colnames(df)) {
      cat("Removing CPT entries...\n")
      cpt_mask <- df$EMPLOYMENT_DESCRIPTION == "CPT"
      stats$cpt_rows_removed <- sum(cpt_mask, na.rm = TRUE)
      df <- df[!cpt_mask]
      cat("CPT rows removed:", stats$cpt_rows_removed, "Remaining rows:", nrow(df), "\n")
    } else {
      cat("Keeping CPT entries or EMPLOYMENT_DESCRIPTION column not found\n")
    }
    
    # Enhanced date parsing with validation (PRESERVED)
    cat("Standardizing", length(date_cols), "date columns...\n")
    for (col in date_cols) {
      if (col %in% colnames(df) && !col %in% exclude_cols) {
        original_dates <- df[[col]]
        
        # Use enhanced date parsing
        temp_dates <- parse_dates_safely(original_dates, col, verbose = TRUE)

        if (col == "FIRST_ENTRY_DATE") {
          # Nullify future dates
          future_mask <- temp_dates > as.Date(future_cutoff)
          temp_dates[future_mask] <- NA
          stats$future_dates_nullified <- sum(future_mask, na.rm = TRUE)

          # Nullify historic dates
          historic_mask <- temp_dates < as.Date(historic_cutoff)
          temp_dates[historic_mask] <- NA
          stats$historic_dates_nullified <- sum(historic_mask, na.rm = TRUE)
        }

        df[[col]] <- temp_dates
      }
    }
    
    # Add year column
    df$Year <- year
    
    # Clean specific SEVIS columns (PRESERVED)
    cat("Cleaning text data in SEVIS columns...\n")
    df <- clean_sevis_columns(df, verbose = TRUE)

    # Restore leading zeros to ZIP codes BEFORE lowercase conversion
    # (fixes DHS/ICE source data issue, must run before lowercase to preserve character type)
    cat("Restoring leading zeros to ZIP codes...\n")
    df <- fix_zip_leading_zeros(df, verbose = TRUE)

    # Convert all remaining character columns to lowercase
    # (ZIP codes are now character and will be included, but digits are case-insensitive so unaffected)
    char_cols <- names(df)[sapply(df, is.character)]
    df[, (char_cols) := lapply(.SD, tolower), .SDcols = char_cols]

    # Write cleaned data with enhanced error handling (PRESERVED)
    output_path <- fs::path(output_dir, sprintf("cleaned_%s_all.csv", year))
    cat("Writing cleaned data to:", output_path, "\n")
    cat("Final data size - Rows:", nrow(df), "Columns:", ncol(df), "\n")
    
    # Ensure ZIP code columns remain as character type (prevent auto-conversion to integer)
    zip_cols <- c("CAMPUS_ZIP_CODE", "EMPLOYER_ZIP_CODE")
    for (col in zip_cols) {
      if (col %in% colnames(df)) {
        df[[col]] <- as.character(df[[col]])
      }
    }

    cat("Using data.table fwrite...\n")
    safe_file_operation(
      operation = function() {
        # Use quote="auto" to preserve leading zeros in numeric-looking strings
        fwrite(df, output_path, quote="auto")
      },
      file_path = output_path,
      operation_name = "writing cleaned file"
    )
    cat("File write complete\n")
    
    # Store statistics
    summary_stats[[year]] <- stats
    
    # Clean up
    cat("Cleaning up memory for year", year, "...\n")
    rm(df)
    gc()
    
    # Print summary
    message(sprintf("Year %s summary:", year))
    message(sprintf("Initial rows: %d", stats$initial_rows))
    message(sprintf("Duplicates removed: %d", stats$duplicates_removed))
    if (!keep_cpt) {
      message(sprintf("CPT rows removed: %d", stats$cpt_rows_removed))
    } else {
      message("CPT rows kept (keep_cpt = TRUE)")
    }
    message(sprintf("Future dates nullified: %d", stats$future_dates_nullified))
    message(sprintf("Historic dates nullified: %d", stats$historic_dates_nullified))

    return(list(year = year, stats = stats, output_path = output_path))
  }, future.seed = TRUE)
  
  return(summary_stats)
}

# Main optimized function (PRESERVING ALL FUNCTIONALITY)
combine_and_clean_data_optimized <- function(root_dir, raw_output_dir, clean_output_dir,
                                            write_raw_files = FALSE,
                                            write_clean_files = FALSE,
                                            exclude_cols = DEFAULT_EXCLUDE_COLS,
                                            verbose = TRUE,
                                            year_range = NULL,
                                            keep_cpt = TRUE,
                                            historic_cutoff = NULL) {
  
  cat("=== Starting combine_and_clean_data_optimized function ===\n")
  cat("Parameters: root_dir =", root_dir, "\n")
  cat("            write_raw_files =", write_raw_files, "\n")
  cat("            write_clean_files =", write_clean_files, "\n")

  # Use date columns from configuration
  date_cols <- DATE_COLUMNS

  # First, combine the raw data (this writes to files)
  if (write_raw_files) {
    if (is.null(raw_output_dir)) {
      stop("raw_output_dir must be specified when write_raw_files is TRUE")
    }
    process_yearly_data_parallel(
      root_dir = root_dir,
      exclude_cols = exclude_cols,
      verbose = verbose,
      output_dir = raw_output_dir,
      year_range = year_range
    )
  }
  
  # Then clean the data from raw_output_dir
  cat("Checking if write_clean_files =", write_clean_files, "\n")
  if (write_clean_files) {
    cat("write_clean_files is TRUE, proceeding with cleaning...\n")
    if (is.null(raw_output_dir) | is.null(clean_output_dir)) {
      stop("raw_output_dir must be specified for cleaning")
    }
    
    cat("raw_output_dir =", raw_output_dir, "\n")
    cat("clean_output_dir =", clean_output_dir, "\n")
  
    # Check headers in raw_output_dir before cleaning (PRESERVED)
    cat("Checking directory headers in raw_output_dir...\n")
    check_directory_headers(raw_output_dir, exclude_cols, verbose)
    
    cleaning_summary <- clean_yearly_data_optimized(
      input_dir = raw_output_dir,
      output_dir = clean_output_dir,
      date_cols = date_cols,
      exclude_cols = exclude_cols,
      keep_cpt = keep_cpt,
      year_range = year_range,
      historic_cutoff = historic_cutoff
    )
  }
  
  return(list(
    cleaning_summary = cleaning_summary,
    raw_output_dir = if(write_raw_files) raw_output_dir else "",
    clean_output_dir = if(write_clean_files) clean_output_dir else ""
  ))
}

# Function to check if all files in a directory have consistent headers (PRESERVED)
check_directory_headers <- function(dir_path, exclude_cols = DEFAULT_EXCLUDE_COLS, verbose = TRUE) {
  cat("=== Starting check_directory_headers ===\n")
  cat("dir_path:", dir_path, "\n")
  
  if (!dir.exists(dir_path)) {
    stop(sprintf("Directory does not exist: %s", dir_path))
  }
  cat("Directory exists\n")
  
  cat("Looking for CSV files...\n")
  # Get all files and filter for CSV files more robustly
  all_files <- fs::dir_ls(dir_path, type = "file")
  potential_csv_files <- all_files[grepl("\\.csv$", all_files, ignore.case = TRUE)]
  
  # Validate that the files are actually readable CSV files
  cat("Validating CSV files...\n")
  valid_csv_files <- c()
  for (file in potential_csv_files) {
    if (validate_csv_file(file)) {
      valid_csv_files <- c(valid_csv_files, file)
    }
  }
  
  csv_files <- valid_csv_files
  cat("Found", length(csv_files), "valid CSV files out of", length(all_files), "total files\n")
  
  if (length(csv_files) == 0) {
    stop(sprintf("No valid CSV files found in: %s (total files: %d)", dir_path, length(all_files)))
  }
  
  # Get structure of all files
  cat("Getting file structures for", length(csv_files), "files...\n")
  structures <- lapply(csv_files, get_file_structure, exclude_cols = exclude_cols)
  cat("File structure analysis complete\n")
  
  # Check if all structures are identical to the first one
  all_identical <- all(sapply(structures[-1], identical, structures[[1]]))
  
  if (!all_identical) {
    stop(sprintf("Files in %s have inconsistent headers. Please check the files manually.", dir_path))
  }
  
  if (verbose) {
    message(sprintf("\n✓ All files in %s have identical structure (%d columns)", 
                   dir_path, length(structures[[1]])))
  }
  
  return(TRUE)
}

# Example usage - configured for OPT Observatory repository
result <- combine_and_clean_data_optimized(
  root_dir = "/Users/violet/Library/CloudStorage/GoogleDrive-violet@ifp.org/Shared drives/DataDrive/raw/sevis_data/F-1/F-1_raw",
  raw_output_dir = "/Users/violet/Desktop/repos/OPT-observatory/data/raw/USE_THESE__uncorrected_file_names",
  clean_output_dir = "/Users/violet/Desktop/repos/OPT-observatory/data/cleaned_corrected_file_names",
  write_raw_files = FALSE,  # Raw files already exist in data/raw
  write_clean_files = TRUE,
  exclude_cols = DEFAULT_EXCLUDE_COLS,
  verbose = TRUE,
  year_range = c(2005:2022),  # TEST: verify employer ZIP fix
  keep_cpt = TRUE,
  historic_cutoff = "1980-01-01"  # Nullify dates before 1980
)

cat("\n=== Cleaning complete ===\n")
cat("Raw files written to:", result$raw_output_dir, "\n")
cat("Cleaned files written to:", result$clean_output_dir, "\n") 