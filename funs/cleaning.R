calculate_daily_totals <- function(data, vars) {
  data %>%
    group_by(date) %>% 
    summarise(across({{ vars }}, sum))
}


create_cron_wide_body_measures <- function(data) {
  data %>%
    filter(metric != "Weight", metric != "Body Fat (Garmin)") %>%
    mutate(
      metric = case_when(
        metric == "Weight (Garmin)" ~ "weight",
        metric == "Heart Rate (Garmin)" ~ "hr_bpm",
        metric == "Sleep (Garmin)" ~ "sleep_hours"
      ),
      amount = if_else(is.na(amount), NA_real_, amount)
    ) %>%
    select(-unit) %>%
    filter(!(date == "2017-05-10" & amount == 159)) %>%
    pivot_wider(
      id_cols = date,
      names_from = metric,
      values_from = amount
    )
}

join_all_data <- function(
    mfp_body_measures, wide_cron_body_measures,
    mfp_nutrition_totals, cron_nutrition, 
    mfp_exercise_totals, cron_exercise_totals
  ) {
  mfp_body_measures %>% 
    full_join(
      wide_cron_body_measures,
      by = "date",
      suffix = c(".mfp", ".cron")
    ) %>% 
    full_join(mfp_nutrition_totals, by = "date") %>% 
    full_join(
      cron_nutrition,
      by = "date",
      suffix = c(".mfp", ".cron")
    ) %>% 
    full_join(mfp_exercise_totals, by = "date") %>% 
    full_join(
      cron_exercise_totals,
      by = "date",
      suffix = c(".mfp", ".cron")
    )
}

clean_joined_data_vars <- function(data) {
  shared_vars <- data %>%
    select(contains(".cron")) %>%
    names()  %>%
    str_remove_all(".cron")

  map(
    .x = shared_vars,
    .f = function(.x) {
      cron_var <- glue::glue("{.x}.cron")
      mfp_var <- glue::glue("{.x}.mfp")

      data %>%
        transmute(
          !!.x := case_when(
            !is.na(.data[[cron_var]]) ~ .data[[cron_var]],
            TRUE ~ .data[[mfp_var]]
          )
        )
    }
  ) %>%
  bind_cols(select(data, !contains(shared_vars)), .)
}

feature_calorie_vars <- function(data) {
  data %>%
    mutate(
      date = as_date(date),
      age_years = lubridate::interval(ymd("1993-07-16"), date) / years(1),
      net_calories = calories - exercise_calories,
      bmr_mifflin_st_joer = 10 * weight + 6.25 * 179 - 5 * age_years - 5,
      calorie_delta = net_calories - bmr_mifflin_st_joer
    )
}

calculate_rolling_average <- function(data, var, n_days) {
  var_str <- rlang::as_string(rlang::ensym(var))
  avg_var_str <- glue::glue("daily_{n_days}d_avg_{var_str}")

  data %>%
    mutate(
      !!avg_var_str := 
        slider::slide_dbl(
          .data[[var_str]], mean, .before = n_days, .complete = FALSE, na.rm = TRUE
        ),
      !!avg_var_str := if_else(
        .data[[avg_var_str]] == "NaN", NA_real_, .data[[avg_var_str]]
      )
    )
}

prepare_GC_weight_data <- function(data) {
  data %>% 
    select(date, weight) %>% 
    rename(weightkg = weight) %>% 
    as_tibble() %>% 
    mutate(date = as_datetime(date)) %>% 
    filter(!is.na(weightkg))
}

prepare_GC_nutrition_data <- function(data) {
  data %>% 
    select(date, calories, carbohydrates_g, fat_g, protein_g) %>% 
    rename(
      Datetime = date,
      Calories = calories,
      CHO = carbohydrates_g,
      PRO = protein_g,
      FAT = fat_g
      ) %>% 
    as_tibble() %>% 
    mutate(Datetime = as_datetime(Datetime)) %>%
    drop_na()
}

write_csv_and_return_path <- function(data, dir, filename) {
  write_csv(data, here::here(glue::glue("{dir}"), glue::glue("{filename}.csv")))

  return(here::here(dir, glue::glue("{filename}.csv")))
}