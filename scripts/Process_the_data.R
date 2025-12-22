library("tidyverse")
source("functions/helper_functions.R")
source("functions/process_data.R")

# Process the main deer data ===================================================

chem_categories <- read_csv("data/chemical_categories.csv")
dat_deer <- read_csv("data/clean_data.csv")
df_detected_by_category <- process_data(dat_deer, chem_categories)
write_csv(df_detected_by_category, file = "data/data_by_pollutant_category.csv")

# Save as Excel
wb <- save_data_as_xls(df_detected_by_category)
openxlsx::saveWorkbook(
  wb,
  "data/data_by_pollutant_category.xlsx",
  overwrite = TRUE
)
