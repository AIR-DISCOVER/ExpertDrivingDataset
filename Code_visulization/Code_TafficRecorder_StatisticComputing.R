# =============================================================================
# Load Necessary Packages
# =============================================================================
library(readr)
library(ggplot2)
library(dplyr)
library(tidyr)

# =============================================================================
# 1. Read the Combined Analysis Data
# =============================================================================
# Read the CSV file containing the combined results.
analysis_data <- read.csv('conbine_result.csv')
# Preview the first few rows of the dataset.
head(analysis_data)

# =============================================================================
# 2. Prepare Data for Visualization
# =============================================================================
# Transform the data for visualization:
# - Convert 'Driver' into a factor with 'Novice' and 'Expert' levels.
# - Reshape the data from wide to long format for columns bicycle through truck.
# - Order the categories in the 'name' variable.
# - Remove any missing values.
plot_data <- analysis_data %>%
  mutate(Driver = factor(Driver, levels = c('Novice', 'Expert'))) %>%
  pivot_longer(cols = bicycle:truck) %>%
  mutate(name = factor(name, levels = c('traffic', 'stop', 'car', 'bus', 'truck', 
                                        'bicycle', 'motorcycle', 'person'))) %>%
  na.omit() %>%
  data.frame()

# Verify the transformed data.
head(plot_data)

# =============================================================================
# 3. Create Stacked Bar Plot
# =============================================================================
# Create a 100% stacked bar plot to compare proportions for different categories
# across Driver groups, faceted by the Group variable.
ggplot(plot_data, aes(x = Driver, y = value, fill = name)) +
  geom_bar(stat = 'identity', position = 'fill') +
  facet_wrap(~ Group, nrow = 1) +
  labs(title = "Stacked Bar Plot by Driver and Group",
       x = "Driver",
       y = "Proportion",
       fill = "Category") +
  theme_minimal()
