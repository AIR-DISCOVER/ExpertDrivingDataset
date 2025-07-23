# =============================================================================
# Load Necessary Packages
# =============================================================================
library(readr)
library(readxl)
library(ggplot2)
library(dplyr)
library(tidyr)
library(zoo)
library(stringr)   # For string manipulation functions like str_sub
library(tibble)    # For converting columns to rownames (column_to_rownames)

# =============================================================================
# 1. List All csv files
# =============================================================================
# Replace 'filename' with the appropriate folder path that contains your CSV files.
right_turn_files <- list.files('drivingcondition', full.names = TRUE)

# =============================================================================
# 2. Initialize an Empty Data Frame for Processed Data
# =============================================================================
processed_data <- data.frame()

# =============================================================================
# 3. Process Each File
# =============================================================================
for(file in right_turn_files) {
  
  # -- Extract identifiers from the file name --
  # Here, subject_id is extracted from characters 11 to 13 of the file name,
  # and driver_type is obtained from the 11th character.
  subject_id <- str_sub(file, 11, 13)
  driver_type <- str_sub(file, 11, 11)
  
  # -- Read and Transform Data --
  # Read the CSV file, then remove the first two columns. The remaining data is 
  # transformed from wide to long format (from column "car" to "stop").
  temp_data <- read.csv(file) %>%
    select(-c(1:2)) %>%
    pivot_longer(cols = car:stop)
  
  # -- Calculate Statistics --
  # Aggregate the data by the "name" column computing the mean of the "value".
  # The aggregated data is then:
  #   1. Converted with row names set to the variable names
  #   2. Transposed, so that each variable now becomes a column
  #   3. Converted into a data frame.
  # Finally, add identifiers: subject ID, driver type, and group ("RT").
  temp_stats <- aggregate(value ~ name, temp_data, mean) %>%
    column_to_rownames('name') %>%
    t() %>%
    data.frame() %>%
    mutate(
      ID = subject_id,
      Driver = ifelse(driver_type == 'E', 'Expert', 'Novice'),
      Group = 'drivingcondition'
    )
  
  # -- Combine Results --
  # Append the statistics for this file to the processed_data dataframe.
  processed_data <- rbind(processed_data, temp_stats)
}

# =============================================================================
# 4. Save Processed Data to a CSV File
# =============================================================================
# Replace 'filename.csv' with the desired output file name or path.
write.csv(processed_data, 'drivingcondition.csv', row.names = FALSE)

# =============================================================================
# 5. Combine result files
# =============================================================================
# List all result files in the '_result' directory and show the file names.
result_files <- list.files('_result', full.names = TRUE)
head(result_files)

# Initialize an empty data frame to store combined results.
combined_results <- data.frame()

# Loop over each file in the result_files list.
# For each file, read the CSV data and append it to the combined_results data frame.
for(file in result_files) {
  temp_data <- read.csv(file)
  combined_results <- rbind(combined_results, temp_data)
}

# Save the combined results data frame to a CSV file.
write.csv(combined_results, 'conbine_result.csv', row.names = FALSE)