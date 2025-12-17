Below is a detailed **Driver Data Analysis README** that explains the workflow and logic of the code. This script reads and transforms driver survey data from Excel files, generates boxplots for visualization, and performs paired as well as independent t-tests for statistical comparisons.

---

# Driver Data Analysis README

The script is organized into five main sections:

1. **Reading and Transforming "sub_Driver_DES.xlsx" Data**  
   This section reads driver survey data from an Excel file (DES data) and reshapes it into a long format for further analysis.

2. **Plotting Boxplots from the Transformed Data**  
   Two sets of boxplots are created:
   - Boxplots by driver, with the pre/post group as the fill color.
   - Boxplots by pre/post group, with the driver type as the fill color.

3. **Paired t-test for Pre vs. Post Within Each Variable and Driver**  
   For every combination of variable and driver, a paired t-test is conducted to compare pre- and post-test measurements. Test statistics and group means are collected and saved.

4. **Independent t-test for Expert vs. Novice Within Each Variable and Group**  
   Within each variable and pre/post group, an independent t-test compares the Expert and Novice driver groups. The results are saved to a CSV file.

5. **MDSI Data: Read, Transform, Plot, and t-test**  
   This section processes another Excel file (MDSI data), cleans and reshapes the data, generates boxplots for the MDSI measures, and performs an independent t-test comparing driver groups.

Below is a breakdown of each section along with key code snippets.

---

## Section 1: Read and Transform "sub_Driver_DES.xlsx" Data

- **Objective**:  
  Read the Excel file that contains driver data (DES data), retain the first three columns, and pivot all remaining columns into a long format. The column names are split into a variable name (`var`) and a group label (`pre` or `post`).

- **Key Steps**:
  - Use `readxl::read_excel()` to load the data.
  - Convert the data into a data frame.
  - Pivot all columns except the first three with `pivot_longer()`, splitting column names using a regular expression.
  - Convert the resulting `group` column to a factor with levels ordered as "pre" and "post".

- **Snippet**:
  ```r
  df2 <- readxl::read_excel("sub_Driver_DES.xlsx") %>% 
    data.frame() %>% 
    pivot_longer(
      cols = -c(1:3),
      names_to = c("var", "group"),
      names_pattern = "(.*)_(pre|post)",
      values_to = "value"
    ) %>% 
    mutate(group = factor(group, levels = c("pre", "post")))
  ```

---

## Section 2: Plotting Boxplots from df2

This section creates two types of boxplots based on the transformed DES data (`df2`).

### 2.1 Boxplot by Driver with Group as Fill

- **Objective**:  
  Plot boxplots using the `Driver` variable on the x-axis and display the pre/post groups via the fill color. The plots are faceted by each variable (`var`).

- **Snippet**:
  ```r
  ggplot(df2, aes(x = Driver, y = value, fill = group)) +
    geom_boxplot() +
    scale_fill_manual(values = c("#FF8230", "#1E78FE")) +
    facet_wrap(~ var, ncol = 5, scales = "free_y") +
    theme_classic() +
    theme(
      panel.border = element_rect(fill = NA, linewidth = 0.2358),
      axis.line = element_line(linewidth = 0.2358),
      axis.ticks = element_line(linewidth = 0.2358, colour = "black"),
      axis.title = element_text(size = 10),
      axis.text = element_text(size = 10, colour = "black")
    )
  ```

### 2.2 Boxplot by Group with Driver as Fill

- **Objective**:  
  Create boxplots with the group (pre/post) on the x-axis and driver type (`Driver`) depicted by color. Again, the plots are faceted by the variable (`var`).

- **Snippet**:
  ```r
  ggplot(df2, aes(x = group, y = value, fill = Driver)) +
    geom_boxplot() +
    scale_fill_manual(values = c("#1E78FE", "#FF8230")) +
    facet_wrap(~ var, ncol = 5, scales = "free_y") +
    theme_classic() +
    theme(
      panel.border = element_rect(fill = NA, linewidth = 0.2358),
      axis.line = element_line(linewidth = 0.2358),
      axis.ticks = element_line(linewidth = 0.2358, colour = "black"),
      axis.title = element_text(size = 10),
      axis.text = element_text(size = 10, colour = "black")
    )
  ```

---

## Section 3: Paired t-test for Pre vs. Post within Each Variable and Driver

- **Objective**:  
  For every variable and driver combination, conduct a paired t-test comparing the "pre" and "post" groups.

- **Key Steps**:
  - Loop over each variable (`var`) and each `Driver` in `df2`.
  - Subset the data into pre and post measurements.
  - Perform a paired t-test using `t.test()` with `paired = TRUE`.
  - Extract the t-value, degrees of freedom, p-value, and the mean values for pre and post.
  - Aggregate the results into a results data frame and save the output in a CSV file named `"DSSQ_pre_post.csv"`.

- **Snippet**:
  ```r
  df_pre_post <- data.frame()

  for (i in unique(df2$var)) {
    for (j in unique(df2$Driver)) {
      tryCatch({
        data_subset <- subset(df2, var == i & Driver == j)
        pre_data  <- data_subset$value[data_subset$group == "pre"]
        post_data <- data_subset$value[data_subset$group == "post"]
        
        tmp_test <- t.test(pre_data, post_data, paired = TRUE)
        
        tmp_t      <- tmp_test$statistic
        tmp_df_val <- tmp_test$parameter
        tmp_p      <- tmp_test$p.value
        tmp_mean1  <- mean(pre_data, na.rm = TRUE)
        tmp_mean2  <- mean(post_data, na.rm = TRUE)
        
        tmp_res <- c(i, j, "pre vs post", tmp_t, tmp_df_val, tmp_p, tmp_mean1, tmp_mean2)
        df_pre_post <- rbind(df_pre_post, tmp_res)
      }, error = function(e) {
        NULL
      })
    }
  }

  df_pre_post <- df_pre_post %>% 
    mutate(across(-c(1:3), as.numeric)) %>% 
    `colnames<-`(c("var", "Driver", "comparison", "t_value", "df_value", "p_value", "mean1", "mean2"))

  write.csv(df_pre_post, "DSSQ_pre_post.csv", row.names = FALSE)
  ```

---

## Section 4: Independent t-test for Expert vs. Novice within Each Variable and Group

- **Objective**:  
  For each combination of variable and pre/post group, perform an independent t-test comparing the Expert and Novice driver groups.

- **Key Steps**:
  - Loop over each variable and each group.
  - Use `t.test()` to compare values between driver groups within the subset.
  - Extract relevant statistics and group means.
  - Store the results in a data frame and export them as `"DSSQ_expert_novice.csv"`.

- **Snippet**:
  ```r
  df_exp_nov <- data.frame()

  for (i in unique(df2$var)) {
    for (j in unique(df2$group)) {
      tryCatch({
        tmp_test <- t.test(value ~ Driver, data = subset(df2, var == i & group == j))
        
        tmp_t      <- tmp_test$statistic
        tmp_df_val <- tmp_test$parameter
        tmp_p      <- tmp_test$p.value
        tmp_mean1 <- tmp_test$estimate["mean in group Expert"]
        tmp_mean2 <- tmp_test$estimate["mean in group Novice"]
        
        tmp_res <- c(i, j, "Expert vs Novice", tmp_t, tmp_df_val, tmp_p, tmp_mean1, tmp_mean2)
        df_exp_nov <- rbind(df_exp_nov, tmp_res)
      }, error = function(e) {
        NULL
      })
    }
  }

  df_exp_nov <- df_exp_nov %>% 
    mutate(across(-c(1:3), as.numeric)) %>% 
    `colnames<-`(c("var", "group", "comparison", "t_value", "df_value", "p_value", "mean1", "mean2"))

  write.csv(df_exp_nov, "DSSQ_expert_novice.csv", row.names = FALSE)
  ```

---

## Section 5: MDSI Data — Read, Transform, Plot, and t-test

This section processes the MDSI data from a separate Excel file.

### 5.1 Read and Pivot the "sub_Driver_MDSI_C.xlsx" Data

- **Objective**:  
  Read the MDSI data, clean the column names using the `janitor` package, and pivot the data into a long format.

- **Snippet**:
  ```r
  df3 <- readxl::read_excel("sub_Driver_MDSI_C.xlsx") %>% 
    clean_names() %>% 
    pivot_longer(cols = dissociative_driving_style:careful_driving_style)
  ```

### 5.2 Create Boxplot for the MDSI Data

- **Objective**:  
  Visualize the MDSI data with boxplots where the x-axis represents the driver category and the facets represent different MDSI measures.

- **Snippet**:
  ```r
  ggplot(df3, aes(x = driver, y = value, fill = driver)) +
    geom_boxplot() +
    scale_fill_manual(values = c("#FF8230", "#1E78FE")) +
    facet_wrap(~ name, ncol = 5, scales = "free_y") +
    theme_classic() +
    theme(
      panel.border = element_rect(fill = NA, linewidth = 0.2358),
      axis.line = element_line(linewidth = 0.2358),
      axis.ticks = element_line(linewidth = 0.2358, colour = "black"),
      axis.title = element_text(size = 10),
      axis.text = element_text(size = 10, colour = "black")
    )
  ```

### 5.3 Independent t-test for Expert vs. Novice in MDSI Data

- **Objective**:  
  Perform an independent t-test on each MDSI measure, comparing the driver groups (Expert vs. Novice). The results, including test statistics and group means, are saved.

- **Snippet**:
  ```r
  df_exp_nov2 <- data.frame()

  for (i in unique(df3$name)) {
    tryCatch({
      tmp_test <- t.test(value ~ driver, data = subset(df3, name == i))
      
      tmp_t      <- tmp_test$statistic
      tmp_df_val <- tmp_test$parameter
      tmp_p      <- tmp_test$p.value
      tmp_mean1  <- tmp_test$estimate["mean in group Expert"]
      tmp_mean2  <- tmp_test$estimate["mean in group Novice"]
      
      tmp_res <- c(i, "Expert vs Novice", tmp_t, tmp_df_val, tmp_p, tmp_mean1, tmp_mean2)
      df_exp_nov2 <- rbind(df_exp_nov2, tmp_res)
    }, error = function(e) {
      NULL
    })
  }

  df_exp_nov2 <- df_exp_nov2 %>% 
    mutate(across(-c(1:2), as.numeric)) %>% 
    `colnames<-`(c("var", "comparison", "t_value", "df_value", "p_value", "mean1", "mean2"))

  write.csv(df_exp_nov2, "statistics_expert_novice2.csv", row.names = FALSE)
  ```

---

## Running Instructions

1. **Data Preparation**:  
   - Ensure that `sub_Driver_DES.xlsx` and `sub_Driver_MDSI_C.xlsx` exist in your working directory.
   - Verify that the file formats match the expected structure (e.g., columns requiring pivoting are named appropriately).

2. **Install Required Libraries**:  
   The script uses several R packages. Install them if they are not already available:
   ```r
   install.packages(c("ggpubr", "data.table", "readxl", "tidyverse", "dplyr", "ggplot2", "janitor"))
   ```

3. **Execute the Script**:  
   Run the entire script in an R environment or within RStudio. Make sure each section finishes without errors:
   - Sections 1 through 5 will read, transform, visualize, and perform the statistical tests.
   - The t-test results will be exported to CSV files (`DSSQ_pre_post.csv`, `DSSQ_expert_novice.csv`, and `statistics_expert_novice2.csv`).

4. **Review the Outputs**:  
   - Boxplots will be displayed in the R plotting window.
   - CSV files with the t-test results will be saved in your working directory for further review.

---

## Summary

This script implements a comprehensive driver data analysis workflow:
- **Data Transformation (DES Data)**: Reading and pivoting data from an Excel file, thereby transforming wide-format data into a long format.
- **Visualization**: Creating two sets of boxplots to explore the relationships between Drivers and pre/post groups.
- **Statistical Tests**:  
  - Performing paired t-tests to compare pre- vs. post-values within each driver for each variable.
  - Conducting independent t-tests between Expert and Novice drivers within each variable and group.
- **MDSI Data Analysis**: Processing and visualizing additional driver data (MDSI), and performing independent t-tests for group comparisons.

This README provides an overview of the code’s workflow, facilitating both replication of the analysis and future modifications or extensions.

---