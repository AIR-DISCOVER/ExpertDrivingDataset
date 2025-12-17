Below is an English README for the provided R code. This document explains the workflow and logic of the code, which includes splitting CSV files, calculating the relative frequency of specific characters, and combining CSV files from several folders.

---

# CSV Processing and Data Aggregation Script README

This R script automates several data processing tasks on CSV files. The script is broken down into four main sections:

1. **Splitting CSV Files by Row Count**  
2. **Calculating Relative Frequency of Specific Characters**  
3. **Combining Data from the "0_Baseline_" Folder**  
4. **Combining Data from the "1-5" Folder**

Each section’s functionality and usage are described in detail below.

---

## Dependencies

The script uses the following R packages:

- **dplyr**: For data manipulation.  
- **tidyr**: For data reshaping.  
- **ggpubr**: (Generally used for plotting/statistical comparisons; included as part of the package set.)  
- **stringr**: For string manipulation functions such as `str_sub` and `str_count`.  
- **tools**: For file name processing (e.g., `file_path_sans_ext`).

Make sure these packages are installed. You can install them with:

```r
install.packages(c("dplyr", "tidyr", "ggpubr", "stringr", "tools"))
```

---

## 1. Splitting CSV Files by Row Count

### Purpose

This section splits CSV files into smaller parts based on a fixed number of rows. This is useful when dealing with very large files. For each file, the code:
- Reads the file and calculates the total number of rows.
- Divides the data into segments with a preset number of rows (set by `rows_per_file`, e.g., 500).
- Writes each segment to a new CSV file.
- Deletes the last part if it contains fewer rows than expected.

### Key Functions

- **`split_csv` Function:**  
  Reads a CSV file, splits it into parts, and writes each part as a separate CSV file in the output directory.  
  - It constructs an output filename based on the original file name and appends `_partX` for each segment.
  - After processing, it checks if the last file has fewer rows than the target and, if so, removes it.

- **`process_folder` Function:**  
  Processes all CSV files in a specified folder by:
  - Creating an output directory (named by appending an underscore to the original folder name).
  - Applying the `split_csv` function to each CSV file found.

### Code Segment

```r
# Define folder path and number of rows per split file
folder_path <- "~/Desktop/scientificdata/3-Driver/2-EyeTracking_/13_LeftTurn-3"
rows_per_file <- 500

# Function to split a CSV file into multiple parts based on fixed row count
split_csv <- function(file_path, output_dir, rows_per_file = 1000) {
  # Read the CSV file (with headers)
  data <- read.csv(file_path, header = TRUE)
  
  # Extract the file name without extension
  file_name <- tools::file_path_sans_ext(basename(file_path))
  
  # Calculate total rows and the number of required output files
  total_rows <- nrow(data)
  num_files <- ceiling(total_rows / rows_per_file)
  
  last_file_path <- NULL
  
  # Loop through and write each part to a new CSV file
  for (i in 1:num_files) {
    start_row <- (i - 1) * rows_per_file + 1
    end_row <- min(i * rows_per_file, total_rows)
    
    # Extract the subset of data for current part
    split_data <- data[start_row:end_row, ]
    
    # Create output file name and path
    output_file <- paste0(output_dir, "/", file_name, "_part", i, ".csv")
    
    # Write subset to a CSV file (with header, no row names)
    write.csv(split_data, file = output_file, row.names = FALSE)
    
    # Save the path of the current (last) file
    last_file_path <- output_file
  }
  
  # Delete the last file if it has fewer rows than 'rows_per_file'
  if (!is.null(last_file_path)) {
    last_file_data <- read.csv(last_file_path, header = TRUE)
    if (nrow(last_file_data) < rows_per_file) {
      file.remove(last_file_path)
    }
  }
}

# Function to process all CSV files in the specified folder
process_folder <- function(folder_path, rows_per_file = 1000) {
  # Get folder name
  folder_name <- basename(folder_path)
  
  # Create output directory (folderName_ in the same parent folder)
  output_dir <- file.path(dirname(folder_path), paste0(folder_name, "_"))
  
  # Create output directory if not exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir)
  }
  
  # List all CSV files in the folder
  csv_files <- list.files(folder_path, pattern = "\\.csv$", full.names = TRUE)
  
  # Apply split_csv function to each CSV file
  for (file in csv_files) {
    split_csv(file, output_dir, rows_per_file)
  }
}

# Execute the CSV splitting process
process_folder(folder_path, rows_per_file)
```

---

## 2. Calculating Relative Frequency of Specific Characters

### Purpose

This section calculates the relative frequency of numeric characters (from "9" to "1") in a specified column of each CSV file in a given folder. Here, the target is the 57th column of each CSV file. The calculation involves:
- Counting how many times each character appears in the text.
- Dividing by the total number of characters in the data.

### Key Steps

- **List CSV Files:**  
  All CSV files in a provided folder (here, the placeholder folder name is `"filename"`) are read.

- **Character Frequency Calculation:**  
  For each CSV file:
  - The file's ID is determined (using the file name without extension) and a driver type is deduced from the first character of the ID.
  - The 57th column is extracted.
  - For each character in the list `c("9", "8", "7", "6", "5", "4", "3", "2", "1")`, the relative frequency is computed.
  - The results are aggregated (grouped by ID and Driver) and stored.

- **Output:**  
  The final aggregated data is saved as `<folder_name>_result.csv`.

### Code Segment

```r
# List CSV files from the folder "filename" (ensure the folder path is correct)
id1 <- list.files("filename", full.names = TRUE)
head(id1)
df_bs <- data.frame()  # Initialize an empty data frame

# Define characters to calculate relative frequency for
characters_to_count <- c("9", "8", "7", "6", "5", "4", "3", "2", "1")

# Loop through each file to compute character frequencies
for (i in id1) {
  # Get folder name from the file's directory
  folder_name <- basename(dirname(i))
  
  # Extract file name without extension (ID)
  tmp_id <- tools::file_path_sans_ext(basename(i))
  
  # Get the first character of the ID (driver type indicator)
  tmp_id2 <- str_sub(tmp_id, 1, 1)
  
  # Read the CSV file and select the 57th column
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

# Add a "Group" column with the folder name for every record
df_bs <- df_bs %>%
  mutate(Group = folder_name)

# Write the resulting data frame to a CSV file named "<folder_name>_result.csv"
output_file <- paste0(folder_name, "_result.csv")
write.csv(df_bs, output_file, row.names = FALSE)
```

---

## 3. Combining Data from the "0_Baseline_" Folder

### Purpose

This section reads all CSV files in the `"0_Baseline_"` folder, extracts a specific column (the 54th column) from each file, and combines the results into a single CSV output.

### Key Steps

- **List Files:**  
  List all CSV files in the `"0_Baseline_"` directory.

- **Read and Process:**  
  For each file:
  - Extract the file's ID and determine the driver type (again, based on the first character of the file name).
  - Read the 54th column.
  - Append the data to a cumulative dataframe.
  
- **Add Group Identifier:**  
  The folder name is assigned as the Group for all rows.
  
- **Output:**  
  Write the combined data to a CSV file named `<folder_name>_result.csv`.

### Code Segment

```r
# List CSV files in the "0_Baseline_" directory
id1 <- list.files("0_Baseline_", full.names = TRUE)
head(id1)
df_bs <- data.frame()  # Initialize an empty data frame

for (i in id1) {
  # Get folder name from the file's directory
  folder_name <- basename(dirname(i))
  
  # Extract file name (ID) without extension
  tmp_id <- tools::file_path_sans_ext(basename(i))
  
  # Determine driver type from the first character of the ID
  tmp_id2 <- str_sub(tmp_id, 1, 1)
  
  # Read the CSV file and select the 54th column
  tmp_df <- read.csv(i) %>%
    select(c(54)) %>%  # Select the 54th column of the data
    mutate(ID = tmp_id,
           Driver = tmp_id2)
  
  # Append the data from this file to the overall data frame
  df_bs <- rbind(df_bs, tmp_df)
}

# Assign the folder name as the 'Group' for all rows
df_bs$Group <- folder_name

# Write the combined data frame to a CSV file named "<folder_name>_result.csv"
output_file <- paste0(folder_name, "_result.csv")
write.csv(df_bs, output_file, row.names = FALSE)
```

---

## 4. Combining Data from the "1-5" Folder

### Purpose

This section merges all CSV files located in the `"1-5"` folder into one master CSV file. This allows for the aggregated data to be easily processed in later stages.

### Key Steps

- **List Files:**  
  Identify all CSV files in the `"1-5"` folder.

- **Combine Data:**  
  Loop through each file, read its content, and combine all data into one dataframe.

- **Output:**  
  Write the final combined data to a CSV file named `"conbi_string.csv"`.

### Code Segment

```r
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
```

---

## Running Instructions

1. **File Organization:**  
   - Place the CSV files to be split in the folder defined by `folder_path` (e.g., `"~/Desktop/scientificdata/3-Driver/2-EyeTracking_/13_LeftTurn-3"`).
   - Ensure that the folders `"filename"`, `"0_Baseline_"`, and `"1-5"` contain the respective CSV files as expected.

2. **Install Dependencies:**  
   Install the required packages if you haven’t already:
   ```r
   install.packages(c("dplyr", "tidyr", "ggpubr", "stringr", "tools"))
   ```

3. **Execute the Script:**  
   - Run the entire script in your R environment (e.g., RStudio).
   - The script will:
     - Split large CSV files based on the specified row count.
     - Calculate relative frequencies of selected characters and save the summary.
     - Combine specific columns from CSV files in the `"0_Baseline_"` folder.
     - Merge all CSV files from the `"1-5"` folder into one file.

4. **Check Output:**  
   After execution, confirm that the following output CSV files are generated:
   - `<folder_name>_result.csv` (from relative frequency calculations and baseline data merging).
   - `conbi_string.csv` (from merging the `"1-5"` folder files).

---

## Summary

This script provides a complete workflow to:

- **Split Large CSV Files:**  
  Divide CSV files into multiple parts based on a fixed number of rows.

- **Calculate Character Frequencies:**  
  Compute the relative frequency of specific numeric characters in a target column, aggregating the results by file ID and driver type.

- **Combine Multiple CSV Files:**  
  Aggregate data from multiple folders into consolidated CSV files for subsequent analysis.

This README should help you understand, run, and modify the processing pipeline as needed.

---