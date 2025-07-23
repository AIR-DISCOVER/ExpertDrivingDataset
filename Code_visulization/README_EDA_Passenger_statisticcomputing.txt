Below is an English README that explains the workflow and functionality of the provided R code. This script processes EDA data by reading a CSV file and corresponding timestamp data from an Excel file, applying custom column names, normalizing and interpolating the data, performing baseline correction, reshaping the data for further analysis, and finally generating a plot with event-based shading along with individual and mean EDA traces.

---

# EDA Data Processing and Visualization Script

This script processes Electrodermal Activity (EDA) data using the following steps:

1. **Load Necessary Packages**  
2. **Read EDA Data and Timestamps Data**  
3. **Set Column Names Using a Custom Function**  
4. **Define Normalization and Interpolation Functions**  
5. **Apply Interpolation to the EDA Data**  
6. **Reshape Data (Long Format) and Apply Baseline Correction**  
7. **Prepare Event Intervals Data for Plot Shading**  
8. **Plot the Data: Shaded Event Regions, EDA Lines, and Mean Lines**

Each section is explained in detail below.

---

## 1. Load Necessary Packages

The script begins by loading the required libraries for reading data, data manipulation, time series operations, and plotting.

```r
library(readr)     # For reading CSV files.
library(readxl)    # For reading Excel files.
library(ggplot2)   # For plotting.
library(dplyr)     # For data manipulation.
library(tidyr)     # For reshaping data.
library(zoo)       # For time series-related functions.
```

---

## 2. Read EDA Data and Timestamps Data

The script reads the EDA data from a CSV file (`Conbine_sd_EDA.csv`) and the corresponding timestamps from an Excel file (`Conbine_row_EDA.xlsx`).

```r
eda_data <- read_csv("Conbine_sd_EDA.csv", col_names = TRUE)
timestamps <- read_excel("Conbine_row_EDA.xlsx")
```

---

## 3. Set Column Names Using a Custom Function

A custom function `set_colnames` is defined to assign new column names based on a given prefix. When the `include_event` flag is set to TRUE, an "Event" column is prepended. In this script, 20 columns are designated for the "exper" group and another 20 for the "novice" group.

```r
set_colnames <- function(data, prefix, include_event = FALSE) {
  if (include_event) {
    colnames(data) <- c("Event", paste0(prefix, 1:20), paste0("novice", 1:20))
  } else {
    colnames(data) <- c(paste0(prefix, 1:20), paste0("novice", 1:20))
  }
  return(data)
}

# Apply the function to both datasets.
eda_data <- set_colnames(eda_data, "exper")
timestamps <- set_colnames(timestamps, "exper", include_event = TRUE)

# Remove rows with NA values from the timestamps data.
timestamps <- na.omit(timestamps)

# Check that column names are set correctly.
print(colnames(eda_data))
print(colnames(timestamps))
```

---

## 4. Define Normalization and Interpolation Functions

### Normalization

A simple min–max normalization function is defined to scale any numeric vector to the range [0,1].

```r
normalize <- function(x) {
  return ((x - min(x)) / (max(x) - min(x)))
}
```

### Interpolation

The `interpolate_data` function processes each column (each "person") in the EDA data. For each person, the function:

- Uses consecutive timestamp indices provided in the `timestamps` dataset to split data into segments.
- Uses linear interpolation (via the `approx` function) to resample each segment to 100 data points.
- Concatenates all interpolated segments.
- Normalizes the entire interpolated series.
- Pads each person’s series so all have the same length.
- Adds a `Time` column for plotting.

```r
interpolate_data <- function(data, timestamps) {
  interpolated_data <- list()
  
  # Loop over each person (column) in the data.
  for (person in colnames(data)) {
    if (!person %in% colnames(timestamps)) {
      warning(paste("Column", person, "not found in timestamps"))
      next
    }
    
    person_data <- data[[person]]
    person_interpolated <- numeric()
    
    # Loop through each pair of consecutive timestamp rows.
    for (i in 1:(nrow(timestamps) - 1)) {
      start_idx <- as.numeric(timestamps[i, person])
      end_idx   <- as.numeric(timestamps[i + 1, person])
      
      # Process only if the start and end indices are valid.
      if (!is.na(start_idx) && !is.na(end_idx) && end_idx > start_idx) {
        segment <- person_data[start_idx:end_idx]
        # Perform linear interpolation with 100 points.
        interpolated_segment <- approx(seq_along(segment), segment, n = 100)$y
        person_interpolated <- c(person_interpolated, interpolated_segment)
      }
    }
    
    # Normalize the interpolated data.
    person_interpolated <- normalize(person_interpolated)
    interpolated_data[[person]] <- person_interpolated
  }
  
  # Find the maximum length among all interpolated vectors.
  max_length <- max(sapply(interpolated_data, length))
  
  # Pad each vector to the maximum length and convert the list to a data frame.
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

## 5. Apply the Interpolation Function

The interpolation function is applied to the EDA data using the timestamps. The result is a data frame, `interpolated_data`, containing normalized and interpolated EDA values for each person along with a Time column.

```r
interpolated_data <- interpolate_data(eda_data, timestamps)
```

---

## 6. Reshape Data (Long Format) and Apply Baseline Correction

### Reshape Data

The wide-format `interpolated_data` is transformed into a long format using `gather()` from the tidyr package. This results in:
- **Person:** Indicates the individual (column name).
- **EDA:** The EDA measurement.

A new variable `Group` is then created based on the `Person` identifier. If the `Person` column starts with "exper," it is labeled as "Expert"; otherwise, it is labeled as "Novice."

```r
data_long <- gather(interpolated_data, key = "Person", value = "EDA", -Time)

data_long <- data_long %>%
  mutate(Group = ifelse(grepl("^exper", Person), "Expert", "Novice"))
```

### Baseline Correction

For each person, the baseline mean is calculated using the time interval from 700 to 800. This baseline is then subtracted from each corresponding EDA measurement.

```r
baseline_mean <- data_long %>%
  filter(Time >= 700 & Time < 800) %>%
  group_by(Person) %>%
  summarize(baseline_mean = mean(EDA, na.rm = TRUE))

data_long <- data_long %>%
  left_join(baseline_mean, by = "Person") %>%
  mutate(EDA = EDA - baseline_mean) %>%
  select(-baseline_mean)
```

After correction, the script computes the mean EDA for each Time point grouped by `Group`.

```r
mean_data <- data_long %>%
  group_by(Time, Group) %>%
  summarize(Mean_EDA = mean(EDA, na.rm = TRUE))
```

---

## 7. Prepare Event Intervals Data for Plot Shading

An `events` data frame is created to define time intervals (using `xmin` and `xmax`) that correspond to various events. These intervals are used for shading the background of the plot. Each event is assigned a label (provided as a factor with fixed levels).

```r
events <- data.frame(
  xmin = c(0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100,
           1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000, 2100,
           2200, 2300, 2400),
  xmax = c(100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200,
           1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000, 2100, 2200,
           2300, 2400, 2500),
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

Each `Time` point in the long-format `data_long` is then assigned an event label using the `cut()` function.

```r
data_long <- data_long %>%
  mutate(Event = cut(Time,
                     breaks = c(events$xmin, max(events$xmax)),
                     labels = events$event,
                     include.lowest = TRUE))
```

---

## 8. Plot the Data: Shaded Event Regions, EDA Lines, and Mean Lines

Finally, the script builds a plot using **ggplot2**, with the following features:

- **Shaded Regions:**  
  Event intervals are visualized using `geom_rect()` to create transparent rectangles behind the data.
  
- **Individual EDA Traces:**  
  Each person’s EDA trace is drawn with `geom_line()` using a low alpha so that overlapping patterns can be visualized.
  
- **Group Mean Lines:**  
  Group-level mean EDA values are overlaid with thicker lines.
  
- **Custom Axes and Colors:**  
  The x-axis tick marks are set using event start times and labeled with event names. Custom fill and line colors are applied.

```r
p <- ggplot() +
  # Plot shaded rectangles for each event interval.
  geom_rect(data = events, aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = event), alpha = 0.2) +
  # Plot individual EDA traces (faint lines).
  geom_line(data = data_long, aes(x = Time, y = EDA, color = Group, group = Person), alpha = 0.2) +
  # Plot mean EDA lines for each group.
  geom_line(data = mean_data, aes(x = Time, y = Mean_EDA, color = Group, group = Group), size = 1.0) +
  scale_x_continuous(breaks = events$xmin, labels = events$event) +
  labs(title = "EDA Comparison", x = "Event", y = "EDA") +
  theme_minimal() +
  # Custom fill colors for the event shading.
  scale_fill_manual(values = c("lightblue", "lightgrey", "#458FFE", "lightgrey", "#458FFE", 
                               "lightgrey", "#458FFE", "#458FFE", "#458FFE", "lightgrey", 
                               "#458FFE", "lightgrey", "#458FFE", "lightgrey", "#458FFE", 
                               "lightgrey", "#458FFE", "lightgrey", "#458FFE", "lightgrey", 
                               "#458FFE", "lightgrey", "#458FFE", "lightgrey", "#458FFE")) +
  # Custom colors for the individual and mean EDA lines.
  scale_color_manual(values = c("#1E78FE", "#FF822F"))

# Display the final plot.
print(p)
```

---

## Running Instructions

1. **Data Files:**  
   - Ensure that the CSV file (`Conbine_sd_EDA.csv`) and the Excel file (`Conbine_row_EDA.xlsx`) are present in your working directory.
   - Verify that these files contain the expected columns so that the custom naming function works correctly.

2. **Install Packages:**  
   If you have not already installed the required packages, run:
   ```r
   install.packages(c("readr", "readxl", "ggplot2", "dplyr", "tidyr", "zoo"))
   ```

3. **Execute the Script:**  
   - Open your R environment (e.g., RStudio) and run the script section by section or as a whole.
   - The script will read, process, and interpolate the EDA data; apply baseline correction; and generate a plot with shaded event intervals, individual traces, and group means.

4. **Review the Output:**  
   - The final output will be a composite plot showing the event intervals (as shaded regions), individual EDA traces (faint lines), and overlaid mean EDA lines for the Expert and Novice groups.

---

## Summary

This script provides an end-to-end solution for processing and visualizing EDA data:

- **Data Input and Preprocessing:**  
  Reads EDA and timestamp data while applying consistent column naming.

- **Data Transformation:**  
  Normalizes and interpolates the data based on specified timestamp intervals, reshapes the data into long format, and performs baseline correction.

- **Visualization:**  
  Creates a comprehensive plot combining shaded event intervals with individual EDA traces and group-level summary curves.

Use this README as a guide to understand, run, and modify the script to suit your data analysis and visualization needs.

---