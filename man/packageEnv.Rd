% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/internal.R
\name{packageEnv}
\alias{packageEnv}
\title{Package a Function and Dependencies into an Environment}
\usage{
packageEnv(exportenv, packages = NULL, version = "3.1.0")
}
\arguments{
\item{exportenv}{R environment to package}

\item{packages}{a character vector of required R package dependencies}

\item{version}{optional R version}
}
\value{
A base64-encoded zip file containing the saved 'exportenv' environment
}
\description{
Package a Function and Dependencies into an Environment
}
\keyword{Internal}

