# =============================================================================
# Load Required Libraries
# =============================================================================
library(dplyr)
library(tidyr)
library(ggpubr)
library(stringr)   # for str_sub and str_count functions
library(tools)     # for file_path_sans_ext

# =============================================================================
# 1. Split CSV Files by Row Count
# =============================================================================

# Path to the folder containing CSV files to split
folder_path <- "~/Desktop/scientificdata/3-Driver/2-EyeTracking_/13_LeftTurn-3"
rows_per_file <- 500

# Function to split a CSV file into multiple parts based on a fixed number of rows
split_csv <- function(file_path, output_dir, rows_per_file = 1000) {
  # Read the CSV file (with headers)
  data <- read.csv(file_path, header = TRUE)
  
  # Get the file name without its extension
  file_name <- tools::file_path_sans_ext(basename(file_path))
  
  # Calculate the required number of output files
  total_rows <- nrow(data)
  num_files <- ceiling(total_rows / rows_per_file)
  
  last_file_path <- NULL
  
  # Loop over each file part, slicing the data accordingly
  for (i in 1:num_files) {
    start_row <- (i - 1) * rows_per_file + 1
    end_row <- min(i * rows_per_file, total_rows)
    
    # Extract the subset of data for the current part
    split_data <- data[start_row:end_row, ]
    
    # Create the output file name and path
    output_file <- paste0(output_dir, "/", file_name, "_part", i, ".csv")
    
    # Write the subset to a CSV file (with header, without row names)
    write.csv(split_data, file = output_file, row.names = FALSE)
    
    # Save the path of the current (last) file
    last_file_path <- output_file
  }
  
  # Check if the last file has fewer rows than rows_per_file; if so, delete it.
  if (!is.null(last_file_path)) {
    last_file_data <- read.csv(last_file_path, header = TRUE)
    if (nrow(last_file_data) < rows_per_file) {
      file.remove(last_file_path)
    }
  }
}

# Function to process all CSV files in a specified folder
process_folder <- function(folder_path, rows_per_file = 1000) {
  # Get the folder name
  folder_name <- basename(folder_path)
  
  # Create an output directory with name "folderName_"
  output_dir <- file.path(dirname(folder_path), paste0(folder_name, "_"))
  
  # Create the output directory if it does not exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir)
  }
  
  # Get a list of all CSV files in the folder
  csv_files <- list.files(folder_path, pattern = "\\.csv$", full.names = TRUE)
  
  # Apply the split_csv function to each CSV file in the folder
  for (file in csv_files) {
    split_csv(file, output_dir, rows_per_file)
  }
}

# Execute the CSV splitting process
process_folder(folder_path, rows_per_file)

# =============================================================================
# 2. Calculate Relative Frequency of Specific Characters
# =============================================================================

# List CSV files from the folder named 'filename'
id1 <- list.files("filename", full.names = TRUE)
head(id1)
df_bs <- data.frame()  # Initialize an empty data frame

# Define the characters whose relative frequency will be calculated
characters_to_count <- c("9", "8", "7", "6", "5", "4", "3", "2", "1")

# Loop through each file to compute character frequencies
for (i in id1) {
  # Get the folder name (from the file's directory)
  folder_name <- basename(dirname(i))
  
  # Extract the file name without extension (ID)
  tmp_id <- tools::file_path_sans_ext(basename(i))
  
  # Get the first character of the file name (acts as a driver type indicator)
  tmp_id2 <- str_sub(tmp_id, 1, 1)
  
  tmp_df <- read.csv(i) %>%
    select(c(57)) %>%  # Select the 57th column of the data
    mutate(ID = tmp_id,
           Driver = tmp_id2)
  
  # For each character, compute its relative frequency in the selected column
  for (char in characters_to_count) {
    tmp_df[[char]] <- str_count(tmp_df[[1]], char) / nchar(tmp_df[[1]])
  }
  
  # Group by ID and Driver, then compute mean frequencies for each character
  tmp_summary <- tmp_df %>%
    group_by(ID, Driver) %>%
    summarize(across(all_of(characters_to_count), mean, na.rm = TRUE))
  
  # Append the summarized data to the final data frame
  df_bs <- rbind(df_bs, tmp_summary)
}

# Add a "Group" column to assign the folder name to every record
df_bs <- df_bs %>%
  mutate(Group = folder_name)

# Write the resulting data frame to a CSV file called "<folder_name>_result.csv"
output_file <- paste0(folder_name, "_result.csv")
write.csv(df_bs, output_file, row.names = FALSE)

# =============================================================================
# 3. Combine Data from "0_Baseline_" Folder into One CSV File
# =============================================================================

# List CSV files in the "0_Baseline_" directory
id1 <- list.files("0_Baseline_", full.names = TRUE)
head(id1)
df_bs <- data.frame()  # Create an empty data frame

for (i in id1) {
  # Get folder name from the file's directory
  folder_name <- basename(dirname(i))
  
  # Extract the file name without extension (ID)
  tmp_id <- tools::file_path_sans_ext(basename(i))
  
  # Determine driver type based on the first character of the ID
  tmp_id2 <- str_sub(tmp_id, 1, 1)
  
  tmp_df <- read.csv(i) %>%
    select(c(54)) %>%  # Select the 54th column of the data
    mutate(ID = tmp_id,
           Driver = tmp_id2)
  
  # Append the data from this file to the overall data frame
  df_bs <- rbind(df_bs, tmp_df)
}

# Assign the folder name as the group for all rows
df_bs$Group <- folder_name

# Write the combined data frame to a CSV file named "<folder_name>_result.csv"
output_file <- paste0(folder_name, "_result.csv")
write.csv(df_bs, output_file, row.names = FALSE)

# =============================================================================
# 4. Combine Data from "1-5" Folder into One CSV File
# =============================================================================

# List CSV files in the "1-5" directory
id1 <- list.files("1-5", full.names = TRUE)
head(id1)
df_bs <- data.frame()  # Initialize an empty data frame

for (i in id1) {
  tmp_df <- read.csv(i)
  df_bs <- rbind(df_bs, tmp_df)
}

# Write the combined data to a CSV file named "conbi_string.csv"
write.csv(df_bs, "conbi_string.csv", row.names = FALSE)
