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
# 1. Read EDA Data and Timestamps Data
# =============================================================================
eda_data <- read_csv("Conbine_sd_EDA.csv", col_names = TRUE)
timestamps <- read_excel("Conbine_row_EDA.xlsx")

# =============================================================================
# 2. Set Column Names Using a Custom Function
# =============================================================================
# This function sets the column names based on a given prefix.
# If include_event is TRUE, an "Event" column is prepended.
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

# =============================================================================
# 3. Define Normalization and Interpolation Functions
# =============================================================================
# Normalization function: scales a numeric vector to the [0,1] range.
normalize <- function(x) {
  return ((x - min(x)) / (max(x) - min(x)))
}

# Interpolation function: for each column ("person") in the data,
# the function extracts segments based on consecutive timestamp values,
# linearly interpolates each segment to 100 points, concatenates the results,
# normalizes them, and finally pads each series to a uniform length.
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

# Apply the interpolation function.
interpolated_data <- interpolate_data(eda_data, timestamps)

# =============================================================================
# 4. Reshape Data (Long Format) and Apply Baseline Correction
# =============================================================================
# Convert the interpolated wide-format data to long format.
data_long <- gather(interpolated_data, key = "Person", value = "EDA", -Time)

# Create a Group variable: columns starting with "exper" are labeled as "Expert",
# and others as "Novice".
data_long <- data_long %>%
  mutate(Group = ifelse(grepl("^exper", Person), "Expert", "Novice"))

# Calculate the baseline mean for each person using Time values between 700 and 800.
baseline_mean <- data_long %>%
  filter(Time >= 700 & Time < 800) %>%
  group_by(Person) %>%
  summarize(baseline_mean = mean(EDA, na.rm = TRUE))

# Subtract the baseline mean from each EDA value.
data_long <- data_long %>%
  left_join(baseline_mean, by = "Person") %>%
  mutate(EDA = EDA - baseline_mean) %>%
  select(-baseline_mean)

# Compute the mean EDA at each time point for each group.
mean_data <- data_long %>%
  group_by(Time, Group) %>%
  summarize(Mean_EDA = mean(EDA, na.rm = TRUE))

# =============================================================================
# 5. Prepare Event Intervals Data for Shading in the Plot
# =============================================================================
# Define events with specific start (xmin) and end (xmax) times.
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

# Assign an event label to each Time point using the defined intervals.
data_long <- data_long %>%
  mutate(Event = cut(Time,
                     breaks = c(events$xmin, max(events$xmax)),
                     labels = events$event,
                     include.lowest = TRUE))

# =============================================================================
# 7. Plot the Data: Shaded Event Regions, EDA Lines, and Mean Lines
# =============================================================================
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
  # Set custom colors for shaded event regions.
  scale_fill_manual(values = c("lightblue", "lightgrey", "#458FFE", "lightgrey", "#458FFE", 
                               "lightgrey", "#458FFE", "#458FFE", "#458FFE", "lightgrey", 
                               "#458FFE", "lightgrey", "#458FFE", "lightgrey", "#458FFE", 
                               "lightgrey", "#458FFE", "lightgrey", "#458FFE", "lightgrey", 
                               "#458FFE", "lightgrey", "#458FFE", "lightgrey", "#458FFE")) +
  # Set custom colors for the EDA lines.
  scale_color_manual(values = c("#1E78FE", "#FF822F"))

# Display the final plot.
print(p)