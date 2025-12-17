Below is an English README that explains the workflow and functionality of the provided R code. This script processes EDA (Electrodermal Activity) data along with corresponding timestamp data from Excel files. It performs custom column naming, normalization, interpolation, baseline correction, data reshaping, and ultimately produces a plot with event-based shading, individual EDA traces, and group mean lines.

---

# EDA Data Processing and Visualization Script

This script is designed to automate the analysis of EDA data. It reads raw data from Excel files, performs data cleaning and transformation, and finally visualizes the results with a shaded event timeline overlaid on individual and group mean EDA traces.

---

## Overview of the Workflow

1. **Load Necessary Packages**  
2. **Read EDA and Timestamp Data**  
3. **Set Custom Column Names**  
4. **Define Utility Functions for Normalization and Interpolation**  
5. **Apply Interpolation to EDA Data**  
6. **Reshape Data and Perform Baseline Correction**  
7. **Prepare Event Interval Data for Plot Shading**  
8. **Plot the Data**  

---

## 1. Load Necessary Packages

The script begins by loading the following R packages:

- **readr** and **readxl** for reading CSV and Excel files.
- **ggplot2** for plotting.
- **dplyr** and **tidyr** for data manipulation and reshaping.
- **zoo** for some time-series related functionality (if needed).

```r
library(readr)
library(readxl)
library(ggplot2)
library(dplyr)
library(tidyr)
library(zoo)
```

---

## 2. Read EDA and Timestamp Data

The script reads two Excel files: one containing the EDA data and another containing timestamp data. The data are stored as data frames (`eda_data` and `timestamps`).

```r
# Read the EDA data and timestamp data from Excel files.
eda_data <- read_excel("EDA_sd_reset.xlsx", col_names = TRUE)
timestamps <- read_excel("EDA_tag_reset.xlsx")
```

---

## 3. Set Custom Column Names

A custom function `set_colnames` is defined to assign new column names to the data. The function allows you to include an "Event" column if needed. The function is then applied to the `eda_data` (without an event column) and `timestamps` (with an event column).

```r
set_colnames <- function(data, prefix, include_event = FALSE) {
  if (include_event) {
    colnames(data) <- c("Event", paste0(prefix, 1:10), paste0("novice", 1:10))
  } else {
    colnames(data) <- c(paste0(prefix, 1:10), paste0("novice", 1:10))
  }
  return(data)
}

# Apply the function to both datasets.
eda_data <- set_colnames(eda_data, "exper")
timestamps <- set_colnames(timestamps, "exper", include_event = TRUE)

# Remove rows with NA values from the timestamps data.
timestamps <- na.omit(timestamps)

# Print column names for verification.
print(colnames(eda_data))
print(colnames(timestamps))
```

---

## 4. Define Utility Functions: Normalization and Interpolation

Two helper functions are defined:

- **normalize:** Scales a numeric vector to the range [0, 1].
- **interpolate_data:** For each column (representing a “person”), the function uses timestamp indices to extract data segments, performs linear interpolation (resampling every segment to 100 data points), concatenates the interpolated segments, and then normalizes the result. Finally, all interpolated series are padded to the same length and combined into a data frame with an added Time column.

```r
# Normalization function: scales a numeric vector to [0,1].
normalize <- function(x) {
  return ((x - min(x)) / (max(x) - min(x)))
}

# Interpolation function:
# For each column in the data (each "person"),
# interpolate the values between timestamp indices and then normalize.
interpolate_data <- function(data, timestamps) {
  interpolated_data <- list()
  
  for (person in colnames(data)) {
    if (!person %in% colnames(timestamps)) {
      warning(paste("Column", person, "not found in timestamps"))
      next
    }
    
    person_data <- data[[person]]
    person_interpolated <- numeric()
    
    for (i in 1:(nrow(timestamps) - 1)) {
      start_idx <- as.numeric(timestamps[i, person])
      end_idx <- as.numeric(timestamps[i + 1, person])
      
      # Check if start_idx and end_idx are valid numbers.
      if (!is.na(start_idx) && !is.na(end_idx) && end_idx > start_idx) {
        segment <- person_data[start_idx:end_idx]
        
        # Perform linear interpolation to 100 points within the segment.
        interpolated_segment <- approx(seq_along(segment), segment, n = 100)$y
        person_interpolated <- c(person_interpolated, interpolated_segment)
      }
    }
    
    # Normalize the interpolated data.
    person_interpolated <- normalize(person_interpolated)
    interpolated_data[[person]] <- person_interpolated
  }
  
  # Find the maximum length among all interpolated series.
  max_length <- max(sapply(interpolated_data, length))
  
  # Pad each series to have the same length and convert the list to a data frame.
  interpolated_df <- as.data.frame(lapply(interpolated_data, function(x) {
    length(x) <- max_length
    return(x)
  }))
  
  # Add a Time column.
  interpolated_df$Time <- seq(0, by = 1, length.out = max_length)
  return(interpolated_df)
}
```

---

## 5. Apply Interpolation to the EDA Data

The interpolation function is applied to the `eda_data` using the timestamp information, resulting in a new data frame (`interpolated_data`) that contains the interpolated and normalized data for each person, along with a Time column.

```r
# Apply interpolation function to the EDA data.
interpolated_data <- interpolate_data(eda_data, timestamps)
```

---

## 6. Reshape Data to Long Format & Baseline Correction

### Data Reshaping

- The wide-format interpolated data is reshaped into long format using the `gather` function (from tidyr), with all columns except Time pivoted into key-value pairs.
- A new `Group` variable is added: if the "Person" column starts with "exper", it is labeled "Expert"; otherwise it is labeled "Novice".

### Baseline Correction

- The baseline is defined as the mean EDA value between Time 700 and 800 for each person.
- The baseline mean is computed and then subtracted from the EDA values.
- After the correction, the mean EDA for each Time point is computed by grouping the data by Time and Group.

```r
# Convert the wide-form data to long format. The "Time" column is retained.
data_long <- gather(interpolated_data, key = "Person", value = "EDA", -Time)

# Define group: if the Person column starts with "exper" then "Expert", otherwise "Novice".
data_long <- data_long %>%
  mutate(Group = ifelse(grepl("^exper", Person), "Expert", "Novice"))

# Compute the baseline mean for the time interval [700, 800) for each person.
baseline_mean <- data_long %>%
  filter(Time >= 700 & Time < 800) %>%
  group_by(Person) %>%
  summarize(baseline_mean = mean(EDA, na.rm = TRUE))

# Subtract the baseline mean.
data_long <- data_long %>%
  left_join(baseline_mean, by = "Person") %>%
  mutate(EDA = EDA - baseline_mean) %>%
  select(-baseline_mean)

# Compute the mean EDA for each Time point grouped by Group.
mean_data <- data_long %>%
  group_by(Time, Group) %>%
  summarize(Mean_EDA = mean(EDA, na.rm = TRUE))
```

---

## 7. Prepare Event Interval Data for Shading in the Plot

### Event Data Frame

An `events` data frame is created to define event intervals. Each event interval specifies:
- **xmin and xmax:** The starting and ending Time values.
- **ymin and ymax:** The vertical extent (set to -Inf and Inf to cover the full plot height).
- **event:** A categorical label for each interval (with a specified order).

### Tagging Data with Events

Each Time point in the long-format EDA data is then assigned an event label based on where it falls within the defined intervals.

```r
events <- data.frame(
  xmin  = c(0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000, 2100, 2200, 2300, 2400),
  xmax  = c(100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000, 2100, 2200, 2300, 2400, 2500),
  ymin  = -Inf,
  ymax  = Inf,
  event = factor(c("baseline", "space", "A1", "space1", "A2", "space2", "D1", "S1", "A3", "space3", 
                   "A4", "space4", "L1", "space5", "L2", "space6", "R1", "space7", "R2", "space8", 
                   "R3", "space9", "R4", "space10", "L3"),
                 levels = c("baseline", "space", "A1", "space1", "A2", "space2", "D1", "S1", 
                            "A3", "space3", "A4", "space4", "L1", "space5", "L2", "space6", 
                            "R1", "space7", "R2", "space8", "R3", "space9", "R4", "space10", "L3"))
)

# Tag each Time point with an event label.
data_long <- data_long %>%
  mutate(Event = cut(Time,
                     breaks = c(events$xmin, max(events$xmax)),
                     labels = events$event,
                     include.lowest = TRUE))
```

---

## 8. Plotting the Data

### Plot Elements

The final plot is built using `ggplot2` and includes:
- **Event Shading:** Event intervals are shaded using `geom_rect` with transparency.
- **Individual EDA Traces:** Each person's EDA trace is drawn using `geom_line` with a low alpha value.
- **Group Mean Lines:** The computed mean EDA for each group is overlaid using thicker lines.
- **Custom Axes and Themes:** X-axis ticks are set according to the event intervals, a minimal theme is used, and custom colors are defined for event shading.

```r
p <- ggplot() +
  # Draw event rectangles (shaded regions).
  geom_rect(data = events, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = event), alpha = 0.2) +
  # Plot individual EDA lines.
  geom_line(data = data_long, aes(x = Time, y = EDA, color = Group, group = Person), alpha = 0.2) +
  # Plot mean EDA lines for each group.
  geom_line(data = mean_data, aes(x = Time, y = Mean_EDA, color = Group, group = Group), size = 1.0) +
  scale_x_continuous(breaks = events$xmin, labels = events$event) +
  labs(title = "EDA Comparison", x = "Event", y = "EDA") +
  theme_minimal() +
  # Custom fill colors for event shading.
  scale_fill_manual(values = c("lightblue", "lightgrey", "#458FFE", "lightgrey", "#458FFE",
                               "lightgrey", "#458FFE", "#458FFE", "#458FFE", "lightgrey",
                               "#458FFE", "lightgrey", "#458FFE", "lightgrey", "#458FFE",
                               "lightgrey", "#458FFE", "lightgrey", "#458FFE", "lightgrey",
                               "#458FFE", "lightgrey", "#458FFE", "lightgrey", "#458FFE"))

# Display the plot.
print(p)
```

---

## Running Instructions

1. **Data Files:**  
   - Ensure the Excel files (`EDA_sd_reset.xlsx` and `EDA_tag_reset.xlsx`) are in your working directory.  
   - Check that the data structure is compatible with the custom column naming in the script.

2. **Install Dependencies:**  
   If you have not installed the required packages, execute:
   ```r
   install.packages(c("readr", "readxl", "ggplot2", "dplyr", "tidyr", "zoo"))
   ```

3. **Execution:**  
   Run the script in an R environment (such as RStudio). The script will:
   - Read and rename columns of the EDA and timestamp data.
   - Remove NA rows from the timestamps.
   - Normalize and interpolate the EDA signals.
   - Reshape the data and correct for baseline measures.
   - Prepare event intervals for shading.
   - Generate and display the final EDA comparison plot.

4. **Output:**  
   The final output is a plot that displays:
   - Shaded event intervals.
   - Overlaid individual and mean EDA trajectories.
   - Annotated event labels on the x-axis.

---

## Summary

This script provides an end-to-end solution for processing and visualizing EDA data:

- **Data Preparation:**  
  Reading raw Excel data and applying custom column names.
  
- **Data Transformation:**  
  Normalizing, interpolating, and reshaping the data into long format.
  
- **Baseline Correction:**  
  Removing baseline effects based on a defined time interval.
  
- **Visualization:**  
  Creating a comprehensive plot that integrates event shading, individual traces, and group mean lines.

Use this README as a guide to understand, run, and modify the analysis pipeline to suit your research needs.

---