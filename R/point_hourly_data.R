#' Point hourly data
#'
#' @param lat Numeric. The latitude of the geographic location.
#' @param lon Numeric. The longitude of the geographic location.
#' @param alt Integer. The elevation of the geographic location.
#' @param start String. The start date of the query (format: YYYY-MM-DD).
#' @param end String. The end date of the query (format: YYYY-MM-DD).
#' @param tz String. The time zone according to the tz database.
#'
#' @return Historical hourly weather.
#' @export
#'
#' @examples
#' point_hourly_data(lat = 49.4967, lon = 8.4795, alt = 104, start = "2020-01-01", end = "2020-01-01", tz = "Europe/Berlin")

point_hourly_data <- function(lat, lon, alt = 0, start, end, tz = "UTC") {

  # Expected pattern for dates
  date_pattern <- "[12]\\d{3}\\-(0[1-9]|1[0-2])\\-(0[1-9]|[12]\\d|3[01])"

  # Check arguments
  stopifnot(is.numeric(lat))
  stopifnot(is.numeric(lon))
  stopifnot(is.null(alt) | is.numeric(alt))
  stopifnot(is.character(start))
  stopifnot(stringr::str_detect(start, date_pattern))
  stopifnot(is.character(end))
  stopifnot(stringr::str_detect(end, date_pattern))
  stopifnot(is.null(tz) | is.character(tz))

  start <- as.Date(start)
  end <- as.Date(end)

  days <- difftime(end, start, units = "days") %>%
    as.integer()

  stopifnot(days < 10)

  # Query string
  endpoint <- "https://api.meteostat.net/v2/point/hourly"
  endpoint <- paste0(endpoint, "?lat=", lat, "&lon=", lon, "&start=", start, "&end=", end)

  if (!is.null(alt)) {
    alt <- as.integer(alt)
    # Query string
    endpoint <- paste0(endpoint, "&alt=", alt)
  }

  if (!is.null(tz)) {
    # Query string
    endpoint <- paste0(endpoint, "&tz=", tz)
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
