
#' Meta data
#'
#' @param id String. The Meteostat ID of the weather station.
#' @param wmo Integer. The WMO ID of the weather station.
#' @param icao String. The ICAO ID of the weather station.
#'
#' @return Meta data weather station.
#' @export
#'
#' @examples
#' metadata_station(id = "71508")

metadata_station <- function(id = NULL, wmo = NULL, icao = NULL) {

  # Check arguments
  stopifnot(is.character(id) | is.numeric(wmo) | is.character(icao))

  # Query string
  endpoint <- "https://api.meteostat.net/v2/stations/meta"

  if (is.character(id)) {
    # Query string
    endpoint <- paste0(endpoint, "?id=", id)
  } else if (is.numeric(wmo)) {
    wmo <- as.integer(wmo)
    # Query string
    endpoint <- paste0(endpoint, "?wmo=", wmo)
  } else if (is.character(icao)) {
    # Query string
    endpoint <- paste0(endpoint, "?icao=", icao)
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
    unlist() %>%
    t() %>%
    as.data.frame()

  if (nrow(data) != 0) {
    # Format output
    data <- data %>%
      dplyr::mutate(latitude = as.numeric(.data$latitude),
                    longitude = as.numeric(.data$longitude),
                    elevation = as.integer(.data$elevation),
                    inventory.hourly.start = as.Date(.data$inventory.hourly.start),
                    inventory.hourly.end = as.Date(.data$inventory.hourly.end),
                    inventory.daily.start = as.Date(.data$inventory.daily.start),
                    inventory.daily.end = as.Date(.data$inventory.daily.end))
  }

  list(meta = meta,
       data = data)
}
