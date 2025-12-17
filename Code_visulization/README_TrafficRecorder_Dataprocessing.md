Below is a detailed **README** that explains the workflow and purpose of the provided R code. This script processes CSV files containing driving condition data, computes summary statistics for each file, and then combines multiple result CSV files into a final output. The following README is organized into sections that mirror the structure of the code.

---

# Driving Condition Data Processing and Combination Script

This script automates the processing of CSV files stored in a folder (e.g., `"drivingcondition"`) and then consolidates result files from another directory (e.g., `"_result"`). The main tasks performed by the script include:

- **Listing and Processing CSV Files:**  
  The code reads each CSV file in the `"drivingcondition"` directory, extracts identifiers from the file name, transforms the data from wide to long format, and computes the mean for each variable.

- **Saving Processed Data:**  
  The aggregated results from each file are combined into a single data frame and saved as `drivingcondition.csv`.

- **Combining Additional Result Files:**  
  The script then reads all CSV files from the `"_result"` folder, combines them into one data frame, and saves the final combined result in `conbine_result.csv`.

---

## 1. Load Necessary Packages

The script begins by loading a set of R packages that are needed for file input/output, data manipulation, reshaping, interpolation, and string manipulation. In particular, the code uses:
- **readr** and **readxl** for reading CSV and Excel files.
- **ggplot2** primarily for plotting (if needed), though this script focuses on data processing.
- **dplyr** and **tidyr** for data manipulation and reshaping.
- **zoo** for time-series tools.
- **stringr** for substring extractions.
- **tibble** for helper functions (e.g., converting columns to row names).

```r
library(readr)
library(readxl)
library(ggplot2)
library(dplyr)
library(tidyr)
library(zoo)
library(stringr)   # For string manipulation functions like str_sub
library(tibble)    # For converting columns to rownames (column_to_rownames)
```

---

## 2. List All CSV Files

The script lists all CSV files located in the `"drivingcondition"` folder using the `list.files()` function. The full paths of these files are stored in the variable `right_turn_files`.

```r
right_turn_files <- list.files('drivingcondition', full.names = TRUE)
```

---

## 3. Process Each File and Compute Summary Statistics

For each CSV file in the `"drivingcondition"` folder, the script performs the following steps:

- **Extract Identifiers:**  
  Uses `str_sub()` to extract a subject identifier and driver type from specific positions in the file name. In this example, characters 11 to 13 are used as the subject ID and the 11th character determines the driver type (with `"E"` indicating an expert).

- **Read and Transform Data:**  
  Reads the CSV file into a data frame, removes the first two columns, and converts the remaining wide-format data (from columns `"car"` to `"stop"`) into a long format via `pivot_longer()`.

- **Calculate Statistics:**  
  Aggregates the long-format data by computing the mean value for each variable (grouped by the variable name). The aggregated data is then transformed:
  - Row names are set to the variable names.
  - The data are transposed so that each variable becomes a column.
  - The subject ID, driver type (mapped to `"Expert"` or `"Novice"`), and a constant group label (here, `"drivingcondition"`) are added to the data.

- **Combine the Results:**  
  Each file’s processed data is appended to a cumulative data frame `processed_data`.

```r
processed_data <- data.frame()

for(file in right_turn_files) {
  
  # -- Extract identifiers from the file name --
  subject_id <- str_sub(file, 11, 13)
  driver_type <- str_sub(file, 11, 11)
  
  # -- Read and transform data --
  temp_data <- read.csv(file) %>%
    select(-c(1:2)) %>%
    pivot_longer(cols = car:stop)
  
  # -- Calculate statistics --
  temp_stats <- aggregate(value ~ name, temp_data, mean) %>%
    column_to_rownames('name') %>%
    t() %>%
    data.frame() %>%
    mutate(
      ID = subject_id,
      Driver = ifelse(driver_type == 'E', 'Expert', 'Novice'),
      Group = 'drivingcondition'
    )
  
  # -- Combine results --
  processed_data <- rbind(processed_data, temp_stats)
}
```

---

## 4. Save the Processed Data to CSV

Once all CSV files have been processed, the aggregated data is saved to a file named `drivingcondition.csv`.

```r
write.csv(processed_data, 'drivingcondition.csv', row.names = FALSE)
```

---

## 5. Combine Result Files from the `_result` Folder

In the next phase, the script performs the following operations:

- **List Result Files:**  
  All CSV files in the `_result` folder are listed.

- **Combine Data:**  
  The script reads each file and appends its contents into a cumulative data frame, `combined_results`.

- **Save Combined Results:**  
  The final combined data frame is saved to a CSV file named `conbine_result.csv`.

```r
# List all result files in the '_result' directory.
result_files <- list.files('_result', full.names = TRUE)
head(result_files)

# Initialize an empty data frame to store combined results.
combined_results <- data.frame()

# Loop over each result file.
for(file in result_files) {
  temp_data <- read.csv(file)
  combined_results <- rbind(combined_results, temp_data)
}

# Save the combined results.
write.csv(combined_results, 'conbine_result.csv', row.names = FALSE)
```

---

## Running Instructions

1. **Data Preparation:**  
   - Ensure that the folder `"drivingcondition"` contains your CSV files to be processed.
   - Also, place the result files you wish to combine inside the `_result` folder.

2. **Install Dependencies:**  
   Make sure the required R packages are installed. Missing packages can be installed via:
   ```r
   install.packages(c("readr", "readxl", "ggplot2", "dplyr", "tidyr", "zoo", "stringr", "tibble"))
   ```

3. **Execute the Script:**  
   - Run the script in your preferred R environment (e.g., RStudio).
   - The processed data will be saved as `drivingcondition.csv` and the combined result as `conbine_result.csv`.

4. **Review the Output:**  
   After execution, check your working directory for the two CSV output files.

---

## Summary

This script provides an automated workflow to:

- **Process Multiple CSV Files:**  
  It reads each CSV file from a specified folder, transforms the data from wide to long format, extracts and processes identifiers, and computes mean values for each variable.

- **Combine and Save Results:**  
  The processed data for individual files is combined into one CSV file (`drivingcondition.csv`), and additional result files from another folder are merged into a final consolidated CSV (`conbine_result.csv`).

This README serves as a comprehensive guide to understanding, running, and modifying the analysis pipeline for your driving condition data.

---