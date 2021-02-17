
#' Hourly data
#'
#' @importFrom stats time
#'
#' @param station String. The weather station ID.
#' @param start String. The start date of the query (format: YYYY-MM-DD).
#' @param end String. The end date of the query (format: YYYY-MM-DD).
#' @param tz String. The time zone according to the tz database.
#' @param model Integer. A boolean parameter that specifies whether missing observations should be substituted with statistically optimized model data.
#'
#' @return Historical hourly weather.
#' @export
#'
#' @examples
#' hourly_data(station = "10637", start = "2020-02-01", end = "2020-02-04")

hourly_data <- function(station, start, end, tz = "UTC", model = 0) {

  # Expected pattern for dates
  date_pattern <- "[12]\\d{3}\\-(0[1-9]|1[0-2])\\-(0[1-9]|[12]\\d|3[01])"

  # Check arguments
  stopifnot(is.character(station))
  stopifnot(is.character(start))
  stopifnot(stringr::str_detect(start, date_pattern))
  stopifnot(is.character(end))
  stopifnot(stringr::str_detect(end, date_pattern))
  stopifnot(is.null(tz) | is.character(tz))
  stopifnot(is.null(model) | is.numeric(model))

  start <- as.Date(start)
  end <- as.Date(end)

  days <- difftime(end, start, units = "days") %>%
    as.integer()

  stopifnot(days < 10)

  # Query string
  endpoint <- "https://api.meteostat.net/v2/stations/hourly"
  endpoint <- paste0(endpoint, "?station=", station, "&start=", start, "&end=", end)

  if (!is.null(tz)) {
    # Query string
    endpoint <- paste0(endpoint, "&tz=", tz)
  }

  if (!is.null(model)) {
    stopifnot(model %in% c(0, 1))
    # Query string
    endpoint <- paste0(endpoint, "&model=", model)
  }

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
      dplyr::mutate(time = lubridate::as_datetime(time),
                    temp = as.numeric(.data$temp),
                    dwpt = as.numeric(.data$dwpt),
                    rhum = as.integer(.data$rhum),
                    prcp = as.numeric(.data$prcp),
                    snow = as.integer(.data$snow),
                    wdir = as.integer(.data$wdir),
                    wspd = as.numeric(.data$wspd),
                    wpgt = as.numeric(.data$wpgt),
                    pres = as.numeric(.data$pres),
                    tsun = as.integer(.data$tsun),
                    coco = as.integer(.data$coco))

    if (!is.null(tz)) {
      data <- data %>%
        dplyr::mutate(time_local = lubridate::as_datetime(.data$time_local))
    }
  }

  list(meta = meta,
       data = data)
}
