library("tidyverse")
library("survival")
library("patchwork")
source("functions/fit_interval_regression.R")
source("functions/ggplot_box_legend.R")
source("functions/plot_elements.R")
source("functions/process_data.R")
source("functions/helper_functions.R")
source("functions/plot_results.R")
theme_set(theme_bw())

# Set locale to English for displaying the month names correctly
# (with fallbacks recommended by the CodeRabbit)
loc <- Sys.setlocale("LC_TIME", "English")
if (is.na(loc)) loc <- Sys.setlocale("LC_TIME", "en_US.UTF-8")
if (is.na(loc)) loc <- Sys.setlocale("LC_TIME", "English_United States.1252")

# Model the main deer data =====================================================

# Load and filter the model data. We remove observation Z91 that was collected
# on 29.05.2024, which is approx. 2 months before all other observations. This
# creates a gap in the time covariate, better continue without it.
df_detected_by_category <- read_csv("data/data_by_pollutant_category.csv") |>
  filter(Sample_number != "Z91")

# Load and process the descriptive data, that shall be used for displaying the
# bar- and boxplot part.
chem_categories <- read_csv("data/chemical_categories.csv")

dat <- read_csv("data/clean_data.csv") |>
  # Filter out the Z91 observation.
  filter(Sample_number != "Z91")
df_descriptive <- dat |>
  process_data(chem_categories, exclude_uninformative = FALSE)

# Fit the model
results <- fit_interval_reg(df_detected_by_category, df_descriptive)

# Put NULL everywhere, where fitting was unsuccessful
bad_fitting <- results$plt |> lapply(is_empty) |> unlist() |> which()
results$plt[bad_fitting] <- list(rep(NULL, length(bad_fitting)))
results$fitted_mods[bad_fitting] <- list(rep(NULL, length(bad_fitting)))

# Put NULL everywhere, where fitting was unsuccessful
bad_fitting <- results$plt |> lapply(is_empty) |> unlist() |> which()
results$plt[bad_fitting] <- list(rep(NULL, length(bad_fitting)))
results$fitted_mods[bad_fitting] <- list(rep(NULL, length(bad_fitting)))

# Save the plots
save_results_as_image(results$plt, format = "png")

# Save the results into an Excel file
wb <- save_results_as_xls(results$fitted_mods)
openxlsx::saveWorkbook(wb, "tables/model_summaries.xlsx", overwrite = TRUE)

# Save the results into a .csv file
results_csv <- save_results_as_csv(results$fitted_mods)
write_csv(results_csv, "tables/model_summaries.csv")
