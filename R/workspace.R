# Copyright (c) 2015 Microsoft Corporation
# All rights reserved.
#   
# The MIT License (MIT)
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#   
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.



default_api <- function(api_endpoint = "https://studioapi.azureml.net"){
  defaults <- list(
    
    "https://studio.azureml.net" = list(
      api_endpoint        = "https://studioapi.azureml.net",
      management_endpoint = "https://management.azureml.net",
      studioapi           = "https://studioapi.azureml.net/api"
    ), 
    "https://studioapi.azureml.net" = list(
      api_endpoint        = "https://studioapi.azureml.net",
      management_endpoint = "https://management.azureml.net",
      studioapi           = "https://studioapi.azureml.net/api"
    ),
    "https://studioapi.azureml-int.net" = list(
      api_endpoint        = "https://studio.azureml-int.net",
      management_endpoint = "https://management.azureml-int.net",
      studioapi           = "https://studioapi.azureml-int.net/api"
    )
  )
  
  
  if(api_endpoint %in% names(defaults)){
    defaults[api_endpoint][[1]]
  } else {
    stop("api_endpoint not recognized")
  }
}

#' Create a reference to an AzureML Studio workspace.
#'
#' Create a reference to an AzureML Studio workspace, returning a \code{Workspace} object that is an R environment containing details and data associated with the AzureML work space. Data corresponding to services, experiments, and datasets in the workspace are cached in the result object environment. See \code{\link{refresh}} about updating cached data.
#' 
#' @param id Optional workspace id from ML studio -> settings -> WORKSPACE ID
#' @param auth Optional authorization token from ML studio -> settings -> AUTHORIZATION TOKENS
#' @param api_endpoint Optional AzureML API web service URI. Defaults to \url{https://studio.azureml.net} if not provided and not specified in config.  See note.
#' @param management_endpoint Optional AzureML management web service URI. Defaults to \url{https://management.azureml.net} if not provided and not specified in config.  See note.
#' @param config Optional settings file containing id and authorization info. Used if any of the other arguments are missing. The default config file is \code{~/.azureml/settings.json}, but you can change this location by setting \code{options(AzureML.config = "newlocation")}
#'
#' @note If any of the \code{id}, \code{auth}, \code{api_endpoint} or \code{management_endpoint} arguments are missing, the function attempts to read values from the \code{config} file with JSON format: \preformatted{
#'  {"workspace":{
#'    "id": "test_id",
#'    "authorization_token": "test_token",
#'    "api_endpoint": "api_endpoint",
#'    "management_endpoint": "management_endpoint"
#'  }}
#' } (see \url{https://github.com/RevolutionAnalytics/azureml/issues/13}).
#' 
#' @return An R environment of class \code{Workspace} containing at least the following objects:
#' \describe{
#'   \item{experiments}{Collection of experiments in the workspace represented as an \code{Experiments} data.frame}
#'   \item{datasets}{Collection of datasets in the workspace represented as a \code{Datasets} data.frame}
#'   \item{services}{Collection of web services in the workspace represented as a data.frame}
#' }
#' @importFrom jsonlite fromJSON
#' @export
#' @family dataset functions
#' @family experiment functions
#' @family discovery functions
#' @family consumption functions
#' @family publishing functions
#' @seealso \code{\link{datasets}}, \code{\link{experiments}}, \code{\link{refresh}},
#'          \code{\link{services}}, \code{\link{consume}}, \code{\link{publishWebService}}
workspace <- function(id, auth, api_endpoint, management_endpoint,
                      config = getOption("AzureML.config"))
{
  
  
  # If workspace_id or auth are missing, read from config. Stop if unavailable.
  if(missing(id) || missing(auth)) {
    x <- validate.AzureML.config(config, stopOnError = TRUE)
    if(inherits(x, "error")) stop(x$message)
    settings <- read.AzureML.config(config)
    
    if(missing(id)){
      id <- settings[["workspace"]][["id"]]
    }
    if(missing(auth)){
      auth <- settings[["workspace"]][["authorization_token"]]
    }
  }
  
  # If workspace_id or auth are missing, read from config, if available.
  if(missing(api_endpoint) || missing(management_endpoint)){
    x <- validate.AzureML.config(config, stopOnError = FALSE)
    if(!inherits(x, "error")){
      settings <- read.AzureML.config(config)
      
      if(missing(api_endpoint)){
        api_endpoint <- settings[["workspace"]][["api_endpoint"]]
      }
      if(missing(management_endpoint)){
        management_endpoint <- settings[["workspace"]][["management_endpoint"]]
      }
    }
  }
  
  # Assign a default api_endpoint if this was not provided
  default_api <- if(missing(api_endpoint) || is.null(api_endpoint)) {
    default_api()
  } else {
    default_api(api_endpoint)
  }
  if(missing(api_endpoint) || is.null(api_endpoint)){
    api_endpoint <- default_api[["api_endpoint"]]
  }
  
  # Assign a default management_endpoint if this was not provided
  if(missing(management_endpoint) || is.null(management_endpoint)){
    management_endpoint <- default_api[["management_endpoint"]]
  }
  
  # Test to see if api_endpoint is a valid url
  resp <- tryCatch(
    suppressWarnings(curl::curl_fetch_memory(api_endpoint)),
    error = function(e)e
  )
  if(inherits(resp, "error")) stop("Invalid api_endpoint: ", api_endpoint)
  
  # Test to see if management_endpoint is a valid url
  resp <- tryCatch(
    suppressWarnings(curl::curl_fetch_memory(management_endpoint)),
    error = function(e)e
  )
  if(inherits(resp, "error")) stop("Invalid management_endpoint: ", management_endpoint)
  
  # It seems all checks passed. Now construct the Workspace object
  
  e <- new.env()
  class(e) <- "Workspace"
  e$id <- id
  e$.auth <- auth
  e$.api_endpoint <- api_endpoint
  e$.management_endpoint <- management_endpoint
  e$.studioapi <- default_api[["studioapi"]]
  e$.headers <- list(
    `User-Agent` = "R",
    `Content-Type` = "application/json;charset=UTF8",
    `x-ms-client-session-id` = "DefaultSession",
    `x-ms-metaanalytics-authorizationtoken` = auth
  )
  delayedAssign("experiments", get_experiments(e), assign.env = e)
  delayedAssign("datasets", get_datasets(e), assign.env = e)
  delayedAssign("services", services(e), assign.env = e)
  e
}

#'  Refresh data in an AzureML workspace object.
#'
#' Contact the AzureML web service and refresh/update data in an AzureML workspace object.
#' 
#' @param ws An AzureML workspace reference returned by \code{\link{workspace}}.
#' @param what Select "everything" to update all cached data, or other values to selectively update those values.
#' 
#' @return NULL is invisibly returned--this function updates data in the \code{w} environment.
#' @seealso \code{\link{workspace}}
#' @export
refresh <- function(ws, what=c("everything", "datasets", "experiments", "services"))
{
  what = match.arg(what)
  if(what %in% c("everything", "experiments")) ws$experiments <-  get_experiments(ws)
  if(what %in% c("everything", "datasets")) ws$datasets <- get_datasets(ws)
  if(what %in% c("everything", "services")) ws$services <- services(ws)
  invisible()
}

#' List datasets in an AzureML workspace.
#'
#' List datasets in an AzureML workspace, optionally filtering on sample or my datasets.
#' 
#' @inheritParams refresh
#' @param filter Optionally filter result, returing all, mine, or sample datasets.
#' 
#' @return A data.frame with class \code{Datasets} listing available datasets in the workspace.
#' @note \code{datasets(w)} is equivalent to \code{w$datasets}. Since \code{w$datasets} is simply
#' an R data.frame, you can alternatively filter on any variable as desired.
#' @seealso \code{\link{workspace}}, \code{\link{experiments}}, \code{\link{download.datasets}}
#' 
#' @export
#' @family dataset functions
#' @example inst/examples/example_datasets.R
datasets <- function(ws, filter=c("all", "my datasets", "samples"))
{
  stopIfNotWorkspace(ws)
  filter = match.arg(filter)
  if(filter == "all") return(ws$datasets)
  samples = filter == "samples"
  i = grep(paste("^", ws$id, sep=""), ws$datasets[,"Id"], invert=samples)
  ws$datasets[i, ]
}

#' List experiments in an AzureML workspace.
#'
#' List experiments in an AzureML workspace, optionally filtering on sample or my experiments.
#' 
#' @inheritParams datasets
#' 
#' @return A data.frame with class \code{Experiments} listing available experiments in the workspace.
#' @note \code{experiments(w)} is equivalent to \code{w$experiments}. Since \code{w$experiments} is simply an R data.frame, you can alternatively filter on any variable as desired.
#' @seealso \code{\link{workspace}}, \code{\link{datasets}}, \code{\link{download.intermediate.dataset}}
#' 
#' @export
#' @family experiment functions
#' @example inst/examples/example_experiments.R
experiments <- function(ws, filter=c("all", "my datasets", "samples"))
{
  filter = match.arg(filter)
  if(filter == "all") return(ws$experiments)
  samples = filter == "samples"
  i = grep(paste("^", ws$id, sep=""), ws$experiments[,"ExperimentId"], invert=samples)
  ws$experiments[i, ]
}
