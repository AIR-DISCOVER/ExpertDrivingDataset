# =============================================================================
# 1. Load Required Libraries
# =============================================================================
library(ggpubr)
library(data.table)
library(readxl)
library(tidyverse)   # Loads ggplot2, dplyr, tidyr, stringr, etc.
library(dplyr)
library(ggplot2)

# =============================================================================
# 2. Process Event Data from "drivingcondition"
# =============================================================================

# List all CSV files in the "drivingcondition" folder with full paths.
id1 <- list.files('drivingcondition', full.names = TRUE)
head(id1)

# Create an empty data frame to store the processed statistics.
df_bs <- data.frame()

# Loop through each CSV file in the folder.
for(i in id1) {
  
  # -- Extract Identifiers --
  # Get the folder name (used later as the Group identifier)
  folder_name <- basename(dirname(i))
  
  # Extract the file name without extension (serves as the subject ID)
  tmp_id <- tools::file_path_sans_ext(basename(i))
  
  # Determine whether the first character of the file name indicates Expert ('E') or Novice
  tmp_id2 <- str_sub(tmp_id, 1, 1)
  
  # -- Read and Transform Data --
  # Read the CSV file, remove undesired columns (columns 1-3, 11, and 19-25),
  # then pivot data from wide to long format for the columns from "Emotion.value_angry" to "emotion_ratios_neutral".
  tmp_df <- read.csv(i) %>%
    select(-c(1:3, 11, 19:25)) %>%
    pivot_longer(cols = Emotion.value_angry:emotion_ratios_neutral)
  
  # -- Calculate Statistics --
  # Aggregate the mean values for each variable grouped by "name", 
  # set the "name" column as rownames, transpose the data, and convert it to a data frame.
  # Finally, add the subject ID, Driver type, and Group information.
  tmp_stat <- aggregate(value ~ name, tmp_df, mean) %>%
    column_to_rownames('name') %>%  # Set the values in column "name" as rownames
    t() %>%
    data.frame() %>%
    mutate(
      ID = tmp_id,
      Driver = ifelse(tmp_id2 == 'E', 'Expert', 'Novice'),
      Group = folder_name  # Use folder name for Group
    )
  
  # Append the processed statistics for this file to the overall data frame.
  df_bs <- rbind(df_bs, tmp_stat)
}

# =============================================================================
# 3. Write Processed Data to CSV
# =============================================================================
# Construct an output file name using the folder name and save the results.
output_file <- paste0(folder_name, '_result.csv')
write.csv(df_bs, output_file, row.names = FALSE)

# =============================================================================
# 4. Combine CSV Files from the "conbine_csv" Folder
# =============================================================================
# List all CSV files in the "conbine_csv" folder with their full paths.
id1 <- list.files('conbine_csv', full.names = TRUE)
head(id1)

# Create an empty data frame to store the combined data.
df_bs <- data.frame()

# Loop through each CSV file and append its data to the combined data frame.
for(i in id1) {
  tmp_df <- read.csv(i)
  df_bs <- rbind(df_bs, tmp_df)
}

# Write the combined data to a CSV file.
write.csv(df_bs, 'conbine_result.csv', row.names = FALSE)