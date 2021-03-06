% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/config.R
\name{read.AzureML.config}
\alias{read.AzureML.config}
\alias{write.AzureML.config}
\title{Reads settings from configuration file in JSON format.}
\usage{
read.AzureML.config(config = getOption("AzureML.config"))

write.AzureML.config(id = NULL, auth = NULL, api_endpoint = NULL,
  management_endpoint = NULL, file = "")
}
\arguments{
\item{config}{Optional settings file containing id and authorization info. Used if any of the other arguments are missing. The default config file is \code{~/.azureml/settings.json}, but you can change this location by setting \code{options(AzureML.config = "newlocation")}}

\item{id}{Optional workspace id from ML studio -> settings -> WORKSPACE ID}

\item{auth}{Optional authorization token from ML studio -> settings -> AUTHORIZATION TOKENS}

\item{api_endpoint}{Optional AzureML API web service URI. Defaults to \url{https://studio.azureml.net} if not provided and not specified in config.  See note.}

\item{management_endpoint}{Optional AzureML management web service URI. Defaults to \url{https://management.azureml.net} if not provided and not specified in config.  See note.}

\item{file}{either a character string naming a file or a connection open for writing. "" indicates output to the console.}
}
\description{
Reads settings from configuration file in JSON format.

Writes settings to configuration file.
}
\seealso{
write.AzureML.config

workspace

write.AzureML.config

workspace
}

