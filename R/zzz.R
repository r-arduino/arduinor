.onUnload <- function(libpath) {
  library.dynam.unload("arduinor", libpath)
}

Rcpp::loadModule("RunningMeanModule", TRUE)

