# =============================================================================
# 1. Load Required Libraries
# =============================================================================
library(tidyverse)   # Loads dplyr, tidyr, stringr, ggplot2, etc.
library(ggpubr)      # For creating the box plots with statistical comparisons

# =============================================================================
# 2. Read and Process Data
# =============================================================================
# Read the CSV file containing statistical results
df1 <- read.csv("conbine_result_st.csv")
head(df1)

# Transform the data:
# - Convert 'Driver' into a factor with levels 'Novice' and 'Expert'
# - Pivot data from wide to long format for the columns from "emotion_positive" to "emotion_neutral"
# - Adjust the ordering of the 'Group' factor with a custom level sequence.
tmp_df1 <- df1 %>%
  mutate(Driver = factor(Driver, levels = c("Novice", "Expert"))) %>%
  pivot_longer(cols = emotion_positive:emotion_neutral) %>%  # Convert wide format to long format
  data.frame() %>%
  mutate(Group = factor(Group, levels = unique(Group)[c(1,6:12,2:5,13)]))  # Custom ordering of Group

# Inspect the transformed data
head(tmp_df1)

# =============================================================================
# 3. Create a Box Plot with Statistical Comparisons
# =============================================================================
# Create a boxplot comparing measurements across different groups and drivers.
# A t-test is used to compare the groups, with statistically significant differences marked
p <- ggboxplot(tmp_df1,
               x = "Group", y = "value", color = "Driver",
               outlier.shape = NA) +
  stat_compare_means(aes(x = Group, y = value, group = Driver),
                     method = "t.test", label = "p.signif") +  # Add t-test p-value comparisons
  facet_wrap(~ name, nrow = 2, scales = "free_y") +       # Facet by the measurement variable (name)
  guides(x = guide_axis(angle = 45)) +                     # Rotate x-axis labels for readability
  scale_colour_manual(values = c("#FF8230", "#1E78FE"))    # Manually set colors for the Driver factor

# Display the plot
print(p)
