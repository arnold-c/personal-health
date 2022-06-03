workout_data_api <- httr::GET(url = "http://localhost:12021/Callum")             
http_status(workout_data_api)
headers(workout_data_api)

workout_data <- content(workout_data_api, "text")
jsonlite::fromJSON(workout_data)

workout_df <- read_csv(textConnection(workout_data))
