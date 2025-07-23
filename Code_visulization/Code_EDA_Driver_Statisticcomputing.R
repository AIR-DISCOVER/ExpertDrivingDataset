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
# 1. Read EDA and Timestamp Data
# =============================================================================
# Read the EDA data and timestamp data from Excel files.
eda_data <- read_excel("EDA_sd_reset.xlsx", col_names = TRUE)
timestamps <- read_excel("EDA_tag_reset.xlsx")

# =============================================================================
# 2. Set Column Names with a Custom Function
# =============================================================================
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

# =============================================================================
# 3. Define Utility Functions: Normalization and Interpolation
# =============================================================================
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

# Apply interpolation function to the EDA data.
interpolated_data <- interpolate_data(eda_data, timestamps)

# =============================================================================
# 4. Reshape Data to Long Format & Baseline Correction
# =============================================================================
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

# =============================================================================
# 5. Prepare Event Interval Data for Shading in Plot
# =============================================================================
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

# =============================================================================
# 6. Plotting the Data (without statistical tests and annotations)
# =============================================================================
# Create the plot with event shading, individual EDA traces, and group mean lines.
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

