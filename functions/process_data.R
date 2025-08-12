# Function processing the concentration measurements into values by category.
# Main outputs is the column indicating, whether a category was "Quantified",
# "Detected", or "Not detected" and the possible range, where the measurement
# is, i.e. the interval bounds between the best-case and worst-case scenario.
process_data <- function(dat, chem_categories) {
  # Reshape the data to a long format
  dat_long <- dat |>
    # Convert the measurements to character to avoid problems when pivoting
    mutate(across(-tidyselect::any_of("Age"), as.character)) |>
    pivot_longer(
      -tidyselect::any_of(
        c(
          "Park",
          "Sample_number",
          "Species",
          "Sex",
          "Age",
          "Date_of_sample_collection",
          "Season"
        )
      ),
      names_to = "Chemical",
      values_to = "Value"
    ) |>
    mutate(
      # Throws 2 warnings, because we use as.numeric() and grepl() on NA values,
      # but it is OK
      Detected = case_when(
        # When a cell is empty, the chemical was not detected
        is.na(Value) ~ "Not detected",
        # Not quantified values contain the "<" character
        grepl("<", Value) ~ "Detected",
        # Quantified values are values that can be converted to a numeric
        !is.na(as.numeric(Value)) ~ "Quantified"
      ),
      Value = ifelse(Detected == "Quantified", as.numeric(Value), NA)
    )

  # Assign the category to the chemicals. `chem_categories` contain everything
  # needed.
  dat_long <- left_join(dat_long, chem_categories, by = "Chemical")

  # Handle the detection of chemicals by category
  df_detected_by_category <- dat_long |>
    group_by(
      across(
        tidyselect::any_of(
          c(
            "primary_category",
            "Park",
            "Sample_number",
            "Species",
            "Sex",
            "Age",
            "Date_of_sample_collection",
            "Season"
          )
        )
      )
    ) |>
    summarise(
      # For plotting the descriptive concentration plot
      Value_sum_quantified_by_category = sum(Value, na.rm = TRUE),
      # For the regression model fitting
      Value_sum_by_category_left_censored = list(
        summarise_censoring(Detected, Value, Detection_threshold)
      ),
      Detected_by_category = summarise_detection(Detected)
    ) |>
    ungroup() |>
    unnest_wider(Value_sum_by_category_left_censored)
  df_detected_by_category
}
