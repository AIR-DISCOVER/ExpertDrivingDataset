Below is a detailed README that explains the functionality and logic behind the provided code. The script is divided into two main parts:

1. **Processing Event Data from the "drivingcondition" Folder**  
2. **Combining CSV Files from the "conbine_csv" Folder**

Each section is explained in detail below.

---

# Event Data and CSV Combination Processing README

This script processes event-related CSV files, computes summary statistics for each subject, and then combines data across multiple CSV files into a single output. It is organized into several sections:

- **Section 1:** Load required libraries.  
- **Section 2:** Process event data from files located in the "drivingcondition" folder.  
- **Section 3:** Write the processed event data to CSV.  
- **Section 4:** Combine CSV files from the "conbine_csv" folder into one CSV file.

## Section 1: Load Required Libraries

The script loads several libraries that help with reading Excel files, data manipulation, plotting, and handling data tables. Some libraries (like those in the tidyverse) load common packages such as ggplot2, dplyr, tidyr, and stringr.

```r
library(ggpubr)
library(data.table)
library(readxl)
library(tidyverse)   # Loads ggplot2, dplyr, tidyr, stringr, etc.
library(dplyr)
library(ggplot2)
```

*Key Points:*
- **`ggpubr`**: Used for publication-ready plots.
- **`data.table`**: Useful for fast data manipulation.
- **`readxl`**: For reading Excel files (even though not used in this section, it is loaded for consistency).
- **`tidyverse`**: Loads a series of packages for data manipulation and visualization.

---

## Section 2: Process Event Data from "drivingcondition"

In this section, a series of CSV files containing event data are processed.

### 2.1 List and Identify Files

- **List Files:**  
  The code lists all CSV files in the folder `drivingcondition` with their full paths.

  ```r
  id1 <- list.files('drivingcondition', full.names = TRUE)
  head(id1)
  ```

### 2.2 Initialize an Empty Data Frame

An empty data frame `df_bs` is created to hold the processed statistics from each CSV file.

```r
df_bs <- data.frame()
```

### 2.3 Loop Through Each CSV File

For every CSV file in `drivingcondition`:

1. **Extract Identifiers:**
   - **Folder Name:**  
     Retrieves the folder name where the CSV file is located. This is later used as the “Group” variable.
   - **Subject ID:**  
     Extracts the file name (without extension) to serve as a unique subject identifier.
   - **Driver Type:**  
     The first character of the subject ID is checked; if it is `"E"`, the driver is labeled as `"Expert"`, otherwise as `"Novice"`.

2. **Read and Transform Data:**
   - **CSV Read:**  
     Uses `read.csv()` to read the file.
   - **Column Selection:**  
     Unwanted columns (columns 1–3, column 11, and columns 19–25) are removed using `select(-c(1:3, 11, 19:25))`.
   - **Reshape Data:**  
     The remaining columns—from `"Emotion.value_angry"` to `"emotion_ratios_neutral"`—are reshaped from wide to long format using `pivot_longer()`. This converts the data so that each measurement variable becomes a `name` and its value becomes `value`.

3. **Calculate Statistics:**
   - **Aggregation:**  
     The code then aggregates the data by taking the mean of `value` grouped by the variable name.
   - **Transpose and Format:**  
     The aggregated summary is transposed, converted into a data frame, and then annotated with the subject ID, driver type, and group (folder name).
   - **Append Results:**  
     The processed statistics for the current file are appended (row-wise) to the overall data frame `df_bs`.

```r
for(i in id1) {
  
  # -- Extract Identifiers --
  folder_name <- basename(dirname(i))
  tmp_id <- tools::file_path_sans_ext(basename(i))
  tmp_id2 <- str_sub(tmp_id, 1, 1)
  
  # -- Read and Transform Data --
  tmp_df <- read.csv(i) %>%
    select(-c(1:3, 11, 19:25)) %>%
    pivot_longer(cols = Emotion.value_angry:emotion_ratios_neutral)
  
  # -- Calculate Statistics --
  tmp_stat <- aggregate(value ~ name, tmp_df, mean) %>%
    column_to_rownames('name') %>%  # Set "name" as rownames.
    t() %>%                       # Transpose the data.
    data.frame() %>%
    mutate(
      ID = tmp_id,
      Driver = ifelse(tmp_id2 == 'E', 'Expert', 'Novice'),
      Group = folder_name      # Use folder name for group information.
    )
  
  df_bs <- rbind(df_bs, tmp_stat)
}
```

*Key Points:*
- **`tools::file_path_sans_ext()`**: Extracts file name without extension.
- **`str_sub()`**: Helps determine the driver type based on the first character.
- **`pivot_longer()`**: Converts data from wide to long format.
- **`aggregate()`**: Calculates mean values for each variable.
- **`rbind()`**: Combines each processed file’s data into one large data frame.

---

## Section 3: Write Processed Data to CSV

After processing all files in the "drivingcondition" folder, the combined statistical data is written to a CSV file. The output file name includes the folder name with the suffix `_result.csv`.

```r
output_file <- paste0(folder_name, '_result.csv')
write.csv(df_bs, output_file, row.names = FALSE)
```

---

## Section 4: Combine CSV Files from the "conbine_csv" Folder

This section merges data from several CSV files located in the `conbine_csv` folder.

### 4.1 List CSV Files in Folder

- **List Files:**  
  Get a list of all CSV files (with full paths) in `conbine_csv`.

```r
id1 <- list.files('conbine_csv', full.names = TRUE)
head(id1)
```

### 4.2 Initialize and Build Combined Data

- **Initialize Data Frame:**  
  An empty data frame `df_bs` is created to store merged data.
  
- **Loop and Append:**  
  Each CSV file is read, and its data is appended (row-wise) to `df_bs`.

```r
df_bs <- data.frame()

for(i in id1) {
  tmp_df <- read.csv(i)
  df_bs <- rbind(df_bs, tmp_df)
}
```

### 4.3 Write Combined Data to CSV

The combined data is saved to a CSV file named `conbine_result.csv`.

```r
write.csv(df_bs, 'conbine_result.csv', row.names = FALSE)
```

---

## Running Instructions

1. **Data Preparation:**  
   - Ensure the directories `drivingcondition` and `conbine_csv` exist in your working directory, and that they contain the appropriate CSV files.
   - Verify that the CSV files have the expected structure (i.e., the columns to be removed and the columns to pivot for analysis).

2. **Install Dependencies:**  
   Make sure the required packages are installed. You can install missing packages using:
   ```r
   install.packages(c("ggpubr", "data.table", "readxl", "tidyverse", "dplyr", "ggplot2"))
   ```

3. **Execute the Script:**  
   Run the entire script in your preferred R environment. The script:
   - Processes event data from each CSV file in `drivingcondition`.
   - Computes summary statistics and writes the processed output.
   - Merges CSV files from the `conbine_csv` folder and writes the results to a combined CSV file.

4. **Review the Output:**  
   - The file `{folder_name}_result.csv` contains the processed statistics for each subject from the event data.
   - The file `conbine_result.csv` contains the combined data from all CSV files in the `conbine_csv` folder.

---

## Summary

This script provides an automated workflow using R to:
- **Process and Aggregate Event Data:**  
  It loops through CSV files, extracts identifiers, reshapes data from wide to long format, calculates mean values per event variable, and assigns group labels, resulting in a summary data frame.
- **Combine Data Files:**  
  It reads multiple CSV files from a designated folder and appends them into one combined CSV file.
- **Output:**  
  Two CSV files are generated: one with per-subject event statistics and another with the combined data from additional CSV files.

This README should serve as a guide to understanding, executing, and potentially modifying the script for further analyses.

---