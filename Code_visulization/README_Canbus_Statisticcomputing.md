Below is a detailed **README** for the provided R code. This script reads a combined CSV file, filters outliers based on a 3×IQR rule on all numeric columns, reshapes the data to a long format, and then creates a boxplot with statistical comparisons (using Wilcoxon tests) facetting the plot by measurement variable.

---

# Boxplot with Statistical Comparison for Combined Analysis Data

This script processes combined data by performing the following steps:

1. **Load Required Libraries**  
2. **Read Data and Set "Driver" as a Factor**  
3. **Define an Outlier Filtering Function**  
4. **Apply Outlier Filtering to Numeric Columns**  
5. **Convert Data to Long Format**  
6. **Create a Boxplot with Statistical Comparison**  
7. **Display the Plot**

---

## 1. Load the Required Libraries

The script uses several packages for data manipulation, reshaping, and plotting:

- **dplyr**: For data manipulation.
- **tidyr**: For reshaping data.
- **ggpubr**: For creating publication-quality plots and adding statistical comparisons.

```r
library(dplyr)
library(tidyr)
library(ggpubr)
```

---

## 2. Read Data and Set "Driver" as a Factor

The script reads the combined results from `conbine_result.csv` and converts the `Driver` column to a factor with levels "Novice" and "Expert". This ensures consistent ordering when plotting.

```r
df1 <- read.csv("conbine_result.csv") %>%
  mutate(Driver = factor(Driver, levels = c("Novice", "Expert")))

head(df1)
```

---

## 3. Define a Function to Filter Outliers (3×IQR Rule)

The function `filter_outliers` calculates the first (Q1) and third (Q3) quartiles and computes the Interquartile Range (IQR). It then filters out values that fall outside the range \[Q1 - 3×IQR, Q3 + 3×IQR\].

```r
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
```

---

## 4. Apply Outlier Filtering to All Numeric Columns

Using `mutate(across(...))`, the script processes every numeric column in the dataset to filter out extreme outliers. If a value is `NA`, it is left unchanged.

```r
df1_filtered <- df1 %>%
  mutate(across(
    where(is.numeric),
    ~ ifelse(is.na(.), ., filter_outliers(.))
  ))
```

---

## 5. Convert Data to Long Format

The data is originally in wide format (with measurement columns from `acceleration` to `throttle_percentage`).  
By using `pivot_longer()`, the script converts the data to long format, creating two key columns:
- `name`: The measurement variable.
- `value`: The corresponding measurement value.

Additionally, the `Group` variable is converted to a factor with a custom order determined by the specific arrangement of its unique values.

```r
tmp_df1 <- df1_filtered %>%
  pivot_longer(
    cols = acceleration:throttle_percentage
  ) %>%
  data.frame() %>%
  # Set the "Group" variable as a factor with a custom level order.
  mutate(Group = factor(Group, levels = unique(Group)[c(1:2, 7:14, 3:6, 15)]))
```

---

## 6. Create a Boxplot with Statistical Comparison

Using **ggpubr**, the script builds a boxplot with the following features:

- **X-axis**: Represents `Group`.
- **Y-axis**: Represents the measurement `value`.
- **Color**: Distinguishes between "Driver" groups ("Novice" and "Expert").
- **Faceting**: The plot is separated into panels using the `name` variable (measurement type), arranged in two rows with free y-axis scales.
- **Statistical Comparison**: `stat_compare_means()` adds a Wilcoxon test (displaying significance levels) to compare groups.
- **Aesthetic Adjustments**: X-axis labels are rotated 45° for better readability, and custom colors are applied for the Driver groups.

```r
plot <- ggboxplot(
  tmp_df1,
  x = "Group", y = "value", color = "Driver",
  outlier.shape = NA
) +
  stat_compare_means(
    aes(x = Group, y = value, group = Driver),
    method = "wilcox.test", label = "p.signif"
  ) +
  facet_wrap(~ name, nrow = 2, scales = "free_y") +
  guides(x = guide_axis(angle = 45)) +
  scale_colour_manual(values = c("#FF8230", "#1E78FE"))
```

---

## 7. Display the Plot

Finally, the plot is printed to the R graphics device.

```r
print(plot)
```

---

## Running Instructions

1. **Data Preparation:**  
   - Ensure the file `conbine_result.csv` is located in your working directory.
   - Verify that the CSV contains the required columns including `Driver`, `Group`, and measurement columns from `acceleration` to `throttle_percentage`.

2. **Install Dependencies:**  
   If not installed, run:
   ```r
   install.packages(c("dplyr", "tidyr", "ggpubr"))
   ```

3. **Execute the Script:**  
   Open your R environment (e.g., RStudio), then run the entire script.  
   The data will be processed to remove outliers, reshaped into long format, and a multi-faceted boxplot with statistical significance annotations will be displayed.

---

## Summary

This script provides a full workflow to:

- **Import and Prepare Data:**  
  Read combined analysis data and set key factor variables.

- **Filter Outliers:**  
  Apply a 3×IQR rule to remove extreme values from all numeric columns.

- **Reshape Data:**  
  Convert wide-format data into a long format suitable for plotting.

- **Visualize with Boxplots:**  
  Create a boxplot showcasing the distribution of various measurements across different groups, complete with Wilcoxon test comparisons to highlight statistically significant differences between Driver groups.

This comprehensive guide should help you understand, run, and modify the analysis pipeline as needed.

---