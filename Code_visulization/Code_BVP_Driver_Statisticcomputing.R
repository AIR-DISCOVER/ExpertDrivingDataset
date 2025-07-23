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
# 1. Read HRV Data and Timestamp Data from Excel Files
# =============================================================================
eda_data <- read_excel("RMSSD.xlsx", col_names = TRUE)
timestamps <- read_excel("HRV_tag_reset.xlsx")

# =============================================================================
# 2. Set Column Names Using a Custom Function
# =============================================================================
# This function assigns new column names using the provided prefix.
# If 'include_event' is TRUE, an "Event" column is prepended.
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

# Remove any rows with NA values in the timestamps dataset
timestamps <- na.omit(timestamps)

# Verify that the column names are correctly set
print(colnames(eda_data))
print(colnames(timestamps))

# =============================================================================
# 3. Define Utility Functions: Normalization and Data Interpolation
# =============================================================================
# Normalize a numeric vector to the [0,1] range.
normalize <- function(x) {
  return ((x - min(x)) / (max(x) - min(x)))
}

# Interpolate HRV data based on timestamps.
# For each "person" (i.e., each column), the function uses consecutive timestamp
# indices to extract data segments, interpolates each segment to 1000 points,
# concatenates the interpolated segments, and then normalizes the result.
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
    
    # Loop over each pair of consecutive timestamps
    for (i in 1:(nrow(timestamps) - 1)) {
      start_idx <- as.numeric(timestamps[i, person])
      end_idx   <- as.numeric(timestamps[i + 1, person])
      
      # Only process valid numeric indices where end_idx > start_idx
      if (!is.na(start_idx) && !is.na(end_idx) && end_idx > start_idx) {
        segment <- person_data[start_idx:end_idx]
        # Perform linear interpolation to get 1000 points
        interpolated_segment <- approx(seq_along(segment), segment, n = 1000)$y
        person_interpolated <- c(person_interpolated, interpolated_segment)
      }
    }
    
    # Normalize the interpolated segment
    person_interpolated <- normalize(person_interpolated)
    interpolated_data[[person]] <- person_interpolated
  }
  
  # Find the maximum length of the interpolated series across all persons
  max_length <- max(sapply(interpolated_data, length))
  
  # Pad all series to the same length and convert to a data frame
  interpolated_df <- as.data.frame(lapply(interpolated_data, function(x) {
    length(x) <- max_length  # pad with NA if needed
    return(x)
  }))
  
  # Add a Time column for the x-axis (assuming unit time steps)
  interpolated_df$Time <- seq(0, by = 1, length.out = max_length)
  
  return(interpolated_df)
}

# Apply the interpolation function to the HRV data
interpolated_data <- interpolate_data(eda_data, timestamps)

# =============================================================================
# 4. Reshape Data to Long Format and Apply Baseline Correction
# =============================================================================
# Convert the data from wide to long format, keeping the Time column intact.
data_long <- gather(interpolated_data, key = "Person", value = "EDA", -Time)

# Assign Group labels based on the column name prefix.
data_long <- data_long %>%
  mutate(Group = ifelse(grepl("^exper", Person), "Expert", "Novice"))

# Calculate the baseline mean EDA for each person using data within [0, 1000)
baseline_mean <- data_long %>%
  filter(Time >= 0 & Time < 1000) %>%
  group_by(Person) %>%
  summarize(baseline_mean = mean(EDA, na.rm = TRUE))

# Subtract the baseline mean from each EDA measurement
data_long <- data_long %>%
  left_join(baseline_mean, by = "Person") %>%
  mutate(EDA = EDA - baseline_mean) %>%
  select(-baseline_mean)

# Calculate the mean EDA at each time point for each group (Expert and Novice)
mean_data <- data_long %>%
  group_by(Time, Group) %>%
  summarize(Mean_EDA = mean(EDA, na.rm = TRUE))

# =============================================================================
# 5. Define Event Intervals for Plot Shading
# =============================================================================
# Create a data frame defining start and end times for each event interval.
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

# Assign an event label to each Time point based on the defined intervals.
data_long <- data_long %>%
  mutate(Event = cut(Time,
                     breaks = c(events$xmin, max(events$xmax)),
                     labels = events$event,
                     include.lowest = TRUE))

# =============================================================================
# 6. Plotting: Line Plot with Shaded Event Regions
# =============================================================================
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

# Display the final plot.
print(p)

