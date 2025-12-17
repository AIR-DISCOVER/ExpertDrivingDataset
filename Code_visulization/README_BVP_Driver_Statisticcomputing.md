Below is an English README that explains the workflow and functionality of the provided R code for processing HRV data. The script reads HRV (RMSSD) data and timestamp data from Excel files, assigns custom column names, normalizes and interpolates the data based on timestamps, applies baseline correction, reshapes the data into long format, and finally produces a line plot with shaded event intervals.

---

# HRV Data Processing and Visualization Script README

This R script is designed to analyze Heart Rate Variability (HRV) data (using RMSSD as a metric) alongside corresponding timestamp data. The script performs several steps including data reading, column renaming, normalization, interpolation, baseline correction, reshaping, and visualization. Below is a complete explanation of each section in the script.

---

## Overview of the Workflow

1. **Load Necessary Packages**  
2. **Read HRV Data and Timestamp Data from Excel Files**  
3. **Set Column Names Using a Custom Function**  
4. **Define Utility Functions for Normalization and Data Interpolation**  
5. **Apply Interpolation to the HRV Data**  
6. **Reshape Data and Apply Baseline Correction**  
7. **Define Event Intervals for Plot Shading**  
8. **Plotting: Create a Line Plot with Shaded Event Regions**  

---

## 1. Load Necessary Packages

The script begins by loading the required libraries:

- **readr & readxl**: For reading data files (CSV or Excel).
- **ggplot2**: For creating plots.
- **dplyr** and **tidyr**: For data manipulation and reshaping.
- **zoo**: For additional time series functionality.

```r
library(readr)
library(readxl)
library(ggplot2)
library(dplyr)
library(tidyr)
library(zoo)
```

---

## 2. Read HRV Data and Timestamp Data from Excel Files

This section reads the HRV data (from `RMSSD.xlsx`) and the associated timestamp data (from `HRV_tag_reset.xlsx`). Both files should contain the raw measures and tag information for different individuals (or “persons”).

```r
eda_data <- read_excel("RMSSD.xlsx", col_names = TRUE)
timestamps <- read_excel("HRV_tag_reset.xlsx")
```

---

## 3. Set Column Names Using a Custom Function

A custom function `set_colnames` is defined to assign new column names to the datasets. The function uses a provided prefix and, if desired, prepends an "Event" column. This helps standardize the column names so that further processing (e.g., interpolation) can refer to columns by name.

- For the HRV data, the new column names will be in the form: `"exper1"`, `"exper2"`, …, `"exper10"` for expert data, followed by `"novice1"`, ..., `"novice10"`.
- For the timestamp data, when `include_event` is `TRUE`, an "Event" column is added first.

```r
set_colnames <- function(data, prefix, include_event = FALSE) {
  if (include_event) {
    colnames(data) <- c("Event", paste0(prefix, 1:10), paste0("novice", 1:10))
  } else {
    colnames(data) <- c(paste0(prefix, 1:10), paste0("novice", 1:10))
  }
  return(data)
}

# Apply the function to both datasets
eda_data <- set_colnames(eda_data, "exper")
timestamps <- set_colnames(timestamps, "exper", include_event = TRUE)

# Remove any rows with NA values in the timestamps dataset.
timestamps <- na.omit(timestamps)

# Verify that the column names are correctly set.
print(colnames(eda_data))
print(colnames(timestamps))
```

---

## 4. Define Utility Functions: Normalization and Data Interpolation

Two utility functions are defined:

- **normalize**:  
  Scales a numeric vector to the [0, 1] range. This is a simple min-max normalization.
  
  ```r
  normalize <- function(x) {
    return ((x - min(x)) / (max(x) - min(x)))
  }
  ```

- **interpolate_data**:  
  For each column (i.e., each “person”) in the HRV dataset, the function uses consecutive timestamp values (provided in the `timestamps` data) to extract segments of data. Each segment is then interpolated to exactly 1000 points using linear interpolation (via `approx`). The interpolated segments are concatenated, normalized, and then padded (if necessary) so that all series share the same length. Finally, a Time column is appended to the resulting data frame.
  
  ```r
  interpolate_data <- function(data, timestamps) {
    interpolated_data <- list()
    
    for (person in colnames(data)) {
      # Check if this column exists in the timestamps data.
      if (!person %in% colnames(timestamps)) {
        warning(paste("Column", person, "not found in timestamps"))
        next
      }
      
      person_data <- data[[person]]
      person_interpolated <- numeric()
      
      # Loop over each pair of consecutive timestamps.
      for (i in 1:(nrow(timestamps) - 1)) {
        start_idx <- as.numeric(timestamps[i, person])
        end_idx   <- as.numeric(timestamps[i + 1, person])
        
        # Only process valid indices where end_idx > start_idx.
        if (!is.na(start_idx) && !is.na(end_idx) && end_idx > start_idx) {
          segment <- person_data[start_idx:end_idx]
          # Perform linear interpolation to get 1000 points.
          interpolated_segment <- approx(seq_along(segment), segment, n = 1000)$y
          person_interpolated <- c(person_interpolated, interpolated_segment)
        }
      }
      
      # Normalize the interpolated segment.
      person_interpolated <- normalize(person_interpolated)
      interpolated_data[[person]] <- person_interpolated
    }
    
    # Find the maximum length of the interpolated series across all persons.
    max_length <- max(sapply(interpolated_data, length))
    
    # Pad all series to the same length and convert to a data frame.
    interpolated_df <- as.data.frame(lapply(interpolated_data, function(x) {
      length(x) <- max_length  # pad with NA if needed
      return(x)
    }))
    
    # Add a Time column for the x-axis (assuming unit time steps).
    interpolated_df$Time <- seq(0, by = 1, length.out = max_length)
    
    return(interpolated_df)
  }
  ```

---

## 5. Apply Interpolation to the HRV Data

Using the `interpolate_data` function, the HRV data is processed. Each “person’s” HRV measure is interpolated over the segments defined by the corresponding timestamps. The resulting data frame, `interpolated_data`, now contains normalized and interpolated time series data for each person, along with a Time column.

```r
# Apply the interpolation function to the HRV data.
interpolated_data <- interpolate_data(eda_data, timestamps)
```

---

## 6. Reshape Data to Long Format and Apply Baseline Correction

### Reshaping to Long Format

The wide-format data is reshaped into long format using `gather()`. This creates two main columns:
- **Person**: Identifier for each column (i.e., each individual).
- **EDA**: The HRV (or EDA) measurement values.

A new column, `Group`, is assigned based on the Person identifier (if it starts with `"exper"` then it’s labeled "Expert"; otherwise, "Novice").

```r
# Convert the data from wide to long format, keeping the Time column intact.
data_long <- gather(interpolated_data, key = "Person", value = "EDA", -Time)

# Assign Group labels based on the column name prefix.
data_long <- data_long %>%
  mutate(Group = ifelse(grepl("^exper", Person), "Expert", "Novice"))
```

### Baseline Correction

The script calculates the baseline mean for the time interval \[0, 1000) for each person. This baseline is then subtracted from the entire HRV series to correct for initial level differences.

```r
# Calculate the baseline mean for each person using data within [0, 1000).
baseline_mean <- data_long %>%
  filter(Time >= 0 & Time < 1000) %>%
  group_by(Person) %>%
  summarize(baseline_mean = mean(EDA, na.rm = TRUE))

# Subtract the baseline mean from each EDA measurement.
data_long <- data_long %>%
  left_join(baseline_mean, by = "Person") %>%
  mutate(EDA = EDA - baseline_mean) %>%
  select(-baseline_mean)
```

Next, the mean HRV (EDA) is aggregated for each time point within each group.

```r
# Calculate the mean EDA at each time point for each group (Expert and Novice).
mean_data <- data_long %>%
  group_by(Time, Group) %>%
  summarize(Mean_EDA = mean(EDA, na.rm = TRUE))
```

---

## 7. Define Event Intervals for Plot Shading

A data frame called `events` is created to define the event intervals. These intervals specify the start (`xmin`) and end (`xmax`) times for each event. Other columns (`ymin`, `ymax`) are used to span the full vertical range. Each event is given a categorical label (with predefined levels) that is later used both for labeling and for shading.

```r
events <- data.frame(
  xmin = c(0, 1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000,
           10000, 11000, 12000, 13000, 14000, 15000, 16000, 17000, 18000,
           19000, 20000, 21000, 22000, 23000, 24000),
  xmax = c(1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 10000,
           11000, 12000, 13000, 14000, 15000, 16000, 17000, 18000, 19000,
           20000, 21000, 22000, 23000, 24000, 25000),
  ymin = -Inf,
  ymax = Inf,
  event = factor(
    c("baseline", "space", "A1", "space1", "A2", "space2", "D1", "S1",
      "A3", "space3", "A4", "space4", "L1", "space5", "L2", "space6",
      "R1", "space7", "R2", "space8", "R3", "space9", "R4", "space10", "L3"),
    levels = c("baseline", "space", "A1", "space1", "A2", "space2", "D1", "S1",
               "A3", "space3", "A4", "space4", "L1", "space5", "L2", "space6",
               "R1", "space7", "R2", "space8", "R3", "space9", "R4", "space10", "L3")
  )
)
```

Each Time point in the long-format data is tagged with an event label based on the defined intervals using the `cut()` function.

```r
# Assign an event label to each Time point based on the defined intervals.
data_long <- data_long %>%
  mutate(Event = cut(Time,
                     breaks = c(events$xmin, max(events$xmax)),
                     labels = events$event,
                     include.lowest = TRUE))
```

---

## 8. Plotting: Line Plot with Shaded Event Regions

The final section creates a composite plot using **ggplot2**. The plot includes:

- **Shaded Event Regions**: `geom_rect` is used to draw rectangles corresponding to event intervals.
- **Individual HRV Traces**: All interpolated HRV (EDA) traces are plotted as lines with low transparency.
- **Group Mean Lines**: The mean HRV values for the Expert and Novice groups are overlaid using thicker lines.
- **Custom X-axis Labels and Colors**: The x-axis is labeled with event names based on the events data frame, and custom fill and line colors are applied.

```r
p <- ggplot() +
  # Add shaded rectangles for event intervals.
  geom_rect(data = events, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = event), alpha = 0.2) +
  # Plot individual HRV (EDA) traces.
  geom_line(data = data_long, aes(x = Time, y = EDA, color = Group, group = Person), alpha = 0.2) +
  # Plot mean HRV lines for each group.
  geom_line(data = mean_data, aes(x = Time, y = Mean_EDA, color = Group, group = Group), size = 1.0) +
  scale_x_continuous(breaks = events$xmin, labels = events$event) +
  labs(title = "HRV Comparison", x = "Event", y = "EDA") +
  theme_minimal() +
  # Custom fill colors for the event shading.
  scale_fill_manual(values = c("lightblue", "lightgrey", "#458FFE", "lightgrey", "#458FFE",
                               "lightgrey", "#458FFE", "#458FFE", "#458FFE", "lightgrey",
                               "#458FFE", "lightgrey", "#458FFE", "lightgrey", "#458FFE",
                               "lightgrey", "#458FFE", "lightgrey", "#458FFE", "lightgrey",
                               "#458FFE", "lightgrey", "#458FFE", "lightgrey", "#458FFE")) +
  # Custom colors for the line plots.
  scale_color_manual(values = c("#1E78FE", "#FF822F"))
```

Finally, the plot is displayed using the `print()` function.

```r
# Display the final plot.
print(p)
```

---

## Running Instructions

1. **Prepare Your Data Files:**
   - Make sure that the Excel files (`RMSSD.xlsx` and `HRV_tag_reset.xlsx`) are in your working directory.
   - Verify that the structure of your Excel files matches the expected format (i.e., the right number of columns).

2. **Install Required Packages:**
   If you have not yet installed the necessary packages, you can install them using:
   ```r
   install.packages(c("readr", "readxl", "ggplot2", "dplyr", "tidyr", "zoo"))
   ```

3. **Execute the Script:**
   - Run the script in an R environment such as RStudio.
   - The script will read, process, and interpolate the HRV data, perform baseline correction, and finally generate a plot.

4. **Review the Output:**
   - The final composite plot will show individual HRV traces (with transparency), overlaid group mean lines, and shaded event intervals.
   - The x-axis is annotated with event labels for easier interpretation.

---

## Summary

This script provides an end-to-end pipeline for HRV data analysis:

- **Data Input & Column Standardization:**
  - Reads HRV and timestamp data from Excel files.
  - Uses a custom function for consistent column naming.

- **Data Processing:**
  - Interpolates and normalizes HRV signals using consecutive timestamp indices.
  - Reshapes the data into long format.
  - Applies a baseline correction over the initial time period.

- **Visualization:**
  - Defines event intervals for contextual shading.
  - Constructs a line plot that overlays individual HRV traces with group means, incorporating shaded event regions.

This README should serve as a comprehensive guide to understand, run, and modify the script for your HRV analysis projects.

---