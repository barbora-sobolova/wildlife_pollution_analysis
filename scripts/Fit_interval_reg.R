library("tidyverse")
library("survival")
library("patchwork")
source("functions/fit_interval_regression.R")
source("functions/plot_elements.R")
source("functions/helper_functions.R")
source("functions/plot_results.R")
theme_set(theme_bw())

# Model the main deer data =====================================================

# Load the data
df_detected_by_category <- read_csv("data/data_by_pollutant_category.csv")

# Fit the model
results <- fit_interval_reg(df_detected_by_category)

# Save the plots
save_results_as_image(results$plt)

# Save the results into an Excel file
wb <- save_results_as_xls(results$fitted_mods)
openxlsx::saveWorkbook(wb, "tables/model_summaries.xlsx", overwrite = TRUE)

# Save the results into a .csv file
results_csv <- save_results_as_csv(results$fitted_mods)
write_csv(results_csv, "tables/model_summaries.csv")

# Secondary analysis: Comparison with the roe deer data ========================

df_roe_detected_by_category <- read_csv(
  "data/data_non_park_comparison_by_pollutant_category.csv"
)

results_roe <- fit_interval_reg(
  df_roe_detected_by_category,
  non_park_comparison = TRUE
)

# Save the plots
save_results_as_image(results_roe$plt, non_park_comparison = TRUE)

# Save the results into a .csv file
results_csv_roe <- save_results_as_csv(results_roe$fitted_mods)
write_csv(results_csv_roe, "tables/model_summaries_non_park_comparison.csv")

# Save the results into an Excel file
wb_roe <- save_results_as_xls(results_roe$fitted_mods)
openxlsx::saveWorkbook(
  wb_roe,
  "tables/model_summaries_non_park_comparison.xlsx",
  overwrite = TRUE
)

# Diagnostics
fits_vs_residuals <- results$fitted_mods |>
  lapply(function(x) {
    data.frame(fitted = fitted(x), residuals = residuals(x))
  }) |>
  bind_rows(.id = "Category")
ggplot(fits_vs_residuals, aes(x = fitted, y = residuals)) +
  geom_point() +
  geom_hline(yintercept = 0, color = "blue") +
  facet_wrap(~Category, scales = "free")
