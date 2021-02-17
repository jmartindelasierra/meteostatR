
#' Nearby weather stations
#'
#' @param lat Numeric. The latitude of the location.
#' @param lon Numeric. The longitude of the location.
#' @param limit Integer. The maximum number of results.
#' @param radius Numeric. The radius of the query in kilometers.
#'
#' @return Available weather stations in the nearby of **lat** and **lon**.
#' @export
#'
#' @examples
#' nearby_stations(lat = 1.28, lon = 103.83, limit = 3)

nearby_stations <- function(lat, lon, limit = 8, radius = 100) {

  # Check arguments
  stopifnot(is.numeric(lat))
  stopifnot(is.numeric(lon))
  stopifnot(is.null(limit) | is.numeric(limit))
  stopifnot(is.null(radius) | is.numeric(radius))

  # Query string
  endpoint <- "https://api.meteostat.net/v2/stations/nearby"
  endpoint <- paste0(endpoint, "?lat=", lat, "&lon=", lon)

  if (!is.null(limit)) {
    limit <- as.integer(limit)
    # Query string
    endpoint <- paste0(endpoint, "&limit=", limit)
  }

  if(!is.null(radius)) {
    radius <- as.integer(radius)
    # Query string
    endpoint <- paste0(endpoint, "&radius=", radius)
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
      dplyr::mutate(id = as.character(.data$id),
                    active = as.logical(.data$active),
                    distance = as.numeric(.data$distance))
  }

  list(meta = meta,
       data = data)
}
