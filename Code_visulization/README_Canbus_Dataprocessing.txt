Below is a detailed **README** that explains the workflow and logic of the provided R code. This script is used for processing event data from a specific folder (in this case, `"13_LeftTurn-3"`), extracting and computing summary statistics from each CSV file, and then combining CSV files from another folder (`"conbine_csv"`) into a single results file. The README is organized into several sections that correspond with the steps in the code.

---

# Event Data Processing and Combination Script

This R script performs the following tasks:

1. **Load Required Libraries:**  
   It loads all necessary packages for data I/O, manipulation, and visualization.

2. **Process Event 1 Data from `13_LeftTurn-3`:**  
   - **File Listing:** Lists all CSV files within the folder `"13_LeftTurn-3"`.  
   - **Identifier Extraction:** Extracts subject identifiers and driver type (Expert vs. Novice) from the file names.  
   - **Data Transformation:** Reads in each CSV file, removes unwanted columns, pivots the data from wide to long format (for variables from `speed_mps` to `jerk.1s`), and then aggregates the data by computing the mean for each variable.  
   - **Appending Identifiers:** The computed statistics are transposed into a data frame, and then additional columns are appended for subject ID, driver type, and group (which is based on the folder name).  
   - **Result Saving:** Each file’s processed statistics are accumulated into one data frame that is finally written to a CSV file. The output file name is generated using the folder name concatenated with `_result.csv`.

3. **Combine CSV Files from the `conbine_csv` Folder:**  
   - **File Listing & Reading:** Lists and reads all CSV files within the `"conbine_csv"` folder.  
   - **Result Combining:** Appends the contents of each CSV file into one large data frame.  
   - **Final Output:** Saves the combined data into a single CSV file named `conbine_result.csv`.

---

## 1. Load the Required Libraries

The script starts by loading the necessary libraries. These libraries include functions for plot creation, data manipulation, file I/O, and string processing.

```r
library(ggpubr)
library(data.table)
library(readxl)
library(tidyverse)  # Loads ggplot2, dplyr, tidyr, etc.
library(dplyr)
library(ggplot2)
```

---

## 2. Process Event 1 Data from "13_LeftTurn-3"

### 2.1 List CSV Files

All CSV files located in the `13_LeftTurn-3` folder are listed and stored in the variable `id1`. The code prints out the first few files to verify they have been correctly identified.

```r
id1 <- list.files('13_LeftTurn-3', full.names = TRUE)
head(id1)
```

### 2.2 Initialize Data Frame

An empty data frame `df_bs` is initialized to store the processed statistics from each file.

```r
df_bs <- data.frame()
```

### 2.3 Process Each File

For every file found in `id1`, the following steps are performed:
- **Extract Identifiers:**  
  - The folder name is extracted to be used as the `Group` identifier.
  - The file name (without extension) is used as the subject ID.
  - The first character of the subject ID is examined to determine if the subject is an expert (`E`) or a novice.
  
- **Read and Transform Data:**  
  - Each CSV file is read.
  - Unwanted columns (columns 1–9, 11, and 16–18) are removed.
  - The remaining data is reshaped from wide to long format with `pivot_longer()` for columns `speed_mps` to `jerk.1s`.
  
- **Calculate Statistics:**  
  - The mean of each variable (grouped by `name`) is computed using the `aggregate()` function.
  - The resulting table is transposed and converted to a data frame.
  - Subject ID, driver type (mapped to "Expert" or "Novice"), and Group (folder name) are added as new columns.
  
- **Append Data:**  
  - The computed statistics for each file are accumulated into the overall data frame `df_bs`.

```r
for(i in id1) {
  
  # -- Extract Identifiers --
  folder_name <- basename(dirname(i))
  tmp_id <- tools::file_path_sans_ext(basename(i))
  tmp_id2 <- str_sub(tmp_id, 1, 1)
  
  # -- Read and Transform Data --
  tmp_df <- read.csv(i) %>%
    select(-c(1:9, 11, 16:18)) %>%
    pivot_longer(cols = speed_mps:jerk.1s)
  
  # -- Calculate Statistics --
  tmp_stat <- aggregate(value ~ name, tmp_df, mean) %>%
    column_to_rownames('name') %>%
    t() %>%
    data.frame() %>%
    mutate(
      ID = tmp_id,
      Driver = ifelse(tmp_id2 == 'E', 'Expert', 'Novice'),
      Group = folder_name  # Use folder name as Group
    )
  
  # Append the temporary statistics to the overall data frame.
  df_bs <- rbind(df_bs, tmp_stat)
}
```

### 2.4 Save Processed Event Data

After processing all files in `"13_LeftTurn-3"`, the resulting data is written to a CSV file. The output filename is constructed by appending `'_result.csv'` to the folder name.

```r
output_file <- paste0(folder_name, '_result.csv')
write.csv(df_bs, output_file, row.names = FALSE)
```

---

## 3. Combine CSV Files from the "conbine_csv" Folder

### 3.1 List and Read CSV Files

The script proceeds to list all CSV files within the `"conbine_csv"` folder. The file names are previewed using `head()`.

```r
id1 <- list.files('conbine_csv', full.names = TRUE)
head(id1)
```

### 3.2 Combine the Data

An empty data frame, `df_bs`, is reinitialized for combining all CSV files from `"conbine_csv"`. Each file is read and appended to the data frame.

```r
df_bs <- data.frame()

for(i in id1) {
  tmp_df <- read.csv(i)
  df_bs <- rbind(df_bs, tmp_df)
}
```

### 3.3 Save the Combined CSV

The combined data is then saved to a single CSV file named `conbine_result.csv`.

```r
write.csv(df_bs, 'conbine_result.csv', row.names = FALSE)
```

---

## Running Instructions

1. **Folder Setup:**  
   - Place the event data CSV files in the `13_LeftTurn-3` folder.  
   - Place the intermediate result CSV files in the `conbine_csv` folder.

2. **Install Required Packages:**  
   Make sure all necessary R packages are installed:
   ```r
   install.packages(c("ggpubr", "data.table", "readxl", "tidyverse"))
   ```

3. **Execute the Script:**  
   Run the script in your R environment (e.g., RStudio).  
   - The script will process the event data files, generate summary statistics, and output the results to a CSV file named according to the folder (e.g., `13_LeftTurn-3_result.csv`).  
   - It will then combine all CSV files from the `"conbine_csv"` folder into a file named `conbine_result.csv`.

4. **Review the Output:**  
   Check the created CSV files in your working directory to ensure the processed and combined results are correct.

---

## Summary

This script provides an automated workflow to:

- **Process Event Data:**  
  Read and transform multiple CSV files from the folder `"13_LeftTurn-3"`, extract key identifiers (subject ID, driver type), compute the mean statistics for selected variables, and save the processed data.

- **Combine CSV Files:**  
  Read, combine, and save CSV files from the `"conbine_csv"` folder into a single consolidated results file.

This README serves as a comprehensive guide to understanding, executing, and potentially modifying the processing pipeline for event data analysis and combination.

---