# =============================================================================
# 1. Load the Required Libraries
# =============================================================================
library(dplyr)
library(tidyr)
library(ggpubr)

# =============================================================================
# 2. Read Data and Set "Driver" as a Factor
# =============================================================================
# Read the CSV file and convert the "Driver" column to a factor with levels "Novice" and "Expert".
df1 <- read.csv("conbine_result.csv") %>%
  mutate(Driver = factor(Driver, levels = c("Novice", "Expert")))

# Preview the first few rows of the dataset.
head(df1)

# =============================================================================
# 3. Define a Function to Filter Outliers (3×IQR Rule)
# =============================================================================
filter_outliers <- function(column) {
  # Calculate the first and third quartiles.
  Q1 <- quantile(column, 0.25, na.rm = TRUE)
  Q3 <- quantile(column, 0.75, na.rm = TRUE)
  
  # Compute the Interquartile Range (IQR).
  IQR_value <- Q3 - Q1
  
  # Define lower and upper bounds using the 3×IQR rule.
  lower_bound <- Q1 - 3 * IQR_value
  upper_bound <- Q3 + 3 * IQR_value
  
  # Return values that fall within the calculated bounds.
  column[column >= lower_bound & column <= upper_bound]
}

# =============================================================================
# 4. Apply Outlier Filtering to All Numeric Columns
# =============================================================================
df1_filtered <- df1 %>%
  mutate(across(
    where(is.numeric),
    ~ ifelse(is.na(.), ., filter_outliers(.))
  ))

# =============================================================================
# 5. Convert Data to Long Format
# =============================================================================
# Pivot the data from wide format (columns "acceleration" to "throttle_percentage") into long format.
tmp_df1 <- df1_filtered %>%
  pivot_longer(
    cols = acceleration:throttle_percentage
  ) %>%
  data.frame() %>%
  # Set the "Group" variable as a factor with a custom level order.
  mutate(Group = factor(Group, levels = unique(Group)[c(1:2, 7:14, 3:6, 15)]))

# =============================================================================
# 6. Create Boxplot with Statistical Comparison
# =============================================================================
# Build a boxplot using ggpubr with:
#   - x-axis as "Group"
#   - y-axis as the measured "value"
#   - colored by "Driver"
#   - faceted by the variable "name" (result of pivot_longer)
plot <- ggboxplot(
  tmp_df1,
  x = "Group", y = "value", color = "Driver",
  outlier.shape = NA
) +
  # Add Wilcoxon test to compare groups within each facet.
  stat_compare_means(
    aes(x = Group, y = value, group = Driver),
    method = "wilcox.test", label = "p.signif"
  ) +
  # Create facets by the variable "name" in 2 rows with free y-axis scales.
  facet_wrap(~ name, nrow = 2, scales = "free_y") +
  # Rotate the x-axis labels by 45 degrees for better readability.
  guides(x = guide_axis(angle = 45)) +
  # Manually set the color palette for the "Driver" groups.
  scale_colour_manual(values = c("#FF8230", "#1E78FE"))

# =============================================================================
# 7. Display the Plot
# =============================================================================
print(plot)
