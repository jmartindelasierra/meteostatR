
#' Climate normals
#'
#' @param station String. The weather station ID.
#'
#' @return Average monthly weather.
#' @export
#'
#' @examples
#' climate_normals(station = "10637")

climate_normals <- function(station) {

  # Check arguments
  stopifnot(is.character(station))

  # Query string
  endpoint <- "https://api.meteostat.net/v2/stations/climate"
  endpoint <- paste0(endpoint, "?station=", station)

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
      dplyr::mutate(month = as.integer(.data$month),
                    tavg = as.numeric(.data$tavg),
                    tmin = as.numeric(.data$tmin),
                    tmax = as.numeric(.data$tmax),
                    prcp = as.integer(.data$prcp),
                    pres = as.numeric(.data$pres),
                    tsun = as.integer(.data$tsun))
  }

  list(meta = meta,
       data = data)
}
