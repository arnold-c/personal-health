library(targets)
library(tarchetypes)

# Set target-specific options such as packages.
tar_option_set(
  packages = c(
    "tidyverse",
    "tsibble",
    "janitor",
    "plotly",
    "here",
    "lubridate",
    "fable",
    "fabletools",
    "feasts",
    "highcharter",
    "arrow"
  )
)

source(here::here("funs", "cleaning.R"))

cleaning_targets <- list(
  # Load Cronometer ----
  tar_target(
    cron_biometrics_raw_file,
    here::here("data/Cronometer", "cron_biometrics.csv"),
    format = "file"
  ),
  tar_target(
    cron_biometrics_raw,
    read_csv(cron_biometrics_raw_file) %>%
      janitor::clean_names() %>%
      rename(date = day) %>%
      mutate(date = as_date(date)) %>%
      drop_na()
  ),
  tar_target(
    cron_nutrition_raw_file,
    here::here("data/Cronometer", "cron_daily-nutrition.csv"),
    format = "file"
  ),
  tar_target(
    cron_nutrition_raw,
    read_csv(cron_nutrition_raw_file, guess_max = 5000) %>%
      janitor::clean_names() %>%
      rename(calories = energy_kcal, carbohydrates_g = carbs_g) %>%
      mutate(date = as_date(date)) %>%
      drop_na()
  ),
  tar_target(
    cron_exercise_raw_file,
    here::here("data/Cronometer", "cron_exercises.csv"),
    format = "file"
  ),
  tar_target(
    cron_exercise_raw,
    read_csv(cron_exercise_raw_file) %>%
      janitor::clean_names() %>%
      rename(date = day) %>%
      mutate(date = as_date(date)) %>%
      drop_na()
  ),

  # Load MFP ----
  tar_target(
    mfp_biometrics_raw_file,
    here::here("data/MFP", "Measurement-Summary-2015-04-08-to-2021-05-17.csv"),
    format = "file"
  ),
  tar_target(
    mfp_biometrics_raw,
    read_csv(mfp_biometrics_raw_file) %>%
      janitor::clean_names() %>%
      rename(weight = weightkg) %>%
      mutate(date = as_date(date)) %>%
      drop_na()
  ),
  tar_target(
    mfp_nutrition_raw_file,
    here::here("data/MFP", "mfp_daily-nutrition.parquet"),
    format = "file"
  ),
  tar_target(
    mfp_nutrition_raw,
    read_parquet(mfp_nutrition_raw_file) %>%
      janitor::clean_names() %>%
      rename_with(~paste0(., "_g"), .cols = -c(date, calories)) %>%
      mutate(date = as_date(date)) %>%
      drop_na()
  ),
  tar_target(
    mfp_exercise_raw_file,
    here::here("data/MFP", "Exercise-Summary-2015-04-08-to-2021-05-17.csv"),
    format = "file"
  ),
  tar_target(
    mfp_exercise_raw,
    read_csv(mfp_exercise_raw_file) %>%
      janitor::clean_names() %>%
      mutate(date = as_date(date)) %>%
      drop_na()
  ),

  # Cronometer totals ----
  tar_target(
    cron_exercise_totals,
    calculate_daily_totals(cron_exercise_raw, minutes:calories_burned) %>%
      rename(exercise_calories = calories_burned)
  ),

  # MFP totals ----
  tar_target(
    mfp_exercise_totals,
    calculate_daily_totals(mfp_exercise_raw, exercise_calories:exercise_minutes)
  ),

  # Cronometer body measures ----
  tar_target(
    cron_body_measures,
    create_cron_wide_body_measures(cron_biometrics_raw)
  ),

  # Join data ----
  tar_target(
    joined_data_raw,
    join_all_data(
      mfp_body_measures = mfp_biometrics_raw,
      wide_cron_body_measures = cron_body_measures,
      mfp_nutrition_totals = mfp_nutrition_raw,
      cron_nutrition = cron_nutrition_raw,
      mfp_exercise_totals = mfp_exercise_totals,
      cron_exercise_totals = cron_exercise_totals
    )
  ),
  tar_target(
    joined_data_renamed,
    clean_joined_data_vars(joined_data_raw)
  ),

  # Feature engineering ----
  tar_target(
    featured_calorie_vars,
    feature_calorie_vars(joined_data_renamed)
  ),
  tar_target(
    all_totals,
    featured_calorie_vars %>%
      calculate_rolling_average(., var = weight, n_days = 7) %>%
      calculate_rolling_average(., var = calories, n_days = 7) %>%
      calculate_rolling_average(., var = net_calories, n_days = 7) %>%
      calculate_rolling_average(., var = calorie_delta, n_days = 7)
  ),

  # Pivot Longer ----
  tar_target(
    all_totals_long,
    all_totals %>% 
      select(-c(contains(".x"), contains(".y"))) %>% 
      pivot_longer(
        cols = !date,
        names_to = "Metric",
        values_to = "Value",
        values_drop_na = TRUE
      )
  ),

  # Prepare tsibbles ----
  tar_target(
    all_totals_ts,
    as_tsibble(all_totals, index = date, regular = FALSE)
  ),
  tar_target(
    all_totals_long_ts,
    as_tsibble(
      all_totals_long, 
      index = date,
      key = Metric,
      regular = FALSE
    )
  ),

  # Golden Cheetah ----
  tar_target(
    gc_weight_data,
    prepare_GC_weight_data(all_totals_ts)
  ),
  tar_target(
    gc_weight_data_file,
    write_csv_and_return_path(
      gc_weight_data, dir = "out", filename = "gc_weight"
    ),
    format = "file"
  ),
  tar_target(
    gc_nutrition_data,
    prepare_GC_nutrition_data(all_totals_ts)
  ),
  tar_target(
    gc_nutrition_data_file,
    write_csv_and_return_path(
      gc_nutrition_data, dir = "out", filename = "gc_nutrition"
    ),
    format = "file"
  )
)

report_targets <- list(
  tar_render(
    personal_health_report,
    "personal-health.Rmd"
  )
)


# End this file with a list of target objects.
list(
  cleaning_targets,
  report_targets
)
