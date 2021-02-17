
#' Point climate normals
#'
#' @param lat Numeric. The latitude of the geographic location.
#' @param lon Numeric. The longitude of the geographic location.
#' @param alt Integer. The elevation of the geographic location.
#'
#' @return Average monthly weather.
#' @export
#'
#' @examples
#' point_climate_normals(lat = -33.87, lon = 151.21, alt = 58)

point_climate_normals <- function(lat, lon, alt = 0) {

  # Check arguments
  stopifnot(is.numeric(lat))
  stopifnot(is.numeric(lon))
  stopifnot(is.null(alt) | is.numeric(alt))

  # Query string
  endpoint <- "https://api.meteostat.net/v2/point/climate"
  endpoint <- paste0(endpoint, "?lat=", lat, "&lon=", lon)

  if (!is.null(alt)) {
    alt <- as.integer(alt)
    # Query string
    endpoint <- paste0(endpoint, "&alt=", alt)
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
