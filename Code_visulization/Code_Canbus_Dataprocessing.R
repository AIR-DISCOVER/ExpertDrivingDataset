# =============================================================================
# 1. Load the Required Libraries
# =============================================================================
library(ggpubr)
library(data.table)
library(readxl)
library(tidyverse)  # This loads ggplot2, dplyr, tidyr, etc.
library(dplyr)
library(ggplot2)

# =============================================================================
# 2. Process Event 1 Data from "13_LeftTurn-3"
# =============================================================================
# List all CSV files in the specified folder.
id1 <- list.files('13_LeftTurn-3', full.names = TRUE)
head(id1)

# Initialize an empty data frame to store the processed statistics.
df_bs <- data.frame()

# Loop through each file in the folder.
for(i in id1) {
  
  # -- Extract Identifiers --
  # Get the folder name (used later as the Group identifier)
  folder_name <- basename(dirname(i))
  # Extract the file name without extension (serving as the subject ID)
  tmp_id <- tools::file_path_sans_ext(basename(i))
  # Determine whether the file represents an Expert (E) or Novice (N) based on the first character
  tmp_id2 <- str_sub(tmp_id, 1, 1)
  
  # -- Read and Transform Data --
  # Read the CSV file and remove unwanted columns (columns 1 to 9, 11, and 16 to 18)
  # Then pivot the data from wide format to long format for columns "speed_mps" to "jerk.1s"
  tmp_df <- read.csv(i) %>%
    select(-c(1:9, 11, 16:18)) %>%
    pivot_longer(cols = speed_mps:jerk.1s)
  
  # -- Calculate Statistics --
  # Aggregate the values by the 'name' column (computing the mean), 
  # set the variable names as row names, transpose the data, and convert it into a data frame.
  # Finally, add the subject ID, Driver type, and Group (folder name) as new columns.
  tmp_stat <- aggregate(value ~ name, tmp_df, mean) %>%
    column_to_rownames('name') %>%
    t() %>%
    data.frame() %>%
    mutate(
      ID = tmp_id,
      Driver = ifelse(tmp_id2 == 'E', 'Expert', 'Novice'),
      Group = folder_name  # Use folder name as Group
    )
  
  # Append the temporary statistics of the current file to the overall data frame.
  df_bs <- rbind(df_bs, tmp_stat)
}

# =============================================================================
# 3. Write Processed Event Data to CSV
# =============================================================================
# Construct an output file name based on the folder name and save the data.
output_file <- paste0(folder_name, '_result.csv')
write.csv(df_bs, output_file, row.names = FALSE)

# =============================================================================
# 4. Combine CSV Files from the "conbine_csv" Folder
# =============================================================================
# List all CSV files within the 'conbine_csv' folder.
id1 <- list.files('conbine_csv', full.names = TRUE)
head(id1)

# Initialize an empty data frame for the combined results.
df_bs <- data.frame()

# Loop through each file in the folder and append its content to df_bs.
for(i in id1) {
  tmp_df <- read.csv(i)
  df_bs <- rbind(df_bs, tmp_df)
}

# Save the combined data into a single CSV file.
write.csv(df_bs, 'conbine_result.csv', row.names = FALSE)