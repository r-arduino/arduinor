#' Split string by special symbols
#' 
#' @description This function determines how the plotter extracts numbers from
#' the readings. By default, it trims of the "new line" symbol at the end of 
#' the row and split the string by special symbols (if you have used 
#' `tidyr::separate`, they are the same). You can write your own function if you
#' need special processing.
#' 
#' @param x Arduino Reading. Usually a string and needs to be chopped and 
#' converted to numbers. 
#' 
#' @export
ar_sep_comma <- function(x) {
  x <- sub("\r\n$", "", x)
  return(as.numeric(strsplit(x, ",")[[1]]))
}