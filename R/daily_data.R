
#' Daily data
#'
#'
#' @param station String. The weather station ID.
#' @param start String. The start date of the query (format: YYYY-MM-DD).
#' @param end String. The end date of the query (format: YYYY-MM-DD).
#'
#' @return Historical daily weather.
#' @export
#'
#' @examples
#' daily_data(station = "68816", start = "2019-06-01", end = "2019-06-30")

daily_data <- function(station, start, end) {

  # Expected pattern for dates
  date_pattern <- "[12]\\d{3}\\-(0[1-9]|1[0-2])\\-(0[1-9]|[12]\\d|3[01])"

  # Check arguments
  stopifnot(is.character(station))
  stopifnot(is.character(start))
  stopifnot(stringr::str_detect(start, date_pattern))
  stopifnot(is.character(end))
  stopifnot(stringr::str_detect(end, date_pattern))

  start <- as.Date(start)
  end <- as.Date(end)

  days <- difftime(end, start, units = "days") %>%
    as.integer()

  stopifnot(days < 370)

  # Query string
  endpoint <- "https://api.meteostat.net/v2/stations/daily"
  endpoint <- paste0(endpoint, "?station=", station, "&start=", start, "&end=", end)

  # Retrieve data
  msdata <- RCurl::getURL(url = endpoint,
                          httpheader = c("x-api-key" = Sys.getenv("METEOSTAT_KEY")))

  if (msdata == "") {
    message("No data returned.")
    return(NULL)
  }

  # Format output
  meta <- jsonlite::fromJSON(msdata)["meta"]$meta %>%
    dplyr::as_tibble() %>%
    dplyr::mutate(generated = lubridate::as_datetime(.data$generated))

  data <- jsonlite::fromJSON(msdata)["data"]$data %>%
    dplyr::as_tibble()

  if (nrow(data) != 0) {
    # Format output
    data <- data %>%
      dplyr::mutate(date = lubridate::as_date(date),
                    tavg = as.numeric(.data$tavg),
                    tmin = as.numeric(.data$tmin),
                    tmax = as.numeric(.data$tmax),
                    prcp = as.numeric(.data$prcp),
                    snow = as.integer(.data$snow),
                    wdir = as.integer(.data$wdir),
                    wspd = as.numeric(.data$wspd),
                    wpgt = as.numeric(.data$wpgt),
                    pres = as.numeric(.data$pres),
                    tsun = as.integer(.data$tsun))
  }

  list(meta = meta,
       data = data)
}
