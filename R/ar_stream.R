#' Stream serial port data into R console
#' 
#' @description This function wraps around `ar_read()` and will read serial
#' port data into R console until user stop it.
#' 
#' @param fd File descriptor returned by `ar_init()`. Should be an integer.
#' @param eolchar End of line character. Default value is `'\\n'`
#' @param buf_max Maximum length of one line of entry. Default is 256.
#' @param timeout Timeout for reads in millisecs. Default is 5000 ms.
#' 
#' @export
ar_stream <- function(fd, eolchar = "\n", buf_max = 256, timeout = 5000) {
  ar_flush(fd)
  ar_read(fd, eolchar, buf_max, timeout)
  repeat(cat(ar_read(fd, eolchar, buf_max, timeout)))
}