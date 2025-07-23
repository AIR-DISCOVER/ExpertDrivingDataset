# =============================================================================
# Load Necessary Packages
# =============================================================================
library(readr)
library(readxl)
library(ggplot2)
library(dplyr)
library(tidyr)
library(zoo)

# =============================================================================
# 1. Read RMSSD Data and Timestamps Data
# =============================================================================
RMSSD_data <- read_excel("RMSSD_1115.xlsx", col_names = TRUE)
timestamps   <- read_excel("HRV_tag_reset.xlsx")

# =============================================================================
# 2. Set Column Names Using a Custom Function
# =============================================================================
# This function renames the columns based on a given prefix.
# If include_event is TRUE, an "Event" column is prepended.
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

# =============================================================================
# 3. Define Utility Functions: Normalization and Interpolation
# =============================================================================
# Normalization function: scales a numeric vector to the [0, 1] range.
normalize <- function(x) {
  return((x - min(x)) / (max(x) - min(x)))
}

# Interpolation function:
# For each column (person) in the RMSSD data, we use consecutive timestamps 
# to extract segments, perform linear interpolation to 1000 points per segment,
# concatenate them, normalize, and pad to a uniform length.
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

# Apply the interpolation function.
interpolated_data <- interpolate_data(RMSSD_data, timestamps)

# =============================================================================
# 4. Reshape Data and Apply Baseline Correction
# =============================================================================
# Convert wide-format data into long format while keeping the Time column.
data_long <- gather(interpolated_data, key = "Person", value = "RMSSD", -Time)

# Create a Group variable: "Expert" if column name starts with "exper"; otherwise "Novice".
data_long <- data_long %>%
  mutate(Group = ifelse(grepl("^exper", Person), "Expert", "Novice"))

# Compute the baseline mean for each person in the interval [0, 1000).
baseline_mean <- data_long %>%
  filter(Time >= 0 & Time < 1000) %>%
  group_by(Person) %>%
  summarize(baseline_mean = mean(RMSSD, na.rm = TRUE))

# Subtract the baseline from each RMSSD measurement.
data_long <- data_long %>%
  left_join(baseline_mean, by = "Person") %>%
  mutate(RMSSD = RMSSD - baseline_mean) %>%
  select(-baseline_mean)

# Calculate the mean RMSSD for each time point and group.
mean_data <- data_long %>%
  group_by(Time, Group) %>%
  summarize(Mean_RMSSD = mean(RMSSD, na.rm = TRUE))

# =============================================================================
# 5. Prepare Event Intervals for Shaded Regions in the Plot
# =============================================================================
# Define event intervals with specified start (xmin) and end (xmax) times.
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

# Classify each Time point into an event using the defined intervals.
data_long <- data_long %>%
  mutate(Event = cut(Time, breaks = c(events$xmin, max(events$xmax)),
                     labels = events$event, include.lowest = TRUE))

# =============================================================================
# 6. Plot the Data with Shaded Events and RMSSD Lines
# =============================================================================
p <- ggplot() +
  # Draw shaded rectangles corresponding to each event interval.
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
  # Custom line colors.
  scale_color_manual(values = c("#1E78FE", "#FF822F"))

# Display the final plot.
print(p)

