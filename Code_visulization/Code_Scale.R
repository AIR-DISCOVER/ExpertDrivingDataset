# ==============================================================================
# Load Required Libraries
# ==============================================================================
# Note: Some libraries are part of the tidyverse, so not all are strictly necessary.
library(ggpubr)
library(data.table)
library(readxl)
library(tidyverse)
library(dplyr)
library(ggplot2)
library(janitor)

# ==============================================================================
# Section 1: Read and Transform "sub_Driver_DES.xlsx" Data
# ==============================================================================
# Reads the Excel file, converts to a data frame,
# pivots columns (except the first three) into long format.
# The column names are split into variable ("var") and group ("pre" or "post").
df2 <- readxl::read_excel("sub_Driver_DES.xlsx") %>% 
  data.frame() %>% 
  pivot_longer(
    cols = -c(1:3),
    names_to = c("var", "group"),
    names_pattern = "(.*)_(pre|post)",
    values_to = "value"
  ) %>% 
  mutate(group = factor(group, levels = c("pre", "post")))

# ==============================================================================
# Section 2: Plotting Boxplots from df2
# ------------------------------------------------------------------------------
# 2.1 Boxplot by Driver with Group (pre/post) as fill:
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

# ------------------------------------------------------------------------------
# 2.2 Boxplot by Group with Driver as fill:
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

# ==============================================================================
# Section 3: Paired t-test for Pre vs. Post within Each Variable and Driver
# ==============================================================================
# Initialize an empty data frame to store the test results.
df_pre_post <- data.frame()

# Loop over each variable (var) and each driver, and perform a paired t-test.
for (i in unique(df2$var)) {
  for (j in unique(df2$Driver)) {
    tryCatch({
      # Subset data for a given variable and Driver
      data_subset <- subset(df2, var == i & Driver == j)
      
      pre_data  <- data_subset$value[data_subset$group == "pre"]
      post_data <- data_subset$value[data_subset$group == "post"]
      
      # Perform paired-sample t-test
      tmp_test <- t.test(pre_data, post_data, paired = TRUE)
      
      tmp_t      <- tmp_test$statistic         # t-value
      tmp_df_val <- tmp_test$parameter         # degrees of freedom
      tmp_p      <- tmp_test$p.value
      tmp_mean1  <- mean(pre_data, na.rm = TRUE)  # mean value for pre-test
      tmp_mean2  <- mean(post_data, na.rm = TRUE) # mean value for post-test
      
      # Create a temporary vector with the test results
      tmp_res <- c(i, j, "pre vs post", tmp_t, tmp_df_val, tmp_p, tmp_mean1, tmp_mean2)
      # Append the results to the data frame
      df_pre_post <- rbind(df_pre_post, tmp_res)
    }, error = function(e) {
      # In case of error, simply continue
      NULL
    })
  }
}

# Convert appropriate columns to numeric and set column names
df_pre_post <- df_pre_post %>% 
  mutate(across(-c(1:3), as.numeric)) %>% 
  `colnames<-`(c("var", "Driver", "comparison", "t_value", "df_value", "p_value", "mean1", "mean2"))

# Write the paired t-test results to a CSV file
write.csv(df_pre_post, "DSSQ_pre_post.csv", row.names = FALSE)

# ==============================================================================
# Section 4: Independent t-test for Expert vs. Novice within Each Variable and Group
# ==============================================================================
df_exp_nov <- data.frame()

# Loop over each variable and group within df2 for Expert vs. Novice comparison.
for (i in unique(df2$var)) {
  for (j in unique(df2$group)) {
    tryCatch({
      tmp_test <- t.test(value ~ Driver, data = subset(df2, var == i & group == j))
      
      tmp_t      <- tmp_test$statistic
      tmp_df_val <- tmp_test$parameter
      tmp_p      <- tmp_test$p.value
      # Extract group means from the test result estimates
      tmp_mean1 <- tmp_test$estimate["mean in group Expert"]
      tmp_mean2 <- tmp_test$estimate["mean in group Novice"]
      
      tmp_res <- c(i, j, "Expert vs Novice", tmp_t, tmp_df_val, tmp_p, tmp_mean1, tmp_mean2)
      df_exp_nov <- rbind(df_exp_nov, tmp_res)
    }, error = function(e) {
      NULL
    })
  }
}

# Convert columns (except the first three) to numeric and rename columns
df_exp_nov <- df_exp_nov %>% 
  mutate(across(-c(1:3), as.numeric)) %>% 
  `colnames<-`(c("var", "group", "comparison", "t_value", "df_value", "p_value", "mean1", "mean2"))

# Write the Expert vs. Novice comparison results to a CSV file
write.csv(df_exp_nov, "DSSQ_expert_novice.csv", row.names = FALSE)

# ==============================================================================
# Section 5: MDSI Data: Read, Transform, Plot, and t-test
# ------------------------------------------------------------------------------
# 5.1 Read and Pivot the "sub_Driver_MDSI_C.xlsx" Data:
df3 <- readxl::read_excel("sub_Driver_MDSI_C.xlsx") %>% 
  clean_names() %>% 
  pivot_longer(cols = dissociative_driving_style:careful_driving_style)

# 5.2 Create Boxplot for the MDSI Data:
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

# ------------------------------------------------------------------------------
# 5.3 Expert vs. Novice t-test for MDSI Data:
df_exp_nov2 <- data.frame()

# Loop through each MDSI variable (name) and perform an independent t-test.
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

# Convert the numeric columns and set proper column names.
df_exp_nov2 <- df_exp_nov2 %>% 
  mutate(across(-c(1:2), as.numeric)) %>% 
  `colnames<-`(c("var", "comparison", "t_value", "df_value", "p_value", "mean1", "mean2"))

# Write the MDSI Expert vs. Novice test results to a CSV file.
write.csv(df_exp_nov2, "statistics_expert_novice2.csv", row.names = FALSE)

