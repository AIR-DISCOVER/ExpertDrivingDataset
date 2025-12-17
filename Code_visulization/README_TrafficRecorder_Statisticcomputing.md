Below is a detailed **README** that explains the workflow and logic of the provided R code. This script reads a combined results CSV file, transforms the data for visualization, and creates a 100% stacked bar plot comparing the proportions of different transportation categories (from `bicycle` to `truck`) across Driver groups. The plot is further faceted by a grouping variable, allowing for a side-by-side comparison based on group.

---

# Stacked Bar Plot Visualization for Combined Analysis Data

This script is organized into four main sections:

1. **Read the Combined Analysis Data**  
2. **Prepare Data for Visualization**  
3. **Create Stacked Bar Plot**  
4. **Running Instructions**

Each section is described in detail below.

---

## 1. Read the Combined Analysis Data

- **Purpose:**  
  The script starts by reading the CSV file (`conbine_result.csv`) that contains the combined analysis results from previous processing steps.

- **Preview:**  
  It uses `head()` to preview the first few rows of the dataset, ensuring the data have been loaded correctly.

```r
analysis_data <- read.csv('conbine_result.csv')
head(analysis_data)
```

---

## 2. Prepare Data for Visualization

- **Transforming the `Driver` Column:**  
  The `Driver` column is converted to a factor with two levels: `"Novice"` and `"Expert"`.

- **Reshaping Data:**  
  The data are reshaped from wide to long format using `pivot_longer()`. The columns spanning from `bicycle` to `truck` are transformed so that each category becomes a row entry under the new `name` column, with corresponding values in the `value` column.

- **Ordering Categories:**  
  The factor levels of the `name` variable are explicitly set in a specific order:
  `traffic`, `stop`, `car`, `bus`, `truck`, `bicycle`, `motorcycle`, `person`.

- **Removing Missing Values:**  
  Any rows with missing values (`NA`) are removed to ensure a clean visualization.

```r
plot_data <- analysis_data %>%
  mutate(Driver = factor(Driver, levels = c('Novice', 'Expert'))) %>%
  pivot_longer(cols = bicycle:truck) %>%
  mutate(name = factor(name, levels = c('traffic', 'stop', 'car', 'bus', 'truck', 
                                        'bicycle', 'motorcycle', 'person'))) %>%
  na.omit() %>%
  data.frame()

head(plot_data)
```

---

## 3. Create Stacked Bar Plot

Using **ggplot2**, the script generates a 100% stacked bar plot:

- **X-Axis:**  
  The x-axis represents the `Driver` factor (Novice vs. Expert).

- **Stacked Bars:**  
  The bars are filled by the `name` variable, which represents various transportation categories.

- **Normalization:**  
  The `position = 'fill'` argument ensures that the heights of the bars represent proportions, resulting in a 100% stacked bar plot.

- **Faceting:**  
  The plot is faceted by the `Group` variable, enabling side-by-side comparisons by group in a single row layout.

- **Labels and Theme:**  
  Titles, axis labels, and legend titles are provided, and a minimal theme is applied for clarity.

```r
ggplot(plot_data, aes(x = Driver, y = value, fill = name)) +
  geom_bar(stat = 'identity', position = 'fill') +
  facet_wrap(~ Group, nrow = 1) +
  labs(title = "Stacked Bar Plot by Driver and Group",
       x = "Driver",
       y = "Proportion",
       fill = "Category") +
  theme_minimal()
```

---

## 4. Running Instructions

1. **Data Preparation:**  
   - Ensure that the file `conbine_result.csv` is present in your working directory.
   - Verify that this file contains the necessary columns, including `Driver`, `Group`, and the transportation categories (from `bicycle` to `truck`).

2. **Install Required Packages:**  
   Install any missing packages using:
   ```r
   install.packages(c("readr", "ggplot2", "dplyr", "tidyr"))
   ```

3. **Execute the Script:**  
   - Run the entire script in your R environment (such as RStudio).
   - The script will load the data, perform the necessary transformations, and generate the final stacked bar plot.

4. **Review the Output:**  
   Once executed, the 100% stacked bar plot will be displayed in your R plotting window, showing the proportional distribution of different transportation categories for each Driver (Novice vs. Expert), faceted by the Group variable.

---

## Summary

This visualization script performs the following operations:

- **Data Input:**  
  Reads the combined analysis results from a CSV file.

- **Data Transformation:**  
  Converts key columns to factors, reshapes the data from wide to long format, orders categories explicitly, and cleans the data by removing missing values.

- **Visualization:**  
  Creates a 100% stacked bar plot that compares the proportions of various transportation categories across Driver groups, making it easy to compare differences across groups through faceting.

This README serves as a complete guide to running and understanding the visualization process for the combined analysis data.

---