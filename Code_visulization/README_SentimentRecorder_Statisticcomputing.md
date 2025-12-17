Below is a detailed **Data Processing and Boxplot Analysis README** that explains the workflow and logic of the provided R code. This script reads a CSV file containing statistical results, transforms the data for proper visualization, and creates box plots with statistical t-test comparisons across different groups and driver types.

---

# Data Processing and Boxplot Analysis README

This script is organized into three main sections:

1. **Load Required Libraries**  
2. **Read and Process Data**  
3. **Create a Box Plot with Statistical Comparisons**

Below is a breakdown of each section.

---

## 1. Load Required Libraries

The script loads the following key libraries:

- **tidyverse**: For data manipulation (dplyr, tidyr, stringr) and visualization (ggplot2).  
- **ggpubr**: Provides a convenient function (`ggboxplot()`) to create publication-ready box plots along with functions to add statistical comparisons.

```r
library(tidyverse)   # Loads dplyr, tidyr, stringr, ggplot2, etc.
library(ggpubr)      # For creating the box plots with statistical comparisons
```

---

## 2. Read and Process Data

### 2.1 Reading the Data

- The CSV file `"conbine_result_st.csv"` is read into the data frame `df1`.
- The `head(df1)` function call provides an initial look at the data.

```r
df1 <- read.csv("conbine_result_st.csv")
head(df1)
```

### 2.2 Data Transformation

The following transformations are performed to prepare the data for visualization:

1. **Convert 'Driver' to Factor:**  
   - The `Driver` column is converted into a factor with levels `"Novice"` and `"Expert"`. This ensures that when plotting, the groups will be ordered accordingly.

2. **Pivoting Data:**  
   - The script pivots the data from wide to long format covering the columns from `"emotion_positive"` to `"emotion_neutral"`.  
   - The pivoted data results in two new columns: one (`name`) holding the original column names (which represent the emotion or measurement variable) and a second (`value`) holding the corresponding values.

3. **Custom Group Factor Ordering:**  
   - The `Group` variable is adjusted to a custom order by reassigning factor levels. This is achieved by extracting unique levels and reordering them with the sequence `c(1,6:12,2:5,13)` from the unique group names.

```r
tmp_df1 <- df1 %>%
  mutate(Driver = factor(Driver, levels = c("Novice", "Expert"))) %>%
  pivot_longer(cols = emotion_positive:emotion_neutral) %>%  # Convert wide format to long format
  data.frame() %>%
  mutate(Group = factor(Group, levels = unique(Group)[c(1,6:12,2:5,13)]))  # Custom ordering of Group

# Inspect the transformed data
head(tmp_df1)
```

*Key Points:*
- **Pivoting Data:**  
  Allows multiple measurement variables (emotion values) to be stacked into two columns (`name` and `value`), making it easier to facet plots.
- **Custom Factor Ordering:**  
  Ensures that the groups appear in the desired order in the final plot.

---

## 3. Create a Box Plot with Statistical Comparisons

The final section creates the box plot using `ggboxplot()` from **ggpubr** and adds t-test comparisons.

### 3.1 Plot Construction

- **Box Plot:**  
  A box plot is constructed with the following aesthetics:  
  - **x-axis:** `Group`
  - **y-axis:** `value`
  - **Color:** `Driver` (differentiates between "Novice" and "Expert")
  - Outliers are removed (via `outlier.shape = NA`) to streamline the plot appearance.

- **Statistical Comparisons:**  
  - The `stat_compare_means()` function is used to perform t-tests comparing the groups, with significance labels (e.g., `*`, `**`, `***`) shown directly on the plot.

- **Faceting:**  
  - The plot is faceted by the `name` variable (which corresponds to the measurement variable or emotion), and arranged in two rows (`nrow = 2`).  
  - Scales are set to "free_y" so that each facet can adjust its y-axis independently for optimal clarity.

- **Additional Customizations:**  
  - The x-axis labels are rotated 45 degrees using `guides(x = guide_axis(angle = 45))` for readability.
  - Custom colors are manually set for the `Driver` factor via `scale_colour_manual()`.

```r
p <- ggboxplot(tmp_df1,
               x = "Group", y = "value", color = "Driver",
               outlier.shape = NA) +
  stat_compare_means(aes(x = Group, y = value, group = Driver),
                     method = "t.test", label = "p.signif") +  # Add t-test p-value comparisons
  facet_wrap(~ name, nrow = 2, scales = "free_y") +       # Facet by the measurement variable (name)
  guides(x = guide_axis(angle = 45)) +                    # Rotate x-axis labels for readability
  scale_colour_manual(values = c("#FF8230", "#1E78FE"))    # Manually set colors for the Driver factor

# Display the plot
print(p)
```

*Key Points:*
- **`ggboxplot()`**:  
  A convenient function from ggpubr for creating elegant box plots.
- **`stat_compare_means()`**:  
  Automatically calculates and overlays statistical comparisons (t-test here) onto the plot.
- **Faceting and Axis Customization:**  
  Ensures that each measurement variable is clearly separated and x-axis labels are readable.

---

## Running Instructions

1. **Data Preparation:**  
   - Ensure you have the CSV file `"conbine_result_st.csv"` in your working directory.
   - Verify that the data file contains the relevant columns, particularly `Driver`, `Group`, and the emotion measurement columns ranging from `emotion_positive` to `emotion_neutral`.

2. **Dependencies:**  
   - Make sure the following packages are installed:
     ```r
     install.packages(c("tidyverse", "ggpubr"))
     ```

3. **Execution:**  
   - Copy and paste the complete script into an R script file or R session.
   - Run the script. The data will be processed and the box plot with overlaid t-test results will be displayed.

---

## Summary

This script performs the following steps:

- **Data Import and Transformation:**  
  Reads a CSV file with statistical results, adjusts factor levels for proper ordering, and pivots from wide to long format.
  
- **Visualization:**  
  Constructs a faceted box plot comparing measurements across different groups and driver types, with t-test statistical comparisons annotated on the plot.

This README serves as a guide to understand how the data are processed and visualized. Adjust the factor order and aesthetics as needed to match your specific dataset and analysis goals.

---