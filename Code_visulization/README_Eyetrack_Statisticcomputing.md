Below is an English README that explains the workflow and functionality of the provided R code. This script reads a CSV file, filters and reshapes the data, and then creates a faceted box plot with statistical (Wilcoxon test) comparisons.

---

# Box Plot with Statistical Comparisons: Data Preparation and Visualization

This script processes a CSV file to produce a box plot that visualizes data distribution and tests group differences using Wilcoxon comparisons. The code can be broken into the following main sections:

1. **Load Required Libraries**  
2. **Read and Filter Data**  
3. **Transform Data to Long Format**  
4. **Create Box Plot with Statistical Comparisons**  
5. **Display the Plot**

---

## 1. Load Required Libraries

The script begins by loading essential libraries:

- **tidyverse**: A collection of R packages for data manipulation and visualization (includes dplyr, tidyr, ggplot2, etc.).
- **ggpubr**: Provides easy-to-use functions for creating publication-ready plots and adding statistical annotations.

```r
library(tidyverse)   # Loads dplyr, tidyr, ggplot2, etc.
library(ggpubr)
```

---

## 2. Read and Filter Data

### Purpose

- **Reading Data**: The script loads the data from the CSV file `"conbi_string1.csv"`.
- **Filtering**: It filters out rows where the `ID` column contains `"N08"` or `"N14"`. This ensures that undesired records are excluded from further analysis.
- **Driver Factor**: The `Driver` column is converted into a factor with levels `"N"` and `"E"` (which may represent, for example, Novice and Expert).

### Code

```r
df1 <- read.csv("conbi_string1.csv") %>%
  filter(!grepl("N08|N14", ID)) %>%  # Remove rows with "N08" or "N14" in the ID field
  mutate(Driver = factor(Driver, levels = c("N", "E")))  # Set Driver as a factor with levels "N" and "E"
```

---

## 3. Transform Data to Long Format

### Purpose

The code converts the data from wide to long format to facilitate plotting. In this case, columns `X9` to `X1` are pivoted into key-value pairs. Additionally, the `Group` column is converted into a factor with a custom order.

### Key Steps

- **Pivoting**: The `pivot_longer` function converts columns `X9` through `X1` into two columns: one for the original column names (`name`) and one for the values (`value`).
- **Custom Group Ordering**: The `Group` variable is transformed to a factor with a specific order by rearranging its unique levels.

### Code

```r
tmp_df1 <- df1 %>%
  pivot_longer(cols = X9:X1) %>%  # Pivot columns X9 to X1 into key-value pairs
  data.frame() %>%
  mutate(Group = factor(Group, levels = unique(Group)[c(1:2, 7:14, 3:6, 15)]))  # Set custom factor levels for Group
```

---

## 4. Create Box Plot with Statistical Comparisons

### Purpose

This section uses **ggpubr** to create a box plot with the following features:

- **X-axis**: Represents the `Group`.
- **Y-axis**: Represents the measurement values (from the `value` column).
- **Color**: Differentiates between `Driver` groups.
- **Statistical Comparison**: A Wilcoxon test is applied to compare distributions across different groups, with significance levels shown on the plot.
- **Faceting**: The plot is faceted by the `name` variable (which came from the pivoted columns) into three rows, with the y-axis scales set free for each facet.
- **Customization**: X-axis labels are rotated by 45° for better readability, and custom colors are applied to the Driver groups. The y-axis scale is limited between 0 and 1.

### Code

```r
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
```

---

## 5. Display the Plot

The final step is to print the plot to the active graphics device so that you can view and analyze the box plot.

### Code

```r
print(plot)
```

---

## Running Instructions

1. **Preparation**:
   - Ensure the CSV file `"conbi_string1.csv"` is located in your working directory.
   - Verify that the file includes columns such as `ID`, `Driver`, `Group`, and the numeric columns `X9` to `X1`.

2. **Dependencies**:
   - Install necessary packages (if not already installed) by running:
     ```r
     install.packages(c("tidyverse", "ggpubr"))
     ```

3. **Execution**:
   - Open an R environment (such as RStudio).
   - Run the script section by section or as a whole.
   - The script will filter and reshape your data, then generate and display the faceted box plot with statistical comparison annotations.

4. **Output**:
   - The output is a multi-faceted box plot visualizing the data distribution across groups and driver types, complete with p-values from Wilcoxon tests indicating statistical significance.

---

## Summary

This script provides a robust workflow to:
- Read and pre-process a CSV file by filtering based on IDs.
- Reshape the data into a long format suitable for visualization.
- Create a detailed faceted box plot with statistical comparisons to detect differences across groups and driver types.
- Customize the plot with specific aesthetic choices for clarity and presentation.

This README should assist you in understanding, running, and modifying the code to suit your data visualization needs.

---