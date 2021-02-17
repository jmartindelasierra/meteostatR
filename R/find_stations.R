
#' Find weather stations
#'
#' @importFrom dplyr %>%
#' @importFrom rlang .data
#'
#' @param query String. The search string.
#' @param limit Integer. The maximum number of results.
#'
#' @return Available weather stations.
#' @export
#'
#' @examples
#' find_stations(query = "vancouver")

find_stations <- function(query, limit = 8) {

  # Check arguments
  stopifnot(is.character(query))
  stopifnot(nchar(query) > 2)
  stopifnot(is.null(limit) | is.numeric(limit))

  # Query string
  endpoint <- "https://api.meteostat.net/v2/stations/search"
  endpoint <- paste0(endpoint, "?query=", query)

  if (!is.null(limit)) {
    limit <- as.integer(limit)
    # Query string
    endpoint <- paste0(endpoint, "&limit=", limit)
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
                    country = as.character(.data$country),
                    region = as.character(.data$region),
                    national = as.character(.data$national),
                    wmo = as.integer(.data$wmo),
                    icao = as.character(.data$icao),
                    iata = as.character(.data$iata),
                    latitude = as.numeric(.data$latitude),
                    longitude = as.numeric(.data$longitude),
                    elevation = as.integer(.data$elevation),
                    timezone = as.character(.data$timezone),
                    active = as.logical(.data$active))
  }

  list(meta = meta,
       data = data)
}
