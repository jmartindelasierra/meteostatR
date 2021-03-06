% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/find_stations.R
\name{find_stations}
\alias{find_stations}
\title{Find weather stations}
\usage{
find_stations(query, limit = 8)
}
\arguments{
\item{query}{String. The search string.}

\item{limit}{Integer. The maximum number of results.}
}
\value{
Available weather stations.
}
\description{
Find weather stations
}
\examples{
find_stations(query = "vancouver")
}
