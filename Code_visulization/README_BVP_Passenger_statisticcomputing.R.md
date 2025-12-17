Below is an English README in Markdown format that explains the workflow and functionality of the provided R code for processing HRV data using RMSSD measurements.

---

# RMSSD Data Analysis and Visualization Script README

This script processes Heart Rate Variability (HRV) data based on RMSSD values. It reads the RMSSD data and corresponding timestamp data from Excel files, renames columns with a custom function, normalizes and interpolates the data by segmenting it according to timestamp intervals, applies baseline correction, and finally plots the results with event-based background shading.

The script uses several R packages to handle data manipulation, interpolation, and visualization.

---

## Overview of the Workflow

1. **Load Necessary Packages**  
2. **Read RMSSD and Timestamps Data**  
3. **Set Column Names Using a Custom Function**  
4. **Define Utility Functions: Normalization and Interpolation**  
5. **Apply the Interpolation Function**  
6. **Reshape Data and Apply Baseline Correction**  
7. **Prepare Event Intervals for Shading**  
8. **Plot the Data with Shaded Event Regions and RMSSD Lines**  

---

## Detailed Explanation

### 1. Load Necessary Packages

The script starts by loading the essential R libraries:

- **readr** and **readxl**: For reading CSV and Excel files, respectively.
- **ggplot2**: For creating the final plot.
- **dplyr** and **tidyr**: For data manipulation and reshaping.
- **zoo**: For additional support with time series operations (if applicable).

```r
library(readr)
library(readxl)
library(ggplot2)
library(dplyr)
library(tidyr)
library(zoo)
```

### 2. Read RMSSD Data and Timestamps Data

The RMSSD values are read from an Excel file (`RMSSD_1115.xlsx`), while the timestamps are read from another Excel file (`HRV_tag_reset.xlsx`).  
The timestamps will later be used to segment and interpolate the RMSSD data.

```r
RMSSD_data <- read_excel("RMSSD_1115.xlsx", col_names = TRUE)
timestamps   <- read_excel("HRV_tag_reset.xlsx")
```

### 3. Set Column Names Using a Custom Function

A custom function `set_colnames` is defined to standardize column names. The function:
- Renames columns based on a given prefix.
- Optionally prepends an "Event" column if `include_event` is set to TRUE.

In this script, RMSSD data is assigned column names with prefix `"exper"` for the first 19 columns and `"novice"` for the following 20 columns. The timestamps data is similarly renamed, with the "Event" column added.

```r
set_colnames <- function(data, prefix, include_event = FALSE) {
  if (include_event) {
    colnames(data) <- c("Event", paste0(prefix, 1:19), paste0("novice", 1:20))
  } else {
    colnames(data) <- c(paste0(prefix, 1:19), paste0("novice", 1:20))
  }
  return(data)
}

# Apply the function to both data sets.
RMSSD_data <- set_colnames(RMSSD_data, "exper")
timestamps   <- set_colnames(timestamps, "exper", include_event = TRUE)

# Remove rows with NA values from the timestamps data.
timestamps <- na.omit(timestamps)

# Check that the column names have been set correctly.
print(colnames(RMSSD_data))
print(colnames(timestamps))
```

### 4. Define Utility Functions: Normalization and Interpolation

#### Normalization

The `normalize` function scales a numeric vector to the [0,1] range using min–max normalization.

```r
normalize <- function(x) {
  return((x - min(x)) / (max(x) - min(x)))
}
```

#### Interpolation

The `interpolate_data` function processes each column (representing a “person”) in the RMSSD data. For each person, it performs the following:
- Uses consecutive timestamp indices to extract segments from the data.
- Applies linear interpolation (via R’s `approx` function) to each segment with 1000 points.
- Concatenates the interpolated segments.
- Normalizes the resulting vector.
- Pads each vector to a uniform length.
- Appends a `Time` column to facilitate plotting.

```r
interpolate_data <- function(data, timestamps) {
  interpolated_data <- list()
  
  for (person in colnames(data)) {
    # Check if the "person" column exists in the timestamps data.
    if (!person %in% colnames(timestamps)) {
      warning(paste("Column", person, "not found in timestamps"))
      next
    }
    
    person_data <- data[[person]]
    person_interpolated <- numeric()
    
    # Interpolate between successive timestamp indices.
    for (i in 1:(nrow(timestamps) - 1)) {
      start_idx <- as.numeric(timestamps[i, person])
      end_idx   <- as.numeric(timestamps[i + 1, person])
      
      # Only process if indices are valid and end_idx is greater than start_idx.
      if (!is.na(start_idx) && !is.na(end_idx) && end_idx > start_idx) {
        segment <- person_data[start_idx:end_idx]
        # Perform linear interpolation with 1000 points.
        interpolated_segment <- approx(seq_along(segment), segment, n = 1000)$y
        person_interpolated <- c(person_interpolated, interpolated_segment)
      }
    }
    
    # Normalize the interpolated data.
    person_interpolated <- normalize(person_interpolated)
    interpolated_data[[person]] <- person_interpolated
  }
  
  # Find the maximum length among all interpolated series.
  max_length <- max(sapply(interpolated_data, length))
  
  # Pad each series with NA (if necessary) and convert to a data frame.
  interpolated_df <- as.data.frame(lapply(interpolated_data, function(x) {
    length(x) <- max_length
    return(x)
  }))
  
  # Add a Time column based on sequence of length max_length.
  interpolated_df$Time <- seq(0, by = 1, length.out = max_length)
  return(interpolated_df)
}
```

### 5. Apply the Interpolation Function

The RMSSD data is then processed using the `interpolate_data` function alongside the timestamps. The resulting data frame, `interpolated_data`, contains interpolated and normalized RMSSD time series for each person, along with a Time column.

```r
interpolated_data <- interpolate_data(RMSSD_data, timestamps)
```

### 6. Reshape Data and Apply Baseline Correction

#### Reshape Data

Using the `gather()` function (from _tidyr_), the wide-format interpolated data is reshaped into long format. This step produces:
- **Person:** Identity of the measurement source.
- **RMSSD:** The RMSSD measurement.
- **Time:** The time sequence.

Additionally, the script creates a new variable `Group` based on whether the `Person` identifier starts with `"exper"` (labeled "Expert") or not (labeled "Novice").

```r
data_long <- gather(interpolated_data, key = "Person", value = "RMSSD", -Time)

data_long <- data_long %>%
  mutate(Group = ifelse(grepl("^exper", Person), "Expert", "Novice"))
```

#### Baseline Correction

A baseline is computed for each person over the time interval \[0, 1000). That baseline value is then subtracted from each RMSSD measurement to remove initial offset effects.

```r
baseline_mean <- data_long %>%
  filter(Time >= 0 & Time < 1000) %>%
  group_by(Person) %>%
  summarize(baseline_mean = mean(RMSSD, na.rm = TRUE))

data_long <- data_long %>%
  left_join(baseline_mean, by = "Person") %>%
  mutate(RMSSD = RMSSD - baseline_mean) %>%
  select(-baseline_mean)
```

After baseline correction, the code aggregates the mean RMSSD for each time point and group.

```r
mean_data <- data_long %>%
  group_by(Time, Group) %>%
  summarize(Mean_RMSSD = mean(RMSSD, na.rm = TRUE))
```

### 7. Prepare Event Intervals for Shaded Regions in the Plot

The `events` data frame specifies intervals defined by `xmin` and `xmax` representing different event segments (e.g., baseline, spaces, task phases). Each event is given a factor label to control the order and the corresponding shading colors.

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
    c("baseline", "space", "A1", "space1", "A2", "space2", "D1", "S1", "A3", 
      "space3", "A4", "space4", "L1", "space5", "L2", "space6", "R1", "space7", 
      "R2", "space8", "R3", "space9", "R4", "space10", "L3"),
    levels = c("baseline", "space", "A1", "space1", "A2", "space2", "D1", "S1", 
               "A3", "space3", "A4", "space4", "L1", "space5", "L2", "space6", 
               "R1", "space7", "R2", "space8", "R3", "space9", "R4", "space10", "L3")
  )
)
```

Each time point in the reshaped data is then assigned an event label using `cut()`, which categorizes the `Time` values into the defined intervals.

```r
data_long <- data_long %>%
  mutate(Event = cut(Time, breaks = c(events$xmin, max(events$xmax)),
                     labels = events$event, include.lowest = TRUE))
```

### 8. Plot the Data with Shaded Events and RMSSD Lines

The final plot is built using **ggplot2** and includes:

- **Shaded Rectangles:**  
  `geom_rect()` draws translucent rectangles to indicate event intervals.
  
- **Individual RMSSD Traces:**  
  `geom_line()` displays each person’s RMSSD trace in a faint color.
  
- **Mean RMSSD Lines:**  
  Group-level mean RMSSD is plotted using thicker lines.
  
- **Custom X-axis Labels and Colors:**  
  The x-axis is set using event start times and labeled with event names; manual color scales are applied for fill and line colors.

```r
p <- ggplot() +
  # Draw shaded rectangles for each event interval.
  geom_rect(data = events, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = event), alpha = 0.2) +
  # Plot individual RMSSD traces (faint lines for each Person).
  geom_line(data = data_long, aes(x = Time, y = RMSSD, color = Group, group = Person), alpha = 0.2) +
  # Plot the mean RMSSD for each group.
  geom_line(data = mean_data, aes(x = Time, y = Mean_RMSSD, color = Group, group = Group), size = 1.0) +
  # Set x-axis breaks and labels using events.
  scale_x_continuous(breaks = events$xmin, labels = events$event) +
  labs(title = "HRV Comparison", x = "Event", y = "RMSSD") +
  theme_minimal() +
  # Custom fill colors for event shading.
  scale_fill_manual(values = c("lightblue", "lightgrey", "#458FFE", "lightgrey", "#458FFE", 
                               "lightgrey", "#458FFE", "#458FFE", "#458FFE", "lightgrey", 
                               "#458FFE", "lightgrey", "#458FFE", "lightgrey", "#458FFE", 
                               "lightgrey", "#458FFE", "lightgrey", "#458FFE", "lightgrey", 
                               "#458FFE", "lightgrey", "#458FFE", "lightgrey", "#458FFE")) +
  # Custom colors for the individual and mean RMSSD lines.
  scale_color_manual(values = c("#1E78FE", "#FF822F"))

# Display the final plot.
print(p)
```

---

## Running Instructions

1. **Prepare the Data Files:**  
   - Ensure that `RMSSD_1115.xlsx` and `HRV_tag_reset.xlsx` are in your working directory.
   - Verify that the data files follow the expected column structure so that the custom naming function works correctly.

2. **Install Required Packages:**  
   If not already installed, install the necessary R packages by running:
   ```r
   install.packages(c("readr", "readxl", "ggplot2", "dplyr", "tidyr", "zoo"))
   ```

3. **Execute the Script:**  
   - Open the script in your R environment (e.g., RStudio) and run it section by section or as one complete script.
   - The code will read, process, and interpolate the RMSSD data, apply baseline correction, and finally generate the composite plot.

4. **Review the Output:**  
   - The resulting plot will display shaded event intervals (based on defined time ranges), individual RMSSD traces (with low opacity), and overlaid mean RMSSD lines for the Expert and Novice groups.

---

## Summary

This script provides an end-to-end workflow for RMSSD-based HRV analysis:

- **Data Input & Preprocessing:**  
  Read RMSSD and timestamp data from Excel files and standardize column names.

- **Data Transformation:**  
  Normalize and interpolate RMSSD values based on consecutive timestamp intervals; reshape the data and apply baseline correction.

- **Visualization:**  
  Create a detailed plot that overlays individual HRV traces with group means and annotated event regions for contextual analysis.

Use this README as a guide to understand, run, and adapt the script for your HRV data analysis projects.

---