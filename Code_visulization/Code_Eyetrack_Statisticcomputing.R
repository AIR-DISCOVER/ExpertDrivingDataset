# =============================================================================
# 1. Load Required Libraries
# =============================================================================
library(tidyverse)   # Loads dplyr, tidyr, ggplot2, etc.
library(ggpubr)

# =============================================================================
# 2. Read and Filter Data
# =============================================================================
# Read data from "conbi_string1.csv" and filter out rows where ID contains "N08" or "N14".
df1 <- read.csv("conbi_string1.csv") %>%
  filter(!grepl("N08|N14", ID)) %>%  # Remove rows with "N08" or "N14" in the ID field
  mutate(Driver = factor(Driver, levels = c("N", "E")))  # Set Driver as factor with levels "N" and "E"

# =============================================================================
# 3. Transform Data to Long Format
# =============================================================================
# Convert the data from wide to long format for columns X9 to X1.
tmp_df1 <- df1 %>%
  pivot_longer(cols = X9:X1) %>%  # Pivot columns X9 to X1 into key-value pairs
  data.frame() %>%
  mutate(Group = factor(Group, levels = unique(Group)[c(1:2, 7:14, 3:6, 15)]))  # Set custom factor levels for Group

# =============================================================================
# 4. Create Box Plot with Statistical Comparisons
# =============================================================================
# Create a box plot using ggpubr with Wilcoxon test comparisons across Group and Driver.
plot <- ggboxplot(tmp_df1,
                  x = "Group", 
                  y = "value", 
                  color = "Driver",
                  outlier.shape = NA) +
  stat_compare_means(aes(x = Group, y = value, group = Driver),
                     method = "wilcox.test", 
                     label = "p.signif") +
  facet_wrap(~ name, nrow = 3, scales = "free_y") +
  guides(x = guide_axis(angle = 45)) +
  scale_colour_manual(values = c("#FF8230", "#1E78FE")) +
  scale_y_continuous(limits = c(0, 1))

# =============================================================================
# 5. Display the Plot
# =============================================================================
print(plot)